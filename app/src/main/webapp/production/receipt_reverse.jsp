<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.math.BigDecimal, java.util.Map, util.NumberUtil, dao.ProductionDao, model.Production" %>
<% request.setAttribute("pageTitle", "沖正入庫"); %>
<% request.setAttribute("pageIcon", "⚙"); %>
<% request.setAttribute("pageSubtitle", "撤銷成品入庫記錄"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>沖正入庫</h2>

    <%
        String idStr = request.getParameter("id");
        if (idStr == null || idStr.isEmpty()) {
            out.println("<div class='error-msg'>無效的工單編號。</div>");
        } else {
            String error = request.getParameter("error");
            if ("failed".equals(error)) {
    %>
        <div class="error-msg">沖正失敗，請稍後再試。</div>
    <% } else if ("invalid_qty".equals(error)) { %>
        <div class="error-msg">沖正數量必須大於 0。</div>
    <% } else if ("exceed".equals(error)) { %>
        <div class="error-msg">沖正數量不能超過該筆入庫數量。</div>
    <% } else if ("insufficient_stock".equals(error)) { %>
        <div class="error-msg">成品倉庫存不足，無法沖正。</div>
    <% } else if ("success".equals(request.getParameter("status"))) { %>
        <div class="alert alert-success">沖正成功！</div>
    <% }

        int productionId = Integer.parseInt(idStr);
        ProductionDao dao = new ProductionDao();
        Production p = dao.getProductionById(productionId);
        if (p == null) {
            out.println("<div class='error-msg'>找不到此工單。</div>");
            return;
        }

        String prodNumber = p.getProductionNumber();
        String productName = p.getProductName();
        String unit = p.getPriceType() == 1 ? "kg" : "pcs";
        BigDecimal manufacturedQty = p.getManufacturedQty() != null ? p.getManufacturedQty() : BigDecimal.ZERO;
        int productId = p.getProductId();
        int orderId = p.getOrderId();

        BigDecimal netReceived = dao.getNetReceivedQty(productionId);
        BigDecimal currentStock = dao.getStockForProduct(productId);

        java.util.List<Map<String, Object>> receipts = dao.getReceiptTransactions(productionId);
    %>

    <div class="order-info">
        <span><b>工單編號：</b><%= prodNumber %></span>
        <span><b>品項：</b><%= productName %></span>
        <span><b>單位：</b><%= unit %></span>
    </div>
    <div class="order-info" style="margin-top:8px;background:#fff5f5;border-left-color:#28a745;">
        <span><b>已製造：</b><%= NumberUtil.fmtQty(manufacturedQty.doubleValue()) %> <%= unit %></span>
        <span><b>淨入庫：</b><%= NumberUtil.fmtQty(netReceived.doubleValue()) %> <%= unit %></span>
        <span style="margin-left:20px;"><b>成品倉庫存：</b><%= NumberUtil.fmtQty(currentStock.doubleValue()) %> <%= unit %></span>
    </div>

    <% if (receipts.isEmpty()) { %>
        <div style="text-align:center;padding:30px;color:#999;">此工單尚無入庫紀錄。</div>
    <% } else { %>
        <h3 style="margin-top:24px;margin-bottom:12px;font-size:16px;color:#333;">入庫紀錄</h3>
        <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>交易編號</th>
                    <th>入庫數量</th>
                    <th>已沖正</th>
                    <th>可沖正</th>
                    <th>入庫前庫存</th>
                    <th>入庫後庫存</th>
                    <th>入庫時間</th>
                    <th>操作</th>
                </tr>
            </thead>
            <tbody>
                <%
                    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm");
                    for (Map<String, Object> r : receipts) {
                        BigDecimal qty = (BigDecimal) r.get("quantity");
                        java.sql.Timestamp ts = (java.sql.Timestamp) r.get("createdAt");
                        BigDecimal revQty = (BigDecimal) r.get("reversedUpTo");
                        BigDecimal canReverse = qty.subtract(revQty);
                        if (canReverse.compareTo(BigDecimal.ZERO) < 0) canReverse = BigDecimal.ZERO;
                %>
                <tr>
                    <td><%= r.get("txnNumber") %></td>
                    <td><%= NumberUtil.fmtQty(qty.doubleValue()) %> <%= unit %></td>
                    <td><%= NumberUtil.fmtQty(revQty.doubleValue()) %> <%= unit %></td>
                    <td style="font-weight:600;"><%= canReverse.compareTo(BigDecimal.ZERO) > 0 ? NumberUtil.fmtQty(canReverse.doubleValue()) + " " + unit : "-" %></td>
                    <td><%= NumberUtil.fmtQty(((BigDecimal) r.get("balanceBefore")).doubleValue()) %></td>
                    <td><%= NumberUtil.fmtQty(((BigDecimal) r.get("balanceAfter")).doubleValue()) %></td>
                    <td><%= ts != null ? sdf.format(ts) : "-" %></td>
                    <td>
                        <% if (canReverse.compareTo(BigDecimal.ZERO) > 0) { %>
                            <button class="btn btn-danger btn-sm" onclick="openReverseModal(<%= r.get("id") %>, '<%= r.get("txnNumber") %>', <%= canReverse.doubleValue() %>, '<%= unit %>')">沖正</button>
                        <% } else { %>
                            <span style="color:#999;">已全沖</span>
                        <% } %>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
        </div>
    <% } %>

        <a href="production_list.jsp?orderId=<%= orderId %>" class="back-link">返回工單列表</a>

    <script>
    function openReverseModal(txnId, txnNumber, maxQty, unit) {
        var html = '<h3 style="margin:0 0 20px;font-size:18px;color:#1a1a2e;border-bottom:2px solid #e9ecef;padding-bottom:12px;">沖正入庫紀錄</h3>'
            + '<table style="width:100%;font-size:14px;border-collapse:collapse;">'
            + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;">交易編號</td><td style="padding:6px 0;font-weight:600;">' + txnNumber + '</td></tr>'
            + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;">可沖正數量</td><td style="padding:6px 0;font-weight:600;">' + maxQty + ' ' + unit + '</td></tr>'
            + '</table>'
            + '<div style="margin-top:16px;">'
            + '<label style="display:block;margin-bottom:6px;font-weight:600;">沖正數量 (' + unit + ')</label>'
            + '<input type="number" id="revQty" step="any" value="' + maxQty + '" max="' + maxQty + '" style="width:100%;padding:8px 12px;border:1px solid #ddd;border-radius:6px;font-size:14px;">'
            + '</div>'
            + '<div style="margin-top:16px;">'
            + '<label style="display:block;margin-bottom:6px;font-weight:600;">備註</label>'
            + '<input type="text" id="revNote" value="沖正：' + txnNumber + '" style="width:100%;padding:8px 12px;border:1px solid #ddd;border-radius:6px;font-size:14px;">'
            + '</div>'
            + '<div style="display:flex;justify-content:flex-end;gap:10px;margin-top:24px;">'
            + '<button id="revCancelBtn" style="padding:8px 24px;border:1px solid #6c757d;background:#fff;border-radius:6px;cursor:pointer;font-size:14px;">取消</button>'
            + '<button id="revOkBtn" style="padding:8px 24px;border:none;background:#4361ee;color:#fff;border-radius:6px;cursor:pointer;font-size:14px;">確認沖正</button>'
            + '</div>';

        var overlay = document.createElement('div');
        overlay.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:10000;display:flex;align-items:center;justify-content:center;';
        var box = document.createElement('div');
        box.className = 'dialog-box';
        box.innerHTML = html;
        overlay.appendChild(box);
        document.body.appendChild(overlay);

        document.getElementById('revCancelBtn').onclick = function() { document.body.removeChild(overlay); };
        document.getElementById('revOkBtn').onclick = function() {
            var qty = parseFloat(document.getElementById('revQty').value) || 0;
            if (qty <= 0) { alert('沖正數量必須大於 0'); return; }
            if (qty > maxQty) { alert('沖正數量不能超過 ' + maxQty + ' ' + unit); return; }
            var note = document.getElementById('revNote').value || '';
            document.body.removeChild(overlay);

            var form = document.createElement('form');
            form.method = 'POST';
            form.action = '<%= request.getContextPath() %>/ProductionReceiptServlet';

            var fields = {
                action: 'reverse',
                productionId: '<%= productionId %>',
                orderId: '<%= orderId %>',
                txnId: txnId,
                quantity: qty,
                note: note
            };
            for (var k in fields) {
                var inp = document.createElement('input');
                inp.type = 'hidden';
                inp.name = k;
                inp.value = fields[k];
                form.appendChild(inp);
            }
            document.body.appendChild(form);
            form.submit();
        };
        overlay.onclick = function(e) { if (e.target === overlay) document.body.removeChild(overlay); };
    }
    </script>

    <% } %>
</div>

<%@ include file="../include/footer.jsp" %>
