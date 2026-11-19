package servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Enumeration;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.regex.Pattern;
import java.util.logging.Logger;

import model.User;

@WebServlet("/api/v1/*")
public class ApiProxyServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(ApiProxyServlet.class.getName());

    private static final String BASE = "http://ai-gateway:8080/api/v1";
    private static final String API_KEY_ENV = "AI_GATEWAY_API_KEY";
    private static final String API_PREFIX = "/api/v1";

    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(10);
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(300);

    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .connectTimeout(CONNECT_TIMEOUT)
            .followRedirects(HttpClient.Redirect.NEVER)
            .build();

    private static final Set<String> REQUEST_SKIP_HEADERS = Set.of(
            "host", "content-length", "expect", "x-api-key", "cookie",
            "x-charphone-user-id", "x-charphone-username", "x-charphone-session-id", "x-charphone-source",
            "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
            "te", "trailer", "transfer-encoding", "upgrade");

    private static final Set<String> RESPONSE_SKIP_HEADERS = Set.of(
            "content-length", "connection", "keep-alive", "proxy-authenticate",
            "proxy-authorization", "te", "trailer", "transfer-encoding", "upgrade");

    private static final Set<String> READONLY_POST_PATHS = Set.of(
            "/api/v1/chat",
            "/api/v1/chat/stream",
            "/api/v1/agent/run",
            "/api/v1/rag/ask",
            "/api/v1/rag/query");

    private static final Set<String> READONLY_GET_PATHS = Set.of(
            "/api/v1/rag/documents");

    private static final Pattern RAG_DOWNLOAD_PATH = Pattern.compile(
            "^/api/v1/rag/documents/[0-9a-fA-F-]{36}/download$");
    private static final Pattern RAG_VIEWER_PATH = Pattern.compile(
            "^/api/v1/rag/documents/[0-9a-fA-F-]{36}/viewer$");

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getRequestURI().substring(req.getContextPath().length());
        if (!isAllowed(req, path)) {
            writeForbidden(resp);
            return;
        }

        String query = req.getQueryString();
        String target = BASE + path.substring(API_PREFIX.length()) + (query != null ? "?" + query : "");

        try {
            HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(target)).timeout(REQUEST_TIMEOUT);
            String method = req.getMethod();
            if (isBodyless(method)) {
                builder.method(method, HttpRequest.BodyPublishers.noBody());
            } else {
                byte[] body = req.getInputStream().readAllBytes();
                builder.method(method, HttpRequest.BodyPublishers.ofByteArray(body));
            }

            Enumeration<String> headerNames = req.getHeaderNames();
            while (headerNames.hasMoreElements()) {
                String name = headerNames.nextElement();
                String lower = name.toLowerCase(Locale.ROOT);
                if (REQUEST_SKIP_HEADERS.contains(lower)) {
                    continue;
                }
                builder.header(name, req.getHeader(name));
            }

            String apiKey = System.getenv(API_KEY_ENV);
            if (apiKey == null || apiKey.isBlank()) {
                throw new IllegalStateException(API_KEY_ENV + " is not configured");
            }
            builder.header("X-API-Key", apiKey.trim());
            applyAppUserHeaders(req, builder);

            HttpResponse<InputStream> upstream = HTTP_CLIENT.send(
                    builder.build(), HttpResponse.BodyHandlers.ofInputStream());

            resp.setStatus(upstream.statusCode());
            String contentType = null;
            for (Map.Entry<String, List<String>> entry : upstream.headers().map().entrySet()) {
                String name = entry.getKey();
                if (name == null) {
                    continue;
                }
                String lower = name.toLowerCase(Locale.ROOT);
                if (RESPONSE_SKIP_HEADERS.contains(lower)) {
                    continue;
                }
                for (String value : entry.getValue()) {
                    resp.addHeader(name, value);
                }
                if ("content-type".equals(lower) && !entry.getValue().isEmpty()) {
                    contentType = entry.getValue().get(0);
                }
            }

            if (contentType != null && contentType.toLowerCase(Locale.ROOT).startsWith("text/event-stream")) {
                resp.setHeader("Cache-Control", "no-cache");
                resp.setHeader("X-Accel-Buffering", "no");
            }

            try (InputStream in = upstream.body(); OutputStream out = resp.getOutputStream()) {
                in.transferTo(out);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            LOGGER.log(Level.WARNING, "AI gateway proxy interrupted", e);
            sendBadGateway(resp);
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "AI gateway proxy failed", e);
            sendBadGateway(resp);
        }
    }

    private boolean isAllowed(HttpServletRequest req, String path) {
        String method = req.getMethod();
        if ("GET".equalsIgnoreCase(method) || "HEAD".equalsIgnoreCase(method)) {
            return READONLY_GET_PATHS.contains(path)
                    || RAG_DOWNLOAD_PATH.matcher(path).matches()
                    || RAG_VIEWER_PATH.matcher(path).matches();
        }
        if ("POST".equalsIgnoreCase(method)) {
            if (READONLY_POST_PATHS.contains(path)) {
                return true;
            }
            if ("/api/v1/rag/ingest".equals(path)) {
                return isAdmin(req);
            }
        }
        if ("DELETE".equalsIgnoreCase(method) && path.startsWith("/api/v1/rag/documents/")) {
            return isAdmin(req);
        }
        return false;
    }

    /**
     * 注入 CharPhone 的登入者身分，供 AI Gateway 稽核使用。
     *
     * <p>所有 {@code X-CharPhone-*} 標頭都會先被丟棄，再由本方法覆寫，
     * 避免使用者自行偽造身分。</p>
     */
    private void applyAppUserHeaders(HttpServletRequest req, HttpRequest.Builder builder) {
        HttpSession session = req.getSession(false);
        if (session == null) {
            return;
        }
        Object attr = session.getAttribute("user");
        if (!(attr instanceof User user)) {
            return;
        }
        builder.header("X-CharPhone-User-Id", String.valueOf(user.getId()));
        String username = user.getUsername();
        if (username != null && !username.isBlank()) {
            builder.header("X-CharPhone-Username",
                    URLEncoder.encode(username, StandardCharsets.UTF_8));
        }
        builder.header("X-CharPhone-Session-Id", session.getId());
        builder.header("X-CharPhone-Source", "charphone");
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

    private boolean isBodyless(String method) {
        return "GET".equalsIgnoreCase(method)
                || "HEAD".equalsIgnoreCase(method)
                || "OPTIONS".equalsIgnoreCase(method);
    }

    private void writeForbidden(HttpServletResponse resp) throws IOException {
        resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().write("{\"error\":\"forbidden\"}");
    }

    private void sendBadGateway(HttpServletResponse resp) throws IOException {
        if (resp.isCommitted()) {
            return;
        }
        resp.reset();
        resp.setStatus(HttpServletResponse.SC_BAD_GATEWAY);
        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().write("{\"error\":\"AI Gateway unavailable\"}");
    }
}
