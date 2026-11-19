package servlet;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import dao.CustomerDao;
import model.Customer;

@WebServlet("/CustomerServlet")
@MultipartConfig
public class CustomerServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(CustomerServlet.class.getName());

    private boolean isAjax(HttpServletRequest request) {
        return "XMLHttpRequest".equals(request.getHeader("X-Requested-With"));
    }

    private void writeJson(HttpServletResponse response, String json) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(json);
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        if ("get".equals(action)) {
            String idParam = request.getParameter("id");
            try {
                CustomerDao dao = new CustomerDao();
                Customer c = dao.getCustomerById(Integer.parseInt(idParam));
                if (c != null) {
                    writeJson(response, "{\"success\":true,\"id\":" + c.getId()
                            + ",\"customerNumber\":\"" + esc(c.getCustomerNumber())
                            + "\",\"customerName\":\"" + esc(c.getCustomerName())
                            + "\",\"phone\":\"" + esc(c.getPhone())
                            + "\",\"taxId\":\"" + esc(c.getTaxId())
                            + "\",\"contactPerson\":\"" + esc(c.getContactPerson())
                            + "\",\"address\":\"" + esc(c.getAddress())
                            + "\",\"deliveryAddress\":\"" + esc(c.getDeliveryAddress()) + "\"}");
                } else {
                    writeJson(response, "{\"success\":false,\"error\":\"找不到該客戶\"}");
                }
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to get customer detail", e);
                writeJson(response, "{\"success\":false,\"error\":\"系統錯誤\"}");
            }
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        String idParam = request.getParameter("id");
        String contextPath = request.getContextPath();

        try {
            String customerName = request.getParameter("customerName");
            String phone = request.getParameter("phone");
            String taxId = request.getParameter("taxId");
            String contactPerson = request.getParameter("contactPerson");
            String address = request.getParameter("address");
            String deliveryAddress = request.getParameter("deliveryAddress");

            Customer customer = new Customer();
            customer.setCustomerName(customerName);
            customer.setPhone(phone);
            customer.setTaxId(taxId);
            customer.setContactPerson(contactPerson);
            customer.setAddress(address);
            customer.setDeliveryAddress(deliveryAddress);

            CustomerDao dao = new CustomerDao();
            boolean success;

            if (idParam != null && !idParam.isEmpty()) {
                int custId = Integer.parseInt(idParam);
                if (dao.isDuplicate(phone, customerName, custId)) {
                    if (isAjax(request)) {
                        writeJson(response, "{\"success\":false,\"error\":\"此客戶電話或名稱已被其他客戶使用\"}");
                    } else {
                        response.sendRedirect(contextPath + "/customer/edit_customer.jsp?id=" + custId + "&error=duplicate");
                    }
                    return;
                }
                customer.setId(custId);
                success = dao.updateCustomer(customer);
            } else {
                if (dao.isDuplicate(phone, customerName, null)) {
                    if (isAjax(request)) {
                        writeJson(response, "{\"success\":false,\"error\":\"此客戶電話或名稱已存在，請勿重複新增\"}");
                    } else {
                        response.sendRedirect(contextPath + "/customer/add_customer.jsp?error=duplicate");
                    }
                    return;
                }
                success = dao.insertCustomer(customer);
            }

            if (isAjax(request)) {
                if (success) {
                    writeJson(response, "{\"success\":true}");
                } else {
                    writeJson(response, "{\"success\":false,\"error\":\"寫入失敗，請稍後再試\"}");
                }
            } else {
                if (success) {
                    response.sendRedirect(contextPath + "/customer/customer_list.jsp?message=success");
                } else if (idParam != null && !idParam.isEmpty()) {
                    response.sendRedirect(contextPath + "/customer/edit_customer.jsp?id=" + idParam + "&error=failed");
                } else {
                    response.sendRedirect(contextPath + "/customer/add_customer.jsp?error=failed");
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to save customer", e);
            if (isAjax(request)) {
                String msg = e.getMessage() != null ? esc(e.getMessage()) : "系統錯誤";
                writeJson(response, "{\"success\":false,\"error\":\"" + msg + "\"}");
            } else {
                if (idParam != null && !idParam.isEmpty()) {
                    response.sendRedirect(contextPath + "/customer/edit_customer.jsp?id=" + idParam + "&error=exception");
                } else {
                    response.sendRedirect(contextPath + "/customer/add_customer.jsp?error=exception");
                }
            }
        }
    }
}
