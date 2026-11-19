package servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import dao.InventoryItemDao;
import model.InventoryItem;

@WebServlet("/InventoryItemServlet")
public class InventoryItemServlet extends BaseServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(InventoryItemServlet.class.getName());

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        String idParam = request.getParameter("id");
        String contextPath = request.getContextPath();

        try {
            String itemCode = request.getParameter("itemCode");
            String itemName = request.getParameter("itemName");
            int itemType = Integer.parseInt(request.getParameter("itemType"));
            String productIdParam = request.getParameter("productId");
            String unit = request.getParameter("unit");
            BigDecimal unitCost = request.getParameter("unitCost") != null && !request.getParameter("unitCost").isEmpty()
                    ? new BigDecimal(request.getParameter("unitCost")) : BigDecimal.ZERO;
            BigDecimal safetyStock = request.getParameter("safetyStock") != null && !request.getParameter("safetyStock").isEmpty()
                    ? new BigDecimal(request.getParameter("safetyStock")) : BigDecimal.ZERO;
            int status = Integer.parseInt(request.getParameter("status"));
            String note = request.getParameter("note");

            InventoryItem item = new InventoryItem();
            item.setItemCode(itemCode);
            item.setItemName(itemName);
            item.setItemType(itemType);
            if (productIdParam != null && !productIdParam.isEmpty()) {
                item.setProductId(Integer.parseInt(productIdParam));
            }
            item.setUnit(unit);
            item.setUnitCost(unitCost);
            item.setSafetyStock(safetyStock);
            item.setStatus(status);
            item.setNote(note);

            InventoryItemDao dao = new InventoryItemDao();
            boolean success;

            if (idParam != null && !idParam.isEmpty()) {
                item.setId(Integer.parseInt(idParam));
                success = dao.updateItem(item);
            } else {
                success = dao.insertItem(item);
            }

            if (success) {
                response.sendRedirect(contextPath + "/inventory/item_list.jsp?message=success");
            } else if (idParam != null && !idParam.isEmpty()) {
                response.sendRedirect(contextPath + "/inventory/edit_item.jsp?id=" + idParam + "&error=failed");
            } else {
                response.sendRedirect(contextPath + "/inventory/add_item.jsp?error=failed");
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to save inventory item", e);
            if (idParam != null && !idParam.isEmpty()) {
                response.sendRedirect(contextPath + "/inventory/edit_item.jsp?id=" + idParam + "&error=exception");
            } else {
                response.sendRedirect(contextPath + "/inventory/add_item.jsp?error=exception");
            }
        }
    }
}
