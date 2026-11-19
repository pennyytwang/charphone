package util;

/**
 * 以 ThreadLocal 傳遞目前請求的 Demo 狀態。
 * AuthFilter 設定，請求結束時務必呼叫 {@link #clear()} 避免執行緒重用造成狀態外洩。
 */
public final class DemoContext {

    private static final ThreadLocal<Boolean> READ_ONLY = new ThreadLocal<>();
    private static final ThreadLocal<Boolean> MASKED = new ThreadLocal<>();

    private DemoContext() {}

    public static void setReadOnly(boolean value) {
        READ_ONLY.set(value);
    }

    public static boolean isReadOnly() {
        return Boolean.TRUE.equals(READ_ONLY.get());
    }

    public static void setMasked(boolean value) {
        MASKED.set(value);
    }

    public static boolean isMasked() {
        return Boolean.TRUE.equals(MASKED.get());
    }

    public static void clear() {
        READ_ONLY.remove();
        MASKED.remove();
    }
}
