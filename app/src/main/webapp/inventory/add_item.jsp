<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.ProductDao, model.Product, java.util.List" %>
<% request.setAttribute("pageTitle", "新增庫存品項"); %>
<% request.setAttribute("pageIcon", "▣"); %>
<% request.setAttribute("pageSubtitle", "建立庫存品項"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>新增庫存品項</h2>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">資料庫寫入失敗。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請檢查輸入資料格式。</div>
    <% } %>

    <form action="<%= request.getContextPath() %>/InventoryItemServlet" method="POST">

        <div class="form-group">
            <label>品項編號：</label>
            <input type="text" name="itemCode" placeholder="例如: INV-RAW-001" required>
        </div>

        <div class="form-group">
            <label>品項名稱：</label>
            <input type="text" name="itemName" placeholder="例如: 鑄鐵原料" required>
        </div>

        <div class="row-2">
            <div class="form-group">
                <label>類型：</label>
                <select name="itemType">
                    <option value="1">原料</option>
                    <option value="2">半成品</option>
                    <option value="3">成品</option>
                </select>
            </div>
            <div class="form-group">
                <label>單位：</label>
                <select name="unit">
                    <option value="kg">kg</option>
                    <option value="pcs">pcs</option>
                    <option value="m">m</option>
                    <option value="L">L</option>
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
                    <option value="<%= p.getId() %>"><%= p.getProductName() %></option>
                <%
                        }
                    } catch (Exception e) {}
                %>
            </select>
        </div>

        <div class="row-2">
            <div class="form-group">
                <label>單位成本：</label>
                <input type="number" name="unitCost" step="any" placeholder="0.00">
            </div>
            <div class="form-group">
                <label>安全庫存量：</label>
                <input type="number" name="safetyStock" step="any" placeholder="0">
            </div>
        </div>

        <div class="form-group">
            <label>狀態：</label>
            <select name="status">
                <option value="1">啟用</option>
                <option value="0">停用</option>
            </select>
        </div>

        <div class="form-group">
            <label>備註：</label>
            <textarea name="note" rows="3" placeholder="備註事項..."></textarea>
        </div>

        <button type="submit" class="btn-submit">確認新增</button>
        <a href="item_list.jsp" class="back-link">返回品項列表</a>
    </form>
</div>

<%@ include file="../include/footer.jsp" %>
