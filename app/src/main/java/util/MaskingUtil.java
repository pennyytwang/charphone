package util;

/**
 * 唯讀 Demo 模式的敏感資料遮罩工具。
 * 只遮蔽客戶 PII，不遮蔽金額與數量，避免儀表板數字不一致。
 */
public final class MaskingUtil {

    private static final String MASK = "***";

    private MaskingUtil() {}

    public static String maskTaxId(String value) {
        if (isBlank(value)) {
            return value;
        }
        String v = value.trim();
        if (v.length() <= 3) {
            return MASK;
        }
        return v.substring(0, 3) + "*****";
    }

    public static String maskPhone(String value) {
        if (isBlank(value)) {
            return value;
        }
        String v = value.trim();
        int dash = v.indexOf('-');
        if (dash > 0) {
            return v.substring(0, dash + 1) + "******";
        }
        if (v.length() <= 4) {
            return MASK;
        }
        return v.substring(0, 4) + "****";
    }

    public static String maskPersonName(String value) {
        if (isBlank(value)) {
            return value;
        }
        String v = value.trim();
        return v.substring(0, 1) + "**";
    }

    public static String maskAddress(String value) {
        if (isBlank(value)) {
            return value;
        }
        String v = value.trim();
        if (v.length() <= 3) {
            return MASK;
        }
        return v.substring(0, 3) + MASK;
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
