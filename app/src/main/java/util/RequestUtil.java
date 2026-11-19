package util;

import jakarta.servlet.http.HttpServletRequest;

/**
 * HTTP 請求相關的小工具。
 */
public final class RequestUtil {

    private RequestUtil() {}

    /**
     * 取得用戶端 IP。
     *
     * <p>本系統位於 nginx 反向代理後方，優先採用 X-Forwarded-For 的第一個值。
     * 僅用於稽核與 rate limit，不作為授權依據。</p>
     */
    public static String clientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            int comma = forwarded.indexOf(',');
            String first = comma > 0 ? forwarded.substring(0, comma) : forwarded;
            return first.trim();
        }
        String realIp = request.getHeader("X-Real-IP");
        if (realIp != null && !realIp.isBlank()) {
            return realIp.trim();
        }
        return request.getRemoteAddr();
    }

    public static String userAgent(HttpServletRequest request) {
        String ua = request.getHeader("User-Agent");
        return ua == null ? null : ua;
    }

    public static boolean isAjax(HttpServletRequest request) {
        return "XMLHttpRequest".equals(request.getHeader("X-Requested-With"));
    }
}
