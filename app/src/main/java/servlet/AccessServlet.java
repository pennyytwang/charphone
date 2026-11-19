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
 * Magic Link 登入。
 *
 * <p>GET 只顯示確認頁，避免 Email/通訊軟體預覽連結時誤消耗 token；
 * 使用者按下確認後才以 POST 兌換 session。</p>
 */
@WebServlet("/AccessServlet")
public class AccessServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        noStore(response);
        String rawToken = request.getParameter("t");
        if (rawToken == null || rawToken.trim().isEmpty()) {
            response.sendRedirect("login.jsp");
            return;
        }
        request.setAttribute("token", rawToken.trim());
        request.getRequestDispatcher("/token_confirm.jsp").forward(request, response);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");
        noStore(response);

        String rawToken = request.getParameter("token");
        String ip = RequestUtil.clientIp(request);
        String userAgent = RequestUtil.userAgent(request);

        if (rawToken == null || rawToken.trim().isEmpty()) {
            response.sendRedirect("login.jsp?tab=token&error=token_invalid");
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

    private void noStore(HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-store");
        response.setHeader("Pragma", "no-cache");
        response.setHeader("Referrer-Policy", "no-referrer");
    }
}
