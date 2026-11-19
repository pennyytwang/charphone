package dao;

import java.math.BigDecimal;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.Order;
import model.Customer;
import model.Product;

public class OrderDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(OrderDao.class.getName());

    public String getCustomerNumberById(int customerId) {
        String sql = "SELECT customer_number FROM customers WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String num = rs.getString("customer_number");
                    if (num != null && !num.isEmpty()) return num;
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query customer number", e);
        }
        throw new RuntimeException("客戶 ID " + customerId + " 的 customer_number 未設定，無法產生訂單編號");
    }

    public String generateOrderNumber(String customerNumber) {
        String prefix = customerNumber + "-" + new SimpleDateFormat("yyyyMM").format(new Date()) + "-";
        String sql = "SELECT order_number FROM orders WHERE order_number LIKE ? ORDER BY order_number DESC LIMIT 1 FOR UPDATE";
        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, prefix + "%");
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String last = rs.getString("order_number");
                        int seq = Integer.parseInt(last.substring(last.length() - 3)) + 1;
                        conn.commit();
                        return prefix + String.format("%03d", seq);
                    }
                }
            }
            conn.commit();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to generate order number", e);
        }
        return prefix + "001";
    }

    public int insertOrder(Order order) throws Exception {
        String sql = "INSERT INTO orders (customer_id, order_number, product_id, price_type, unit_price, unit_weight, quantity, total_amount, actual_amount, amount_diff_reason, order_date, delivery_date, expected_delivery_date, status, close_status, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        int maxRetries = 3;
        for (int attempt = 0; attempt < maxRetries; attempt++) {
            try (Connection conn = getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
                if (attempt > 0) {
                    String customerNumber = getCustomerNumberById(order.getCustomerId());
                    order.setOrderNumber(generateOrderNumber(customerNumber));
                }
                ps.setInt(1, order.getCustomerId());
                ps.setString(2, order.getOrderNumber());
                ps.setInt(3, order.getProductId());
                ps.setInt(4, order.getPriceType());
                ps.setBigDecimal(5, order.getUnitPrice());
                ps.setBigDecimal(6, order.getUnitWeight());
                ps.setBigDecimal(7, order.getQuantity());
                ps.setBigDecimal(8, order.getTotalAmount());
                ps.setBigDecimal(9, order.getActualAmount());
                ps.setString(10, order.getAmountDiffReason());
                ps.setDate(11, order.getOrderDate() != null ? new java.sql.Date(order.getOrderDate().getTime()) : null);
                ps.setDate(12, order.getDeliveryDate() != null ? new java.sql.Date(order.getDeliveryDate().getTime()) : null);
                ps.setDate(13, order.getExpectedDeliveryDate() != null ? new java.sql.Date(order.getExpectedDeliveryDate().getTime()) : null);
                ps.setInt(14, order.getStatus());
                ps.setInt(15, order.getCloseStatus());
                ps.setString(16, order.getNote());
                int rows = ps.executeUpdate();
                if (rows > 0) {
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (keys.next()) return keys.getInt(1);
                    }
                    return 0;
                }
            } catch (java.sql.SQLIntegrityConstraintViolationException e) {
                if (attempt >= maxRetries - 1) throw e;
            }
        }
        return 0;
    }

    public Order getOrderById(int id) {
        String sql = "SELECT o.*, c.customer_name, p.product_name FROM orders o LEFT JOIN customers c ON o.customer_id = c.id LEFT JOIN products p ON o.product_id = p.id WHERE o.id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapOrder(rs);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query order by id", e);
        }
        return null;
    }

    public boolean deleteOrder(int id) {
        String sql = "DELETE FROM orders WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to delete order", e);
        }
        return false;
    }

    public boolean updateOrder(Order order) throws Exception {
        String sql = "UPDATE orders SET customer_id=?, product_id=?, price_type=?, unit_price=?, unit_weight=?, quantity=?, total_amount=?, actual_amount=?, amount_diff_reason=?, order_date=?, delivery_date=?, expected_delivery_date=?, status=?, close_status=?, note=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, order.getCustomerId());
            ps.setInt(2, order.getProductId());
            ps.setInt(3, order.getPriceType());
            ps.setBigDecimal(4, order.getUnitPrice());
            ps.setBigDecimal(5, order.getUnitWeight());
            ps.setBigDecimal(6, order.getQuantity());
            ps.setBigDecimal(7, order.getTotalAmount());
            ps.setBigDecimal(8, order.getActualAmount());
            ps.setString(9, order.getAmountDiffReason());
            ps.setDate(10, order.getOrderDate() != null ? new java.sql.Date(order.getOrderDate().getTime()) : null);
            ps.setDate(11, order.getDeliveryDate() != null ? new java.sql.Date(order.getDeliveryDate().getTime()) : null);
            ps.setDate(12, order.getExpectedDeliveryDate() != null ? new java.sql.Date(order.getExpectedDeliveryDate().getTime()) : null);
            ps.setInt(13, order.getStatus());
            ps.setInt(14, order.getCloseStatus());
            ps.setString(15, order.getNote());
            ps.setInt(16, order.getId());
            return ps.executeUpdate() > 0;
        }
    }

    public BigDecimal getTotalDelivered(int orderId) {
        String sql = "SELECT COALESCE(SUM(quantity), 0) FROM deliveries WHERE order_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query total delivered quantity", e);
        }
        return BigDecimal.ZERO;
    }

    public List<Order> getAllOrders() {
        List<Order> list = new ArrayList<>();
        String sql = "SELECT o.*, c.customer_name, p.product_name FROM orders o LEFT JOIN customers c ON o.customer_id = c.id LEFT JOIN products p ON o.product_id = p.id ORDER BY o.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapOrder(rs));
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query all orders", e);
        }
        return list;
    }

    public List<Order> getOpenOrdersWithInvoicedSum() {
        List<Order> list = new ArrayList<>();
        String sql = "SELECT o.id, o.order_number, o.total_amount, o.actual_amount, o.quantity, c.customer_name, c.id as cid, "
                + "COALESCE((SELECT SUM(amount) FROM invoices WHERE order_id = o.id), 0) as invoiced_sum "
                + "FROM orders o LEFT JOIN customers c ON o.customer_id = c.id "
                + "WHERE o.close_status = 0 ORDER BY o.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Order o = new Order();
                o.setId(rs.getInt("id"));
                o.setCustomerId(rs.getInt("cid"));
                o.setCustomerName(rs.getString("customer_name"));
                o.setOrderNumber(rs.getString("order_number"));
                o.setTotalAmount(rs.getBigDecimal("total_amount"));
                o.setActualAmount(rs.getBigDecimal("actual_amount"));
                o.setQuantity(rs.getBigDecimal("quantity"));
                o.setInvoicedSum(rs.getBigDecimal("invoiced_sum"));
                list.add(o);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query open orders with invoiced sum", e);
        }
        return list;
    }

    public List<Customer> getCustomers() {
        List<Customer> list = new ArrayList<>();
        String sql = "SELECT id, customer_number, customer_name FROM customers";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Customer c = new Customer();
                c.setId(rs.getInt("id"));
                c.setCustomerNumber(rs.getString("customer_number"));
                c.setCustomerName(rs.getString("customer_name"));
                list.add(c);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query customers for order", e);
        }
        return list;
    }

    public List<Product> getProducts() {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT id, product_code, product_name, price_type, unit_weight, unit_price FROM products";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Product p = new Product();
                p.setId(rs.getInt("id"));
                p.setProductCode(rs.getString("product_code"));
                p.setProductName(rs.getString("product_name"));
                p.setPriceType(rs.getInt("price_type"));
                p.setUnitWeight(rs.getBigDecimal("unit_weight"));
                p.setUnitPrice(rs.getBigDecimal("unit_price"));
                list.add(p);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query products for order", e);
        }
        return list;
    }

    public int countProductions(int orderId) {
        return countByColumn("productions", "order_id", orderId);
    }

    public int countDeliveries(int orderId) {
        return countByColumn("deliveries", "order_id", orderId);
    }

    public int countInvoices(int orderId) {
        return countByColumn("invoices", "order_id", orderId);
    }

    public int countInventoryTransactions(int orderId) {
        return countByColumn("inventory_transactions", "order_id", orderId);
    }

    public java.util.List<java.util.Map<String, Object>> getOpenOrdersForProduction() {
        java.util.List<java.util.Map<String, Object>> list = new java.util.ArrayList<>();
        String sql = "SELECT o.id, o.order_number, c.customer_name, o.expected_delivery_date "
                   + "FROM orders o LEFT JOIN customers c ON o.customer_id = c.id WHERE o.close_status != 1 ORDER BY o.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                java.util.Map<String, Object> row = new java.util.HashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("orderNumber", rs.getString("order_number"));
                row.put("customerName", rs.getString("customer_name"));
                row.put("expectedDeliveryDate", rs.getDate("expected_delivery_date"));
                list.add(row);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query open orders for production", e);
        }
        return list;
    }

    public java.util.List<java.util.Map<String, Object>> getOrderProductionData(int orderId) {
        java.util.List<java.util.Map<String, Object>> list = new java.util.ArrayList<>();
        String sql = "SELECT o.product_id, p.product_name, o.price_type, o.unit_price, o.unit_weight, o.quantity, "
                   + "o.expected_delivery_date, o.actual_amount, "
                   + "(SELECT COALESCE(SUM(manufactured_qty), 0) FROM productions WHERE order_id = o.id AND status != 3) as total_manufactured, "
                   + "(SELECT COUNT(*) FROM productions WHERE order_id = o.id AND status != 3) as production_count, "
                   + "(SELECT COALESCE(SUM(produced_qty), 0) FROM productions WHERE order_id = o.id AND status != 3) as total_produced_qty "
                   + "FROM orders o LEFT JOIN products p ON o.product_id = p.id WHERE o.id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    java.util.Map<String, Object> row = new java.util.HashMap<>();
                    row.put("product_id", rs.getInt("product_id"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("price_type", rs.getInt("price_type"));
                    row.put("unit_price", rs.getBigDecimal("unit_price"));
                    row.put("unit_weight", rs.getBigDecimal("unit_weight"));
                    row.put("quantity", rs.getBigDecimal("quantity"));
                    row.put("total_manufactured", rs.getBigDecimal("total_manufactured"));
                    row.put("production_count", rs.getInt("production_count"));
                    row.put("total_produced_qty", rs.getBigDecimal("total_produced_qty"));
                    row.put("expected_delivery_date", rs.getDate("expected_delivery_date"));
                    row.put("actual_amount", rs.getBigDecimal("actual_amount"));
                    list.add(row);
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query order production data", e);
        }
        return list;
    }

    private int countByColumn(String table, String column, int value) {
        String sql = "SELECT COUNT(*) FROM " + table + " WHERE " + column + " = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, value);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to count related records", e);
        }
        return 0;
    }

    private Order mapOrder(ResultSet rs) throws SQLException {
        Order o = new Order();
        o.setId(rs.getInt("id"));
        o.setCustomerId(rs.getInt("customer_id"));
        o.setCustomerName(rs.getString("customer_name"));
        o.setOrderNumber(rs.getString("order_number"));
        o.setProductId(rs.getInt("product_id"));
        o.setProductName(rs.getString("product_name"));
        o.setPriceType(rs.getInt("price_type"));
        o.setUnitPrice(rs.getBigDecimal("unit_price"));
        o.setUnitWeight(rs.getBigDecimal("unit_weight"));
        o.setQuantity(rs.getBigDecimal("quantity"));
        o.setTotalAmount(rs.getBigDecimal("total_amount"));
        o.setActualAmount(rs.getBigDecimal("actual_amount"));
        o.setAmountDiffReason(rs.getString("amount_diff_reason"));
        o.setOrderDate(rs.getDate("order_date"));
        o.setDeliveryDate(rs.getDate("delivery_date"));
        o.setExpectedDeliveryDate(rs.getDate("expected_delivery_date"));
        o.setStatus(rs.getInt("status"));
        o.setCloseStatus(rs.getInt("close_status"));
        o.setNote(rs.getString("note"));
        o.setCreatedAt(rs.getTimestamp("created_at"));
        o.setUpdatedAt(rs.getTimestamp("updated_at"));
        return o;
    }

    public List<java.util.Map<String, Object>> getOrderList(
            boolean useOrderDate, String dateFrom, String dateTo,
            boolean useExpectedDate, String expectedDateFrom, String expectedDateTo,
            String customerName, String filterOrderNumber, String productKeyword,
            String filterCloseStatus, String filterOrderId, String filterPaymentStatus) {
        List<java.util.Map<String, Object>> list = new ArrayList<>();
        List<String> conditions = new ArrayList<>();
        List<Object> params = new ArrayList<>();
        if (useOrderDate) {
            if (dateFrom != null && !dateFrom.isEmpty()) { conditions.add("o.order_date >= ?"); params.add(dateFrom); }
            if (dateTo != null && !dateTo.isEmpty()) { conditions.add("o.order_date <= ?"); params.add(dateTo); }
        }
        if (useExpectedDate) {
            if (expectedDateFrom != null && !expectedDateFrom.isEmpty()) { conditions.add("o.expected_delivery_date >= ?"); params.add(expectedDateFrom); }
            if (expectedDateTo != null && !expectedDateTo.isEmpty()) { conditions.add("o.expected_delivery_date <= ?"); params.add(expectedDateTo); }
        }
        if (customerName != null && !customerName.trim().isEmpty()) { conditions.add("c.customer_name LIKE ?"); params.add("%" + customerName.trim() + "%"); }
        if (filterOrderNumber != null && !filterOrderNumber.trim().isEmpty()) { conditions.add("o.order_number LIKE ?"); params.add("%" + filterOrderNumber.trim() + "%"); }
        if (productKeyword != null && !productKeyword.trim().isEmpty()) { conditions.add("p.product_name LIKE ?"); params.add("%" + productKeyword.trim() + "%"); }
        if (filterCloseStatus != null && !filterCloseStatus.isEmpty()) {
            conditions.add("o.close_status = ?"); params.add(Integer.parseInt(filterCloseStatus));
        }
        if (filterOrderId != null && !filterOrderId.isEmpty()) {
            conditions.add("o.id = ?"); params.add(Integer.parseInt(filterOrderId));
        }
        if ("shipped_unpaid".equals(filterPaymentStatus)) {
            conditions.add("o.id IN (SELECT d2.order_id FROM deliveries d2 JOIN orders o3 ON d2.order_id = o3.id GROUP BY d2.order_id, o3.quantity HAVING SUM(d2.quantity) >= o3.quantity)");
            conditions.add("(o.id NOT IN (SELECT DISTINCT order_id FROM invoices WHERE order_id IS NOT NULL) OR o.id IN (SELECT order_id FROM invoices GROUP BY order_id HAVING COUNT(*) > 0 AND SUM(CASE WHEN payment_status = 0 THEN 1 ELSE 0 END) = COUNT(*)))");
        } else if ("shipped_paid".equals(filterPaymentStatus)) {
            conditions.add("o.id IN (SELECT d2.order_id FROM deliveries d2 JOIN orders o3 ON d2.order_id = o3.id GROUP BY d2.order_id, o3.quantity HAVING SUM(d2.quantity) >= o3.quantity)");
            conditions.add("o.id IN (SELECT order_id FROM invoices WHERE payment_status = 1 GROUP BY order_id HAVING COUNT(*) > 0)");
        }
        String where = conditions.isEmpty() ? "" : " WHERE " + String.join(" AND ", conditions);
        String sql = "SELECT o.*, c.customer_name, p.product_name, "
            + "(SELECT COUNT(*) FROM productions WHERE order_id = o.id) as prod_count, "
            + "(SELECT COALESCE(SUM(manufactured_qty), 0) FROM productions WHERE order_id = o.id AND status != 3) as total_produced, "
            + "(SELECT COUNT(*) FROM productions WHERE order_id = o.id AND status != 3 AND (manufactured_qty <= 0 OR manufactured_qty IS NULL)) as prod_waiting, "
            + "(SELECT COUNT(*) FROM productions WHERE order_id = o.id AND status != 3 AND manufactured_qty > 0 AND manufactured_qty < produced_qty) as prod_in_progress, "
            + "(SELECT COUNT(*) FROM productions WHERE order_id = o.id AND status != 3 AND produced_qty > 0 AND manufactured_qty >= produced_qty) as prod_completed, "
            + "(SELECT COUNT(*) FROM productions WHERE order_id = o.id AND status = 3) as prod_cancelled, "
            + "(SELECT COALESCE(SUM(d2.quantity), 0) FROM deliveries d2 WHERE d2.order_id = o.id) as total_delivered, "
            + "COALESCE((SELECT SUM(amount) FROM invoices WHERE order_id = o.id), 0) as total_invoiced, "
             + "COALESCE((SELECT SUM(CASE WHEN payment_status = 1 THEN received_amount ELSE 0 END) FROM invoices WHERE order_id = o.id), 0) as total_received, "
            + "(SELECT COUNT(*) FROM invoices WHERE order_id = o.id AND payment_status = 1) as paid_invoice_count, "
            + "(SELECT COUNT(*) FROM invoices WHERE order_id = o.id) as invoice_count, "
            + "(SELECT COUNT(*) FROM deliveries WHERE order_id = o.id) as delivery_count, "
            + "(SELECT COUNT(*) FROM inventory_transactions WHERE order_id = o.id) as inv_txn_count, "
            + "(SELECT COALESCE(SUM(s.quantity), 0) FROM inventory_stock s JOIN inventory_items i ON s.item_id = i.id WHERE i.product_id = o.product_id) as product_stock "
            + "FROM orders o LEFT JOIN customers c ON o.customer_id = c.id LEFT JOIN products p ON o.product_id = p.id" + where + " ORDER BY o.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) {
                Object v = params.get(i);
                if (v instanceof Integer) stmt.setInt(i + 1, (Integer) v);
                else stmt.setString(i + 1, v.toString());
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    java.util.Map<String, Object> row = new java.util.HashMap<>();
                    ResultSetMetaData meta = rs.getMetaData();
                    for (int i = 1; i <= meta.getColumnCount(); i++) {
                        row.put(meta.getColumnLabel(i), rs.getObject(i));
                    }
                    list.add(row);
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query filtered order list", e);
        }
        return list;
    }
}
