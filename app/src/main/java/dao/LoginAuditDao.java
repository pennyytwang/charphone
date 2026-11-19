package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 登入稽核紀錄。只記錄必要欄位，token 一律只存 hint，不存明文。
 */
public class LoginAuditDao extends BaseDao {

    private static final Logger LOGGER = Logger.getLogger(LoginAuditDao.class.getName());

    public void record(Integer userId, String attemptedUsername, String tokenHint,
                       String authMethod, boolean success, String reason,
                       String ip, String userAgent) {
        String sql = "INSERT INTO login_audit "
                + "(user_id, attempted_username, token_hint, auth_method, result, reason, ip, user_agent) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (userId == null) {
                ps.setNull(1, java.sql.Types.INTEGER);
            } else {
                ps.setInt(1, userId);
            }
            ps.setString(2, truncate(attemptedUsername, 50));
            ps.setString(3, truncate(tokenHint, 20));
            ps.setString(4, truncate(authMethod, 20));
            ps.setString(5, success ? "success" : "failed");
            ps.setString(6, truncate(reason, 100));
            ps.setString(7, truncate(ip, 45));
            ps.setString(8, truncate(userAgent, 255));
            ps.executeUpdate();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to record login audit", e);
        }
    }

    private String truncate(String value, int maxLength) {
        if (value == null) {
            return null;
        }
        return value.length() <= maxLength ? value : value.substring(0, maxLength);
    }
}
