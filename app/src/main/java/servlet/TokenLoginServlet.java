package servlet;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import dao.LoginAuditDao;
import model.AccessToken;
import service.TokenAuthService;
import util.AuthSession;
import util.RequestUtil;

/**
 * 手動輸入存取碼登入。
 */
@WebServlet("/TokenLoginServlet")
public class TokenLoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");
        noStore(response);

        String rawToken = request.getParameter("token");
        String ip = RequestUtil.clientIp(request);
        String userAgent = RequestUtil.userAgent(request);

        if (rawToken == null || rawToken.trim().isEmpty()) {
            response.sendRedirect("login.jsp?tab=token&error=token_empty");
            return;
        }

        TokenAuthService service = new TokenAuthService();
        TokenAuthService.Result result = service.authenticate(rawToken, ip);
        LoginAuditDao auditDao = new LoginAuditDao();

        if (result.isSuccess()) {
            AccessToken token = result.getToken();
            AuthSession.create(request, result.getUser(), "token", token.getId(), token.getExpiresAt());
            auditDao.record(result.getUser().getId(), null, result.getTokenHint(),
                    "token", true, null, ip, userAgent);
            response.sendRedirect("index.jsp");
            return;
        }

        Integer userId = result.getToken() == null ? null : result.getToken().getUserId();
        auditDao.record(userId, null, result.getTokenHint(), "token", false,
                result.getReason(), ip, userAgent);
        response.sendRedirect("login.jsp?tab=token&error=token_invalid");
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.sendRedirect("login.jsp?tab=token");
    }

    private void noStore(HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-store");
        response.setHeader("Pragma", "no-cache");
    }
}
