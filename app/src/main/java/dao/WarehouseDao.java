package dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.Warehouse;

public class WarehouseDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(WarehouseDao.class.getName());

    public boolean insertWarehouse(Warehouse warehouse) {
        String sql = "INSERT INTO warehouses (warehouse_code, warehouse_name, contact_person, phone, address, status, note) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, warehouse.getWarehouseCode());
            ps.setString(2, warehouse.getWarehouseName());
            ps.setString(3, warehouse.getContactPerson());
            ps.setString(4, warehouse.getPhone());
            ps.setString(5, warehouse.getAddress());
            ps.setInt(6, warehouse.getStatus());
            ps.setString(7, warehouse.getNote());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to insert warehouse", e);
            return false;
        }
    }

    public Warehouse getWarehouseById(int id) {
        String sql = "SELECT id, warehouse_code, warehouse_name, contact_person, phone, address, status, note FROM warehouses WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapWarehouse(rs);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query warehouse by id", e);
        }
        return null;
    }

    public boolean updateWarehouse(Warehouse warehouse) {
        String sql = "UPDATE warehouses SET warehouse_code=?, warehouse_name=?, contact_person=?, phone=?, address=?, status=?, note=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, warehouse.getWarehouseCode());
            ps.setString(2, warehouse.getWarehouseName());
            ps.setString(3, warehouse.getContactPerson());
            ps.setString(4, warehouse.getPhone());
            ps.setString(5, warehouse.getAddress());
            ps.setInt(6, warehouse.getStatus());
            ps.setString(7, warehouse.getNote());
            ps.setInt(8, warehouse.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to update warehouse", e);
            return false;
        }
    }

    public List<Warehouse> getAllWarehouses() {
        List<Warehouse> list = new ArrayList<>();
        String sql = "SELECT id, warehouse_code, warehouse_name, contact_person, phone, address, status, note FROM warehouses ORDER BY id ASC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapWarehouse(rs));
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query all warehouses", e);
        }
        return list;
    }

    private Warehouse mapWarehouse(ResultSet rs) throws SQLException {
        Warehouse w = new Warehouse();
        w.setId(rs.getInt("id"));
        w.setWarehouseCode(rs.getString("warehouse_code"));
        w.setWarehouseName(rs.getString("warehouse_name"));
        w.setContactPerson(rs.getString("contact_person"));
        w.setPhone(rs.getString("phone"));
        w.setAddress(rs.getString("address"));
        w.setStatus(rs.getInt("status"));
        w.setNote(rs.getString("note"));
        return w;
    }
}
