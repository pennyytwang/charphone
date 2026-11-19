package servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import dao.BaseDao;
import dao.InventoryItemDao;
import dao.InventoryTransactionDao;
import model.InventoryItem;
import model.User;

@WebServlet("/ProductionReceiptServlet")
public class ProductionReceiptServlet extends BaseServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(ProductionReceiptServlet.class.getName());

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");
        String contextPath = request.getContextPath();

        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");

        String action = request.getParameter("action");
        if ("reverse".equals(action)) {
            handleReverse(request, response, user);
            return;
        }
        if ("adjust_receipt".equals(action)) {
            handleAdjustReceipt(request, response, user);
            return;
        }

        Connection conn = null;

        try {
            int productionId = Integer.parseInt(request.getParameter("productionId"));
            BigDecimal quantity = new BigDecimal(request.getParameter("quantity"));

            if (quantity.compareTo(BigDecimal.ZERO) <= 0) {
                response.sendRedirect(contextPath + "/production/receipt.jsp?id=" + productionId + "&error=invalid_qty");
                return;
            }

            InventoryTransactionDao txnDao = new InventoryTransactionDao();
            String txnNumber = txnDao.generateTransactionNumber();

            conn = BaseDao.getConnection();
            conn.setAutoCommit(false);

            int productId = 0;
            int orderId = 0;
            String productName = "";
            String unit = "pcs";
            String prodNumber = "";
            double manufacturedQty = 0;

            String prodSql = "SELECT p.*, pr.product_name, pr.price_type FROM productions p JOIN products pr ON p.product_id = pr.id WHERE p.id = ?";
            try (PreparedStatement ps = conn.prepareStatement(prodSql)) {
                ps.setInt(1, productionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        response.sendRedirect(contextPath + "/production/production_list.jsp?error=notfound");
                        return;
                    }
                    productId = rs.getInt("product_id");
                    productName = rs.getString("product_name");
                    unit = rs.getInt("price_type") == 1 ? "kg" : "pcs";
                    prodNumber = rs.getString("production_number");
                    manufacturedQty = rs.getDouble("manufactured_qty");
                    orderId = rs.getInt("order_id");
                }
            }

            // 計算淨入庫量
            BigDecimal netReceived = BigDecimal.ZERO;
            try (PreparedStatement psNet = conn.prepareStatement(
                    "SELECT (SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type = 'production' AND ref_id = ? AND transaction_type = 1) - (SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type = 'production' AND ref_id = ? AND transaction_type = 2)")) {
                psNet.setInt(1, productionId);
                psNet.setInt(2, productionId);
                try (ResultSet rsNet = psNet.executeQuery()) {
                    if (rsNet.next()) netReceived = rsNet.getBigDecimal(1);
                }
            }

            if (quantity.compareTo(BigDecimal.valueOf(manufacturedQty).subtract(netReceived)) > 0) {
                response.sendRedirect(contextPath + "/production/receipt.jsp?id=" + productionId + "&error=exceed");
                return;
            }

            InventoryItemDao itemDao = new InventoryItemDao();
            InventoryItem item = itemDao.findByProductId(productId);
            if (item == null) {
                String insertItemSql = "INSERT INTO inventory_items (item_code, item_name, item_type, product_id, unit, status) VALUES (?, ?, 1, ?, ?, 1)";
                try (PreparedStatement pi = conn.prepareStatement(insertItemSql)) {
                    pi.setString(1, "PROD-" + productId);
                    pi.setString(2, productName);
                    pi.setInt(3, productId);
                    pi.setString(4, unit);
                    pi.executeUpdate();
                }
                String findSql = "SELECT id FROM inventory_items WHERE product_id = ? LIMIT 1";
                try (PreparedStatement pf = conn.prepareStatement(findSql)) {
                    pf.setInt(1, productId);
                    try (ResultSet rf = pf.executeQuery()) {
                        if (rf.next()) {
                            item = new InventoryItem();
                            item.setId(rf.getInt("id"));
                        }
                    }
                }
                if (item == null) {
                    response.sendRedirect(contextPath + "/production/receipt.jsp?id=" + productionId + "&error=create_failed");
                    return;
                }
            }

            int warehouseId = 2;

            BigDecimal before = BigDecimal.ZERO;
            String qryStock = "SELECT quantity FROM inventory_stock WHERE warehouse_id = ? AND item_id = ?";
            try (PreparedStatement pq = conn.prepareStatement(qryStock)) {
                pq.setInt(1, warehouseId);
                pq.setInt(2, item.getId());
                try (ResultSet rq = pq.executeQuery()) {
                    if (rq.next()) before = rq.getBigDecimal("quantity");
                }
            }

            BigDecimal after = before.add(quantity);

            String txnSql = "INSERT INTO inventory_transactions (transaction_number, warehouse_id, item_id, transaction_type, quantity, balance_before, balance_after, ref_type, ref_id, order_id, production_id, note, created_by) VALUES (?, ?, ?, 1, ?, ?, ?, 'production', ?, ?, ?, ?, ?)";
            try (PreparedStatement pt = conn.prepareStatement(txnSql)) {
                pt.setString(1, txnNumber);
                pt.setInt(2, warehouseId);
                pt.setInt(3, item.getId());
                pt.setBigDecimal(4, quantity);
                pt.setBigDecimal(5, before);
                pt.setBigDecimal(6, after);
                pt.setInt(7, productionId);
                pt.setInt(8, orderId);
                pt.setInt(9, productionId);
                pt.setString(10, "生產入庫：" + prodNumber);
                pt.setObject(11, user != null ? user.getId() : null, java.sql.Types.INTEGER);
                pt.executeUpdate();
            }

            String upsert = "INSERT INTO inventory_stock (warehouse_id, item_id, quantity) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE quantity = VALUES(quantity)";
            try (PreparedStatement pu = conn.prepareStatement(upsert)) {
                pu.setInt(1, warehouseId);
                pu.setInt(2, item.getId());
                pu.setBigDecimal(3, after);
                pu.executeUpdate();
            }

            conn.commit();
            response.sendRedirect(contextPath + "/production/production_list.jsp?message=receipt_ok&orderId=" + orderId);

        } catch (Exception e) {
            if (conn != null) try { conn.rollback(); } catch (Exception ex) {}
            LOGGER.log(Level.SEVERE, "Production receipt failed", e);
            String orderIdFallback = request.getParameter("orderId");
            response.sendRedirect(request.getContextPath() + "/production/production_list.jsp?error=exception" + (orderIdFallback != null && !orderIdFallback.isEmpty() ? "&orderId=" + orderIdFallback : ""));
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception e) {}
        }
    }

    private void handleReverse(HttpServletRequest request, HttpServletResponse response, User user) throws ServletException, IOException {
        String contextPath = request.getContextPath();
        Connection conn = null;

        try {
            int productionId = Integer.parseInt(request.getParameter("productionId"));
            int orderId = Integer.parseInt(request.getParameter("orderId"));
            int txnId = Integer.parseInt(request.getParameter("txnId"));
            BigDecimal quantity = new BigDecimal(request.getParameter("quantity"));
            String note = request.getParameter("note");

            if (quantity.compareTo(BigDecimal.ZERO) <= 0) {
                response.sendRedirect(contextPath + "/production/receipt_reverse.jsp?id=" + productionId + "&error=invalid_qty");
                return;
            }

            conn = BaseDao.getConnection();
            conn.setAutoCommit(false);

            int productId = 0;
            String prodNumber = "";
            String unit = "pcs";
            int warehouseId = 2;

            String prodSql = "SELECT p.product_id, p.production_number, pr.price_type FROM productions p JOIN products pr ON p.product_id = pr.id WHERE p.id = ?";
            try (PreparedStatement ps = conn.prepareStatement(prodSql)) {
                ps.setInt(1, productionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        productId = rs.getInt("product_id");
                        prodNumber = rs.getString("production_number");
                        unit = rs.getInt("price_type") == 1 ? "kg" : "pcs";
                    } else {
                        response.sendRedirect(contextPath + "/production/production_list.jsp?error=notfound");
                        return;
                    }
                }
            }

            // 查詢原始入庫數量
            BigDecimal originalQty = BigDecimal.ZERO;
            try (PreparedStatement ps = conn.prepareStatement("SELECT quantity FROM inventory_transactions WHERE id = ? AND transaction_type = 1")) {
                ps.setInt(1, txnId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) originalQty = rs.getBigDecimal("quantity");
                }
            }

            // 計算已沖正的量（此筆之後的沖正紀錄）
            BigDecimal alreadyReversed = BigDecimal.ZERO;
            java.sql.Timestamp originalTs = null;
            try (PreparedStatement ps = conn.prepareStatement("SELECT created_at FROM inventory_transactions WHERE id = ?")) {
                ps.setInt(1, txnId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) originalTs = rs.getTimestamp("created_at");
                }
            }
            if (originalTs != null) {
                try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type = 'production' AND ref_id = ? AND transaction_type = 2 AND created_at > ?")) {
                    ps.setInt(1, productionId);
                    ps.setTimestamp(2, originalTs);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) alreadyReversed = rs.getBigDecimal(1);
                    }
                }
            }

            BigDecimal canReverse = originalQty.subtract(alreadyReversed);
            if (canReverse.compareTo(BigDecimal.ZERO) <= 0) {
                conn.rollback();
                response.sendRedirect(contextPath + "/production/receipt_reverse.jsp?id=" + productionId + "&error=exceed");
                return;
            }
            if (quantity.compareTo(canReverse) > 0) {
                conn.rollback();
                response.sendRedirect(contextPath + "/production/receipt_reverse.jsp?id=" + productionId + "&error=exceed");
                return;
            }

            // 查詢目前庫存
            BigDecimal before = BigDecimal.ZERO;
            try (PreparedStatement ps = conn.prepareStatement("SELECT quantity FROM inventory_stock WHERE warehouse_id = ? AND item_id = (SELECT id FROM inventory_items WHERE product_id = ? LIMIT 1)")) {
                ps.setInt(1, warehouseId);
                ps.setInt(2, productId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) before = rs.getBigDecimal("quantity");
                }
            }

            if (before.compareTo(quantity) < 0) {
                conn.rollback();
                response.sendRedirect(contextPath + "/production/receipt_reverse.jsp?id=" + productionId + "&error=insufficient_stock");
                return;
            }

            BigDecimal after = before.subtract(quantity);

            InventoryTransactionDao txnDao = new InventoryTransactionDao();
            String txnNumber = txnDao.generateTransactionNumber();

            // 寫入沖正紀錄 (transaction_type = 2)
            String txnSql = "INSERT INTO inventory_transactions (transaction_number, warehouse_id, item_id, transaction_type, quantity, balance_before, balance_after, ref_type, ref_id, order_id, production_id, note, created_by) VALUES (?, ?, ?, 2, ?, ?, ?, 'production', ?, ?, ?, ?, ?)";
            try (PreparedStatement pt = conn.prepareStatement(txnSql)) {
                pt.setString(1, txnNumber);
                pt.setInt(2, warehouseId);
                int itemId = 0;
                try (PreparedStatement pi = conn.prepareStatement("SELECT id FROM inventory_items WHERE product_id = ? LIMIT 1")) {
                    pi.setInt(1, productId);
                    try (ResultSet ri = pi.executeQuery()) {
                        if (ri.next()) itemId = ri.getInt("id");
                    }
                }
                pt.setInt(3, itemId);
                pt.setBigDecimal(4, quantity);
                pt.setBigDecimal(5, before);
                pt.setBigDecimal(6, after);
                pt.setInt(7, productionId);
                pt.setInt(8, orderId);
                pt.setInt(9, productionId);
                pt.setString(10, note != null && !note.isEmpty() ? note : "沖正：" + prodNumber);
                pt.setObject(11, user != null ? user.getId() : null, java.sql.Types.INTEGER);
                pt.executeUpdate();
            }

            // 更新庫存
            String upsert = "INSERT INTO inventory_stock (warehouse_id, item_id, quantity) VALUES (?, (SELECT id FROM inventory_items WHERE product_id = ? LIMIT 1), ?) ON DUPLICATE KEY UPDATE quantity = VALUES(quantity)";
            try (PreparedStatement pu = conn.prepareStatement(upsert)) {
                pu.setInt(1, warehouseId);
                pu.setInt(2, productId);
                pu.setBigDecimal(3, after);
                pu.executeUpdate();
            }

            conn.commit();
            response.sendRedirect(contextPath + "/production/receipt_reverse.jsp?id=" + productionId + "&status=success");

        } catch (Exception e) {
            if (conn != null) try { conn.rollback(); } catch (Exception ex) {}
            LOGGER.log(Level.SEVERE, "Production receipt reverse failed", e);
            String orderIdParam = request.getParameter("orderId");
            response.sendRedirect(contextPath + "/production/receipt_reverse.jsp?id=" + request.getParameter("productionId") + "&error=failed" + (orderIdParam != null ? "&orderId=" + orderIdParam : ""));
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception e) {}
        }
    }

    private void handleAdjustReceipt(HttpServletRequest request, HttpServletResponse response, User user) throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");
        Connection conn = null;

        try {
            int productionId = Integer.parseInt(request.getParameter("productionId"));
            int orderId = Integer.parseInt(request.getParameter("orderId"));
            BigDecimal newQty = new BigDecimal(request.getParameter("quantity"));

            if (newQty.compareTo(BigDecimal.ZERO) < 0) {
                response.getWriter().write("{\"success\":false,\"error\":\"數量不能為負數\"}");
                return;
            }

            conn = BaseDao.getConnection();
            conn.setAutoCommit(false);

            int productId = 0;
            String prodNumber = "";
            String unit = "pcs";
            double manufacturedQty = 0;

            String prodSql = "SELECT p.product_id, p.production_number, p.manufactured_qty, pr.price_type FROM productions p JOIN products pr ON p.product_id = pr.id WHERE p.id = ?";
            try (PreparedStatement ps = conn.prepareStatement(prodSql)) {
                ps.setInt(1, productionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        productId = rs.getInt("product_id");
                        prodNumber = rs.getString("production_number");
                        unit = rs.getInt("price_type") == 1 ? "kg" : "pcs";
                        manufacturedQty = rs.getDouble("manufactured_qty");
                    } else {
                        conn.rollback();
                        response.getWriter().write("{\"success\":false,\"error\":\"找不到此工單\"}");
                        return;
                    }
                }
            }

            if (newQty.compareTo(BigDecimal.valueOf(manufacturedQty)) > 0) {
                conn.rollback();
                response.getWriter().write("{\"success\":false,\"error\":\"入庫數量不能超過已製造數量 " + manufacturedQty + " " + unit + "\"}");
                return;
            }

            // 計算目前淨入庫量 (type=1 - type=2)
            BigDecimal currentReceived = BigDecimal.ZERO;
            try (PreparedStatement ps = conn.prepareStatement("SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type = 'production' AND ref_id = ? AND transaction_type = 1")) {
                ps.setInt(1, productionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) currentReceived = rs.getBigDecimal(1);
                }
            }
            BigDecimal currentReversed = BigDecimal.ZERO;
            try (PreparedStatement ps = conn.prepareStatement("SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type = 'production' AND ref_id = ? AND transaction_type = 2")) {
                ps.setInt(1, productionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) currentReversed = rs.getBigDecimal(1);
                }
            }
            BigDecimal currentNet = currentReceived.subtract(currentReversed);
            BigDecimal delta = newQty.subtract(currentNet);

            if (delta.compareTo(BigDecimal.ZERO) == 0) {
                conn.commit();
                response.getWriter().write("{\"success\":true}");
                return;
            }

            // 取得庫存資訊
            int warehouseId = 2;
            InventoryItemDao itemDao = new InventoryItemDao();
            InventoryItem item = itemDao.findByProductId(productId);
            if (item == null) {
                String insertItemSql = "INSERT INTO inventory_items (item_code, item_name, item_type, product_id, unit, status) VALUES (?, ?, 1, ?, ?, 1)";
                try (PreparedStatement pi = conn.prepareStatement(insertItemSql)) {
                    pi.setString(1, "PROD-" + productId);
                    pi.setString(2, prodNumber);
                    pi.setInt(3, productId);
                    pi.setString(4, unit);
                    pi.executeUpdate();
                }
                String findSql = "SELECT id FROM inventory_items WHERE product_id = ? LIMIT 1";
                try (PreparedStatement pf = conn.prepareStatement(findSql)) {
                    pf.setInt(1, productId);
                    try (ResultSet rf = pf.executeQuery()) {
                        if (rf.next()) {
                            item = new InventoryItem();
                            item.setId(rf.getInt("id"));
                        }
                    }
                }
                if (item == null) {
                    conn.rollback();
                    response.getWriter().write("{\"success\":false,\"error\":\"無法建立庫存項目\"}");
                    return;
                }
            }

            BigDecimal before = BigDecimal.ZERO;
            try (PreparedStatement pq = conn.prepareStatement("SELECT quantity FROM inventory_stock WHERE warehouse_id = ? AND item_id = ?")) {
                pq.setInt(1, warehouseId);
                pq.setInt(2, item.getId());
                try (ResultSet rq = pq.executeQuery()) {
                    if (rq.next()) before = rq.getBigDecimal("quantity");
                }
            }

            InventoryTransactionDao txnDao = new InventoryTransactionDao();

            if (delta.compareTo(BigDecimal.ZERO) > 0) {
                // 增加入庫：建立 type=1 紀錄，庫存增加
                BigDecimal after = before.add(delta);
                String txnNumber = txnDao.generateTransactionNumber();
                String txnSql = "INSERT INTO inventory_transactions (transaction_number, warehouse_id, item_id, transaction_type, quantity, balance_before, balance_after, ref_type, ref_id, order_id, production_id, note, created_by) VALUES (?, ?, ?, 1, ?, ?, ?, 'production', ?, ?, ?, ?, ?)";
                try (PreparedStatement pt = conn.prepareStatement(txnSql)) {
                    pt.setString(1, txnNumber);
                    pt.setInt(2, warehouseId);
                    pt.setInt(3, item.getId());
                    pt.setBigDecimal(4, delta);
                    pt.setBigDecimal(5, before);
                    pt.setBigDecimal(6, after);
                    pt.setInt(7, productionId);
                    pt.setInt(8, orderId);
                    pt.setInt(9, productionId);
                    pt.setString(10, "修改入庫：" + prodNumber);
                    pt.setObject(11, user != null ? user.getId() : null, java.sql.Types.INTEGER);
                    pt.executeUpdate();
                }
                try (PreparedStatement pu = conn.prepareStatement("INSERT INTO inventory_stock (warehouse_id, item_id, quantity) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE quantity = VALUES(quantity)")) {
                    pu.setInt(1, warehouseId);
                    pu.setInt(2, item.getId());
                    pu.setBigDecimal(3, after);
                    pu.executeUpdate();
                }
            } else {
                // 減少入庫：建立 type=2 沖正紀錄
                BigDecimal absDelta = delta.abs();
                if (before.compareTo(absDelta) < 0) {
                    conn.rollback();
                    response.getWriter().write("{\"success\":false,\"error\":\"成品倉庫存不足，無法沖正\"}");
                    return;
                }
                BigDecimal after = before.subtract(absDelta);
                String txnNumber = txnDao.generateTransactionNumber();
                String txnSql = "INSERT INTO inventory_transactions (transaction_number, warehouse_id, item_id, transaction_type, quantity, balance_before, balance_after, ref_type, ref_id, order_id, production_id, note, created_by) VALUES (?, ?, ?, 2, ?, ?, ?, 'production', ?, ?, ?, ?, ?)";
                try (PreparedStatement pt = conn.prepareStatement(txnSql)) {
                    pt.setString(1, txnNumber);
                    pt.setInt(2, warehouseId);
                    pt.setInt(3, item.getId());
                    pt.setBigDecimal(4, absDelta);
                    pt.setBigDecimal(5, before);
                    pt.setBigDecimal(6, after);
                    pt.setInt(7, productionId);
                    pt.setInt(8, orderId);
                    pt.setInt(9, productionId);
                    pt.setString(10, "修改入庫沖正：" + prodNumber);
                    pt.setObject(11, user != null ? user.getId() : null, java.sql.Types.INTEGER);
                    pt.executeUpdate();
                }
                try (PreparedStatement pu = conn.prepareStatement("INSERT INTO inventory_stock (warehouse_id, item_id, quantity) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE quantity = VALUES(quantity)")) {
                    pu.setInt(1, warehouseId);
                    pu.setInt(2, item.getId());
                    pu.setBigDecimal(3, after);
                    pu.executeUpdate();
                }
            }

            conn.commit();
            response.getWriter().write("{\"success\":true}");

        } catch (Exception e) {
            if (conn != null) try { conn.rollback(); } catch (Exception ex) {}
            LOGGER.log(Level.SEVERE, "Adjust receipt failed", e);
            response.getWriter().write("{\"success\":false,\"error\":\"系統錯誤：" + e.getMessage() + "\"}");
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception e) {}
        }
    }
}
