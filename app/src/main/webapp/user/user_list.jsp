<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.UserDao, model.User, java.util.List, java.text.SimpleDateFormat" %>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"admin".equals(currentUser.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<% request.setAttribute("pageTitle", "帳號管理"); %>
<% request.setAttribute("pageIcon", "☏"); %>
<% request.setAttribute("pageSubtitle", "使用者帳號與存取權限"); %>
<%@ include file="../include/header.jsp" %>
<%@ taglib prefix="my" tagdir="/WEB-INF/tags" %>
<%
    String msg = request.getParameter("message");
    String error = request.getParameter("error");
    if ("success".equals(msg)) {
%>
    <div class="alert alert-success">操作成功！</div>
<% } else if (error != null) { %>
    <div class="alert alert-danger">
        <%
            if ("self_delete".equals(error)) out.print("不可刪除目前登入的帳號。");
            else if ("token_not_found".equals(error)) out.print("找不到該 Token。");
            else out.print("操作失敗，請稍後再試。");
        %>
    </div>
<% } %>

<%
    int pageNum = 1;
    int pageSize = 20;
    String pageParam = request.getParameter("page");
    if (pageParam != null) {
        try { pageNum = Integer.parseInt(pageParam); if (pageNum < 1) pageNum = 1; } catch (NumberFormatException e) {}
    }
    int startIdx = (pageNum - 1) * pageSize;
    int userTotalPages = 1;
    int userFilteredIdx = 0;
    int userDisplayed = 0;
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");
%>

<div style="display:flex;justify-content:flex-end;margin-bottom:16px;">
    <a href="add_user.jsp" class="btn btn-primary">+ 新增帳號</a>
</div>

<%
    String userBaseUrl = "user_list.jsp?submitted=1";
%>
<div class="table-container" style="display:flex;flex-direction:column;padding:0;">
<table style="order:2;width:100%;">
    <thead>
        <tr>
            <th>序號</th>
            <th>帳號</th>
            <th>顯示名稱</th>
            <th>角色</th>
            <th>類型</th>
            <th>到期時間</th>
            <th>狀態</th>
            <th>操作</th>
        </tr>
    </thead>
    <tbody>
        <%
            try {
                UserDao dao = new UserDao();
                List<User> users = dao.getAllUsers();
                userTotalPages = 1;
                userFilteredIdx = 0;
                userDisplayed = 0;
                for (User u : users) {
                        userFilteredIdx++;
                        if (userFilteredIdx <= startIdx) continue;
                        if (userDisplayed >= pageSize) continue;
                        userDisplayed++;
                        boolean temporary = u.isTemporary();
        %>
        <tr>
            <td><%= userFilteredIdx %></td>
            <td><b><%= esc(u.getUsername()) %></b></td>
            <td><%= esc(u.getDisplayName()) %></td>
            <td><span class="badge <%= "admin".equals(u.getRole()) ? "badge-blue" : "badge-gray" %>"><%= "admin".equals(u.getRole()) ? "管理員" : "使用者" %></span></td>
            <td><span class="badge <%= temporary ? "badge-orange" : "badge-blue" %>"><%= temporary ? "暫時" : "一般" %></span></td>
            <td><%= u.getExpiresAt() != null ? sdf.format(u.getExpiresAt()) : "—" %></td>
            <td>
                <% if (!u.isActive()) { %>
                    <span class="badge badge-gray">停用</span>
                <% } else if (u.isReadOnly() || temporary) { %>
                    <span class="badge badge-blue">唯讀</span>
                <% } else { %>
                    <span class="badge badge-green">啟用</span>
                <% } %>
            </td>
            <td>
                <div class="actions">
                    <a href="edit_user.jsp?id=<%= u.getId() %>" class="btn btn-warning" style="padding:4px 12px;font-size:12px;">編輯</a>
                    <a href="token_list.jsp?userId=<%= u.getId() %>" class="btn btn-primary" style="padding:4px 12px;font-size:12px;">Token</a>
                    <% if (!u.getUsername().equals(currentUser.getUsername())) { %>
                        <form action="../UserServlet" method="POST" style="display:inline;" onsubmit="return confirm('確定刪除此帳號？相關 Token 也會一併失效。')">
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<%= u.getId() %>">
                            <button type="submit" class="btn btn-danger" style="padding:4px 12px;font-size:12px;">刪除</button>
                        </form>
                    <% } %>
                </div>
            </td>
        </tr>
        <%
                }
                userTotalPages = userFilteredIdx > 0 ? (int) Math.ceil((double) userFilteredIdx / pageSize) : 1;
                if (pageNum > userTotalPages) pageNum = userTotalPages;
            } catch (Exception e) {
                out.println("<tr><td colspan='8' style='color:#dc3545;'>錯誤：" + e.getMessage() + "</td></tr>");
            }
        %>
    </tbody>
</table>
<div style="order:1;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= userTotalPages %>" totalCount="<%= userFilteredIdx %>" baseUrl="<%= userBaseUrl %>" position="top"/></div>
<div style="order:3;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= userTotalPages %>" totalCount="<%= userFilteredIdx %>" baseUrl="<%= userBaseUrl %>"/></div>
</div>
<%@ include file="../include/footer.jsp" %>
