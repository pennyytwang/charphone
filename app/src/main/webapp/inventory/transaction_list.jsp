<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.InventoryTransactionDao, util.NumberUtil, model.InventoryTransaction, java.util.List" %>
<% request.setAttribute("pageTitle", "庫存異動記錄"); %>
<% request.setAttribute("pageIcon", "▣"); %>
<% request.setAttribute("pageSubtitle", "出入庫明細"); %>
<%@ include file="../include/header.jsp" %>
<%@ taglib prefix="my" tagdir="/WEB-INF/tags" %>

    <%
        String msg = request.getParameter("message");
        if ("success".equals(msg)) {
    %>
        <div class="alert alert-success">庫存異動已儲存！</div>
    <% } %>

    <div class="page-header">
        <a href="add_transaction.jsp" class="btn btn-success">+ 新增異動</a>
    </div>

    <%
        String dateFrom = request.getParameter("dateFrom");
        String dateTo = request.getParameter("dateTo");
        String keyword = request.getParameter("keyword");

        int pageNum = 1;
        int pageSize = 20;
        String pageParam = request.getParameter("page");
        if (pageParam != null) {
            try { pageNum = Integer.parseInt(pageParam); if (pageNum < 1) pageNum = 1; } catch (NumberFormatException e) {}
        }
        int startIdx = (pageNum - 1) * pageSize;
        int txTotalPages = 1;
        int txFilteredIdx = 0;
        int txDisplayed = 0;
    %>

    <form class="filter-bar" method="GET">
        <div class="field">
            <label>日期從</label>
            <input type="date" name="dateFrom" value="<%= dateFrom != null ? dateFrom : "" %>">
        </div>
        <div class="field">
            <label>日期到</label>
            <input type="date" name="dateTo" value="<%= dateTo != null ? dateTo : "" %>">
        </div>
        <div class="field">
            <label>關鍵字</label>
            <input type="text" name="keyword" value="<%= keyword != null ? keyword : "" %>" placeholder="單號/品項">
        </div>
        <button type="submit" class="btn-search">查詢</button>
        <a href="transaction_list.jsp" class="btn-clear">清除</a>
    </form>

    <%
        String txBaseUrl = "transaction_list.jsp?submitted=1"
            + (dateFrom != null && !dateFrom.isEmpty() ? "&dateFrom=" + dateFrom : "")
            + (dateTo != null && !dateTo.isEmpty() ? "&dateTo=" + dateTo : "")
            + (keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword.trim(), java.nio.charset.StandardCharsets.UTF_8) : "");
    %>
