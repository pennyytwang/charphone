<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.math.BigDecimal, java.util.*, dao.OrderDao, util.NumberUtil, model.Customer, model.Product, java.text.SimpleDateFormat" %>
<% request.setAttribute("pageTitle", "訂單管理"); %>
<% request.setAttribute("pageIcon", "☰"); %>
<% request.setAttribute("pageSubtitle", "建立與追蹤客戶訂單，掌握生產與出貨狀態"); %>
<%@ include file="../include/header.jsp" %>
<%@ taglib prefix="my" tagdir="/WEB-INF/tags" %>

<%!
    int toInt(Object v) { return v instanceof Number ? ((Number)v).intValue() : 0; }
    double toDbl(Object v) { return v instanceof Number ? ((Number)v).doubleValue() : 0.0; }
    BigDecimal toBd(Object v) { return v instanceof BigDecimal ? (BigDecimal)v : (v instanceof Number ? BigDecimal.valueOf(((Number)v).doubleValue()) : null); }
%>

<%
    String msg = request.getParameter("message");
    String err = request.getParameter("error");
    String alertMsg = null;
    String alertType = null;
    if ("success".equals(msg)) { alertMsg = "訂單資料已儲存！"; alertType = "success"; }
    else if ("deleted".equals(msg)) { alertMsg = "訂單已刪除！"; alertType = "success"; }
    else if ("closed".equals(msg)) { alertMsg = "訂單已結案！"; alertType = "success"; }
    else if ("unclosed".equals(msg)) { alertMsg = "訂單已重開！"; alertType = "success"; }
    else if ("close_not_found".equals(err)) { alertMsg = "找不到訂單。"; alertType = "danger"; }
    else if ("close_not_delivered".equals(err)) { alertMsg = "出貨未完成，無法結案。"; alertType = "danger"; }
    else if ("close_not_paid".equals(err)) { alertMsg = "尚有應收帳款未收款，無法結案。"; alertType = "danger"; }
    else if ("delete_has_relations".equals(err)) { alertMsg = "此訂單已有關聯資料，無法刪除。"; alertType = "danger"; }
    else if ("delete_no_selection".equals(err)) { alertMsg = "未選擇任何訂單。"; alertType = "danger"; }
    else if ("cancel_not_found".equals(err)) { alertMsg = "找不到訂單。"; alertType = "danger"; }
    else if ("cancel_has_productions".equals(err)) { alertMsg = "此訂單已有生產紀錄，無法取消。"; alertType = "danger"; }
    else if ("cancel_has_deliveries".equals(err)) { alertMsg = "此訂單已有出貨紀錄，無法取消。"; alertType = "danger"; }
    else if ("cancel_has_invoices".equals(err)) { alertMsg = "此訂單已有帳務紀錄，無法取消。"; alertType = "danger"; }
    else if ("cancel_has_inventory".equals(err)) { alertMsg = "此訂單已有庫存異動紀錄，無法取消。"; alertType = "danger"; }
    else if ("exception".equals(err)) { alertMsg = "系統發生錯誤，請稍後再試。"; alertType = "danger"; }
%>

