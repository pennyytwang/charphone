package dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.InventoryStock;

public class InventoryStockDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(InventoryStockDao.class.getName());

    public List<InventoryStock> getAllStock(String warehouseId, String keyword) {
        List<InventoryStock> list = new ArrayList<>();
        String sql = "SELECT s.id, s.warehouse_id, w.warehouse_name, s.item_id, i.item_code, i.item_name, i.unit, i.safety_stock, i.product_id, s.quantity, s.updated_at "
                   + "FROM inventory_stock s "
                   + "JOIN warehouses w ON s.warehouse_id = w.id "
                   + "JOIN inventory_items i ON s.item_id = i.id";
        List<String> conds = new ArrayList<>();
        List<Object> params = new ArrayList<>();
        if (warehouseId != null && !warehouseId.isEmpty()) {
            conds.add("s.warehouse_id = ?");
            params.add(warehouseId);
        }
        if (keyword != null && !keyword.trim().isEmpty()) {
            String k = "%" + keyword.trim() + "%";
            conds.add("(i.item_name LIKE ? OR i.item_code LIKE ?)");
            params.add(k); params.add(k);
        }
        if (!conds.isEmpty()) sql += " WHERE " + String.join(" AND ", conds);
        sql += " ORDER BY w.warehouse_name, i.item_code";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) {
                Object v = params.get(i);
                if (v instanceof Integer) ps.setInt(i + 1, (Integer) v);
                else ps.setString(i + 1, v.toString());
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    InventoryStock s = new InventoryStock();
                    s.setId(rs.getInt("id"));
                    s.setWarehouseId(rs.getInt("warehouse_id"));
                    s.setWarehouseName(rs.getString("warehouse_name"));
                    s.setItemId(rs.getInt("item_id"));
                    s.setItemCode(rs.getString("item_code"));
                    s.setItemName(rs.getString("item_name"));
                    s.setUnit(rs.getString("unit"));
                    s.setSafetyStock(rs.getBigDecimal("safety_stock"));
                    s.setProductId(rs.getObject("product_id", Integer.class));
                    s.setQuantity(rs.getBigDecimal("quantity"));
                    s.setUpdatedAt(rs.getString("updated_at"));
                    list.add(s);
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query inventory stock", e);
        }
        return list;
    }
}
