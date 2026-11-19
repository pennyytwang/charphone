package util;

/**
 * HTML 與 JavaScript 字串跳脫工具。
 */
public final class HtmlUtil {

    private HtmlUtil() {
    }

    /**
     * 跳脫 HTML 文字內容與屬性值。
     */
    public static String escape(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    /**
     * 跳脫單引號包覆的 JavaScript 字串。
     */
    public static String escapeJs(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\")
                .replace("'", "\\'")
                .replace("\r", "\\r")
                .replace("\n", "\\n")
                .replace("</", "<\\/");
    }
}
