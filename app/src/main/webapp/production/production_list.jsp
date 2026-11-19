<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.SimpleDateFormat, util.NumberUtil, dao.ProductionDao, dao.OrderDao, model.Production" %>
<% request.setAttribute("pageTitle", "生產管理"); %>
<% request.setAttribute("pageIcon", "⚙"); %>
<% request.setAttribute("pageSubtitle", "工單開立、生產進度與成品入庫"); %>
<%@ include file="../include/header.jsp" %>
<%@ taglib prefix="my" tagdir="/WEB-INF/tags" %>

    <%
        String filterOrderId = request.getParameter("orderId");
        String filterCustomer = request.getParameter("filterCustomer");
        String filterOrderNumber = request.getParameter("filterOrderNumber");
        String filterProduct = request.getParameter("filterProduct");
        String dateFrom = request.getParameter("dateFrom");
        String dateTo = request.getParameter("dateTo");
        String keyword = request.getParameter("keyword");
        String filterCloseStatus = request.getParameter("closeStatus");
        String filterProdStatus = request.getParameter("prodStatus");
        boolean isFiltered = filterOrderId != null && !filterOrderId.isEmpty();

        java.time.LocalDate today = java.time.LocalDate.now();
        java.time.LocalDate defaultFrom = today;
        java.time.LocalDate defaultTo = today.plusDays(7);
        String useDate = request.getParameter("useDate");
        boolean dateEnabled = "1".equals(useDate);

        int pageNum = 1;
        int pageSize = 20;
        String pageParam = request.getParameter("page");
        if (pageParam != null) {
            try { pageNum = Integer.parseInt(pageParam); if (pageNum < 1) pageNum = 1; } catch (NumberFormatException e) {}
        }
        int startIdx = (pageNum - 1) * pageSize;
        String baseUrl = "production_list.jsp?submitted=1"
            + (dateEnabled ? "&useDate=1" : "")
            + (dateFrom != null && !dateFrom.isEmpty() ? "&dateFrom=" + dateFrom : "")
            + (dateTo != null && !dateTo.isEmpty() ? "&dateTo=" + dateTo : "")
            + (filterCustomer != null && !filterCustomer.trim().isEmpty() ? "&filterCustomer=" + java.net.URLEncoder.encode(filterCustomer.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
            + (filterOrderNumber != null && !filterOrderNumber.trim().isEmpty() ? "&filterOrderNumber=" + java.net.URLEncoder.encode(filterOrderNumber.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
            + (filterProduct != null && !filterProduct.trim().isEmpty() ? "&filterProduct=" + java.net.URLEncoder.encode(filterProduct.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
            + (keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword.trim(), java.nio.charset.StandardCharsets.UTF_8) : "")
            + (filterCloseStatus != null && !filterCloseStatus.isEmpty() ? "&closeStatus=" + filterCloseStatus : "")
            + (filterProdStatus != null && !filterProdStatus.isEmpty() ? "&prodStatus=" + filterProdStatus : "")
            + (filterOrderId != null && !filterOrderId.isEmpty() ? "&orderId=" + filterOrderId : "");
    %>

    <% if (isFiltered) { %>
    <div style="margin-bottom:16px;">
        <a href="production_list.jsp" class="btn btn-outline">← 返回全部工單</a>
    </div>
    <% } %>

    <% if (!isFiltered) { %>
    <form class="filter-bar" method="GET" id="filterForm">
        <div class="date-range-wrap">
            <input type="checkbox" name="useDate" value="1" <%= dateEnabled ? "checked" : "" %> onchange="toggleDateRange(this)" style="margin:0;">
            <label style="margin:0;">生產日</label>
            <input type="date" name="dateFrom" id="dateFrom" value="<%= dateFrom != null ? dateFrom : defaultFrom.toString() %>" <%= dateEnabled ? "" : "disabled" %> style="width:auto;">
            <span style="color:#6c757d;">~</span>
            <input type="date" name="dateTo" id="dateTo" value="<%= dateTo != null ? dateTo : defaultTo.toString() %>" <%= dateEnabled ? "" : "disabled" %> style="width:auto;">
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
            <div class="field">
                <label>工單狀態</label>
                <select name="closeStatus">
                    <option value="">全部</option>
                    <option value="0" <%= "0".equals(filterCloseStatus) ? "selected" : "" %>>未結案</option>
                    <option value="1" <%= "1".equals(filterCloseStatus) ? "selected" : "" %>>已結案</option>
                </select>
            </div>
            <div class="field">
                <label>生產進度</label>
                <select name="prodStatus">
                    <option value="">全部</option>
                    <option value="0" <%= "0".equals(filterProdStatus) ? "selected" : "" %>>待生產</option>
                    <option value="1" <%= "1".equals(filterProdStatus) ? "selected" : "" %>>生產中</option>
                    <option value="2" <%= "2".equals(filterProdStatus) ? "selected" : "" %>>已完成</option>
                    <option value="3" <%= "3".equals(filterProdStatus) ? "selected" : "" %>>暫停中</option>
                </select>
            </div>
            <button type="submit" class="btn-search">查詢</button>
            <a href="production_list.jsp" class="btn-clear">清除</a>
        </div>
    </form>
    <script>
    function toggleDateRange(cb) {
        document.getElementById('dateFrom').disabled = !cb.checked;
        document.getElementById('dateTo').disabled = !cb.checked;
    }
    </script>
    <% } %>

    <script>
    (function() {
        var p = new URLSearchParams(window.location.search);
        var msg = p.get('message'), err = p.get('error');
        var text = null, type = 'success';
        if (msg === 'success') { text = '工單資料已儲存！'; }
        else if (msg === 'deleted' || msg === 'paused') { text = '工單已暫停！'; }
        else if (msg === 'restored') { text = '工單已恢復！'; }
        else if (msg === 'receipt_ok') { text = '成品入庫成功！'; }
        else if (msg === 'closed') { text = '工單已結案！'; }
        else if (msg === 'unclosed') { text = '工單已反結案！'; }
        else if (err === 'deletefailed') { text = '刪除失敗，此工單可能已有相關記錄無法刪除。'; type = 'error'; }
        else if (err === 'delete_blocked') { text = '此工單已入庫，無法暫停。請先沖正入庫。'; type = 'error'; }
        else if (err === 'not_completed') { text = '工單尚未完成，無法結案。'; type = 'error'; }
        else if (err === 'not_all_received') { text = '尚有未入庫的成品，請先完成入庫再結案。'; type = 'error'; }
        else if (err === 'already_closed') { text = '此工單已結案。'; type = 'error'; }
        else if (err === 'cancelled_cannot_close') { text = '暫停中的工單無法結案。'; type = 'error'; }
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

    <div style="display:flex;justify-content:flex-end;margin-bottom:16px;">
        <% if (isFiltered) { %>
            <button onclick="openAddProdModal(<%= filterOrderId %>)" class="btn btn-primary">+ 開立工單</button>
        <% } else { %>
            <button onclick="openAddProdModal()" class="btn btn-primary">+ 開立工單</button>
        <% } %>
    </div>

    <%
        String orderNumber = "";
        String customerName = "";
        double orderQuantity = 0;
        double orderManufactured = 0;
        int orderWOCount = 0;
        int orderWOCompleted = 0;
        int orderWOReceived = 0;
        int colCount = 11;
        int totalPages = 1;
        int filteredIdx = 0;
        int displayed = 0;

        ProductionDao prodDao = new ProductionDao();
        List<Map<String, Object>> prodList = new ArrayList<>();

        try {
            if (isFiltered) {
                Map<String, Object> summary = prodDao.getOrderProductionSummary(Integer.parseInt(filterOrderId));
                if (!summary.isEmpty()) {
                    orderNumber = (String) summary.getOrDefault("orderNumber", "");
                    customerName = (String) summary.getOrDefault("customerName", "");
                    orderQuantity = (double) summary.getOrDefault("quantity", 0.0);
                    orderManufactured = (double) summary.getOrDefault("manuf", 0.0);
                    orderWOCount = (int) summary.getOrDefault("woCount", 0);
                    orderWOCompleted = (int) summary.getOrDefault("woCompleted", 0);
                    orderWOReceived = (int) summary.getOrDefault("woReceived", 0);
                }
            }

            int orderIdParam = isFiltered && filterOrderId != null && !filterOrderId.isEmpty() ? Integer.parseInt(filterOrderId) : 0;
            prodList = prodDao.getFilteredProductionList(
                orderIdParam, dateFrom, dateTo,
                filterCustomer, filterOrderNumber, filterProduct,
                keyword, filterCloseStatus, filterProdStatus,
                isFiltered, dateEnabled
            );

            String[] statusLabels = {"待生產", "生產中", "已完成", "暫停中", "已結案"};

    %>

    <% if (isFiltered) {
        int opct = orderQuantity > 0 ? (int)Math.min(Math.round(orderManufactured / orderQuantity * 100), 100) : 0;
    %>
        <div style="background:#fff;border:1px solid #e0e0e0;border-radius:8px;padding:16px 20px;margin-bottom:16px;">
            <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:12px;">
                <div>
                    <div style="font-size:18px;font-weight:700;color:#333;"><span style="font-size:14px;font-weight:400;color:#666;">訂單編號：</span><%= orderNumber %></div>
                    <div style="font-size:14px;color:#666;margin-top:2px;"><span style="font-weight:400;">客戶：</span><b style="color:#333;"><%= customerName %></b></div>
                </div>
                <div style="display:flex;gap:24px;align-items:center;font-size:14px;">
                    <div>訂單數量 <b><%= NumberUtil.fmtQty(orderQuantity) %></b></div>
                    <div>已製 <b><%= NumberUtil.fmtQty(orderManufactured) %></b></div>
                    <div>
                        進度
                        <div class="progress-bar" style="width:120px;height:16px;display:inline-block;vertical-align:middle;">
                            <div class="progress-fill" style="width:<%= opct %>%;background-color:#007bff;line-height:16px;font-size:11px;"><%= opct %>%</div>
                        </div>
                    </div>
                    <div>工單 <b style="color:#28a745;"><%= orderWOCompleted %></b>/<b><%= orderWOCount %></b></div>
                    <div>入庫 <b style="color:#1565c0;"><%= orderWOReceived %></b>/<b><%= orderWOCompleted %></b></div>
                </div>
            </div>
        </div>
    <% } %>

    <div class="table-container" style="display:flex;flex-direction:column;padding:0;">
    <table id="prodTable" style="order:2;width:100%;">
        <thead>
            <tr class="col-header">
                <th>序號</th>
                <th data-col="0" onclick="sortProdTable(0,'str')" style="cursor:pointer;">客戶 ↕</th>
                <th data-col="1" onclick="sortProdTable(1,'str')" style="cursor:pointer;">訂單編號 ↕</th>
                <th data-col="2" onclick="sortProdTable(2,'str')" style="cursor:pointer;">工單編號 ↕</th>
                <th data-col="3" onclick="sortProdTable(3,'str')" style="cursor:pointer;">品項 ↕</th>
                <th>已製 / 預計 (待製)</th>
                <th data-col="5" onclick="sortProdTable(5,'str')" style="cursor:pointer;">狀態 ↕</th>
                <th>入庫</th>
                <th data-col="7" onclick="sortProdTable(7,'date')" style="cursor:pointer;">開始日 ↕</th>
                <th data-col="8" onclick="sortProdTable(8,'date')" style="cursor:pointer;">目標日 ↕</th>
                <th data-col="9" onclick="sortProdTable(9,'date')" style="cursor:pointer;">維護時間 ↕</th>
                <th>操作</th>
            </tr>
        </thead>
        <tbody>
            <%
                boolean hasData = false;

                for (Map<String, Object> row : prodList) {
                    hasData = true;

                    filteredIdx++;
                    if (filteredIdx <= startIdx) continue;
                    if (displayed >= pageSize) continue;
                    displayed++;

                    int oid = (int) row.get("orderId");
                    String cname = (String) row.get("customerName");
                    String onum = (String) row.get("orderNumber");

                    int dbSt = (int) row.get("status");
                    int closeSt = (int) row.get("closeStatus");
                    double planned = (double) row.get("producedQty");
                    double manuf = (double) row.get("manufacturedQty");

                    int dispSt = dbSt;
                    String dispLabel = statusLabels[dbSt];
                    if (closeSt == 1) {
                        dispSt = 4; dispLabel = "已結案";
                    } else if (dbSt == 3) {
                        dispSt = 3; dispLabel = "暫停中";
                    } else if (manuf >= planned && planned > 0) {
                        dispSt = 2; dispLabel = "已完成";
                    } else if (manuf > 0) {
                        dispSt = 1; dispLabel = "生產中";
                    } else {
                        dispSt = 0; dispLabel = "待生產";
                    }

                    java.sql.Date startDt = (java.sql.Date) row.get("startDate");
                    java.sql.Date targetDt = (java.sql.Date) row.get("targetDate");
                    String startDateStr = startDt != null ? startDt.toString() : "";
                    String targetDateStr = targetDt != null ? targetDt.toString() : "";
                    java.sql.Timestamp updatedTs = (java.sql.Timestamp) row.get("updatedAt");
                    String updatedStr = updatedTs != null ? new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm").format(updatedTs) : "";
                    int prodId = (int) row.get("id");
                    String prodNumber = (String) row.get("productionNumber");
                    String prodName = (String) row.get("productName");
                    double recvQty = (double) row.get("receivedQty");
                    double netRecv = (double) row.get("netReceived");
                    int priceType = (int) row.get("priceType");
            %>
                        <tr class="data-row"
                            data-prod-id="<%= prodId %>"
                            data-customer="<%= cname != null ? cname : "" %>"
                            data-order="<%= onum != null ? onum : "" %>"
                            data-startdate="<%= startDateStr %>"
                            data-targetdate="<%= targetDateStr %>"
                            data-updated="<%= updatedStr %>">
                            <td><%= filteredIdx %></td>
                            <td><%= cname != null ? cname : "" %></td>
                            <td><a href="../order/order_list.jsp?orderId=<%= oid %>" style="color:#1a1a2e;text-decoration:underline;font-weight:600;"><%= onum != null ? onum : "" %></a></td>
                            <td><b style="cursor:pointer;color:#1565c0;text-decoration:underline;" onclick="event.stopPropagation();openEditProdModal(<%= prodId %>)"><%= prodNumber %></b></td>
                            <td><%= prodName %></td>
                            <td><%= NumberUtil.fmtQty(manuf) %> / <%= NumberUtil.fmtQty(planned) %> <span style="color:#6c757d;font-size:11px;">(待 <%= NumberUtil.fmtQty(Math.max(0, planned - manuf)) %>)</span></td>
                            <td><span class="badge badge-<%= dispSt == 4 ? "blue" : dispSt == 0 ? "blue" : dispSt == 1 ? "orange" : dispSt == 2 ? "green" : "gray" %>" style="cursor:pointer;" onclick="event.stopPropagation();openEditProdModal(<%= prodId %>)"><%= dispLabel %></span></td>
                            <td><%
                                if (dbSt == 3) { %><span class="badge badge-gray">-</span><%
                                } else if (netRecv <= 0 && manuf > 0) { %><a href="receipt.jsp?id=<%= prodId %>&orderId=<%= oid %>" class="badge badge-red">未入庫</a><%
                                } else if (netRecv > 0 && netRecv >= manuf) { %><a href="receipt_reverse.jsp?id=<%= prodId %>&orderId=<%= oid %>" class="badge badge-green">已入庫</a><%
                                } else if (netRecv > 0) { %><a href="receipt.jsp?id=<%= prodId %>&orderId=<%= oid %>" class="badge badge-orange">部分入庫</a><%
                                } else { %><span class="badge badge-gray">-</span><%
                                } %>
                                <% if (netRecv > 0 && dbSt != 3) { %>
                                    <a href="javascript:void(0);" onclick="openEditRecvModal(<%= prodId %>, <%= oid %>, <%= netRecv %>, '<%= priceType == 1 ? "kg" : "pcs" %>')" style="font-size:11px;color:#4361ee;text-decoration:none;margin-left:4px;">修改</a>
                                <% } %></td>
                            <td><%= startDateStr.isEmpty() ? "-" : startDateStr %></td>
                            <td><%= targetDateStr.isEmpty() ? "-" : targetDateStr %></td>
                            <td style="font-size:12px;color:#6c757d;"><%= updatedStr.isEmpty() ? "-" : new java.text.SimpleDateFormat("MM/dd HH:mm").format(updatedTs) %></td>
                            <td>
                                <% if (closeSt == 1) { %>
                                    <a href="<%= request.getContextPath() %>/ProductionServlet?action=unclose&id=<%= prodId %>&orderId=<%= oid %>" class="btn btn-outline btn-sm" onclick="return confirm('確定反結案此工單？')">反結案</a>
                                <% } else { %>
                                    <% if (dispSt == 2) { %>
                                        <a href="<%= request.getContextPath() %>/ProductionServlet?action=close&id=<%= prodId %>&orderId=<%= oid %>" class="btn btn-info btn-sm" onclick="return confirm('確定結案？結案後將無法再修改此工單。')">結案</a>
                                    <% } %>
                                    <% if (dispSt == 3) { %>
                                        <a href="<%= request.getContextPath() %>/ProductionServlet?action=restore&id=<%= prodId %>&orderId=<%= oid %>" class="btn btn-outline btn-sm" onclick="return confirm('確定恢復此工單？')">恢復</a>
                                    <% } else if (dispSt == 0 || dispSt == 1) { %>
                                        <a href="<%= request.getContextPath() %>/ProductionServlet?action=pause&id=<%= prodId %>&orderId=<%= oid %>" class="btn btn-danger btn-sm" onclick="return confirm('確定暫停此工單？')">暫停</a>
                                    <% } %>
                                <% } %>
                            </td>
                        </tr>
            <%
                }

                if (!hasData) {
            %>
                        <tr>
                            <td colspan="<%= colCount + 1 %>" style="text-align:center;padding:30px;color:#999;">
                                目前尚無工單資料
                                <% if (isFiltered) { %><br>
                                <button onclick="openAddProdModal(<%= filterOrderId %>)" class="btn btn-primary btn-sm" style="margin-top:10px;">＋開立工單</button>
                                <% } %>
                            </td>
                        </tr>
            <%
                }
                filteredIdx = prodList.size();
                totalPages = filteredIdx > 0 ? (int) Math.ceil((double) filteredIdx / pageSize) : 1;
                if (pageNum > totalPages) pageNum = totalPages;
            } catch (Exception e) {
                out.println("<tr><td colspan='" + colCount + "' style='color:red;padding:20px;'>錯誤：" + e.getMessage() + "</td></tr>");
                e.printStackTrace();
            }
            %>
    </tbody>
</table>
<div style="order:1;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= totalPages %>" totalCount="<%= filteredIdx %>" baseUrl="<%= baseUrl %>" position="top"/></div>
<div style="order:3;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= totalPages %>" totalCount="<%= filteredIdx %>" baseUrl="<%= baseUrl %>"/></div>
</div>

<script>
var sortState = {col: -1, asc: true};

function sortProdTable(colIdx, type) {
    var table = document.getElementById('prodTable');
    var tbody = table.tBodies[0];
    var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr.data-row'));
    if (rows.length === 0) return;

    if (sortState.col === colIdx) { sortState.asc = !sortState.asc; }
    else { sortState.col = colIdx; sortState.asc = true; }

    var sortKeys = ['customer','order','_text','_text','_num','_text','_text','startdate','targetdate','updated','_text'];

    rows.sort(function(a, b) {
        var av, bv;
        var key = sortKeys[colIdx];
        if (key === 'startdate' || key === 'targetdate' || key === 'updated') {
            av = a.getAttribute('data-' + key) || '0000';
            bv = b.getAttribute('data-' + key) || '0000';
        } else if (key === '_num') {
            av = parseFloat(a.cells[colIdx].textContent) || 0;
            bv = parseFloat(b.cells[colIdx].textContent) || 0;
            return sortState.asc ? av - bv : bv - av;
        } else {
            av = a.cells[colIdx].textContent.trim().toLowerCase();
            bv = b.cells[colIdx].textContent.trim().toLowerCase();
        }
        if (av < bv) return sortState.asc ? -1 : 1;
        if (av > bv) return sortState.asc ? 1 : -1;
        return 0;
    });

    var frag = document.createDocumentFragment();
    rows.forEach(function(r) { frag.appendChild(r); });
    tbody.appendChild(frag);

    table.querySelectorAll('thead th').forEach(function(th) {
        var ci = parseInt(th.getAttribute('data-col'));
        if (isNaN(ci)) return;
        var base = th.textContent.replace(/ [↑↓↕]$/, '');
        th.textContent = base + (ci === colIdx ? (sortState.asc ? ' ↑' : ' ↓') : ' ↕');
    });
}
</script>

<%
    OrderDao orderDao = new OrderDao();
    List<Map<String, Object>> prodOrderList = orderDao.getOpenOrdersForProduction();
%>

<div id="prodOverlay" class="confirm-overlay" style="display:none;">
  <div class="dialog-box-lg" style="max-height:90vh;overflow-y:auto;">
    <h3 id="prodModalTitle">開立工單</h3>
    <div id="prodFormError" class="error-msg" style="display:none;"></div>

    <div id="prodOrderSection">
      <div class="form-group">
        <label>選擇來源訂單：</label>
        <select id="prodOrderId" onchange="loadProdOrder()">
          <option value="">-- 請選擇訂單 --</option>
<% for (Map<String, Object> o : prodOrderList) {
    String expD = o.get("expectedDeliveryDate") != null ? o.get("expectedDeliveryDate").toString() : "";
    String ordNum = (String) o.get("orderNumber");
    String custName = (String) o.get("customerName");
    String ordId = o.get("id").toString();
%>
          <option value="<%= ordId %>" data-customer="<%= custName != null ? custName.replace("\"","&quot;") : "" %>" data-order="<%= ordNum != null ? ordNum.replace("\"","&quot;") : "" %>" data-expdelivery="<%= expD %>"><%= ordNum %> - <%= custName %></option>
<% } %>
        </select>
      </div>
      <div id="prodOrderRef" style="display:none;background:#f0f7ff;border:1px solid #b3d4fc;border-radius:8px;padding:14px 18px;margin-bottom:20px;">
        <div style="font-weight:600;color:#1565c0;margin-bottom:8px;font-size:13px;">📋 訂單資訊</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;font-size:13px;">
          <div><span style="color:#6c757d;">客戶：</span><span id="prodRefCust" style="font-weight:600;">-</span></div>
          <div><span style="color:#6c757d;">訂單編號：</span><span id="prodRefOrdNum" style="font-weight:600;">-</span></div>
          <div><span style="color:#6c757d;">訂單總量：</span><span id="prodRefQty" style="font-weight:600;">-</span></div>
          <div><span style="color:#6c757d;">已生產量：</span><span id="prodRefManuf" style="font-weight:600;">-</span></div>
          <div><span style="color:#6c757d;">已開立工單：</span><span id="prodRefWoCount" style="font-weight:600;">-</span></div>
          <div><span style="color:#6c757d;">已開立合計：</span><span id="prodRefWoQty" style="font-weight:600;">-</span></div>
          <div><span style="color:#6c757d;">剩餘待產：</span><span id="prodRefRemain" style="font-weight:600;color:#d32f2f;">-</span></div>
          <div><span style="color:#6c757d;">預計交期：</span><span id="prodRefDeliv" style="font-weight:600;">-</span></div>
        </div>
      </div>
    </div>

    <input type="hidden" id="prodOrderIdHidden">

    <div id="prodProdSection" style="display:none;">
      <div class="row-2">
        <div class="form-group"><label>品項：</label><select id="prodProductId" onchange="fillProdProductInfo()"><option value="">-- 先選訂單 --</option></select></div>
        <div class="form-group"><label>計價方式：</label><input type="text" id="prodPriceTypeDisp" readonly></div>
      </div>
      <div class="row-2">
        <div class="form-group"><label>代工單價：</label><input type="text" id="prodUnitPriceDisp" readonly></div>
        <div class="form-group"><label>單個重量 (kg)：</label><input type="text" id="prodUnitWeightDisp" readonly></div>
      </div>
    </div>

    <div id="prodEditRef" style="display:none;background:#f0f7ff;border:1px solid #b3d4fc;border-radius:8px;padding:14px 18px;margin-bottom:20px;">
      <div style="font-weight:600;color:#1565c0;margin-bottom:8px;font-size:13px;">📋 訂單資訊</div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;font-size:13px;">
        <div><span style="color:#6c757d;">工單編號：</span><span id="peNum" style="font-weight:600;">-</span></div>
        <div><span style="color:#6c757d;">來源訂單：</span><span id="peOrdNum" style="font-weight:600;">-</span></div>
        <div><span style="color:#6c757d;">客戶：</span><span id="peCust" style="font-weight:600;">-</span></div>
        <div><span style="color:#6c757d;">品項：</span><span id="peProd" style="font-weight:600;">-</span></div>
        <div><span style="color:#6c757d;">訂單總量：</span><span id="peQty" style="font-weight:600;">-</span></div>
        <div><span style="color:#6c757d;">其他工單已產：</span><span id="peOther" style="font-weight:600;">-</span></div>
        <div><span style="color:#6c757d;">預計交期：</span><span id="peDeliv" style="font-weight:600;">-</span></div>
        <div><span style="color:#6c757d;">計價方式：</span><span id="pePType" style="font-weight:600;">-</span></div>
      </div>
    </div>

    <div style="border:2px solid #e3f2fd;border-radius:10px;padding:16px 18px;margin-bottom:16px;background:#fafcff;">
      <div style="font-weight:600;color:#1565c0;margin-bottom:12px;font-size:14px;">📝 預計生產</div>
      <div class="row-2">
        <div class="form-group"><label>訂單總數量：</label><input type="number" id="prodQuantity" readonly></div>
        <div class="form-group"><label>本工單預計生產量：</label><input type="number" id="prodProducedQty" step="any" required>
          <span id="prodRemainHint" style="font-size:12px;color:#6c757d;display:block;margin-top:3px;"></span></div>
      </div>
      <div class="row-2">
        <div class="form-group"><label>預計開始日：</label><input type="date" id="prodStartDate"></div>
        <div class="form-group"><label>預計完成日：</label><input type="date" id="prodTargetDate"></div>
      </div>
    </div>

    <div id="prodActualSection" style="display:none;border:2px solid #e8f5e9;border-radius:10px;padding:16px 18px;margin-bottom:16px;background:#fafffa;">
      <div style="font-weight:600;color:#2e7d32;margin-bottom:12px;font-size:14px;">🏭 實際生產</div>
      <div class="form-group"><label>已製造數量：</label><input type="number" id="prodManufacturedQty" step="any" onchange="checkAutoCompleteDate()">
        <span id="prodManufHint" style="font-size:12px;color:#6c757d;display:block;margin-top:3px;"></span></div>
      <div class="form-group"><label>實際完成日：</label><input type="date" id="prodCompletedDate" readonly style="background:#f0f0f0;"></div>
    </div>

    <div class="form-group" id="prodNoteWrap">
      <label>備註：<span id="prodNoteToggle" onclick="toggleNoteInput()" style="cursor:pointer;font-size:13px;margin-left:4px;" title="新增備註">✏️</span></label>
      <textarea id="prodNote" rows="2" style="display:none;"></textarea>
    </div>

    <div id="prodTimestamps" style="display:none;font-size:12px;color:#6c757d;margin-bottom:12px;padding:8px 12px;background:#f8f9fa;border-radius:6px;">
      <span id="peCreated"></span><br><span id="peUpdated"></span>
    </div>

    <input type="hidden" id="prodId">
    <input type="hidden" id="prodStatus">
    <input type="hidden" id="prodPriceType">
    <input type="hidden" id="prodUnitPrice">
    <input type="hidden" id="prodUnitWeight">

    <div id="prodActions" style="display:none;gap:8px;margin-bottom:12px;">
      <button type="button" onclick="restoreProd()" class="btn btn-outline btn-sm" id="prodRestoreBtn" style="display:none;">恢復工單</button>
      <button type="button" onclick="pauseProd()" class="btn btn-danger btn-sm" id="prodPauseBtn" style="display:none;">暫停工單</button>
      <button type="button" onclick="permanentDeleteProd()" class="btn btn-danger btn-sm" id="prodDeleteBtn" style="display:none;background:#8b0000;">永久刪除</button>
    </div>

    <button type="button" onclick="showProdConfirm()" class="btn-submit" id="prodSubmitBtn">確認</button>
    <button type="button" onclick="closeProdModal()" class="btn-cancel">取消</button>
  </div>
</div>

<script>
var CTX = '<%= request.getContextPath() %>';
var prodOrderDataCache = {};

function openAddProdModal(preOrderId) {
    var ov = document.getElementById('prodOverlay');
    ov.style.display = 'flex';
    document.getElementById('prodModalTitle').textContent = '開立工單';
    document.getElementById('prodFormError').style.display = 'none';
    document.getElementById('prodSubmitBtn').textContent = '確認開立';
    document.getElementById('prodSubmitBtn').disabled = false;
    document.getElementById('prodOrderSection').style.display = 'block';
    document.getElementById('prodProdSection').style.display = 'none';
    document.getElementById('prodEditRef').style.display = 'none';
    document.getElementById('prodActualSection').style.display = 'none';
    document.getElementById('prodRemainHint').textContent = '';
    document.getElementById('prodManufHint').textContent = '';
    document.getElementById('prodOrderId').value = preOrderId || '';
    document.getElementById('prodOrderRef').style.display = 'none';
    document.getElementById('prodProducedQty').value = '';
    document.getElementById('prodStartDate').value = prodTodayStr();
    document.getElementById('prodTargetDate').value = prodFutureStr(14);
    document.getElementById('prodNote').value = '';
    document.getElementById('prodNote').style.display = 'none';
    document.getElementById('prodTimestamps').style.display = 'none';
    document.getElementById('prodId').value = '';
    document.getElementById('prodStatus').value = '0';
    document.getElementById('prodOrderIdHidden').value = '';
    if (preOrderId) loadProdOrder();
}

function openEditProdModal(id) {
    var ov = document.getElementById('prodOverlay');
    ov.style.display = 'flex';
    document.getElementById('prodModalTitle').textContent = '編輯工單';
    document.getElementById('prodFormError').style.display = 'none';
    document.getElementById('prodSubmitBtn').textContent = '儲存修改';
    document.getElementById('prodSubmitBtn').disabled = false;
    document.getElementById('prodOrderSection').style.display = 'none';
    document.getElementById('prodProdSection').style.display = 'none';
    document.getElementById('prodEditRef').style.display = 'block';
    document.getElementById('prodActualSection').style.display = 'block';
    document.getElementById('prodManufHint').textContent = '';

    fetch(CTX + '/ProductionServlet?action=get&id=' + id)
        .then(function(r){return r.json();})
        .then(function(d){
            if(!d.success){document.getElementById('prodFormError').textContent='載入失敗';document.getElementById('prodFormError').style.display='block';return;}
            document.getElementById('prodId').value=d.id;
            document.getElementById('prodOrderIdHidden').value=d.orderId;
            document.getElementById('prodStatus').value=d.status;
            var pidSel=document.getElementById('prodProductId');
            pidSel.innerHTML='<option value="'+d.productId+'">'+(d.productName||'品項-'+d.productId)+'</option>';
            pidSel.value=d.productId;
            document.getElementById('prodPriceType').value=d.priceType;
            document.getElementById('prodUnitPrice').value=d.unitPrice;
            document.getElementById('prodUnitWeight').value=d.unitWeight;
            document.getElementById('prodQuantity').value=cleanNum(d.orderQuantity);
            document.getElementById('prodProducedQty').value=cleanNum(d.producedQty);
            document.getElementById('prodManufacturedQty').value=cleanNum(d.manufacturedQty);
            document.getElementById('prodStartDate').value=d.startDate;
            document.getElementById('prodTargetDate').value=d.targetDate;
            document.getElementById('prodCompletedDate').value=d.completedDate||'';
            showNoteIfHasValue(d.note);
            var cDate=document.getElementById('prodCompletedDate');
            if(cDate.value){cDate.removeAttribute('readonly');cDate.style.background='';}
            else{cDate.setAttribute('readonly',true);cDate.style.background='#f0f0f0';}
            var u=d.priceType==1?'kg':'pcs';
            document.getElementById('peNum').textContent=d.productionNumber||'-';
            document.getElementById('peOrdNum').textContent=d.orderNumber;
            document.getElementById('peCust').textContent=d.customerName;
            document.getElementById('peProd').textContent=d.productName;
            document.getElementById('peQty').textContent=cleanNum(d.quantity)+' '+u;
            document.getElementById('peOther').textContent=cleanNum(d.otherManufactured)+' '+u;
            document.getElementById('peDeliv').textContent=d.expectedDeliveryDate||'-';
            document.getElementById('pePType').textContent=d.priceType==1?'按重量 (kg)':'按個數 (pcs)';
            if(parseFloat(d.receivedQty)>0){document.getElementById('prodManufHint').textContent='已入庫 '+cleanNum(d.receivedQty)+'，已製造不可低於此數';}
            document.getElementById('prodTimestamps').style.display='block';
            document.getElementById('peCreated').textContent='建立時間：'+(d.createdAt||'-');
            document.getElementById('peUpdated').textContent='維護時間：'+(d.updatedAt||'-');
            var actDiv=document.getElementById('prodActions');
            var isPaused=d.status==3;
            var hasReceived=parseFloat(d.receivedQty)>0;
            var closeSt=d.closeStatus;
            actDiv.style.display=(isPaused||(!isPaused&&closeSt!=1))?'flex':'none';
            document.getElementById('prodRestoreBtn').style.display=isPaused?'':'none';
            document.getElementById('prodPauseBtn').style.display=(!isPaused&&closeSt!=1)?'':'none';
            document.getElementById('prodDeleteBtn').style.display=(isPaused&&!hasReceived)?'':'none';
            if(isPaused){document.getElementById('prodSubmitBtn').disabled=true;document.getElementById('prodSubmitBtn').style.opacity='0.5';}
            else{document.getElementById('prodSubmitBtn').disabled=false;document.getElementById('prodSubmitBtn').style.opacity='1';}
        })
        .catch(function(){document.getElementById('prodFormError').textContent='系統錯誤';document.getElementById('prodFormError').style.display='block';});
}

function closeProdModal(){document.getElementById('prodOverlay').style.display='none';}

function pauseProd(){
    if(!confirm('確定暫停此工單？'))return;
    var id=document.getElementById('prodId').value;
    var orderId=document.getElementById('prodOrderId').value;
    postAction(CTX+'/ProductionServlet?action=pause&id='+id+'&orderId='+orderId);
}

function restoreProd(){
    if(!confirm('確定恢復此工單？'))return;
    var id=document.getElementById('prodId').value;
    var fd=new FormData();
    fd.append('action','restore');fd.append('id',id);
    fetch(CTX+'/ProductionServlet',{method:'POST',headers:{'X-Requested-With':'XMLHttpRequest'},body:fd})
    .then(function(r){return r.json();})
    .then(function(d){
        if(d.success){showToast('工單已恢復！','success');setTimeout(function(){location.reload();},1000);}
        else{var err=document.getElementById('prodFormError');err.textContent=d.error||'恢復失敗';err.style.display='block';}
    })
    .catch(function(){var err=document.getElementById('prodFormError');err.textContent='系統錯誤';err.style.display='block';});
}

function permanentDeleteProd(){
    if(!confirm('確定永久刪除此工單？此操作無法復原！'))return;
    if(!confirm('再次確認：您確定要永久刪除嗎？'))return;
    var id=document.getElementById('prodId').value;
    var orderId=document.getElementById('prodOrderId').value;
    postAction(CTX+'/ProductionServlet?action=delete&id='+id+'&orderId='+orderId);
}

function toggleNoteInput(){
    var ta=document.getElementById('prodNote');
    if(ta.style.display==='none'){ta.style.display='';ta.focus();}
    else{ta.style.display='none';}
}

function showNoteIfHasValue(note){
    var ta=document.getElementById('prodNote');
    if(note&&note.trim()){ta.value=note;ta.style.display='';}
    else{ta.value='';ta.style.display='none';}
}

function loadProdOrder(){
    var sel=document.getElementById('prodOrderId');
    var opt=sel.options[sel.selectedIndex];
    if(!sel.value){document.getElementById('prodOrderRef').style.display='none';document.getElementById('prodProdSection').style.display='none';return;}
    document.getElementById('prodRefCust').textContent=opt.getAttribute('data-customer')||'-';
    document.getElementById('prodRefOrdNum').textContent=opt.getAttribute('data-order')||'-';
    document.getElementById('prodRefDeliv').textContent=opt.getAttribute('data-expdelivery')||'未設定';
    document.getElementById('prodOrderRef').style.display='block';
    var xhr=new XMLHttpRequest();
    xhr.open('GET','../order/order_data.jsp?id='+sel.value,false);
    try{xhr.send();}catch(e){}
    if(xhr.status===200){
        try{
            var data=JSON.parse(xhr.responseText);
            var sp=document.getElementById('prodProductId');sp.innerHTML='';
            for(var i=0;i<data.length;i++){
                var o=data[i];var op=document.createElement('option');
                op.value=o.product_id;op.text=o.product_name;
                op.setAttribute('data-ptype',o.price_type);
                op.setAttribute('data-price',o.unit_price||'');
                op.setAttribute('data-weight',o.unit_weight||'');
                op.setAttribute('data-qty',o.quantity);
                op.setAttribute('data-manufactured',o.total_manufactured||'0');
                op.setAttribute('data-wo-count',o.production_count||'0');
                op.setAttribute('data-wo-qty',o.total_produced_qty||'0');
                sp.appendChild(op);
            }
            document.getElementById('prodProdSection').style.display='block';
            if(data.length>0)fillProdProductInfo();
        }catch(e){}
    }
}

function fillProdProductInfo(){
    var sel=document.getElementById('prodProductId');
    var opt=sel.options[sel.selectedIndex];if(!opt)return;
    var pt=opt.getAttribute('data-ptype');
    document.getElementById('prodPriceTypeDisp').value=pt=='1'?'按重量 (kg)':'按個數 (pcs)';
    document.getElementById('prodPriceType').value=pt;
    document.getElementById('prodUnitPrice').value=opt.getAttribute('data-price')||'';
    document.getElementById('prodUnitPriceDisp').value=cleanNum(opt.getAttribute('data-price')||'');
    document.getElementById('prodUnitWeight').value=opt.getAttribute('data-weight')||'';
    document.getElementById('prodUnitWeightDisp').value=cleanNum(opt.getAttribute('data-weight')||'');
    var qty=parseFloat(opt.getAttribute('data-qty'))||0;
    var manuf=parseFloat(opt.getAttribute('data-manufactured'))||0;
    var woCount=parseInt(opt.getAttribute('data-wo-count'))||0;
    var woQty=parseFloat(opt.getAttribute('data-wo-qty'))||0;
    var u=pt=='1'?'kg':'pcs';
    var rem=Math.max(qty-woQty,0);
    document.getElementById('prodRefQty').textContent=cleanNum(qty)+' '+u;
    document.getElementById('prodRefManuf').textContent=cleanNum(manuf)+' '+u;
    document.getElementById('prodRefWoCount').textContent=woCount+' 張';
    document.getElementById('prodRefWoQty').textContent=cleanNum(woQty)+' '+u;
    document.getElementById('prodRefRemain').textContent=cleanNum(rem)+' '+u;
    document.getElementById('prodQuantity').value=cleanNum(qty);
    document.getElementById('prodProducedQty').value=cleanNum(rem);
    document.getElementById('prodRemainHint').textContent='可再開立 '+cleanNum(rem)+' '+u+'（已開 '+woCount+' 張合計 '+cleanNum(woQty)+' '+u+'）';
}

function prodTodayStr(){var d=new Date();return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0');}
function prodFutureStr(n){var d=new Date(Date.now()+n*86400000);return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0');}
function cleanNum(v){var n=parseFloat(v);return isNaN(n)?'0':String(n);}

function checkAutoCompleteDate(){
    var manuf=parseFloat(document.getElementById('prodManufacturedQty').value)||0;
    var prod=parseFloat(document.getElementById('prodProducedQty').value)||0;
    var cd=document.getElementById('prodCompletedDate');
    if(manuf>0&&manuf>=prod&&!cd.value){
        cd.value=prodTodayStr();
        cd.removeAttribute('readonly');cd.style.background='';
    }
}

function showProdConfirm(){
    var err=document.getElementById('prodFormError');err.style.display='none';
    var id=document.getElementById('prodId').value;
    var isEdit=id!='';
    if(!isEdit&&!document.getElementById('prodOrderId').value){err.textContent='請選擇來源訂單';err.style.display='block';return;}
    if(!isEdit&&!document.getElementById('prodProductId').value){err.textContent='請選擇品項';err.style.display='block';return;}
    var pq=parseFloat(document.getElementById('prodProducedQty').value);
    if(!pq||pq<=0){err.textContent='請填寫有效的預計生產量';err.style.display='block';return;}

    var selO=document.getElementById('prodOrderId');
    var custName=selO.options[selO.selectedIndex]?selO.options[selO.selectedIndex].getAttribute('data-customer'):'';
    var orderNum=selO.options[selO.selectedIndex]?selO.options[selO.selectedIndex].getAttribute('data-order'):'';
    var prodQty=cleanNum(document.getElementById('prodQuantity').value);
    var producedQty=cleanNum(document.getElementById('prodProducedQty').value);
    var manufQty=isEdit?cleanNum(document.getElementById('prodManufacturedQty').value):'0';
    var startDate=document.getElementById('prodStartDate').value||'-';
    var targetDate=document.getElementById('prodTargetDate').value||'-';
    var compDate=document.getElementById('prodCompletedDate').value||'-';
    var note=document.getElementById('prodNote').value||'';

    var rows='';
    if(isEdit){
        var peNum=document.getElementById('peNum').textContent;
        var peProd=document.getElementById('peProd').textContent;
        rows+='<tr><td>工單編號</td><td>'+peNum+'</td></tr>';
        rows+='<tr><td>品項</td><td>'+peProd+'</td></tr>';
    }else{
        var selP=document.getElementById('prodProductId');
        var prodName=selP.options[selP.selectedIndex]?selP.options[selP.selectedIndex].text:'';
        rows+='<tr><td>客戶</td><td>'+(custName||'-')+'</td></tr>';
        rows+='<tr><td>訂單編號</td><td>'+(orderNum||'-')+'</td></tr>';
        rows+='<tr><td>品項</td><td>'+prodName+'</td></tr>';
    }
    rows+='<tr><td>訂單總量</td><td>'+prodQty+'</td></tr>';
    rows+='<tr><td>預計生產量</td><td>'+producedQty+'</td></tr>';
    rows+='<tr><td>已製造量</td><td>'+manufQty+'</td></tr>';
    rows+='<tr><td>預計開始日</td><td>'+startDate+'</td></tr>';
    rows+='<tr><td>預計完成日</td><td>'+targetDate+'</td></tr>';
    if(isEdit) rows+='<tr><td>實際完成日</td><td>'+compDate+'</td></tr>';
    if(note) rows+='<tr><td>備註</td><td>'+note+'</td></tr>';

    var ov=document.createElement('div');
    ov.className='confirm-overlay';ov.id='prodConfirmOverlay';
    ov.innerHTML='<div class="confirm-card">'
        +'<h3>'+(isEdit?'確認修改工單':'確認開立工單')+'</h3>'
        +'<table>'+rows+'</table>'
        +'<div class="confirm-actions">'
        +'<button class="btn-confirm-cancel" onclick="document.getElementById(\'prodConfirmOverlay\').remove()">取消</button>'
        +'<button class="btn-confirm-ok" id="prodConfirmOkBtn">確認</button>'
        +'</div></div>';
    document.body.appendChild(ov);
    document.getElementById('prodConfirmOkBtn').onclick=function(){
        document.getElementById('prodConfirmOverlay').remove();
        doSubmitProdForm();
    };
}

function doSubmitProdForm(){
    var id=document.getElementById('prodId').value;
    var isEdit=id!='';
    var fd=new FormData();
    if(isEdit)fd.append('id',id);
    var orderIdVal = isEdit ? document.getElementById('prodOrderIdHidden').value : document.getElementById('prodOrderId').value;
    fd.append('orderId',orderIdVal);
    fd.append('productId',document.getElementById('prodProductId').value);
    fd.append('priceType',document.getElementById('prodPriceType').value);
    fd.append('unitPrice',document.getElementById('prodUnitPrice').value);
    fd.append('unitWeight',document.getElementById('prodUnitWeight').value);
    fd.append('quantity',document.getElementById('prodQuantity').value);
    fd.append('producedQty',document.getElementById('prodProducedQty').value);
    fd.append('manufacturedQty',isEdit?document.getElementById('prodManufacturedQty').value:'0');
    fd.append('status',document.getElementById('prodStatus').value);
    fd.append('startDate',document.getElementById('prodStartDate').value);
    fd.append('targetDate',document.getElementById('prodTargetDate').value);
    if(isEdit)fd.append('completedDate',document.getElementById('prodCompletedDate').value);
    fd.append('note',document.getElementById('prodNote').value);
    var btn=document.getElementById('prodSubmitBtn');btn.disabled=true;
    fetch(CTX+'/ProductionServlet',{method:'POST',headers:{'X-Requested-With':'XMLHttpRequest'},body:fd})
    .then(function(r){return r.json();})
    .then(function(d){
        if(d.success){
            showToast(isEdit?'工單已更新！':'工單已開立！','success');
            if(isEdit){
                setTimeout(function(){ window.location.href = 'production_list.jsp?submitted=1&prodId=' + encodeURIComponent(id) + (window.location.search.indexOf('orderId=') >= 0 ? '&' + window.location.search.replace(/^\?/, '') : ''); }, 1000);
            } else {
                setTimeout(function(){ location.reload(); }, 1000);
            }
        }
        else{var err=document.getElementById('prodFormError');err.textContent=d.error||'儲存失敗';err.style.display='block';btn.disabled=false;}
    })
    .catch(function(){var err=document.getElementById('prodFormError');err.textContent='系統錯誤';err.style.display='block';btn.disabled=false;});
}

function openEditRecvModal(prodId, orderId, currentQty, unit) {
    var ov = document.createElement('div');
    ov.id = 'editRecvOverlay';
    ov.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:10000;display:flex;align-items:center;justify-content:center;';
    ov.innerHTML = '<div class="dialog-box">'
        + '<h3 style="margin:0 0 20px;font-size:18px;color:#1a1a2e;border-bottom:2px solid #e9ecef;padding-bottom:12px;">修改入庫數量</h3>'
        + '<div style="margin-bottom:16px;font-size:14px;color:#6c757d;">目前淨入庫：<b style="color:#333;font-size:16px;">' + currentQty + ' ' + unit + '</b></div>'
        + '<div style="margin-bottom:16px;">'
        + '<label style="display:block;margin-bottom:6px;font-weight:600;">新入庫數量 (' + unit + ')</label>'
        + '<input type="number" id="editRecvQty" step="any" value="' + currentQty + '" min="0" style="width:100%;padding:8px 12px;border:1px solid #ddd;border-radius:6px;font-size:14px;">'
        + '<div style="margin-top:6px;font-size:12px;color:#6c757d;" id="editRecvHint"></div>'
        + '</div>'
        + '<div style="display:flex;justify-content:flex-end;gap:10px;margin-top:20px;">'
        + '<button onclick="document.getElementById(\'editRecvOverlay\').remove()" style="padding:8px 24px;border:1px solid #6c757d;background:#fff;border-radius:6px;cursor:pointer;font-size:14px;">取消</button>'
        + '<button onclick="submitEditRecv(' + prodId + ',' + orderId + ',\'' + unit + '\')" style="padding:8px 24px;border:none;background:#4361ee;color:#fff;border-radius:6px;cursor:pointer;font-size:14px;">確認修改</button>'
        + '</div>'
        + '</div>';
    document.body.appendChild(ov);
    ov.onclick = function(e) { if (e.target === ov) ov.remove(); };
    document.getElementById('editRecvQty').focus();
    document.getElementById('editRecvQty').select();
    document.getElementById('editRecvQty').addEventListener('input', function() {
        var newVal = parseFloat(this.value) || 0;
        var diff = newVal - currentQty;
        var hint = document.getElementById('editRecvHint');
        if (diff > 0) {
            hint.textContent = '將新增入庫 ' + diff + ' ' + unit;
            hint.style.color = '#28a745';
        } else if (diff < 0) {
            hint.textContent = '將沖正 ' + Math.abs(diff) + ' ' + unit;
            hint.style.color = '#dc3545';
        } else {
            hint.textContent = '';
        }
    });
}

function submitEditRecv(prodId, orderId, unit) {
    var newQty = parseFloat(document.getElementById('editRecvQty').value);
    if (isNaN(newQty) || newQty < 0) { alert('請輸入有效的數量'); return; }
    if (!confirm('確定將入庫數量改為 ' + newQty + ' ' + unit + '？')) return;
    var params = new URLSearchParams();
    params.append('action', 'adjust_receipt');
    params.append('productionId', prodId);
    params.append('orderId', orderId);
    params.append('quantity', newQty);
    fetch(CTX + '/ProductionReceiptServlet', { method: 'POST', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: params.toString() })
    .then(function(r) { return r.json(); })
    .then(function(d) {
        if (d.success) {
            document.getElementById('editRecvOverlay').remove();
            showToast('入庫數量已更新！', 'success');
            setTimeout(function() { location.reload(); }, 1000);
        } else {
            alert(d.error || '修改失敗');
        }
    })
    .catch(function() { alert('系統錯誤，請稍後再試'); });
}
</script>

<%@ include file="../include/footer.jsp" %>
