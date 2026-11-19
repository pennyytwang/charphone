<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, dao.OrderDao, model.Customer" %>
<% request.setAttribute("pageTitle", "新增訂單"); %>
<% request.setAttribute("pageIcon", "☰"); %>
<% request.setAttribute("pageSubtitle", "建立新訂單"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>📋 新增訂單</h2>
    <form action="<%= request.getContextPath() %>/OrderServlet" method="POST">
        
        <div class="form-group">
            <label>選擇客戶：</label>
            <select name="customerId" required>
                <option value="">-- 請選擇客戶 --</option>
                <%
                    try {
                        OrderDao dao = new OrderDao();
                        List<Customer> customers = dao.getCustomers();
                        for(Customer c : customers) {
                %>
                            <option value="<%= c.getId() %>"><%= c.getCustomerName() %></option>
                <% 
                        }
                    } catch (Exception e) {
                        out.println("<option value=''>錯誤：" + e.getMessage() + "</option>");
                    }
                %>
            </select>
        </div>

        <div class="form-group">
            <label>訂單編號：</label>
            <input type="text" name="orderNumber" placeholder="例如: ORD-2026-001" required>
        </div>

        <div class="form-group">
            <label>下單日期：</label>
            <input type="date" name="orderDate" required>
        </div>

        <div class="form-group">
            <label>預計交期：</label>
            <input type="date" name="deliveryDate">
        </div>

        <div class="form-group">
            <label>訂單總金額：</label>
            <input type="number" name="totalAmount" step="any" placeholder="0.00" required>
        </div>

        <div class="form-group">
            <label>備註事項：</label>
            <textarea name="note" rows="3" placeholder="廠內生產注意事項..."></textarea>
        </div>

        <button type="submit" class="btn-submit">✅ 確認存檔並送出</button>
        <a href="invoice_list.jsp" class="back-link">← 返回清單</a>
    </form>
</div>

<%@ include file="../include/footer.jsp" %>
