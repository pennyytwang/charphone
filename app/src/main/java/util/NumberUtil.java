package util;

import java.math.BigDecimal;
import java.text.DecimalFormat;

public final class NumberUtil {

    private static final DecimalFormat COMMA = new DecimalFormat("#,##0.##");

    private NumberUtil() {}

    /**
     * Format quantity: strip trailing zeros, max 3 decimal places.
     * 12.000 -> "12", 12.30 -> "12.3", 12.345 -> "12.345"
     */
    public static String fmtQty(double value) {
        if (value == (long) value) {
            return String.valueOf((long) value);
        }
        String s = String.format("%.3f", value);
        s = s.replaceFirst("0+$", "").replaceFirst("\\.$", "");
        return s;
    }

    /**
     * Format quantity from BigDecimal: strip trailing zeros.
     */
    public static String fmtQty(BigDecimal value) {
        if (value == null) return "0";
        String s = value.setScale(3, java.math.RoundingMode.HALF_UP).stripTrailingZeros().toPlainString();
        if (s.contains(".") && !s.contains("E")) {
            s = s.replaceFirst("0+$", "").replaceFirst("\\.$", "");
        }
        return s;
    }

    /**
     * Format money: comma-separated, strip trailing zeros.
     * 1200 -> "1,200", 1200.50 -> "1,200.5", 1200.99 -> "1,200.99"
     */
    public static String fmtMoney(BigDecimal value) {
        if (value == null) return "0";
        BigDecimal stripped = value.stripTrailingZeros();
        String plain = stripped.toPlainString();
        if (plain.contains(".")) {
            String[] parts = plain.split("\\.");
            long intPart = Long.parseLong(parts[0]);
            return COMMA.format(intPart) + "." + parts[1];
        }
        long intPart = Long.parseLong(plain);
        return COMMA.format(intPart);
    }

    /**
     * Format money from double.
     */
    public static String fmtMoney(double value) {
        return fmtMoney(BigDecimal.valueOf(value));
    }
}