<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.InventoryStockDao, dao.WarehouseDao, util.NumberUtil, model.InventoryStock, model.Warehouse, java.util.List" %>
<% request.setAttribute("pageTitle", "庫存總覽"); %>
<% request.setAttribute("pageIcon", "▣"); %>
<% request.setAttribute("pageSubtitle", "庫存總覽與異動管理"); %>
<%@ include file="../include/header.jsp" %>
<%@ taglib prefix="my" tagdir="/WEB-INF/tags" %>

    <div class="page-header">
        <div>
            <a href="add_transaction.jsp" class="btn btn-success">+ 入庫/出庫</a>
            <a href="item_list.jsp" class="btn btn-primary">庫存品項管理</a>
        </div>
    </div>

    <%
        String warehouseId = request.getParameter("warehouseId");
        String keyword = request.getParameter("keyword");

        int pageNum = 1;
        int pageSize = 20;
        String pageParam = request.getParameter("page");
        if (pageParam != null) {
            try { pageNum = Integer.parseInt(pageParam); if (pageNum < 1) pageNum = 1; } catch (NumberFormatException e) {}
        }
        int startIdx = (pageNum - 1) * pageSize;
        int stockTotalPages = 1;
        int stockFilteredIdx = 0;
        int stockDisplayed = 0;
        String stockBaseUrl = "inventory_list.jsp?submitted=1"
            + (warehouseId != null && !warehouseId.isEmpty() ? "&warehouseId=" + warehouseId : "")
            + (keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword.trim(), java.nio.charset.StandardCharsets.UTF_8) : "");
    %>

    <form class="filter-bar" method="GET">
        <div class="field">
            <label>倉庫</label>
            <select name="warehouseId">
                <option value="">全部倉庫</option>
                <%
                    try {
                        WarehouseDao wdao = new WarehouseDao();
                        List<Warehouse> whList = wdao.getAllWarehouses();
                        for (Warehouse wh : whList) {
                            if (wh.getStatus() == 1) {
                                String sel = warehouseId != null && warehouseId.equals(String.valueOf(wh.getId())) ? "selected" : "";
                %>
                    <option value="<%= wh.getId() %>" <%= sel %>><%= wh.getWarehouseName() %></option>
                <%
                            }
                        }
                    } catch (Exception e) {}
                %>
            </select>
        </div>
        <div class="field">
            <label>關鍵字</label>
            <input type="text" name="keyword" value="<%= keyword != null ? keyword : "" %>" placeholder="品項名稱/編號">
        </div>
        <button type="submit" class="btn-search">查詢</button>
        <a href="inventory_list.jsp" class="btn-clear">清除</a>
    </form>

    <%
        try {
            InventoryStockDao dao = new InventoryStockDao();
            List<InventoryStock> list = dao.getAllStock(warehouseId, keyword);
            int lowCount = 0;
            for (InventoryStock s : list) {
                if (s.getSafetyStock() != null && s.getSafetyStock().compareTo(java.math.BigDecimal.ZERO) > 0 && s.getQuantity().compareTo(s.getSafetyStock()) < 0) lowCount++;
            }
    %>

    <div class="summary-cards">
        <div class="summary-card">
            <div class="num"><%= list.size() %></div>
            <div class="lbl">庫存品項數</div>
        </div>
        <div class="summary-card" style="<%= lowCount > 0 ? "background:#fff5f5;" : "" %>">
            <div class="num" style="<%= lowCount > 0 ? "color:#d32f2f;" : "" %>"><%= lowCount %></div>
            <div class="lbl">低於安全庫存</div>
        </div>
    </div>

    <div class="table-container" style="display:flex;flex-direction:column;padding:0;">
    <table style="order:2;width:100%;">
        <thead>
            <tr>
                <th>序號</th>
                <th>倉庫</th>
                <th>品項編號</th>
                <th>品項名稱</th>
                <th>單位</th>
                <th>目前庫存</th>
                <th>安全庫存</th>
                <th>狀態</th>
                <th>最後更新</th>
                <th>操作</th>
            </tr>
        </thead>
        <tbody>
            <%
                stockTotalPages = 1;
                stockFilteredIdx = 0;
                stockDisplayed = 0;
                for (InventoryStock s : list) {
                    stockFilteredIdx++;
                    if (stockFilteredIdx <= startIdx) continue;
                    if (stockDisplayed >= pageSize) continue;
                    stockDisplayed++;
                    boolean isLow = s.getSafetyStock() != null && s.getSafetyStock().compareTo(java.math.BigDecimal.ZERO) > 0 && s.getQuantity().compareTo(s.getSafetyStock()) < 0;
            %>
                <tr class="<%= isLow ? "low-stock" : "" %>">
                    <td><%= stockFilteredIdx %></td>
                    <td><b><%= s.getWarehouseName() %></b></td>
                    <td><%= s.getItemCode() %></td>
                    <td><%= s.getItemName() %></td>
                    <td><%= s.getUnit() %></td>
                    <td style="font-weight:700;font-size:15px;"><%= NumberUtil.fmtQty(s.getQuantity().doubleValue()) %></td>
                    <td><%= s.getSafetyStock() != null && s.getSafetyStock().compareTo(java.math.BigDecimal.ZERO) > 0 ? NumberUtil.fmtQty(s.getSafetyStock().doubleValue()) : "-" %></td>
                    <td>
                        <% if (isLow) { %><span class='badge badge-red'>庫存不足</span>
                        <% } else if (s.getQuantity().compareTo(java.math.BigDecimal.ZERO) == 0) { %><span class='badge badge-yellow'>無庫存</span>
                        <% } else { %><span class='badge badge-green'>正常</span><% } %>
                    </td>
                    <td style="font-size:12px;color:#888;"><%= s.getUpdatedAt() != null ? s.getUpdatedAt() : "-" %></td>
                    <td>
                        <a href="transaction_list.jsp?keyword=<%= s.getItemCode() %>" class="btn btn-info btn-sm">異動記錄</a>
                        <% if (s.getProductId() != null) { %>
                            <a href="javascript:void(0)" class="btn btn-warning btn-sm" onclick="showInvCheckModal('<%= s.getItemName() %>', '<%= s.getProductId() %>', '<%= NumberUtil.fmtQty(s.getQuantity().doubleValue()) %>')">出貨試算</a>
                        <% } %>
                    </td>
                </tr>
            <%
                }
                if (list.isEmpty()) {
            %>
                    <tr><td colspan="10"><div class="empty-state"><p>尚無庫存資料</p></div></td></tr>
            <%
                }
                stockTotalPages = stockFilteredIdx > 0 ? (int) Math.ceil((double) stockFilteredIdx / pageSize) : 1;
                if (pageNum > stockTotalPages) pageNum = stockTotalPages;
            } catch (Exception e) {
                    out.println("<tr><td colspan='10' style='color: red;'>錯誤：" + e.getMessage() + "</td></tr>");
                e.printStackTrace();
            }
            %>
        </tbody>
    </table>
    <div style="order:1;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= stockTotalPages %>" totalCount="<%= stockFilteredIdx %>" baseUrl="<%= stockBaseUrl %>" position="top"/></div>
    <div style="order:3;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= stockTotalPages %>" totalCount="<%= stockFilteredIdx %>" baseUrl="<%= stockBaseUrl %>"/></div>
    </div>

