package dao;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import util.DemoContext;

public abstract class BaseDao {

    private static final String DB_URL = requireEnv("DB_URL");
    private static final String DB_USER = requireEnv("DB_USER");
    private static final String DB_PASS = requireEnv("DB_PASS");
    private static final String DB_RO_USER = requireEnv("DB_RO_USER");
    private static final String DB_RO_PASS = requireEnv("DB_RO_PASS");

    private static final HikariDataSource dataSource;
    private static final HikariDataSource readOnlyDataSource;

    static {
        dataSource = buildDataSource(DB_URL, DB_USER, DB_PASS, 10, 2);
        readOnlyDataSource = buildDataSource(DB_URL, DB_RO_USER, DB_RO_PASS, 5, 1);
    }

    public static Connection getConnection() throws SQLException {
        return DemoContext.isReadOnly()
                ? readOnlyDataSource.getConnection()
                : dataSource.getConnection();
    }

    private static HikariDataSource buildDataSource(String url, String user, String pass,
                                                    int maxPoolSize, int minIdle) {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(url);
        config.setUsername(user);
        config.setPassword(pass);
        config.setMaximumPoolSize(maxPoolSize);
        config.setMinimumIdle(minIdle);
        config.setConnectionTimeout(30000);
        config.setIdleTimeout(600000);
        config.setMaxLifetime(1800000);
        config.setPoolName("charphone-" + user);
        config.addDataSourceProperty("useSSL", "false");
        config.addDataSourceProperty("allowPublicKeyRetrieval", "true");
        config.addDataSourceProperty("serverTimezone", "UTC");
        config.addDataSourceProperty("characterEncoding", "utf-8");
        config.addDataSourceProperty("useUnicode", "true");
        return new HikariDataSource(config);
    }

    private static String requireEnv(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("環境變數 " + key +
                " 未設定，無法建立資料庫連線；請由 docker-compose 注入 DB_URL / DB_USER / DB_PASS / DB_RO_USER / DB_RO_PASS 後再啟動");
        }
        return value;
    }
}
