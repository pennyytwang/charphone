<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.ProductDao, util.NumberUtil, model.Product" %>
<% request.setAttribute("pageTitle", "編輯品項"); %>
<% request.setAttribute("pageIcon", "★"); %>
<% request.setAttribute("pageSubtitle", "修改品項資料"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>編輯品項</h2>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">資料庫更新失敗，請稍後再試。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請檢查輸入資料格式。</div>
    <% }

        String idStr = request.getParameter("id");
        Product p = null;
        if (idStr != null && !idStr.isEmpty()) {
            try {
                ProductDao dao = new ProductDao();
                p = dao.getProductById(Integer.parseInt(idStr));
            } catch (Exception e) {
                out.println("<div class='error-msg'>找不到該品項資料。</div>");
            }
        }
        if (p == null) {
            out.println("<div class='error-msg'>無效的品項編號。</div>");
        } else {
    %>

    <form action="<%= request.getContextPath() %>/ProductServlet" method="POST">
        <input type="hidden" name="id" value="<%= p.getId() %>">

        <div class="form-group">
            <label>產品編號：</label>
            <input type="text" name="productCode" value="<%= p.getProductCode() != null ? p.getProductCode() : "" %>">
        </div>

        <div class="form-group">
            <label>產品名稱：</label>
            <input type="text" name="productName" value="<%= p.getProductName() != null ? p.getProductName() : "" %>" required>
        </div>

        <div class="form-group">
            <label>計價方式：</label>
            <select name="priceType">
                <option value="1" <%= p.getPriceType() == 1 ? "selected" : "" %>>按重量 (kg)</option>
                <option value="2" <%= p.getPriceType() == 2 ? "selected" : "" %>>按個數 (pcs)</option>
            </select>
        </div>

        <div class="form-group">
            <label>單個重量 (kg)：</label>
            <input type="number" name="unitWeight" step="any" value="<%= p.getUnitWeight() != null ? NumberUtil.fmtQty(p.getUnitWeight().doubleValue()) : "" %>">
        </div>

        <div class="form-group">
            <label>代工單價：</label>
            <input type="number" name="unitPrice" step="any" value="<%= p.getUnitPrice() != null ? NumberUtil.fmtMoney(p.getUnitPrice()) : "" %>">
        </div>

        <div class="form-group">
            <label>備註：</label>
            <textarea name="description" rows="3"><%= p.getDescription() != null ? p.getDescription() : "" %></textarea>
        </div>

        <button type="submit" class="btn-submit">儲存修改</button>
        <a href="product_list.jsp" class="back-link">返回品項列表</a>
    </form>
    <% } %>
</div>

<%@ include file="../include/footer.jsp" %>
