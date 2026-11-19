package servlet;

import java.io.IOException;
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
import dao.UserDao;
import model.User;

@WebServlet("/UserServlet")
public class UserServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(UserServlet.class.getName());

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
        String idParam = request.getParameter("id");
        String contextPath = request.getContextPath();

        try {
            if ("delete".equals(action) && idParam != null) {
                int targetId = Integer.parseInt(idParam);
                if (targetId == currentUser.getId()) {
                    response.sendRedirect(contextPath + "/user/user_list.jsp?error=self_delete");
                    return;
                }
                boolean success = new UserDao().deleteUser(targetId);
                response.sendRedirect(contextPath + "/user/user_list.jsp?"
                        + (success ? "message=success" : "error=delete_failed"));
                return;
            }

            String username = trim(request.getParameter("username"));
            String displayName = trim(request.getParameter("displayName"));
            String role = request.getParameter("role");
            String accountType = request.getParameter("accountType");
            boolean active = !"0".equals(request.getParameter("isActive"))
                    && !"false".equalsIgnoreCase(request.getParameter("isActive"));
            boolean readOnly = "on".equals(request.getParameter("readOnly"))
                    || "true".equalsIgnoreCase(request.getParameter("readOnly"));
            Timestamp expiresAt = parseTimestamp(request.getParameter("expiresAt"));

            if (!"temporary".equals(accountType)) {
                accountType = "normal";
            }
            if (!"admin".equals(role)) {
                role = "user";
            }
            if ("temporary".equals(accountType)) {
                readOnly = true;
                role = "user";
                if (expiresAt == null) {
                    redirectError(response, contextPath, idParam, "expiry_required");
                    return;
                }
                if (expiresAt.getTime() <= System.currentTimeMillis()) {
                    redirectError(response, contextPath, idParam, "expiry_past");
                    return;
                }
            } else {
                expiresAt = null;
            }
            if (username == null || username.isEmpty()) {
                redirectError(response, contextPath, idParam, "username_required");
                return;
            }
            if (username.length() > 50) {
                redirectError(response, contextPath, idParam, "username_too_long");
                return;
            }
            if (displayName != null && displayName.length() > 100) {
                redirectError(response, contextPath, idParam, "display_too_long");
                return;
            }

            UserDao dao = new UserDao();
            boolean success;

            if (idParam != null && !idParam.isEmpty()) {
                int userId = Integer.parseInt(idParam);
                if (userId == currentUser.getId()) {
                    if (!active) {
                        redirectError(response, contextPath, idParam, "self_deactivate");
                        return;
                    }
                    if (!"admin".equals(role)) {
                        redirectError(response, contextPath, idParam, "self_demote");
                        return;
                    }
                }
                if (dao.isUsernameTaken(username, userId)) {
                    response.sendRedirect(contextPath + "/user/edit_user.jsp?id=" + userId + "&error=duplicate");
                    return;
                }
                User u = new User();
                u.setId(userId);
                u.setUsername(username);
                u.setDisplayName(displayName);
                u.setRole(role);
                u.setAccountType(accountType);
                u.setExpiresAt(expiresAt);
                u.setActive(active);
                u.setReadOnly(readOnly);
                success = dao.updateUser(u);

                String password = request.getParameter("password");
                if (success && password != null && !password.trim().isEmpty()) {
                    success = dao.updatePassword(userId, password);
                }
            } else {
                if (dao.isUsernameTaken(username, null)) {
                    response.sendRedirect(contextPath + "/user/add_user.jsp?error=duplicate");
                    return;
                }
                String password = request.getParameter("password");
                if (!"temporary".equals(accountType) && (password == null || password.trim().isEmpty())) {
                    response.sendRedirect(contextPath + "/user/add_user.jsp?error=password_required");
                    return;
                }
                User u = new User();
                u.setUsername(username);
                u.setPassword(password);
                u.setDisplayName(displayName);
                u.setRole(role);
                u.setAccountType(accountType);
                u.setExpiresAt(expiresAt);
                u.setActive(active);
                u.setReadOnly(readOnly);
                u.setCreatedBy(currentUser.getId());
                success = dao.insertUser(u);
            }

            if (success) {
                response.sendRedirect(contextPath + "/user/user_list.jsp?message=success");
            } else {
                redirectError(response, contextPath, idParam, "failed");
            }
        } catch (NumberFormatException e) {
            response.sendRedirect(contextPath + "/user/user_list.jsp?error=invalid");
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to save user", e);
            redirectError(response, contextPath, idParam, "exception");
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/user/user_list.jsp");
    }

    private void redirectError(HttpServletResponse response, String contextPath, String idParam,
                               String error) throws IOException {
        if (idParam != null && !idParam.isEmpty()) {
            response.sendRedirect(contextPath + "/user/edit_user.jsp?id=" + idParam + "&error=" + error);
        } else {
            response.sendRedirect(contextPath + "/user/add_user.jsp?error=" + error);
        }
    }

    private Timestamp parseTimestamp(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Timestamp.valueOf(LocalDateTime.parse(value.trim()));
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
