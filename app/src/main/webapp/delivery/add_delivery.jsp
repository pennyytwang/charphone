<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.DeliveryDao, util.NumberUtil, java.util.List, java.util.Map" %>
<% request.setAttribute("pageTitle", "新增出貨"); %>
<% request.setAttribute("pageIcon", "▶"); %>
<% request.setAttribute("pageSubtitle", "登錄一筆出貨"); %>
<%@ include file="../include/header.jsp" %>
<div class="form-container">
    <h2>新增出貨記錄</h2>

    <%
        String error = request.getParameter("error");
        if ("insufficient_stock".equals(error)) {
    %>
        <div class="error-msg">成品倉庫存不足，無法出貨。</div>
    <% } else if ("exceed_order_remaining".equals(error)) { %>
        <div class="error-msg">出貨數量超出訂單剩餘可出量。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請稍後再試。</div>
    <% } %>

    <form action="<%= request.getContextPath() %>/DeliveryServlet" method="POST">
        <div class="form-group">
            <label>選擇訂單：</label>
            <select name="orderId" id="orderId" required onchange="updateOrderInfo()">
                <option value="">-- 請選擇訂單 --</option>
                <%
                    DeliveryDao deliveryDao = new DeliveryDao();
                    List<Map<String, Object>> openOrders = deliveryDao.getOpenOrdersWithStock();
                    if (openOrders.isEmpty()) {
                %>
                    <option value="">-- 無可出貨訂單 --</option>
                <%
                    } else {
                        for (Map<String, Object> row : openOrders) {
                            int orderId = (Integer) row.get("id");
                            String orderNumber = (String) row.get("orderNumber");
                            String customerName = (String) row.get("customerName");
                            java.math.BigDecimal quantity = (java.math.BigDecimal) row.get("quantity");
                            java.math.BigDecimal totalDelivered = (java.math.BigDecimal) row.get("totalDelivered");
                            double remain = ((Number) row.get("remain")).doubleValue();
                            java.math.BigDecimal stockQty = (java.math.BigDecimal) row.get("stockQty");
                %>
                    <option value="<%= orderId %>"
                        data-order="<%= orderNumber %>"
                        data-customer="<%= customerName %>"
                        data-qty="<%= NumberUtil.fmtQty(quantity.doubleValue()) %>"
                        data-delivered="<%= NumberUtil.fmtQty(totalDelivered.doubleValue()) %>"
                        data-remain="<%= NumberUtil.fmtQty(remain) %>"
                        data-stock="<%= NumberUtil.fmtQty(stockQty.doubleValue()) %>">
                        <%= orderNumber %> - <%= customerName %> (未出貨量 <%= NumberUtil.fmtQty(remain) %>)
                    </option>
                <%
                        }
                    }
                %>
            </select>
        </div>

        <div id="orderInfo" class="order-info" style="display:none;">
            <span id="infoOrder"></span><br>
            <span id="infoRemain"></span>
            <span id="infoStock" style="display:block;margin-top:4px;color:#28a745;font-weight:600;"></span>
        </div>

        <div class="form-group">
            <label>出貨日期：</label>
            <input type="date" name="deliveryDate" id="deliveryDate" required>
        </div>

        <div class="form-group">
            <label>出貨數量：</label>
            <input type="number" name="quantity" id="quantity" step="any" required>
        </div>

        <input type="hidden" name="status" value="1">

        <div class="form-group">
            <label>備註：</label>
            <textarea name="note" rows="2" placeholder="出貨備註..."></textarea>
        </div>

        <button type="submit" class="btn-submit">確認出貨</button>
        <a href="delivery_list.jsp" class="back-link">返回出貨列表</a>
    </form>
</div>

<script>
function stripZeros(n) {
    var s = String(n);
    if (s.indexOf('.') !== -1) { s = s.replace(/0+$/, '').replace(/\.$/, ''); }
    return s;
}

function updateOrderInfo() {
    var sel = document.getElementById('orderId');
    var opt = sel.options[sel.selectedIndex];
    if (sel.value) {
        document.getElementById('infoOrder').textContent = '訂單：' + opt.getAttribute('data-order') + ' | 客戶：' + opt.getAttribute('data-customer');
        document.getElementById('infoRemain').textContent = '訂單總量：' + stripZeros(opt.getAttribute('data-qty')) + ' | 已出貨：' + stripZeros(opt.getAttribute('data-delivered')) + ' | 未出貨量：' + stripZeros(opt.getAttribute('data-remain'));
        document.getElementById('infoStock').textContent = '成品倉庫存：' + stripZeros(opt.getAttribute('data-stock'));
        document.getElementById('orderInfo').style.display = 'block';
    } else {
        document.getElementById('orderInfo').style.display = 'none';
    }
}

document.addEventListener('DOMContentLoaded', function() {
    var today = new Date();
    document.getElementById('deliveryDate').value = today.getFullYear() + '-' +
        String(today.getMonth()+1).padStart(2,'0') + '-' +
        String(today.getDate()).padStart(2,'0');

    var params = new URLSearchParams(window.location.search);
    var orderId = params.get('orderId');
    if (orderId) {
        var sel = document.getElementById('orderId');
        for (var i = 0; i < sel.options.length; i++) {
            if (sel.options[i].value === orderId) {
                sel.value = orderId;
                updateOrderInfo();
                break;
            }
        }
    }
});
</script>
<%@ include file="../include/footer.jsp" %>