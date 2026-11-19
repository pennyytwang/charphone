<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, dao.OrderDao, util.NumberUtil, model.Customer, model.Product" %>
<% request.setAttribute("pageTitle", "新增訂單"); %>
<% request.setAttribute("pageIcon", "☰"); %>
<% request.setAttribute("pageSubtitle", "建立新訂單"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>新增訂單</h2>

    <%
        OrderDao dao = new OrderDao();
        List<Customer> customers = dao.getCustomers();
        List<Product> products = dao.getProducts();
    %>

    <form id="orderForm" action="<%= request.getContextPath() %>/OrderServlet" method="POST">

        <div class="form-group">
            <label>客戶名稱：</label>
            <select name="customerId" id="customerId" required onchange="generateOrderNumber()">
                <option value="">-- 請選擇客戶 --</option>
                <% for(Customer c : customers) { %>
                    <option value="<%= c.getId() %>" data-customer-number="<%= c.getCustomerNumber() != null ? c.getCustomerNumber() : String.valueOf(c.getId()) %>"><%= c.getCustomerName() %></option>
                <% } %>
            </select>
        </div>

        <div class="form-group">
            <label>訂單編號 (依客戶編號-日期西洋年月-流水號3碼)：</label>
            <input type="text" name="orderNumber" id="orderNumber" readonly placeholder="選擇客戶後自動產生">
        </div>

        <div class="form-group">
            <label>品項：</label>
            <select name="productId" id="productId" required onchange="fillProductInfo()">
                <option value="">-- 請選擇品項 --</option>
                <% for(Product p : products) { %>
                    <option value="<%= p.getId() %>"
                        data-ptype="<%= p.getPriceType() %>"
                        data-price="<%= p.getUnitPrice() != null ? NumberUtil.fmtQty(p.getUnitPrice().doubleValue()) : "" %>"
                        data-weight="<%= p.getUnitWeight() != null ? NumberUtil.fmtQty(p.getUnitWeight().doubleValue()) : "" %>">
                        <%= p.getProductName() %> <%= p.getProductCode() != null ? "(" + p.getProductCode() + ")" : "" %>
                    </option>
                <% } %>
            </select>
        </div>

        <div class="form-group">
            <label>計價方式：</label>
            <select name="priceType" id="priceType" onchange="updateLabels(); calcTotal();">
                <option value="1">按重量 (kg)</option>
                <option value="2">按個數 (pcs)</option>
            </select>
        </div>

        <div class="row-2">
            <div class="form-group">
                <span style="display:inline-flex;align-items:center;gap:4px;">
                    <label id="weightLabel" style="margin-bottom:0;">單個重量 (kg)：</label>
                    <button type="button" onclick="toggleWeightEdit()" class="btn-toggle" title="切換為可修改">✎</button>
                </span>
                <input type="text" name="unitWeight" id="unitWeight" readonly placeholder="選擇品項後自動帶入" onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="calcTotal()">
            </div>
            <div class="form-group">
                <span style="display:inline-flex;align-items:center;gap:4px;">
                    <label id="unitLabel" style="margin-bottom:0;">代工單價 (/kg)：</label>
                    <button type="button" onclick="togglePriceEdit()" class="btn-toggle" title="切換為可修改">✎</button>
                </span>
                <input type="text" name="unitPrice" id="unitPrice" readonly placeholder="選擇品項後自動帶入" onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="calcTotal()">
            </div>
        </div>

        <div class="form-group">
            <label>客戶下單量 (單位依計價方式決定為 pcs 或 kg)：</label>
            <input type="text" name="quantity" id="quantity" placeholder="請輸入數量" required onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="calcTotal()">
        </div>

        <div class="form-group">
            <label>預計應收金額：</label>
            <input type="text" id="totalAmountDisplay" readonly value="$0">
            <input type="hidden" name="totalAmount" id="totalAmount" value="0">
        </div>

        <div class="form-group">
            <label>實際應收金額：</label>
            <input type="text" name="actualAmount" id="actualAmount" inputmode="decimal" placeholder="如有差異請填寫實際金額" onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="checkAmountDiff()">
        </div>

        <div class="form-group" id="diffReasonGroup" style="display:none;">
            <label>金額差異原因：</label>
            <textarea name="amountDiffReason" id="amountDiffReason" rows="2" placeholder="請說明差異原因"></textarea>
        </div>

        <div class="form-group">
            <label>交期：</label>
            <input type="date" name="expectedDeliveryDate" id="expectedDeliveryDate">
        </div>

        <input type="hidden" name="orderDate" id="orderDate">
        <input type="hidden" name="deliveryDate" id="deliveryDate" value="">

        <div class="form-group">
            <label>備註：
                <button type="button" id="noteToggleBtn" onclick="toggleNote()" class="btn-toggle">+</button>
            </label>
            <textarea name="note" id="noteTextarea" rows="3" style="display:none;"></textarea>
        </div>

        <button type="button" onclick="confirmSubmit()" class="btn-submit" id="submitBtn">新增</button>
        <a href="order_list.jsp" class="back-link">返回訂單列表</a>
    </form>
</div>

<script>
function formatAmountField(el) {
    var v = el.value.replace(/[^0-9.\-]/g, '');
    if (v && !isNaN(parseFloat(v))) el.value = fmtQtyDisplay(v);
}
function parseAmountField(el) {
    el.value = el.value.replace(/[^0-9.\-]/g, '');
}
function generateOrderNumber() {
    var sel = document.getElementById('customerId');
    var opt = sel.options[sel.selectedIndex];
    var today = new Date();
    var yymm = today.getFullYear() + '' + String(today.getMonth()+1).padStart(2,'0');
    if (sel.value) {
        var cnum = opt.getAttribute('data-customer-number');
        document.getElementById('orderNumber').value = cnum + '-' + yymm + '-001';
    } else {
        document.getElementById('orderNumber').value = '';
    }
}

function fillProductInfo() {
    var sel = document.getElementById('productId');
    var opt = sel.options[sel.selectedIndex];
    var ptype = opt.getAttribute('data-ptype');
    var price = opt.getAttribute('data-price');
    var weight = opt.getAttribute('data-weight');

        if (ptype) {
            document.getElementById('priceType').value = ptype;
            if (price) document.getElementById('unitPrice').value = fmtQtyDisplay(price);
            if (weight) document.getElementById('unitWeight').value = fmtQtyDisplay(weight);
            updateLabels();
            calcTotal();
        }
}

function updateLabels() {
    var ptype = document.getElementById('priceType').value;
    document.getElementById('unitLabel').textContent = ptype === '1' ? '代工單價 (/kg)：' : '單價 (/pcs)：';
    document.getElementById('weightLabel').textContent = '單個重量 (kg)：';
}

function calcTotal() {
    var ptype = parseInt(document.getElementById('priceType').value) || 1;
    var qty = parseNumber(document.getElementById('quantity').value);
    var price = parseNumber(document.getElementById('unitPrice').value);
    var total = qty * price;
    document.getElementById('totalAmountDisplay').value = total > 0 ? fmtMoney(total) : '$0';
    document.getElementById('totalAmount').value = total.toFixed(2);
    document.getElementById('actualAmount').value = total > 0 ? fmtQtyDisplay(total) : '';
}

function checkAmountDiff() {
    var expected = parseFloat(document.getElementById('totalAmount').value) || 0;
    var actual = parseFloat(document.getElementById('actualAmount').value.replace(/[^0-9.\-]/g, ''));
    document.getElementById('diffReasonGroup').style.display = (actual && Math.abs(actual - expected) > 0.01) ? 'block' : 'none';
}

function toggleNote() {
    var ta = document.getElementById('noteTextarea');
    var btn = document.getElementById('noteToggleBtn');
    if (ta.style.display === 'none') {
        ta.style.display = 'block';
        btn.textContent = '-';
    } else {
        ta.style.display = 'none';
        btn.textContent = '+';
    }
}

function toggleWeightEdit() {
    var el = document.getElementById('unitWeight');
    if (el.hasAttribute('readonly')) { el.removeAttribute('readonly'); el.focus(); }
    else { el.setAttribute('readonly', true); }
}

function togglePriceEdit() {
    var el = document.getElementById('unitPrice');
    if (el.hasAttribute('readonly')) { el.removeAttribute('readonly'); el.focus(); }
    else { el.setAttribute('readonly', true); }
}

document.addEventListener('DOMContentLoaded', function() {
    var today = new Date();
    var dateStr = today.getFullYear() + '-' + 
        String(today.getMonth()+1).padStart(2,'0') + '-' + 
        String(today.getDate()).padStart(2,'0');
    document.getElementById('orderDate').value = dateStr;
    var exp = new Date(today.getTime() + 14 * 24 * 60 * 60 * 1000);
    document.getElementById('expectedDeliveryDate').value = exp.getFullYear() + '-' +
        String(exp.getMonth()+1).padStart(2,'0') + '-' +
        String(exp.getDate()).padStart(2,'0');
});

function confirmSubmit() {
    var form = document.getElementById('orderForm');
    var custSel = document.getElementById('customerId');
    var prodSel = document.getElementById('productId');
    if (!custSel.value) { alert('請選擇客戶'); return; }
    if (!prodSel.value) { alert('請選擇品項'); return; }
    if (!document.getElementById('quantity').value || parseFloat(document.getElementById('quantity').value) <= 0) { alert('請填寫有效數量'); return; }

    var custName = custSel.options[custSel.selectedIndex] ? custSel.options[custSel.selectedIndex].text : '';
    var prodName = prodSel.options[prodSel.selectedIndex] ? prodSel.options[prodSel.selectedIndex].text : '';
    var qty = document.getElementById('quantity').value || '0';
    var priceType = document.getElementById('priceType').value === '1' ? '按重量(kg)' : '按個數(pcs)';
    var totalAmt = parseFloat(document.getElementById('totalAmount').value) || 0;
    var actualVal = document.getElementById('actualAmount').value;
    var actualAmt = actualVal ? parseNumber(actualVal) : totalAmt;
    var expDate = document.getElementById('expectedDeliveryDate').value || '-';
    var orderNum = document.getElementById('orderNumber').value || '待產生';

    var html = '<div id="confirmOverlay" style="position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:10000;display:flex;align-items:center;justify-content:center;">'
        + '<div class="dialog-box">'
        + '<h3 style="margin:0 0 20px;font-size:18px;color:#1a1a2e;border-bottom:2px solid #e9ecef;padding-bottom:12px;">確認新增訂單</h3>'
        + '<table style="width:100%;font-size:14px;border-collapse:collapse;">'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">訂單編號</td><td style="padding:6px 0;font-weight:600;">' + orderNum + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">客戶名稱</td><td style="padding:6px 0;font-weight:600;">' + custName + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">品項</td><td style="padding:6px 0;font-weight:600;">' + prodName + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">計價方式</td><td style="padding:6px 0;">' + priceType + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">數量</td><td style="padding:6px 0;">' + qty + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">預計應收</td><td style="padding:6px 0;font-weight:600;">' + fmtMoney(totalAmt) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">實際應收</td><td style="padding:6px 0;font-weight:600;">' + fmtMoney(actualAmt) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">預計交期</td><td style="padding:6px 0;">' + expDate + '</td></tr>'
        + '</table>'
        + '<div style="display:flex;justify-content:flex-end;gap:10px;margin-top:24px;">'
        + '<button onclick="document.getElementById(\'confirmOverlay\').remove()" style="padding:8px 24px;border:1px solid #6c757d;background:#fff;border-radius:6px;cursor:pointer;font-size:14px;">取消</button>'
        + '<button id="confirmOkBtn" style="padding:8px 24px;border:none;background:#4a6cf7;color:#fff;border-radius:6px;cursor:pointer;font-size:14px;">確認</button>'
        + '</div></div></div>';

    var overlay = document.createElement('div');
    overlay.innerHTML = html;
    document.body.appendChild(overlay.firstChild);

    document.getElementById('confirmOkBtn').onclick = function() {
        document.getElementById('confirmOverlay').remove();
        doAjaxSubmit();
    };
}

function doAjaxSubmit() {
    var form = document.getElementById('orderForm');
    var btn = document.getElementById('submitBtn');
    btn.disabled = true;

    var rawVals = {};
    ['quantity','unitPrice','unitWeight','actualAmount'].forEach(function(id) {
        var el = document.getElementById(id);
        if (el) { rawVals[id] = el.value; el.value = el.value.replace(/[^0-9.\-]/g, ''); }
    });
    var formData = new FormData(form);
    Object.keys(rawVals).forEach(function(id) { document.getElementById(id).value = rawVals[id]; });

    fetch(form.action, {
        method: 'POST',
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        body: formData
    })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.success) {
            showToast('訂單已新增！', 'success');
            form.reset();
            document.getElementById('totalAmountDisplay').value = '$0';
            document.getElementById('totalAmount').value = '0';
            document.getElementById('diffReasonGroup').style.display = 'none';
            document.getElementById('orderNumber').value = '';
            var today = new Date();
            var ds = today.getFullYear() + '-' + String(today.getMonth()+1).padStart(2,'0') + '-' + String(today.getDate()).padStart(2,'0');
            document.getElementById('orderDate').value = ds;
            var exp = new Date(today.getTime() + 14 * 24 * 60 * 60 * 1000);
            document.getElementById('expectedDeliveryDate').value = exp.getFullYear() + '-' + String(exp.getMonth()+1).padStart(2,'0') + '-' + String(exp.getDate()).padStart(2,'0');
            var noteTa = document.getElementById('noteTextarea');
            noteTa.style.display = 'none';
            document.getElementById('noteToggleBtn').textContent = '+';
            btn.disabled = false;
        } else {
            showToast(data.error || '新增失敗', 'error');
            btn.disabled = false;
        }
    })
    .catch(function() {
        showToast('系統錯誤，請稍後再試', 'error');
        btn.disabled = false;
    });
}
</script>

<%@ include file="../include/footer.jsp" %>
