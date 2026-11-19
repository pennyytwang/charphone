package listener;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.configuration.FluentConfiguration;
import org.flywaydb.core.api.exception.FlywayValidateException;
import util.PasswordUtil;

import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

@WebListener
public class FlywayListener implements ServletContextListener {

    private static final Logger LOGGER = Logger.getLogger(FlywayListener.class.getName());

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        String dbUrl = requireEnv("DB_URL");
        String dbUser = requireEnv("DB_USER");
        String dbPass = requireEnv("DB_PASS");
        requireEnv("DB_RO_USER");
        requireEnv("DB_RO_PASS");

        Map<String, String> placeholders = buildPlaceholders();

        // Retry logic with exponential backoff
        int maxRetries = 10;
        int retryDelayMs = 2000;
        int lastException = 0;
        
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                FluentConfiguration config = Flyway.configure()
                        .dataSource(dbUrl, dbUser, dbPass)
                        .connectRetries(3)
                        .baselineOnMigrate(true)
                        .baselineVersion("0")
                        .placeholders(placeholders);

                Flyway flyway = config.load();
                flyway.migrate();
                LOGGER.info("Flyway migrations completed successfully on attempt " + attempt);
                return;
            } catch (FlywayValidateException e) {
                if (!isChecksumMismatch(e)) {
                    throw e;
                }

                LOGGER.warning("Repairing Flyway schema history after checksum mismatch: " + e.getMessage());
                try {
                    FluentConfiguration config = Flyway.configure()
                            .dataSource(dbUrl, dbUser, dbPass)
                            .connectRetries(3)
                            .baselineOnMigrate(true)
                            .baselineVersion("0")
                            .placeholders(placeholders);
                    
                    Flyway flyway = config.load();
                    flyway.repair();
                    flyway.migrate();
                    LOGGER.info("Flyway migrations completed after repair on attempt " + attempt);
                    return;
                } catch (Exception repairException) {
                    LOGGER.warning("Repair failed on attempt " + attempt + ": " + repairException.getMessage());
                    throw repairException;
                }
            } catch (Exception e) {
                lastException = attempt;
                if (attempt < maxRetries) {
                    long delayMs = retryDelayMs * attempt; // exponential backoff
                    LOGGER.warning("Flyway connection attempt " + attempt + " failed: " + e.getMessage() + 
                                 ". Retrying in " + delayMs + "ms...");
                    try {
                        Thread.sleep(delayMs);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        throw new RuntimeException("Interrupted during Flyway retry", ie);
                    }
                } else {
                    LOGGER.severe("Flyway failed after " + maxRetries + " attempts: " + e.getMessage());
                    throw new RuntimeException("Failed to initialize Flyway after " + maxRetries + " attempts", e);
                }
            }
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
    }

    boolean isChecksumMismatch(Throwable exception) {
        String message = exception.getMessage();
        return message != null && message.toLowerCase().contains("checksum mismatch");
    }

    private Map<String, String> buildPlaceholders() {
        Map<String, String> placeholders = new HashMap<>();
        String adminPassword = System.getenv("ADMIN_PASSWORD");
        if (adminPassword == null || adminPassword.isBlank()) {
            LOGGER.warning("ADMIN_PASSWORD 未設定；空資料庫將建立停用的 admin 帳號");
            placeholders.put("adminPasswordHash", "!");
        } else {
            placeholders.put("adminPasswordHash", PasswordUtil.hash(adminPassword));
        }
        return placeholders;
    }

    private String requireEnv(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("環境變數 " + key +
                " 未設定，無法啟動；請由 docker-compose 注入 DB_URL / DB_USER / DB_PASS / DB_RO_USER / DB_RO_PASS 後再啟動");
        }
        return value;
    }
}