<div id="invCheckModal" class="modal" style="display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.4);z-index:9999;justify-content:center;align-items:center;">
    <div style="background:#fff;border-radius:12px;width:500px;max-width:90vw;padding:28px;box-shadow:0 8px 32px rgba(0,0,0,0.18);">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;">
            <h3 style="margin:0;">出貨試算</h3>
            <a href="javascript:void(0)" onclick="closeInvCheck()" style="font-size:22px;color:#999;text-decoration:none;">&times;</a>
        </div>
        <form style="margin-bottom:16px;display:flex;gap:8px;align-items:flex-end;">
            <div>
                <label style="display:block;font-size:12px;margin-bottom:4px;">出貨日期</label>
                <input type="date" id="invCheckDate" style="padding:6px;border:1px solid #ccc;border-radius:4px;">
            </div>
            <div>
                <label style="display:block;font-size:12px;margin-bottom:4px;">出貨量</label>
                <input type="number" id="invCheckQty" step="any" style="padding:6px;border:1px solid #ccc;border-radius:4px;width:100px;">
            </div>
            <button type="button" class="btn btn-primary btn-sm" onclick="runInvCheck()">試算</button>
        </form>
        <div id="invCheckResult" style="min-height:80px;text-align:center;color:#888;padding:20px 0;">請選擇日期與數量後按試算</div>
    </div>
