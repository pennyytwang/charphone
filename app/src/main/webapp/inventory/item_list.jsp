<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.InventoryItemDao, model.InventoryItem, java.util.List" %>
<% request.setAttribute("pageTitle", "庫存品項管理"); %>
<% request.setAttribute("pageIcon", "▣"); %>
<% request.setAttribute("pageSubtitle", "庫存品項與數量"); %>
<%@ include file="../include/header.jsp" %>
<%@ taglib prefix="my" tagdir="/WEB-INF/tags" %>

    <%
        String msg = request.getParameter("message");
        if ("success".equals(msg)) {
    %>
        <div class="alert alert-success">庫存品項已儲存！</div>
    <% } %>

    <div class="page-header">
        <a href="add_item.jsp" class="btn btn-primary">+ 新增庫存品項</a>
    </div>

    <%
        String keyword = request.getParameter("keyword");

        int pageNum = 1;
        int pageSize = 20;
        String pageParam = request.getParameter("page");
        if (pageParam != null) {
            try { pageNum = Integer.parseInt(pageParam); if (pageNum < 1) pageNum = 1; } catch (NumberFormatException e) {}
        }
        int startIdx = (pageNum - 1) * pageSize;
        int itemTotalPages = 1;
        int itemFilteredIdx = 0;
        int itemDisplayed = 0;
    %>

    <form class="filter-bar" method="GET">
        <div class="field">
            <label>關鍵字</label>
            <input type="text" name="keyword" value="<%= keyword != null ? keyword : "" %>" placeholder="品項名稱/編號">
        </div>
        <button type="submit" class="btn-search">查詢</button>
        <a href="item_list.jsp" class="btn-clear">清除</a>
    </form>

    <%
        String itemBaseUrl = "item_list.jsp?submitted=1"
            + (keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword.trim(), java.nio.charset.StandardCharsets.UTF_8) : "");
    %>
<div class="table-container" style="display:flex;flex-direction:column;padding:0;">
<table style="order:2;width:100%;">
        <thead>
            <tr>
                <th>序號</th>
                <th>品項編號</th>
                <th>品項名稱</th>
                <th>類型</th>
                <th>關聯產品</th>
                <th>單位</th>
                <th>單位成本</th>
                <th>安全庫存</th>
                <th>狀態</th>
                <th>備註</th>
                <th>操作</th>
            </tr>
        </thead>
        <tbody>
            <%
                try {
                    InventoryItemDao dao = new InventoryItemDao();
                    List<InventoryItem> list = dao.getAllItems(keyword);
                    itemTotalPages = 1;
                    itemFilteredIdx = 0;
                    itemDisplayed = 0;
                    for (InventoryItem item : list) {
                            itemFilteredIdx++;
                            if (itemFilteredIdx <= startIdx) continue;
                            if (itemDisplayed >= pageSize) continue;
                            itemDisplayed++;
            %>
                <tr>
                    <td><%= itemFilteredIdx %></td>
                    <td><b><%= item.getItemCode() %></b></td>
                    <td><%= item.getItemName() %></td>
                    <td>
                        <% if (item.getItemType() == 1) { %><span class='badge badge-blue'>原料</span>
                        <% } else if (item.getItemType() == 2) { %><span class='badge badge-orange'>半成品</span>
                        <% } else { %><span class='badge badge-green'>成品</span><% } %>
                    </td>
                    <td><%= item.getProductName() != null ? item.getProductName() : "-" %></td>
                    <td><%= item.getUnit() %></td>
                    <td><%= item.getUnitCost() != null && item.getUnitCost().compareTo(java.math.BigDecimal.ZERO) > 0 ? item.getUnitCost() : "-" %></td>
                    <td><%= item.getSafetyStock() != null && item.getSafetyStock().compareTo(java.math.BigDecimal.ZERO) > 0 ? item.getSafetyStock() : "-" %></td>
                    <td><%= item.getStatus() == 1 ? "<span class='badge badge-green'>啟用</span>" : "<span class='badge badge-gray'>停用</span>" %></td>
                    <td style="color:#888;font-size:12px;"><%= item.getNote() != null ? item.getNote() : "" %></td>
                    <td><a href="edit_item.jsp?id=<%= item.getId() %>" class="btn btn-primary btn-sm">編輯</a></td>
                </tr>
            <%
                    }
                    if (list.isEmpty()) {
            %>
                    <tr><td colspan="11"><div class="empty-state"><p>尚無庫存品項資料</p></div></td></tr>
            <%
                    }
                    itemTotalPages = itemFilteredIdx > 0 ? (int) Math.ceil((double) itemFilteredIdx / pageSize) : 1;
                    if (pageNum > itemTotalPages) pageNum = itemTotalPages;
                } catch (Exception e) {
                    out.println("<tr><td colspan='11' style='color: red;'>錯誤：" + e.getMessage() + "</td></tr>");
                    e.printStackTrace();
                }
            %>
        </tbody>
    </table>
<div style="order:1;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= itemTotalPages %>" totalCount="<%= itemFilteredIdx %>" baseUrl="<%= itemBaseUrl %>" position="top"/></div>
<div style="order:3;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= itemTotalPages %>" totalCount="<%= itemFilteredIdx %>" baseUrl="<%= itemBaseUrl %>"/></div>
</div>

<%@ include file="../include/footer.jsp" %>
