<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.math.*, java.text.SimpleDateFormat, util.NumberUtil, dao.OrderDao, dao.DeliveryDao, dao.InvoiceDao, model.Order" %>
<% request.setAttribute("pageTitle", "新增應收帳款"); %>
<% request.setAttribute("pageIcon", "$"); %>
<% request.setAttribute("pageSubtitle", "開立應收帳單"); %>
<%@ include file="../include/header.jsp" %>
<div class="form-container">
    <h2>新增應收帳款</h2>

    <script>
    (function() {
        var p = new URLSearchParams(window.location.search);
        var err = p.get('error');
        var text = null;
        if (err === 'failed') { text = '資料庫寫入失敗，請稍後再試。'; }
        else if (err === 'exception') { text = '系統錯誤，請檢查輸入資料格式。'; }
        else if (err === 'duplicate') { text = '此訂單已建立過應收帳款，請勿重複結帳。'; }
        else if (err === 'over_amount') { text = '此訂單的應收金額已超過或等於訂單總額，無法再新增應收帳款。'; }
        if (text) {
            var toast = document.createElement('div');
            toast.style.cssText = 'position:fixed;top:20px;right:20px;z-index:10002;padding:14px 24px;border-radius:8px;font-size:14px;font-weight:600;color:#fff;background:#dc3545;box-shadow:0 4px 16px rgba(0,0,0,0.2);opacity:0;transition:opacity 0.3s;';
            toast.textContent = text;
            document.body.appendChild(toast);
            requestAnimationFrame(function() { toast.style.opacity = '1'; });
            setTimeout(function() { toast.style.opacity = '0'; setTimeout(function() { toast.remove(); }, 300); }, 2500);
            window.history.replaceState({}, '', window.location.pathname + '?orderId=' + p.get('orderId'));
        }
    })();
    </script>

    <%
        String orderIdParam = request.getParameter("orderId");
        boolean hasOrder = orderIdParam != null && !orderIdParam.isEmpty();
        int orderIdVal = 0;
        String orderNumber = "", customerName = "", productName = "";
        BigDecimal orderQty = BigDecimal.ZERO, unitPrice = BigDecimal.ZERO, actualAmount = BigDecimal.ZERO;
        int priceType = 0;
        java.util.Date orderDate = null, expectedDeliveryDate = null;
        BigDecimal deliveredQty = BigDecimal.ZERO;
        java.util.Date lastDeliveryDate = null;
        BigDecimal remaining = BigDecimal.ZERO;
        int customerIdVal = 0;

        BigDecimal invoicedTotal = BigDecimal.ZERO;
        BigDecimal paidTotal = BigDecimal.ZERO;
        int invoiceCount = 0;
        int paidCount = 0;

        if (hasOrder) {
            orderIdVal = Integer.parseInt(orderIdParam);
            try {
                OrderDao orderDao = new OrderDao();
                model.Order o = orderDao.getOrderById(orderIdVal);
                if (o != null) {
                    orderNumber = o.getOrderNumber() != null ? o.getOrderNumber() : "-";
                    customerName = o.getCustomerName() != null ? o.getCustomerName() : "-";
                    productName = o.getProductName() != null ? o.getProductName() : "-";
                    orderQty = o.getQuantity();
                    unitPrice = o.getUnitPrice();
                    priceType = o.getPriceType();
                    orderDate = o.getOrderDate();
                    expectedDeliveryDate = o.getExpectedDeliveryDate();
                    customerIdVal = o.getCustomerId();
                    actualAmount = o.getActualAmount() != null ? o.getActualAmount() : o.getTotalAmount();
                }

                DeliveryDao deliveryDao = new DeliveryDao();
                Object[] delivInfo = deliveryDao.getDeliverySummaryByOrderId(orderIdVal);
                deliveredQty = (BigDecimal) delivInfo[0];
                lastDeliveryDate = (java.util.Date) delivInfo[1];

                InvoiceDao invoiceDao = new InvoiceDao();
                Object[] invInfo = invoiceDao.getInvoiceSummaryByOrderId(orderIdVal);
                invoicedTotal = (BigDecimal) invInfo[0];
                paidTotal = (BigDecimal) invInfo[1];
                invoiceCount = (int) invInfo[2];
                paidCount = (int) invInfo[3];

                remaining = actualAmount.subtract(invoicedTotal);
                if (remaining.compareTo(BigDecimal.ZERO) < 0) remaining = BigDecimal.ZERO;
            } catch (Exception e) {
                out.println("<div class='error-msg'>載入訂單資料失敗：" + e.getMessage() + "</div>");
            }
        }
    %>

    <form id="invoiceForm" action="<%= request.getContextPath() %>/InvoiceServlet" method="POST">
        <input type="hidden" name="orderId" id="orderId" value="<%= hasOrder ? orderIdVal : "" %>">
        <input type="hidden" name="customerId" id="customerId" value="<%= hasOrder ? customerIdVal : "" %>">

        <% if (hasOrder) { %>
        <div class="form-section">
            <div class="order-quick-info">
                <div class="quick-item">
                    <span class="quick-label">訂單編號</span>
                    <span class="quick-value"><%= orderNumber %></span>
                </div>
                <div class="quick-item">
                    <span class="quick-label">客戶</span>
                    <span class="quick-value"><%= customerName %></span>
                </div>
                <div class="quick-item">
                    <span class="quick-label">實際應收</span>
                    <span class="quick-value amount">$<%= NumberUtil.fmtMoney(actualAmount) %></span>
                </div>
            </div>
            <div class="toggle-detail" id="toggleDetail" onclick="toggleOrderDetail()">
                <span id="toggleIcon">&#9654;</span> 訂單詳細資訊
            </div>
            <div class="order-detail" id="orderDetail">
                <div class="detail-grid">
                    <div class="detail-item">
                        <span class="detail-label">品項</span>
                        <span class="detail-value"><%= productName %></span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">數量</span>
                        <span class="detail-value"><%= NumberUtil.fmtQty(orderQty.doubleValue()) %> <%= priceType == 1 ? "kg" : "pcs" %></span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">單價</span>
                        <span class="detail-value">$<%= NumberUtil.fmtMoney(unitPrice) %>/<%= priceType == 1 ? "kg" : "pcs" %></span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">下單日期</span>
                        <span class="detail-value"><%= orderDate != null ? new SimpleDateFormat("yyyy-MM-dd").format(orderDate) : "-" %></span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">預計交期</span>
                        <span class="detail-value"><%= expectedDeliveryDate != null ? new SimpleDateFormat("yyyy-MM-dd").format(expectedDeliveryDate) : "-" %></span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">出貨數量</span>
                        <span class="detail-value"><%= NumberUtil.fmtQty(deliveredQty.doubleValue()) %> <%= priceType == 1 ? "kg" : "pcs" %></span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">出貨日期</span>
                        <span class="detail-value"><%= lastDeliveryDate != null ? new SimpleDateFormat("yyyy-MM-dd").format(lastDeliveryDate) : "尚未出貨" %></span>
                    </div>
                </div>
            </div>
        </div>

        <div class="form-section">
            <h3 class="form-section-title toggle-section" onclick="togglePaymentDetail()">
                <span id="payToggleIcon">&#9654;</span> 收款狀況
            </h3>
            <div id="paymentDetail" style="display:none;">
            <% if (invoiceCount == 0) { %>
                <div class="payment-status-empty">尚未進行</div>
            <% } else {
                BigDecimal unpaidTotal = actualAmount.subtract(paidTotal);
                if (unpaidTotal.compareTo(BigDecimal.ZERO) < 0) unpaidTotal = BigDecimal.ZERO;
                BigDecimal toInvoice = actualAmount.subtract(invoicedTotal);
                if (toInvoice.compareTo(BigDecimal.ZERO) < 0) toInvoice = BigDecimal.ZERO;
                boolean allPaid = paidTotal.compareTo(actualAmount) >= 0;
                boolean allInvoiced = invoicedTotal.compareTo(actualAmount) >= 0;
            %>
                <div class="payment-summary">
                    <div class="pay-row">
                        <span class="pay-label">已開帳</span>
                        <span class="pay-value pay-link" onclick="openInvoiceDetail()"><%= invoiceCount %> 筆 / $<%= NumberUtil.fmtMoney(invoicedTotal) %></span>
                    </div>
                    <div class="pay-row">
                        <span class="pay-label">已收款</span>
                        <span class="pay-value pay-green"><%= paidCount %> 筆 / $<%= NumberUtil.fmtMoney(paidTotal) %></span>
                    </div>
                    <div class="pay-row">
                        <span class="pay-label">未收款</span>
                        <span class="pay-value pay-red">$<%= NumberUtil.fmtMoney(unpaidTotal) %></span>
                    </div>
                    <div class="pay-row">
                        <span class="pay-label">待開帳</span>
                        <span class="pay-value"><%= toInvoice.compareTo(BigDecimal.ZERO) > 0 ? "$" + NumberUtil.fmtMoney(toInvoice) : "已全額開帳" %></span>
                    </div>
                </div>
                <div class="payment-progress">
                    <div class="progress-bar">
                        <div class="progress-invoiced" style="width: <%= actualAmount.compareTo(BigDecimal.ZERO) > 0 ? Math.min(100, invoicedTotal.multiply(new BigDecimal(100)).divide(actualAmount, 0, RoundingMode.HALF_UP).intValue()) : 0 %>%"></div>
                        <div class="progress-paid" style="width: <%= actualAmount.compareTo(BigDecimal.ZERO) > 0 ? Math.min(100, paidTotal.multiply(new BigDecimal(100)).divide(actualAmount, 0, RoundingMode.HALF_UP).intValue()) : 0 %>%"></div>
                    </div>
                </div>
                <% if (allPaid && allInvoiced) { %>
                    <div class="payment-done">收款完成</div>
                <% } else if (allInvoiced) { %>
                    <div class="payment-waiting">等待收款中</div>
                <% } else { %>
                    <div class="payment-waiting">開帳未完成，尚可開 $<%= NumberUtil.fmtMoney(toInvoice) %></div>
                <% } %>
            <% } %>
            </div>
        </div>

        <% } else { %>
        <div class="form-section">
            <h3 class="form-section-title">選擇訂單</h3>
            <div class="form-group">
                <select name="orderId" id="orderSelect" required onchange="loadOrderInfo()">
                    <option value="">-- 請選擇訂單 --</option>
                    <%
                        try {
                            OrderDao orderDao = new OrderDao();
                            for (Order o : orderDao.getOpenOrdersWithInvoicedSum()) {
                                BigDecimal amt = o.getActualAmount() != null ? o.getActualAmount() : o.getTotalAmount();
                                BigDecimal invoiced = o.getInvoicedSum() != null ? o.getInvoicedSum() : BigDecimal.ZERO;
                                BigDecimal rem = amt.subtract(invoiced);
                    %>
                        <option value="<%= o.getId() %>"
                            data-customerid="<%= o.getCustomerId() %>"
                            data-customer="<%= o.getCustomerName() %>"
                            data-amount="<%= NumberUtil.fmtMoney(amt) %>"
                            data-remaining="<%= rem.compareTo(BigDecimal.ZERO) > 0 ? NumberUtil.fmtMoney(rem) : "0" %>"
                            data-ordernumber="<%= o.getOrderNumber() %>">
                            <%= o.getOrderNumber() %> - <%= o.getCustomerName() %> ($<%= NumberUtil.fmtMoney(amt) %>)
                        </option>
                    <%
                            }
                        } catch (Exception e) {
                            out.println("<option value=''>載入失敗：" + e.getMessage() + "</option>");
                        }
                    %>
                </select>
            </div>
        </div>
        <% } %>

        <div class="form-section">
            <h3 class="form-section-title">應收帳款</h3>

            <div class="form-group">
                <label>單據編號 (留空自動產生)：</label>
                <input type="text" name="invoiceNumber" placeholder="例如: INV-202606-001">
            </div>

            <div class="form-group">
                <label>應收金額：</label>
                <input type="text" inputmode="decimal" name="amount" id="amount" required value="<%= hasOrder ? NumberUtil.fmtMoney(remaining) : "" %>" oninput="formatMoneyInput(this)">
            </div>

            <div class="row-2">
                <div class="form-group">
                    <label>請款日期：</label>
                    <input type="date" name="issueDate" id="issueDate" required>
                </div>
                <div class="form-group">
                    <label>到期日：</label>
                    <input type="date" name="dueDate" id="dueDate">
                </div>
            </div>

            <div class="form-group" id="noteGroup">
                <label>備註 <span class="btn-add-note" id="btnAddNote" onclick="toggleNote()">+</span></label>
                <textarea name="note" id="noteArea" rows="2" placeholder="備註..." style="display:none;"></textarea>
            </div>
        </div>

        <div class="form-section form-section-highlight">
            <h3 class="form-section-title">實際到帳</h3>

            <div class="form-group">
                <label>收款狀態：</label>
                <select name="paymentStatus" id="paymentStatus" onchange="togglePaymentFields()">
                    <option value="0">未收款</option>
                    <option value="1">已收款 (已到帳)</option>
                </select>
            </div>
            <div class="row-2">
                <div class="form-group">
                    <label>收款日期：</label>
                    <input type="date" name="paymentDate" id="paymentDate" disabled>
                </div>
                <div class="form-group">
                    <label>實收金額：</label>
                    <input type="text" inputmode="decimal" name="receivedAmount" id="receivedAmount" disabled oninput="formatMoneyInput(this)">
                </div>
            </div>
        </div>

        <input type="hidden" name="status" value="0">
        <button type="button" class="btn-submit" onclick="confirmSubmit()">新增</button>
        <a href="invoice_list.jsp<%= hasOrder ? "?orderId=" + orderIdVal : "" %>" class="back-link">返回應收帳款列表</a>
    </form>
