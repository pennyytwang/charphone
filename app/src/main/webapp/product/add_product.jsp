<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<% request.setAttribute("pageTitle", "新增品項"); %>
<% request.setAttribute("pageIcon", "★"); %>
<% request.setAttribute("pageSubtitle", "建立產品品項"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>新增品項</h2>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">資料庫寫入失敗，請稍後再試。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請檢查輸入資料格式。</div>
    <% } %>

    <form action="<%= request.getContextPath() %>/ProductServlet" method="POST">

        <div class="form-group">
            <label>產品編號：</label>
            <input type="text" name="productCode" placeholder="例如: P-001">
        </div>

        <div class="form-group">
            <label>產品名稱：</label>
            <input type="text" name="productName" placeholder="例如: 法蘭盤" required>
        </div>

        <div class="form-group">
            <label>計價方式：</label>
            <select name="priceType">
                <option value="1">按重量 (kg)</option>
                <option value="2">按個數 (pcs)</option>
            </select>
        </div>

        <div class="form-group">
            <label>單個重量 (kg)：</label>
            <input type="number" name="unitWeight" step="any" placeholder="例如: 1.500">
        </div>

        <div class="form-group">
            <label>代工單價：</label>
            <input type="number" name="unitPrice" step="any" placeholder="例如: 50.00">
        </div>

        <div class="form-group">
            <label>備註：</label>
            <textarea name="description" rows="3" placeholder="廠內備註事項..."></textarea>
        </div>

        <button type="submit" class="btn-submit">確認新增</button>
        <a href="product_list.jsp" class="back-link">返回品項列表</a>
    </form>
</div>

<%@ include file="../include/footer.jsp" %>
