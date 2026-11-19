package servlet;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import dao.AccessTokenDao;
import dao.UserDao;
import model.AccessToken;
import model.User;
import util.TokenUtil;

/**
 * 管理員建立、撤銷、重新產生存取 token。
 */
@WebServlet("/TokenAdminServlet")
public class TokenAdminServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(TokenAdminServlet.class.getName());

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        HttpSession session = request.getSession(false);
        User currentUser = (User) (session != null ? session.getAttribute("user") : null);
        if (currentUser == null || !"admin".equals(currentUser.getRole())) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String action = request.getParameter("action");
        try {
            if ("revoke".equals(action)) {
                revoke(request, response);
            } else if ("regenerate".equals(action)) {
                regenerate(request, response, currentUser);
            } else {
                create(request, response, currentUser);
            }
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/user/user_list.jsp?error=invalid");
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to manage access token", e);
            response.sendRedirect(request.getContextPath() + "/user/user_list.jsp?error=token_failed");
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/user/user_list.jsp");
    }

    private void create(HttpServletRequest request, HttpServletResponse response, User currentUser)
            throws IOException {
        int userId = Integer.parseInt(request.getParameter("userId"));
        String label = trim(request.getParameter("label"));
        Timestamp expiresAt = parseExpiresAt(request.getParameter("expiresAt"));
        Integer maxUses = parseMaxUses(request.getParameter("maxUses"));

        UserDao userDao = new UserDao();
        User target = userDao.getUserById(userId);
        String validationError = validate(target, label, expiresAt, maxUses);
        if (validationError != null) {
            response.sendRedirect(request.getContextPath()
                    + "/user/token_list.jsp?userId=" + userId + "&error=" + validationError);
            return;
        }

        String rawToken = TokenUtil.generate();
        String scopes = (target.isReadOnly() || target.isTemporary()) ? "read_only" : "full";
        AccessTokenDao tokenDao = new AccessTokenDao();
        int tokenId = tokenDao.insert(userId, TokenUtil.hash(rawToken), TokenUtil.hint(rawToken),
                label, scopes, expiresAt, maxUses, currentUser.getId());
        if (tokenId < 0) {
            response.sendRedirect(request.getContextPath()
                    + "/user/token_list.jsp?userId=" + userId + "&error=token_failed");
            return;
        }
        flashToken(request, rawToken, label, expiresAt, maxUses, userId, TokenUtil.hint(rawToken));
        LOGGER.info("Access token created: id=" + tokenId + ", userId=" + userId
                + ", by=" + currentUser.getId());
        response.sendRedirect(request.getContextPath() + "/user/token_created.jsp");
    }

    private void revoke(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int tokenId = Integer.parseInt(request.getParameter("tokenId"));
        AccessTokenDao tokenDao = new AccessTokenDao();
        AccessToken token = tokenDao.findById(tokenId);
        if (token == null) {
            response.sendRedirect(request.getContextPath() + "/user/user_list.jsp?error=token_not_found");
            return;
        }
        boolean ok = tokenDao.revoke(tokenId);
        String suffix = ok ? "message=revoked" : "error=revoke_failed";
        response.sendRedirect(request.getContextPath()
                + "/user/token_list.jsp?userId=" + token.getUserId() + "&" + suffix);
    }

    private void regenerate(HttpServletRequest request, HttpServletResponse response, User currentUser)
            throws IOException {
        int tokenId = Integer.parseInt(request.getParameter("tokenId"));
        AccessToken old = new AccessTokenDao().findById(tokenId);
        if (old == null) {
            response.sendRedirect(request.getContextPath() + "/user/user_list.jsp?error=token_not_found");
            return;
        }

        String label = trim(request.getParameter("label"));
        if (label == null || label.isEmpty()) {
            label = old.getLabel();
        }
        Timestamp expiresAt = parseExpiresAt(request.getParameter("expiresAt"));
        Integer maxUses = parseMaxUses(request.getParameter("maxUses"));

        UserDao userDao = new UserDao();
        User target = userDao.getUserById(old.getUserId());
        String validationError = validate(target, label, expiresAt, maxUses);
        if (validationError != null) {
            response.sendRedirect(request.getContextPath()
                    + "/user/token_list.jsp?userId=" + old.getUserId() + "&error=" + validationError);
            return;
        }

        AccessTokenDao tokenDao = new AccessTokenDao();
        String rawToken = TokenUtil.generate();
        String scopes = (target.isReadOnly() || target.isTemporary()) ? "read_only" : "full";
        int newId = tokenDao.regenerate(tokenId, target.getId(), TokenUtil.hash(rawToken),
                TokenUtil.hint(rawToken), label, scopes, expiresAt, maxUses, currentUser.getId());
        if (newId < 0) {
            response.sendRedirect(request.getContextPath()
                    + "/user/token_list.jsp?userId=" + old.getUserId() + "&error=token_failed");
            return;
        }
        flashToken(request, rawToken, label, expiresAt, maxUses, target.getId(), TokenUtil.hint(rawToken));
        LOGGER.info("Access token regenerated: oldId=" + tokenId + ", newId=" + newId
                + ", userId=" + target.getId() + ", by=" + currentUser.getId());
        response.sendRedirect(request.getContextPath() + "/user/token_created.jsp");
    }

    private String validate(User target, String label, Timestamp expiresAt, Integer maxUses) {
        if (target == null) {
            return "user_not_found";
        }
        if (!target.isActive()) {
            return "user_inactive";
        }
        if (label == null || label.isEmpty()) {
            return "label_required";
        }
        if (label.length() > 100) {
            return "label_too_long";
        }
        if (expiresAt == null) {
            return "expiry_required";
        }
        if (expiresAt.getTime() <= System.currentTimeMillis()) {
            return "expiry_past";
        }
        if (target.getExpiresAt() != null && expiresAt.after(target.getExpiresAt())) {
            return "expiry_exceeds_user";
        }
        if (maxUses != null && maxUses <= 0) {
            return "max_uses_invalid";
        }
        return null;
    }

    private void flashToken(HttpServletRequest request, String rawToken, String label,
                            Timestamp expiresAt, Integer maxUses, int userId, String hint) {
        HttpSession session = request.getSession(true);
        session.setAttribute("newTokenPlain", rawToken);
        session.setAttribute("newTokenLink", buildMagicLink(request, rawToken));
        session.setAttribute("newTokenLabel", label);
        session.setAttribute("newTokenExpiresAt", expiresAt);
        session.setAttribute("newTokenMaxUses", maxUses);
        session.setAttribute("newTokenUserId", userId);
        session.setAttribute("newTokenHint", hint);
    }

    private String buildMagicLink(HttpServletRequest request, String rawToken) {
        String baseUrl = System.getenv("APP_BASE_URL");
        if (baseUrl == null || baseUrl.isBlank()) {
            String scheme = request.getScheme();
            String host = request.getHeader("Host");
            if (host == null || host.isBlank()) {
                host = request.getServerName() + ":" + request.getServerPort();
            }
            baseUrl = scheme + "://" + host;
        }
        if (baseUrl.endsWith("/")) {
            baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
        }
        return baseUrl + request.getContextPath() + "/AccessServlet?t="
                + URLEncoder.encode(rawToken, StandardCharsets.UTF_8);
    }

    private Timestamp parseExpiresAt(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Timestamp.valueOf(LocalDateTime.parse(value.trim()));
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private Integer parseMaxUses(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Integer.valueOf(value.trim());
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
