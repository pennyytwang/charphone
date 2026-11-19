package dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.InventoryItem;

public class InventoryItemDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(InventoryItemDao.class.getName());

    public boolean insertItem(InventoryItem item) {
        String sql = "INSERT INTO inventory_items (item_code, item_name, item_type, product_id, unit, unit_cost, safety_stock, status, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, item.getItemCode());
            ps.setString(2, item.getItemName());
            ps.setInt(3, item.getItemType());
            if (item.getProductId() != null) {
                ps.setInt(4, item.getProductId());
            } else {
                ps.setNull(4, Types.INTEGER);
            }
            ps.setString(5, item.getUnit());
            ps.setBigDecimal(6, item.getUnitCost());
            ps.setBigDecimal(7, item.getSafetyStock());
            ps.setInt(8, item.getStatus());
            ps.setString(9, item.getNote());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to insert inventory item", e);
            return false;
        }
    }

    public InventoryItem getItemById(int id) {
        String sql = "SELECT ii.*, p.product_name FROM inventory_items ii LEFT JOIN products p ON ii.product_id = p.id WHERE ii.id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapItem(rs);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query inventory item by id", e);
        }
        return null;
    }

    public InventoryItem findByProductId(int productId) {
        String sql = "SELECT ii.*, p.product_name FROM inventory_items ii LEFT JOIN products p ON ii.product_id = p.id WHERE ii.product_id = ? LIMIT 1";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapItem(rs);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to find inventory item by product id", e);
        }
        return null;
    }

    public boolean updateItem(InventoryItem item) {
        String sql = "UPDATE inventory_items SET item_code=?, item_name=?, item_type=?, product_id=?, unit=?, unit_cost=?, safety_stock=?, status=?, note=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, item.getItemCode());
            ps.setString(2, item.getItemName());
            ps.setInt(3, item.getItemType());
            if (item.getProductId() != null) {
                ps.setInt(4, item.getProductId());
            } else {
                ps.setNull(4, Types.INTEGER);
            }
            ps.setString(5, item.getUnit());
            ps.setBigDecimal(6, item.getUnitCost());
            ps.setBigDecimal(7, item.getSafetyStock());
            ps.setInt(8, item.getStatus());
            ps.setString(9, item.getNote());
            ps.setInt(10, item.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to update inventory item", e);
            return false;
        }
    }

    public List<InventoryItem> getAllItems(String keyword) {
        List<InventoryItem> list = new ArrayList<>();
        String sql = "SELECT ii.*, p.product_name FROM inventory_items ii LEFT JOIN products p ON ii.product_id = p.id";
        List<String> conds = new ArrayList<>();
        List<Object> params = new ArrayList<>();
        if (keyword != null && !keyword.trim().isEmpty()) {
            String k = "%" + keyword.trim() + "%";
            conds.add("(ii.item_name LIKE ? OR ii.item_code LIKE ?)");
            params.add(k); params.add(k);
        }
        if (!conds.isEmpty()) sql += " WHERE " + String.join(" AND ", conds);
        sql += " ORDER BY ii.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i).toString());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapItem(rs));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query inventory items", e);
        }
        return list;
    }

    private InventoryItem mapItem(ResultSet rs) throws SQLException {
        InventoryItem item = new InventoryItem();
        item.setId(rs.getInt("id"));
        item.setItemCode(rs.getString("item_code"));
        item.setItemName(rs.getString("item_name"));
        item.setItemType(rs.getInt("item_type"));
        int pid = rs.getInt("product_id");
        if (!rs.wasNull()) item.setProductId(pid);
        item.setProductName(rs.getString("product_name"));
        item.setUnit(rs.getString("unit"));
        item.setUnitCost(rs.getBigDecimal("unit_cost"));
        item.setSafetyStock(rs.getBigDecimal("safety_stock"));
        item.setStatus(rs.getInt("status"));
        item.setNote(rs.getString("note"));
        return item;
    }
}
