<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.text.SimpleDateFormat, java.util.Map, dao.OrderDao" %>
<% request.setAttribute("pageTitle", "開立工單"); %>
<% request.setAttribute("pageIcon", "⚙"); %>
<% request.setAttribute("pageSubtitle", "為訂單建立生產工單"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container" style="max-width:620px;">
    <h2>開立工單</h2>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">資料庫寫入失敗，請稍後再試。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請檢查輸入資料格式。</div>
    <% } %>

    <form action="<%= request.getContextPath() %>/ProductionServlet" method="POST">

        <div class="form-group">
            <label>選擇來源訂單：</label>
            <select name="orderId" id="orderId" required onchange="loadOrder()">
                <option value="">-- 請選擇訂單 --</option>
                <%
                    OrderDao orderDao = new OrderDao();
                    SimpleDateFormat sdfOpt = new SimpleDateFormat("yyyy-MM-dd");
                    try {
                        for (Map<String, Object> row : orderDao.getOpenOrdersForProduction()) {
                            java.util.Date expDate = (java.util.Date) row.get("expectedDeliveryDate");
                            String expDateStr = expDate != null ? sdfOpt.format(expDate) : "";
                            int oid = (Integer) row.get("id");
                            String onum = (String) row.get("orderNumber");
                            String cname = (String) row.get("customerName");
                %>
                    <option value="<%= oid %>"
                        data-customer="<%= cname != null ? cname : "" %>"
                        data-order="<%= onum != null ? onum : "" %>"
                        data-expdelivery="<%= expDateStr %>">
                        <%= onum %> - <%= cname %>
                    </option>
                <%
                        }
                    } catch (Exception e) {
                        out.println("<option value=''>載入失敗：" + e.getMessage() + "</option>");
                    }
                %>
            </select>
        </div>

        <%-- ═══ 訂單參考資訊 ═══ --%>
        <div id="orderRefSection" style="display:none;background:#f0f7ff;border:1px solid #b3d4fc;border-radius:8px;padding:14px 18px;margin-bottom:20px;">
            <div style="font-weight:600;color:#1565c0;margin-bottom:8px;font-size:13px;">📋 訂單資訊</div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;font-size:13px;">
                <div><span style="color:#6c757d;">客戶：</span><span id="refCustomer" style="font-weight:600;">-</span></div>
                <div><span style="color:#6c757d;">訂單編號：</span><span id="refOrderNumber" style="font-weight:600;">-</span></div>
                <div><span style="color:#6c757d;">訂單總量：</span><span id="refQty" style="font-weight:600;">-</span></div>
                <div><span style="color:#6c757d;">已生產量：</span><span id="refManufactured" style="font-weight:600;">-</span></div>
                <div><span style="color:#6c757d;">剩餘待產：</span><span id="refRemaining" style="font-weight:600;color:#d32f2f;">-</span></div>
                <div><span style="color:#6c757d;">預計交期：</span><span id="refDelivery" style="font-weight:600;">-</span></div>
            </div>
        </div>

        <%-- ═══ 品項資訊（唯讀） ═══ --%>
        <div class="row-2">
            <div class="form-group">
                <label>品項：</label>
                <select name="productId" id="productId" required>
                    <option value="">-- 先選訂單 --</option>
                </select>
            </div>
            <div class="form-group">
                <label>計價方式：</label>
                <input type="text" id="priceTypeDisplay" readonly>
                <input type="hidden" name="priceType" id="priceType">
            </div>
        </div>
        <div class="row-2">
            <div class="form-group">
                <label>代工單價：</label>
                <input type="text" id="unitPriceDisplay" readonly>
                <input type="hidden" name="unitPrice" id="unitPrice">
            </div>
            <div class="form-group">
                <label>單個重量 (kg)：</label>
                <input type="text" id="unitWeightDisplay" readonly>
                <input type="hidden" name="unitWeight" id="unitWeight">
            </div>
        </div>

        <%-- ═══ 預計生產 ═══ --%>
        <div style="border:2px solid #e3f2fd;border-radius:10px;padding:16px 18px;margin-bottom:16px;background:#fafcff;">
            <div style="font-weight:600;color:#1565c0;margin-bottom:12px;font-size:14px;">📝 預計生產</div>
            <div class="row-2">
                <div class="form-group">
                    <label>訂單總數量：</label>
                    <input type="number" name="quantity" id="quantity" step="any" readonly>
                </div>
                <div class="form-group">
                    <label>本工單預計生產量：</label>
                    <input type="number" name="producedQty" id="producedQty" step="any" required>
                    <span id="remainingHint" style="font-size:12px;color:#6c757d;display:block;margin-top:3px;"></span>
                </div>
            </div>
            <div class="row-2">
                <div class="form-group">
                    <label>預計開始日：</label>
                    <input type="date" name="startDate" id="startDate">
                </div>
                <div class="form-group">
                    <label>預計完成日：</label>
                    <input type="date" name="targetDate">
                </div>
            </div>
        </div>

        <%-- ═══ 實際生產（開立時為初始值） ═══ --%>
        <div style="border:2px solid #e8f5e9;border-radius:10px;padding:16px 18px;margin-bottom:16px;background:#fafffa;">
            <div style="font-weight:600;color:#2e7d32;margin-bottom:12px;font-size:14px;">🏭 實際生產</div>
            <div class="form-group">
                <label>已製造數量：</label>
                <input type="number" name="manufacturedQty" id="manufacturedQty" step="any" value="0" readonly style="background:#f0f0f0;color:#999;cursor:not-allowed;">
                <span style="font-size:12px;color:#6c757d;display:block;margin-top:3px;">開立工單時為 0，實際生產後再更新</span>
            </div>
        </div>

        <input type="hidden" name="status" value="0">

        <div class="form-group">
            <label>備註：</label>
            <textarea name="note" rows="2" placeholder="生產注意事項..."></textarea>
        </div>

        <button type="submit" class="btn-submit">確認開立工單</button>
        <a href="production_list.jsp" class="back-link">返回生產列表</a>
    </form>
