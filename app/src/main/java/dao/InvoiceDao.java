package dao;

import java.math.BigDecimal;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import model.Invoice;
import model.Order;

public class InvoiceDao extends BaseDao {
    private static final Logger LOGGER = Logger.getLogger(InvoiceDao.class.getName());

    public String generateInvoiceNumber() {
        String prefix = "INV-" + new SimpleDateFormat("yyyyMM").format(new Date()) + "-";
        String sql = "SELECT invoice_number FROM invoices WHERE invoice_number LIKE ? ORDER BY id DESC LIMIT 1 FOR UPDATE";
        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, prefix + "%");
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String last = rs.getString("invoice_number");
                        int seq = Integer.parseInt(last.substring(last.length() - 3)) + 1;
                        conn.commit();
                        return prefix + String.format("%03d", seq);
                    }
                }
            }
            conn.commit();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to generate invoice number", e);
        }
        return prefix + "001";
    }

    public boolean insertInvoice(Invoice inv) {
        String sql = "INSERT INTO invoices (customer_id, order_id, invoice_number, amount, issue_date, due_date, status, payment_status, payment_date, received_amount, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, inv.getCustomerId());
            ps.setInt(2, inv.getOrderId());
            ps.setString(3, inv.getInvoiceNumber());
            ps.setBigDecimal(4, inv.getAmount());
            ps.setDate(5, inv.getIssueDate() != null ? new java.sql.Date(inv.getIssueDate().getTime()) : null);
            ps.setDate(6, inv.getDueDate() != null ? new java.sql.Date(inv.getDueDate().getTime()) : null);
            ps.setInt(7, inv.getStatus());
            ps.setInt(8, inv.getPaymentStatus());
            if (inv.getPaymentDate() != null) {
                ps.setDate(9, new java.sql.Date(inv.getPaymentDate().getTime()));
            } else {
                ps.setNull(9, Types.DATE);
            }
            if (inv.getReceivedAmount() != null) {
                ps.setBigDecimal(10, inv.getReceivedAmount());
            } else {
                ps.setNull(10, Types.DECIMAL);
            }
            ps.setString(11, inv.getNote());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to insert invoice", e);
            return false;
        }
    }

    public BigDecimal getSumAmountByOrderId(int orderId) {
        String sql = "SELECT COALESCE(SUM(amount), 0) FROM invoices WHERE order_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query invoice sum", e);
        }
        return BigDecimal.ZERO;
    }

    public BigDecimal getTotalReceivedByOrder(int orderId) {
        String sql = "SELECT COALESCE(SUM(CASE WHEN payment_status = 1 THEN received_amount ELSE 0 END), 0) FROM invoices WHERE order_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query total received amount", e);
        }
        return BigDecimal.ZERO;
    }

    public Object[] getInvoiceSummaryByOrderId(int orderId) {
        String sql = "SELECT COALESCE(SUM(amount), 0) as invoiced, "
                   + "COALESCE(SUM(CASE WHEN payment_status = 1 THEN received_amount ELSE 0 END), 0) as paid, "
                   + "COUNT(*) as cnt, "
                   + "SUM(CASE WHEN payment_status = 1 THEN 1 ELSE 0 END) as paid_cnt "
                   + "FROM invoices WHERE order_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Object[] {
                        rs.getBigDecimal("invoiced"),
                        rs.getBigDecimal("paid"),
                        rs.getInt("cnt"),
                        rs.getInt("paid_cnt")
                    };
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query invoice summary", e);
        }
        return new Object[] { java.math.BigDecimal.ZERO, java.math.BigDecimal.ZERO, 0, 0 };
    }

    public boolean areAllInvoicesPaid(int orderId) {
        String sql = "SELECT " +
                "SUM(CASE WHEN payment_status = 0 THEN 1 ELSE 0 END) as unpaid_count, " +
                "COALESCE(SUM(CASE WHEN payment_status = 1 THEN received_amount ELSE 0 END), 0) as total_paid, " +
                "COUNT(*) as total_count " +
                "FROM invoices WHERE order_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int unpaidCount = rs.getInt("unpaid_count");
                    int totalCount = rs.getInt("total_count");
                    java.math.BigDecimal totalPaid = rs.getBigDecimal("total_paid");
                    if (unpaidCount > 0) return false;
                    if (totalCount == 0) return false;
                    if (totalPaid == null || totalPaid.compareTo(java.math.BigDecimal.ZERO) <= 0) return false;
                }
                return true;
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to check invoice payment status", e);
        }
        return false;
    }

    public Invoice getInvoiceByOrderId(int orderId) {
        String sql = "SELECT i.*, c.customer_name, o.order_number FROM invoices i LEFT JOIN customers c ON i.customer_id = c.id LEFT JOIN orders o ON i.order_id = o.id WHERE i.order_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapInvoice(rs);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query invoice by order id", e);
        }
        return null;
    }

    public Invoice getInvoiceById(int id) {
        String sql = "SELECT i.*, c.customer_name, o.order_number FROM invoices i LEFT JOIN customers c ON i.customer_id = c.id LEFT JOIN orders o ON i.order_id = o.id WHERE i.id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapInvoice(rs);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query invoice by id", e);
        }
        return null;
    }

    public boolean updateInvoice(Invoice inv) {
        String sql = "UPDATE invoices SET customer_id=?, order_id=?, invoice_number=?, amount=?, issue_date=?, due_date=?, status=?, payment_status=?, payment_date=?, received_amount=?, note=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, inv.getCustomerId());
            ps.setInt(2, inv.getOrderId());
            ps.setString(3, inv.getInvoiceNumber());
            ps.setBigDecimal(4, inv.getAmount());
            ps.setDate(5, inv.getIssueDate() != null ? new java.sql.Date(inv.getIssueDate().getTime()) : null);
            ps.setDate(6, inv.getDueDate() != null ? new java.sql.Date(inv.getDueDate().getTime()) : null);
            ps.setInt(7, inv.getStatus());
            ps.setInt(8, inv.getPaymentStatus());
            if (inv.getPaymentDate() != null) {
                ps.setDate(9, new java.sql.Date(inv.getPaymentDate().getTime()));
            } else {
                ps.setNull(9, Types.DATE);
            }
            if (inv.getReceivedAmount() != null) {
                ps.setBigDecimal(10, inv.getReceivedAmount());
            } else {
                ps.setNull(10, Types.DECIMAL);
            }
            ps.setString(11, inv.getNote());
            ps.setInt(12, inv.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to update invoice", e);
            return false;
        }
    }

    public boolean deleteInvoice(int id) {
        String sql = "DELETE FROM invoices WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to delete invoice", e);
            return false;
        }
    }

    public List<Invoice> getInvoicesByOrderId(int orderId) {
        List<Invoice> list = new ArrayList<>();
        String sql = "SELECT i.*, c.customer_name, o.order_number FROM invoices i LEFT JOIN customers c ON i.customer_id = c.id LEFT JOIN orders o ON i.order_id = o.id WHERE i.order_id = ? ORDER BY i.issue_date ASC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapInvoice(rs));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query invoices by order id", e);
        }
        return list;
    }

    public boolean updatePaymentStatus(int invoiceId, int paymentStatus, java.math.BigDecimal receivedAmount, java.util.Date paymentDate) {
        String sql = "UPDATE invoices SET payment_status=?, received_amount=?, payment_date=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, paymentStatus);
            if (receivedAmount != null) {
                ps.setBigDecimal(2, receivedAmount);
            } else {
                ps.setNull(2, Types.DECIMAL);
            }
            if (paymentDate != null) {
                ps.setDate(3, new java.sql.Date(paymentDate.getTime()));
            } else {
                ps.setNull(3, Types.DATE);
            }
            ps.setInt(4, invoiceId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to update payment status", e);
            return false;
        }
    }

    public List<Invoice> getAllInvoices() {
        return getAllInvoices(null, null, null);
    }

    public List<Invoice> getAllInvoices(String dateFrom, String dateTo, String keyword) {
        return getAllInvoices(dateFrom, dateTo, keyword, null);
    }

    public List<Invoice> getAllInvoices(String dateFrom, String dateTo, String keyword, Integer orderId) {
        return getAllInvoices(dateFrom, dateTo, keyword, orderId, null, null, null, null);
    }

    public List<Invoice> getAllInvoices(String dateFrom, String dateTo, String keyword, Integer orderId,
                                        Integer paymentStatus, String customerName, String invoiceNumber) {
        return getAllInvoices(dateFrom, dateTo, keyword, orderId, paymentStatus, customerName, invoiceNumber, null);
    }

    public List<Invoice> getAllInvoices(String dateFrom, String dateTo, String keyword, Integer orderId,
                                        Integer paymentStatus, String customerName, String invoiceNumber,
                                        Boolean shipped) {
        return getAllInvoices(dateFrom, dateTo, keyword, orderId, paymentStatus, customerName, invoiceNumber, shipped, null);
    }

    public List<Invoice> getAllInvoices(String dateFrom, String dateTo, String keyword, Integer orderId,
                                        Integer paymentStatus, String customerName, String invoiceNumber,
                                        Boolean shipped, Boolean unpaid) {
        List<Invoice> list = new ArrayList<>();
        List<String> conds = new ArrayList<>();
        List<Object> params = new ArrayList<>();
        if (dateFrom != null && !dateFrom.isEmpty()) { conds.add("i.issue_date >= ?"); params.add(dateFrom); }
        if (dateTo != null && !dateTo.isEmpty()) { conds.add("i.issue_date <= ?"); params.add(dateTo); }
        if (keyword != null && !keyword.trim().isEmpty()) {
            String k = "%" + keyword.trim() + "%";
            conds.add("(i.invoice_number LIKE ? OR c.customer_name LIKE ? OR o.order_number LIKE ?)");
            params.add(k); params.add(k); params.add(k);
        }
        if (customerName != null && !customerName.trim().isEmpty()) {
            conds.add("c.customer_name LIKE ?"); params.add("%" + customerName.trim() + "%");
        }
        if (invoiceNumber != null && !invoiceNumber.trim().isEmpty()) {
            conds.add("i.invoice_number LIKE ?"); params.add("%" + invoiceNumber.trim() + "%");
        }
        if (paymentStatus != null) {
            conds.add("i.payment_status = ?"); params.add(paymentStatus);
        }
        if (orderId != null) {
            conds.add("i.order_id = ?"); params.add(orderId);
        }
        if (Boolean.TRUE.equals(shipped)) {
            conds.add("EXISTS (SELECT 1 FROM deliveries d WHERE d.order_id = i.order_id)");
        }
        if (Boolean.TRUE.equals(unpaid)) {
            // 已出貨且尚未付清：應收 (actual_amount 優於 total_amount) > 已收款
            conds.add("EXISTS (" +
                    "  SELECT 1 FROM orders oo " +
                    "  LEFT JOIN (SELECT order_id, SUM(CASE WHEN payment_status = 1 THEN received_amount ELSE 0 END) AS received FROM invoices GROUP BY order_id) inv ON inv.order_id = oo.id " +
                    "  WHERE oo.id = i.order_id " +
                    "  AND COALESCE(COALESCE(oo.actual_amount, oo.total_amount), 0) > 0" +
                    "  AND COALESCE(inv.received, 0) < COALESCE(COALESCE(oo.actual_amount, oo.total_amount), 0)" +
                    ")");
        }
        String whereClause = conds.isEmpty() ? "" : " WHERE " + String.join(" AND ", conds);
        String sql = "SELECT i.*, c.customer_name, o.order_number FROM invoices i LEFT JOIN customers c ON i.customer_id = c.id LEFT JOIN orders o ON i.order_id = o.id" + whereClause + " ORDER BY i.issue_date DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) {
                Object v = params.get(i);
                if (v instanceof Integer) ps.setInt(i + 1, (Integer) v);
                else ps.setString(i + 1, v.toString());
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapInvoice(rs));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query all invoices", e);
        }
        return list;
    }

    public List<Order> getShippedUninvoicedOrders() {
        List<Order> list = new ArrayList<>();
        String sql = "SELECT o.*, c.customer_name, p.product_name " +
                "FROM orders o " +
                "LEFT JOIN customers c ON o.customer_id = c.id " +
                "LEFT JOIN products p ON o.product_id = p.id " +
                "WHERE o.id NOT IN (SELECT DISTINCT order_id FROM invoices WHERE order_id IS NOT NULL) " +
                "AND o.id IN (" +
                "  SELECT d2.order_id FROM deliveries d2 JOIN orders o3 ON d2.order_id = o3.id " +
                "  GROUP BY d2.order_id, o3.quantity HAVING SUM(d2.quantity) >= o3.quantity" +
                ") " +
                "ORDER BY o.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Order o = new Order();
                o.setId(rs.getInt("id"));
                o.setCustomerId(rs.getInt("customer_id"));
                o.setCustomerName(rs.getString("customer_name"));
                o.setOrderNumber(rs.getString("order_number"));
                o.setProductId(rs.getInt("product_id"));
                o.setProductName(rs.getString("product_name"));
                o.setTotalAmount(rs.getBigDecimal("total_amount"));
                o.setActualAmount(rs.getBigDecimal("actual_amount"));
                o.setOrderDate(rs.getDate("order_date"));
                o.setExpectedDeliveryDate(rs.getDate("expected_delivery_date"));
                o.setNote(rs.getString("note"));
                list.add(o);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query shipped uninvoiced orders", e);
        }
        return list;
    }

    /**
     * 查詢已出貨、尚未付清、且完全未開帳的訂單（用於「已出貨未收款」的未開帳分頁）。
     */
    public List<Order> getShippedUnpaidUninvoicedOrders() {
        List<Order> list = new ArrayList<>();
        String sql = "SELECT o.*, c.customer_name, p.product_name " +
                "FROM orders o " +
                "LEFT JOIN customers c ON o.customer_id = c.id " +
                "LEFT JOIN products p ON o.product_id = p.id " +
                "WHERE o.id NOT IN (SELECT DISTINCT order_id FROM invoices WHERE order_id IS NOT NULL) " +
                "AND COALESCE(COALESCE(o.actual_amount, o.total_amount), 0) > 0 " +
                "AND EXISTS (SELECT 1 FROM deliveries d WHERE d.order_id = o.id) " +
                "ORDER BY o.id DESC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Order o = new Order();
                o.setId(rs.getInt("id"));
                o.setCustomerId(rs.getInt("customer_id"));
                o.setCustomerName(rs.getString("customer_name"));
                o.setOrderNumber(rs.getString("order_number"));
                o.setProductId(rs.getInt("product_id"));
                o.setProductName(rs.getString("product_name"));
                o.setTotalAmount(rs.getBigDecimal("total_amount"));
                o.setActualAmount(rs.getBigDecimal("actual_amount"));
                o.setOrderDate(rs.getDate("order_date"));
                o.setExpectedDeliveryDate(rs.getDate("expected_delivery_date"));
                o.setNote(rs.getString("note"));
                list.add(o);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to query shipped unpaid uninvoiced orders", e);
        }
        return list;
    }

    private Invoice mapInvoice(ResultSet rs) throws SQLException {
        Invoice inv = new Invoice();
        inv.setId(rs.getInt("id"));
        inv.setCustomerId(rs.getInt("customer_id"));
        inv.setCustomerName(rs.getString("customer_name"));
        inv.setOrderId(rs.getInt("order_id"));
        inv.setOrderNumber(rs.getString("order_number"));
        inv.setInvoiceNumber(rs.getString("invoice_number"));
        inv.setAmount(rs.getBigDecimal("amount"));
        inv.setIssueDate(rs.getDate("issue_date"));
        inv.setDueDate(rs.getDate("due_date"));
        inv.setStatus(rs.getInt("status"));
        inv.setPaymentStatus(rs.getInt("payment_status"));
        inv.setPaymentDate(rs.getDate("payment_date"));
        inv.setReceivedAmount(rs.getBigDecimal("received_amount"));
        inv.setNote(rs.getString("note"));
        return inv;
    }
}