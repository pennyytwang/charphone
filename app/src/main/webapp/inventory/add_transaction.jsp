<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.WarehouseDao, dao.InventoryItemDao, model.Warehouse, model.InventoryItem, java.util.List" %>
<% request.setAttribute("pageTitle", "入庫/出庫作業"); %>
<% request.setAttribute("pageIcon", "▣"); %>
<% request.setAttribute("pageSubtitle", "登錄庫存異動"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>入庫 / 出庫作業</h2>

    <div class="info-box">入庫輸入正數，出庫輸入正數（系統自動轉為負數扣減庫存）</div>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">庫存異動寫入失敗。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請檢查輸入資料格式。</div>
    <% } %>

    <form action="<%= request.getContextPath() %>/InventoryTransactionServlet" method="POST">

        <div class="form-group">
            <label>交易類型：</label>
            <select name="transactionType" id="transactionType">
                <option value="1">入庫</option>
                <option value="2">出庫</option>
                <option value="5">盤盈</option>
                <option value="6">盤虧</option>
            </select>
        </div>

        <div class="form-group">
            <label>倉庫：</label>
            <select name="warehouseId" required>
                <option value="">-- 請選擇倉庫 --</option>
                <%
                    try {
                        WarehouseDao wdao = new WarehouseDao();
                        List<Warehouse> warehouses = wdao.getAllWarehouses();
                        for (Warehouse w : warehouses) {
                            if (w.getStatus() == 1) {
                %>
                    <option value="<%= w.getId() %>"><%= w.getWarehouseName() %></option>
                <%
                            }
                        }
                    } catch (Exception e) {}
                %>
            </select>
        </div>

        <div class="form-group">
            <label>庫存品項：</label>
            <select name="itemId" required>
                <option value="">-- 請選擇品項 --</option>
                <%
                    try {
                        InventoryItemDao idao = new InventoryItemDao();
                        List<InventoryItem> items = idao.getAllItems(null);
                        for (InventoryItem item : items) {
                            if (item.getStatus() == 1) {
                %>
                    <option value="<%= item.getId() %>">[<%= item.getItemCode() %>] <%= item.getItemName() %></option>
                <%
                            }
                        }
                    } catch (Exception e) {}
                %>
            </select>
        </div>

        <div class="form-group">
            <label>數量：</label>
            <input type="number" name="quantity" step="any" placeholder="請輸入正數" required>
        </div>

        <div class="form-group">
            <label>備註：</label>
            <textarea name="note" rows="3" placeholder="異動原因..."></textarea>
        </div>

        <button type="submit" class="btn-submit" id="submitBtn">確認送出</button>
        <a href="inventory_list.jsp" class="back-link">返回庫存總覽</a>
    </form>
</div>

<script src="${pageContext.request.contextPath}/js/common.js"></script>
<script>
    document.getElementById('transactionType').addEventListener('change', function() {
        var btn = document.getElementById('submitBtn');
        if (this.value == '1' || this.value == '5') {
            btn.textContent = '確認入庫';
            btn.style.background = '#28a745';
        } else {
            btn.textContent = '確認出庫';
            btn.style.background = '#dc3545';
        }
    });
</script>

<%@ include file="../include/footer.jsp" %>