</div>

<script>
var orderDataCache = {};

function loadOrder() {
    var sel = document.getElementById('orderId');
    var opt = sel.options[sel.selectedIndex];
    var cid = sel.value;

    if (!cid) {
        document.getElementById('orderRefSection').style.display = 'none';
        document.getElementById('productId').innerHTML = '<option value="">-- 先選訂單 --</option>';
        return;
    }

    document.getElementById('refCustomer').textContent = opt.getAttribute('data-customer') || '-';
    document.getElementById('refOrderNumber').textContent = opt.getAttribute('data-order') || '-';
    document.getElementById('refDelivery').textContent = opt.getAttribute('data-expdelivery') || '未設定';
    document.getElementById('orderRefSection').style.display = 'block';

    var xhr = new XMLHttpRequest();
    xhr.open('GET', '../order/order_data.jsp?id=' + cid, false);
    try { xhr.send(); } catch(e) {}
    if (xhr.status === 200) {
        try {
            var data = JSON.parse(xhr.responseText);
            orderDataCache = data[0] || {};
            var selP = document.getElementById('productId');
            selP.innerHTML = '';
            for (var i = 0; i < data.length; i++) {
                var o = data[i];
                var opt2 = document.createElement('option');
                opt2.value = o.product_id;
                opt2.text = o.product_name;
                opt2.setAttribute('data-ptype', o.price_type);
                opt2.setAttribute('data-price', o.unit_price || '');
                opt2.setAttribute('data-weight', o.unit_weight || '');
                opt2.setAttribute('data-qty', o.quantity);
                opt2.setAttribute('data-manufactured', o.total_manufactured || '0');
                selP.appendChild(opt2);
            }
            if (data.length > 0) fillProductInfo();
        } catch(e) {}
    }
}

function fillProductInfo() {
    var sel = document.getElementById('productId');
    var opt = sel.options[sel.selectedIndex];
    if (!opt) return;
    var ptype = opt.getAttribute('data-ptype');
    var price = opt.getAttribute('data-price');
    var weight = opt.getAttribute('data-weight');
    var qty = parseFloat(opt.getAttribute('data-qty')) || 0;
    var manufactured = parseFloat(opt.getAttribute('data-manufactured')) || 0;

    document.getElementById('priceTypeDisplay').value = ptype === '1' ? '按重量 (kg)' : '按個數 (pcs)';
    document.getElementById('priceType').value = ptype;
    document.getElementById('unitPrice').value = price || '';
    document.getElementById('unitPriceDisplay').value = price || '';
    document.getElementById('unitWeight').value = weight || '';
    document.getElementById('unitWeightDisplay').value = weight || '';

    var unit = ptype === '1' ? 'kg' : 'pcs';
    document.getElementById('refQty').textContent = qty + ' ' + unit;
    document.getElementById('refManufactured').textContent = manufactured + ' ' + unit;
    var remaining = Math.max(qty - manufactured, 0);
    document.getElementById('refRemaining').textContent = remaining + ' ' + unit;
    document.getElementById('quantity').value = qty || '';
    document.getElementById('producedQty').value = remaining || '';
    document.getElementById('remainingHint').textContent = '訂單剩餘 ' + remaining + ' ' + unit + '，此工單預計生產全部剩餘量';
    document.getElementById('manufacturedQty').value = '0';
}

document.addEventListener('DOMContentLoaded', function() {
    var today = new Date();
    document.getElementById('startDate').value = today.getFullYear() + '-' +
        String(today.getMonth()+1).padStart(2,'0') + '-' +
        String(today.getDate()).padStart(2,'0');

    var params = new URLSearchParams(window.location.search);
    var orderId = params.get('orderId');
    if (orderId) {
        var sel = document.getElementById('orderId');
        for (var i = 0; i < sel.options.length; i++) {
            if (sel.options[i].value === orderId) {
                sel.value = orderId;
                loadOrder();
                break;
            }
        }
    }
});
</script>

<%@ include file="../include/footer.jsp" %>
