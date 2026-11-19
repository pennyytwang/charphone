package dao;

import java.math.BigDecimal;
import java.sql.*;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;

public class SimulationDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(SimulationDao.class.getName());

    public List<Map<String, Object>> getOrderRiskAnalysis() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT o.id, o.order_number, o.product_id, o.quantity, o.expected_delivery_date, o.status, o.close_status, "
                   + "p.product_name, c.customer_name, "
                   + "COALESCE(del.sum_qty, 0) AS delivered_qty, "
                   + "COALESCE(stk.quantity, 0) AS stock_qty "
                   + "FROM orders o "
                   + "JOIN customers c ON o.customer_id = c.id "
                   + "JOIN products p ON o.product_id = p.id "
                   + "LEFT JOIN (SELECT order_id, SUM(quantity) AS sum_qty FROM deliveries GROUP BY order_id) del ON del.order_id = o.id "
                   + "LEFT JOIN (SELECT ii.product_id, s.quantity FROM inventory_items ii JOIN inventory_stock s ON s.item_id = ii.id AND s.warehouse_id = 2) stk ON stk.product_id = o.product_id "
                   + "WHERE o.close_status = 0 AND o.status != 3 "
                   + "HAVING o.quantity > delivered_qty "
                   + "ORDER BY o.expected_delivery_date ASC, o.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                int productId = rs.getInt("product_id");
                String expectedDate = rs.getString("expected_delivery_date");
                BigDecimal totalQty = rs.getBigDecimal("quantity");
                BigDecimal deliveredQty = rs.getBigDecimal("delivered_qty");
                BigDecimal remaining = totalQty.subtract(deliveredQty);
                if (remaining.compareTo(BigDecimal.ZERO) <= 0) continue;

                BigDecimal stockQty = rs.getBigDecimal("stock_qty");
                BigDecimal prodSupply = getProductionSupply(productId, expectedDate != null ? expectedDate : "2099-12-31");
                BigDecimal available = stockQty.add(prodSupply);

                row.put("orderId", rs.getInt("id"));
                row.put("orderNumber", rs.getString("order_number"));
                row.put("productId", productId);
                row.put("productName", rs.getString("product_name"));
                row.put("customerName", rs.getString("customer_name"));
                row.put("totalQty", totalQty);
                row.put("deliveredQty", deliveredQty);
                row.put("remainingQty", remaining);
                row.put("stockQty", stockQty);
                row.put("expectedDate", expectedDate);
                row.put("prodSupply", prodSupply);
                row.put("available", available);

                BigDecimal shortfall = remaining.compareTo(available) > 0 ? remaining.subtract(available) : BigDecimal.ZERO;
                row.put("shortfall", shortfall);

                if (available.compareTo(remaining) >= 0) {
                    row.put("risk", "low");
                } else {
                    BigDecimal ratio = available.compareTo(BigDecimal.ZERO) > 0
                        ? remaining.subtract(available).multiply(new BigDecimal("100")).divide(remaining, 0, BigDecimal.ROUND_HALF_UP)
                        : new BigDecimal("100");
                    row.put("riskPct", ratio);
                    row.put("risk", ratio.compareTo(new BigDecimal("30")) >= 0 ? "high" : "mid");
                }
                list.add(row);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query order risk analysis", e);
        }
        return list;
    }

    private BigDecimal getProductionSupply(int productId, String targetDate) {
        String sql = "SELECT COALESCE(SUM(p.produced_qty - COALESCE(r.net_received, 0)), 0) FROM productions p "
                   + "LEFT JOIN (SELECT ref_id, SUM(CASE WHEN transaction_type=1 THEN quantity WHEN transaction_type=2 THEN -quantity ELSE 0 END) AS net_received FROM inventory_transactions WHERE ref_type='production' GROUP BY ref_id) r ON r.ref_id = p.id "
                   + "WHERE p.product_id = ? AND p.target_date <= ? AND p.status != 3 AND p.produced_qty > COALESCE(r.net_received, 0)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            ps.setString(2, targetDate);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query production supply", e);
        }
        return BigDecimal.ZERO;
    }

    public BigDecimal getStockForProduct3(int productId) {
        String sql = "SELECT COALESCE(s.quantity, 0) AS stock FROM products p "
                   + "LEFT JOIN inventory_items ii ON ii.product_id = p.id "
                   + "LEFT JOIN inventory_stock s ON s.item_id = ii.id AND s.warehouse_id = 2 WHERE p.id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal("stock");
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query product stock", e);
        }
        return BigDecimal.ZERO;
    }

    public Map<String, BigDecimal> getSupplyMap(int productId, String dateFrom, String dateTo) {
        Map<String, BigDecimal> map = new TreeMap<>();
        String sql = "SELECT p.target_date, SUM(p.produced_qty - COALESCE(r.net_received, 0)) AS remaining FROM productions p "
                   + "LEFT JOIN (SELECT ref_id, SUM(CASE WHEN transaction_type=1 THEN quantity WHEN transaction_type=2 THEN -quantity ELSE 0 END) AS net_received FROM inventory_transactions WHERE ref_type='production' GROUP BY ref_id) r ON r.ref_id = p.id "
                   + "WHERE p.product_id = ? AND p.target_date BETWEEN ? AND ? AND p.status != 3 AND p.produced_qty > COALESCE(r.net_received, 0) "
                   + "GROUP BY p.target_date ORDER BY p.target_date";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            ps.setString(2, dateFrom);
            ps.setString(3, dateTo);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) map.put(rs.getString("target_date"), rs.getBigDecimal("remaining"));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query supply map", e);
        }
        return map;
    }

    public Map<String, BigDecimal> getDemandMap(int productId, String dateFrom, String dateTo) {
        Map<String, BigDecimal> map = new TreeMap<>();
        String sql = "SELECT o.expected_delivery_date, SUM(o.quantity - COALESCE(del.sum_qty, 0)) AS remaining FROM orders o "
                   + "LEFT JOIN (SELECT order_id, SUM(quantity) AS sum_qty FROM deliveries GROUP BY order_id) del ON del.order_id = o.id "
                   + "WHERE o.product_id = ? AND o.expected_delivery_date BETWEEN ? AND ? AND o.close_status = 0 AND o.status != 3 "
                   + "AND o.quantity > COALESCE(del.sum_qty, 0) GROUP BY o.expected_delivery_date ORDER BY o.expected_delivery_date";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            ps.setString(2, dateFrom);
            ps.setString(3, dateTo);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) map.put(rs.getString("expected_delivery_date"), rs.getBigDecimal("remaining"));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query demand map", e);
        }
        return map;
    }
}
