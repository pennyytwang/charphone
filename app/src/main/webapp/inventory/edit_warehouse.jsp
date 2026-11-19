<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.WarehouseDao, model.Warehouse" %>
<% request.setAttribute("pageTitle", "編輯倉庫"); %>
<% request.setAttribute("pageIcon", "▣"); %>
<% request.setAttribute("pageSubtitle", "修改倉庫"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>編輯倉庫</h2>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">資料庫更新失敗。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請檢查輸入資料格式。</div>
    <% }

        String idStr = request.getParameter("id");
        Warehouse w = null;
        if (idStr != null && !idStr.isEmpty()) {
            try {
                WarehouseDao dao = new WarehouseDao();
                w = dao.getWarehouseById(Integer.parseInt(idStr));
            } catch (Exception e) {
                out.println("<div class='error-msg'>找不到該倉庫資料。</div>");
            }
        }
        if (w == null) {
            out.println("<div class='error-msg'>無效的倉庫編號。</div>");
        } else {
    %>

    <form action="<%= request.getContextPath() %>/WarehouseServlet" method="POST">
        <input type="hidden" name="id" value="<%= w.getId() %>">

        <div class="form-group">
            <label>倉庫代碼：</label>
            <input type="text" name="warehouseCode" value="<%= w.getWarehouseCode() != null ? w.getWarehouseCode() : "" %>" required>
        </div>

        <div class="form-group">
            <label>倉庫名稱：</label>
            <input type="text" name="warehouseName" value="<%= w.getWarehouseName() != null ? w.getWarehouseName() : "" %>" required>
        </div>

        <div class="form-group">
            <label>聯絡人：</label>
            <input type="text" name="contactPerson" value="<%= w.getContactPerson() != null ? w.getContactPerson() : "" %>">
        </div>

        <div class="form-group">
            <label>電話：</label>
            <input type="text" name="phone" value="<%= w.getPhone() != null ? w.getPhone() : "" %>">
        </div>

        <div class="form-group">
            <label>地址：</label>
            <input type="text" name="address" value="<%= w.getAddress() != null ? w.getAddress() : "" %>">
        </div>

        <div class="form-group">
            <label>狀態：</label>
            <select name="status">
                <option value="1" <%= w.getStatus() == 1 ? "selected" : "" %>>啟用</option>
                <option value="0" <%= w.getStatus() == 0 ? "selected" : "" %>>停用</option>
            </select>
        </div>

        <div class="form-group">
            <label>備註：</label>
            <textarea name="note" rows="3"><%= w.getNote() != null ? w.getNote() : "" %></textarea>
        </div>

        <button type="submit" class="btn-submit">儲存修改</button>
        <a href="warehouse_list.jsp" class="back-link">返回倉庫列表</a>
    </form>
    <% } %>
</div>

<%@ include file="../include/footer.jsp" %>
