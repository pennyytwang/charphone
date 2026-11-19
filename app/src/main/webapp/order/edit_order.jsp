<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, dao.OrderDao, util.NumberUtil, model.Customer, model.Product, model.Order, java.text.SimpleDateFormat, java.sql.Timestamp" %>
<% request.setAttribute("pageTitle", "編輯訂單"); %>
<% request.setAttribute("pageIcon", "☰"); %>
<% request.setAttribute("pageSubtitle", "修改訂單內容"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>編輯訂單</h2>

    <%

        String idStr = request.getParameter("id");
        Order o = null;
        if (idStr != null && !idStr.isEmpty()) {
            try {
                OrderDao dao = new OrderDao();
                o = dao.getOrderById(Integer.parseInt(idStr));
            } catch (Exception e) {
                out.println("<div class='error-msg'>找不到該訂單資料。</div>");
            }
        }
        if (o == null) {
            out.println("<div class='error-msg'>無效的訂單編號。</div>");
        } else {
            OrderDao dao = new OrderDao();
            List<Customer> customers = dao.getCustomers();
            List<Product> products = dao.getProducts();
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            String actualAmountValue = o.getActualAmount() != null ? o.getActualAmount().toPlainString() : "";
            if (actualAmountValue.isEmpty()) {
                actualAmountValue = o.getTotalAmount() != null ? o.getTotalAmount().toPlainString() : "";
            }
            String actualAmountDisplay = actualAmountValue.isEmpty() ? "" : NumberUtil.fmtMoney(Double.parseDouble(actualAmountValue));
    %>

    <form id="orderForm" action="<%= request.getContextPath() %>/OrderServlet" method="POST">
        <input type="hidden" name="id" value="<%= o.getId() %>">

        <div class="form-group">
            <label>客戶名稱：</label>
            <select name="customerId" id="customerId" required>
                <option value="">-- 請選擇客戶 --</option>
                <% for(Customer c : customers) { %>
                    <option value="<%= c.getId() %>" <%= c.getId() == o.getCustomerId() ? "selected" : "" %>><%= c.getCustomerName() %></option>
                <% } %>
            </select>
        </div>

        <div class="form-group">
            <label>訂單編號 (依客戶編號-日期西洋年月-流水號3碼)：</label>
            <input type="text" name="orderNumber" value="<%= o.getOrderNumber() %>" readonly>
        </div>

        <div class="form-group">
            <label>品項：</label>
            <select name="productId" id="productId" required onchange="fillProductInfo()">
                <option value="">-- 請選擇品項 --</option>
                <% for(Product p : products) { %>
                    <option value="<%= p.getId() %>"
                        <%= p.getId() == o.getProductId() ? "selected" : "" %>
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
                <option value="1" <%= o.getPriceType() == 1 ? "selected" : "" %>>按重量 (kg)</option>
                <option value="2" <%= o.getPriceType() == 2 ? "selected" : "" %>>按個數 (pcs)</option>
            </select>
        </div>

        <div class="row-2">
            <div class="form-group">
                <span style="display:inline-flex;align-items:center;gap:4px;">
                    <label id="weightLabel" style="margin-bottom:0;">單個重量 (kg)：</label>
                    <button type="button" onclick="toggleWeightEdit()" class="btn-toggle" title="切換為可修改">✎</button>
                </span>
                <input type="text" name="unitWeight" id="unitWeight" readonly value="<%= o.getUnitWeight() != null ? NumberUtil.fmtQty(o.getUnitWeight().doubleValue()) : "" %>" onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="calcTotal()">
            </div>
            <div class="form-group">
                <span style="display:inline-flex;align-items:center;gap:4px;">
                    <label id="unitLabel" style="margin-bottom:0;">單價：</label>
                    <button type="button" onclick="togglePriceEdit()" class="btn-toggle" title="切換為可修改">✎</button>
                </span>
                <input type="text" name="unitPrice" id="unitPrice" readonly value="<%= o.getUnitPrice() != null ? NumberUtil.fmtQty(o.getUnitPrice().doubleValue()) : "" %>" onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="calcTotal()">
            </div>
        </div>

        <div class="form-group">
            <label>客戶下單量 (單位依計價方式決定為 pcs 或 kg)：</label>
                <input type="text" name="quantity" id="quantity" value="<%= NumberUtil.fmtQty(o.getQuantity().doubleValue()) %>" required onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="calcTotal()">
        </div>

        <div class="form-group">
            <label>預計應收金額：</label>
            <input type="text" id="totalAmountDisplay" readonly value="$<%= NumberUtil.fmtMoney(o.getTotalAmount()) %>">
            <input type="hidden" name="totalAmount" id="totalAmount" value="<%= NumberUtil.fmtQty(o.getTotalAmount().doubleValue()) %>">
        </div>

        <div class="form-group">
            <label>實際應收金額：</label>
            <input type="text" name="actualAmount" id="actualAmount" inputmode="decimal" value="<%= actualAmountDisplay %>" onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="checkAmountDiff()">
        </div>

        <div class="form-group" id="diffReasonGroup" style="<%= o.getActualAmount() != null && o.getTotalAmount() != null && o.getActualAmount().compareTo(o.getTotalAmount()) != 0 ? "" : "display:none;" %>">
            <label>金額差異原因：</label>
            <textarea name="amountDiffReason" id="amountDiffReason" rows="2"><%= o.getAmountDiffReason() != null ? o.getAmountDiffReason() : "" %></textarea>
        </div>

        <div class="form-group">
            <label>交期：</label>
            <input type="date" name="expectedDeliveryDate" value="<%= o.getExpectedDeliveryDate() != null ? sdf.format(o.getExpectedDeliveryDate()) : "" %>">
        </div>

        <input type="hidden" name="orderDate" value="<%= sdf.format(o.getOrderDate()) %>">
        <input type="hidden" name="deliveryDate" value="<%= o.getDeliveryDate() != null ? sdf.format(o.getDeliveryDate()) : "" %>">

        <div class="form-group">
            <label>備註：
                <button type="button" id="noteToggleBtn" onclick="toggleNote()" class="btn-toggle">+</button>
            </label>
            <textarea name="note" id="noteTextarea" rows="3" style="display:none;"><%= o.getNote() != null ? o.getNote() : "" %></textarea>
        </div>

        <script>
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
        </script>

        <button type="button" onclick="confirmSubmit()" class="btn-submit">儲存修改</button>
        <a href="order_list.jsp" class="back-link">返回訂單列表</a>
    </form>

    <script>
    function formatAmountField(el) {
        var v = el.value.replace(/[^0-9.\-]/g, '');
        if (v && !isNaN(parseFloat(v))) el.value = fmtQtyDisplay(v);
    }
    function parseAmountField(el) {
        el.value = el.value.replace(/[^0-9.\-]/g, '');
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
    }

    function checkAmountDiff() {
        var expected = parseFloat(document.getElementById('totalAmount').value) || 0;
        var actual = parseFloat(document.getElementById('actualAmount').value.replace(/[^0-9.\-]/g, ''));
        document.getElementById('diffReasonGroup').style.display = (actual && Math.abs(actual - expected) > 0.01) ? 'block' : 'none';
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

    function confirmSubmit() {
        var custSel = document.getElementById('customerId');
        var prodSel = document.getElementById('productId');
        if (!custSel.value) { alert('請選擇客戶'); return; }
        if (!prodSel.value) { alert('請選擇品項'); return; }
        if (!document.getElementById('quantity').value || parseFloat(document.getElementById('quantity').value) <= 0) { alert('請填寫有效數量'); return; }

        var custName = custSel.options[custSel.selectedIndex] ? custSel.options[custSel.selectedIndex].text : '';
        var prodName = prodSel.options[prodSel.selectedIndex] ? prodSel.options[prodSel.selectedIndex].text : '';
        var qty = document.getElementById('quantity').value || '0';
        var priceType = document.getElementById('priceType').value === '1' ? '按重量(kg)' : '按個數(pcs)';
        var unitWeight = document.getElementById('unitWeight').value || '-';
        var unitPrice = document.getElementById('unitPrice').value || '-';
        var totalAmt = parseFloat(document.getElementById('totalAmount').value) || 0;
        var actualVal = document.getElementById('actualAmount').value;
        var actualAmt = actualVal ? parseNumber(actualVal) : totalAmt;
        var expDateEl = document.querySelector('input[name="expectedDeliveryDate"]');
        var expDate = expDateEl ? expDateEl.value || '-' : '-';
        var orderNum = document.querySelector('input[name="orderNumber"]').value || '-';
        var note = document.getElementById('noteTextarea').value || '';

        var rows = ''
            + '<tr><td>訂單編號</td><td>' + orderNum + '</td></tr>'
            + '<tr><td>客戶名稱</td><td>' + custName + '</td></tr>'
            + '<tr><td>品項</td><td>' + prodName + '</td></tr>'
            + '<tr><td>計價方式</td><td>' + priceType + '</td></tr>'
            + '<tr><td>數量</td><td>' + qty + '</td></tr>'
            + '<tr><td>單個重量</td><td>' + unitWeight + '</td></tr>'
            + '<tr><td>單價</td><td>' + unitPrice + '</td></tr>'
            + '<tr><td>預計應收</td><td>' + fmtMoney(totalAmt) + '</td></tr>'
            + '<tr><td>實際應收</td><td>' + fmtMoney(actualAmt) + '</td></tr>'
            + '<tr><td>預計交期</td><td>' + expDate + '</td></tr>';
        if (note) {
            rows += '<tr><td>備註</td><td>' + note + '</td></tr>';
        }

        var overlay = document.createElement('div');
        overlay.className = 'confirm-overlay';
        overlay.id = 'confirmOverlay';
        overlay.innerHTML = '<div class="confirm-card">'
            + '<h3>確認修改訂單</h3>'
            + '<table>' + rows + '</table>'
            + '<div class="confirm-actions">'
            + '<button class="btn-confirm-cancel" onclick="document.getElementById(\'confirmOverlay\').remove()">取消</button>'
            + '<button class="btn-confirm-ok" id="confirmOkBtn">確認</button>'
            + '</div></div>';
        document.body.appendChild(overlay);

        document.getElementById('confirmOkBtn').onclick = function() {
            document.getElementById('confirmOverlay').remove();
            doAjaxSubmit();
        };
    }

    function doAjaxSubmit() {
        var form = document.getElementById('orderForm');
        var btn = form.querySelector('.btn-submit');
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
                showToast('訂單已更新！', 'success');
                setTimeout(function() {
                    window.location.href = 'order_list.jsp';
                }, 1000);
            } else {
                showToast(data.error || '更新失敗', 'error');
                btn.disabled = false;
            }
        })
        .catch(function() {
            showToast('系統錯誤，請稍後再試', 'error');
            btn.disabled = false;
        });
    }
    </script>
    <% } %>
</div>

<%@ include file="../include/footer.jsp" %>
