<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.WarehouseDao, model.Warehouse, java.util.List" %>
<% request.setAttribute("pageTitle", "倉庫管理"); %>
<% request.setAttribute("pageIcon", "▣"); %>
<% request.setAttribute("pageSubtitle", "倉庫基本資料"); %>
<%@ include file="../include/header.jsp" %>
<%@ taglib prefix="my" tagdir="/WEB-INF/tags" %>

    <%
        String msg = request.getParameter("message");
        if ("success".equals(msg)) {
    %>
        <div class="alert alert-success">倉庫資料已儲存！</div>
    <% } %>

    <div class="page-header">
        <a href="add_warehouse.jsp" class="btn btn-primary">+ 新增倉庫</a>
    </div>

    <%
        int pageNum = 1;
        int pageSize = 20;
        String pageParam = request.getParameter("page");
        if (pageParam != null) {
            try { pageNum = Integer.parseInt(pageParam); if (pageNum < 1) pageNum = 1; } catch (NumberFormatException e) {}
        }
        int startIdx = (pageNum - 1) * pageSize;
        int whTotalPages = 1;
        int whFilteredIdx = 0;
        int whDisplayed = 0;
    %>

    <%
        String whBaseUrl = "warehouse_list.jsp?submitted=1";
    %>
<div class="table-container" style="display:flex;flex-direction:column;padding:0;">
<table style="order:2;width:100%;">
        <thead>
            <tr>
                <th>序號</th>
                <th>倉庫代碼</th>
                <th>倉庫名稱</th>
                <th>聯絡人</th>
                <th>電話</th>
                <th>地址</th>
                <th>狀態</th>
                <th>備註</th>
                <th>操作</th>
            </tr>
        </thead>
        <tbody>
            <%
                try {
                    WarehouseDao dao = new WarehouseDao();
                    List<Warehouse> list = dao.getAllWarehouses();
                    whTotalPages = 1;
                    whFilteredIdx = 0;
                    whDisplayed = 0;
                    for (Warehouse w : list) {
                            whFilteredIdx++;
                            if (whFilteredIdx <= startIdx) continue;
                            if (whDisplayed >= pageSize) continue;
                            whDisplayed++;
            %>
                <tr>
                    <td><%= whFilteredIdx %></td>
                    <td><b><%= w.getWarehouseCode() %></b></td>
                    <td><%= w.getWarehouseName() %></td>
                    <td><%= w.getContactPerson() != null ? w.getContactPerson() : "-" %></td>
                    <td><%= w.getPhone() != null ? w.getPhone() : "-" %></td>
                    <td><%= w.getAddress() != null ? w.getAddress() : "-" %></td>
                    <td><%= w.getStatus() == 1 ? "<span class='badge badge-green'>啟用</span>" : "<span class='badge badge-gray'>停用</span>" %></td>
                    <td style="color:#888;font-size:12px;"><%= w.getNote() != null ? w.getNote() : "" %></td>
                    <td><a href="edit_warehouse.jsp?id=<%= w.getId() %>" class="btn btn-primary btn-sm">編輯</a></td>
                </tr>
            <%
                    }
                    if (list.isEmpty()) {
            %>
                    <tr><td colspan="9"><div class="empty-state"><p>尚無倉庫資料</p></div></td></tr>
            <%
                    }
                    whTotalPages = whFilteredIdx > 0 ? (int) Math.ceil((double) whFilteredIdx / pageSize) : 1;
                    if (pageNum > whTotalPages) pageNum = whTotalPages;
                } catch (Exception e) {
                    out.println("<tr><td colspan='9' style='color: red;'>錯誤：" + e.getMessage() + "</td></tr>");
                    e.printStackTrace();
                }
            %>
        </tbody>
    </table>
<div style="order:1;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= whTotalPages %>" totalCount="<%= whFilteredIdx %>" baseUrl="<%= whBaseUrl %>" position="top"/></div>
<div style="order:3;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= whTotalPages %>" totalCount="<%= whFilteredIdx %>" baseUrl="<%= whBaseUrl %>"/></div>
</div>

<%@ include file="../include/footer.jsp" %>
