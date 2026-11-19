<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.math.BigDecimal, java.util.*, dao.ProductDao, dao.ProductionDao, model.Product" %>
<% request.setAttribute("pageTitle", "出貨試算"); %>
<% request.setAttribute("pageIcon", "▶"); %>
<% request.setAttribute("pageSubtitle", "工單出貨試算"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>出貨試算</h2>

    <form method="GET" action="delivery_check.jsp" class="filter-form" style="display:flex;gap:12px;flex-wrap:wrap;align-items:flex-end;margin-bottom:20px;">
        <div>
            <label style="display:block;font-size:13px;margin-bottom:4px;">產品</label>
            <select name="productId" style="padding:6px;border:1px solid #ccc;border-radius:4px;min-width:200px;">
                <option value="">-- 請選擇產品 --</option>
                <%
                    String selProductId = request.getParameter("productId");
                    ProductDao productDao = new ProductDao();
                    for (Product prod : productDao.getAllProducts()) {
                        boolean selected = selProductId != null && selProductId.equals(String.valueOf(prod.getId()));
                %>
                <option value="<%= prod.getId() %>" <%= selected ? "selected" : "" %>><%= prod.getProductName() %></option>
                <%
                    }
                %>
            </select>
        </div>
        <div>
            <label style="display:block;font-size:13px;margin-bottom:4px;">預計出貨日</label>
            <input type="date" name="deliveryDate" value="<%= request.getParameter("deliveryDate") != null ? request.getParameter("deliveryDate") : "" %>" style="padding:6px;border:1px solid #ccc;border-radius:4px;">
        </div>
        <div>
            <label style="display:block;font-size:13px;margin-bottom:4px;">預計出貨量</label>
            <input type="number" name="deliveryQty" step="any" value="<%= request.getParameter("deliveryQty") != null ? request.getParameter("deliveryQty") : "" %>" style="padding:6px;border:1px solid #ccc;border-radius:4px;width:120px;">
        </div>
        <button type="submit" class="btn-submit" style="padding:6px 20px;">試算</button>
    </form>

    <%
        if (selProductId == null || selProductId.isEmpty()) return;
        int productId = Integer.parseInt(selProductId);
        String deliveryDateStr = request.getParameter("deliveryDate");
        String deliveryQtyStr = request.getParameter("deliveryQty");
        if (deliveryDateStr == null || deliveryDateStr.isEmpty() || deliveryQtyStr == null || deliveryQtyStr.isEmpty()) return;

        BigDecimal deliveryQty = new BigDecimal(deliveryQtyStr);
        String productName = "";

        try {
            ProductDao prodDao = new ProductDao();
            Product prod = prodDao.getProductById(productId);
            productName = prod != null ? prod.getProductName() : "";
            ProductionDao prodDao2 = new ProductionDao();
            BigDecimal currentStock = prodDao2.getStockForProduct(productId);

            List<Map<String, Object>> prodList = prodDao2.getProductionsByProductAndDate(productId, deliveryDateStr);
            BigDecimal potentialSupply = BigDecimal.ZERO;
            for (Map<String, Object> row : prodList) {
                BigDecimal planned = (BigDecimal) row.get("planned");
                BigDecimal received = (BigDecimal) row.get("received");
                BigDecimal remaining = planned.subtract(received);
                if (remaining.compareTo(BigDecimal.ZERO) > 0) {
                    potentialSupply = potentialSupply.add(remaining);
                }
            }

            BigDecimal totalAvailable = currentStock.add(potentialSupply);
            boolean canDeliver = totalAvailable.compareTo(deliveryQty) >= 0;
    %>

    <div style="background:#fff;border:1px solid #ddd;border-radius:8px;padding:20px;">
        <h3 style="margin-top:0;">試算結果：<%= productName %></h3>

        <table style="width:100%;border-collapse:collapse;margin-bottom:16px;">
            <tr>
                <td style="padding:8px;border-bottom:1px solid #eee;font-weight:bold;">目前 WH-FG 庫存</td>
                <td style="padding:8px;border-bottom:1px solid #eee;text-align:right;"><%= currentStock %></td>
            </tr>
            <tr>
                <td style="padding:8px;border-bottom:1px solid #eee;font-weight:bold;">到期前未入庫量（<%= prodList.size() %> 筆工單）</td>
                <td style="padding:8px;border-bottom:1px solid #eee;text-align:right;color:#1976d2;">+ <%= potentialSupply %></td>
            </tr>
            <tr style="font-size:16px;">
                <td style="padding:8px;border-bottom:2px solid #333;font-weight:bold;">預計可供量</td>
                <td style="padding:8px;border-bottom:2px solid #333;text-align:right;font-weight:bold;"><%= totalAvailable %></td>
            </tr>
            <tr>
                <td style="padding:8px;font-weight:bold;">預計出貨量</td>
                <td style="padding:8px;text-align:right;"><%= deliveryQty %></td>
            </tr>
        </table>

        <div style="text-align:center;padding:16px;border-radius:8px;font-size:18px;font-weight:bold;background:<%= canDeliver ? "#e8f5e9" : "#ffebee" %>;color:<%= canDeliver ? "#2e7d32" : "#c62828" %>;">
            <%= canDeliver ? "✅  可如期出貨" : "❌  可能短缺 " + deliveryQty.subtract(totalAvailable) + " 單位" %>
        </div>
    </div>

    <% if (!prodList.isEmpty()) { %>
    <h4 style="margin-top:24px;margin-bottom:8px;">到期前工單明細</h4>
    <table class="data-table">
        <tr>
            <th>工單編號</th>
            <th>計畫量</th>
            <th>已入庫</th>
            <th>待入庫</th>
            <th>目標完成日</th>
            <th>狀態</th>
        </tr>
        <% for (Map<String, Object> row : prodList) {
            BigDecimal planned = (BigDecimal) row.get("planned");
            BigDecimal received = (BigDecimal) row.get("received");
            BigDecimal remaining = planned.subtract(received);
            int st = (int) row.get("status");
        %>
        <tr>
            <td><%= row.get("num") %></td>
            <td style="text-align:right;"><%= planned %></td>
            <td style="text-align:right;"><%= received %></td>
            <td style="text-align:right;"><%= remaining.compareTo(BigDecimal.ZERO) > 0 ? remaining : BigDecimal.ZERO %></td>
            <td><%= row.get("target") %></td>
            <td><%= st == 0 ? "待生產" : st == 1 ? "生產中" : "已完成" %></td>
        </tr>
        <% } %>
    </table>
    <% } %>

    <%
        } catch (Exception e) {
            out.println("<div class='error-msg'>查詢失敗：" + e.getMessage() + "</div>");
            e.printStackTrace();
        }
    %>
</div>
<%@ include file="../include/footer.jsp" %>
