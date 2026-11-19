package servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import dao.BaseDao;

@WebServlet("/ShippingCheckServlet")
public class ShippingCheckServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(ShippingCheckServlet.class.getName());

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");

        String productIdStr = request.getParameter("productId");
        String dateStr = request.getParameter("date");
        String qtyStr = request.getParameter("qty");

        if (productIdStr == null || productIdStr.isEmpty()) {
            response.getWriter().write("{\"error\":\"missing productId\"}");
            return;
        }

        try (Connection conn = BaseDao.getConnection()) {
            int productId = Integer.parseInt(productIdStr);

            String productName = "";
            BigDecimal currentStock = BigDecimal.ZERO;

            String stockSql = "SELECT p.product_name, COALESCE(s.quantity, 0) AS stock FROM products p "
                + "LEFT JOIN inventory_items ii ON ii.product_id = p.id "
                + "LEFT JOIN inventory_stock s ON s.item_id = ii.id AND s.warehouse_id = 2 WHERE p.id = ?";
            try (PreparedStatement ps = conn.prepareStatement(stockSql)) {
                ps.setInt(1, productId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        productName = rs.getString("product_name");
                        currentStock = rs.getBigDecimal("stock");
                    }
                }
            }

            BigDecimal potentialSupply = BigDecimal.ZERO;
            if (dateStr != null && !dateStr.isEmpty()) {
                String prodSql = "SELECT COALESCE(SUM(p.produced_qty - COALESCE(r.received, 0)), 0) AS remaining FROM productions p "
                    + "LEFT JOIN (SELECT ref_id, SUM(quantity) AS received FROM inventory_transactions WHERE ref_type='production' AND transaction_type=1 GROUP BY ref_id) r ON r.ref_id = p.id "
                    + "WHERE p.product_id = ? AND p.target_date <= ? AND p.status != 3 AND p.produced_qty > COALESCE(r.received, 0)";
                try (PreparedStatement ps = conn.prepareStatement(prodSql)) {
                    ps.setInt(1, productId);
                    ps.setString(2, dateStr);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) potentialSupply = rs.getBigDecimal("remaining");
                    }
                }
            }

            BigDecimal totalAvailable = currentStock.add(potentialSupply);
            boolean canDeliver = true;
            BigDecimal shortage = BigDecimal.ZERO;
            if (qtyStr != null && !qtyStr.isEmpty()) {
                BigDecimal requested = new BigDecimal(qtyStr);
                canDeliver = totalAvailable.compareTo(requested) >= 0;
                if (!canDeliver) shortage = requested.subtract(totalAvailable);
            }

            String json = "{"
                + "\"productName\":\"" + (productName != null ? productName.replace("\"", "\\\"") : "") + "\","
                + "\"currentStock\":" + currentStock + ","
                + "\"potentialSupply\":" + potentialSupply + ","
                + "\"totalAvailable\":" + totalAvailable + ","
                + "\"canDeliver\":" + canDeliver + ","
                + "\"shortage\":" + shortage
                + "}";

            response.getWriter().write(json);

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Shipping check query failed", e);
            response.getWriter().write("{\"error\":\"" + e.getMessage().replace("\"", "\\\"").replace("\n", " ") + "\"}");
        }
    }
}
