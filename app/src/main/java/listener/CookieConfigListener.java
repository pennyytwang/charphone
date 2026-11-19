package listener;

import jakarta.servlet.ServletContext;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.SessionCookieConfig;
import jakarta.servlet.annotation.WebListener;

/**
 * 依部署環境設定 session cookie 的 Secure 屬性。
 *
 * <p>本機開發走 HTTP 時不能加 Secure，否則瀏覽器不會回傳 cookie；
 * 正式環境設定 APP_BASE_URL=https://... 後自動啟用 Secure。</p>
 */
@WebListener
public class CookieConfigListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        ServletContext context = sce.getServletContext();
        SessionCookieConfig cookie = context.getSessionCookieConfig();
        cookie.setHttpOnly(true);
        String baseUrl = System.getenv("APP_BASE_URL");
        cookie.setSecure(baseUrl != null && baseUrl.startsWith("https://"));
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
    }
}
