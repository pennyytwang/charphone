package servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import dao.InvoiceDao;
import dao.OrderDao;
import model.Invoice;
import model.Order;

@WebServlet("/InvoiceServlet")
@MultipartConfig
public class InvoiceServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(InvoiceServlet.class.getName());

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        String action = request.getParameter("action");
        String idParam = request.getParameter("id");
        String contextPath = request.getContextPath();
        InvoiceDao dao = new InvoiceDao();

        if ("delete".equals(action)) {
            try {
                Invoice inv = dao.getInvoiceById(Integer.parseInt(idParam));
                if (inv == null) {
                    response.sendRedirect(contextPath + "/invoice/invoice_list.jsp?error=delete_failed");
                    return;
                }
                if (inv.getPaymentStatus() == 1) {
                    response.sendRedirect(contextPath + "/invoice/invoice_list.jsp?error=delete_paid");
                    return;
                }
                if (inv.getStatus() == 1) {
                    response.sendRedirect(contextPath + "/invoice/invoice_list.jsp?error=delete_settled");
                    return;
                }
                int deletedOrderId = inv.getOrderId();
                boolean success = dao.deleteInvoice(inv.getId());
                if (success) {
                    response.sendRedirect(contextPath + "/invoice/invoice_list.jsp?message=success&orderId=" + deletedOrderId);
                } else {
                    response.sendRedirect(contextPath + "/invoice/invoice_list.jsp?error=delete_failed&orderId=" + deletedOrderId);
                }
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to delete invoice", e);
                response.sendRedirect(contextPath + "/invoice/invoice_list.jsp?error=exception");
            }
            return;
        }

        if ("update_payment".equals(action)) {
            try {
                int invoiceId = Integer.parseInt(idParam);
                int paymentStatus = Integer.parseInt(request.getParameter("paymentStatus"));
                String receivedAmountStr = request.getParameter("receivedAmount");
                String paymentDateStr = request.getParameter("paymentDate");
                BigDecimal receivedAmount = receivedAmountStr != null && !receivedAmountStr.isEmpty() ? new BigDecimal(receivedAmountStr) : null;
                java.util.Date paymentDate = paymentDateStr != null && !paymentDateStr.isEmpty() ? new SimpleDateFormat("yyyy-MM-dd").parse(paymentDateStr) : null;
                boolean success = dao.updatePaymentStatus(invoiceId, paymentStatus, receivedAmount, paymentDate);
                if (success) {
                    response.sendRedirect(contextPath + "/invoice/invoice_list.jsp?message=payment_updated");
                } else {
                    response.sendRedirect(contextPath + "/invoice/invoice_list.jsp?error=payment_failed");
                }
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to update invoice payment", e);
                response.sendRedirect(contextPath + "/invoice/invoice_list.jsp?error=payment_failed");
            }
            return;
        }

        try {
            String invoiceNumber = request.getParameter("invoiceNumber");
            int customerId = Integer.parseInt(request.getParameter("customerId"));
            int orderId = Integer.parseInt(request.getParameter("orderId"));
            BigDecimal amount = new BigDecimal(request.getParameter("amount"));
            int status = Integer.parseInt(request.getParameter("status"));

            String issueDateStr = request.getParameter("issueDate");
            String dueDateStr = request.getParameter("dueDate");
            String note = request.getParameter("note");

            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");

            Invoice inv = new Invoice();
            inv.setCustomerId(customerId);
            inv.setOrderId(orderId);
            inv.setInvoiceNumber(invoiceNumber);
            inv.setAmount(amount);
            inv.setIssueDate(issueDateStr != null && !issueDateStr.isEmpty() ? sdf.parse(issueDateStr) : new java.util.Date());
            inv.setDueDate(dueDateStr != null && !dueDateStr.isEmpty() ? sdf.parse(dueDateStr) : null);
            inv.setStatus(status);
            inv.setPaymentStatus(Integer.parseInt(request.getParameter("paymentStatus")));
            String paymentDateStr = request.getParameter("paymentDate");
            inv.setPaymentDate(paymentDateStr != null && !paymentDateStr.isEmpty() ? sdf.parse(paymentDateStr) : null);
            String receivedAmountStr = request.getParameter("receivedAmount");
            inv.setReceivedAmount(receivedAmountStr != null && !receivedAmountStr.isEmpty() ? new BigDecimal(receivedAmountStr) : null);
            inv.setNote(note);

            boolean success;

            if (idParam != null && !idParam.isEmpty()) {
                inv.setId(Integer.parseInt(idParam));
                success = dao.updateInvoice(inv);
            } else {
                OrderDao orderDao = new OrderDao();
                Order order = orderDao.getOrderById(orderId);
                BigDecimal orderAmount = order.getActualAmount() != null ? order.getActualAmount() : order.getTotalAmount();
                BigDecimal existingSum = dao.getSumAmountByOrderId(orderId);
                if (existingSum.add(amount).compareTo(orderAmount) > 0) {
                    response.sendRedirect(contextPath + "/invoice/add_invoice.jsp?error=over_amount&orderId=" + orderId);
                    return;
                }
                if (invoiceNumber == null || invoiceNumber.trim().isEmpty()) {
                    inv.setInvoiceNumber(dao.generateInvoiceNumber());
                }
                success = dao.insertInvoice(inv);
            }

            if (success) {
                response.sendRedirect(contextPath + "/invoice/invoice_list.jsp?message=success&orderId=" + orderId);
            } else if (idParam != null && !idParam.isEmpty()) {
                response.sendRedirect(contextPath + "/invoice/edit_invoice.jsp?id=" + idParam + "&error=failed");
            } else {
                response.sendRedirect(contextPath + "/invoice/add_invoice.jsp?error=failed&orderId=" + orderId);
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to save invoice", e);
            if (idParam != null && !idParam.isEmpty()) {
                response.sendRedirect(contextPath + "/invoice/edit_invoice.jsp?id=" + idParam + "&error=exception");
            } else {
                response.sendRedirect(contextPath + "/invoice/add_invoice.jsp?error=exception");
            }
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        if ("delete".equals(action)) {
            doPost(request, response);
        }
    }
}