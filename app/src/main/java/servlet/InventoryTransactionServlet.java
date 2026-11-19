package servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import dao.InventoryTransactionDao;
import model.InventoryTransaction;
import model.User;

@WebServlet("/InventoryTransactionServlet")
public class InventoryTransactionServlet extends BaseServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(InventoryTransactionServlet.class.getName());

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        String contextPath = request.getContextPath();

        try {
            int warehouseId = Integer.parseInt(request.getParameter("warehouseId"));
            int itemId = Integer.parseInt(request.getParameter("itemId"));
            int transactionType = Integer.parseInt(request.getParameter("transactionType"));
            BigDecimal quantity = new BigDecimal(request.getParameter("quantity"));
            String note = request.getParameter("note");

            if (transactionType == 2 || transactionType == 4 || transactionType == 6) {
                quantity = quantity.negate();
            }

            HttpSession session = request.getSession();
            User user = (User) session.getAttribute("user");

            InventoryTransactionDao dao = new InventoryTransactionDao();
            InventoryTransaction t = new InventoryTransaction();
            t.setTransactionNumber(dao.generateTransactionNumber());
            t.setWarehouseId(warehouseId);
            t.setItemId(itemId);
            t.setTransactionType(transactionType);
            t.setQuantity(quantity);
            t.setNote(note);
            if (user != null) t.setCreatedBy(user.getId());

            boolean success = dao.createTransaction(t);

            if (success) {
                response.sendRedirect(contextPath + "/inventory/transaction_list.jsp?message=success");
            } else {
                response.sendRedirect(contextPath + "/inventory/add_transaction.jsp?error=failed");
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to create inventory transaction", e);
            response.sendRedirect(contextPath + "/inventory/add_transaction.jsp?error=exception");
        }
    }
}
