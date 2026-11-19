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
import dao.InventoryItemDao;
import dao.InventoryTransactionDao;
import dao.ProductionDao;
import model.InventoryItem;
import model.InventoryTransaction;
import model.Production;

@WebServlet("/ProductionServlet")
@MultipartConfig
public class ProductionServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(ProductionServlet.class.getName());

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        doPost(request, response);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        String idParam = request.getParameter("id");
        String action = request.getParameter("action");
        String contextPath = request.getContextPath();

        ProductionDao dao = new ProductionDao();

        if ("get".equals(action)) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            try {
                int prodId = Integer.parseInt(idParam);
                Production prod = dao.getProductionById(prodId);
                if (prod == null) { response.getWriter().write("{\"success\":false}"); return; }
                BigDecimal receivedQty = dao.getNetReceivedQty(prodId);
                BigDecimal otherManuf = dao.getOtherManufacturedQty(prod.getOrderId(), prodId);
                String expectedDeliveryDate = dao.getExpectedDeliveryDate(prod.getOrderId());
                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                SimpleDateFormat dtf = new SimpleDateFormat("yyyy-MM-dd HH:mm");
                StringBuilder j = new StringBuilder("{");
                j.append("\"success\":true");
                j.append(",\"id\":").append(prod.getId());
                j.append(",\"orderId\":").append(prod.getOrderId());
                j.append(",\"orderNumber\":\"").append(safe(prod.getOrderNumber())).append("\"");
                j.append(",\"customerName\":\"").append(safe(prod.getCustomerName())).append("\"");
                j.append(",\"productId\":").append(prod.getProductId());
                j.append(",\"productName\":\"").append(safe(prod.getProductName())).append("\"");
                j.append(",\"productionNumber\":\"").append(safe(prod.getProductionNumber())).append("\"");
                j.append(",\"priceType\":").append(prod.getPriceType());
                j.append(",\"unitPrice\":\"").append(prod.getUnitPrice()!=null?prod.getUnitPrice().toPlainString():"").append("\"");
                j.append(",\"unitWeight\":\"").append(prod.getUnitWeight()!=null?prod.getUnitWeight().toPlainString():"").append("\"");
                j.append(",\"quantity\":\"").append(prod.getQuantity()!=null?prod.getQuantity().toPlainString():"0").append("\"");
                j.append(",\"orderQuantity\":\"").append(prod.getOrderQuantity()!=null?prod.getOrderQuantity().toPlainString():"0").append("\"");
                j.append(",\"producedQty\":\"").append(prod.getProducedQty()!=null?prod.getProducedQty().toPlainString():"0").append("\"");
                j.append(",\"manufacturedQty\":\"").append(prod.getManufacturedQty()!=null?prod.getManufacturedQty().toPlainString():"0").append("\"");
                j.append(",\"status\":").append(prod.getStatus());
                j.append(",\"closeStatus\":").append(prod.getCloseStatus());
                j.append(",\"startDate\":\"").append(prod.getStartDate()!=null?sdf.format(prod.getStartDate()):"").append("\"");
                j.append(",\"targetDate\":\"").append(prod.getTargetDate()!=null?sdf.format(prod.getTargetDate()):"").append("\"");
                j.append(",\"completedDate\":\"").append(prod.getCompletedDate()!=null?sdf.format(prod.getCompletedDate()):"").append("\"");
                j.append(",\"note\":\"").append(safe(prod.getNote())).append("\"");
                j.append(",\"createdAt\":\"").append(prod.getCreatedAt()!=null?dtf.format(prod.getCreatedAt()):"").append("\"");
                j.append(",\"updatedAt\":\"").append(prod.getUpdatedAt()!=null?dtf.format(prod.getUpdatedAt()):"").append("\"");
                j.append(",\"receivedQty\":\"").append(receivedQty.toPlainString()).append("\"");
                j.append(",\"otherManufactured\":\"").append(otherManuf.toPlainString()).append("\"");
                j.append(",\"expectedDeliveryDate\":\"").append(expectedDeliveryDate).append("\"");
                j.append("}");
                response.getWriter().write(j.toString());
            } catch (Exception e) { LOGGER.log(Level.SEVERE, "Failed to get production detail", e); response.getWriter().write("{\"success\":false}"); }
            return;
        }

        if ("cancel".equals(action)) {
            int prodId = Integer.parseInt(idParam);
            int newStatus = Integer.parseInt(request.getParameter("status"));
            BigDecimal received = dao.getNetReceivedQty(prodId);
            if (newStatus == 3 && received.compareTo(BigDecimal.ZERO) > 0) {
                response.sendRedirect(contextPath + "/production/edit_production.jsp?id=" + idParam + "&error=cancel_blocked");
                return;
            }
            Production prod = dao.getProductionById(prodId);
            if (prod != null) {
                prod.setStatus(newStatus);
                dao.updateProduction(prod);
            }
            String orderId = request.getParameter("orderId");
            String msg = newStatus == 3 ? "deleted" : "unclosed";
            response.sendRedirect(contextPath + "/production/production_list.jsp?orderId=" + (orderId != null ? orderId : "") + "&message=" + msg);
            return;
        }

        if ("pause".equals(action)) {
            String orderIdParam = request.getParameter("orderId");
            int prodId = Integer.parseInt(idParam);
            BigDecimal received = dao.getNetReceivedQty(prodId);
            if (received.compareTo(BigDecimal.ZERO) > 0) {
                String redirect = contextPath + "/production/production_list.jsp?error=delete_blocked" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : "");
                response.sendRedirect(redirect);
                return;
            }
            Production prod = dao.getProductionById(prodId);
            if (prod != null) {
                prod.setStatus(3);
                dao.updateProduction(prod);
            }
            response.sendRedirect(contextPath + "/production/production_list.jsp?message=paused" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
            return;
        }

        if ("restore".equals(action)) {
            String orderIdParam = request.getParameter("orderId");
            int prodId = Integer.parseInt(idParam);
            Production prod = dao.getProductionById(prodId);
            if (prod != null) {
                prod.setStatus(0);
                prod.setCloseStatus(0);
                dao.updateProduction(prod);
            }
            boolean isAjax = "XMLHttpRequest".equals(request.getHeader("X-Requested-With"));
            if (isAjax) {
                response.setContentType("application/json");
                response.getWriter().write("{\"success\":true}");
            } else {
                response.sendRedirect(contextPath + "/production/production_list.jsp?message=restored" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
            }
            return;
        }

        if ("delete".equals(action)) {
            String orderIdParam = request.getParameter("orderId");
            int prodId = Integer.parseInt(idParam);
            BigDecimal received = dao.getNetReceivedQty(prodId);
            if (received.compareTo(BigDecimal.ZERO) > 0) {
                response.sendRedirect(contextPath + "/production/production_list.jsp?error=delete_blocked" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
                return;
            }
            boolean success = dao.deleteProduction(Integer.parseInt(idParam));
            if (success) {
                response.sendRedirect(contextPath + "/production/production_list.jsp?message=deleted" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
            } else {
                response.sendRedirect(contextPath + "/production/production_list.jsp?error=deletefailed" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
            }
            return;
        }

        if ("close".equals(action)) {
            String orderIdParam = request.getParameter("orderId");
            try {
                int prodId = Integer.parseInt(idParam);
                Production prod = dao.getProductionById(prodId);
                if (prod == null) {
                    response.sendRedirect(contextPath + "/production/production_list.jsp?error=notfound");
                    return;
                }
                if (prod.getCloseStatus() == 1) {
                    response.sendRedirect(contextPath + "/production/production_list.jsp?error=already_closed" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
                    return;
                }
                if (prod.getStatus() == 3) {
                    response.sendRedirect(contextPath + "/production/production_list.jsp?error=cancelled_cannot_close" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
                    return;
                }
                BigDecimal planned = prod.getProducedQty() != null ? prod.getProducedQty() : BigDecimal.ZERO;
                BigDecimal manuf = prod.getManufacturedQty() != null ? prod.getManufacturedQty() : BigDecimal.ZERO;
                if (planned.compareTo(BigDecimal.ZERO) <= 0 || manuf.compareTo(planned) < 0) {
                    response.sendRedirect(contextPath + "/production/production_list.jsp?error=not_completed" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
                    return;
                }
                BigDecimal received = dao.getNetReceivedQty(prodId);
                if (received.compareTo(manuf) < 0) {
                    response.sendRedirect(contextPath + "/production/production_list.jsp?error=not_all_received" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
                    return;
                }
                prod.setCloseStatus(1);
                dao.updateProduction(prod);
                response.sendRedirect(contextPath + "/production/production_list.jsp?message=closed" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to close production", e);
                String orderIdParam2 = request.getParameter("orderId");
                response.sendRedirect(contextPath + "/production/production_list.jsp?error=exception" + (orderIdParam2 != null && !orderIdParam2.isEmpty() ? "&orderId=" + orderIdParam2 : ""));
            }
            return;
        }

        if ("unclose".equals(action)) {
            String orderIdParam = request.getParameter("orderId");
            try {
                int prodId = Integer.parseInt(idParam);
                Production prod = dao.getProductionById(prodId);
                if (prod != null) {
                    prod.setCloseStatus(0);
                    dao.updateProduction(prod);
                }
                response.sendRedirect(contextPath + "/production/production_list.jsp?message=unclosed" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to unclose production", e);
                response.sendRedirect(contextPath + "/production/production_list.jsp?error=exception" + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : ""));
            }
            return;
        }

        if ("reverse_receipt".equals(action)) {
            String qtyStr = request.getParameter("quantity");
            try {
                BigDecimal revQty = new BigDecimal(qtyStr);
                if (revQty.compareTo(BigDecimal.ZERO) <= 0) {
                    response.sendRedirect(contextPath + "/production/edit_production.jsp?id=" + idParam + "&error=reverse_invalid");
                    return;
                }
                int prodId = Integer.parseInt(idParam);
                Object[] info = dao.getReceivedInfo(prodId);
                int prodProductId = (Integer) info[0];
                int prodOrderId = (Integer) info[1];
                BigDecimal receivedQty = (BigDecimal) info[2];
                if (revQty.compareTo(receivedQty) > 0) {
                    response.sendRedirect(contextPath + "/production/edit_production.jsp?id=" + idParam + "&error=reverse_exceed");
                    return;
                }
                InventoryTransactionDao txnDao = new InventoryTransactionDao();
                InventoryItemDao itemDao = new InventoryItemDao();
                InventoryItem item = itemDao.findByProductId(prodProductId);
                if (item != null) {
                    InventoryTransaction t = new InventoryTransaction();
                    t.setTransactionNumber(txnDao.generateTransactionNumber());
                    t.setWarehouseId(2);
                    t.setItemId(item.getId());
                    t.setTransactionType(1);
                    t.setQuantity(revQty.negate());
                    t.setRefType("production");
                    t.setRefId(prodId);
                    t.setOrderId(prodOrderId);
                    t.setProductionId(prodId);
                    t.setNote("工單沖正入庫");
                    txnDao.createTransaction(t);
                }
                response.sendRedirect(contextPath + "/production/edit_production.jsp?id=" + idParam + "&message=reversed");
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Failed to reverse production receipt", e);
                response.sendRedirect(contextPath + "/production/edit_production.jsp?id=" + idParam + "&error=reverse_failed");
            }
            return;
        }

        try {
            int orderId = parseIntParam(request.getParameter("orderId"));
            int productId = parseIntParam(request.getParameter("productId"));
            int priceType = parseIntParam(request.getParameter("priceType"));
            BigDecimal unitPrice = request.getParameter("unitPrice") != null && !request.getParameter("unitPrice").isEmpty()
                    ? new BigDecimal(request.getParameter("unitPrice")) : null;
            BigDecimal unitWeight = request.getParameter("unitWeight") != null && !request.getParameter("unitWeight").isEmpty()
                    ? new BigDecimal(request.getParameter("unitWeight")) : null;
            BigDecimal quantity = request.getParameter("quantity") != null && !request.getParameter("quantity").isEmpty()
                    ? new BigDecimal(request.getParameter("quantity")) : BigDecimal.ZERO;
            BigDecimal producedQty = request.getParameter("producedQty") != null && !request.getParameter("producedQty").isEmpty()
                    ? new BigDecimal(request.getParameter("producedQty")) : BigDecimal.ZERO;
            BigDecimal manufacturedQty = request.getParameter("manufacturedQty") != null && !request.getParameter("manufacturedQty").isEmpty()
                    ? new BigDecimal(request.getParameter("manufacturedQty")) : BigDecimal.ZERO;
            int status = parseIntParam(request.getParameter("status"));

            if (manufacturedQty.compareTo(producedQty) > 0) {
                boolean isAjax = "XMLHttpRequest".equals(request.getHeader("X-Requested-With"));
                if (isAjax) {
                    response.setContentType("application/json");
                    response.getWriter().write("{\"success\":false,\"error\":\"實際生產量不得大於預計生產量\"}");
                } else {
                    String back = idParam != null && !idParam.isEmpty() ? "edit_production.jsp?id=" + idParam : "add_production.jsp";
                    response.sendRedirect(contextPath + "/production/" + back + "&error=manufactured_exceed");
                }
                return;
            }

            String startDateStr = request.getParameter("startDate");
            String targetDateStr = request.getParameter("targetDate");
            String completedDateStr = request.getParameter("completedDate");
            String note = request.getParameter("note");

            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");

            Production prod = new Production();
            prod.setOrderId(orderId);
            prod.setProductId(productId);
            prod.setPriceType(priceType);
            prod.setUnitPrice(unitPrice);
            prod.setUnitWeight(unitWeight);
            prod.setQuantity(quantity);
            prod.setProducedQty(producedQty);
            prod.setManufacturedQty(manufacturedQty);
            prod.setStatus(status);
            prod.setStartDate(startDateStr != null && !startDateStr.isEmpty() ? sdf.parse(startDateStr) : null);
            prod.setTargetDate(targetDateStr != null && !targetDateStr.isEmpty() ? sdf.parse(targetDateStr) : null);
            prod.setCompletedDate(completedDateStr != null && !completedDateStr.isEmpty() ? sdf.parse(completedDateStr) : null);
            prod.setNote(note);

            boolean success;

            if (idParam != null && !idParam.isEmpty()) {
                prod.setId(Integer.parseInt(idParam));

                // Check manufacturedQty >= already received qty
                if (manufacturedQty.compareTo(BigDecimal.ZERO) > 0) {
                    BigDecimal received = dao.getNetReceivedQty(Integer.parseInt(idParam));
                    if (manufacturedQty.compareTo(received) < 0) {
                        response.sendRedirect(contextPath + "/production/edit_production.jsp?id=" + idParam + "&error=receipt_conflict");
                        return;
                    }
                }

                // Cancel logic: if setting status to 3 (cancelled), auto-reverse received inventory
                if (status == 3) {
                    int prodId = Integer.parseInt(idParam);
                    Object[] info = dao.getReceivedInfo(prodId);
                    int prodProductId = (Integer) info[0];
                    int prodOrderId = (Integer) info[1];
                    BigDecimal receivedQty = (BigDecimal) info[2];

                    if (receivedQty.compareTo(BigDecimal.ZERO) > 0) {
                        // Check WH-FG stock (warehouse_id=2) for this product
                        BigDecimal stock = dao.getStockForProduct(prodProductId);

                        if (stock.compareTo(receivedQty) < 0) {
                            response.sendRedirect(contextPath + "/production/edit_production.jsp?id=" + idParam + "&error=cancel_blocked");
                            return;
                        }

                        // Auto-reverse: create inventory transaction
                        InventoryTransactionDao txnDao = new InventoryTransactionDao();
                        InventoryItemDao itemDao = new InventoryItemDao();
                        InventoryItem item = itemDao.findByProductId(prodProductId);
                        if (item != null) {
                            InventoryTransaction t = new InventoryTransaction();
                            t.setTransactionNumber(txnDao.generateTransactionNumber());
                            t.setWarehouseId(2);
                            t.setItemId(item.getId());
                            t.setTransactionType(5);
                            t.setQuantity(receivedQty.negate());
                            t.setRefType("production_cancel");
                            t.setRefId(prodId);
                            t.setOrderId(prodOrderId);
                            t.setProductionId(prodId);
                            t.setNote("工單取消自動沖銷");
                            txnDao.createTransaction(t);
                        }
                    }
                }

                success = dao.updateProduction(prod);
            } else {
                prod.setProductionNumber(dao.generateProductionNumber());
                success = dao.insertProduction(prod);
            }

            boolean isAjax = "XMLHttpRequest".equals(request.getHeader("X-Requested-With"));
            if (success) {
                if (isAjax) { response.setContentType("application/json"); response.getWriter().write("{\"success\":true}"); }
                else response.sendRedirect(contextPath + "/production/production_list.jsp?orderId=" + orderId + "&message=success");
            } else {
                if (isAjax) { response.setContentType("application/json"); response.getWriter().write("{\"success\":false,\"error\":\"儲存失敗\"}"); }
                else if (idParam != null && !idParam.isEmpty()) response.sendRedirect(contextPath + "/production/edit_production.jsp?id=" + idParam + "&error=failed");
                else response.sendRedirect(contextPath + "/production/add_production.jsp?error=failed");
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to save production", e);
            boolean isAjax2 = "XMLHttpRequest".equals(request.getHeader("X-Requested-With"));
            if (isAjax2) { response.setContentType("application/json"); response.getWriter().write("{\"success\":false,\"error\":\"系統錯誤\"}"); }
            else if (idParam != null && !idParam.isEmpty()) response.sendRedirect(contextPath + "/production/edit_production.jsp?id=" + idParam + "&error=exception");
            else response.sendRedirect(contextPath + "/production/add_production.jsp?error=exception");
        }
    }

    private static String safe(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
    }

    private static int parseIntParam(String s) {
        if (s == null || s.isEmpty()) return 0;
        return Integer.parseInt(s);
    }
}
