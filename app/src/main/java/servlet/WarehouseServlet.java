package servlet;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import dao.WarehouseDao;
import model.Warehouse;

@WebServlet("/WarehouseServlet")
public class WarehouseServlet extends BaseServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(WarehouseServlet.class.getName());

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        String idParam = request.getParameter("id");
        String contextPath = request.getContextPath();

        try {
            String warehouseCode = request.getParameter("warehouseCode");
            String warehouseName = request.getParameter("warehouseName");
            String contactPerson = request.getParameter("contactPerson");
            String phone = request.getParameter("phone");
            String address = request.getParameter("address");
            int status = Integer.parseInt(request.getParameter("status"));
            String note = request.getParameter("note");

            Warehouse w = new Warehouse();
            w.setWarehouseCode(warehouseCode);
            w.setWarehouseName(warehouseName);
            w.setContactPerson(contactPerson);
            w.setPhone(phone);
            w.setAddress(address);
            w.setStatus(status);
            w.setNote(note);

            WarehouseDao dao = new WarehouseDao();
            boolean success;

            if (idParam != null && !idParam.isEmpty()) {
                w.setId(Integer.parseInt(idParam));
                success = dao.updateWarehouse(w);
            } else {
                success = dao.insertWarehouse(w);
            }

            if (success) {
                response.sendRedirect(contextPath + "/inventory/warehouse_list.jsp?message=success");
            } else if (idParam != null && !idParam.isEmpty()) {
                response.sendRedirect(contextPath + "/inventory/edit_warehouse.jsp?id=" + idParam + "&error=failed");
            } else {
                response.sendRedirect(contextPath + "/inventory/add_warehouse.jsp?error=failed");
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to save warehouse", e);
            if (idParam != null && !idParam.isEmpty()) {
                response.sendRedirect(contextPath + "/inventory/edit_warehouse.jsp?id=" + idParam + "&error=exception");
            } else {
                response.sendRedirect(contextPath + "/inventory/add_warehouse.jsp?error=exception");
            }
        }
    }
}
