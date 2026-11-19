package servlet;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import dao.LoginAuditDao;
import dao.UserDao;
import model.User;
import util.AuthSession;
import util.RequestUtil;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        if (username == null || password == null || username.trim().isEmpty() || password.trim().isEmpty()) {
            response.sendRedirect("login.jsp?error=empty");
            return;
        }

        String trimmedUsername = username.trim();
        String ip = RequestUtil.clientIp(request);
        String userAgent = RequestUtil.userAgent(request);
        UserDao dao = new UserDao();
        LoginAuditDao auditDao = new LoginAuditDao();
        User user = dao.authenticate(trimmedUsername, password);

        if (user != null) {
            AuthSession.create(request, user, "password", null, null);
            auditDao.record(user.getId(), trimmedUsername, null, "password", true, null, ip, userAgent);
            response.sendRedirect("index.jsp");
        } else {
            auditDao.record(null, trimmedUsername, null, "password", false, "bad_credentials", ip, userAgent);
            response.sendRedirect("login.jsp?error=failed");
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.sendRedirect("login.jsp");
    }
}
