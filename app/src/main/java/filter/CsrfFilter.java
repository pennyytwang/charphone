package filter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import util.RequestUtil;

/**
 * 全站 CSRF 防護。
 *
 * <p>GET/HEAD/OPTIONS 不驗證，但會確保 session 中有 token；
 * 狀態變更請求必須帶 {@code _csrf} 參數或 {@code X-CSRF-Token} header。</p>
 */
public class CsrfFilter implements Filter {

    public static final String SESSION_ATTR = "csrfToken";
    public static final String PARAM_NAME = "_csrf";
    public static final String HEADER_NAME = "X-CSRF-Token";

    private static final SecureRandom RANDOM = new SecureRandom();

    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;

        String path = request.getRequestURI().substring(request.getContextPath().length());
        if (isStatic(path) || path.startsWith("/api/v1/")) {
            chain.doFilter(req, res);
            return;
        }

        String method = request.getMethod();
        if ("GET".equalsIgnoreCase(method) || "HEAD".equalsIgnoreCase(method) || "OPTIONS".equalsIgnoreCase(method)) {
            HttpSession session = request.getSession(true);
            ensureToken(session);
            chain.doFilter(req, res);
            return;
        }

        HttpSession session = request.getSession(false);
        String expected = session == null ? null : (String) session.getAttribute(SESSION_ATTR);
        String actual = request.getHeader(HEADER_NAME);
        if (actual == null) {
            actual = request.getParameter(PARAM_NAME);
        }

        if (!matches(expected, actual)) {
            if (RequestUtil.isAjax(request)) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"error\":\"csrf_failed\"}");
            } else {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("text/html;charset=UTF-8");
                response.getWriter().write("<h1>403 Forbidden</h1><p>CSRF 驗證失敗，請重新整理頁面後再試。</p>");
            }
            return;
        }

        chain.doFilter(req, res);
    }

    private boolean isStatic(String path) {
        return path.startsWith("/css/") || path.startsWith("/js/") || path.startsWith("/images/")
                || path.equals("/favicon.ico") || path.equals("/robots.txt");
    }

    private void ensureToken(HttpSession session) {
        if (session.getAttribute(SESSION_ATTR) == null) {
            byte[] bytes = new byte[32];
            RANDOM.nextBytes(bytes);
            session.setAttribute(SESSION_ATTR, Base64.getUrlEncoder().withoutPadding().encodeToString(bytes));
        }
    }

    private boolean matches(String expected, String actual) {
        if (expected == null || actual == null) {
            return false;
        }
        return MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8),
                actual.getBytes(StandardCharsets.UTF_8));
    }

    public void init(FilterConfig fConfig) throws ServletException {}
    public void destroy() {}
}
