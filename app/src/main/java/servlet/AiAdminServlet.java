package servlet;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Duration;
import java.util.Base64;
import java.util.Enumeration;
import java.util.Locale;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

import filter.CsrfFilter;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;

/**
 * AI Gateway 管理後台代理。
 *
 * <p>僅允許 CharPhone 管理員使用，並由伺服器端注入 ADMIN API Key；
 * 金鑰不會傳到瀏覽器。代理頁面與 admin.html 所需的稽核、用量、API Key 管理 API。</p>
 */
@WebServlet(urlPatterns = {"/AiAdminServlet", "/AiAdminServlet/*"})
public class AiAdminServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(AiAdminServlet.class.getName());

    private static final String GATEWAY_BASE = "http://ai-gateway:8080";
    private static final String ADMIN_PAGE_PATH = "/admin.html";
    private static final String ADMIN_KEY_ENV = "AI_GATEWAY_ADMIN_API_KEY";
    private static final String FALLBACK_KEY_ENV = "AI_GATEWAY_API_KEY";

    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(10);
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(30);

    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .connectTimeout(CONNECT_TIMEOUT)
            .followRedirects(HttpClient.Redirect.NEVER)
            .build();

    private static final Set<String> REQUEST_SKIP_HEADERS = Set.of(
            "host", "content-length", "expect", "x-api-key", "cookie",
            "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
            "te", "trailer", "transfer-encoding", "upgrade");

    private static final Set<String> RESPONSE_SKIP_HEADERS = Set.of(
            "content-length", "connection", "keep-alive", "proxy-authenticate",
            "proxy-authorization", "te", "trailer", "transfer-encoding", "upgrade");

    private static final SecureRandom RANDOM = new SecureRandom();

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!isAdmin(req)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "AI 管理僅限管理員");
            return;
        }

        String pathInfo = req.getPathInfo();
        if (pathInfo == null) {
            if ("GET".equalsIgnoreCase(req.getMethod()) || "HEAD".equalsIgnoreCase(req.getMethod())) {
                resp.sendRedirect(req.getContextPath() + "/AiAdminServlet/");
            } else {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            }
            return;
        }

        if (isPageRequest(pathInfo)) {
            proxyPage(req, resp);
            return;
        }
        if (isAllowedApi(pathInfo)) {
            proxyApi(req, resp, pathInfo);
            return;
        }

        resp.sendError(HttpServletResponse.SC_NOT_FOUND);
    }

    private boolean isAdmin(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) {
            return false;
        }
        Object user = session.getAttribute("user");
        Object readOnly = session.getAttribute("readOnly");
        return user instanceof User u
                && "admin".equalsIgnoreCase(u.getRole())
                && !Boolean.TRUE.equals(readOnly);
    }

    private boolean isPageRequest(String pathInfo) {
        return "/".equals(pathInfo) || "/admin.html".equals(pathInfo);
    }

    private boolean isAllowedApi(String pathInfo) {
        return pathInfo.equals("/api/v1/usage/report")
                || pathInfo.startsWith("/api/v1/admin/");
    }

    private void proxyPage(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (!"GET".equalsIgnoreCase(req.getMethod()) && !"HEAD".equalsIgnoreCase(req.getMethod())) {
            resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            return;
        }

        try {
            HttpRequest request = baseRequest(ADMIN_PAGE_PATH, req.getQueryString())
                    .GET()
                    .build();
            HttpResponse<byte[]> upstream = HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofByteArray());

            if (upstream.statusCode() != HttpServletResponse.SC_OK) {
                copyResponse(resp, upstream);
                return;
            }

            String html = new String(upstream.body(), StandardCharsets.UTF_8);
            byte[] body = injectBootstrap(html, csrfToken(req), req.getContextPath()).getBytes(StandardCharsets.UTF_8);

            resp.setStatus(HttpServletResponse.SC_OK);
            resp.setContentType("text/html;charset=UTF-8");
            resp.setHeader("Cache-Control", "no-store");
            resp.setContentLength(body.length);
            if (!"HEAD".equalsIgnoreCase(req.getMethod())) {
                try (OutputStream out = resp.getOutputStream()) {
                    out.write(body);
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            LOGGER.log(Level.WARNING, "AI admin page proxy interrupted", e);
            sendBadGateway(resp);
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "AI admin page proxy failed", e);
            sendBadGateway(resp);
        }
    }

    private void proxyApi(HttpServletRequest req, HttpServletResponse resp, String pathInfo) throws IOException {
        String method = req.getMethod();
        if (!isAllowedMethod(method)) {
            resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            return;
        }

        try {
            HttpRequest.Builder builder = baseRequest(pathInfo, req.getQueryString());
            copyRequestHeaders(builder, req);
            if (isBodyless(method)) {
                builder.method(method, HttpRequest.BodyPublishers.noBody());
            } else {
                byte[] payload = req.getInputStream().readAllBytes();
                builder.method(method, HttpRequest.BodyPublishers.ofByteArray(payload));
            }

            HttpRequest request = builder.build();
            HttpResponse<InputStream> upstream = HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofInputStream());

            resp.setStatus(upstream.statusCode());
            copyHeaders(resp, upstream);
            resp.setHeader("Cache-Control", "no-store");

            try (InputStream in = upstream.body(); OutputStream out = resp.getOutputStream()) {
                in.transferTo(out);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            LOGGER.log(Level.WARNING, "AI admin API proxy interrupted", e);
            sendBadGateway(resp);
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "AI admin API proxy failed", e);
            sendBadGateway(resp);
        }
    }

    private HttpRequest.Builder baseRequest(String path, String query) {
        String target = GATEWAY_BASE + path + (query != null && !query.isBlank() ? "?" + query : "");
        HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(target))
                .timeout(REQUEST_TIMEOUT)
                .header("Accept", "application/json, text/html;q=0.9,*/*;q=0.8");

        String adminKey = adminApiKey();
        if (adminKey == null || adminKey.isBlank()) {
            throw new IllegalStateException("AI_GATEWAY_ADMIN_API_KEY / AI_GATEWAY_API_KEY is not configured");
        }
        builder.header("X-API-Key", adminKey.trim());
        return builder;
    }

    private void copyRequestHeaders(HttpRequest.Builder builder, HttpServletRequest req) {
        Enumeration<String> headerNames = req.getHeaderNames();
        while (headerNames.hasMoreElements()) {
            String name = headerNames.nextElement();
            String lower = name.toLowerCase(Locale.ROOT);
            if (REQUEST_SKIP_HEADERS.contains(lower) || "accept".equals(lower)) {
                continue;
            }
            builder.header(name, req.getHeader(name));
        }
    }

    private String adminApiKey() {
        String key = System.getenv(ADMIN_KEY_ENV);
        if (key == null || key.isBlank()) {
            key = System.getenv(FALLBACK_KEY_ENV);
        }
        return key;
    }

    private boolean isAllowedMethod(String method) {
        return "GET".equalsIgnoreCase(method)
                || "POST".equalsIgnoreCase(method)
                || "PATCH".equalsIgnoreCase(method)
                || "DELETE".equalsIgnoreCase(method)
                || "HEAD".equalsIgnoreCase(method);
    }

    private boolean isBodyless(String method) {
        return "GET".equalsIgnoreCase(method)
                || "HEAD".equalsIgnoreCase(method)
                || "OPTIONS".equalsIgnoreCase(method);
    }

    private void copyResponse(HttpServletResponse resp, HttpResponse<byte[]> upstream) throws IOException {
        resp.setStatus(upstream.statusCode());
        copyHeaders(resp, upstream);
        resp.setHeader("Cache-Control", "no-store");
        byte[] body = upstream.body();
        if (body != null && body.length > 0) {
            try (OutputStream out = resp.getOutputStream()) {
                out.write(body);
            }
        }
    }

    private void copyHeaders(HttpServletResponse resp, HttpResponse<?> upstream) {
        upstream.headers().map().forEach((name, values) -> {
            if (name == null) {
                return;
            }
            String lower = name.toLowerCase(Locale.ROOT);
            if (RESPONSE_SKIP_HEADERS.contains(lower)) {
                return;
            }
            for (String value : values) {
                resp.addHeader(name, value);
            }
        });
    }

    private String injectBootstrap(String html, String csrfToken, String contextPath) {
        String bootstrap = adminBootstrap(csrfToken, contextPath);
        int bodyIndex = html.indexOf("<body");
        if (bodyIndex < 0) {
            return html + bootstrap;
        }
        int bodyTagEnd = html.indexOf('>', bodyIndex);
        if (bodyTagEnd < 0) {
            return html + bootstrap;
        }
        return html.substring(0, bodyTagEnd + 1)
                + bootstrap
                + html.substring(bodyTagEnd + 1);
    }

    private String adminBootstrap(String csrfToken, String contextPath) {
        return "<script>(function(){"
                + "var token='" + csrfToken + "';"
                + "var ctx='" + contextPath + "';"
                + "try{localStorage.setItem('gwAdminKey','__CHARPHONE_ADMIN_PROXY__');}catch(e){}"
                + "var originalFetch=window.fetch;"
                + "if(originalFetch){window.fetch=function(input,init){"
                + "init=init||{};"
                + "try{var headers=new Headers(init.headers||{});headers.set('X-CSRF-Token',token);init.headers=headers;}catch(e){}"
                + "return originalFetch.call(window,input,init);"
                + "};}"
                + "document.addEventListener('DOMContentLoaded',function(){"
                + "var input=document.getElementById('apiKey');"
                + "if(input){var card=input.closest('.card');if(card){card.style.display='none';}}"
                + "var link=document.createElement('a');"
                + "link.href=ctx+'/AiUiAdminServlet';"
                + "link.textContent='企業AI 頁面內容';"
                + "link.style.cssText='position:fixed;right:18px;bottom:18px;z-index:99999;background:#4361ee;color:#fff;padding:10px 16px;border-radius:999px;font-size:13px;font-weight:700;text-decoration:none;box-shadow:0 6px 18px rgba(67,97,238,.35)';"
                + "document.body.appendChild(link);"
                + "});"
                + "})();</script>";
    }

    private String csrfToken(HttpServletRequest req) {
        HttpSession session = req.getSession(true);
        Object existing = session.getAttribute(CsrfFilter.SESSION_ATTR);
        if (existing instanceof String token && !token.isBlank()) {
            return token;
        }
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        session.setAttribute(CsrfFilter.SESSION_ATTR, token);
        return token;
    }

    private void sendBadGateway(HttpServletResponse resp) throws IOException {
        if (resp.isCommitted()) {
            return;
        }
        resp.reset();
        resp.setStatus(HttpServletResponse.SC_BAD_GATEWAY);
        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().write("{\"error\":\"AI Gateway admin proxy unavailable\"}");
    }
}
