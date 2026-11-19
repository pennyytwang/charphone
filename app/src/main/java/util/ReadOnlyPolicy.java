package util;

import java.util.Map;
import java.util.Set;

/**
 * 唯讀帳號的請求白名單。
 *
 * <p>本系統有多個「用 GET 執行寫入」的路徑（例如
 * {@code OrderServlet?action=delete}），因此不能只用 HTTP method 判斷，
 * 必須以路徑 + action 白名單放行。</p>
 */
public final class ReadOnlyPolicy {

    private static final Map<String, Set<String>> ALLOWED_ACTIONS = Map.of(
            "/OrderServlet", Set.of("get"),
            "/CustomerServlet", Set.of("get"),
            "/ProductServlet", Set.of("get"),
            "/DeliveryServlet", Set.of("getDelivery", "getOrders"),
            "/ProductionServlet", Set.of("get")
    );

    private static final Set<String> ALLOWED_SERVLETS = Set.of(
            "/LogoutServlet",
            "/DashboardDataServlet",
            "/ShippingCheckServlet",
            "/AiProxyServlet"
    );

    private ReadOnlyPolicy() {}

    /**
     * 判斷唯讀帳號是否可存取此請求。
     *
     * @param path   去除 context path 後的路徑
     * @param method HTTP method
     * @param action 查詢參數 action
     * @return true 表示允許
     */
    public static boolean isAllowed(String path, String method, String action) {
        if (path == null) {
            return false;
        }
        if (path.equals("/api/v1") || path.startsWith("/api/v1/")) {
            return true;
        }
        if (!"GET".equalsIgnoreCase(method)) {
            return false;
        }
        if (path.isEmpty() || "/".equals(path) || "/index.jsp".equals(path)) {
            return true;
        }
        if (path.startsWith("/user/") || "/UserServlet".equals(path) || "/TokenAdminServlet".equals(path)) {
            return false;
        }
        if ("/production/receipt.jsp".equals(path) || "/production/receipt_reverse.jsp".equals(path)) {
            return false;
        }
        if (path.endsWith(".jsp")) {
            String file = path.substring(path.lastIndexOf('/') + 1);
            return !file.startsWith("add_") && !file.startsWith("edit_");
        }
        if ("/favicon.ico".equals(path) || "/robots.txt".equals(path)) {
            return true;
        }
        if (ALLOWED_SERVLETS.contains(path)) {
            return true;
        }
        Set<String> actions = ALLOWED_ACTIONS.get(path);
        return actions != null && action != null && actions.contains(action);
    }
}
