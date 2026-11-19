package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import model.AiUiConfig;
import model.AiUiTab;

/**
 * 企業AI 頁面內容設定的資料存取。
 */
public class AiUiDao extends BaseDao {

    private static final Logger LOGGER = Logger.getLogger(AiUiDao.class.getName());

    private static final String LOAD_SETTINGS_SQL =
            "SELECT setting_key, setting_value FROM ai_ui_setting";
    private static final String LOAD_TABS_SQL =
            "SELECT id, label, href, target, active_key, sort_order, visible FROM ai_ui_tab ORDER BY sort_order, id";
    private static final String UPSERT_SETTING_SQL =
            "INSERT INTO ai_ui_setting (setting_key, setting_value, updated_by) VALUES (?, ?, ?) "
            + "ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), updated_by = VALUES(updated_by)";
    private static final String DELETE_TABS_SQL = "DELETE FROM ai_ui_tab";
    private static final String INSERT_TAB_SQL =
            "INSERT INTO ai_ui_tab (label, href, target, active_key, sort_order, visible) VALUES (?, ?, ?, ?, ?, ?)";
    private static final String DELETE_SETTINGS_SQL = "DELETE FROM ai_ui_setting";

    /**
     * 載入設定；資料表尚未建立或查詢失敗時回傳預設值。
     */
    public AiUiConfig load() {
        AiUiConfig config = AiUiConfig.defaults();
        try (Connection conn = getConnection()) {
            loadSettings(conn, config);
            List<AiUiTab> tabs = loadTabs(conn);
            if (!tabs.isEmpty()) {
                config.setTabs(tabs);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "載入 AI 頁面設定失敗，使用預設值", e);
        }
        return config;
    }

    /**
     * 儲存設定與頁籤。
     *
     * @return true 表示儲存成功
     */
    public boolean save(AiUiConfig config, int userId) {
        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);
            try {
                upsertSettings(conn, config.values(), userId);
                replaceTabs(conn, config.getTabs());
                conn.commit();
                return true;
            } catch (SQLException e) {
                rollbackQuietly(conn);
                throw e;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "儲存 AI 頁面設定失敗", e);
            return false;
        }
    }

    /**
     * 刪除自訂設定，回覆程式內建預設值。
     */
    public boolean reset() {
        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement tabs = conn.prepareStatement(DELETE_TABS_SQL);
                 PreparedStatement settings = conn.prepareStatement(DELETE_SETTINGS_SQL)) {
                tabs.executeUpdate();
                settings.executeUpdate();
                conn.commit();
                return true;
            } catch (SQLException e) {
                rollbackQuietly(conn);
                throw e;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "重設 AI 頁面設定失敗", e);
            return false;
        }
    }

    private void loadSettings(Connection conn, AiUiConfig config) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(LOAD_SETTINGS_SQL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                config.set(rs.getString("setting_key"), rs.getString("setting_value"));
            }
        }
    }

    private List<AiUiTab> loadTabs(Connection conn) throws SQLException {
        List<AiUiTab> tabs = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(LOAD_TABS_SQL);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                AiUiTab tab = new AiUiTab();
                tab.setId(rs.getInt("id"));
                tab.setLabel(rs.getString("label"));
                tab.setHref(rs.getString("href"));
                tab.setTarget(rs.getString("target"));
                tab.setActiveKey(rs.getString("active_key"));
                tab.setSortOrder(rs.getInt("sort_order"));
                tab.setVisible(rs.getBoolean("visible"));
                tabs.add(tab);
            }
        }
        return tabs;
    }

    private void upsertSettings(Connection conn, Map<String, String> values, int userId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(UPSERT_SETTING_SQL)) {
            for (Map.Entry<String, String> entry : values.entrySet()) {
                ps.setString(1, entry.getKey());
                ps.setString(2, entry.getValue());
                ps.setInt(3, userId);
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private void replaceTabs(Connection conn, List<AiUiTab> tabs) throws SQLException {
        try (PreparedStatement delete = conn.prepareStatement(DELETE_TABS_SQL)) {
            delete.executeUpdate();
        }
        try (PreparedStatement insert = conn.prepareStatement(INSERT_TAB_SQL)) {
            int order = 0;
            for (AiUiTab tab : tabs) {
                insert.setString(1, tab.getLabel());
                insert.setString(2, tab.getHref());
                insert.setString(3, tab.getTarget());
                insert.setString(4, tab.getActiveKey());
                insert.setInt(5, order++);
                insert.setBoolean(6, tab.isVisible());
                insert.addBatch();
            }
            insert.executeBatch();
        }
    }

    private void rollbackQuietly(Connection conn) {
        try {
            conn.rollback();
        } catch (SQLException ignored) {
        }
    }
}
