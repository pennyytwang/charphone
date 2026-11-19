package servlet;

import java.io.IOException;
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

@WebServlet("/DashboardDataServlet")
public class DashboardDataServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(DashboardDataServlet.class.getName());

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");

        int orderCount = 0;
        int prodCount = 0;
        int unpaidOrderCount = 0;
        double outstandingAmount = 0;

        try (Connection conn = BaseDao.getConnection()) {

            // 進行中訂單：未結案
            try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE close_status = 0");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) orderCount = rs.getInt(1);
            }

            // 進行中工單：未結案訂單中尚未全部生產完的工單（排除已取消）
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM productions p JOIN orders o ON p.order_id = o.id WHERE o.close_status = 0 AND p.status != 3 AND p.manufactured_qty < p.produced_qty");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) prodCount = rs.getInt(1);
            }

            // 已出貨未收款：已出貨（有出貨紀錄）且尚未付清，含已開帳與未開帳訂單
            // 應收金額優先取 actual_amount，未填則取 total_amount
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*), COALESCE(SUM(t.outstanding), 0) FROM (" +
                    "  SELECT o.id, COALESCE(COALESCE(o.actual_amount, o.total_amount), 0) - COALESCE(inv.received, 0) AS outstanding " +
                    "  FROM orders o " +
                    "  LEFT JOIN (SELECT order_id, SUM(CASE WHEN payment_status = 1 THEN received_amount ELSE 0 END) AS received FROM invoices GROUP BY order_id) inv ON inv.order_id = o.id " +
                    "  WHERE COALESCE(COALESCE(o.actual_amount, o.total_amount), 0) > 0 " +
                    "  AND COALESCE(inv.received, 0) < COALESCE(COALESCE(o.actual_amount, o.total_amount), 0) " +
                    "  AND EXISTS (SELECT 1 FROM deliveries WHERE order_id = o.id)" +
                    ") t");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    unpaidOrderCount = rs.getInt(1);
                    outstandingAmount = rs.getDouble(2);
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Dashboard data query failed", e);
        }

        String json = "{"
            + "\"orderCount\":" + orderCount + ","
            + "\"prodCount\":" + prodCount + ","
            + "\"invCount\":" + unpaidOrderCount + ","
            + "\"outstandingAmount\":" + outstandingAmount
            + "}";

        response.getWriter().write(json);
    }
}
