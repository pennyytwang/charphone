package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.AccessToken;

/**
 * 存取 token 的資料存取層。
 * 只處理 CRUD 與原子計數，不包含登入流程或商業規則。
 */
public class AccessTokenDao extends BaseDao {

    private static final Logger LOGGER = Logger.getLogger(AccessTokenDao.class.getName());

    private static final String COLUMNS =
            "id, user_id, token_hash, token_hint, label, scopes, expires_at, max_uses, "
            + "used_count, last_used_at, last_used_ip, revoked_at, created_by, created_at";

    /**
     * 新增 token，回傳新資料列 id；失敗回傳 -1。
     */
    public int insert(int userId, String tokenHash, String tokenHint, String label,
                      String scopes, Timestamp expiresAt, Integer maxUses, Integer createdBy) {
        try (Connection conn = getConnection()) {
            return insert(conn, userId, tokenHash, tokenHint, label, scopes, expiresAt, maxUses, createdBy);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to insert access token", e);
            return -1;
        }
    }

    /**
     * 在同一個交易中撤銷舊 token 並建立新 token。
     *
     * @return 新 token id；失敗回傳 -1（舊 token 不會被撤銷）
     */
    public int regenerate(int oldId, int userId, String tokenHash, String tokenHint, String label,
                          String scopes, Timestamp expiresAt, Integer maxUses, Integer createdBy) {
        String sql = "UPDATE access_tokens SET revoked_at = NOW() WHERE id = ? AND revoked_at IS NULL";
        try (Connection conn = getConnection()) {
            boolean autoCommit = conn.getAutoCommit();
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, oldId);
                    ps.executeUpdate();
                }
                int newId = insert(conn, userId, tokenHash, tokenHint, label, scopes, expiresAt, maxUses, createdBy);
                if (newId < 0) {
                    conn.rollback();
                    return -1;
                }
                conn.commit();
                return newId;
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(autoCommit);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to regenerate access token", e);
            return -1;
        }
    }

    private int insert(Connection conn, int userId, String tokenHash, String tokenHint, String label,
                       String scopes, Timestamp expiresAt, Integer maxUses, Integer createdBy)
            throws java.sql.SQLException {
        String sql = "INSERT INTO access_tokens "
                + "(user_id, token_hash, token_hint, label, scopes, expires_at, max_uses, created_by) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, userId);
            ps.setString(2, tokenHash);
            ps.setString(3, tokenHint);
            ps.setString(4, label);
            ps.setString(5, scopes);
            ps.setTimestamp(6, expiresAt);
            if (maxUses == null) {
                ps.setNull(7, java.sql.Types.INTEGER);
            } else {
                ps.setInt(7, maxUses);
            }
            if (createdBy == null) {
                ps.setNull(8, java.sql.Types.INTEGER);
            } else {
                ps.setInt(8, createdBy);
            }
            if (ps.executeUpdate() == 0) {
                return -1;
            }
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : -1;
            }
        }
    }

    public AccessToken findByHash(String tokenHash) {
        String sql = "SELECT " + COLUMNS + " FROM access_tokens WHERE token_hash = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tokenHash);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to find access token by hash", e);
            return null;
        }
    }

    public AccessToken findById(int id) {
        String sql = "SELECT " + COLUMNS + " FROM access_tokens WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to find access token by id", e);
            return null;
        }
    }

    /**
     * 原子遞增使用次數；只有未撤銷、未到期、次數未滿時才會成功。
     */
    public boolean consume(int id, String ip) {
        String sql = "UPDATE access_tokens SET used_count = used_count + 1, "
                + "last_used_at = NOW(), last_used_ip = ? "
                + "WHERE id = ? AND revoked_at IS NULL AND expires_at > NOW() "
                + "AND (max_uses IS NULL OR used_count < max_uses)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, truncate(ip, 45));
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to consume access token", e);
            return false;
        }
    }

    public List<AccessToken> listByUser(int userId) {
        List<AccessToken> list = new ArrayList<>();
        String sql = "SELECT " + COLUMNS + " FROM access_tokens WHERE user_id = ? ORDER BY id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to list access tokens", e);
        }
        return list;
    }

    public boolean revoke(int id) {
        String sql = "UPDATE access_tokens SET revoked_at = NOW() WHERE id = ? AND revoked_at IS NULL";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to revoke access token", e);
            return false;
        }
    }

    public boolean revokeAllForUser(int userId) {
        String sql = "UPDATE access_tokens SET revoked_at = NOW() WHERE user_id = ? AND revoked_at IS NULL";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to revoke access tokens for user", e);
            return false;
        }
    }

    private AccessToken map(ResultSet rs) throws java.sql.SQLException {
        AccessToken t = new AccessToken();
        t.setId(rs.getInt("id"));
        t.setUserId(rs.getInt("user_id"));
        t.setTokenHint(rs.getString("token_hint"));
        t.setLabel(rs.getString("label"));
        t.setScopes(rs.getString("scopes"));
        t.setExpiresAt(rs.getTimestamp("expires_at"));
        int maxUses = rs.getInt("max_uses");
        t.setMaxUses(rs.wasNull() ? null : maxUses);
        t.setUsedCount(rs.getInt("used_count"));
        t.setLastUsedAt(rs.getTimestamp("last_used_at"));
        t.setLastUsedIp(rs.getString("last_used_ip"));
        t.setRevokedAt(rs.getTimestamp("revoked_at"));
        int createdBy = rs.getInt("created_by");
        t.setCreatedBy(rs.wasNull() ? null : createdBy);
        t.setCreatedAt(rs.getTimestamp("created_at"));
        return t;
    }

    private String truncate(String value, int maxLength) {
        if (value == null) {
            return null;
        }
        return value.length() <= maxLength ? value : value.substring(0, maxLength);
    }
}