</div>

<% if (!hasOrder) { %>
<script>
function loadOrderInfo() {
    var sel = document.getElementById('orderSelect');
    if (sel.value) {
        window.location.href = 'add_invoice.jsp?orderId=' + sel.value;
    }
}
</script>
<% } %>

<% if (hasOrder) { %>
<script>
function toggleOrderDetail() {
    var detail = document.getElementById('orderDetail');
    var icon = document.getElementById('toggleIcon');
    if (detail.style.display === 'none' || detail.style.display === '') {
        detail.style.display = 'block';
        icon.innerHTML = '&#9660;';
    } else {
        detail.style.display = 'none';
        icon.innerHTML = '&#9654;';
    }
}
function togglePaymentDetail() {
    var detail = document.getElementById('paymentDetail');
    var icon = document.getElementById('payToggleIcon');
    if (detail.style.display === 'none' || detail.style.display === '') {
        detail.style.display = 'block';
        icon.innerHTML = '&#9660;';
    } else {
        detail.style.display = 'none';
        icon.innerHTML = '&#9654;';
    }
}
function openInvoiceDetail() {
    window.open('<%= request.getContextPath() %>/invoice/invoice_list.jsp?orderId=<%= orderIdVal %>', 'invoiceDetail', 'width=900,height=500,scrollbars=yes');
}
</script>
<% } %>

