package util;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.sql.Timestamp;
import model.User;

/**
 * 建立已驗證 session 的共用邏輯。
 *
 * <p>一律先 invalidate 舊 session 再建立新的，避免 Session Fixation。</p>
 */
public final class AuthSession {

    private static final int DEFAULT_TIMEOUT_SECONDS = 8 * 60 * 60;

    private AuthSession() {}

    public static HttpSession create(HttpServletRequest request, User user,
                                     String authMethod, Integer tokenId,
                                     Timestamp tokenExpiresAt) {
        HttpSession old = request.getSession(false);
        if (old != null) {
            try {
                old.invalidate();
            } catch (IllegalStateException ignored) {
            }
        }
        HttpSession session = request.getSession(true);

        boolean readOnly = user.isReadOnly() || user.isTemporary();
        session.setAttribute("user", user);
        session.setAttribute("readOnly", readOnly);
        session.setAttribute("authMethod", authMethod);
        if (tokenId != null) {
            session.setAttribute("tokenId", tokenId);
        }
        if (tokenExpiresAt != null) {
            session.setAttribute("tokenExpiresAt", tokenExpiresAt);
        }
        if (user.getExpiresAt() != null) {
            session.setAttribute("userExpiresAt", user.getExpiresAt());
        }

        session.setMaxInactiveInterval(calculateTimeout(user, tokenExpiresAt));
        return session;
    }

    private static int calculateTimeout(User user, Timestamp tokenExpiresAt) {
        long now = System.currentTimeMillis();
        long timeoutMillis = DEFAULT_TIMEOUT_SECONDS * 1000L;

        if (tokenExpiresAt != null) {
            timeoutMillis = Math.min(timeoutMillis, tokenExpiresAt.getTime() - now);
        }
        if (user.getExpiresAt() != null) {
            timeoutMillis = Math.min(timeoutMillis, user.getExpiresAt().getTime() - now);
        }
        if (timeoutMillis <= 0) {
            return 1;
        }
        return (int) Math.min(Integer.MAX_VALUE, timeoutMillis / 1000L);
    }
}
