<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.text.SimpleDateFormat, dao.DeliveryDao, util.NumberUtil, model.Delivery" %>
<% request.setAttribute("pageTitle", "編輯出貨"); %>
<% request.setAttribute("pageIcon", "▶"); %>
<% request.setAttribute("pageSubtitle", "修改出貨記錄"); %>
<%@ include file="../include/header.jsp" %>
<div class="form-container">
    <h2>編輯出貨記錄</h2>

    <%
        String editError = request.getParameter("error");
        if ("exceed_order_remaining".equals(editError)) {
    %>
        <div class="error-msg">出貨數量超出訂單剩餘可出量。</div>
    <% } else if ("insufficient_stock".equals(editError)) { %>
        <div class="error-msg">成品倉庫存不足，無法出貨。</div>
    <% } else if ("exception".equals(editError)) { %>
        <div class="error-msg">系統錯誤，請稍後再試。</div>
    <% } %>

    <%
        String idStr = request.getParameter("id");
        Delivery d = null;
        if (idStr != null && !idStr.isEmpty()) {
            try {
                DeliveryDao dao = new DeliveryDao();
                d = dao.getDeliveryById(Integer.parseInt(idStr));
            } catch (Exception e) {
                out.println("<div class='error-msg'>找不到該出貨記錄。</div>");
            }
        }
        if (d == null) {
            out.println("<div class='error-msg'>無效的編號。</div>");
        } else {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    %>

    <div class="order-info">
        <b>出貨單號：</b><%= d.getDeliveryNumber() %> |
        <b>訂單：</b><%= d.getOrderNumber() %> |
        <b>客戶：</b><%= d.getCustomerName() %>
    </div>

    <form action="<%= request.getContextPath() %>/DeliveryServlet" method="POST">
        <input type="hidden" name="id" value="<%= d.getId() %>">
        <input type="hidden" name="orderId" value="<%= d.getOrderId() %>">

        <div class="form-group">
            <label>出貨日期：</label>
            <input type="date" name="deliveryDate" value="<%= sdf.format(d.getDeliveryDate()) %>" required>
        </div>

        <div class="form-group">
            <label>出貨數量：</label>
            <input type="number" name="quantity" step="any" value="<%= NumberUtil.fmtQty(d.getQuantity().doubleValue()) %>" required>
        </div>

        <div class="form-group">
            <label>狀態：</label>
            <select name="status">
                <option value="1" <%= d.getStatus() == 1 ? "selected" : "" %>>已出貨</option>
                <option value="0" <%= d.getStatus() == 0 ? "selected" : "" %>>取消</option>
            </select>
        </div>

        <div class="form-group">
            <label>備註：</label>
            <textarea name="note" rows="2"><%= d.getNote() != null ? d.getNote() : "" %></textarea>
        </div>

        <button type="submit" class="btn-submit">儲存修改</button>
        <a href="delivery_list.jsp" class="back-link">返回出貨列表</a>
    </form>
    <% } %>
</div>
<%@ include file="../include/footer.jsp" %>