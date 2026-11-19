package servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import dao.DeliveryDao;
import dao.InventoryItemDao;
import dao.InventoryTransactionDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Delivery;
import model.InventoryItem;
import model.User;
import util.NumberUtil;

@WebServlet("/DeliveryServlet")
@MultipartConfig
public class DeliveryServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(DeliveryServlet.class.getName());

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");
        String action = request.getParameter("action");
        DeliveryDao dao = new DeliveryDao();

        try {
            if ("getDelivery".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                Delivery d = dao.getDeliveryById(id);
                if (d != null) {
                    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
                    StringBuilder sb = new StringBuilder();
                    sb.append("{");
                    sb.append("\"success\":true");
                    sb.append(",\"id\":").append(d.getId());
                    sb.append(",\"orderId\":").append(d.getOrderId());
                    sb.append(",\"orderNumber\":\"").append(jsonEscape(d.getOrderNumber())).append("\"");
                    sb.append(",\"customerName\":\"").append(jsonEscape(d.getCustomerName())).append("\"");
                    sb.append(",\"deliveryNumber\":\"").append(jsonEscape(d.getDeliveryNumber())).append("\"");
                    sb.append(",\"deliveryDate\":\"").append(d.getDeliveryDate() != null ? sdf.format(d.getDeliveryDate()) : "").append("\"");
                    sb.append(",\"quantity\":\"").append(d.getQuantity()).append("\"");
                    sb.append(",\"status\":").append(d.getStatus());
                    sb.append(",\"note\":\"").append(jsonEscape(d.getNote() != null ? d.getNote() : "")).append("\"");
                    sb.append("}");
                    response.getWriter().write(sb.toString());
                } else {
                    response.getWriter().write("{\"success\":false,\"error\":\"找不到該出貨記錄\"}");
                }
            } else if ("getOrders".equals(action)) {
                StringBuilder sb = new StringBuilder();
                sb.append("[");
                java.util.List<java.util.Map<String, Object>> orders = dao.getOpenOrdersWithStock();
                boolean first = true;
                for (Map<String, Object> row : orders) {
                    if (!first) sb.append(",");
                    first = false;
                    sb.append("{");
                    sb.append("\"id\":").append(row.get("id"));
                    sb.append(",\"orderNumber\":\"").append(jsonEscape((String) row.get("orderNumber"))).append("\"");
                    sb.append(",\"customerName\":\"").append(jsonEscape((String) row.get("customerName"))).append("\"");
                    sb.append(",\"productName\":\"").append(jsonEscape((String) row.get("productName"))).append("\"");
                    sb.append(",\"quantity\":\"").append(row.get("quantity")).append("\"");
                    sb.append(",\"totalDelivered\":\"").append(row.get("totalDelivered")).append("\"");
                    sb.append(",\"remain\":\"").append(NumberUtil.fmtQty((Double) row.get("remain"))).append("\"");
                    sb.append(",\"stockQty\":\"").append(row.get("stockQty")).append("\"");
                    sb.append("}");
                }
                sb.append("]");
                response.getWriter().write(sb.toString());
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to fetch delivery data", e);
            response.getWriter().write("{\"success\":false,\"error\":\"" + jsonEscape(e.getMessage()) + "\"}");
        }
    }

    private String jsonEscape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        boolean isAjax = "XMLHttpRequest".equals(request.getHeader("X-Requested-With"));

        String idParam = request.getParameter("id");
        String contextPath = request.getContextPath();
        Connection conn = null;

        try {
            String orderIdStr = request.getParameter("orderId");
            String quantityStr = request.getParameter("quantity");
            String statusStr = request.getParameter("status");
            if (orderIdStr == null || orderIdStr.isEmpty() || quantityStr == null || quantityStr.isEmpty() || statusStr == null || statusStr.isEmpty()) {
                throw new IllegalArgumentException("缺少必要欄位");
            }
            int orderId = Integer.parseInt(orderIdStr);
            BigDecimal quantity = new BigDecimal(quantityStr);
            int status = Integer.parseInt(statusStr);

            String deliveryDateStr = request.getParameter("deliveryDate");
            String note = request.getParameter("note");

            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");

            Delivery delivery = new Delivery();
            delivery.setOrderId(orderId);
            delivery.setQuantity(quantity);
            delivery.setStatus(status);
            delivery.setDeliveryDate(deliveryDateStr != null && !deliveryDateStr.isEmpty() ? sdf.parse(deliveryDateStr) : new java.util.Date());
            delivery.setNote(note);

            DeliveryDao dao = new DeliveryDao();
            boolean success;
            int deliveryId = -1;

            if (idParam != null && !idParam.isEmpty()) {
                int editId = Integer.parseInt(idParam);
                delivery.setId(editId);

                Delivery oldDelivery = dao.getDeliveryById(editId);
                if (oldDelivery == null) throw new IllegalArgumentException("找不到該出貨記錄");

                BigDecimal oldEffective = oldDelivery.getStatus() == 1 ? oldDelivery.getQuantity() : BigDecimal.ZERO;
                BigDecimal newEffective = status == 1 ? quantity : BigDecimal.ZERO;

                if (newEffective.compareTo(oldEffective) > 0) {
                    Object[] remaining = dao.getRemainingInfo(orderId, editId);
                    if (remaining != null) {
                        BigDecimal orderQty = (BigDecimal) remaining[0];
                        BigDecimal totalDelivered = (BigDecimal) remaining[1];
                        BigDecimal remain = orderQty.subtract(totalDelivered);
                        if (newEffective.compareTo(remain) > 0) {
                            if (isAjax) {
                                response.setContentType("application/json;charset=UTF-8");
                                response.getWriter().write("{\"success\":false,\"error\":\"exceed_order_remaining\"}");
                            } else {
                                response.sendRedirect(contextPath + "/delivery/edit_delivery.jsp?id=" + editId + "&error=exceed_order_remaining");
                            }
                            return;
                        }
                    }
                }

                int cmp = oldEffective.compareTo(newEffective);

                if (cmp == 0) {
                    success = dao.updateDelivery(delivery);
                } else {
                    conn = dao.getConnection();
                    conn.setAutoCommit(false);

                    Object[] orderInfo = dao.getOrderInfo(orderId);
                    if (orderInfo != null) {
                        int productId = (Integer) orderInfo[0];

                        InventoryItemDao itemDao = new InventoryItemDao();
                        InventoryItem item = itemDao.findByProductId(productId);

                        if (item != null) {
                            BigDecimal diff = oldEffective.subtract(newEffective);

                            BigDecimal before = BigDecimal.ZERO;
                            String qryStock = "SELECT quantity FROM inventory_stock WHERE warehouse_id = 2 AND item_id = ?";
                            try (PreparedStatement pq = conn.prepareStatement(qryStock)) {
                                pq.setInt(1, item.getId());
                                try (ResultSet rq = pq.executeQuery()) {
                                    if (rq.next()) before = rq.getBigDecimal("quantity");
                                }
                            }

                            BigDecimal after = before.add(diff);

                            if (after.compareTo(BigDecimal.ZERO) < 0) {
                                conn.rollback();
                                if (isAjax) {
                                    response.setContentType("application/json;charset=UTF-8");
                                    response.getWriter().write("{\"success\":false,\"error\":\"insufficient_stock\"}");
                                } else {
                                    response.sendRedirect(contextPath + "/delivery/edit_delivery.jsp?id=" + editId + "&error=insufficient_stock");
                                }
                                return;
                            }

                            String upsert = "INSERT INTO inventory_stock (warehouse_id, item_id, quantity) VALUES (2, ?, ?) ON DUPLICATE KEY UPDATE quantity = VALUES(quantity)";
                            try (PreparedStatement pu = conn.prepareStatement(upsert)) {
                                pu.setInt(1, item.getId());
                                pu.setBigDecimal(2, after);
                                pu.executeUpdate();
                            }

                            String findTxn = "SELECT id, transaction_number FROM inventory_transactions WHERE ref_type = 'delivery' AND ref_id = ? LIMIT 1";
                            try (PreparedStatement pf = conn.prepareStatement(findTxn)) {
                                pf.setInt(1, editId);
                                try (ResultSet rf = pf.executeQuery()) {
                                    if (rf.next()) {
                                        String updTxn = "UPDATE inventory_transactions SET quantity = ?, balance_before = ?, balance_after = ? WHERE id = ?";
                                        try (PreparedStatement ptu = conn.prepareStatement(updTxn)) {
                                            ptu.setBigDecimal(1, newEffective.negate());
                                            ptu.setBigDecimal(2, after.add(newEffective));
                                            ptu.setBigDecimal(3, after);
                                            ptu.setInt(4, rf.getInt("id"));
                                            ptu.executeUpdate();
                                        }
                                    } else {
                                        InventoryTransactionDao txnDao = new InventoryTransactionDao();
                                        String txnNumber = txnDao.generateTransactionNumber();
                                        HttpSession session = request.getSession(false);
                                        Integer userId = null;
                                        if (session != null) {
                                            User u = (User) session.getAttribute("user");
                                            if (u != null) userId = u.getId();
                                        }
                                        String insTxn = "INSERT INTO inventory_transactions (transaction_number, warehouse_id, item_id, transaction_type, quantity, balance_before, balance_after, ref_type, ref_id, order_id, note, created_by) VALUES (?, 2, ?, 2, ?, ?, ?, 'delivery', ?, ?, ?, ?)";
                                        try (PreparedStatement pt = conn.prepareStatement(insTxn)) {
                                            pt.setString(1, txnNumber);
                                            pt.setInt(2, item.getId());
                                            pt.setBigDecimal(3, newEffective.negate());
                                            pt.setBigDecimal(4, after.add(newEffective));
                                            pt.setBigDecimal(5, after);
                                            pt.setInt(6, editId);
                                            pt.setInt(7, orderId);
                                            pt.setString(8, "出貨：" + delivery.getDeliveryNumber());
                                            if (userId != null) {
                                                pt.setInt(9, userId);
                                            } else {
                                                pt.setNull(9, java.sql.Types.INTEGER);
                                            }
                                            pt.executeUpdate();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    String updateSql = "UPDATE deliveries SET order_id=?, delivery_date=?, quantity=?, status=?, note=? WHERE id=?";
                    try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                        ps.setInt(1, delivery.getOrderId());
                        ps.setDate(2, delivery.getDeliveryDate() != null ? new java.sql.Date(delivery.getDeliveryDate().getTime()) : null);
                        ps.setBigDecimal(3, delivery.getQuantity());
                        ps.setInt(4, delivery.getStatus());
                        ps.setString(5, delivery.getNote());
                        ps.setInt(6, delivery.getId());
                        ps.executeUpdate();
                    }

                    conn.commit();
                    success = true;
                }
            } else {
                delivery.setDeliveryNumber(dao.generateDeliveryNumber());

                InventoryTransactionDao txnDao = new InventoryTransactionDao();
                String txnNumber = txnDao.generateTransactionNumber();

                conn = dao.getConnection();
                conn.setAutoCommit(false);

                if (status == 1) {
                    Object[] remaining = dao.getRemainingInfo(orderId, -1);
                    if (remaining != null) {
                        BigDecimal orderQty = (BigDecimal) remaining[0];
                        BigDecimal totalDelivered = (BigDecimal) remaining[1];
                        BigDecimal remain = orderQty.subtract(totalDelivered);
                        if (quantity.compareTo(remain) > 0) {
                            conn.rollback();
                            if (isAjax) {
                                response.setContentType("application/json;charset=UTF-8");
                                response.getWriter().write("{\"success\":false,\"error\":\"exceed_order_remaining\"}");
                            } else {
                                response.sendRedirect(contextPath + "/delivery/add_delivery.jsp?orderId=" + orderId + "&error=exceed_order_remaining");
                            }
                            return;
                        }
                    }
                }

                String insertSql = "INSERT INTO deliveries (order_id, delivery_number, delivery_date, quantity, status, note) VALUES (?, ?, ?, ?, ?, ?)";
                try (PreparedStatement ps = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, delivery.getOrderId());
                    ps.setString(2, delivery.getDeliveryNumber());
                    ps.setDate(3, delivery.getDeliveryDate() != null ? new java.sql.Date(delivery.getDeliveryDate().getTime()) : null);
                    ps.setBigDecimal(4, delivery.getQuantity());
                    ps.setInt(5, delivery.getStatus());
                    ps.setString(6, delivery.getNote());
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        deliveryId = keys.next() ? keys.getInt(1) : -1;
                    }
                }

                if (deliveryId > 0) {
                    Object[] orderInfo = dao.getOrderInfo(orderId);
                    if (orderInfo != null) {
                        int productId = (Integer) orderInfo[0];
                        int priceType = (Integer) orderInfo[1];
                        String unit = priceType == 1 ? "kg" : "pcs";

                        InventoryItemDao itemDao = new InventoryItemDao();
                        InventoryItem item = itemDao.findByProductId(productId);
                        if (item == null) {
                            String insertItemSql = "INSERT INTO inventory_items (item_code, item_name, item_type, product_id, unit, status) VALUES (?, ?, 1, ?, ?, 1)";
                            try (PreparedStatement pi = conn.prepareStatement(insertItemSql)) {
                                pi.setString(1, "PROD-" + productId);
                                pi.setString(2, "產品#" + productId);
                                pi.setInt(3, productId);
                                pi.setString(4, unit);
                                pi.executeUpdate();
                            }
                            String findSql = "SELECT id FROM inventory_items WHERE product_id = ? LIMIT 1";
                            try (PreparedStatement pf = conn.prepareStatement(findSql)) {
                                pf.setInt(1, productId);
                                try (ResultSet rf = pf.executeQuery()) {
                                    item = rf.next() ? new InventoryItem() : null;
                                    if (item != null) item.setId(rf.getInt("id"));
                                }
                            }
                        }

                        if (item != null) {
                            BigDecimal before = BigDecimal.ZERO;
                            String qryStock = "SELECT quantity FROM inventory_stock WHERE warehouse_id = 2 AND item_id = ?";
                            try (PreparedStatement pq = conn.prepareStatement(qryStock)) {
                                pq.setInt(1, item.getId());
                                try (ResultSet rq = pq.executeQuery()) {
                                    if (rq.next()) before = rq.getBigDecimal("quantity");
                                }
                            }

                            if (before.compareTo(quantity) < 0) {
                                conn.rollback();
                                if (isAjax) {
                                    response.setContentType("application/json;charset=UTF-8");
                                    response.getWriter().write("{\"success\":false,\"error\":\"insufficient_stock\"}");
                                } else {
                                    response.sendRedirect(contextPath + "/delivery/add_delivery.jsp?orderId=" + orderId + "&error=insufficient_stock");
                                }
                                return;
                            }

                            BigDecimal after = before.subtract(quantity);

                            String txnSql = "INSERT INTO inventory_transactions (transaction_number, warehouse_id, item_id, transaction_type, quantity, balance_before, balance_after, ref_type, ref_id, order_id, note, created_by) VALUES (?, 2, ?, 2, ?, ?, ?, 'delivery', ?, ?, ?, ?)";
                            try (PreparedStatement pt = conn.prepareStatement(txnSql)) {
                                pt.setString(1, txnNumber);
                                pt.setInt(2, item.getId());
                                pt.setBigDecimal(3, quantity.negate());
                                pt.setBigDecimal(4, before);
                                pt.setBigDecimal(5, after);
                                pt.setInt(6, deliveryId);
                                pt.setInt(7, orderId);
                                pt.setString(8, "出貨：" + delivery.getDeliveryNumber());
                                HttpSession session = request.getSession(false);
                                if (session != null) {
                                    User u = (User) session.getAttribute("user");
                                    pt.setObject(9, u != null ? u.getId() : null, java.sql.Types.INTEGER);
                                } else {
                                    pt.setNull(9, java.sql.Types.INTEGER);
                                }
                                pt.executeUpdate();
                            }

                            String upsert = "INSERT INTO inventory_stock (warehouse_id, item_id, quantity) VALUES (2, ?, ?) ON DUPLICATE KEY UPDATE quantity = VALUES(quantity)";
                            try (PreparedStatement pu = conn.prepareStatement(upsert)) {
                                pu.setInt(1, item.getId());
                                pu.setBigDecimal(2, after);
                                pu.executeUpdate();
                            }
                        }
                    }
                }

                conn.commit();
                success = deliveryId > 0;
            }

            if (isAjax) {
                response.setContentType("application/json;charset=UTF-8");
                if (success) {
                    response.getWriter().write("{\"success\":true}");
                } else {
                    response.getWriter().write("{\"success\":false,\"error\":\"操作失敗\"}");
                }
            } else {
                if (success) {
                    response.sendRedirect(contextPath + "/delivery/delivery_list.jsp?message=success");
                } else if (idParam != null && !idParam.isEmpty()) {
                    response.sendRedirect(contextPath + "/delivery/edit_delivery.jsp?id=" + idParam + "&error=failed");
                } else {
                    response.sendRedirect(contextPath + "/delivery/add_delivery.jsp?error=failed");
                }
            }
        } catch (Exception e) {
            if (conn != null) try { conn.rollback(); } catch (Exception ex) {}
            LOGGER.log(Level.SEVERE, "Failed to save delivery", e);
            if (isAjax) {
                response.setContentType("application/json;charset=UTF-8");
                String errMsg = e.getMessage() != null ? e.getMessage() : "系統錯誤";
                response.getWriter().write("{\"success\":false,\"error\":\"" + jsonEscape(errMsg) + "\"}");
            } else {
                if (idParam != null && !idParam.isEmpty()) {
                    response.sendRedirect(contextPath + "/delivery/edit_delivery.jsp?id=" + idParam + "&error=exception");
                } else {
                    response.sendRedirect(contextPath + "/delivery/add_delivery.jsp?error=exception");
                }
            }
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception e) {}
        }
    }
}
