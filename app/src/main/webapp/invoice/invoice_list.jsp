<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.InvoiceDao, dao.OrderDao, util.NumberUtil, model.Invoice, model.Order, java.text.SimpleDateFormat, java.util.List, java.math.BigDecimal" %>
<% request.setAttribute("pageTitle", "應收帳款管理"); %>
<% request.setAttribute("pageIcon", "$"); %>
<% request.setAttribute("pageSubtitle", "開立帳單與收款追蹤"); %>
<%@ include file="../include/header.jsp" %>
<%@ taglib prefix="my" tagdir="/WEB-INF/tags" %>

    <%
        String useInvoiceDate = request.getParameter("useInvoiceDate");
        String dateFrom = request.getParameter("dateFrom");
        String dateTo = request.getParameter("dateTo");
        String filterCustomerName = request.getParameter("customerName");
        String filterInvoiceNumber = request.getParameter("invoiceNumber");
        String paymentStatusParam = request.getParameter("paymentStatus");
        String orderIdParam = request.getParameter("orderId");
        String shippedParam = request.getParameter("shipped");
        String unpaidParam = request.getParameter("unpaid");
        String tabParam = request.getParameter("tab");
        Integer filterOrderId = orderIdParam != null && !orderIdParam.isEmpty() ? Integer.parseInt(orderIdParam) : null;
        boolean isFiltered = filterOrderId != null;
        boolean showUnpaid = "1".equals(unpaidParam);
        String activeTab = (tabParam != null && !tabParam.isEmpty()) ? tabParam : "invoices";

        int pageNum = 1;
        int pageSize = 20;
        String pageParam = request.getParameter("page");
        if (pageParam != null) {
            try { pageNum = Integer.parseInt(pageParam); if (pageNum < 1) pageNum = 1; } catch (NumberFormatException e) {}
        }
        int startIdx = (pageNum - 1) * pageSize;
        int invTotalPages = 1;
        int invFilteredIdx = 0;
        int invDisplayed = 0;
        int unTotalPages = 1;
        int unFilteredIdx = 0;
        int unDisplayed = 0;
    %>

    <% if (isFiltered) { %>
    <div style="display:flex;justify-content:space-between;margin-bottom:16px;">
        <a href="invoice_list.jsp" class="btn btn-outline">← 返回全部帳款</a>
    </div>
    <% } %>

    <% if (!isFiltered) { %>
    <form class="filter-bar" method="GET">
        <input type="hidden" name="unpaid" value="<%= showUnpaid ? "1" : "" %>">
        <input type="hidden" name="tab" value="<%= activeTab %>">
        <div class="field-check">
            <label class="check-label">
                <input type="checkbox" name="useInvoiceDate" <%= "on".equals(useInvoiceDate) ? "checked" : "" %>>
                請款
            </label>
        </div>
        <div class="field">
            <input type="date" name="dateFrom" value="<%= dateFrom != null ? dateFrom : new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date(System.currentTimeMillis() - 30L * 24 * 60 * 60 * 1000)) %>">
        </div>
        <span style="padding:0 4px;line-height:32px;">~</span>
        <div class="field">
            <input type="date" name="dateTo" value="<%= dateTo != null ? dateTo : new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>">
        </div>
        <div style="width:100%"></div>
        <div class="field">
            <label>客戶名稱</label>
            <input type="text" name="customerName" value="<%= filterCustomerName != null ? filterCustomerName : "" %>" placeholder="輸入客戶名稱">
        </div>
        <div class="field">
            <label>應收帳款單據編號</label>
            <input type="text" name="invoiceNumber" value="<%= filterInvoiceNumber != null ? filterInvoiceNumber : "" %>" placeholder="應收帳款單據編號">
        </div>
        <div class="field">
            <label>收款狀態</label>
            <select name="paymentStatus">
                <option value="">全部</option>
                <option value="0" <%= "0".equals(paymentStatusParam) ? "selected" : "" %>>未收款</option>
                <option value="1" <%= "1".equals(paymentStatusParam) ? "selected" : "" %>>已收款</option>
            </select>
        </div>
        <button type="submit" class="btn-search">查詢</button>
        <a href="invoice_list.jsp" class="btn-clear">清除</a>
        <% if (!showUnpaid) { %>
        <a href="invoice_list.jsp?unpaid=1" class="btn btn-outline" style="text-decoration:none;font-size:13px;padding:8px 16px;border-radius:6px;white-space:nowrap;">已出貨未收款</a>
        <% } else { %>
        <a href="invoice_list.jsp" class="btn btn-outline" style="text-decoration:none;font-size:13px;padding:8px 16px;border-radius:6px;white-space:nowrap;background:#fff3e0;border-color:#f57f17;color:#f57f17;">已出貨未收款 ✓</a>
        <% } %>
    </form>
    <% } %>

    <script>
    (function() {
        var p = new URLSearchParams(window.location.search);
        var msg = p.get('message'), err = p.get('error');
        var text = null, type = 'success';
        if (msg === 'success') { text = '資料已儲存！'; }
        else if (err === 'delete_failed') { text = '刪除失敗。'; type = 'error'; }
        else if (err === 'delete_paid') { text = '該筆應收帳款已收款 (已到帳)，無法刪除。'; type = 'error'; }
        else if (err === 'delete_settled') { text = '該筆應收帳款已結清，無法刪除。'; type = 'error'; }
        else if (msg === 'payment_updated') { text = '收款狀態已更新！'; }
        else if (err === 'payment_failed') { text = '更新收款狀態失敗。'; type = 'error'; }
        if (text) {
            var toast = document.createElement('div');
            toast.style.cssText = 'position:fixed;top:20px;right:20px;z-index:10002;padding:14px 24px;border-radius:8px;font-size:14px;font-weight:600;color:#fff;box-shadow:0 4px 16px rgba(0,0,0,0.2);opacity:0;transition:opacity 0.3s;background:' + (type === 'success' ? '#28a745' : '#dc3545') + ';';
            toast.textContent = text;
            document.body.appendChild(toast);
            requestAnimationFrame(function() { toast.style.opacity = '1'; });
            setTimeout(function() { toast.style.opacity = '0'; setTimeout(function() { toast.remove(); }, 300); }, 2500);
            window.history.replaceState({}, '', window.location.pathname);
        }
    })();
    </script>

    <%
        String orderNumber = "";
        String customerName = "";
        String productName = "";
        BigDecimal orderAmount = BigDecimal.ZERO;
        BigDecimal totalInvoiced = BigDecimal.ZERO;
        BigDecimal totalReceived = BigDecimal.ZERO;
        int invoiceCount = 0;
        int paidCount = 0;

        if (isFiltered) {
            try {
                OrderDao orderDao = new OrderDao();
                model.Order o = orderDao.getOrderById(filterOrderId);
                if (o != null) {
                    orderNumber = o.getOrderNumber() != null ? o.getOrderNumber() : "";
                    customerName = o.getCustomerName() != null ? o.getCustomerName() : "";
                    productName = o.getProductName() != null ? o.getProductName() : "";
                    orderAmount = o.getActualAmount() != null ? o.getActualAmount() : o.getTotalAmount();
                }

                InvoiceDao invDao2 = new InvoiceDao();
                Object[] invInfo2 = invDao2.getInvoiceSummaryByOrderId(filterOrderId);
                totalInvoiced = (BigDecimal) invInfo2[0];
                totalReceived = (BigDecimal) invInfo2[1];
                invoiceCount = (int) invInfo2[2];
                paidCount = (int) invInfo2[3];
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    %>

    <% if (isFiltered) {
        BigDecimal remainingToInvoice = orderAmount.subtract(totalInvoiced);
        if (remainingToInvoice.compareTo(BigDecimal.ZERO) < 0) remainingToInvoice = BigDecimal.ZERO;
        BigDecimal unpaid = orderAmount.subtract(totalReceived);
        if (unpaid.compareTo(BigDecimal.ZERO) < 0) unpaid = BigDecimal.ZERO;
        boolean allInvoiced = totalInvoiced.compareTo(orderAmount) >= 0;
        boolean allPaid = totalReceived.compareTo(orderAmount) >= 0 && invoiceCount > 0;
        int invoicedPct = orderAmount.compareTo(BigDecimal.ZERO) > 0 ? (int)Math.min(Math.round(totalInvoiced.multiply(new BigDecimal(100)).divide(orderAmount, 0, java.math.RoundingMode.HALF_UP).intValue()), 100) : 0;
        int paidPct = orderAmount.compareTo(BigDecimal.ZERO) > 0 ? (int)Math.min(Math.round(totalReceived.multiply(new BigDecimal(100)).divide(orderAmount, 0, java.math.RoundingMode.HALF_UP).intValue()), 100) : 0;
    %>
        <div style="background:#fff;border:1px solid #e0e0e0;border-radius:8px;padding:16px 20px;margin-bottom:16px;">
            <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:12px;">
                <div>
                    <div style="font-size:18px;font-weight:700;color:#333;"><%= orderNumber %></div>
                    <div style="font-size:14px;color:#666;margin-top:2px;"><%= customerName %>　|　<%= productName %></div>
                </div>
                <div style="display:flex;gap:24px;align-items:center;font-size:14px;">
                    <div>實際應收 <b>$<%= NumberUtil.fmtMoney(orderAmount) %></b></div>
                    <div>已開帳 <b style="color:#4361ee;">$<%= NumberUtil.fmtMoney(totalInvoiced) %></b> <span style="color:#6c757d;font-size:12px;">(<%= invoiceCount %>筆)</span></div>
                    <div>待開帳 <b style="color:<%= remainingToInvoice.compareTo(BigDecimal.ZERO) > 0 ? "#f57f17" : "#2e7d32" %>;"><%= remainingToInvoice.compareTo(BigDecimal.ZERO) > 0 ? "$" + NumberUtil.fmtMoney(remainingToInvoice) : "已完成" %></b></div>
                    <div>已收款 <b style="color:#2e7d32;">$<%= NumberUtil.fmtMoney(totalReceived) %></b> <span style="color:#6c757d;font-size:12px;">(<%= paidCount %>筆)</span></div>
                    <div>尚未收款 <b style="color:<%= unpaid.compareTo(BigDecimal.ZERO) > 0 ? "#dc3545" : "#2e7d32" %>;">$<%= NumberUtil.fmtMoney(unpaid) %></b></div>
                </div>
            </div>
        </div>
    <% } %>

    <% if (showUnpaid && !isFiltered) {
        String baseParam = "unpaid=1";
        String tabHrefInvoices = "invoice_list.jsp?" + baseParam + "&tab=invoices"
                + (filterCustomerName != null && !filterCustomerName.isEmpty() ? "&customerName=" + java.net.URLEncoder.encode(filterCustomerName, java.nio.charset.StandardCharsets.UTF_8) : "")
                + (filterInvoiceNumber != null && !filterInvoiceNumber.isEmpty() ? "&invoiceNumber=" + java.net.URLEncoder.encode(filterInvoiceNumber, java.nio.charset.StandardCharsets.UTF_8) : "")
                + (paymentStatusParam != null && !paymentStatusParam.isEmpty() ? "&paymentStatus=" + paymentStatusParam : "");
        String tabHrefUninvoiced = "invoice_list.jsp?" + baseParam + "&tab=uninvoiced"
                + (filterCustomerName != null && !filterCustomerName.isEmpty() ? "&customerName=" + java.net.URLEncoder.encode(filterCustomerName, java.nio.charset.StandardCharsets.UTF_8) : "");
    %>
    <div class="tab-bar">
        <a href="<%= tabHrefInvoices %>" class="tab <%= "invoices".equals(activeTab) ? "active" : "" %>">未收款帳款明細</a>
        <a href="<%= tabHrefUninvoiced %>" class="tab <%= "uninvoiced".equals(activeTab) ? "active" : "" %>">未開帳訂單</a>
    </div>
    <% } %>

    <% if (!showUnpaid || "invoices".equals(activeTab) || isFiltered) {
        String invBaseUrl = "invoice_list.jsp?submitted=1"
            + ("on".equals(useInvoiceDate) ? "&useInvoiceDate=on" : "")
            + (dateFrom != null && !dateFrom.isEmpty() ? "&dateFrom=" + dateFrom : "")
            + (dateTo != null && !dateTo.isEmpty() ? "&dateTo=" + dateTo : "")
            + (filterCustomerName != null && !filterCustomerName.trim().isEmpty() ? "&customerName=" + java.net.URLEncoder.encode(filterCustomerName.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
            + (filterInvoiceNumber != null && !filterInvoiceNumber.trim().isEmpty() ? "&invoiceNumber=" + java.net.URLEncoder.encode(filterInvoiceNumber.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
            + (paymentStatusParam != null && !paymentStatusParam.isEmpty() ? "&paymentStatus=" + paymentStatusParam : "")
            + (orderIdParam != null && !orderIdParam.isEmpty() ? "&orderId=" + orderIdParam : "")
            + (showUnpaid ? "&unpaid=1" : "")
            + (activeTab != null && !activeTab.isEmpty() ? "&tab=" + activeTab : "");
    %>
    <div class="table-container" style="display:flex;flex-direction:column;padding:0;">
    <table style="order:2;width:100%;">
        <thead>
            <tr>
                <th>序號</th>
                <th>單據編號</th>
                <th>客戶名稱</th>
                <th>關聯訂單</th>
                <th>實收金額</th>
                <th>請款日期</th>
                <th>到期日</th>
                <th>收款狀態</th>
                <th>收款日期</th>
                <th>備註</th>
                <th>操作</th>
            </tr>
        </thead>
        <tbody>
            <%
                try {
                    InvoiceDao dao = new InvoiceDao();
                    Integer paymentStatus = paymentStatusParam != null && !paymentStatusParam.isEmpty() ? Integer.parseInt(paymentStatusParam) : null;
                    String effectiveDateFrom = "on".equals(useInvoiceDate) ? dateFrom : null;
                    String effectiveDateTo = "on".equals(useInvoiceDate) ? dateTo : null;
                    List<Invoice> list = dao.getAllInvoices(effectiveDateFrom, effectiveDateTo, null, filterOrderId, paymentStatus, filterCustomerName, filterInvoiceNumber, showUnpaid ? true : null, showUnpaid ? true : null);
                    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                    invTotalPages = 1;
                    invFilteredIdx = 0;
                    invDisplayed = 0;
                    for (Invoice inv : list) {
                            invFilteredIdx++;
                            if (invFilteredIdx <= startIdx) continue;
                            if (invDisplayed >= pageSize) continue;
                            invDisplayed++;
            %>
                <tr>
                    <td><%= invFilteredIdx %></td>
                    <td><a href="edit_invoice.jsp?id=<%= inv.getId() %>" style="color:#4361ee;text-decoration:none;font-weight:600;"><%= inv.getInvoiceNumber() != null ? inv.getInvoiceNumber() : "-" %></a></td>
                    <td><b><%= inv.getCustomerName() %></b></td>
                    <td><a href="../order/order_list.jsp?orderId=<%= inv.getOrderId() %>" style="color:#1a1a2e;text-decoration:underline;font-weight:600;"><%= inv.getOrderNumber() != null ? inv.getOrderNumber() : "-" %></a></td>
                    <td><% if (inv.getReceivedAmount() != null) { %><span style="<%= inv.getReceivedAmount().compareTo(inv.getAmount()) != 0 ? "color:#dc3545;font-weight:600;" : "" %>">$<%= NumberUtil.fmtMoney(inv.getReceivedAmount()) %></span><% } else { %>-<% } %></td>
                    <td><%= inv.getIssueDate() != null ? sdf.format(inv.getIssueDate()) : "-" %></td>
                    <td><%= inv.getDueDate() != null ? sdf.format(inv.getDueDate()) : "-" %></td>
                    <td>
                        <%
                            int ps = inv.getPaymentStatus();
                            String paidDate = inv.getPaymentDate() != null ? sdf.format(inv.getPaymentDate()) : "";
                            String recvAmt = inv.getReceivedAmount() != null ? inv.getReceivedAmount().toPlainString() : "";
                            String badgeLabel = ps == 1 ? "已收款 (已到帳)" : "未收款";
                            String badgeClass = ps == 1 ? "badge-green" : "badge-red";
                        %>
                        <span class="badge <%= badgeClass %>" style="cursor:pointer;" onclick="openPaymentModal(<%= inv.getId() %>, <%= ps %>, '<%= recvAmt %>', '<%= paidDate %>', '<%= inv.getInvoiceNumber() %>')"><%= badgeLabel %></span>
                    </td>
                    <td><%= inv.getPaymentDate() != null ? sdf.format(inv.getPaymentDate()) : "-" %></td>
                    <td style="font-size:12px;color:#888;"><%= inv.getNote() != null ? inv.getNote() : "" %></td>
                    <td>
                        <a href="<%= request.getContextPath() %>/InvoiceServlet?action=delete&id=<%= inv.getId() %>" class="btn btn-danger btn-sm" onclick="return confirm('確定刪除此筆應收帳款？')">刪除</a>
                    </td>
                </tr>
            <%
                    }
                    if (list.isEmpty()) {
            %>
                        <tr>
                            <td colspan="11">
                                <div class="empty-state">
                                    <p>尚無應收帳款資料</p>
                                </div>
                            </td>
                        </tr>
            <%
                    }
                    invTotalPages = invFilteredIdx > 0 ? (int) Math.ceil((double) invFilteredIdx / pageSize) : 1;
                    if (pageNum > invTotalPages) pageNum = invTotalPages;
                } catch (Exception e) {
                    out.println("<tr><td colspan='11' style='color: red;'>錯誤：" + e.getMessage() + "</td></tr>");
                    e.printStackTrace();
                }
            %>
            <tr style="border-top:2px solid #e0e0e0;">
                <td colspan="11" style="text-align:center;padding:12px;">
                    <a href="add_invoice.jsp<%= isFiltered ? "?orderId=" + filterOrderId : "" %>" class="btn btn-primary">+ 新增應收帳款</a>
                </td>
            </tr>
        </tbody>
    </table>
    <div style="order:1;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= invTotalPages %>" totalCount="<%= invFilteredIdx %>" baseUrl="<%= invBaseUrl %>" position="top"/></div>
    <div style="order:3;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= invTotalPages %>" totalCount="<%= invFilteredIdx %>" baseUrl="<%= invBaseUrl %>"/></div>
    </div>
    <% } %>
    <% if (showUnpaid && "uninvoiced".equals(activeTab) && !isFiltered) {
        %>
        <%
            String unBaseUrl = "invoice_list.jsp?submitted=1"
                + (filterCustomerName != null && !filterCustomerName.trim().isEmpty() ? "&customerName=" + java.net.URLEncoder.encode(filterCustomerName.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
                + (showUnpaid ? "&unpaid=1" : "")
                + (activeTab != null && !activeTab.isEmpty() ? "&tab=" + activeTab : "");
        %>
        <div class="table-container" style="display:flex;flex-direction:column;padding:0;">
        <table style="order:2;width:100%;">
            <thead>
                <tr>
                    <th>序號</th>
                    <th>訂單編號</th>
                    <th>客戶名稱</th>
                    <th>產品</th>
                    <th>訂單金額</th>
                    <th>訂單日期</th>
                    <th>預計交期</th>
                    <th>操作</th>
                </tr>
            </thead>
            <tbody>
                <%
                    try {
                        InvoiceDao dao2 = new InvoiceDao();
                        List<Order> uninvoicedOrders = showUnpaid ? dao2.getShippedUnpaidUninvoicedOrders() : dao2.getShippedUninvoicedOrders();
                        SimpleDateFormat sdf2 = new SimpleDateFormat("yyyy-MM-dd");
                        if (filterCustomerName != null && !filterCustomerName.trim().isEmpty()) {
                            String kw = filterCustomerName.trim().toLowerCase();
                            List<Order> filtered = new java.util.ArrayList<>();
                            for (Order o : uninvoicedOrders) {
                                if (o.getCustomerName() != null && o.getCustomerName().toLowerCase().contains(kw)) {
                                    filtered.add(o);
                                }
                            }
                            uninvoicedOrders = filtered;
                        }
                        unTotalPages = 1;
                        unFilteredIdx = 0;
                        unDisplayed = 0;
                        for (Order o : uninvoicedOrders) {
                                unFilteredIdx++;
                                if (unFilteredIdx <= startIdx) continue;
                                if (unDisplayed >= pageSize) continue;
                                unDisplayed++;
                %>
                    <tr>
                        <td><%= unFilteredIdx %></td>
                        <td style="font-weight:700;"><%= o.getOrderNumber() != null ? o.getOrderNumber() : "-" %></td>
                        <td><b><%= o.getCustomerName() != null ? o.getCustomerName() : "-" %></b></td>
                        <td><%= o.getProductName() != null ? o.getProductName() : "-" %></td>
                        <td>$<%= NumberUtil.fmtMoney(o.getActualAmount() != null ? o.getActualAmount() : o.getTotalAmount()) %></td>
                        <td><%= o.getOrderDate() != null ? sdf2.format(o.getOrderDate()) : "-" %></td>
                        <td><%= o.getExpectedDeliveryDate() != null ? sdf2.format(o.getExpectedDeliveryDate()) : "-" %></td>
                        <td>
                            <a href="<%= request.getContextPath() %>/invoice/invoice_list.jsp?orderId=<%= o.getId() %>" class="btn btn-outline btn-sm" style="text-decoration:none;">查看帳款</a>
                        </td>
                    </tr>
                <%
                        }
                        if (uninvoicedOrders.isEmpty()) {
                %>
                            <tr>
                                <td colspan="8">
                                    <div class="empty-state">
                                        <p><%= showUnpaid ? "目前沒有已出貨未收款且未開帳的訂單" : "目前沒有已出貨但未開帳的訂單" %></p>
                                    </div>
                                </td>
                            </tr>
                <%
                        }
                        unTotalPages = unFilteredIdx > 0 ? (int) Math.ceil((double) unFilteredIdx / pageSize) : 1;
                        if (pageNum > unTotalPages) pageNum = unTotalPages;
                    } catch (Exception e) {
                    out.println("<tr><td colspan='8' style='color: red;'>錯誤：" + e.getMessage() + "</td></tr>");
                    e.printStackTrace();
                }
            %>
        </tbody>
    </table>
    <div style="order:1;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= unTotalPages %>" totalCount="<%= unFilteredIdx %>" baseUrl="<%= unBaseUrl %>" position="top"/></div>
    <div style="order:3;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= unTotalPages %>" totalCount="<%= unFilteredIdx %>" baseUrl="<%= unBaseUrl %>"/></div>
    </div>
    <% } %>

<div id="paymentModalOverlay" style="display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:10000;align-items:center;justify-content:center;">
    <div class="dialog-box">
        <h3 style="margin:0 0 20px;font-size:18px;color:#1a1a2e;border-bottom:2px solid #e9ecef;padding-bottom:12px;">編輯收款狀態</h3>
        <div style="margin-bottom:16px;font-size:14px;color:#6c757d;">單據編號：<span id="pmInvNumber" style="font-weight:600;color:#333;"></span></div>
        <form id="paymentForm" method="POST" action="<%= request.getContextPath() %>/InvoiceServlet">
            <input type="hidden" name="action" value="update_payment">
            <input type="hidden" name="id" id="pmInvoiceId">
            <div class="form-group">
                <label>收款狀態</label>
                <select name="paymentStatus" id="pmStatus" onchange="togglePaymentFields()">
                    <option value="0">未收款</option>
                    <option value="1">已收款 (已到帳)</option>
                </select>
            </div>
            <div id="pmReceivedFields" style="display:none;">
                <div class="form-group">
                    <label>實收金額</label>
                    <input type="number" name="receivedAmount" id="pmAmount" step="0.01" placeholder="請輸入實收金額">
                </div>
                <div class="form-group">
                    <label>收款日期</label>
                    <input type="date" name="paymentDate" id="pmDate">
                </div>
            </div>
            <div style="display:flex;justify-content:flex-end;gap:10px;margin-top:24px;">
                <button type="button" onclick="closePaymentModal()" style="padding:8px 24px;border:1px solid #6c757d;background:#fff;border-radius:6px;cursor:pointer;font-size:14px;">取消</button>
                <button type="submit" style="padding:8px 24px;border:none;background:#4361ee;color:#fff;border-radius:6px;cursor:pointer;font-size:14px;">儲存</button>
            </div>
        </form>
    </div>
</div>

<script>
function openPaymentModal(id, status, amount, date, invNum) {
    document.getElementById('pmInvoiceId').value = id;
    document.getElementById('pmInvNumber').textContent = invNum;
    document.getElementById('pmStatus').value = status;
    document.getElementById('pmAmount').value = amount;
    document.getElementById('pmDate').value = date;
    togglePaymentFields();
    document.getElementById('paymentModalOverlay').style.display = 'flex';
}

function closePaymentModal() {
    document.getElementById('paymentModalOverlay').style.display = 'none';
}

function togglePaymentFields() {
    var s = document.getElementById('pmStatus').value;
    document.getElementById('pmReceivedFields').style.display = s === '1' ? 'block' : 'none';
}

document.getElementById('paymentModalOverlay').onclick = function(e) {
    if (e.target === this) closePaymentModal();
};
</script>

<%@ include file="../include/footer.jsp" %>
