<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.CustomerDao, model.Customer" %>
<% request.setAttribute("pageTitle", "編輯客戶"); %>
<% request.setAttribute("pageIcon", "☉"); %>
<% request.setAttribute("pageSubtitle", "修改客戶資料"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>編輯客戶</h2>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">資料庫更新失敗，請稍後再試。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請檢查輸入資料格式。</div>
    <% } else if ("duplicate".equals(error)) { %>
        <div class="error-msg">此客戶電話或名稱已被其他客戶使用。</div>
    <% }

        String idStr = request.getParameter("id");
        Customer c = null;
        if (idStr != null && !idStr.isEmpty()) {
            try {
                CustomerDao dao = new CustomerDao();
                c = dao.getCustomerById(Integer.parseInt(idStr));
            } catch (Exception e) {
                out.println("<div class='error-msg'>找不到該客戶資料。</div>");
            }
        }
        if (c == null) {
            out.println("<div class='error-msg'>無效的客戶編號。</div>");
        } else {
    %>

    <form action="<%= request.getContextPath() %>/CustomerServlet" method="POST">
        <input type="hidden" name="id" value="<%= c.getId() %>">

        <div class="form-group">
            <label>客戶編號：</label>
            <input type="text" class="readonly" value="<%= c.getCustomerNumber() != null ? c.getCustomerNumber() : String.valueOf(c.getId()) %>" readonly>
        </div>

        <div class="form-group">
            <label>客戶名稱：</label>
            <input type="text" name="customerName" value="<%= c.getCustomerName() != null ? c.getCustomerName() : "" %>" required>
        </div>

        <div class="form-group">
            <label>客戶電話：</label>
            <input type="text" name="phone" value="<%= c.getPhone() != null ? c.getPhone() : "" %>">
        </div>

        <div class="form-group">
            <label>統一編號：</label>
            <input type="text" name="taxId" value="<%= c.getTaxId() != null ? c.getTaxId() : "" %>">
        </div>

        <div class="form-group">
            <label>聯絡人：</label>
            <input type="text" name="contactPerson" value="<%= c.getContactPerson() != null ? c.getContactPerson() : "" %>">
        </div>

        <div class="form-group">
            <label>地址：</label>
            <textarea name="address" rows="2"><%= c.getAddress() != null ? c.getAddress() : "" %></textarea>
        </div>

        <div class="form-group">
            <label>送貨地址：</label>
            <textarea name="deliveryAddress" rows="2"><%= c.getDeliveryAddress() != null ? c.getDeliveryAddress() : "" %></textarea>
        </div>

        <button type="submit" class="btn-submit">儲存修改</button>
        <a href="customer_list.jsp" class="back-link">返回客戶列表</a>
    </form>
    <% } %>
</div>

<%@ include file="../include/footer.jsp" %>
