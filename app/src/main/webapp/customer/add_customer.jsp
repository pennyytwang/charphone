<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<% request.setAttribute("pageTitle", "新增客戶"); %>
<% request.setAttribute("pageIcon", "☉"); %>
<% request.setAttribute("pageSubtitle", "建立客戶資料"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>新增客戶</h2>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">資料庫寫入失敗，請稍後再試。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請檢查輸入資料格式。</div>
    <% } else if ("duplicate".equals(error)) { %>
        <div class="error-msg">此客戶電話或名稱已存在，請勿重複新增。</div>
    <% } %>

    <form action="<%= request.getContextPath() %>/CustomerServlet" method="POST">

        <div class="form-group">
            <label>客戶名稱：</label>
            <input type="text" name="customerName" placeholder="例如: 宏達精密工業" required>
        </div>

        <div class="form-group">
            <label>客戶電話：</label>
            <input type="text" name="phone" placeholder="例如: 03-1234567">
        </div>

        <div class="form-group">
            <label>統一編號：</label>
            <input type="text" name="taxId" placeholder="例如: 12345678">
        </div>

        <div class="form-group">
            <label>聯絡人：</label>
            <input type="text" name="contactPerson" placeholder="例如: 王經理">
        </div>

        <div class="form-group">
            <label>地址：</label>
            <textarea name="address" rows="2" placeholder="例如: 台中市工業區..."></textarea>
        </div>

        <div class="form-group">
            <label>送貨地址：</label>
            <textarea name="deliveryAddress" rows="2" placeholder="如與地址相同可留空"></textarea>
        </div>

        <button type="submit" class="btn-submit">確認新增</button>
        <a href="customer_list.jsp" class="back-link">返回客戶列表</a>
    </form>
</div>

<%@ include file="../include/footer.jsp" %>
