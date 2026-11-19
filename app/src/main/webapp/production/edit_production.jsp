<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.text.SimpleDateFormat, java.math.BigDecimal, dao.ProductionDao, util.NumberUtil, model.Production" %>
<% request.setAttribute("pageTitle", "編輯工單"); %>
<% request.setAttribute("pageIcon", "⚙"); %>
<% request.setAttribute("pageSubtitle", "修改工單資訊"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container" style="max-width:620px;">
    <h2>編輯生產工單</h2>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">資料庫更新失敗，請稍後再試。</div>
    <% } else if ("exception".equals(error)) { %>
        <div class="error-msg">系統錯誤，請檢查輸入資料格式。</div>
    <% } else if ("receipt_conflict".equals(error)) { %>
        <div class="error-msg">已製造數量不能低於已入庫數量，請先沖正多餘庫存再調降。</div>
    <% } else if ("cancel_blocked".equals(error)) { %>
        <div class="error-msg">該產品已有部分出貨，無法取消工單。</div>
    <% } else if ("reverse_invalid".equals(error)) { %>
        <div class="error-msg">沖正數量必須大於 0。</div>
    <% } else if ("reverse_exceed".equals(error)) { %>
        <div class="error-msg">沖正數量不可大於已入庫數量。</div>
    <% } else if ("reverse_failed".equals(error)) { %>
        <div class="error-msg">沖正失敗，請稍後再試。</div>
    <% }

        String msg = request.getParameter("message");
        if ("reversed".equals(msg)) {
    %>
        <div class="success-msg">入庫沖正成功！</div>
    <% }

        String idStr = request.getParameter("id");
        Production p = null;
        ProductionDao dao = new ProductionDao();
        if (idStr != null && !idStr.isEmpty()) {
            try {
                p = dao.getProductionById(Integer.parseInt(idStr));
            } catch (Exception e) {
                out.println("<div class='error-msg'>找不到該工單資料。</div>");
            }
        }
        if (p == null) {
            out.println("<div class='error-msg'>無效的工單編號。</div>");
        } else {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");

            String expDelivery = "-";
            BigDecimal orderTotalAmt = null;
            try {
                Object[] info = dao.getOrderDeliveryAndAmount(p.getOrderId());
                if (info[0] != null) expDelivery = sdf.format((java.util.Date) info[0]);
                orderTotalAmt = (BigDecimal) info[1];
            } catch (Exception e) {}

            BigDecimal receivedQty = dao.getNetReceivedQty(p.getId());

            BigDecimal otherManufactured = dao.getOtherManufacturedQty(p.getOrderId(), p.getId());

            String unit = p.getPriceType() == 1 ? "kg" : "pcs";
    %>

    <%-- ═══ 訂單參考資訊 ═══ --%>
    <%
        BigDecimal thisManufactured = p.getManufacturedQty() != null ? p.getManufacturedQty() : BigDecimal.ZERO;
        BigDecimal totalManufactured = otherManufactured.add(thisManufactured);
        BigDecimal orderQty = p.getOrderQuantity() != null ? p.getOrderQuantity() : p.getQuantity();
        BigDecimal remaining = orderQty.subtract(totalManufactured);
        if (remaining.compareTo(BigDecimal.ZERO) < 0) remaining = BigDecimal.ZERO;
    %>
    <div style="background:#f0f7ff;border:1px solid #b3d4fc;border-radius:8px;padding:14px 18px;margin-bottom:20px;">
        <div style="font-weight:600;color:#1565c0;margin-bottom:8px;font-size:13px;">📋 訂單資訊</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;font-size:13px;">
            <div><span style="color:#6c757d;">來源訂單：</span><span style="font-weight:600;"><%= p.getOrderNumber() %></span></div>
            <div><span style="color:#6c757d;">客戶：</span><span style="font-weight:600;"><%= p.getCustomerName() %></span></div>
            <div><span style="color:#6c757d;">品項：</span><span style="font-weight:600;"><%= p.getProductName() %></span></div>
            <div><span style="color:#6c757d;">計價方式：</span><span style="font-weight:600;"><%= p.getPriceType() == 1 ? "按重量 (kg)" : "按個數 (pcs)" %></span></div>
            <div><span style="color:#6c757d;">已生產量：</span><span style="font-weight:600;"><%= NumberUtil.fmtQty(totalManufactured.doubleValue()) %> <%= unit %></span></div>
            <div><span style="color:#6c757d;">剩餘待產：</span><span style="font-weight:600;color:#d32f2f;"><%= NumberUtil.fmtQty(remaining.doubleValue()) %> <%= unit %></span></div>
            <div><span style="color:#6c757d;">預計交期：</span><span style="font-weight:600;<%= !"-".equals(expDelivery) ? "" : "color:#999;" %>"><%= expDelivery %></span></div>
        </div>
    </div>

    <form action="<%= request.getContextPath() %>/ProductionServlet" method="POST">
        <input type="hidden" name="id" value="<%= p.getId() %>">
        <input type="hidden" name="orderId" value="<%= p.getOrderId() %>">
        <input type="hidden" name="productId" value="<%= p.getProductId() %>">
        <input type="hidden" name="priceType" value="<%= p.getPriceType() %>">
        <input type="hidden" name="unitPrice" value="<%= p.getUnitPrice() != null ? NumberUtil.fmtQty(p.getUnitPrice().doubleValue()) : "" %>">
        <input type="hidden" name="unitWeight" value="<%= p.getUnitWeight() != null ? NumberUtil.fmtQty(p.getUnitWeight().doubleValue()) : "" %>">
        <input type="hidden" name="status" value="<%= p.getStatus() %>">

        <%-- ═══ 預計生產 ═══ --%>
        <div style="border:2px solid #e3f2fd;border-radius:10px;padding:16px 18px;margin-bottom:16px;background:#fafcff;">
            <div style="font-weight:600;color:#1565c0;margin-bottom:12px;font-size:14px;">📝 預計生產</div>
            <div class="row-2">
                <div class="form-group">
                    <label>訂單總數量：</label>
                    <input type="number" value="<%= NumberUtil.fmtQty((p.getOrderQuantity() != null ? p.getOrderQuantity() : p.getQuantity()).doubleValue()) %>" readonly>
                </div>
                <div class="form-group">
                    <label>本工單預計生產量：</label>
                    <input type="number" name="producedQty" id="producedQty" step="any" value="<%= p.getProducedQty() != null ? NumberUtil.fmtQty(p.getProducedQty().doubleValue()) : "0" %>">
                    <span style="font-size:12px;color:#6c757d;display:block;margin-top:3px;">訂單剩餘 <%= NumberUtil.fmtQty(remaining.doubleValue()) %> <%= unit %>，此工單預計生產全部剩餘量</span>
                </div>
            </div>
            <div class="row-2">
                <div class="form-group">
                    <label>預計開始日：</label>
                    <input type="date" name="startDate" value="<%= p.getStartDate() != null ? sdf.format(p.getStartDate()) : "" %>">
                </div>
                <div class="form-group">
                    <label>預計完成日：</label>
                    <input type="date" name="targetDate" value="<%= p.getTargetDate() != null ? sdf.format(p.getTargetDate()) : "" %>">
                </div>
            </div>
        </div>

        <%-- ═══ 實際生產 ═══ --%>
        <div style="border:2px solid #e8f5e9;border-radius:10px;padding:16px 18px;margin-bottom:16px;background:#fafffa;">
            <div style="font-weight:600;color:#2e7d32;margin-bottom:12px;font-size:14px;">🏭 實際生產</div>
            <div class="form-group">
                <label>已製造數量：</label>
                <input type="number" name="manufacturedQty" step="any" value="<%= p.getManufacturedQty() != null ? NumberUtil.fmtQty(p.getManufacturedQty().doubleValue()) : "0" %>">
                <% if (receivedQty.compareTo(BigDecimal.ZERO) > 0) { %>
                    <small style="color:#6c757d;font-size:12px;">已入庫 <b><%= NumberUtil.fmtQty(receivedQty.doubleValue()) %></b>，已製造不可低於此數</small>
                <% } %>
            </div>
            <div class="form-group">
                <label>實際完成日：</label>
                <input type="date" name="completedDate" value="<%= p.getCompletedDate() != null ? sdf.format(p.getCompletedDate()) : "" %>">
            </div>

            <% if (receivedQty.compareTo(BigDecimal.ZERO) > 0) { %>
            <div style="border:1px solid #ffc107;border-radius:8px;padding:12px;background:#fffde7;margin-top:8px;">
                <label style="color:#e65100;font-weight:bold;font-size:13px;">沖正入庫</label>
                <div style="display:flex;gap:8px;align-items:center;margin-top:6px;">
                    <input type="number" id="reverseQty" step="any" placeholder="沖正數量" style="flex:1;padding:6px;border:1px solid #ccc;border-radius:4px;font-size:13px;">
                    <span style="font-size:13px;color:#666;">目前入庫：<%= NumberUtil.fmtQty(receivedQty.doubleValue()) %></span>
                    <button type="button" class="btn-danger" onclick="doReverse(<%= p.getId() %>)">沖正</button>
                </div>
                <div id="reverseMsg" style="color:#c62828;font-size:13px;margin-top:4px;display:none;"></div>
            </div>
            <script>
            function doReverse(id) {
                var qty = document.getElementById('reverseQty').value;
                var msg = document.getElementById('reverseMsg');
                if (!qty || parseFloat(qty) <= 0) {
                    msg.textContent = '請輸入有效的沖正數量';
                    msg.style.display = '';
                    return;
                }
                if (parseFloat(qty) > <%= NumberUtil.fmtQty(receivedQty.doubleValue()) %>) {
                    msg.textContent = '沖正數量不可大於已入庫數量';
                    msg.style.display = '';
                    return;
                }
                msg.style.display = 'none';
                var form = document.createElement('form');
                form.method = 'POST';
                form.action = '<%= request.getContextPath() %>/ProductionServlet';
                var inp1 = document.createElement('input');
                inp1.type = 'hidden'; inp1.name = 'action'; inp1.value = 'reverse_receipt';
                var inp2 = document.createElement('input');
                inp2.type = 'hidden'; inp2.name = 'id'; inp2.value = id;
                var inp3 = document.createElement('input');
                inp3.type = 'hidden'; inp3.name = 'quantity'; inp3.value = qty;
                form.appendChild(inp1); form.appendChild(inp2); form.appendChild(inp3);
                document.body.appendChild(form);
                form.submit();
            }
            </script>
            <% } %>
        </div>

        <div class="form-group">
            <label>備註：</label>
            <textarea name="note" rows="3"><%= p.getNote() != null ? p.getNote() : "" %></textarea>
        </div>

        <div style="display:flex;gap:10px;align-items:center;">
            <button type="submit" class="btn-submit">儲存修改</button>
            <% if (receivedQty.compareTo(BigDecimal.ZERO) <= 0 && p.getStatus() != 3 && p.getCloseStatus() != 1) { %>
                <button type="button" class="btn-danger" onclick="cancelProduction(<%= p.getId() %>, <%= p.getOrderId() %>)">暫停此工單</button>
            <% } %>
            <% if (p.getStatus() == 3 && p.getCloseStatus() != 1) { %>
                <button type="button" class="btn-submit" style="background:#28a745;" onclick="restoreProduction(<%= p.getId() %>, <%= p.getOrderId() %>)">恢復工單</button>
            <% } %>
            <a href="production_list.jsp?orderId=<%= p.getOrderId() %>" class="back-link">返回工單列表</a>
        </div>
    </form>
    <script>
    function cancelProduction(id, orderId) {
        if (!confirm('確定要暫停此工單嗎？')) return;
        var form = document.createElement('form');
        form.method = 'POST';
        form.action = '<%= request.getContextPath() %>/ProductionServlet';
        var inp1 = document.createElement('input');
        inp1.type = 'hidden'; inp1.name = 'action'; inp1.value = 'cancel';
        var inp2 = document.createElement('input');
        inp2.type = 'hidden'; inp2.name = 'id'; inp2.value = id;
        var inp3 = document.createElement('input');
        inp3.type = 'hidden'; inp3.name = 'orderId'; inp3.value = orderId;
        var inp4 = document.createElement('input');
        inp4.type = 'hidden'; inp4.name = 'status'; inp4.value = '3';
        form.appendChild(inp1); form.appendChild(inp2); form.appendChild(inp3); form.appendChild(inp4);
        document.body.appendChild(form);
        form.submit();
    }

    function restoreProduction(id, orderId) {
        if (!confirm('確定要恢復此工單嗎？')) return;
        var form = document.createElement('form');
        form.method = 'POST';
        form.action = '<%= request.getContextPath() %>/ProductionServlet';
        var inp1 = document.createElement('input');
        inp1.type = 'hidden'; inp1.name = 'action'; inp1.value = 'cancel';
        var inp2 = document.createElement('input');
        inp2.type = 'hidden'; inp2.name = 'id'; inp2.value = id;
        var inp3 = document.createElement('input');
        inp3.type = 'hidden'; inp3.name = 'orderId'; inp3.value = orderId;
        var inp4 = document.createElement('input');
        inp4.type = 'hidden'; inp4.name = 'status'; inp4.value = '0';
        form.appendChild(inp1); form.appendChild(inp2); form.appendChild(inp3); form.appendChild(inp4);
        document.body.appendChild(form);
        form.submit();
    }
    </script>
    <% } %>
</div>

<%@ include file="../include/footer.jsp" %>
