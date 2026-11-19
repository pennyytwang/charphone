<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.InventoryItemDao, dao.ProductDao, util.NumberUtil, model.InventoryItem, model.Product, java.util.List" %>
<% request.setAttribute("pageTitle", "編輯庫存品項"); %>
<% request.setAttribute("pageIcon", "▣"); %>
<% request.setAttribute("pageSubtitle", "修改庫存品項"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>編輯庫存品項</h2>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">資料庫更新失敗。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請檢查輸入資料格式。</div>
    <% }

        String idStr = request.getParameter("id");
        InventoryItem item = null;
        if (idStr != null && !idStr.isEmpty()) {
            try {
                InventoryItemDao dao = new InventoryItemDao();
                item = dao.getItemById(Integer.parseInt(idStr));
            } catch (Exception e) {
                out.println("<div class='error-msg'>找不到該品項資料。</div>");
            }
        }
        if (item == null) {
            out.println("<div class='error-msg'>無效的品項編號。</div>");
        } else {
    %>

    <form action="<%= request.getContextPath() %>/InventoryItemServlet" method="POST">
        <input type="hidden" name="id" value="<%= item.getId() %>">

        <div class="form-group">
            <label>品項編號：</label>
            <input type="text" name="itemCode" value="<%= item.getItemCode() != null ? item.getItemCode() : "" %>" required>
        </div>

        <div class="form-group">
            <label>品項名稱：</label>
            <input type="text" name="itemName" value="<%= item.getItemName() != null ? item.getItemName() : "" %>" required>
        </div>

        <div class="row-2">
            <div class="form-group">
                <label>類型：</label>
                <select name="itemType">
                    <option value="1" <%= item.getItemType() == 1 ? "selected" : "" %>>原料</option>
                    <option value="2" <%= item.getItemType() == 2 ? "selected" : "" %>>半成品</option>
                    <option value="3" <%= item.getItemType() == 3 ? "selected" : "" %>>成品</option>
                </select>
            </div>
            <div class="form-group">
                <label>單位：</label>
                <select name="unit">
                    <option value="kg" <%= "kg".equals(item.getUnit()) ? "selected" : "" %>>kg</option>
                    <option value="pcs" <%= "pcs".equals(item.getUnit()) ? "selected" : "" %>>pcs</option>
                    <option value="m" <%= "m".equals(item.getUnit()) ? "selected" : "" %>>m</option>
                    <option value="L" <%= "L".equals(item.getUnit()) ? "selected" : "" %>>L</option>
                </select>
            </div>
        </div>

        <div class="form-group">
            <label>關聯產品（成品限定）：</label>
            <select name="productId">
                <option value="">-- 不關聯 --</option>
                <%
                    try {
                        ProductDao pdao = new ProductDao();
                        List<Product> products = pdao.getAllProducts();
                        for (Product p : products) {
                %>
                    <option value="<%= p.getId() %>" <%= item.getProductId() != null && item.getProductId() == p.getId() ? "selected" : "" %>><%= p.getProductName() %></option>
                <%
                        }
                    } catch (Exception e) {}
                %>
            </select>
        </div>

        <div class="row-2">
            <div class="form-group">
                <label>單位成本：</label>
                <input type="number" name="unitCost" step="any" value="<%= item.getUnitCost() != null ? NumberUtil.fmtMoney(item.getUnitCost()) : "" %>">
            </div>
            <div class="form-group">
                <label>安全庫存量：</label>
                <input type="number" name="safetyStock" step="any" value="<%= item.getSafetyStock() != null ? NumberUtil.fmtQty(item.getSafetyStock().doubleValue()) : "" %>">
            </div>
        </div>

        <div class="form-group">
            <label>狀態：</label>
            <select name="status">
                <option value="1" <%= item.getStatus() == 1 ? "selected" : "" %>>啟用</option>
                <option value="0" <%= item.getStatus() == 0 ? "selected" : "" %>>停用</option>
            </select>
        </div>

        <div class="form-group">
            <label>備註：</label>
            <textarea name="note" rows="3"><%= item.getNote() != null ? item.getNote() : "" %></textarea>
        </div>

        <button type="submit" class="btn-submit">儲存修改</button>
        <a href="item_list.jsp" class="back-link">返回品項列表</a>
    </form>
    <% } %>
</div>

<%@ include file="../include/footer.jsp" %>
