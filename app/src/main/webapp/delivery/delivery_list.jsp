<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, dao.OrderDao, dao.DeliveryDao, util.NumberUtil, model.Customer, model.Product" %>
<% request.setAttribute("pageTitle", "出貨管理"); %>
<% request.setAttribute("pageIcon", "▶"); %>
<% request.setAttribute("pageSubtitle", "出貨記錄與客戶交貨明細"); %>
<%@ include file="../include/header.jsp" %>
<%@ taglib prefix="my" tagdir="/WEB-INF/tags" %>
<%
    String dateFrom = request.getParameter("dateFrom");
    String dateTo = request.getParameter("dateTo");
    String filterCustomer = request.getParameter("filterCustomer");
    String filterOrderNumber = request.getParameter("filterOrderNumber");
    String filterProduct = request.getParameter("filterProduct");
    String orderId = request.getParameter("orderId");
    boolean isFiltered = orderId != null && !orderId.isEmpty();
    String viewMode = request.getParameter("view");
    if (viewMode == null || viewMode.isEmpty()) viewMode = "byDelivery";

    if (!isFiltered && dateFrom == null && dateTo == null) {
        java.text.SimpleDateFormat _sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
        java.util.Calendar _cal = java.util.Calendar.getInstance();
        _cal.add(java.util.Calendar.DAY_OF_MONTH, -7);
        dateFrom = _sdf.format(_cal.getTime());
        dateTo = _sdf.format(new java.util.Date());
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
    String baseUrl = "delivery_list.jsp?submitted=1"
        + (dateFrom != null && !dateFrom.isEmpty() ? "&dateFrom=" + dateFrom : "")
        + (dateTo != null && !dateTo.isEmpty() ? "&dateTo=" + dateTo : "")
        + (filterCustomer != null && !filterCustomer.trim().isEmpty() ? "&filterCustomer=" + java.net.URLEncoder.encode(filterCustomer.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
        + (filterOrderNumber != null && !filterOrderNumber.trim().isEmpty() ? "&filterOrderNumber=" + java.net.URLEncoder.encode(filterOrderNumber.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
        + (filterProduct != null && !filterProduct.trim().isEmpty() ? "&filterProduct=" + java.net.URLEncoder.encode(filterProduct.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
        + (orderId != null && !orderId.isEmpty() ? "&orderId=" + orderId : "");
%>
    <% if (isFiltered) { %>
    <div style="display:flex;justify-content:space-between;margin-bottom:16px;">
        <a href="delivery_list.jsp" class="btn btn-outline">← 返回全部出貨</a>
    </div>
    <% } %>

    <% if (!isFiltered) { %>
    <form class="filter-bar" method="GET">
        <div style="display:flex;align-items:center;gap:6px;white-space:nowrap;">
            <label style="margin:0;">出貨日期</label>
            <input type="date" name="dateFrom" value="<%= dateFrom != null ? dateFrom : "" %>" style="width:auto;">
            <span style="color:#6c757d;">至</span>
            <input type="date" name="dateTo" value="<%= dateTo != null ? dateTo : "" %>" style="width:auto;">
        </div>
        <div style="display:flex;align-items:flex-end;gap:12px;flex-wrap:wrap;">
            <div class="field">
                <label>客戶名稱</label>
                <input type="text" name="filterCustomer" value="<%= filterCustomer != null ? filterCustomer : "" %>" placeholder="客戶名稱">
            </div>
            <div class="field">
                <label>訂單編號</label>
                <input type="text" name="filterOrderNumber" value="<%= filterOrderNumber != null ? filterOrderNumber : "" %>" placeholder="訂單編號">
            </div>
            <div class="field">
                <label>品項</label>
                <input type="text" name="filterProduct" value="<%= filterProduct != null ? filterProduct : "" %>" placeholder="品項名稱">
            </div>
            <button type="submit" class="btn-search">查詢</button>
            <a href="delivery_list.jsp" class="btn-clear">清除</a>
        </div>
    </form>
    <% } %>

    <div style="display:flex;justify-content:flex-end;gap:8px;margin-bottom:16px;">
        <a href="delivery_list.jsp?<%= baseUrl.replace("delivery_list.jsp?", "") %>&view=byDelivery" class="btn <%= "byDelivery".equals(viewMode) ? "btn-primary" : "btn-outline" %>" style="text-decoration:none;">依出貨呈現</a>
        <a href="delivery_list.jsp?<%= baseUrl.replace("delivery_list.jsp?", "") %>&view=byOrder" class="btn <%= "byOrder".equals(viewMode) ? "btn-primary" : "btn-outline" %>" style="text-decoration:none;">依訂單呈現</a>
        <button onclick="openAddModal(<%= isFiltered ? orderId : "" %>)" class="btn btn-primary">+ 新增出貨</button>
    </div>

    <%
        String msg = request.getParameter("message");
    %>
    <% if ("success".equals(msg)) { %>
    <script>
    document.addEventListener('DOMContentLoaded', function() {
        var toast = document.createElement('div');
        toast.style.cssText = 'position:fixed;top:20px;right:20px;z-index:10002;padding:14px 24px;border-radius:8px;font-size:14px;font-weight:600;color:#fff;background:#28a745;box-shadow:0 4px 16px rgba(0,0,0,0.2);opacity:0;transition:opacity 0.3s;';
        toast.textContent = '出貨資料已儲存！';
        document.body.appendChild(toast);
        requestAnimationFrame(function() { toast.style.opacity = '1'; });
        setTimeout(function() { toast.style.opacity = '0'; setTimeout(function() { toast.remove(); }, 300); }, 2500);
    });
    </script>
    <% } %>

    <%
        String orderNumber = "";
        String customerName = "";
        double orderQuantity = 0;
        double totalDelivered = 0;
        double stockQty = 0;
        String productName = "";
        String priceTypeLabel = "";

        DeliveryDao delDao = new DeliveryDao();

        if (isFiltered) {
            Map<String, Object> info = delDao.getOrderDeliveryInfo(Integer.parseInt(orderId));
            if (!info.isEmpty()) {
                orderNumber = (String) info.getOrDefault("orderNumber", "");
                customerName = (String) info.getOrDefault("customerName", "");
                orderQuantity = (double) info.getOrDefault("quantity", 0.0);
                totalDelivered = (double) info.getOrDefault("totalDelivered", 0.0);
                stockQty = (double) info.getOrDefault("stockQty", 0.0);
                productName = (String) info.getOrDefault("productName", "");
                int pt = (int) info.getOrDefault("priceType", 0);
                priceTypeLabel = pt == 1 ? "按重量(kg)" : "按個數(pcs)";
            }
        }
    %>

    <% if (isFiltered) {
        double remain = orderQuantity - totalDelivered;
        int delivPct = orderQuantity > 0 ? (int)Math.min(Math.round(totalDelivered / orderQuantity * 100), 100) : 0;
        boolean enoughStock = stockQty >= remain;
    %>
        <div style="background:#fff;border:1px solid #e0e0e0;border-radius:8px;padding:16px 20px;margin-bottom:16px;">
            <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:12px;">
                <div>
                    <div style="font-size:18px;font-weight:700;color:#333;"><%= orderNumber %></div>
                    <div style="font-size:14px;color:#666;margin-top:2px;"><%= customerName %>　|　<%= productName %>　<%= priceTypeLabel %></div>
                </div>
                <div style="display:flex;gap:24px;align-items:center;font-size:14px;">
                    <div>訂單數量 <b><%= NumberUtil.fmtQty(orderQuantity) %></b></div>
                    <div>已出貨 <b style="color:#28a745;"><%= NumberUtil.fmtQty(totalDelivered) %></b></div>
                    <div>未出貨 <b style="color:<%= remain > 0 ? "#dc3545" : "#28a745" %>;"><%= NumberUtil.fmtQty(remain) %></b></div>
                    <div>
                        出貨進度
                        <div class="progress-bar" style="width:120px;height:16px;display:inline-block;vertical-align:middle;">
                            <div class="progress-fill" style="width:<%= delivPct %>%;background-color:#007bff;line-height:16px;font-size:11px;"><%= delivPct %>%</div>
                        </div>
                    </div>
                    <div style="padding:4px 12px;border-radius:6px;font-size:13px;font-weight:600;background:<%= enoughStock ? "#e8f5e9" : "#fff3e0" %>;color:<%= enoughStock ? "#2e7d32" : "#e65100" %>;">
                        成品倉庫存 <b><%= NumberUtil.fmtQty(stockQty) %></b>　<%= enoughStock ? "✓ 足夠" : "⚠ 不足" %>
                    </div>
                </div>
            </div>
        </div>
    <% } %>

    <% if ("byDelivery".equals(viewMode)) { %>
    <div class="table-container" style="display:flex;flex-direction:column;padding:0;">
    <table id="delivTable" style="order:2;width:100%;">
        <thead>
            <tr class="col-header">
                <th>序號</th>
                <th data-col="0" onclick="sortDelivTable(0,'str')" style="cursor:pointer;">客戶 ↕</th>
                <th data-col="1" onclick="sortDelivTable(1,'str')" style="cursor:pointer;">訂單編號 ↕</th>
                <th data-col="2" onclick="sortDelivTable(2,'str')" style="cursor:pointer;">出貨單號 ↕</th>
                <th data-col="3" onclick="sortDelivTable(3,'str')" style="cursor:pointer;">品項 ↕</th>
                <th data-col="4" onclick="sortDelivTable(4,'date')" style="cursor:pointer;">出貨日 ↕</th>
                <th>數量</th>
                <th>備註</th>
            </tr>
        </thead>
        <tbody>
            <%
                totalPages = 1;
                filteredIdx = 0;
                displayed = 0;

                try {
                    int orderIdInt = orderId != null && !orderId.isEmpty() ? Integer.parseInt(orderId) : 0;
                    List<Map<String, Object>> delList = delDao.getFilteredDeliveryList(
                        dateFrom, dateTo, filterCustomer, filterOrderNumber, filterProduct,
                        orderIdInt, isFiltered
                    );

                    boolean hasData = false;
                    for (Map<String, Object> row : delList) {
                        hasData = true;

                        filteredIdx++;
                        if (filteredIdx <= startIdx) continue;
                        if (displayed >= pageSize) continue;
                        displayed++;

                        String custName = (String) row.get("customerName");
                        String ordNum = (String) row.get("orderNumber");
                        String delNum = (String) row.get("deliveryNumber");
                        String prodName = (String) row.get("deliveryProductName");
                        java.sql.Date delDate = (java.sql.Date) row.get("deliveryDate");
                        java.math.BigDecimal qty = (java.math.BigDecimal) row.get("deliveryQty");
                        String note = (String) row.get("note");
                        int dOid = (int) row.get("orderId");
                        int delId = (int) row.get("deliveryId");
            %>
                        <tr class="data-row"
                            data-customer="<%= custName != null ? custName : "" %>"
                            data-order="<%= ordNum != null ? ordNum : "" %>"
                            data-delivery="<%= delNum != null ? delNum : "" %>"
                            data-product="<%= prodName != null ? prodName : "" %>"
                            data-deliverydate="<%= delDate != null ? delDate.toString() : "" %>">
                            <td><%= filteredIdx %></td>
                            <td><%= custName %></td>
                            <td><a href="../order/order_list.jsp?orderId=<%= dOid %>" style="color:#1a1a2e;text-decoration:underline;font-weight:600;"><%= ordNum %></a></td>
                            <td><a href="javascript:void(0)" onclick="openEditModal(<%= delId %>)" style="font-weight:700;color:#1a1a2e;text-decoration:underline;cursor:pointer;"><%= delNum %></a></td>
                            <td><%= prodName != null ? prodName : "" %></td>
                            <td><%= delDate %></td>
                            <td><%= NumberUtil.fmtQty(qty.doubleValue()) %></td>
                            <td><%= note != null ? note : "" %></td>
                        </tr>
            <%
                    }
                    if (!hasData) {
            %>
                        <tr>
                            <td colspan="8">
                                <div class="empty-state">
                                    <p>尚無出貨資料</p>
                                    <button onclick="openAddModal(<%= orderId != null && !orderId.isEmpty() ? orderId : "" %>)" class="btn btn-primary" style="margin-top:16px;">+ 新增出貨</button>
                                </div>
                            </td>
                        </tr>
            <%
                    }
                    totalPages = filteredIdx > 0 ? (int) Math.ceil((double) filteredIdx / pageSize) : 1;
                    if (pageNum > totalPages) pageNum = totalPages;
                } catch (Exception e) {
                    out.println("<tr><td colspan='6' style='color:red;'>錯誤：" + e.getMessage() + "</td></tr>");
                }
            %>
    </tbody>
</table>
<div style="order:1;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= totalPages %>" totalCount="<%= filteredIdx %>" baseUrl="<%= baseUrl %>" position="top"/></div>
<div style="order:3;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= totalPages %>" totalCount="<%= filteredIdx %>" baseUrl="<%= baseUrl %>"/></div>
</div>
<% } else { %>
<%
    int byOrderTotal = 0;
    try {
        int orderIdInt = orderId != null && !orderId.isEmpty() ? Integer.parseInt(orderId) : 0;
        List<Map<String, Object>> boList = delDao.getFilteredDeliveryList(
            dateFrom, dateTo, filterCustomer, filterOrderNumber, filterProduct,
            orderIdInt, isFiltered
        );

        java.util.LinkedHashMap<Integer, java.util.List<Map<String, Object>>> groupMap = new java.util.LinkedHashMap<>();
        java.util.LinkedHashMap<Integer, Map<String, Object>> orderInfoMap = new java.util.LinkedHashMap<>();
        boolean boHasData = false;
        for (Map<String, Object> delRow : boList) {
            boHasData = true;
            int oid = (int) delRow.get("orderId");
            groupMap.computeIfAbsent(oid, k -> new java.util.ArrayList<>()).add(delRow);
            if (!orderInfoMap.containsKey(oid)) {
                orderInfoMap.put(oid, delRow);
            }
        }

        if (!boHasData) {
%>
<div class="empty-state" style="background:#fff;border:1px solid #e0e0e0;border-radius:8px;padding:40px;text-align:center;">
    <p>尚無出貨資料</p>
    <button onclick="openAddModal(<%= orderId != null && !orderId.isEmpty() ? orderId : "" %>)" class="btn btn-primary" style="margin-top:16px;">+ 新增出貨</button>
</div>
<%
        } else {
            for (java.util.Map.Entry<Integer, java.util.List<Map<String, Object>>> entry : groupMap.entrySet()) {
                int oid = entry.getKey();
                java.util.List<Map<String, Object>> dlist = entry.getValue();
                Map<String, Object> oi = orderInfoMap.get(oid);
                java.math.BigDecimal orderQty = (java.math.BigDecimal) oi.get("orderQty");
                java.math.BigDecimal delivered = java.math.BigDecimal.ZERO;
                for (Map<String, Object> dr : dlist) {
                    java.math.BigDecimal dqty = (java.math.BigDecimal) dr.get("deliveryQty");
                    delivered = delivered.add(dqty != null ? dqty : java.math.BigDecimal.ZERO);
                }
                double orderQtyDbl = orderQty != null ? orderQty.doubleValue() : 0;
                double deliveredDbl = delivered.doubleValue();
                int delivPct = orderQtyDbl > 0 ? (int)Math.min(Math.round(deliveredDbl / orderQtyDbl * 100), 100) : 0;
                String delivBadge = deliveredDbl <= 0 ? "badge-gray" : (deliveredDbl >= orderQtyDbl ? "badge-green" : "badge-orange");
                String delivLabel = deliveredDbl <= 0 ? "未出貨" : (deliveredDbl >= orderQtyDbl ? "已出貨" : "部分出貨");
                String ordNum = (String) oi.get("orderNumber");
                String custName = (String) oi.get("customerName");
                String prodName = (String) oi.get("deliveryProductName");
                String expD = oi.get("expectedDeliveryDate") != null ? oi.get("expectedDeliveryDate").toString() : "-";
                String ptype = (int) oi.get("priceType") == 1 ? "kg" : "pcs";
                String orderQtyStr = orderQty != null ? NumberUtil.fmtQty(orderQty.doubleValue()) : "0";
                String deliveredStr = NumberUtil.fmtQty(deliveredDbl);
%>
<div style="background:#fff;border:1px solid #e0e0e0;border-radius:8px;margin-bottom:16px;overflow:hidden;">
    <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:12px;padding:14px 20px;background:#f8f9fa;border-bottom:1px solid #e0e0e0;">
        <div>
            <a href="../order/order_list.jsp?orderId=<%= oid %>" style="font-size:16px;font-weight:700;color:#1a1a2e;text-decoration:underline;"><%= ordNum %></a>
            <span style="font-size:14px;color:#666;margin-left:8px;"><%= custName %>　|　<%= prodName %>　<%= ptype %></span>
        </div>
        <div style="display:flex;gap:18px;align-items:center;font-size:13px;">
            <div>訂單總量 <b><%= orderQtyStr %> <%= ptype %></b></div>
            <div>已出貨 <b style="color:#28a745;"><%= deliveredStr %> <%= ptype %></b></div>
            <div>預計出貨日 <b><%= expD %></b></div>
            <span class="badge <%= delivBadge %>"><%= delivLabel %> (<%= delivPct %>%)</span>
        </div>
    </div>
    <table style="width:100%;">
        <thead>
            <tr style="background:#fff;">
                <th style="padding:8px 20px;text-align:left;font-size:13px;color:#6c757d;">出貨單號</th>
                <th style="padding:8px 20px;text-align:left;font-size:13px;color:#6c757d;">出貨日</th>
                <th style="padding:8px 20px;text-align:left;font-size:13px;color:#6c757d;">數量</th>
                <th style="padding:8px 20px;text-align:left;font-size:13px;color:#6c757d;">備註</th>
            </tr>
        </thead>
        <tbody>
<%
                for (Map<String, Object> dr : dlist) {
                    int dDrId = (int) dr.get("deliveryId");
                    String dDrNum = (String) dr.get("deliveryNumber");
                    java.sql.Date dDrDate = (java.sql.Date) dr.get("deliveryDate");
                    java.math.BigDecimal dDrQty = (java.math.BigDecimal) dr.get("deliveryQty");
                    String dDrNote = (String) dr.get("note");
%>
            <tr>
                <td style="padding:8px 20px;"><a href="javascript:void(0)" onclick="openEditModal(<%= dDrId %>)" style="font-weight:600;color:#1a1a2e;text-decoration:underline;cursor:pointer;"><%= dDrNum %></a></td>
                <td style="padding:8px 20px;"><%= dDrDate %></td>
                <td style="padding:8px 20px;"><%= dDrQty != null ? NumberUtil.fmtQty(dDrQty.doubleValue()) : "0" %> <%= ptype %></td>
                <td style="padding:8px 20px;color:#888;font-size:13px;"><%= dDrNote != null ? dDrNote : "" %></td>
            </tr>
<%
                }
%>
        </tbody>
    </table>
</div>
<%
            }
        }
    } catch (Exception e) {
        out.println("<div style='color:red;padding:20px;'>錯誤：" + e.getMessage() + "</div>");
        e.printStackTrace();
    }
%>
<% } %>

<script>
var CTX = '<%= request.getContextPath() %>';

var overlay, box, titleEl, errDiv, formEl;

function stripZeros(n) {
    var s = String(n);
    if (s.indexOf('.') !== -1) { s = s.replace(/0+$/, '').replace(/\.$/, ''); }
    return s;
}

function showToast(msg, type) {
    var toast = document.createElement('div');
    toast.style.cssText = 'position:fixed;top:20px;right:20px;z-index:10002;padding:14px 24px;border-radius:8px;font-size:14px;font-weight:600;color:#fff;box-shadow:0 4px 16px rgba(0,0,0,0.2);opacity:0;transition:opacity 0.3s;';
    toast.style.background = type === 'success' ? '#28a745' : '#dc3545';
    toast.textContent = msg;
    document.body.appendChild(toast);
    requestAnimationFrame(function() { toast.style.opacity = '1'; });
    setTimeout(function() { toast.style.opacity = '0'; setTimeout(function() { toast.remove(); }, 300); }, 2500);
}

function initModal() {
    overlay = document.createElement('div');
    overlay.style.cssText = 'display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(200,200,200,0.5);z-index:9999;align-items:center;justify-content:center;';

    box = document.createElement('div');
    box.style.cssText = 'background:#fff;border-radius:12px;box-shadow:0 8px 32px rgba(0,0,0,0.15);padding:30px 35px 35px;width:520px;max-width:90vw;max-height:85vh;overflow-y:auto;';

    titleEl = document.createElement('h3');
    titleEl.style.cssText = 'margin:0 0 24px;font-size:20px;font-weight:600;color:#1a1a2e;padding-bottom:12px;border-bottom:2px solid #e9ecef;';

    errDiv = document.createElement('div');
    errDiv.style.cssText = 'display:none;padding:12px;border-radius:8px;margin-bottom:16px;text-align:center;font-size:14px;background:#fff5f5;color:#dc3545;border:1px solid #ffe0e0;';

    formEl = document.createElement('div');

    box.appendChild(titleEl);
    box.appendChild(errDiv);
    box.appendChild(formEl);
    overlay.appendChild(box);
    document.body.appendChild(overlay);
}

function closeModal() {
    overlay.style.display = 'none';
    formEl.innerHTML = '';
    errDiv.style.display = 'none';
}

function showError(msg) {
    errDiv.textContent = msg;
    errDiv.style.display = 'block';
}

/* ── Add Modal ────────────────────────────────────────────── */
function openAddModal(preselectedOrderId) {
    if (!overlay) initModal();
    overlay.style.display = 'flex';
    titleEl.textContent = '新增出貨記錄';
    errDiv.style.display = 'none';

    var isLocked = !!preselectedOrderId;

    formEl.innerHTML =
        '<form id="addDeliveryForm">' +
        '<input type="hidden" name="orderId" id="addOrderId">' +
        '<div id="addOrderSelectWrap" style="' + (isLocked ? 'display:none;' : '') + '"><div class="form-group"><label>選擇訂單：</label>' +
        '<select id="addOrderIdSelect" required onchange="updateAddOrderInfo()">' +
        '<option value="">-- 請選擇訂單 --</option></select></div></div>' +
        '<div id="addOrderInfo" style="display:none;padding:10px 14px;background:#f8f9fa;border-radius:8px;margin-bottom:16px;font-size:13px;line-height:1.8;">' +
        '<div id="addInfoOrder"></div>' +
        '<div id="addInfoProduct" style="color:#0056b3;font-weight:600;"></div>' +
        '<div id="addInfoRemain"></div>' +
        '<div id="addInfoStock" style="color:#28a745;font-weight:600;"></div></div>' +
        '<div class="form-group"><label>出貨日期：</label>' +
        '<input type="date" name="deliveryDate" id="addDeliveryDate" required></div>' +
        '<div class="form-group"><label>出貨數量：</label>' +
        '<input type="number" name="quantity" id="addQuantity" step="any" required></div>' +
        '<input type="hidden" name="status" value="1">' +
        '<div class="form-group"><label>備註：</label>' +
        '<textarea name="note" rows="2" placeholder="出貨備註..."></textarea></div>' +
        '<div style="display:flex;gap:12px;margin-top:16px;">' +
        '<button type="button" onclick="submitAddForm()" class="btn-submit" id="addSubmitBtn">確認出貨</button>' +
        '<button type="button" onclick="closeModal()" class="btn-submit" style="background:#6c757d;">取消</button></div>' +
        '</form>';

    var today = new Date();
    var ds = today.getFullYear() + '-' + String(today.getMonth()+1).padStart(2,'0') + '-' + String(today.getDate()).padStart(2,'0');
    document.getElementById('addDeliveryDate').value = ds;

    fetch(CTX + '/DeliveryServlet?action=getOrders')
        .then(function(r){ return r.json(); })
        .then(function(orders){
            if (isLocked) {
                for (var i = 0; i < orders.length; i++) {
                    if (orders[i].id == preselectedOrderId) {
                        var o = orders[i];
                        document.getElementById('addOrderId').value = o.id;
                        document.getElementById('addInfoOrder').textContent = '訂單：' + o.orderNumber + ' | 客戶：' + o.customerName;
                        document.getElementById('addInfoProduct').textContent = '品項：' + o.productName;
                        document.getElementById('addInfoRemain').textContent = '訂單總量：' + stripZeros(o.quantity) + ' | 已出貨：' + stripZeros(o.totalDelivered) + ' | 未出貨量：' + stripZeros(o.remain);
                        document.getElementById('addInfoStock').textContent = '成品倉庫存：' + stripZeros(o.stockQty);
                        document.getElementById('addOrderInfo').style.display = 'block';
                        break;
                    }
                }
            } else {
                var sel = document.getElementById('addOrderIdSelect');
                for (var i = 0; i < orders.length; i++) {
                    var o = orders[i];
                    var opt = document.createElement('option');
                    opt.value = o.id;
                    opt.textContent = o.orderNumber + ' - ' + o.customerName + ' (未出貨量 ' + o.remain + ')';
                    opt.setAttribute('data-id', o.id);
                    opt.setAttribute('data-order', o.orderNumber);
                    opt.setAttribute('data-customer', o.customerName);
                    opt.setAttribute('data-product', o.productName);
                    opt.setAttribute('data-qty', o.quantity);
                    opt.setAttribute('data-delivered', o.totalDelivered);
                    opt.setAttribute('data-remain', o.remain);
                    opt.setAttribute('data-stock', o.stockQty);
                    sel.appendChild(opt);
                }
            }
        });
}

function updateAddOrderInfo() {
    var sel = document.getElementById('addOrderIdSelect');
    var opt = sel.options[sel.selectedIndex];
    document.getElementById('addOrderId').value = sel.value;
    if (sel.value) {
        document.getElementById('addInfoOrder').textContent = '訂單：' + opt.getAttribute('data-order') + ' | 客戶：' + opt.getAttribute('data-customer');
        document.getElementById('addInfoProduct').textContent = '品項：' + opt.getAttribute('data-product');
        document.getElementById('addInfoRemain').textContent = '訂單總量：' + stripZeros(opt.getAttribute('data-qty')) + ' | 已出貨：' + stripZeros(opt.getAttribute('data-delivered')) + ' | 未出貨量：' + stripZeros(opt.getAttribute('data-remain'));
        document.getElementById('addInfoStock').textContent = '成品倉庫存：' + stripZeros(opt.getAttribute('data-stock'));
        document.getElementById('addOrderInfo').style.display = 'block';
    } else {
        document.getElementById('addOrderInfo').style.display = 'none';
    }
}

function submitAddForm() {
    var form = document.getElementById('addDeliveryForm');
    var formData = new FormData(form);
    if (!formData.get('orderId')) { showError('請選擇訂單'); return; }
    if (!formData.get('quantity') || parseFloat(formData.get('quantity')) <= 0) { showError('請填寫有效數量'); return; }

    var remain = 0;
    var isLocked = !!document.getElementById('addOrderId').value && !document.getElementById('addOrderIdSelect');
    if (!isLocked) {
        var sel = document.getElementById('addOrderIdSelect');
        var opt = sel.options[sel.selectedIndex];
        remain = parseFloat(opt.getAttribute('data-remain'));
    } else {
        var remainText = document.getElementById('addInfoRemain').textContent;
        var m = remainText.match(/未出貨量\s*([\d.]+)/);
        if (m) remain = parseFloat(m[1]);
    }
    var qty = parseFloat(formData.get('quantity'));
    if (qty > remain) { showError('出貨數量超出訂單剩餘可出量（剩餘 ' + remain + '）'); return; }

    var orderLabel = document.getElementById('addInfoOrder').textContent;
    var productLabel = document.getElementById('addInfoProduct').textContent;
    var remainLabel = document.getElementById('addInfoRemain').textContent;
    var stockLabel = document.getElementById('addInfoStock').textContent;
    var deliveryDate = formData.get('deliveryDate') || '-';
    var noteVal = formData.get('note') || '';

    showConfirmDialog(orderLabel, productLabel, remainLabel, stockLabel, deliveryDate, qty, noteVal, formData);
}

function showConfirmDialog(orderLabel, productLabel, remainLabel, stockLabel, deliveryDate, qty, noteVal, formData) {
    var confirmOverlay = document.createElement('div');
    confirmOverlay.id = 'confirmOverlay';
    confirmOverlay.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:10000;display:flex;align-items:center;justify-content:center;';

    var cbox = document.createElement('div');
    cbox.className = 'dialog-box';

    cbox.innerHTML = '<h3 style="margin:0 0 20px;font-size:18px;color:#1a1a2e;border-bottom:2px solid #e9ecef;padding-bottom:12px;">確認出貨</h3>'
        + '<table style="width:100%;font-size:14px;border-collapse:collapse;">'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;white-space:nowrap;">' + escHtml(orderLabel) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#0056b3;font-weight:600;">' + escHtml(productLabel) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#6c757d;">' + escHtml(remainLabel) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;color:#28a745;font-weight:600;">' + escHtml(stockLabel) + '</td></tr>'
        + '<tr><td style="border-top:1px solid #e9ecef;padding-top:10px;margin-top:4px;"></td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;"><b>出貨日期：</b>' + escHtml(deliveryDate) + '</td></tr>'
        + '<tr><td style="padding:6px 12px 6px 0;"><b>出貨數量：</b>' + qty + '</td></tr>'
        + (noteVal ? '<tr><td style="padding:6px 12px 6px 0;"><b>備註：</b>' + escHtml(noteVal) + '</td></tr>' : '')
        + '</table>'
        + '<div style="display:flex;justify-content:flex-end;gap:10px;margin-top:24px;">'
        + '<button id="confirmCancelBtn" style="padding:8px 24px;border:1px solid #6c757d;background:#fff;border-radius:6px;cursor:pointer;font-size:14px;">取消</button>'
        + '<button id="confirmOkBtn" style="padding:8px 24px;border:none;background:#4361ee;color:#fff;border-radius:6px;cursor:pointer;font-size:14px;">確認出貨</button>'
        + '</div>';

    confirmOverlay.appendChild(cbox);
    document.body.appendChild(confirmOverlay);

    document.getElementById('confirmCancelBtn').onclick = function() { document.body.removeChild(confirmOverlay); };
    document.getElementById('confirmOkBtn').onclick = function() {
        document.body.removeChild(confirmOverlay);
        doSubmitDelivery(formData);
    };
    confirmOverlay.onclick = function(e) { if (e.target === confirmOverlay) document.body.removeChild(confirmOverlay); };
}

function doSubmitDelivery(formData) {
    document.getElementById('addSubmitBtn').disabled = true;

    fetch(CTX + '/DeliveryServlet', {
        method: 'POST',
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        body: formData
    })
    .then(function(r){ return r.json(); })
    .then(function(data){
        if (data.success) {
            closeModal();
            showToast('出貨資料已儲存！', 'success');
            setTimeout(function() { window.location.reload(); }, 600);
        } else {
            showError(data.error === 'insufficient_stock' ? '成品倉庫存不足，無法出貨。' : (data.error === 'exceed_order_remaining' ? '出貨數量超出訂單剩餘可出量。' : (data.error || '操作失敗')));
            document.getElementById('addSubmitBtn').disabled = false;
        }
    })
    .catch(function(){
        showError('系統錯誤，請稍後再試');
        document.getElementById('addSubmitBtn').disabled = false;
    });
}

function escHtml(s) {
    if (!s) return '';
    var d = document.createElement('div');
    d.textContent = s;
    return d.innerHTML;
}

/* ── Edit Modal ────────────────────────────────────────────── */
function openEditModal(id) {
    if (!overlay) initModal();
    overlay.style.display = 'flex';
    titleEl.textContent = '編輯出貨記錄';
    errDiv.style.display = 'none';

    fetch(CTX + '/DeliveryServlet?action=getDelivery&id=' + id)
        .then(function(r){ return r.json(); })
        .then(function(d){
            if (!d.success) { showError(d.error || '載入失敗'); return; }

            formEl.innerHTML =
                '<form id="editDeliveryForm">' +
                '<input type="hidden" name="id" value="' + d.id + '">' +
                '<input type="hidden" name="orderId" value="' + d.orderId + '">' +
                '<div style="padding:10px 14px;background:#f8f9fa;border-radius:8px;margin-bottom:16px;font-size:13px;line-height:1.8;">' +
                '<div><b>出貨單號：</b>' + d.deliveryNumber + ' | <b>訂單：</b>' + d.orderNumber + ' | <b>客戶：</b>' + d.customerName + '</div></div>' +
                '<div class="form-group"><label>出貨日期：</label>' +
                '<input type="date" name="deliveryDate" value="' + d.deliveryDate + '" required></div>' +
                '<div class="form-group"><label>出貨數量：</label>' +
                '<input type="number" name="quantity" step="any" value="' + d.quantity + '" required></div>' +
                '<div class="form-group"><label>狀態：</label>' +
                '<select name="status">' +
                '<option value="1"' + (d.status === 1 ? ' selected' : '') + '>已出貨</option>' +
                '<option value="0"' + (d.status === 0 ? ' selected' : '') + '>取消</option></select></div>' +
                '<div class="form-group"><label>備註：</label>' +
                '<textarea name="note" rows="2">' + (d.note || '') + '</textarea></div>' +
                '<div style="display:flex;gap:12px;margin-top:16px;">' +
                '<button type="button" onclick="submitEditForm()" class="btn-submit" id="editSubmitBtn">儲存修改</button>' +
                '<button type="button" onclick="closeModal()" class="btn-submit" style="background:#6c757d;">取消</button></div>' +
                '</form>';
        })
        .catch(function(){ showError('系統錯誤，無法載入資料'); });
}

function submitEditForm() {
    var form = document.getElementById('editDeliveryForm');
    var formData = new FormData(form);

    document.getElementById('editSubmitBtn').disabled = true;

    fetch(CTX + '/DeliveryServlet', {
        method: 'POST',
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        body: formData
    })
    .then(function(r){ return r.json(); })
    .then(function(data){
        if (data.success) {
            closeModal();
            showToast('出貨資料已更新！', 'success');
            setTimeout(function() { window.location.reload(); }, 600);
        } else {
            showError(data.error === 'insufficient_stock' ? '成品倉庫存不足，無法出貨。' : (data.error === 'exceed_order_remaining' ? '出貨數量超出訂單剩餘可出量。' : (data.error || '操作失敗')));
            document.getElementById('editSubmitBtn').disabled = false;
        }
    })
    .catch(function(){
        showError('系統錯誤，請稍後再試');
        document.getElementById('editSubmitBtn').disabled = false;
    });
}
</script>

<%@ include file="../include/footer.jsp" %>