<script>
function toggleNote() {
    var area = document.getElementById('noteArea');
    var btn = document.getElementById('btnAddNote');
    if (area.style.display === 'none') {
        area.style.display = 'block';
        btn.textContent = '-';
    } else {
        area.style.display = 'none';
        btn.textContent = '+';
        area.value = '';
    }
}
function togglePaymentFields() {
    var sel = document.getElementById('paymentStatus');
    var dateField = document.getElementById('paymentDate');
    var amountField = document.getElementById('receivedAmount');
    if (sel.value === '0') {
        dateField.disabled = true;
        dateField.value = '';
        amountField.disabled = true;
        amountField.value = '';
    } else {
        dateField.disabled = false;
        amountField.disabled = false;
    }
}
function confirmSubmit() {
    var status = document.getElementById('paymentStatus').value;
    var amount = parseNumber(document.getElementById('amount').value);
    var received = parseNumber(document.getElementById('receivedAmount').value);
    var payDate = document.getElementById('paymentDate').value;

    if (status === '1') {
        if (!payDate) { alert('請填寫收款日期'); return; }
        if (received <= 0) { alert('請填寫實收金額'); return; }
        if (Math.abs(received - amount) > 0.01) {
            var diff = received - amount;
            var msg = diff > 0
                ? '實收金額 ($' + fmtMoney(received) + ') 比應收金額 ($' + fmtMoney(amount) + ') 多了 $' + fmtMoney(diff)
                : '實收金額 ($' + fmtMoney(received) + ') 比應收金額 ($' + fmtMoney(amount) + ') 少了 $' + fmtMoney(Math.abs(diff));
            if (!confirm(msg + '\n\n是否仍要送出？')) return;
        }
    }

    var orderNumber = '<%= hasOrder ? (orderNumber != null ? orderNumber : "-") : "" %>';
    var customerName = '<%= hasOrder ? (customerName != null ? customerName : "-") : "" %>';
    var invoiceNum = document.querySelector('input[name="invoiceNumber"]').value || '(自動產生)';
    var issueDate = document.getElementById('issueDate').value || '-';
    var dueDate = document.getElementById('dueDate').value || '-';
    var note = document.getElementById('noteArea').value || '';
    var payLabel = status === '1' ? '已收款 (已到帳)' : '未收款';
    var payDateVal = status === '1' ? payDate : '-';
    var receivedVal = status === '1' ? '$' + fmtMoney(received) : '-';

    var html = '<h3 style="margin:0 0 20px;font-size:18px;color:#1a1a2e;border-bottom:2px solid #e9ecef;padding-bottom:12px;">確認新增應收帳款</h3>'
        + '<table style="width:100%;font-size:14px;border-collapse:collapse;">'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">訂單編號</td><td style="padding:6px 0;font-weight:600;">' + escHtml(orderNumber) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">客戶名稱</td><td style="padding:6px 0;font-weight:600;">' + escHtml(customerName) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">單據編號</td><td style="padding:6px 0;font-weight:600;">' + escHtml(invoiceNum) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">應收金額</td><td style="padding:6px 0;font-weight:600;color:#4361ee;">$' + fmtMoney(amount) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">請款日期</td><td style="padding:6px 0;">' + escHtml(issueDate) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">到期日</td><td style="padding:6px 0;">' + escHtml(dueDate) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">收款狀態</td><td style="padding:6px 0;">' + escHtml(payLabel) + '</td></tr>';
    if (status === '1') {
        html += '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">收款日期</td><td style="padding:6px 0;">' + escHtml(payDateVal) + '</td></tr>'
            + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">實收金額</td><td style="padding:6px 0;font-weight:600;">' + escHtml(receivedVal) + '</td></tr>';
    }
    if (note) {
        html += '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">備註</td><td style="padding:6px 0;">' + escHtml(note) + '</td></tr>';
    }
    html += '</table>'
        + '<div style="display:flex;justify-content:flex-end;gap:10px;margin-top:24px;">'
        + '<button id="cCancelBtn" style="padding:8px 24px;border:1px solid #6c757d;background:#fff;border-radius:6px;cursor:pointer;font-size:14px;">取消</button>'
        + '<button id="cOkBtn" style="padding:8px 24px;border:none;background:#4361ee;color:#fff;border-radius:6px;cursor:pointer;font-size:14px;">確認新增</button>'
        + '</div>';

    var overlay = document.createElement('div');
    overlay.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:10000;display:flex;align-items:center;justify-content:center;';
    var box = document.createElement('div');
    box.className = 'dialog-box';
    box.style.maxHeight = '85vh';
    box.style.overflowY = 'auto';
    box.innerHTML = html;
    overlay.appendChild(box);
    document.body.appendChild(overlay);

    document.getElementById('cCancelBtn').onclick = function() { document.body.removeChild(overlay); };
    document.getElementById('cOkBtn').onclick = function() {
        document.body.removeChild(overlay);
        ['amount','receivedAmount'].forEach(function(id) {
            var el = document.getElementById(id);
            if (el && !el.disabled) el.value = el.value.replace(/,/g, '');
        });
        document.getElementById('invoiceForm').submit();
    };
    overlay.onclick = function(e) { if (e.target === overlay) document.body.removeChild(overlay); };
}
function escHtml(s) { var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

document.addEventListener('DOMContentLoaded', function() {
    var today = new Date();
    document.getElementById('issueDate').value = today.getFullYear() + '-' +
        String(today.getMonth()+1).padStart(2,'0') + '-' +
        String(today.getDate()).padStart(2,'0');

    var due = new Date(today);
    due.setDate(due.getDate() + 60);
    document.getElementById('dueDate').value = due.getFullYear() + '-' +
        String(due.getMonth()+1).padStart(2,'0') + '-' +
        String(due.getDate()).padStart(2,'0');

    togglePaymentFields();

    document.getElementById('invoiceForm').addEventListener('submit', function() {
        ['amount','receivedAmount'].forEach(function(id) {
            var el = document.getElementById(id);
            if (el && !el.disabled) el.value = el.value.replace(/,/g, '');
        });
    });
});
</script>

<style>
.order-quick-info {
    display: flex;
    gap: 20px;
    margin-bottom: 12px;
}
.quick-item {
    display: flex;
    flex-direction: column;
}
.quick-label {
    font-size: 12px;
    color: #6c757d;
    margin-bottom: 2px;
}
.quick-value {
    font-size: 15px;
    font-weight: 700;
    color: #1a1a2e;
}
.quick-value.amount {
    color: #4361ee;
    font-size: 17px;
}
.toggle-detail {
    font-size: 13px;
    color: #4361ee;
    cursor: pointer;
    padding: 6px 0;
    user-select: none;
}
.toggle-detail:hover { text-decoration: underline; }
.toggle-section { cursor: pointer; user-select: none; }
.toggle-section:hover { color: #4361ee; }
#payToggleIcon { font-size: 10px; margin-right: 4px; }
#toggleIcon { font-size: 10px; margin-right: 4px; }
.order-detail {
    display: none;
    background: #f8f9fa;
    border: 1px solid #e9ecef;
    border-radius: 6px;
    padding: 14px 16px;
    margin-top: 8px;
}
.detail-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px 24px;
}
.detail-item {
    display: flex;
    justify-content: space-between;
    font-size: 13px;
}
.detail-label { color: #6c757d; }
.detail-value { font-weight: 600; color: #1a1a2e; }

.btn-add-note {
    display: inline-block;
    width: 20px;
    height: 20px;
    line-height: 18px;
    text-align: center;
    border: 1.5px solid #adb5bd;
    border-radius: 4px;
    font-size: 14px;
    font-weight: 700;
    color: #6c757d;
    cursor: pointer;
    vertical-align: middle;
    margin-left: 6px;
}
.btn-add-note:hover {
    border-color: #4361ee;
    color: #4361ee;
}

.payment-status-empty {
    text-align: center;
    padding: 20px;
    color: #adb5bd;
    font-size: 14px;
    font-weight: 600;
}
.payment-summary {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px 24px;
    margin-bottom: 14px;
}
.pay-row {
    display: flex;
    justify-content: space-between;
    font-size: 13px;
}
.pay-label { color: #6c757d; }
.pay-value { font-weight: 700; color: #1a1a2e; }
.pay-link { color: #4361ee; cursor: pointer; text-decoration: underline; }
.pay-link:hover { color: #3a56d4; }
.pay-green { color: #2e7d32; }
.pay-red { color: #c62828; }
.payment-progress { margin-bottom: 14px; }
.progress-bar {
    height: 10px;
    background: #e9ecef;
    border-radius: 5px;
    overflow: hidden;
    position: relative;
}
.progress-invoiced {
    position: absolute;
    height: 100%;
    background: #90caf9;
    border-radius: 5px 0 0 5px;
    top: 0; left: 0;
}
.progress-paid {
    position: absolute;
    height: 100%;
    background: #4361ee;
    border-radius: 5px 0 0 5px;
    top: 0; left: 0;
}
.payment-done {
    text-align: center;
    padding: 10px;
    background: #e8f5e9;
    color: #2e7d32;
    border-radius: 6px;
    font-size: 13px;
    font-weight: 700;
}
.payment-waiting {
    text-align: center;
    padding: 10px;
    background: #fff8e1;
    color: #f57f17;
    border-radius: 6px;
    font-size: 13px;
    font-weight: 600;
}
</style>

<%@ include file="../include/footer.jsp" %>