<div class="table-container" style="display:flex;flex-direction:column;padding:0;">
<table style="order:2;width:100%;">
        <thead>
            <tr>
                <th>序號</th>
                <th>單據編號</th>
                <th>日期</th>
                <th>倉庫</th>
                <th>品項</th>
                <th>類型</th>
                <th>數量</th>
                <th>異動前</th>
                <th>異動後</th>
                <th>對應訂單</th>
                <th>對應工單</th>
                <th>來源單據</th>
                <th>備註</th>
            </tr>
        </thead>
        <tbody>
            <%
                try {
                    InventoryTransactionDao dao = new InventoryTransactionDao();
                    List<InventoryTransaction> list = dao.getAllTransactions(dateFrom, dateTo, keyword);
                    txTotalPages = 1;
                    txFilteredIdx = 0;
                    txDisplayed = 0;
                    for (InventoryTransaction t : list) {
                            txFilteredIdx++;
                            if (txFilteredIdx <= startIdx) continue;
                            if (txDisplayed >= pageSize) continue;
                            txDisplayed++;
                        boolean isIn = t.getQuantity().compareTo(java.math.BigDecimal.ZERO) > 0;
            %>
                <tr>
                    <td><%= txFilteredIdx %></td>
                    <td><b><%= t.getTransactionNumber() %></b></td>
                    <td style="font-size:12px;"><%= t.getCreatedAt() != null ? t.getCreatedAt() : "-" %></td>
                    <td><%= t.getWarehouseName() %></td>
                    <td><%= t.getItemCode() %> - <%= t.getItemName() %></td>
                    <td>
                        <% if (t.getTransactionType() == 1) { %><span class='badge badge-green'>入庫</span>
                        <% } else if (t.getTransactionType() == 2) { %><span class='badge badge-red'>出庫</span>
                        <% } else if (t.getTransactionType() == 3) { %><span class='badge badge-blue'>調撥入</span>
                        <% } else if (t.getTransactionType() == 4) { %><span class='badge badge-orange'>調撥出</span>
                        <% } else if (t.getTransactionType() == 5) { %><span class='badge badge-green'>盤盈</span>
                        <% } else if (t.getTransactionType() == 6) { %><span class='badge badge-red'>盤虧</span><% } %>
                    </td>
                    <td class="<%= isIn ? "status-in" : "status-out" %>"><%= isIn ? "+" : "" %><%= NumberUtil.fmtQty(t.getQuantity().doubleValue()) %></td>
                    <td><%= NumberUtil.fmtQty(t.getBalanceBefore().doubleValue()) %></td>
                    <td><%= NumberUtil.fmtQty(t.getBalanceAfter().doubleValue()) %></td>
                    <td style="font-size:12px;color:#888;">
                        <% if (t.getOrderNumber() != null) { %>
                            <a href="../order/order_list.jsp" style="color:#4361ee;"><%= t.getOrderNumber() %></a>
                        <% } else { %>
                            -
                        <% } %>
                    </td>
                    <td style="font-size:12px;color:#888;">
                        <% if (t.getProductionNumber() != null) { %>
                            <a href="../production/production_list.jsp" style="color:#4361ee;"><%= t.getProductionNumber() %></a>
                        <% } else { %>
                            -
                        <% } %>
                    </td>
                    <td style="font-size:12px;color:#888;">
                        <% if (t.getRefType() != null && t.getRefId() != null) {
                            String link = "";
                            if ("delivery".equals(t.getRefType())) link = "../delivery/delivery_list.jsp";
                            else if ("production".equals(t.getRefType())) link = "../production/production_list.jsp";
                            else if ("order".equals(t.getRefType())) link = "../order/order_list.jsp";
                            if (!link.isEmpty()) { %>
                                <a href="<%= link %>" style="color:#4361ee;"><%= t.getRefType() %> #<%= t.getRefId() %></a>
                            <% } else { %>
                                <%= t.getRefType() %> #<%= t.getRefId() %>
                            <% }
                        } else { %>
                            -
                        <% } %>
                    </td>
                    <td style="font-size:12px;color:#888;"><%= t.getNote() != null ? t.getNote() : "" %></td>
                </tr>
            <%
                    }
                    if (list.isEmpty()) {
            %>
                    <tr><td colspan="13"><div class="empty-state"><p>尚無異動記錄</p></div></td></tr>
            <%
                    }
                    txTotalPages = txFilteredIdx > 0 ? (int) Math.ceil((double) txFilteredIdx / pageSize) : 1;
                    if (pageNum > txTotalPages) pageNum = txTotalPages;
                } catch (Exception e) {
                    out.println("<tr><td colspan='10' style='color: red;'>錯誤：" + e.getMessage() + "</td></tr>");
                    e.printStackTrace();
                }
            %>
        </tbody>
    </table>
<div style="order:1;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= txTotalPages %>" totalCount="<%= txFilteredIdx %>" baseUrl="<%= txBaseUrl %>" position="top"/></div>
<div style="order:3;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= txTotalPages %>" totalCount="<%= txFilteredIdx %>" baseUrl="<%= txBaseUrl %>"/></div>
</div>

<%@ include file="../include/footer.jsp" %>
