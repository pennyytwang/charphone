package dao;

import java.sql.*;
import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.Delivery;

public class DeliveryDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(DeliveryDao.class.getName());

    public String generateDeliveryNumber() {
        String prefix = "DEL-" + new SimpleDateFormat("yyyyMM").format(new Date()) + "-";
        String sql = "SELECT delivery_number FROM deliveries WHERE delivery_number LIKE ? ORDER BY id DESC LIMIT 1 FOR UPDATE";
        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, prefix + "%");
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String last = rs.getString("delivery_number");
                        int seq = Integer.parseInt(last.substring(last.length() - 3)) + 1;
                        conn.commit();
                        return prefix + String.format("%03d", seq);
                    }
                }
            }
            conn.commit();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to generate delivery number", e);
        }
        return prefix + "001";
    }

    public int insertDelivery(Delivery d) {
        String sql = "INSERT INTO deliveries (order_id, delivery_number, delivery_date, quantity, status, note) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, d.getOrderId());
            ps.setString(2, d.getDeliveryNumber());
            ps.setDate(3, d.getDeliveryDate() != null ? new java.sql.Date(d.getDeliveryDate().getTime()) : null);
            ps.setBigDecimal(4, d.getQuantity());
            ps.setInt(5, d.getStatus());
            ps.setString(6, d.getNote());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : -1;
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to insert delivery", e);
            return -1;
        }
    }

    public Delivery getDeliveryById(int id) {
        String sql = "SELECT d.*, o.order_number, c.customer_name FROM deliveries d LEFT JOIN orders o ON d.order_id = o.id LEFT JOIN customers c ON o.customer_id = c.id WHERE d.id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapDelivery(rs);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query delivery by id", e);
        }
        return null;
    }

    public boolean updateDelivery(Delivery d) {
        String sql = "UPDATE deliveries SET order_id=?, delivery_date=?, quantity=?, status=?, note=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, d.getOrderId());
            ps.setDate(2, d.getDeliveryDate() != null ? new java.sql.Date(d.getDeliveryDate().getTime()) : null);
            ps.setBigDecimal(3, d.getQuantity());
            ps.setInt(4, d.getStatus());
            ps.setString(5, d.getNote());
            ps.setInt(6, d.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to update delivery", e);
            return false;
        }
    }

    public List<Delivery> getAllDeliveries() {
        List<Delivery> list = new ArrayList<>();
        String sql = "SELECT d.*, o.order_number, c.customer_name FROM deliveries d LEFT JOIN orders o ON d.order_id = o.id LEFT JOIN customers c ON o.customer_id = c.id ORDER BY d.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapDelivery(rs));
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query all deliveries", e);
        }
        return list;
    }

    public java.util.List<java.util.Map<String, Object>> getOpenOrdersWithStock() {
        java.util.List<java.util.Map<String, Object>> list = new java.util.ArrayList<>();
        String sql = "SELECT o.id, o.order_number, o.quantity, o.product_id, o.price_type, c.customer_name, pr.product_name, "
                   + "(SELECT COALESCE(SUM(d2.quantity), 0) FROM deliveries d2 WHERE d2.order_id = o.id) as total_delivered, "
                   + "COALESCE((SELECT s.quantity FROM inventory_stock s JOIN inventory_items ii ON s.item_id = ii.id WHERE ii.product_id = o.product_id AND s.warehouse_id = 2), 0) as stock_qty "
                   + "FROM orders o LEFT JOIN customers c ON o.customer_id = c.id LEFT JOIN products pr ON o.product_id = pr.id "
                   + "WHERE o.close_status = 0 AND o.status != 9 ORDER BY o.id DESC";
        try (Connection conn = getConnection();
             java.sql.Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                double remain = rs.getDouble("quantity") - rs.getDouble("total_delivered");
                if (remain <= 0) continue;
                java.util.Map<String, Object> row = new java.util.HashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("orderNumber", rs.getString("order_number"));
                row.put("customerName", rs.getString("customer_name"));
                row.put("productName", rs.getString("product_name"));
                row.put("quantity", rs.getBigDecimal("quantity"));
                row.put("totalDelivered", rs.getBigDecimal("total_delivered"));
                row.put("remain", remain);
                row.put("stockQty", rs.getBigDecimal("stock_qty"));
                list.add(row);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query open orders with stock", e);
        }
        return list;
    }

    public Object[] getRemainingInfo(int orderId, int excludeDeliveryId) {
        String sql = "SELECT o.quantity AS order_qty, o.product_id, o.price_type, "
                   + "COALESCE((SELECT SUM(d.quantity) FROM deliveries d WHERE d.order_id = o.id AND d.status = 1 AND d.id != ?), 0) AS total_delivered "
                   + "FROM orders o WHERE o.id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, excludeDeliveryId);
            ps.setInt(2, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Object[] {
                        rs.getBigDecimal("order_qty"),
                        rs.getBigDecimal("total_delivered"),
                        rs.getInt("product_id"),
                        rs.getInt("price_type")
                    };
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query remaining delivery info", e);
        }
        return null;
    }

    public Object[] getDeliverySummaryByOrderId(int orderId) {
        String sql = "SELECT COALESCE(SUM(quantity), 0) as delivered, MAX(delivery_date) as last_date FROM deliveries WHERE order_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Object[] {
                        rs.getBigDecimal("delivered"),
                        rs.getDate("last_date")
                    };
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query delivery summary", e);
        }
        return new Object[] { java.math.BigDecimal.ZERO, null };
    }

    public Object[] getOrderInfo(int orderId) {
        String sql = "SELECT product_id, price_type FROM orders WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Object[] { rs.getInt("product_id"), rs.getInt("price_type") };
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query order info for delivery", e);
        }
        return null;
    }

    public boolean hasStock(int productId, BigDecimal requiredQty) {
        String sql = "SELECT COALESCE((SELECT s.quantity FROM inventory_stock s JOIN inventory_items i ON s.item_id=i.id WHERE i.product_id=? AND s.warehouse_id=2), 0)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getBigDecimal(1).compareTo(requiredQty) >= 0;
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to check stock availability", e);
        }
        return false;
    }

    public java.util.Map<String, Object> getOrderDeliveryInfo(int orderId) {
        java.util.Map<String, Object> result = new java.util.HashMap<>();
        String sql = "SELECT o.order_number, c.customer_name, o.quantity, o.price_type, pr.product_name, "
                   + "COALESCE((SELECT SUM(d2.quantity) FROM deliveries d2 WHERE d2.order_id = o.id), 0) as total_delivered, "
                   + "COALESCE((SELECT s.quantity FROM inventory_stock s JOIN inventory_items ii ON s.item_id = ii.id WHERE ii.product_id = o.product_id AND s.warehouse_id = 2), 0) as stock_qty "
                   + "FROM orders o "
                   + "LEFT JOIN customers c ON o.customer_id = c.id "
                   + "LEFT JOIN products pr ON o.product_id = pr.id "
                   + "WHERE o.id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    result.put("orderNumber", rs.getString("order_number"));
                    result.put("customerName", rs.getString("customer_name"));
                    result.put("quantity", rs.getDouble("quantity"));
                    result.put("priceType", rs.getInt("price_type"));
                    result.put("productName", rs.getString("product_name"));
                    result.put("totalDelivered", rs.getDouble("total_delivered"));
                    result.put("stockQty", rs.getDouble("stock_qty"));
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query order delivery info", e);
        }
        return result;
    }

    public java.util.List<java.util.Map<String, Object>> getFilteredDeliveryList(
            String dateFrom, String dateTo, String filterCustomer, String filterOrderNumber,
            String filterProduct, int orderId, boolean isFiltered) {
        java.util.List<java.util.Map<String, Object>> list = new java.util.ArrayList<>();
        java.util.List<String> conds = new java.util.ArrayList<>();
        java.util.List<Object> params = new java.util.ArrayList<>();

        if (dateFrom != null && !dateFrom.isEmpty()) { conds.add("d.delivery_date >= ?"); params.add(dateFrom); }
        if (dateTo != null && !dateTo.isEmpty()) { conds.add("d.delivery_date <= ?"); params.add(dateTo); }
        if (filterCustomer != null && !filterCustomer.trim().isEmpty()) {
            conds.add("c.customer_name LIKE ?"); params.add("%" + filterCustomer.trim() + "%");
        }
        if (filterOrderNumber != null && !filterOrderNumber.trim().isEmpty()) {
            conds.add("o.order_number LIKE ?"); params.add("%" + filterOrderNumber.trim() + "%");
        }
        if (filterProduct != null && !filterProduct.trim().isEmpty()) {
            conds.add("pr.product_name LIKE ?"); params.add("%" + filterProduct.trim() + "%");
        }
        if (isFiltered) {
            conds.add("d.order_id = ?"); params.add(orderId);
        }
        String whereClause = conds.isEmpty() ? "" : " WHERE " + String.join(" AND ", conds);
        String sql = "SELECT d.*, o.id as order_id, o.order_number, o.quantity as order_qty, o.expected_delivery_date, o.price_type, "
                   + "c.customer_name, pr.product_name as delivery_product_name "
                   + "FROM deliveries d "
                   + "LEFT JOIN orders o ON d.order_id = o.id "
                   + "LEFT JOIN customers c ON o.customer_id = c.id "
                   + "LEFT JOIN products pr ON o.product_id = pr.id"
                   + whereClause + " ORDER BY d.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) {
                Object v = params.get(i);
                if (v instanceof Integer) ps.setInt(i + 1, (Integer) v);
                else ps.setString(i + 1, v.toString());
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    java.util.Map<String, Object> row = new java.util.HashMap<>();
                    row.put("deliveryId", rs.getInt("id"));
                    row.put("deliveryNumber", rs.getString("delivery_number"));
                    row.put("deliveryDate", rs.getDate("delivery_date"));
                    row.put("deliveryQty", rs.getBigDecimal("quantity"));
                    row.put("note", rs.getString("note"));
                    row.put("orderId", rs.getInt("order_id"));
                    row.put("orderNumber", rs.getString("order_number"));
                    row.put("orderQty", rs.getBigDecimal("order_qty"));
                    row.put("expectedDeliveryDate", rs.getDate("expected_delivery_date"));
                    row.put("priceType", rs.getInt("price_type"));
                    row.put("customerName", rs.getString("customer_name"));
                    row.put("deliveryProductName", rs.getString("delivery_product_name"));
                    list.add(row);
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query filtered delivery list", e);
        }
        return list;
    }

    private Delivery mapDelivery(ResultSet rs) throws SQLException {
        Delivery d = new Delivery();
        d.setId(rs.getInt("id"));
        d.setOrderId(rs.getInt("order_id"));
        d.setOrderNumber(rs.getString("order_number"));
        d.setCustomerName(rs.getString("customer_name"));
        d.setDeliveryNumber(rs.getString("delivery_number"));
        d.setDeliveryDate(rs.getDate("delivery_date"));
        d.setQuantity(rs.getBigDecimal("quantity"));
        d.setStatus(rs.getInt("status"));
        d.setNote(rs.getString("note"));
        return d;
    }
}