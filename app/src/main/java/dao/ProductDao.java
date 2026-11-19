package dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.Product;

public class ProductDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(ProductDao.class.getName());

    public boolean insertProduct(Product product) throws Exception {
        String sql = "INSERT INTO products (product_code, product_name, price_type, unit_weight, unit_price, description) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, product.getProductCode());
            ps.setString(2, product.getProductName());
            ps.setInt(3, product.getPriceType());
            ps.setBigDecimal(4, product.getUnitWeight());
            ps.setBigDecimal(5, product.getUnitPrice());
            ps.setString(6, product.getDescription());
            return ps.executeUpdate() > 0;
        }
    }

    public Product getProductById(int id) {
        String sql = "SELECT id, product_code, product_name, price_type, unit_weight, unit_price, description FROM products WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Product p = new Product();
                    p.setId(rs.getInt("id"));
                    p.setProductCode(rs.getString("product_code"));
                    p.setProductName(rs.getString("product_name"));
                    p.setPriceType(rs.getInt("price_type"));
                    p.setUnitWeight(rs.getBigDecimal("unit_weight"));
                    p.setUnitPrice(rs.getBigDecimal("unit_price"));
                    p.setDescription(rs.getString("description"));
                    return p;
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query product by id", e);
        }
        return null;
    }

    public boolean updateProduct(Product product) throws Exception {
        String sql = "UPDATE products SET product_code=?, product_name=?, price_type=?, unit_weight=?, unit_price=?, description=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, product.getProductCode());
            ps.setString(2, product.getProductName());
            ps.setInt(3, product.getPriceType());
            ps.setBigDecimal(4, product.getUnitWeight());
            ps.setBigDecimal(5, product.getUnitPrice());
            ps.setString(6, product.getDescription());
            ps.setInt(7, product.getId());
            return ps.executeUpdate() > 0;
        }
    }

    public List<Product> getAllProducts() {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT id, product_code, product_name, price_type, unit_weight, unit_price, description FROM products ORDER BY id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapProduct(rs));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query all products", e);
        }
        return list;
    }

    /**
     * 依關鍵字搜尋產品（product_name、product_code 模糊比對）。
     * @param keyword 搜尋關鍵字，null 或空白表示不篩選
     * @return 符合條件的產品列表
     */
    public List<Product> getFilteredProducts(String keyword) {
        List<Product> list = new ArrayList<>();
        String sql = "SELECT id, product_code, product_name, price_type, unit_weight, unit_price, description FROM products";
        List<String> conds = new ArrayList<>();
        List<String> params = new ArrayList<>();
        if (keyword != null && !keyword.trim().isEmpty()) {
            String k = "%" + keyword.trim() + "%";
            conds.add("(product_name LIKE ? OR product_code LIKE ?)");
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
                    list.add(mapProduct(rs));
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query filtered products", e);
        }
        return list;
    }

    private Product mapProduct(ResultSet rs) throws SQLException {
        Product p = new Product();
        p.setId(rs.getInt("id"));
        p.setProductCode(rs.getString("product_code"));
        p.setProductName(rs.getString("product_name"));
        p.setPriceType(rs.getInt("price_type"));
        p.setUnitWeight(rs.getBigDecimal("unit_weight"));
        p.setUnitPrice(rs.getBigDecimal("unit_price"));
        p.setDescription(rs.getString("description"));
        return p;
    }
}