<%
    java.text.SimpleDateFormat sdfFilter = new java.text.SimpleDateFormat("yyyy-MM-dd");
    Calendar calF = Calendar.getInstance();

    calF.add(Calendar.DAY_OF_MONTH, -30);
    String defaultDateFrom = sdfFilter.format(calF.getTime());

    calF = Calendar.getInstance();
    calF.add(Calendar.DAY_OF_MONTH, 30);
    String defaultDateTo = sdfFilter.format(calF.getTime());

    calF = Calendar.getInstance();
    calF.add(Calendar.DAY_OF_MONTH, -1);
    String defaultExpFrom = sdfFilter.format(calF.getTime());

    calF = Calendar.getInstance();
    calF.add(Calendar.DAY_OF_MONTH, 14);
    String defaultExpTo = sdfFilter.format(calF.getTime());

    String submitted = request.getParameter("submitted");
    boolean isSubmitted = submitted != null;

    String useOrderDate = request.getParameter("useOrderDate");
    String useExpectedDate = request.getParameter("useExpectedDate");
    String dateFrom = request.getParameter("dateFrom");
    String dateTo = request.getParameter("dateTo");
    String expectedDateFrom = request.getParameter("expectedDateFrom");
    String expectedDateTo = request.getParameter("expectedDateTo");
    String customerName = request.getParameter("customerName");
    String productKeyword = request.getParameter("productKeyword");
    String filterOrderNumber = request.getParameter("orderNumber");
    String filterProdStatus = request.getParameter("prodStatus");
    String filterDelivStatus = request.getParameter("delivStatus");
    String filterCloseStatus = request.getParameter("closeStatus");
    String filterPaymentStatus = request.getParameter("paymentStatus");
    String filterOrderId = request.getParameter("orderId");

    if (!isSubmitted) {
        dateFrom = defaultDateFrom;
        dateTo = defaultDateTo;
        expectedDateFrom = defaultExpFrom;
        expectedDateTo = defaultExpTo;
        filterCloseStatus = "0";
    }

    int pageNum = 1;
    int pageSize = 20;
    String pageParam = request.getParameter("page");
    if (pageParam != null) {
        try { pageNum = Integer.parseInt(pageParam); if (pageNum < 1) pageNum = 1; } catch (NumberFormatException e) {}
    }
    int startIdx = (pageNum - 1) * pageSize;
    int totalPages = 1;
    int filteredIdx = 0;
    int displayed = 0;
    String baseUrl = "order_list.jsp?submitted=1"
        + ("on".equals(useOrderDate) ? "&useOrderDate=on" : "")
        + (dateFrom != null && !dateFrom.isEmpty() ? "&dateFrom=" + dateFrom : "")
        + (dateTo != null && !dateTo.isEmpty() ? "&dateTo=" + dateTo : "")
        + ("on".equals(useExpectedDate) ? "&useExpectedDate=on" : "")
        + (expectedDateFrom != null && !expectedDateFrom.isEmpty() ? "&expectedDateFrom=" + expectedDateFrom : "")
        + (expectedDateTo != null && !expectedDateTo.isEmpty() ? "&expectedDateTo=" + expectedDateTo : "")
        + (filterOrderNumber != null && !filterOrderNumber.trim().isEmpty() ? "&orderNumber=" + java.net.URLEncoder.encode(filterOrderNumber.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
        + (customerName != null && !customerName.trim().isEmpty() ? "&customerName=" + java.net.URLEncoder.encode(customerName.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
        + (productKeyword != null && !productKeyword.trim().isEmpty() ? "&productKeyword=" + java.net.URLEncoder.encode(productKeyword.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
        + (filterProdStatus != null && !filterProdStatus.isEmpty() ? "&prodStatus=" + filterProdStatus : "")
        + (filterDelivStatus != null && !filterDelivStatus.isEmpty() ? "&delivStatus=" + filterDelivStatus : "")
        + (filterCloseStatus != null && !filterCloseStatus.isEmpty() ? "&closeStatus=" + filterCloseStatus : "")
        + (filterPaymentStatus != null && !filterPaymentStatus.isEmpty() ? "&paymentStatus=" + filterPaymentStatus : "")
        + (filterOrderId != null && !filterOrderId.isEmpty() ? "&orderId=" + filterOrderId : "");
%>
<%
    boolean isFilteredByOrderId = filterOrderId != null && !filterOrderId.isEmpty();
%>
<% if (!isFilteredByOrderId) { %>
<form class="filter-bar" method="GET">
    <input type="hidden" name="submitted" value="1">

    <div class="field-check">
        <label class="check-label">
            <input type="checkbox" name="useOrderDate" <%= "on".equals(useOrderDate) ? "checked" : "" %>>
            訂單日期
        </label>
    </div>
    <div class="field">
        <input type="date" name="dateFrom" value="<%= dateFrom != null ? dateFrom : "" %>">
    </div>
    <span style="padding:0 4px;line-height:32px;">~</span>
    <div class="field">
        <input type="date" name="dateTo" value="<%= dateTo != null ? dateTo : "" %>">
    </div>

    <div class="field-check">
        <label class="check-label">
            <input type="checkbox" name="useExpectedDate" <%= "on".equals(useExpectedDate) ? "checked" : "" %>>
            交期
        </label>
    </div>
    <div class="field">
        <input type="date" name="expectedDateFrom" value="<%= expectedDateFrom != null ? expectedDateFrom : "" %>">
    </div>
    <span style="padding:0 4px;line-height:32px;">~</span>
    <div class="field">
        <input type="date" name="expectedDateTo" value="<%= expectedDateTo != null ? expectedDateTo : "" %>">
    </div>

    <div style="width:100%"></div>
    <div class="field">
        <label>客戶名稱</label>
        <input type="text" name="customerName" value="<%= customerName != null ? customerName : "" %>" placeholder="輸入客戶名稱">
    </div>
    <div class="field">
        <label>訂單編號</label>
        <input type="text" name="orderNumber" value="<%= filterOrderNumber != null ? filterOrderNumber : "" %>" placeholder="訂單編號">
    </div>
    <div class="field">
        <label>品項/規格</label>
        <input type="text" name="productKeyword" value="<%= productKeyword != null ? productKeyword : "" %>" placeholder="品項名稱">
    </div>
    <div class="field">
        <label>生產狀態</label>
        <select name="prodStatus">
            <option value="">全部</option>
            <option value="0" <%= "0".equals(filterProdStatus) ? "selected" : "" %>>未立工單</option>
            <option value="1" <%= "1".equals(filterProdStatus) ? "selected" : "" %>>待生產</option>
            <option value="2" <%= "2".equals(filterProdStatus) ? "selected" : "" %>>生產中</option>
            <option value="3" <%= "3".equals(filterProdStatus) ? "selected" : "" %>>已完成</option>
        </select>
    </div>
    <div class="field">
        <label>出貨狀態</label>
        <select name="delivStatus">
            <option value="">全部</option>
            <option value="0" <%= "0".equals(filterDelivStatus) ? "selected" : "" %>>未出貨</option>
            <option value="1" <%= "1".equals(filterDelivStatus) ? "selected" : "" %>>部分出貨</option>
            <option value="2" <%= "2".equals(filterDelivStatus) ? "selected" : "" %>>已出貨</option>
        </select>
    </div>
    <div class="field">
        <label>結案狀態</label>
        <select name="closeStatus">
            <option value="">全部</option>
            <option value="0" <%= "0".equals(filterCloseStatus) ? "selected" : "" %>>未結案</option>
            <option value="1" <%= "1".equals(filterCloseStatus) ? "selected" : "" %>>已結案</option>
        </select>
    </div>
    <div class="field">
        <label>帳務狀態</label>
        <select name="paymentStatus">
            <option value="">全部</option>
            <option value="shipped_unpaid" <%= "shipped_unpaid".equals(filterPaymentStatus) ? "selected" : "" %>>已出貨未收款</option>
            <option value="shipped_paid" <%= "shipped_paid".equals(filterPaymentStatus) ? "selected" : "" %>>已出貨已收款</option>
        </select>
    </div>
    <button type="submit" class="btn-search">查詢</button>
    <a href="order_list.jsp" class="btn-clear">清除</a>
</form>
<% } else { %>
<div style="margin-bottom:16px;">
    <a href="order_list.jsp?submitted=1" class="btn btn-outline" style="text-decoration:none;">← 返回全部訂單</a>
</div>
<% } %>

<div style="display:flex;justify-content:flex-end;margin-bottom:16px;">
    <button onclick="openAddModal()" class="btn btn-primary">+ 新增訂單</button>
</div>

<div class="table-container" style="display:flex;flex-direction:column;padding:0;">
<table style="order:2;width:100%;">
    <thead>
        <tr>
            <th>序號</th>
            <th>訂單 / 客戶</th>
            <th>品項及下單總量</th>
            <th>實際應收</th>
            <th>交期</th>
            <th>生產狀態</th>
            <th>出貨狀態</th>
            <th>帳務</th>
            <th>結案</th>
            <th>操作</th>
        </tr>
    </thead>
    <tbody>
        <%
            totalPages = 1;
            filteredIdx = 0;
            displayed = 0;

            try {
                OrderDao orderDao = new OrderDao();
                List<Map<String, Object>> orderList = orderDao.getOrderList(
                    "on".equals(useOrderDate), dateFrom, dateTo,
                    "on".equals(useExpectedDate), expectedDateFrom, expectedDateTo,
                    customerName, filterOrderNumber, productKeyword,
                    filterCloseStatus, filterOrderId, filterPaymentStatus
                );

                boolean hasData = false;
                for (Map<String, Object> row : orderList) {
                    int prodCount = toInt(row.get("prod_count"));
                    int prodWaiting = toInt(row.get("prod_waiting"));
                    int prodInProgress = toInt(row.get("prod_in_progress"));
                    int prodCompleted = toInt(row.get("prod_completed"));
                    int prodCancelled = toInt(row.get("prod_cancelled"));
                    double orderQty = toDbl(row.get("quantity"));
                    int prodStatus;
                    String prodStatusLabel, prodBadgeClass;
                    if (prodCount == 0) {
                        prodStatus = 0; prodStatusLabel = "未立工單"; prodBadgeClass = "badge-gray";
                    } else if (prodWaiting == prodCount) {
                        prodStatus = 1; prodStatusLabel = "待生產"; prodBadgeClass = "badge-blue";
                    } else if (prodCompleted == prodCount) {
                        prodStatus = 3; prodStatusLabel = "已完成"; prodBadgeClass = "badge-green";
                    } else {
                        prodStatus = 2;
                        StringBuilder sb = new StringBuilder();
                        if (prodWaiting > 0) { if (sb.length() > 0) sb.append(", "); sb.append("待生產:").append(prodWaiting); }
                        if (prodInProgress > 0) { if (sb.length() > 0) sb.append(", "); sb.append("進行中:").append(prodInProgress); }
                        if (prodCompleted > 0) { if (sb.length() > 0) sb.append(", "); sb.append("已完成:").append(prodCompleted); }
                        if (prodCancelled > 0) { if (sb.length() > 0) sb.append(", "); sb.append("已取消:").append(prodCancelled); }
                        prodStatusLabel = sb.toString();
                        prodBadgeClass = "badge-orange";
                    }

                    double delivQty = toDbl(row.get("total_delivered"));
                    int delivStatus;
                    String delivStatusLabel, delivBadgeClass;
                    if (delivQty <= 0) {
                        delivStatus = 0; delivStatusLabel = "未出貨"; delivBadgeClass = "badge-gray";
                    } else if (delivQty >= orderQty) {
                        delivStatus = 2; delivStatusLabel = "已出貨"; delivBadgeClass = "badge-green";
                    } else {
                        delivStatus = 1; int delPct = (int)Math.round(delivQty / orderQty * 100);
                        delivStatusLabel = "部分出貨 (" + delPct + "%)"; delivBadgeClass = "badge-orange";
                    }

                    if (filterProdStatus != null && !filterProdStatus.isEmpty() && !filterProdStatus.equals(String.valueOf(prodStatus))) continue;
                    if (filterDelivStatus != null && !filterDelivStatus.isEmpty() && !filterDelivStatus.equals(String.valueOf(delivStatus))) continue;

                    filteredIdx++;
                    if (filteredIdx <= startIdx) continue;
                    if (displayed >= pageSize) continue;
                    displayed++;

                    hasData = true;

                    BigDecimal actual = toBd(row.get("actual_amount"));
                    BigDecimal totalAmt = toBd(row.get("total_amount"));
                    String diffReason = (String) row.get("amount_diff_reason");
                    boolean hasDiff = actual != null && totalAmt != null && actual.compareTo(totalAmt) != 0;
                    int closeSt = toInt(row.get("close_status"));
                    int deliveryCount = toInt(row.get("delivery_count"));
                    int invCount = toInt(row.get("invoice_count"));
                    int invTxnCount = toInt(row.get("inv_txn_count"));
                    boolean canDelete = closeSt == 0 && prodCount == 0 && deliveryCount == 0 && invCount == 0 && invTxnCount == 0;
                    String deleteDisableReason = "";
                    if (!canDelete) {
                        List<String> reasons = new ArrayList<>();
                        if (closeSt == 1) reasons.add("已結案");
                        if (prodCount > 0) reasons.add("已有工單");
                        if (deliveryCount > 0) reasons.add("已有出貨紀錄");
                        if (invCount > 0) reasons.add("已有帳務紀錄");
                        if (invTxnCount > 0) reasons.add("已有庫存異動");
                        deleteDisableReason = String.join("、", reasons);
                    }

                    int id = toInt(row.get("id"));
                    String orderNumber = (String) row.get("order_number");
                    String customerNameVal = (String) row.get("customer_name");
                    String productNameVal = (String) row.get("product_name");
                    int priceType = toInt(row.get("price_type"));
                    BigDecimal unitPrice = toBd(row.get("unit_price"));
                    BigDecimal unitWeight = toBd(row.get("unit_weight"));
                    BigDecimal quantity = toBd(row.get("quantity"));
                    java.sql.Date orderDate = (java.sql.Date) row.get("order_date");
                    java.sql.Date expectedDeliveryDate = (java.sql.Date) row.get("expected_delivery_date");
                    java.sql.Date deliveryDate = (java.sql.Date) row.get("delivery_date");
                    BigDecimal totalProduced = toBd(row.get("total_produced"));
                    BigDecimal totalReceived = toBd(row.get("total_received"));
                    BigDecimal totalInvoiced = toBd(row.get("total_invoiced"));
                    int paidInvoiceCount = toInt(row.get("paid_invoice_count"));
                    int invoiceCount = toInt(row.get("invoice_count"));
                    BigDecimal productStock = toBd(row.get("product_stock"));

                    String orderDataJson = "{"
                        + "\"id\":" + id + ","
                        + "\"orderNumber\":\"" + (orderNumber != null ? orderNumber.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n").replace("\r","\\r").replace("\t","\\t") : "") + "\","
                        + "\"customerName\":\"" + (customerNameVal != null ? customerNameVal.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n").replace("\r","\\r").replace("\t","\\t") : "") + "\","
                        + "\"productName\":\"" + (productNameVal != null ? productNameVal.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n").replace("\r","\\r").replace("\t","\\t") : "") + "\","
                        + "\"priceType\":" + priceType + ","
                        + "\"unitPrice\":\"" + NumberUtil.fmtQty(toDbl(unitPrice)) + "\","
                        + "\"unitWeight\":" + (unitWeight != null ? "\"" + NumberUtil.fmtQty(unitWeight.doubleValue()) + "\"" : "null") + ","
                        + "\"quantity\":\"" + NumberUtil.fmtQty(toDbl(quantity)) + "\","
                        + "\"totalAmount\":\"" + NumberUtil.fmtQty(toDbl(totalAmt)) + "\","
                        + "\"actualAmount\":" + (actual != null ? "\"" + actual + "\"" : "null") + ","
                        + "\"amountDiffReason\":\"" + (diffReason != null ? diffReason.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n").replace("\r","\\r").replace("\t","\\t") : "") + "\","
                        + "\"hasDiff\":" + hasDiff + ","
                        + "\"orderDate\":\"" + (orderDate != null ? orderDate : "") + "\","
                        + "\"expectedDeliveryDate\":\"" + (expectedDeliveryDate != null ? expectedDeliveryDate : "") + "\","
                        + "\"deliveryDate\":\"" + (deliveryDate != null ? deliveryDate : "") + "\","
                        + "\"closeStatus\":" + closeSt + ","
                        + "\"prodStatusLabel\":\"" + (prodStatusLabel != null ? prodStatusLabel.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n").replace("\r","\\r").replace("\t","\\t") : "") + "\","
                        + "\"delivStatusLabel\":\"" + (delivStatusLabel != null ? delivStatusLabel.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n").replace("\r","\\r").replace("\t","\\t") : "") + "\","
                        + "\"prodBadgeClass\":\"" + prodBadgeClass + "\","
                        + "\"delivBadgeClass\":\"" + delivBadgeClass + "\","
                        + "\"totalDelivered\":\"" + NumberUtil.fmtQty(delivQty) + "\","
                        + "\"totalInvoiced\":\"" + NumberUtil.fmtQty(toDbl(totalInvoiced)) + "\","
                        + "\"orderQty\":\"" + NumberUtil.fmtQty(orderQty) + "\","
                        + "\"totalProduced\":\"" + NumberUtil.fmtQty(toDbl(totalProduced)) + "\","
                        + "\"totalReceived\":\"" + NumberUtil.fmtQty(toDbl(totalReceived)) + "\","
                        + "\"paidInvoiceCount\":" + paidInvoiceCount + ","
                        + "\"invoiceCount\":" + invoiceCount + ""
                        + "}";
        %>
        <tr data-order="<%= orderDataJson.replace("\"", "&quot;") %>">
            <td><%= filteredIdx %></td>
            <td>
                <div class="order-cell">
                    <% if (closeSt == 0) { %>
                        <span class="order-number" style="cursor:pointer;text-decoration:underline;" onclick="openEditModal(<%= id %>)"><%= orderNumber %></span>
                    <% } else { %>
                        <span class="order-number"><%= orderNumber %></span>
                    <% } %>
                    <span class="customer-name"><%= customerNameVal %></span>
                </div>
            </td>
            <td>
                <div class="product-cell">
                    <span class="product-name"><%= productNameVal %></span>
                    <span class="product-spec" style="display:block;font-size:12px;color:#6c757d;"><%= NumberUtil.fmtQty(toDbl(quantity)) %> <%= priceType == 1 ? "kg" : "pcs" %></span>
                </div>
            </td>
            <td>
                <div class="amount-cell">
                    <span class="amount-actual <%= hasDiff ? "diff" : "same" %>">
                        $<%= actual != null ? NumberUtil.fmtMoney(actual.doubleValue()) : NumberUtil.fmtMoney(toDbl(totalAmt)) %>
                        <%= hasDiff ? " ⚠" : "" %>
                    </span>
                    <% if (hasDiff && diffReason != null && !diffReason.isEmpty()) { %>
                        <span class="diff-reason"><%= diffReason %></span>
                    <% } %>
                </div>
            </td>
            <td>
                <span class="delivery-date <%= expectedDeliveryDate != null && expectedDeliveryDate.before(new java.util.Date()) ? "past" : "" %>">
                    <%= expectedDeliveryDate != null ? expectedDeliveryDate : "-" %>
                </span>
            </td>
            <td><a href="../production/production_list.jsp?orderId=<%= id %>" class="badge <%= prodBadgeClass %>" style="text-decoration:none;cursor:pointer;"><%= prodStatusLabel %></a></td>
            <td>
                <a href="../delivery/delivery_list.jsp?orderId=<%= id %>" style="text-decoration:none;cursor:pointer;">
                    <span class="badge <%= delivBadgeClass %>"><%= delivStatusLabel %></span>
                    <% if (delivStatus != 2) { %>
                        <span style="display:block;font-size:11px;color:#6c757d;margin-top:4px;">
                            存貨 <%= NumberUtil.fmtQty(toDbl(productStock)) %> <%= priceType == 1 ? "kg" : "pcs" %><br>
                            未出貨 <%= NumberUtil.fmtQty(orderQty - delivQty) %> <%= priceType == 1 ? "kg" : "pcs" %>
                        </span>
                    <% } %>
                </a>
            </td>
            <td>
                <%
                    BigDecimal orderAmt = actual != null ? actual : totalAmt;
                    BigDecimal invoicedAmt = totalInvoiced;
                    BigDecimal receivedAmt = totalReceived;
                    BigDecimal remainingAmt = orderAmt != null ? orderAmt.subtract(invoicedAmt != null ? invoicedAmt : BigDecimal.ZERO) : BigDecimal.ZERO;
                %>
                <a href="../invoice/invoice_list.jsp?orderId=<%= id %>" style="text-decoration:none;">
                <div class="amount-cell" style="cursor:pointer;">
                    <% if (invCount == 0) { %>
                        <span class="badge badge-gray">未開帳</span>
                    <% } else { %>
                        <span style="font-size:12px;color:#495057;">帳 $<%= NumberUtil.fmtMoney(toDbl(invoicedAmt)) %></span>
                        <span style="font-size:12px;color:#495057;">收 $<%= NumberUtil.fmtMoney(toDbl(receivedAmt)) %></span>
                        <% if (receivedAmt != null && receivedAmt.compareTo(orderAmt.subtract(new BigDecimal("0.01"))) >= 0) { %>
                            <span class="badge badge-green">全收</span>
                        <% } else if (receivedAmt != null && receivedAmt.compareTo(BigDecimal.ZERO) > 0) { %>
                            <span class="badge badge-orange">部分收</span>
                        <% } else { %>
                            <span class="badge badge-red">未收</span>
                        <% } %>
                        <% if (remainingAmt.compareTo(BigDecimal.ZERO) > 0) { %>
                            <span style="display:block;font-size:11px;color:#6c757d;margin-top:4px;">未開帳 $<%= NumberUtil.fmtMoney(remainingAmt.doubleValue()) %></span>
                        <% } %>
                    <% } %>
                </div>
                </a>
            </td>
            <td>
                <% if (closeSt == 1) { %>
                    <a href="<%= request.getContextPath() %>/OrderServlet?action=unclose&id=<%= id %>" class="badge badge-green" style="text-decoration:none;cursor:pointer;" onclick="return confirm('確定重開此訂單？')">已結案</a>
                <% } else { %>
                    <a href="<%= request.getContextPath() %>/OrderServlet?action=close&id=<%= id %>" class="badge badge-gray" style="text-decoration:none;cursor:pointer;" onclick="return confirm('確定結案此訂單？')">未結案</a>
                <% } %>
            </td>
            <td>
                <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap;">
                    <% if (closeSt == 0 && canDelete) { %>
                        <a href="<%= request.getContextPath() %>/OrderServlet?action=delete&id=<%= id %>" class="btn btn-danger btn-sm" onclick="return confirm('確定刪除此訂單？此操作無法復原。')">刪除</a>
                    <% } else { %>
                        <span class="btn btn-danger btn-sm disabled" style="opacity:0.4;cursor:not-allowed;" title="<%= deleteDisableReason %>">刪除</span>
                    <% } %>
                    <% if (closeSt == 1) { %>
                        <a href="<%= request.getContextPath() %>/OrderServlet?action=unclose&id=<%= id %>" class="btn btn-outline btn-sm" onclick="return confirm('確定重開此訂單？')">重開訂單</a>
                    <% } %>
                </div>
            </td>
        </tr>
        <%
            }
                if (!hasData) {
                    boolean hasFilter = isSubmitted && (
                        ("on".equals(useOrderDate) && ((dateFrom != null && !dateFrom.isEmpty()) || (dateTo != null && !dateTo.isEmpty())))
                        || ("on".equals(useExpectedDate) && ((expectedDateFrom != null && !expectedDateFrom.isEmpty()) || (expectedDateTo != null && !expectedDateTo.isEmpty())))
                        || (customerName != null && !customerName.trim().isEmpty())
                        || (filterOrderNumber != null && !filterOrderNumber.trim().isEmpty())
                        || (productKeyword != null && !productKeyword.trim().isEmpty())
                        || (filterProdStatus != null && !filterProdStatus.isEmpty())
                        || (filterDelivStatus != null && !filterDelivStatus.isEmpty())
                        || (filterCloseStatus != null && !filterCloseStatus.isEmpty())
                    );
        %>
        <tr>
            <td colspan="10">
                <div class="empty-state">
                    <% if (hasFilter) { %>
                        <p>無符合條件的訂單</p>
                        <a href="order_list.jsp" class="btn btn-outline" style="margin-top:16px;">清除篩選條件</a>
                    <% } else { %>
                        <p>尚無訂單資料</p>
                        <button onclick="openAddModal()" class="btn btn-primary" style="margin-top:16px;">+ 新增第一筆訂單</button>
                    <% } %>
                </div>
            </td>
        </tr>
        <%
                }
                totalPages = filteredIdx > 0 ? (int) Math.ceil((double) filteredIdx / pageSize) : 1;
                if (pageNum > totalPages) pageNum = totalPages;
            } catch (Exception e) {
                out.println("<tr><td colspan='9' style='padding:20px;color:#dc3545;'>錯誤：" + e.getMessage() + "</td></tr>");
                e.printStackTrace();
            }
        %>
    </tbody>
</table>
<div style="order:1;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= totalPages %>" totalCount="<%= filteredIdx %>" baseUrl="<%= baseUrl %>" position="top"/></div>
<div style="order:3;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= totalPages %>" totalCount="<%= filteredIdx %>" baseUrl="<%= baseUrl %>"/></div>
</div>


<script>
var CTX = '<%= request.getContextPath() %>';

function formatAmountField(el) {
    var v = el.value.replace(/[^0-9.\-]/g, '');
    if (v && !isNaN(parseFloat(v))) el.value = fmtQtyDisplay(v);
}
function parseAmountField(el) {
    el.value = el.value.replace(/[^0-9.\-]/g, '');
}

// Embedded reference data
var customers = [];
var products = [];
<%
OrderDao _dao = new OrderDao();
try {
    for (Customer c : _dao.getCustomers()) {
        String num = c.getCustomerNumber();
        String name = c.getCustomerName();
%>
customers.push({id:<%= c.getId() %>, number:'<%= num != null ? num.replace("\\", "\\\\").replace("'", "\\'") : "" %>', name:'<%= name != null ? name.replace("\\", "\\\\").replace("'", "\\'") : "" %>'});
<% } %>
<%
    for (Product p : _dao.getProducts()) {
%>
products.push({id:<%= p.getId() %>, code:'<%= p.getProductCode() != null ? p.getProductCode().replace("\\", "\\\\").replace("'", "\\'") : "" %>', name:'<%= p.getProductName().replace("\\", "\\\\").replace("'", "\\'") %>', ptype:<%= p.getPriceType() %>, price:'<%= p.getUnitPrice() != null ? NumberUtil.fmtQty(p.getUnitPrice().doubleValue()) : "" %>', weight:'<%= p.getUnitWeight() != null ? NumberUtil.fmtQty(p.getUnitWeight().doubleValue()) : "" %>'});
<% }
} catch (Exception _ex) { _ex.printStackTrace(); }
%>

var overlay, box, title, errDiv, formHTML;

formHTML = '<form id="orderForm">'
    + '<input type="hidden" name="id" id="orderId">'
    + '<div class="form-group"><label>客戶名稱：</label>'
    + '<select name="customerId" id="customerId" required onchange="generateOrderNumber()"><option value="">-- 請選擇客戶 --</option></select></div>'
    + '<div class="form-group"><label>訂單編號：</label>'
    + '<input type="text" name="orderNumber" id="orderNumber" readonly placeholder="選擇客戶後自動產生"></div>'
    + '<div class="form-group"><label>品項：</label>'
    + '<select name="productId" id="productId" required onchange="fillProductInfo()"><option value="">-- 請選擇品項 --</option></select></div>'
    + '<div class="form-group"><label>計價方式：</label>'
    + '<select name="priceType" id="priceType" onchange="updateLabels();calcTotal()">'
    + '<option value="2">按個數 (pcs)</option><option value="1">按重量 (kg)</option></select></div>'
    + '<div style="display:flex;gap:12px;"><div class="form-group" style="flex:1;">'
    + '<span style="display:inline-flex;align-items:center;gap:4px;">'
    + '<label id="weightLabel" style="margin-bottom:0;">單個重量 (kg)：</label>'
    + '<button type="button" onclick="toggleWeightEdit()" class="btn-toggle" title="切換為可修改">✎</button>'
    + '</span>'
    + '<input type="text" name="unitWeight" id="unitWeight" readonly onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="calcTotal()"></div>'
    + '<div class="form-group" style="flex:1;">'
    + '<span style="display:inline-flex;align-items:center;gap:4px;">'
    + '<label id="unitLabel" style="margin-bottom:0;">單價 (/pcs)：</label>'
    + '<button type="button" onclick="togglePriceEdit()" class="btn-toggle" title="切換為可修改">✎</button>'
    + '</span>'
    + '<input type="text" name="unitPrice" id="unitPrice" readonly onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="calcTotal()"></div></div>'
    + '<div class="form-group"><label>客戶下單量：</label>'
    + '<input type="text" name="quantity" id="quantity" required onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="calcTotal()"></div>'
    + '<div class="form-group"><label>預計應收金額：</label>'
    + '<input type="text" id="totalAmountDisplay" readonly value="$0.00" style="background:#f8f9fa!important;">'
    + '<input type="hidden" name="totalAmount" id="totalAmount" value="0"></div>'
    + '<div class="form-group"><label>實際應收金額：</label>'
    + '<input type="text" name="actualAmount" id="actualAmount" inputmode="decimal" placeholder="如有差異請填寫實際金額" onfocus="parseAmountField(this)" onblur="formatAmountField(this)" onchange="checkAmountDiff()"></div>'
    + '<div class="form-group" id="diffReasonGroup" style="display:none;"><label>金額差異原因：</label>'
    + '<textarea name="amountDiffReason" id="amountDiffReason" rows="2"></textarea></div>'
    + '<div class="form-group"><label>交期：</label>'
    + '<input type="date" name="expectedDeliveryDate" id="expectedDeliveryDate"></div>'
    + '<input type="hidden" name="orderDate" id="orderDate">'
    + '<input type="hidden" name="deliveryDate" id="deliveryDate">'
    + '<div class="form-group"><label>備註：<button type="button" id="noteToggleBtn" onclick="toggleNote()" style="background:none;border:1px solid #6c757d;color:#6c757d;border-radius:4px;padding:1px 8px;margin-left:8px;cursor:pointer;font-size:13px;">+</button></label>'
    + '<textarea name="note" id="note" rows="3" style="display:none;"></textarea></div>'
    + '<button type="button" onclick="submitForm()" class="btn-submit" id="submitBtn">確認新增</button>'
    + '<button type="button" onclick="closeModal()" class="btn-cancel">取消</button>'
    + '</form>';

function populateDropdowns() {
    var custSel = document.getElementById('customerId');
    for (var i = 0; i < customers.length; i++) {
        var opt = document.createElement('option');
        opt.value = customers[i].id;
        opt.textContent = customers[i].name;
        custSel.appendChild(opt);
    }
    var prodSel = document.getElementById('productId');
    for (var i = 0; i < products.length; i++) {
        var opt = document.createElement('option');
        opt.value = products[i].id;
        opt.setAttribute('data-ptype', products[i].ptype);
        opt.setAttribute('data-price', products[i].price);
        opt.setAttribute('data-weight', products[i].weight);
        opt.textContent = products[i].name + (products[i].code ? ' (' + products[i].code + ')' : '');
        prodSel.appendChild(opt);
    }
}

function initModal() {
    overlay = document.createElement('div');
    overlay.style.cssText = 'display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(200,200,200,0.5);z-index:9999;align-items:center;justify-content:center;';
    overlay.className = 'modal-overlay';
    // overlay 點擊不再關閉，改由取消按鈕關閉

    box = document.createElement('div');
    box.style.cssText = 'background:#fff;border-radius:12px;box-shadow:0 8px 32px rgba(0,0,0,0.15);padding:30px 35px 35px;width:500px;max-width:90vw;max-height:85vh;overflow-y:auto;';
    box.className = 'modal-wrap';

    title = document.createElement('h3');
    title.id = 'modalTitle';
    title.textContent = '新增訂單';
    title.style.cssText = 'margin:0 0 24px;font-size:20px;font-weight:600;color:#1a1a2e;padding-bottom:12px;border-bottom:2px solid #e9ecef;cursor:move;user-select:none;';

    errDiv = document.createElement('div');
    errDiv.id = 'formError';
    errDiv.style.cssText = 'display:none;padding:12px;border-radius:8px;margin-bottom:16px;text-align:center;font-size:14px;background:#fff5f5;color:#dc3545;border:1px solid #ffe0e0;';

    box.appendChild(title);
    box.appendChild(errDiv);
    box.insertAdjacentHTML('beforeend', formHTML);
    overlay.appendChild(box);
    document.body.appendChild(overlay);

    populateDropdowns();

    // Draggable
    var dragActive = false, dsx, dsy, dOx, dOy;
    title.addEventListener('mousedown', function(e) {
        if (e.button !== 0) return;
        var r = box.getBoundingClientRect();
        box.style.left = r.left + 'px';
        box.style.top = r.top + 'px';
        box.style.transform = 'none';
        dsx = e.clientX; dsy = e.clientY;
        dOx = r.left; dOy = r.top;
        dragActive = true;
        e.preventDefault();
    });
    document.addEventListener('mousemove', function(e) {
        if (!dragActive) return;
        box.style.left = (dOx + e.clientX - dsx) + 'px';
        box.style.top = (dOy + e.clientY - dsy) + 'px';
    });
    document.addEventListener('mouseup', function() { dragActive = false; });
}

function openAddModal() {
    if (!overlay) initModal();
    overlay.style.display = 'flex';
    title.textContent = '新增訂單';
    document.getElementById('orderForm').reset();
    document.getElementById('orderId').value = '';
    errDiv.style.display = 'none';
    document.getElementById('submitBtn').disabled = false;
    document.getElementById('submitBtn').textContent = '新增';
    document.getElementById('totalAmountDisplay').value = '$0.00';
    document.getElementById('totalAmount').value = '0';
    document.getElementById('diffReasonGroup').style.display = 'none';
    document.getElementById('customerId').disabled = false;
    var noteTa = document.getElementById('note');
    noteTa.style.display = 'none';
    document.getElementById('noteToggleBtn').textContent = '+';
    var today = new Date();
    var ds = today.getFullYear() + '-' + String(today.getMonth()+1).padStart(2,'0') + '-' + String(today.getDate()).padStart(2,'0');
    document.getElementById('orderDate').value = ds;
    var exp = new Date(today.getTime() + 14 * 24 * 60 * 60 * 1000);
    document.getElementById('expectedDeliveryDate').value = exp.getFullYear() + '-' + String(exp.getMonth()+1).padStart(2,'0') + '-' + String(exp.getDate()).padStart(2,'0');
}

function openEditModal(id) {
    if (!overlay) initModal();
    overlay.style.display = 'flex';
    title.textContent = '編輯訂單';
    errDiv.style.display = 'none';
    document.getElementById('submitBtn').disabled = false;
    document.getElementById('submitBtn').textContent = '儲存修改';
    document.getElementById('orderForm').reset();
    document.getElementById('customerId').disabled = true;

    fetch(CTX + '/OrderServlet?action=get&id=' + id)
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (data.success) {
                document.getElementById('orderId').value = data.id;
                document.getElementById('customerId').value = data.customerId;
                document.getElementById('orderNumber').value = data.orderNumber;
                document.getElementById('productId').value = data.productId;
                document.getElementById('priceType').value = data.priceType;
                document.getElementById('unitPrice').value = fmtQtyDisplay(data.unitPrice);
                document.getElementById('unitWeight').value = data.unitWeight ? fmtQtyDisplay(data.unitWeight) : '';
                document.getElementById('quantity').value = fmtQtyDisplay(data.quantity);
                document.getElementById('totalAmount').value = data.totalAmount;
                document.getElementById('totalAmountDisplay').value = data.totalAmount ? '$' + fmtMoney(parseFloat(data.totalAmount)) : '$0';
                var actualVal = data.actualAmount;
                if (!actualVal) actualVal = data.totalAmount;
                document.getElementById('actualAmount').value = actualVal ? fmtQtyDisplay(actualVal) : '';
                document.getElementById('amountDiffReason').value = data.amountDiffReason || '';
                document.getElementById('expectedDeliveryDate').value = data.expectedDeliveryDate;
                document.getElementById('orderDate').value = data.orderDate;

                var noteTa = document.getElementById('note');
                noteTa.value = data.note || '';
                if (data.note) {
                    noteTa.style.display = 'block';
                    document.getElementById('noteToggleBtn').textContent = '-';
                } else {
                    noteTa.style.display = 'none';
                    document.getElementById('noteToggleBtn').textContent = '+';
                }

                updateLabels();
                checkAmountDiff();
            } else {
                showError(data.error || '載入失敗');
            }
        })
        .catch(function() { showError('系統錯誤，無法載入資料'); });
}

function closeModal() {
    overlay.style.display = 'none';
}

function showError(msg) {
    errDiv.textContent = msg;
    errDiv.style.display = 'block';
}

function generateOrderNumber() {
    var sel = document.getElementById('customerId');
    var val = sel.value;
    var today = new Date();
    var yymm = today.getFullYear() + '' + String(today.getMonth()+1).padStart(2,'0');
    if (val) {
        for (var i = 0; i < customers.length; i++) {
            if (customers[i].id == val) {
                document.getElementById('orderNumber').value = customers[i].number + '-' + yymm + '-001';
                return;
            }
        }
    }
    document.getElementById('orderNumber').value = '';
}

function fillProductInfo() {
    var sel = document.getElementById('productId');
    var val = sel.value;
    if (val) {
        for (var i = 0; i < products.length; i++) {
            if (products[i].id == val) {
                document.getElementById('priceType').value = products[i].ptype;
                if (products[i].price) document.getElementById('unitPrice').value = fmtQtyDisplay(products[i].price);
                if (products[i].weight) document.getElementById('unitWeight').value = fmtQtyDisplay(products[i].weight);
                updateLabels();
                calcTotal();
                return;
            }
        }
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
    if (!document.getElementById('orderId').value) {
        document.getElementById('actualAmount').value = total > 0 ? fmtQtyDisplay(total) : '';
    }
}

function checkAmountDiff() {
    var expected = parseFloat(document.getElementById('totalAmount').value) || 0;
    var actual = parseFloat(document.getElementById('actualAmount').value.replace(/[^0-9.\-]/g, ''));
    document.getElementById('diffReasonGroup').style.display = (actual && Math.abs(actual - expected) > 0.01) ? 'block' : 'none';
}

function toggleNote() {
    var ta = document.getElementById('note');
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

function submitForm() {
    var form = document.getElementById('orderForm');
    var custSel = document.getElementById('customerId');
    var wasDisabled = custSel.disabled;
    if (wasDisabled) custSel.disabled = false;
    var rawVals = {};
    ['quantity','unitPrice','unitWeight','actualAmount'].forEach(function(id) {
        var el = document.getElementById(id);
        if (el) { rawVals[id] = el.value; el.value = el.value.replace(/[^0-9.\-]/g, ''); }
    });
    var formData = new FormData(form);
    Object.keys(rawVals).forEach(function(id) { document.getElementById(id).value = rawVals[id]; });
    if (wasDisabled) custSel.disabled = true;

    if (!formData.get('customerId')) { showError('請選擇客戶'); return; }
    if (!formData.get('productId')) { showError('請選擇品項'); return; }
    if (!formData.get('quantity') || parseFloat(formData.get('quantity')) <= 0) { showError('請填寫有效數量'); return; }

    showConfirmDialog(formData);
}

function showConfirmDialog(formData) {
    var isEdit = !!formData.get('id');
    var custName = '', prodName = '';
    var custId = formData.get('customerId');
    var prodId = formData.get('productId');
    for (var i = 0; i < customers.length; i++) {
        if (customers[i].id == custId) { custName = customers[i].name; break; }
    }
    for (var i = 0; i < products.length; i++) {
        if (products[i].id == prodId) { prodName = products[i].name; break; }
    }
    var qty = formData.get('quantity');
    var priceType = formData.get('priceType') === '1' ? '按重量(kg)' : '按個數(pcs)';
    var totalAmt = parseFloat(formData.get('totalAmount')) || 0;
    var actualAmt = formData.get('actualAmount') ? parseFloat(formData.get('actualAmount').replace(/[^0-9.\-]/g, '')) : totalAmt;
    var expDate = formData.get('expectedDeliveryDate') || '-';
    var orderNum = document.getElementById('orderNumber').value || '-';

    var confirmOverlay = document.createElement('div');
    confirmOverlay.id = 'confirmOverlay';
    confirmOverlay.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:10000;display:flex;align-items:center;justify-content:center;';

    var box = document.createElement('div');
    box.className = 'dialog-box';

    var dialogTitle = isEdit ? '確認修改訂單' : '確認新增訂單';
    box.innerHTML = '<h3 style="margin:0 0 20px;font-size:18px;color:#1a1a2e;border-bottom:2px solid #e9ecef;padding-bottom:12px;">' + dialogTitle + '</h3>'
        + '<table style="width:100%;font-size:14px;border-collapse:collapse;">'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">訂單編號</td><td style="padding:6px 0;font-weight:600;">' + escHtml(orderNum) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">客戶名稱</td><td style="padding:6px 0;font-weight:600;">' + escHtml(custName) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">品項</td><td style="padding:6px 0;font-weight:600;">' + escHtml(prodName) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">計價方式</td><td style="padding:6px 0;">' + priceType + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">數量</td><td style="padding:6px 0;">' + qty + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">預計應收</td><td style="padding:6px 0;font-weight:600;">' + fmtMoney(totalAmt) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">實際應收</td><td style="padding:6px 0;font-weight:600;">' + fmtMoney(actualAmt) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">預計交期</td><td style="padding:6px 0;">' + escHtml(expDate) + '</td></tr>'
        + '</table>'
        + '<div style="display:flex;justify-content:flex-end;gap:10px;margin-top:24px;">'
        + '<button id="confirmCancelBtn" style="padding:8px 24px;border:1px solid #6c757d;background:#fff;border-radius:6px;cursor:pointer;font-size:14px;">取消</button>'
        + '<button id="confirmOkBtn" style="padding:8px 24px;border:none;background:#4a6cf7;color:#fff;border-radius:6px;cursor:pointer;font-size:14px;">確認</button>'
        + '</div>';

    confirmOverlay.appendChild(box);
    document.body.appendChild(confirmOverlay);

    document.getElementById('confirmCancelBtn').onclick = function() {
        document.body.removeChild(confirmOverlay);
    };
    document.getElementById('confirmOkBtn').onclick = function() {
        document.body.removeChild(confirmOverlay);
        doSubmit(formData);
    };
    confirmOverlay.onclick = function(e) {
        if (e.target === confirmOverlay) document.body.removeChild(confirmOverlay);
    };
}

function doSubmit(formData) {
    document.getElementById('submitBtn').disabled = true;
    var isEdit = !!formData.get('id');

    fetch(CTX + '/OrderServlet', {
        method: 'POST',
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        body: formData
    })
    .then(function(r) { return r.json(); })
    .then(function(data) {
            if (data.success) {
                closeModal();
                if (isEdit) {
                    var editId = formData.get('id');
                    setTimeout(function() { window.location.href = 'order_list.jsp?submitted=1&orderId=' + editId; }, 600);
                } else {
                    var newId = data.id;
                    setTimeout(function() { window.location.href = 'order_list.jsp?submitted=1&orderId=' + newId; }, 600);
                }
            } else {
            showError(data.error || '操作失敗');
            document.getElementById('submitBtn').disabled = false;
        }
    })
    .catch(function() {
        showError('系統錯誤，請稍後再試');
        document.getElementById('submitBtn').disabled = false;
    });
}

function refreshTableRow(orderId) {
    fetch(CTX + '/OrderServlet?action=get&id=' + orderId)
    .then(function(r) { return r.json(); })
    .then(function(d) {
        if (!d.success) return;
        var tr = document.querySelector('tr[data-order][onclick], tr[data-order]');
        document.querySelectorAll('tbody tr[data-order]').forEach(function(row) {
            try {
                var od = JSON.parse(row.getAttribute('data-order'));
                if (od.id == orderId) { tr = row; throw 'found'; }
            } catch(e) { if (e === 'found') throw e; }
        });
        if (!tr || !tr.getAttribute('data-order')) return;

        var pl = d.priceType === 1 ? 'kg' : 'pcs';
        var actualAmt = d.actualAmount || d.totalAmount;
        var hasDiff = d.actualAmount && d.totalAmount && parseFloat(d.actualAmount) !== parseFloat(d.totalAmount);
        var closeStatus = d.closeStatus;

        var orderDataJson = JSON.stringify({
            id: d.id, orderNumber: d.orderNumber, customerName: d.customerName,
            productName: d.productName, priceType: d.priceType,
            unitPrice: d.unitPrice, unitWeight: d.unitWeight, quantity: d.quantity,
            totalAmount: d.totalAmount, actualAmount: d.actualAmount,
            amountDiffReason: d.amountDiffReason || '', hasDiff: hasDiff,
            orderDate: d.orderDate, expectedDeliveryDate: d.expectedDeliveryDate,
            deliveryDate: d.deliveryDate || '', closeStatus: closeStatus
        });
        tr.setAttribute('data-order', orderDataJson.replace(/"/g, '&quot;'));

        var cells = tr.querySelectorAll('td');
        if (cells[0]) {
            var orderLink = closeStatus === 0
                ? '<span class="order-number" style="cursor:pointer;text-decoration:underline;" onclick="openEditModal(' + d.id + ')">' + escHtml(d.orderNumber) + '</span>'
                : '<span class="order-number">' + escHtml(d.orderNumber) + '</span>';
            cells[0].innerHTML = '<div class="order-cell">' + orderLink + '<span class="customer-name">' + escHtml(d.customerName) + '</span></div>';
        }
        if (cells[1]) {
            cells[1].innerHTML = '<div class="product-cell"><span class="product-name">' + escHtml(d.productName) + '</span><span class="product-spec" style="display:block;font-size:12px;color:#6c757d;">' + parseFloat(d.quantity) + ' ' + pl + '</span></div>';
        }
        if (cells[2]) {
            var diffClass = hasDiff ? 'diff' : 'same';
            var warnIcon = hasDiff ? ' &#9888;' : '';
            cells[2].innerHTML = '<div class="amount-cell"><span class="amount-actual ' + diffClass + '">$' + fmtMoney(parseFloat(actualAmt)) + warnIcon + '</span>'
                + (hasDiff && d.amountDiffReason ? '<span class="diff-reason">' + escHtml(d.amountDiffReason) + '</span>' : '') + '</div>';
        }
        if (cells[3]) {
            var expDate = d.expectedDeliveryDate || '-';
            var isPast = d.expectedDeliveryDate && new Date(d.expectedDeliveryDate) < new Date(new Date().toDateString());
            cells[3].innerHTML = '<span class="delivery-date' + (isPast ? ' past' : '') + '">' + expDate + '</span>';
        }

        showToast('資料已同步', 'success');
    })
    .catch(function() {});
}

// init today's order date on page load
document.addEventListener('DOMContentLoaded', function() {
    var today = new Date();
    var ds = today.getFullYear() + '-' + String(today.getMonth()+1).padStart(2,'0') + '-' + String(today.getDate()).padStart(2,'0');
    var od = document.getElementById('orderDate');
    if (od) od.value = ds;

    // 編輯/新增後回到列表：高亮並捲動到該筆訂單
    var params = new URLSearchParams(window.location.search);
    var hlId = params.get('orderId');
    var submitted = params.get('submitted');
    if (hlId && submitted === '1') {
        highlightAndScrollOrder(parseInt(hlId, 10));
        history.replaceState({}, '', window.location.pathname + (params.get('status') ? '?status=' + params.get('status') : ''));
    }
});

function highlightAndScrollOrder(orderId) {
    var target = null;
    document.querySelectorAll('tbody tr[data-order]').forEach(function(row) {
        try {
            var od = JSON.parse(row.getAttribute('data-order'));
            if (od.id == orderId) { target = row; }
        } catch (e) {}
    });
    if (!target) return;
    target.scrollIntoView({ behavior: 'smooth', block: 'center' });
    target.classList.add('row-highlight');
    setTimeout(function() { target.classList.remove('row-highlight'); }, 3000);
}

// ─── Order Detail Modal ──────────────────────────────────────────
function openDetailModal(orderData) {
    var d = orderData;
    var overlay = document.getElementById('detailOverlay');
    if (overlay) {
        overlay.style.display = 'flex';
        overlay.style.position = 'fixed';
        overlay.style.top = '0px';
        overlay.style.left = '0px';
        overlay.style.right = '0px';
        overlay.style.bottom = '0px';
        overlay.style.background = 'rgba(0,0,0,0.4)';
        overlay.style.zIndex = '9998';
        overlay.style.alignItems = 'center';
        overlay.style.justifyContent = 'center';
    }
    document.getElementById('detOrderNumber').textContent = d.orderNumber;
    document.getElementById('detCustomer').textContent = d.customerName;
    document.getElementById('detCloseStatus').textContent = d.closeStatus === 1 ? '已結案' : '未結案';
    document.getElementById('detCloseStatus').className = 'badge ' + (d.closeStatus === 1 ? 'badge-green' : 'badge-gray');

    var pl = d.priceType === 1 ? 'kg' : 'pcs';
    var ppl = d.priceType === 1 ? '/kg' : '/pcs';
    var amtDiffHtml = d.hasDiff
        ? '<span class="value diff">$' + parseFloat(d.actualAmount).toLocaleString('en-US', {minimumFractionDigits:2,maximumFractionDigits:2}) + ' &#9888;</span>'
        : '<span class="value">$' + parseFloat(d.actualAmount || d.totalAmount).toLocaleString('en-US', {minimumFractionDigits:2,maximumFractionDigits:2}) + '</span>';

    function fm(n) { return parseFloat(n).toLocaleString('en-US', {minimumFractionDigits:2,maximumFractionDigits:2}); }
    function payStatusHtml(d) {
        var invoiced = parseFloat(d.totalInvoiced) || 0;
        var received = parseFloat(d.totalReceived) || 0;
        var actual = parseFloat(d.actualAmount) || parseFloat(d.totalAmount) || 0;
        if (invoiced === 0) return '<span class="badge badge-gray">未開帳</span>';
        if (received >= actual - 0.01) return '<span class="badge badge-green">全部已收款</span>';
        if (received > 0) return '<span class="badge badge-orange">部分收款</span>';
        return '<span class="badge badge-red">未收款</span>';
    }

    document.getElementById('detBody').innerHTML =
        '<div class="detail-grid">' +
            '<div class="detail-section full">' +
                '<h4>訂單資訊</h4>' +
                '<div class="row"><span class="label">客戶名稱</span><span class="value">' + escHtml(d.customerName) + '</span></div>' +
                '<div class="row"><span class="label">品項名稱</span><span class="value">' + escHtml(d.productName) + '</span></div>' +
                '<div class="row"><span class="label">訂單日期</span><span class="value">' + (d.orderDate || '-') + '</span></div>' +
                '<div class="row"><span class="label">預計交期</span><span class="value">' + (d.expectedDeliveryDate || '-') + '</span></div>' +
            '</div>' +
            '<div class="detail-section">' +
                '<h4>生產進度</h4>' +
                '<div class="row"><span class="label">生產狀態</span><span class="value">' + d.prodStatusLabel + '</span></div>' +
                '<div class="row"><span class="label">訂購數量</span><span class="value">' + parseFloat(d.orderQty) + ' ' + pl + '</span></div>' +
                '<div class="row"><span class="label">已生產數量</span><span class="value">' + parseFloat(d.totalProduced) + ' ' + pl + '</span></div>' +
                (d.unitWeight ? '<div class="row"><span class="label">單位重量</span><span class="value">' + d.unitWeight + ' kg</span></div>' : '') +
                '<div class="row"><span class="label">計價方式</span><span class="value">' + (d.priceType === 1 ? '按重量' : '按個數') + '</span></div>' +
            '</div>' +
            '<div class="detail-section">' +
                '<h4>出貨管理</h4>' +
                '<div class="row"><span class="label">出貨狀態</span><span class="value">' + d.delivStatusLabel + '</span></div>' +
                '<div class="row"><span class="label">已出貨數量</span><span class="value">' + parseFloat(d.totalDelivered) + ' ' + pl + '</span></div>' +
                '<div class="row"><span class="label">實際交期</span><span class="value">' + (d.deliveryDate || '-') + '</span></div>' +
            '</div>' +
            '<div class="detail-section">' +
                '<h4>財務資訊</h4>' +
                '<div class="row"><span class="label">單價</span><span class="value">$' + fm(d.unitPrice) + ppl + '</span></div>' +
                '<div class="row"><span class="label">預計應收</span><span class="value">$' + fm(d.totalAmount) + '</span></div>' +
                '<div class="row"><span class="label">實際應收</span>' + amtDiffHtml + '</div>' +
                (d.amountDiffReason ? '<div class="row"><span class="label">差異原因</span><span class="value">' + escHtml(d.amountDiffReason) + '</span></div>' : '') +
                '<div class="row"><span class="label">已開帳金額</span><span class="value">$' + fm(d.totalInvoiced) + '</span></div>' +
                '<div class="row"><span class="label">已收款金額</span><span class="value">$' + fm(d.totalReceived) + '</span></div>' +
                '<div class="row"><span class="label">未收金額</span><span class="value">$' + fm(Math.max(0, (parseFloat(d.actualAmount) || parseFloat(d.totalAmount)) - d.totalReceived)) + '</span></div>' +
                '<div class="row"><span class="label">收款狀態</span><span class="value">' + payStatusHtml(d) + '</span></div>' +
            '</div>' +
        '</div>';
}

function closeDetailModal() {
    var overlay = document.getElementById('detailOverlay');
    if (overlay) {
        overlay.style.display = 'none';
        overlay.classList.remove('show');
    }
}

function escHtml(s) {
    if (!s) return '';
    var d = document.createElement('div');
    d.textContent = s;
    return d.innerHTML;
}

// Click handler on order rows
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('tbody tr[data-order]').forEach(function(tr) {
        tr.addEventListener('click', function(e) {
            if (e.target.closest('.actions') || e.target.closest('button') || e.target.closest('a') || e.target.closest('.order-number')) return;
            try {
                var data = JSON.parse(tr.getAttribute('data-order'));
                openDetailModal(data);
            } catch(ex) { console.error('Order data parse error', ex); }
        });
    });
});
</script>

<div class="detail-overlay" id="detailOverlay" onclick="if(event.target===this)closeDetailModal()">
    <div class="detail-card">
        <button class="detail-close" onclick="closeDetailModal()">&times;</button>
        <div class="detail-head">
            <h3 id="detOrderNumber"></h3>
            <div class="detail-sub"><span id="detCustomer"></span> &nbsp; <span id="detCloseStatus" class="badge badge-gray"></span></div>
        </div>
        <div class="detail-body" id="detBody"></div>
    </div>
</div>

<% if (alertMsg != null) { %>
<script>
(function() {
    var overlay = document.createElement('div');
    overlay.id = 'alertOverlay';
    overlay.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.4);z-index:10001;display:flex;align-items:center;justify-content:center;';
    overlay.onclick = function(e) { if (e.target === overlay) overlay.remove(); };
    var bgColor = '<%= alertType %>' === 'success' ? '#28a745' : '#dc3545';
    var box = document.createElement('div');
    box.className = 'dialog-box-sm';
    box.style.textAlign = 'center';
    box.innerHTML = '<div style="font-size:16px;font-weight:600;color:#1a1a2e;margin-bottom:20px;"><%= alertMsg.replace("\\", "\\\\").replace("'", "\\'").replace("\"", "&quot;") %></div>'
        + '<button onclick="document.getElementById(\'alertOverlay\').remove()" style="padding:8px 32px;border:none;background:' + bgColor + ';color:#fff;border-radius:6px;cursor:pointer;font-size:14px;font-weight:600;">確認</button>';
    overlay.appendChild(box);
    document.body.appendChild(overlay);
})();
</script>
<% } %>

<%@ include file="../include/footer.jsp" %>