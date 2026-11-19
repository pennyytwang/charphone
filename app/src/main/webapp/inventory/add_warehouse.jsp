<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<% request.setAttribute("pageTitle", "新增倉庫"); %>
<% request.setAttribute("pageIcon", "▣"); %>
<% request.setAttribute("pageSubtitle", "建立倉庫"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>新增倉庫</h2>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">資料庫寫入失敗。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請檢查輸入資料格式。</div>
    <% } %>

    <form action="<%= request.getContextPath() %>/WarehouseServlet" method="POST">

        <div class="form-group">
            <label>倉庫代碼：</label>
            <input type="text" name="warehouseCode" placeholder="例如: WH-001" required>
        </div>

        <div class="form-group">
            <label>倉庫名稱：</label>
            <input type="text" name="warehouseName" placeholder="例如: 原料倉" required>
        </div>

        <div class="form-group">
            <label>聯絡人：</label>
            <input type="text" name="contactPerson" placeholder="倉庫管理員姓名">
        </div>

        <div class="form-group">
            <label>電話：</label>
            <input type="text" name="phone" placeholder="例如: 03-1234567">
        </div>

        <div class="form-group">
            <label>地址：</label>
            <input type="text" name="address" placeholder="倉庫地址">
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
        <a href="warehouse_list.jsp" class="back-link">返回倉庫列表</a>
    </form>
</div>

<%@ include file="../include/footer.jsp" %>
