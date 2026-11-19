package dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.Customer;
import util.DemoContext;
import util.MaskingUtil;

public class CustomerDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(CustomerDao.class.getName());

    public boolean isDuplicate(String phone, String customerName, Integer excludeId) {
        String sql = "SELECT COUNT(*) FROM customers WHERE (phone = ? OR customer_name = ?)";
        if (excludeId != null) {
            sql += " AND id != ?";
        }
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, phone);
            ps.setString(2, customerName);
            if (excludeId != null) {
                ps.setInt(3, excludeId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to check customer duplication", e);
            return false;
        }
    }

    public boolean insertCustomer(Customer customer) {
        String areaCode = "00";
        String phone = customer.getPhone();
        if (phone != null && phone.contains("-")) {
            areaCode = phone.split("-")[0].trim();
        }
        String prefix = areaCode + "-";

        String selectSql = "SELECT customer_number FROM customers WHERE customer_number LIKE ? ORDER BY id DESC LIMIT 1 FOR UPDATE";
        String insertSql = "INSERT INTO customers (customer_number, customer_name, phone, tax_id, contact_person, address, delivery_address) VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);

            String customerNumber;
            try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
                ps.setString(1, prefix + "%");
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String last = rs.getString("customer_number");
                        int seq = Integer.parseInt(last.substring(last.length() - 6)) + 1;
                        customerNumber = prefix + String.format("%06d", seq);
                    } else {
                        customerNumber = prefix + "000001";
                    }
                }
            }

            customer.setCustomerNumber(customerNumber);

            try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                ps.setString(1, customer.getCustomerNumber());
                ps.setString(2, customer.getCustomerName());
                ps.setString(3, phone);
                ps.setString(4, customer.getTaxId());
                ps.setString(5, customer.getContactPerson());
                ps.setString(6, customer.getAddress());
                ps.setString(7, customer.getDeliveryAddress());
                int result = ps.executeUpdate();
                conn.commit();
                return result > 0;
            }
        } catch (java.sql.SQLIntegrityConstraintViolationException e) {
            LOGGER.log(Level.SEVERE, "Failed to insert customer (duplicate key)", e);
            return false;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to insert customer", e);
            return false;
        }
    }

    public Customer getCustomerById(int id) {
        String sql = "SELECT id, customer_number, customer_name, phone, tax_id, contact_person, address, delivery_address FROM customers WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapCustomer(rs);
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query customer by id", e);
        }
        return null;
    }

    public boolean updateCustomer(Customer customer) {
        String sql = "UPDATE customers SET customer_name=?, phone=?, tax_id=?, contact_person=?, address=?, delivery_address=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, customer.getCustomerName());
            ps.setString(2, customer.getPhone());
            ps.setString(3, customer.getTaxId());
            ps.setString(4, customer.getContactPerson());
            ps.setString(5, customer.getAddress());
            ps.setString(6, customer.getDeliveryAddress());
            ps.setInt(7, customer.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to update customer", e);
            return false;
        }
    }

    public List<Customer> getAllCustomers() {
        List<Customer> list = new ArrayList<>();
        String sql = "SELECT id, customer_number, customer_name, phone, tax_id, contact_person, address, delivery_address FROM customers ORDER BY id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapCustomer(rs));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query all customers", e);
        }
        return list;
    }

    /**
     * 依關鍵字搜尋客戶（customer_name、customer_number、phone 模糊比對）。
     * @param keyword 搜尋關鍵字，null 或空白表示不篩選
     * @return 符合條件的客戶列表
     */
    public List<Customer> getFilteredCustomers(String keyword) {
        List<Customer> list = new ArrayList<>();
        String sql = "SELECT id, customer_number, customer_name, phone, tax_id, contact_person, address, delivery_address FROM customers";
        List<String> conds = new ArrayList<>();
        List<String> params = new ArrayList<>();
        if (keyword != null && !keyword.trim().isEmpty()) {
            String k = "%" + keyword.trim() + "%";
            conds.add("(customer_name LIKE ? OR customer_number LIKE ? OR phone LIKE ?)");
            params.add(k);
            params.add(k);
            params.add(k);
        }
        if (!conds.isEmpty()) {
            sql += " WHERE " + String.join(" AND ", conds);
        }
        sql += " ORDER BY id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) {
                ps.setString(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapCustomer(rs));
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query filtered customers", e);
        }
        return list;
    }

    private Customer mapCustomer(ResultSet rs) throws SQLException {
        Customer c = new Customer();
        c.setId(rs.getInt("id"));
        c.setCustomerNumber(rs.getString("customer_number"));
        c.setCustomerName(rs.getString("customer_name"));
        c.setPhone(rs.getString("phone"));
        c.setTaxId(rs.getString("tax_id"));
        c.setContactPerson(rs.getString("contact_person"));
        c.setAddress(rs.getString("address"));
        c.setDeliveryAddress(rs.getString("delivery_address"));

        if (DemoContext.isMasked()) {
            c.setPhone(MaskingUtil.maskPhone(c.getPhone()));
            c.setTaxId(MaskingUtil.maskTaxId(c.getTaxId()));
            c.setContactPerson(MaskingUtil.maskPersonName(c.getContactPerson()));
            c.setAddress(MaskingUtil.maskAddress(c.getAddress()));
            c.setDeliveryAddress(MaskingUtil.maskAddress(c.getDeliveryAddress()));
        }
        return c;
    }
}