</div>
<style>
.btn-sm { font-size:12px; padding:4px 10px; border-radius:4px; border:none; cursor:pointer; text-decoration:none; display:inline-block; }
.btn-info { background:#17a2b8; color:#fff; }
.btn-warning { background:#ff9800; color:#fff; }
</style>
<script>
var invProductId = null, invItemName = '', invStock = 0;
function showInvCheckModal(itemName, productId, stock) {
    invProductId = productId;
    invItemName = itemName;
    invStock = stock;
    document.getElementById('invCheckDate').value = new Date().toISOString().split('T')[0];
    document.getElementById('invCheckQty').value = '';
    document.getElementById('invCheckResult').innerHTML = '請選擇日期與數量後按試算';
    document.getElementById('invCheckModal').style.display = 'flex';
}
function runInvCheck() {
    var date = document.getElementById('invCheckDate').value;
    var qty = document.getElementById('invCheckQty').value;
    if (!date || !qty) { alert('請選擇日期與數量'); return; }
    var url = '../ShippingCheckServlet?productId=' + invProductId + '&date=' + date + '&qty=' + qty;
    document.getElementById('invCheckResult').innerHTML = '載入中...';
    fetch(url)
        .then(function(r) { return r.json(); })
        .then(function(d) {
            var html = '<table style="width:100%;border-collapse:collapse;font-size:14px;">'
                + '<tr><td style="padding:8px;border-bottom:1px solid #eee;font-weight:bold;">產品</td><td style="padding:8px;border-bottom:1px solid #eee;text-align:right;">' + d.productName + '</td></tr>'
                + '<tr><td style="padding:8px;border-bottom:1px solid #eee;font-weight:bold;">WH-FG 庫存</td><td style="padding:8px;border-bottom:1px solid #eee;text-align:right;">' + d.currentStock + '</td></tr>'
                + '<tr><td style="padding:8px;border-bottom:1px solid #eee;font-weight:bold;">' + date + ' 前未入庫</td><td style="padding:8px;border-bottom:1px solid #eee;text-align:right;color:#1976d2;">+ ' + d.potentialSupply + '</td></tr>'
                + '<tr style="font-size:16px;"><td style="padding:8px;border-bottom:2px solid #333;font-weight:bold;">可供量</td><td style="padding:8px;border-bottom:2px solid #333;text-align:right;font-weight:bold;">' + d.totalAvailable + '</td></tr>'
                + '<tr><td style="padding:8px;font-weight:bold;">需求</td><td style="padding:8px;text-align:right;">' + qty + '</td></tr>'
                + '</table>'
                + '<div style="text-align:center;padding:16px;border-radius:8px;font-size:16px;font-weight:bold;margin-top:16px;background:' + (d.canDeliver ? '#e8f5e9' : '#ffebee') + ';color:' + (d.canDeliver ? '#2e7d32' : '#c62828') + ';">'
                + (d.canDeliver ? '可如期出貨' : '可能短缺 ' + d.shortage + ' 單位')
                + '</div>';
            document.getElementById('invCheckResult').innerHTML = html;
        })
        .catch(function(e) {
            document.getElementById('invCheckResult').innerHTML = '<div style="color:red;">查詢失敗：' + e.message + '</div>';
        });
}
function closeInvCheck() {
    document.getElementById('invCheckModal').style.display = 'none';
}
document.addEventListener('click', function(e) {
    if (e.target.id === 'invCheckModal') closeInvCheck();
});
</script>
<%@ include file="../include/footer.jsp" %>
