package servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import dao.InvoiceDao;
import dao.OrderDao;
import model.Order;
import util.NumberUtil;

@WebServlet("/OrderServlet")
@MultipartConfig
public class OrderServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(OrderServlet.class.getName());

    private boolean isAjax(HttpServletRequest req) {
        return "XMLHttpRequest".equals(req.getHeader("X-Requested-With"));
    }

    private void writeJson(HttpServletResponse resp, String json) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().write(json);
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }

    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        String idParam = req.getParameter("id");
        OrderDao dao = new OrderDao();

        if ("get".equals(action) && idParam != null) {
            try {
                Order o = dao.getOrderById(Integer.parseInt(idParam));
                if (o == null) {
                    writeJson(resp, "{\"success\":false,\"error\":\"找不到訂單\"}");
                    return;
                }
                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                SimpleDateFormat dtf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
                String json = String.format(
                    "{\"success\":true,\"id\":%d,\"customerId\":%d,\"customerName\":\"%s\",\"orderNumber\":\"%s\","
                    + "\"productId\":%d,\"productName\":\"%s\",\"priceType\":%d,"
                    + "\"unitPrice\":\"%s\",\"unitWeight\":\"%s\",\"quantity\":\"%s\","
                    + "\"totalAmount\":\"%s\",\"actualAmount\":\"%s\",\"amountDiffReason\":\"%s\","
                    + "\"expectedDeliveryDate\":\"%s\",\"orderDate\":\"%s\","
                    + "\"status\":%d,\"closeStatus\":%d,\"note\":\"%s\","
                    + "\"createdAt\":\"%s\",\"updatedAt\":\"%s\"}",
                    o.getId(), o.getCustomerId(), escapeJson(o.getCustomerName()),
                    escapeJson(o.getOrderNumber()),
                    o.getProductId(), escapeJson(o.getProductName()), o.getPriceType(),
                    o.getUnitPrice() != null ? NumberUtil.fmtQty(o.getUnitPrice().doubleValue()) : "",
                    o.getUnitWeight() != null ? NumberUtil.fmtQty(o.getUnitWeight().doubleValue()) : "",
                    o.getQuantity() != null ? NumberUtil.fmtQty(o.getQuantity().doubleValue()) : "",
                    o.getTotalAmount() != null ? NumberUtil.fmtQty(o.getTotalAmount().doubleValue()) : "",
                    o.getActualAmount() != null ? NumberUtil.fmtQty(o.getActualAmount().doubleValue()) : "",
                    escapeJson(o.getAmountDiffReason()),
                    o.getExpectedDeliveryDate() != null ? sdf.format(o.getExpectedDeliveryDate()) : "",
                    o.getOrderDate() != null ? sdf.format(o.getOrderDate()) : "",
                    o.getStatus(), o.getCloseStatus(),
                    escapeJson(o.getNote()),
                    o.getCreatedAt() != null ? dtf.format(o.getCreatedAt()) : "",
                    o.getUpdatedAt() != null ? dtf.format(o.getUpdatedAt()) : ""
                );
                writeJson(resp, json);
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to get order detail", e);
                writeJson(resp, "{\"success\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}");
            }
            return;
        }

        doPost(req, resp);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        boolean ajax = isAjax(request);
        if (!ajax) response.setContentType("text/html;charset=UTF-8");

        String action = request.getParameter("action");
        String idParam = request.getParameter("id");
        String contextPath = request.getContextPath();
        OrderDao dao = new OrderDao();

        if ("close".equals(action)) {
            try {
                int orderId = Integer.parseInt(idParam);
                Order order = dao.getOrderById(orderId);
                if (order == null) {
                    if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"找不到訂單\"}"); return; }
                    response.sendRedirect(contextPath + "/order/order_list.jsp?error=close_not_found");
                    return;
                }
                BigDecimal orderQty = order.getQuantity();
                BigDecimal deliveredQty = dao.getTotalDelivered(orderId);
                if (deliveredQty.compareTo(orderQty) < 0) {
                    if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"出貨未完成，無法結案\"}"); return; }
                    response.sendRedirect(contextPath + "/order/order_list.jsp?error=close_not_delivered");
                    return;
                }
                InvoiceDao invoiceDao = new InvoiceDao();
                if (!invoiceDao.areAllInvoicesPaid(orderId)) {
                    if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"尚有應收帳款未收款，無法結案\"}"); return; }
                    response.sendRedirect(contextPath + "/order/order_list.jsp?error=close_not_paid");
                    return;
                }
                // 檢查已收款是否全額覆蓋訂單實際應收
                java.math.BigDecimal totalReceived = invoiceDao.getTotalReceivedByOrder(orderId);
                java.math.BigDecimal orderAmount = order.getActualAmount() != null ? order.getActualAmount() : order.getTotalAmount();
                if (totalReceived.compareTo(orderAmount) < 0) {
                    if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"尚有應收帳款未收款，無法結案\"}"); return; }
                    response.sendRedirect(contextPath + "/order/order_list.jsp?error=close_not_paid");
                    return;
                }
                order.setCloseStatus(1);
                dao.updateOrder(order);
                if (ajax) { writeJson(response, "{\"success\":true}"); return; }
                response.sendRedirect(contextPath + "/order/order_list.jsp?message=closed");
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to save order", e);
            if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}"); return; }
                response.sendRedirect(contextPath + "/order/order_list.jsp?error=exception");
            }
            return;
        }

        if ("unclose".equals(action)) {
            try {
                Order order = dao.getOrderById(Integer.parseInt(idParam));
                if (order != null) {
                    order.setCloseStatus(0);
                    dao.updateOrder(order);
                }
                if (ajax) { writeJson(response, "{\"success\":true}"); return; }
                response.sendRedirect(contextPath + "/order/order_list.jsp?message=unclosed");
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to unclose order", e);
                if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}"); return; }
                response.sendRedirect(contextPath + "/order/order_list.jsp?error=exception");
            }
            return;
        }

        if ("delete".equals(action) && idParam != null) {
            try {
                int orderId = Integer.parseInt(idParam);
                Order order = dao.getOrderById(orderId);
                if (order == null) {
                    if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"找不到訂單\"}"); return; }
                    response.sendRedirect(contextPath + "/order/order_list.jsp?error=delete_not_found");
                    return;
                }
                if (order.getCloseStatus() == 1) {
                    String errMsg = "此訂單已結案，無法刪除";
                    if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"" + escapeJson(errMsg) + "\"}"); return; }
                    response.sendRedirect(contextPath + "/order/order_list.jsp?error=delete_has_relations");
                    return;
                }
                String[] labels = { "工單", "出貨紀錄", "帳務紀錄", "庫存異動" };
                int[] counts = {
                    dao.countProductions(orderId),
                    dao.countDeliveries(orderId),
                    dao.countInvoices(orderId),
                    dao.countInventoryTransactions(orderId)
                };
                for (int i = 0; i < counts.length; i++) {
                    if (counts[i] > 0) {
                        String errMsg = "此訂單已有" + labels[i] + "，無法刪除";
                        if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"" + escapeJson(errMsg) + "\"}"); return; }
                        response.sendRedirect(contextPath + "/order/order_list.jsp?error=delete_has_relations");
                        return;
                    }
                }
                dao.deleteOrder(orderId);
                if (ajax) { writeJson(response, "{\"success\":true}"); return; }
                response.sendRedirect(contextPath + "/order/order_list.jsp?message=deleted");
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to delete order", e);
                if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}"); return; }
                response.sendRedirect(contextPath + "/order/order_list.jsp?error=exception");
            }
            return;
        }

        if ("cancel".equals(action)) {
            String orderIdParam = request.getParameter("orderId");
            try {
                int orderId = Integer.parseInt(idParam);
                Order order = dao.getOrderById(orderId);
                if (order == null) {
                    if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"找不到訂單\"}"); return; }
                    response.sendRedirect(contextPath + "/order/order_list.jsp?error=cancel_not_found");
                    return;
                }
                String[] errors = {
                    "cancel_has_productions",
                    "cancel_has_deliveries",
                    "cancel_has_invoices",
                    "cancel_has_inventory"
                };
                int[] counts = {
                    dao.countProductions(orderId),
                    dao.countDeliveries(orderId),
                    dao.countInvoices(orderId),
                    dao.countInventoryTransactions(orderId)
                };
                for (int i = 0; i < counts.length; i++) {
                    if (counts[i] > 0) {
                        String errUrl = contextPath + "/order/order_list.jsp?error=" + errors[i];
                        if (orderIdParam != null && !orderIdParam.isEmpty()) errUrl += "&orderId=" + orderIdParam;
                        if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"此訂單已有活動記錄，無法取消\"}"); return; }
                        response.sendRedirect(errUrl);
                        return;
                    }
                }
                order.setStatus(9);
                dao.updateOrder(order);
                if (ajax) { writeJson(response, "{\"success\":true}"); return; }
                String successUrl = contextPath + "/order/order_list.jsp?message=cancelled";
                if (orderIdParam != null && !orderIdParam.isEmpty()) successUrl += "&orderId=" + orderIdParam;
                response.sendRedirect(successUrl);
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to cancel order", e);
                if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}"); return; }
                response.sendRedirect(contextPath + "/order/order_list.jsp?error=exception");
            }
            return;
        }

        try {
            int customerId = Integer.parseInt(request.getParameter("customerId"));
            String orderNumber = request.getParameter("orderNumber");
            int productId = Integer.parseInt(request.getParameter("productId"));
            int priceType = Integer.parseInt(request.getParameter("priceType"));
            BigDecimal unitPrice = request.getParameter("unitPrice") != null && !request.getParameter("unitPrice").isEmpty()
                    ? new BigDecimal(request.getParameter("unitPrice")) : BigDecimal.ZERO;
            BigDecimal unitWeight = request.getParameter("unitWeight") != null && !request.getParameter("unitWeight").isEmpty()
                    ? new BigDecimal(request.getParameter("unitWeight")) : null;
            BigDecimal quantity = new BigDecimal(request.getParameter("quantity"));
            BigDecimal totalAmount = unitPrice.multiply(quantity);
            BigDecimal actualAmount = request.getParameter("actualAmount") != null && !request.getParameter("actualAmount").isEmpty()
                    ? new BigDecimal(request.getParameter("actualAmount")) : null;
            String amountDiffReason = request.getParameter("amountDiffReason");

            String orderDateStr = request.getParameter("orderDate");
            String deliveryDateStr = request.getParameter("deliveryDate");
            String expectedDeliveryDateStr = request.getParameter("expectedDeliveryDate");
            String note = request.getParameter("note");

            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            java.util.Date orderDate = sdf.parse(orderDateStr);
            java.util.Date deliveryDate = (deliveryDateStr != null && !deliveryDateStr.isEmpty()) ? sdf.parse(deliveryDateStr) : null;
            java.util.Date expectedDeliveryDate = (expectedDeliveryDateStr != null && !expectedDeliveryDateStr.isEmpty()) ? sdf.parse(expectedDeliveryDateStr) : null;

            Order order = new Order();
            order.setCustomerId(customerId);

            if (idParam != null && !idParam.isEmpty()) {
                order.setOrderNumber(orderNumber);
            } else {
                String customerNumber = dao.getCustomerNumberById(customerId);
                order.setOrderNumber(dao.generateOrderNumber(customerNumber));
            }

            order.setProductId(productId);
            order.setPriceType(priceType);
            order.setUnitPrice(unitPrice);
            order.setUnitWeight(unitWeight);
            order.setQuantity(quantity);
            order.setTotalAmount(totalAmount);
            order.setActualAmount(actualAmount);
            order.setAmountDiffReason(amountDiffReason);
            order.setOrderDate(orderDate);
            order.setDeliveryDate(deliveryDate);
            order.setExpectedDeliveryDate(expectedDeliveryDate);
            order.setStatus(0);
            order.setNote(note);

            boolean success;

            if (idParam != null && !idParam.isEmpty()) {
                order.setId(Integer.parseInt(idParam));
                success = dao.updateOrder(order);
            } else {
                int newId = dao.insertOrder(order);
                if (newId > 0) {
                    if (ajax) { writeJson(response, "{\"success\":true,\"id\":" + newId + "}"); return; }
                    response.sendRedirect(contextPath + "/order/order_list.jsp?submitted=1&orderId=" + newId);
                    return;
                }
                success = false;
            }

            if (success) {
                if (ajax) { writeJson(response, "{\"success\":true}"); return; }
                response.sendRedirect(contextPath + "/order/order_list.jsp?message=success");
            } else {
                String errMsg = idParam != null && !idParam.isEmpty() ? "更新失敗" : "新增失敗";
                if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"" + errMsg + "\"}"); return; }
                if (idParam != null && !idParam.isEmpty()) {
                    response.sendRedirect(contextPath + "/order/edit_order.jsp?id=" + idParam + "&error=failed");
                } else {
                    response.sendRedirect(contextPath + "/order/add_order.jsp?error=failed");
                }
            }
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to close order", e);
                if (ajax) { writeJson(response, "{\"success\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}"); return; }
            if (idParam != null && !idParam.isEmpty()) {
                response.sendRedirect(contextPath + "/order/edit_order.jsp?id=" + idParam + "&error=exception");
            } else {
                response.sendRedirect(contextPath + "/order/add_order.jsp?error=exception");
            }
        }
    }
}
