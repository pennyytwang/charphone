package filter;

import java.io.IOException;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import dao.AccessTokenDao;
import dao.UserDao;
import model.AccessToken;
import model.User;
import util.DemoContext;
import util.ReadOnlyPolicy;
import util.RequestUtil;

public class AuthFilter implements Filter {

    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        setSecurityHeaders(response);

        try {
            String path = request.getRequestURI().substring(request.getContextPath().length());

            if (isPublic(path)) {
                chain.doFilter(req, res);
                return;
            }

            HttpSession session = request.getSession(false);
            User sessionUser = (User) (session != null ? session.getAttribute("user") : null);

            if (sessionUser == null) {
                unauthorized(request, response);
                return;
            }

            User freshUser = new UserDao().getUserById(sessionUser.getId());
            if (!isUserValid(freshUser)) {
                invalidateQuietly(session);
                unauthorized(request, response);
                return;
            }

            Integer tokenId = (Integer) session.getAttribute("tokenId");
            AccessToken token = null;
            if (tokenId != null) {
                token = new AccessTokenDao().findById(tokenId);
                if (!isTokenValid(token, freshUser)) {
                    invalidateQuietly(session);
                    unauthorized(request, response);
                    return;
                }
            }

            boolean readOnly = freshUser.isReadOnly() || freshUser.isTemporary()
                    || (token != null && token.getScopes() != null && token.getScopes().contains("read_only"));

            session.setAttribute("user", freshUser);
            session.setAttribute("readOnly", readOnly);

            if (readOnly) {
                // 只有 GET 的白名單需要 action；對 POST 呼叫 getParameter 會讓
                // Tomcat 解析並消耗 form body，導致 /api/v1 代理轉送時遺失參數。
                String action = "GET".equalsIgnoreCase(request.getMethod())
                        ? request.getParameter("action")
                        : null;
                if (!ReadOnlyPolicy.isAllowed(path, request.getMethod(), action)) {
                    denyReadOnly(request, response);
                    return;
                }
            }

            DemoContext.setReadOnly(readOnly);
            DemoContext.setMasked(readOnly);
            chain.doFilter(req, res);
        } finally {
            DemoContext.clear();
        }
    }

    private boolean isPublic(String path) {
        return path.equals("/login.jsp")
                || path.equals("/LoginServlet")
                || path.equals("/AccessServlet")
                || path.equals("/TokenLoginServlet")
                || path.startsWith("/css/")
                || path.startsWith("/js/")
                || path.startsWith("/images/")
                || path.equals("/favicon.ico")
                || path.equals("/robots.txt");
    }

    private boolean isUserValid(User user) {
        if (user == null || !user.isActive()) {
            return false;
        }
        return user.getExpiresAt() == null || user.getExpiresAt().getTime() > System.currentTimeMillis();
    }

    private boolean isTokenValid(AccessToken token, User user) {
        if (token == null || token.getUserId() != user.getId()) {
            return false;
        }
        if (token.isRevoked()) {
            return false;
        }
        return !token.isExpired(System.currentTimeMillis());
    }

    private void invalidateQuietly(HttpSession session) {
        try {
            session.invalidate();
        } catch (IllegalStateException ignored) {
        }
    }

    private void unauthorized(HttpServletRequest request, HttpServletResponse response) throws IOException {
        if (RequestUtil.isAjax(request)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"error\":\"unauthorized\"}");
            return;
        }
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=session_expired");
    }

    private void denyReadOnly(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (RequestUtil.isAjax(request)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"error\":\"read_only\"}");
            return;
        }
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        request.getRequestDispatcher("/error/readonly.jsp").forward(request, response);
    }

    private void setSecurityHeaders(HttpServletResponse response) {
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("X-Frame-Options", "SAMEORIGIN");
        response.setHeader("Referrer-Policy", "no-referrer");
    }

    public void init(FilterConfig fConfig) throws ServletException {}
    public void destroy() {}
}
