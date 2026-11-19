package servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import dao.ProductDao;
import model.Product;
import util.NumberUtil;

@WebServlet("/ProductServlet")
@MultipartConfig
public class ProductServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(ProductServlet.class.getName());

    private boolean isAjax(HttpServletRequest request) {
        return "XMLHttpRequest".equals(request.getHeader("X-Requested-With"));
    }

    private void writeJson(HttpServletResponse response, String json) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(json);
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        if ("get".equals(action)) {
            String idParam = request.getParameter("id");
            try {
                ProductDao dao = new ProductDao();
                Product p = dao.getProductById(Integer.parseInt(idParam));
                if (p != null) {
                    String unitWeight = p.getUnitWeight() != null ? NumberUtil.fmtQty(p.getUnitWeight().doubleValue()) : "";
                    String unitPrice = p.getUnitPrice() != null ? NumberUtil.fmtQty(p.getUnitPrice().doubleValue()) : "";
                    String desc = p.getDescription() != null ? p.getDescription().replace("\\", "\\\\").replace("\"", "\\\"") : "";
                    String code = p.getProductCode() != null ? p.getProductCode().replace("\\", "\\\\").replace("\"", "\\\"") : "";
                    String name = p.getProductName() != null ? p.getProductName().replace("\\", "\\\\").replace("\"", "\\\"") : "";
                    writeJson(response, "{\"success\":true,\"id\":" + p.getId()
                            + ",\"productCode\":\"" + code
                            + "\",\"productName\":\"" + name
                            + "\",\"priceType\":" + p.getPriceType()
                            + ",\"unitWeight\":\"" + unitWeight
                            + "\",\"unitPrice\":\"" + unitPrice
                            + "\",\"description\":\"" + desc + "\"}");
                } else {
                    writeJson(response, "{\"success\":false,\"error\":\"找不到該品項\"}");
                }
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to get product detail", e);
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
            String productCode = request.getParameter("productCode");
            String productName = request.getParameter("productName");
            int priceType = Integer.parseInt(request.getParameter("priceType"));
            BigDecimal unitWeight = request.getParameter("unitWeight") != null && !request.getParameter("unitWeight").isEmpty()
                    ? new BigDecimal(request.getParameter("unitWeight")) : null;
            BigDecimal unitPrice = request.getParameter("unitPrice") != null && !request.getParameter("unitPrice").isEmpty()
                    ? new BigDecimal(request.getParameter("unitPrice")) : null;
            String description = request.getParameter("description");

            Product product = new Product();
            product.setProductCode(productCode);
            product.setProductName(productName);
            product.setPriceType(priceType);
            product.setUnitWeight(unitWeight);
            product.setUnitPrice(unitPrice);
            product.setDescription(description);

            ProductDao dao = new ProductDao();
            boolean success;

            if (idParam != null && !idParam.isEmpty()) {
                product.setId(Integer.parseInt(idParam));
                success = dao.updateProduct(product);
            } else {
                success = dao.insertProduct(product);
            }

            if (isAjax(request)) {
                if (success) {
                    writeJson(response, "{\"success\":true}");
                } else {
                    writeJson(response, "{\"success\":false,\"error\":\"寫入失敗，請稍後再試\"}");
                }
            } else {
                if (success) {
                    response.sendRedirect(contextPath + "/product/product_list.jsp?message=success");
                } else if (idParam != null && !idParam.isEmpty()) {
                    response.sendRedirect(contextPath + "/product/edit_product.jsp?id=" + idParam + "&error=failed");
                } else {
                    response.sendRedirect(contextPath + "/product/add_product.jsp?error=failed");
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to save product", e);
            if (isAjax(request)) {
                String msg = e.getMessage() != null ? e.getMessage().replace("\\", "\\\\").replace("\"", "\\\"") : "系統錯誤";
                writeJson(response, "{\"success\":false,\"error\":\"" + msg + "\"}");
            } else {
                if (idParam != null && !idParam.isEmpty()) {
                    response.sendRedirect(contextPath + "/product/edit_product.jsp?id=" + idParam + "&error=exception");
                } else {
                    response.sendRedirect(contextPath + "/product/add_product.jsp?error=exception");
                }
            }
        }
    }
}
