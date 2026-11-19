package util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * 存取 token 的產生、雜湊與比對工具。
 *
 * <p>Token 明文格式為 {@code cp_} + 32 bytes 隨機值的 Base64URL，
 * 資料庫僅儲存 SHA-256（可選擇加上 TOKEN_PEPPER）後的 hex 值。</p>
 */
public final class TokenUtil {

    private static final String PREFIX = "cp_";
    private static final int TOKEN_BYTES = 32;
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final char[] HEX = "0123456789abcdef".toCharArray();
    private static final String PEPPER = System.getenv("TOKEN_PEPPER");

    private TokenUtil() {}

    /**
     * 產生新的 token 明文。此值只應顯示一次，不可寫入日誌。
     *
     * @return 例如 {@code cp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx}
     */
    public static String generate() {
        byte[] bytes = new byte[TOKEN_BYTES];
        RANDOM.nextBytes(bytes);
        return PREFIX + Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /**
     * 計算 token 的儲存用雜湊值。
     *
     * @param rawToken token 明文
     * @return 64 字元 hex 字串
     */
    public static String hash(String rawToken) {
        if (rawToken == null) {
            throw new IllegalArgumentException("token 不可為空");
        }
        String value = (PEPPER == null || PEPPER.isBlank()) ? rawToken : PEPPER + rawToken;
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            return toHex(hashed);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 不可用", e);
        }
    }

    /**
     * 產生給管理介面顯示的 token 提示，例如 {@code cp_ab12…9f3c}。
     *
     * @param rawToken token 明文
     * @return 遮罩後的提示字串
     */
    public static String hint(String rawToken) {
        if (rawToken == null || rawToken.length() < PREFIX.length() + 12) {
            return PREFIX + "…";
        }
        String body = rawToken.substring(PREFIX.length());
        return PREFIX + body.substring(0, 4) + "…" + body.substring(body.length() - 4);
    }

    /**
     * 基本格式檢查，避免對明顯無效的輸入查詢資料庫。
     *
     * @param rawToken token 明文
     * @return 格式是否合理
     */
    public static boolean looksValid(String rawToken) {
        if (rawToken == null) {
            return false;
        }
        String trimmed = rawToken.trim();
        return trimmed.length() >= 24
                && trimmed.length() <= 100
                && trimmed.startsWith(PREFIX);
    }

    /**
     * 常數時間字串比對，避免 timing attack。
     */
    public static boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null) {
            return false;
        }
        return MessageDigest.isEqual(a.getBytes(StandardCharsets.UTF_8), b.getBytes(StandardCharsets.UTF_8));
    }

    private static String toHex(byte[] bytes) {
        char[] chars = new char[bytes.length * 2];
        for (int i = 0; i < bytes.length; i++) {
            int v = bytes[i] & 0xFF;
            chars[i * 2] = HEX[v >>> 4];
            chars[i * 2 + 1] = HEX[v & 0x0F];
        }
        return new String(chars);
    }
}
