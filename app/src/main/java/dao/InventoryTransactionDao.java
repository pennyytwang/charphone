package dao;

import java.sql.*;
import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.InventoryTransaction;

public class InventoryTransactionDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(InventoryTransactionDao.class.getName());

    public String generateTransactionNumber() {
        String prefix = "IVT-" + new SimpleDateFormat("yyyyMMdd").format(new Date()) + "-";
        String sql = "SELECT transaction_number FROM inventory_transactions WHERE transaction_number LIKE ? ORDER BY id DESC LIMIT 1 FOR UPDATE";
        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, prefix + "%");
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String last = rs.getString("transaction_number");
                        int seq = Integer.parseInt(last.substring(last.length() - 3)) + 1;
                        conn.commit();
                        return prefix + String.format("%03d", seq);
                    }
                }
            }
            conn.commit();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to generate transaction number", e);
        }
        return prefix + "001";
    }

    public boolean createTransaction(InventoryTransaction t) {
        String sql = "INSERT INTO inventory_transactions (transaction_number, warehouse_id, item_id, transaction_type, quantity, balance_before, balance_after, ref_type, ref_id, order_id, production_id, note, created_by) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        Connection conn = null;
        try {
            conn = getConnection();
            conn.setAutoCommit(false);

            BigDecimal before = BigDecimal.ZERO;
            String qry = "SELECT quantity FROM inventory_stock WHERE warehouse_id = ? AND item_id = ?";
            try (PreparedStatement psQ = conn.prepareStatement(qry)) {
                psQ.setInt(1, t.getWarehouseId());
                psQ.setInt(2, t.getItemId());
                try (ResultSet rs = psQ.executeQuery()) {
                    if (rs.next()) before = rs.getBigDecimal("quantity");
                }
            }

            BigDecimal after = before.add(t.getQuantity());

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, t.getTransactionNumber());
                ps.setInt(2, t.getWarehouseId());
                ps.setInt(3, t.getItemId());
                ps.setInt(4, t.getTransactionType());
                ps.setBigDecimal(5, t.getQuantity());
                ps.setBigDecimal(6, before);
                ps.setBigDecimal(7, after);
                ps.setString(8, t.getRefType());
                if (t.getRefId() != null) {
                    ps.setInt(9, t.getRefId());
                } else {
                    ps.setNull(9, Types.INTEGER);
                }
                if (t.getOrderId() != null) {
                    ps.setInt(10, t.getOrderId());
                } else {
                    ps.setNull(10, Types.INTEGER);
                }
                if (t.getProductionId() != null) {
                    ps.setInt(11, t.getProductionId());
                } else {
                    ps.setNull(11, Types.INTEGER);
                }
                ps.setString(12, t.getNote());
                if (t.getCreatedBy() != null) {
                    ps.setInt(13, t.getCreatedBy());
                } else {
                    ps.setNull(13, Types.INTEGER);
                }
                ps.executeUpdate();
            }

            String upsert = "INSERT INTO inventory_stock (warehouse_id, item_id, quantity) VALUES (?, ?, ?) "
                          + "ON DUPLICATE KEY UPDATE quantity = VALUES(quantity)";
            try (PreparedStatement psU = conn.prepareStatement(upsert)) {
                psU.setInt(1, t.getWarehouseId());
                psU.setInt(2, t.getItemId());
                psU.setBigDecimal(3, after);
                psU.executeUpdate();
            }

            conn.commit();
            return true;
        } catch (Exception e) {
            if (conn != null) try { conn.rollback(); } catch (SQLException ex) {}
            LOGGER.log(Level.SEVERE, "Failed to create inventory transaction", e);
            return false;
        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException e) {}
        }
    }

    public List<InventoryTransaction> getAllTransactions(String dateFrom, String dateTo, String keyword) {
        List<InventoryTransaction> list = new ArrayList<>();
        String sql = "SELECT t.*, w.warehouse_name, i.item_code, i.item_name, "
                   + "o.order_number, p.production_number "
                   + "FROM inventory_transactions t "
                   + "JOIN warehouses w ON t.warehouse_id = w.id "
                   + "JOIN inventory_items i ON t.item_id = i.id "
                   + "LEFT JOIN orders o ON t.order_id = o.id "
                   + "LEFT JOIN productions p ON t.production_id = p.id";
        List<String> conds = new ArrayList<>();
        List<Object> params = new ArrayList<>();
        if (dateFrom != null && !dateFrom.isEmpty()) {
            conds.add("DATE(t.created_at) >= ?"); params.add(dateFrom);
        }
        if (dateTo != null && !dateTo.isEmpty()) {
            conds.add("DATE(t.created_at) <= ?"); params.add(dateTo);
        }
        if (keyword != null && !keyword.trim().isEmpty()) {
            String k = "%" + keyword.trim() + "%";
            conds.add("(t.transaction_number LIKE ? OR i.item_name LIKE ? OR i.item_code LIKE ?)");
            params.add(k); params.add(k); params.add(k);
        }
        if (!conds.isEmpty()) sql += " WHERE " + String.join(" AND ", conds);
        sql += " ORDER BY t.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i).toString());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                InventoryTransaction t = new InventoryTransaction();
                t.setId(rs.getInt("id"));
                t.setTransactionNumber(rs.getString("transaction_number"));
                t.setWarehouseId(rs.getInt("warehouse_id"));
                t.setWarehouseName(rs.getString("warehouse_name"));
                t.setItemId(rs.getInt("item_id"));
                t.setItemCode(rs.getString("item_code"));
                t.setItemName(rs.getString("item_name"));
                t.setTransactionType(rs.getInt("transaction_type"));
                t.setQuantity(rs.getBigDecimal("quantity"));
                t.setBalanceBefore(rs.getBigDecimal("balance_before"));
                t.setBalanceAfter(rs.getBigDecimal("balance_after"));
                t.setRefType(rs.getString("ref_type"));
                int rid = rs.getInt("ref_id");
                if (!rs.wasNull()) t.setRefId(rid);
                int oid = rs.getInt("order_id");
                if (!rs.wasNull()) t.setOrderId(oid);
                int pid = rs.getInt("production_id");
                if (!rs.wasNull()) t.setProductionId(pid);
                t.setOrderNumber(rs.getString("order_number"));
                t.setProductionNumber(rs.getString("production_number"));
                t.setNote(rs.getString("note"));
                t.setCreatedAt(rs.getString("created_at"));
                list.add(t);
            }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query all inventory transactions", e);
        }
        return list;
    }
}
