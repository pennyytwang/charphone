package dao;

import java.sql.*;
import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.Production;

public class ProductionDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(ProductionDao.class.getName());

    public String generateProductionNumber() {
        String prefix = "PRD-" + new SimpleDateFormat("yyyyMM").format(new Date()) + "-";
        String sql = "SELECT production_number FROM productions WHERE production_number LIKE ? ORDER BY id DESC LIMIT 1 FOR UPDATE";
        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, prefix + "%");
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String last = rs.getString("production_number");
                        int seq = Integer.parseInt(last.substring(last.length() - 3)) + 1;
                        conn.commit();
                        return prefix + String.format("%03d", seq);
                    }
                }
            }
            conn.commit();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to generate production number", e);
        }
        return prefix + "001";
    }

    public boolean insertProduction(Production p) {
        String sql = "INSERT INTO productions (order_id, production_number, product_id, price_type, unit_price, unit_weight, quantity, produced_qty, manufactured_qty, status, close_status, start_date, target_date, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, p.getOrderId());
            ps.setString(2, p.getProductionNumber());
            ps.setInt(3, p.getProductId());
            ps.setInt(4, p.getPriceType());
            ps.setBigDecimal(5, p.getUnitPrice());
            ps.setBigDecimal(6, p.getUnitWeight());
            ps.setBigDecimal(7, p.getQuantity());
            ps.setBigDecimal(8, p.getProducedQty() != null ? p.getProducedQty() : BigDecimal.ZERO);
            ps.setBigDecimal(9, p.getManufacturedQty() != null ? p.getManufacturedQty() : BigDecimal.ZERO);
            ps.setInt(10, p.getStatus());
            ps.setInt(11, p.getCloseStatus());
            ps.setDate(12, p.getStartDate() != null ? new java.sql.Date(p.getStartDate().getTime()) : null);
            ps.setDate(13, p.getTargetDate() != null ? new java.sql.Date(p.getTargetDate().getTime()) : null);
            ps.setString(14, p.getNote());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to insert production", e);
            return false;
        }
    }

    public Production getProductionById(int id) {
        String sql = "SELECT p.*, o.order_number, o.quantity as order_quantity, c.customer_name, pr.product_name FROM productions p LEFT JOIN orders o ON p.order_id = o.id LEFT JOIN customers c ON o.customer_id = c.id LEFT JOIN products pr ON p.product_id = pr.id WHERE p.id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapProduction(rs);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query production by id", e);
        }
        return null;
    }

    public boolean updateProduction(Production p) {
        String sql = "UPDATE productions SET order_id=?, product_id=?, price_type=?, unit_price=?, unit_weight=?, quantity=?, produced_qty=?, manufactured_qty=?, status=?, close_status=?, start_date=?, target_date=?, completed_date=?, note=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, p.getOrderId());
            ps.setInt(2, p.getProductId());
            ps.setInt(3, p.getPriceType());
            ps.setBigDecimal(4, p.getUnitPrice());
            ps.setBigDecimal(5, p.getUnitWeight());
            ps.setBigDecimal(6, p.getQuantity());
            ps.setBigDecimal(7, p.getProducedQty() != null ? p.getProducedQty() : BigDecimal.ZERO);
            ps.setBigDecimal(8, p.getManufacturedQty() != null ? p.getManufacturedQty() : BigDecimal.ZERO);
            ps.setInt(9, p.getStatus());
            ps.setInt(10, p.getCloseStatus());
            ps.setDate(11, p.getStartDate() != null ? new java.sql.Date(p.getStartDate().getTime()) : null);
            ps.setDate(12, p.getTargetDate() != null ? new java.sql.Date(p.getTargetDate().getTime()) : null);
            ps.setDate(13, p.getCompletedDate() != null ? new java.sql.Date(p.getCompletedDate().getTime()) : null);
            ps.setString(14, p.getNote());
            ps.setInt(15, p.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to update production", e);
            return false;
        }
    }

    public boolean deleteProduction(int id) {
        String sql = "DELETE FROM productions WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to delete production", e);
            return false;
        }
    }

    public List<Production> getAllProductions() {
        List<Production> list = new ArrayList<>();
        String sql = "SELECT p.*, o.order_number, o.quantity as order_quantity, c.customer_name, pr.product_name FROM productions p LEFT JOIN orders o ON p.order_id = o.id LEFT JOIN customers c ON o.customer_id = c.id LEFT JOIN products pr ON p.product_id = pr.id ORDER BY p.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapProduction(rs));
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query all productions", e);
        }
        return list;
    }

    public BigDecimal getReceivedQty(int productionId) {
        String sql = "SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type='production' AND ref_id=? AND transaction_type=1";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query received quantity", e);
        }
        return BigDecimal.ZERO;
    }

    public BigDecimal getReversedQty(int productionId) {
        String sql = "SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type='production' AND ref_id=? AND transaction_type=2";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query reversed quantity", e);
        }
        return BigDecimal.ZERO;
    }

    /**
     * 查詢指定工單的淨入庫數量（入庫總量 - 沖正總量）。
     * @param productionId 工單 ID
     * @return 淨入庫數量
     */
    public BigDecimal getNetReceivedQty(int productionId) {
        String sql = "SELECT "
                   + "(SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type='production' AND ref_id=? AND transaction_type=1) "
                   + "- "
                   + "(SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type='production' AND ref_id=? AND transaction_type=2)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productionId);
            ps.setInt(2, productionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query net received quantity", e);
        }
        return BigDecimal.ZERO;
    }

    public BigDecimal getOtherManufacturedQty(int orderId, int excludeProductionId) {
        String sql = "SELECT COALESCE(SUM(manufactured_qty), 0) FROM productions WHERE order_id=? AND id!=? AND status!=3";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, excludeProductionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query other manufactured quantity", e);
        }
        return BigDecimal.ZERO;
    }

    public String getExpectedDeliveryDate(int orderId) {
        String sql = "SELECT expected_delivery_date FROM orders WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getDate("expected_delivery_date") != null) {
                    return new java.text.SimpleDateFormat("yyyy-MM-dd").format(rs.getDate("expected_delivery_date"));
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query expected delivery date", e);
        }
        return "";
    }

    public Object[] getOrderDeliveryAndAmount(int orderId) {
        String sql = "SELECT expected_delivery_date, actual_amount FROM orders WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Object[] {
                        rs.getDate("expected_delivery_date"),
                        rs.getBigDecimal("actual_amount")
                    };
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query order delivery and amount", e);
        }
        return new Object[] { null, null };
    }

    public Object[] getReceivedInfo(int productionId) {
        String sql = "SELECT COALESCE(SUM(t.quantity), 0) AS rcv, p.product_id, p.order_id "
                   + "FROM productions p LEFT JOIN inventory_transactions t "
                   + "ON t.ref_type='production' AND t.ref_id=p.id AND t.transaction_type=1 "
                   + "WHERE p.id=? GROUP BY p.product_id, p.order_id";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productionId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Object[] {
                        rs.getInt("product_id"),
                        rs.getInt("order_id"),
                        rs.getBigDecimal("rcv")
                    };
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query received info", e);
        }
        return new Object[] { 0, 0, BigDecimal.ZERO };
    }

    public java.util.Map<String, Object> getOrderProductionSummary(int orderId) {
        java.util.Map<String, Object> result = new java.util.HashMap<>();
        String sql = "SELECT o.order_number, c.customer_name, o.quantity, "
                   + "COALESCE((SELECT SUM(manufactured_qty) FROM productions WHERE order_id = o.id AND status != 3), 0) as manuf, "
                   + "(SELECT COUNT(*) FROM productions WHERE order_id = o.id) as wo_count, "
                   + "(SELECT COUNT(*) FROM productions WHERE order_id = o.id AND status != 3 AND manufactured_qty >= produced_qty AND produced_qty > 0) as wo_completed, "
                   + "(SELECT COUNT(*) FROM productions p2 WHERE p2.order_id = o.id AND p2.status != 3 AND p2.manufactured_qty > 0 "
                   + "AND (SELECT COALESCE(SUM(t.quantity), 0) FROM inventory_transactions t WHERE t.ref_type = 'production' AND t.ref_id = p2.id AND t.transaction_type = 1) >= p2.manufactured_qty) as wo_received "
                   + "FROM orders o LEFT JOIN customers c ON o.customer_id = c.id WHERE o.id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    result.put("orderNumber", rs.getString("order_number"));
                    result.put("customerName", rs.getString("customer_name"));
                    result.put("quantity", rs.getDouble("quantity"));
                    result.put("manuf", rs.getDouble("manuf"));
                    result.put("woCount", rs.getInt("wo_count"));
                    result.put("woCompleted", rs.getInt("wo_completed"));
                    result.put("woReceived", rs.getInt("wo_received"));
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query order production summary", e);
        }
        return result;
    }

    public java.util.List<java.util.Map<String, Object>> getFilteredProductionList(
            int orderId, String dateFrom, String dateTo,
            String filterCustomer, String filterOrderNumber, String filterProduct,
            String keyword, String closeStatus, String prodStatus,
            boolean isFiltered, boolean dateEnabled) {
        java.util.List<java.util.Map<String, Object>> list = new java.util.ArrayList<>();
        java.util.List<String> conds = new java.util.ArrayList<>();
        java.util.List<Object> params = new java.util.ArrayList<>();

        if (isFiltered) {
            conds.add("p.order_id = ?"); params.add(orderId);
        }
        if (!isFiltered && dateEnabled && dateFrom != null && !dateFrom.isEmpty()) {
            conds.add("p.start_date >= ?"); params.add(dateFrom);
        }
        if (!isFiltered && dateEnabled && dateTo != null && !dateTo.isEmpty()) {
            conds.add("p.start_date <= ?"); params.add(dateTo);
        }
        if (!isFiltered && filterCustomer != null && !filterCustomer.trim().isEmpty()) {
            conds.add("c.customer_name LIKE ?"); params.add("%" + filterCustomer.trim() + "%");
        }
        if (!isFiltered && filterOrderNumber != null && !filterOrderNumber.trim().isEmpty()) {
            conds.add("o.order_number LIKE ?"); params.add("%" + filterOrderNumber.trim() + "%");
        }
        if (!isFiltered && filterProduct != null && !filterProduct.trim().isEmpty()) {
            conds.add("pr.product_name LIKE ?"); params.add("%" + filterProduct.trim() + "%");
        }
        if (!isFiltered && keyword != null && !keyword.trim().isEmpty()) {
            conds.add("(c.customer_name LIKE ? OR p.production_number LIKE ? OR pr.product_name LIKE ?)");
            params.add("%" + keyword.trim() + "%"); params.add("%" + keyword.trim() + "%"); params.add("%" + keyword.trim() + "%");
        }
        if (!isFiltered && closeStatus != null && !closeStatus.isEmpty()) {
            if ("1".equals(closeStatus)) {
                conds.add("p.close_status = 1");
            } else if ("0".equals(closeStatus)) {
                conds.add("p.close_status != 1");
            }
        }
        if (!isFiltered && prodStatus != null && !prodStatus.isEmpty()) {
            if ("3".equals(prodStatus)) {
                conds.add("p.status = 3");
            } else if ("2".equals(prodStatus)) {
                conds.add("p.status != 3 AND p.manufactured_qty >= p.produced_qty AND p.produced_qty > 0");
            } else if ("1".equals(prodStatus)) {
                conds.add("p.status != 3 AND p.manufactured_qty > 0 AND (p.manufactured_qty < p.produced_qty OR p.produced_qty <= 0)");
            } else if ("0".equals(prodStatus)) {
                conds.add("p.status != 3 AND (p.manufactured_qty = 0 OR p.manufactured_qty IS NULL)");
            }
        }

        String whereClause = conds.isEmpty() ? "" : " WHERE " + String.join(" AND ", conds);
        String sql = "SELECT p.*, o.id as order_id, o.order_number, o.quantity as order_quantity, "
                   + "c.id as customer_id, c.customer_name, pr.product_name, pr.price_type, "
                   + "(SELECT COALESCE(SUM(manufactured_qty), 0) FROM productions WHERE order_id = p.order_id AND status != 3) as order_total_manufactured, "
                   + "(SELECT COUNT(*) FROM productions WHERE order_id = p.order_id) as order_wo_count, "
                   + "(SELECT COUNT(*) FROM productions WHERE order_id = p.order_id AND status != 3 AND manufactured_qty >= produced_qty AND produced_qty > 0) as order_wo_completed, "
                   + "(SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type = 'production' AND ref_id = p.id AND transaction_type = 1) as production_received_qty, "
                   + "(SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type = 'production' AND ref_id = p.id AND transaction_type = 1) - "
                   + "(SELECT COALESCE(SUM(quantity), 0) FROM inventory_transactions WHERE ref_type = 'production' AND ref_id = p.id AND transaction_type = 2) as production_net_received, "
                   + "(SELECT COUNT(*) FROM productions p2 WHERE p2.order_id = p.order_id AND p2.status != 3 AND p2.manufactured_qty > 0 "
                   + "AND (SELECT COALESCE(SUM(t.quantity), 0) FROM inventory_transactions t WHERE t.ref_type = 'production' AND t.ref_id = p2.id AND t.transaction_type = 1) >= p2.manufactured_qty) as order_wo_received "
                   + "FROM productions p "
                   + "LEFT JOIN orders o ON p.order_id = o.id "
                   + "LEFT JOIN customers c ON o.customer_id = c.id "
                   + "LEFT JOIN products pr ON p.product_id = pr.id "
                   + whereClause
                   + (isFiltered ? " ORDER BY p.id" : " ORDER BY c.customer_name, o.order_number, p.id");
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
                    row.put("id", rs.getInt("id"));
                    row.put("customerId", rs.getInt("customer_id"));
                    row.put("orderId", rs.getInt("order_id"));
                    row.put("customerName", rs.getString("customer_name"));
                    row.put("orderNumber", rs.getString("order_number"));
                    row.put("orderQuantity", rs.getDouble("order_quantity"));
                    row.put("productionNumber", rs.getString("production_number"));
                    row.put("productName", rs.getString("product_name"));
                    row.put("priceType", rs.getInt("price_type"));
                    row.put("producedQty", rs.getDouble("produced_qty"));
                    row.put("manufacturedQty", rs.getDouble("manufactured_qty"));
                    row.put("status", rs.getInt("status"));
                    row.put("closeStatus", rs.getInt("close_status"));
                    row.put("startDate", rs.getDate("start_date"));
                    row.put("targetDate", rs.getDate("target_date"));
                    row.put("updatedAt", rs.getTimestamp("updated_at"));
                    row.put("receivedQty", rs.getDouble("production_received_qty"));
                    row.put("netReceived", rs.getDouble("production_net_received"));
                    row.put("orderTotalManufactured", rs.getDouble("order_total_manufactured"));
                    row.put("orderWoCount", rs.getInt("order_wo_count"));
                    row.put("orderWoCompleted", rs.getInt("order_wo_completed"));
                    row.put("orderWoReceived", rs.getInt("order_wo_received"));
                    list.add(row);
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query filtered production list", e);
        }
        return list;
    }

    public java.util.List<java.util.Map<String, Object>> getProductionsByProductAndDate(int productId, String targetDate) {
        java.util.List<java.util.Map<String, Object>> list = new java.util.ArrayList<>();
        String sql = "SELECT p.id, p.production_number, p.produced_qty, p.target_date, p.status, "
                   + "COALESCE(r.net_received, 0) AS received FROM productions p "
                   + "LEFT JOIN (SELECT ref_id, SUM(CASE WHEN transaction_type=1 THEN quantity WHEN transaction_type=2 THEN -quantity ELSE 0 END) AS net_received FROM inventory_transactions WHERE ref_type='production' GROUP BY ref_id) r ON r.ref_id = p.id "
                   + "WHERE p.product_id = ? AND p.target_date <= ? AND p.status != 3 ORDER BY p.target_date";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            ps.setString(2, targetDate);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    java.util.Map<String, Object> row = new java.util.HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("num", rs.getString("production_number"));
                    row.put("planned", rs.getBigDecimal("produced_qty"));
                    row.put("target", rs.getString("target_date"));
                    row.put("status", rs.getInt("status"));
                    row.put("received", rs.getBigDecimal("received"));
                    list.add(row);
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query productions by product and date", e);
        }
        return list;
    }

    public java.util.List<java.util.Map<String, Object>> getReceiptTransactions(int productionId) {
        java.util.List<java.util.Map<String, Object>> list = new java.util.ArrayList<>();
        String sql = "SELECT t.id, t.transaction_number, t.quantity, t.balance_before, t.balance_after, t.note, t.created_at, "
                   + "COALESCE((SELECT SUM(quantity) FROM inventory_transactions WHERE ref_type='production' AND ref_id=t.ref_id AND transaction_type=2 AND created_at <= t.created_at), 0) as reversed_up_to "
                   + "FROM inventory_transactions t WHERE t.ref_type='production' AND t.ref_id=? AND t.transaction_type=1 ORDER BY t.created_at DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productionId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    java.util.Map<String, Object> row = new java.util.HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("txnNumber", rs.getString("transaction_number"));
                    row.put("quantity", rs.getBigDecimal("quantity"));
                    row.put("balanceBefore", rs.getBigDecimal("balance_before"));
                    row.put("balanceAfter", rs.getBigDecimal("balance_after"));
                    row.put("note", rs.getString("note"));
                    row.put("createdAt", rs.getTimestamp("created_at"));
                    row.put("reversedUpTo", rs.getBigDecimal("reversed_up_to"));
                    list.add(row);
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query receipt transactions", e);
        }
        return list;
    }

    public BigDecimal getStockForProduct(int productId) {
        String sql = "SELECT COALESCE((SELECT s.quantity FROM inventory_stock s "
                   + "JOIN inventory_items i ON s.item_id=i.id "
                   + "WHERE i.product_id=? AND s.warehouse_id=2), 0)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query stock for product", e);
        }
        return BigDecimal.ZERO;
    }

    private Production mapProduction(ResultSet rs) throws SQLException {
        Production p = new Production();
        p.setId(rs.getInt("id"));
        p.setOrderId(rs.getInt("order_id"));
        p.setOrderNumber(rs.getString("order_number"));
        p.setCustomerName(rs.getString("customer_name"));
        p.setProductionNumber(rs.getString("production_number"));
        p.setProductId(rs.getInt("product_id"));
        p.setProductName(rs.getString("product_name"));
        p.setPriceType(rs.getInt("price_type"));
        p.setUnitPrice(rs.getBigDecimal("unit_price"));
        p.setUnitWeight(rs.getBigDecimal("unit_weight"));
        p.setQuantity(rs.getBigDecimal("quantity"));
        p.setProducedQty(rs.getBigDecimal("produced_qty"));
        p.setManufacturedQty(rs.getBigDecimal("manufactured_qty"));
        p.setOrderQuantity(rs.getBigDecimal("order_quantity"));
        p.setStatus(rs.getInt("status"));
        p.setCloseStatus(rs.getInt("close_status"));
        p.setStartDate(rs.getDate("start_date"));
        p.setTargetDate(rs.getDate("target_date"));
        p.setCompletedDate(rs.getDate("completed_date"));
        p.setNote(rs.getString("note"));
        p.setCreatedAt(rs.getTimestamp("created_at"));
        p.setUpdatedAt(rs.getTimestamp("updated_at"));
        return p;
    }
}
