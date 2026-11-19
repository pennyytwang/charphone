package dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.User;
import util.PasswordUtil;

public class UserDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(UserDao.class.getName());

    private static final String COLUMNS =
            "id, username, password, display_name, role, account_type, expires_at, "
            + "is_active, read_only, created_by";

    public User authenticate(String username, String password) {
        String sql = "SELECT " + COLUMNS + " FROM users "
                + "WHERE username = ? AND is_active = 1 "
                + "AND (expires_at IS NULL OR expires_at > NOW())";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String storedPassword = rs.getString("password");
                    if (storedPassword != null && PasswordUtil.verify(password, storedPassword)) {
                        User u = map(rs, false);
                        if (PasswordUtil.needsRehash(storedPassword)) {
                            updatePassword(u.getId(), password);
                        }
                        return u;
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to authenticate user", e);
        }
        return null;
    }

    public List<User> getAllUsers() {
        List<User> list = new ArrayList<>();
        String sql = "SELECT " + COLUMNS + " FROM users ORDER BY id";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(map(rs, false));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query all users", e);
        }
        return list;
    }

    public User getUserById(int id) {
        String sql = "SELECT " + COLUMNS + " FROM users WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return map(rs, false);
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query user by id", e);
        }
        return null;
    }

    public boolean insertUser(User u) {
        String sql = "INSERT INTO users "
                + "(username, password, display_name, role, account_type, expires_at, is_active, read_only, created_by) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, u.getUsername());
            if (u.getPassword() != null && !u.getPassword().trim().isEmpty()) {
                ps.setString(2, PasswordUtil.hash(u.getPassword()));
            } else {
                ps.setNull(2, Types.VARCHAR);
            }
            ps.setString(3, u.getDisplayName());
            ps.setString(4, u.getRole());
            ps.setString(5, u.getAccountType());
            ps.setTimestamp(6, u.getExpiresAt());
            ps.setBoolean(7, u.isActive());
            ps.setBoolean(8, u.isReadOnly());
            if (u.getCreatedBy() == null) {
                ps.setNull(9, Types.INTEGER);
            } else {
                ps.setInt(9, u.getCreatedBy());
            }
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to insert user", e);
            return false;
        }
    }

    public boolean updateUser(User u) {
        String sql = "UPDATE users SET username=?, display_name=?, role=?, account_type=?, "
                + "expires_at=?, is_active=?, read_only=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, u.getUsername());
            ps.setString(2, u.getDisplayName());
            ps.setString(3, u.getRole());
            ps.setString(4, u.getAccountType());
            ps.setTimestamp(5, u.getExpiresAt());
            ps.setBoolean(6, u.isActive());
            ps.setBoolean(7, u.isReadOnly());
            ps.setInt(8, u.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to update user", e);
            return false;
        }
    }

    public boolean updatePassword(int id, String password) {
        String sql = "UPDATE users SET password=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, PasswordUtil.hash(password));
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to update password", e);
            return false;
        }
    }

    public boolean updateActive(int id, boolean active) {
        String sql = "UPDATE users SET is_active=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setBoolean(1, active);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to update user status", e);
            return false;
        }
    }

    public boolean deleteUser(int id) {
        String sql = "DELETE FROM users WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to delete user", e);
            return false;
        }
    }

    public boolean isUsernameTaken(String username, Integer excludeId) {
        String sql = "SELECT COUNT(*) FROM users WHERE username = ?";
        if (excludeId != null) sql += " AND id != ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            if (excludeId != null) ps.setInt(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to check username availability", e);
            return false;
        }
    }

    private User map(ResultSet rs, boolean includePassword) throws SQLException {
        User u = new User();
        u.setId(rs.getInt("id"));
        u.setUsername(rs.getString("username"));
        if (includePassword) {
            u.setPassword(rs.getString("password"));
        }
        u.setDisplayName(rs.getString("display_name"));
        u.setRole(rs.getString("role"));
        u.setAccountType(rs.getString("account_type"));
        u.setExpiresAt(rs.getTimestamp("expires_at"));
        u.setActive(rs.getBoolean("is_active"));
        u.setReadOnly(rs.getBoolean("read_only"));
        int createdBy = rs.getInt("created_by");
        u.setCreatedBy(rs.wasNull() ? null : createdBy);
        return u;
    }
}
