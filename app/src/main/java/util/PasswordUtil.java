package util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import org.mindrot.jbcrypt.BCrypt;

/**
 * 密碼雜湊工具類。
 *
 * <p>新密碼一律使用 BCrypt；舊資料（SHA-256 + 固定 salt）仍可驗證，
 * 登入成功後由 UserDao 自動升級為 BCrypt。</p>
 */
public class PasswordUtil {

    private static final String LEGACY_DELIMITER = ":";
    private static final String LEGACY_APP_SALT = "demo_legacy_salt";
    private static final int BCRYPT_COST = 12;

    private PasswordUtil() {}

    /**
     * 產生 BCrypt 雜湊值。
     *
     * @param plainPassword 明文密碼
     * @return BCrypt 雜湊字串
     */
    public static String hash(String plainPassword) {
        if (plainPassword == null || plainPassword.isEmpty()) {
            throw new IllegalArgumentException("密碼不可為空");
        }
        return BCrypt.hashpw(plainPassword, BCrypt.gensalt(BCRYPT_COST));
    }

    /**
     * 驗證明文密碼。支援 BCrypt 與舊版 salted SHA-256 格式。
     *
     * @param plainPassword  明文密碼
     * @param hashedPassword 資料庫中的雜湊值
     * @return true 如果密碼相符
     */
    public static boolean verify(String plainPassword, String hashedPassword) {
        if (plainPassword == null || hashedPassword == null) {
            return false;
        }
        if (isBcrypt(hashedPassword)) {
            try {
                return BCrypt.checkpw(plainPassword, hashedPassword);
            } catch (IllegalArgumentException e) {
                return false;
            }
        }
        return verifyLegacy(plainPassword, hashedPassword);
    }

    /**
     * 判斷是否為舊格式，登入成功後應重新雜湊。
     */
    public static boolean needsRehash(String hashedPassword) {
        return hashedPassword != null && !isBcrypt(hashedPassword);
    }

    /**
     * 判斷密碼是否已經是支援的雜湊格式。
     */
    public static boolean isHashed(String password) {
        if (password == null) {
            return false;
        }
        if (isBcrypt(password)) {
            return true;
        }
        String[] parts = password.split(LEGACY_DELIMITER, 2);
        if (parts.length != 2) {
            return false;
        }
        try {
            Base64.getDecoder().decode(parts[0]);
            Base64.getDecoder().decode(parts[1]);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private static boolean isBcrypt(String value) {
        return value.startsWith("$2a$") || value.startsWith("$2b$") || value.startsWith("$2y$");
    }

    private static boolean verifyLegacy(String plainPassword, String hashedPassword) {
        try {
            String[] parts = hashedPassword.split(LEGACY_DELIMITER, 2);
            if (parts.length != 2) {
                return false;
            }
            byte[] expectedHash = Base64.getDecoder().decode(parts[1]);
            byte[] actualHash = legacySha256(plainPassword);
            return MessageDigest.isEqual(expectedHash, actualHash);
        } catch (Exception e) {
            return false;
        }
    }

    private static byte[] legacySha256(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(LEGACY_APP_SALT.getBytes(StandardCharsets.UTF_8));
            return md.digest(password.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 不可用", e);
        }
    }
}
