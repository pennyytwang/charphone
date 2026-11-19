<%@ tag description="Pagination control bar (top or bottom)" pageEncoding="UTF-8" %>
<%@ attribute name="pageNum" required="true" type="java.lang.Integer" %>
<%@ attribute name="totalPages" required="true" type="java.lang.Integer" %>
<%@ attribute name="totalCount" required="true" type="java.lang.Integer" %>
<%@ attribute name="baseUrl" required="true" type="java.lang.String" %>
<%@ attribute name="position" required="false" type="java.lang.String" %>
<%
    boolean isTop = "top".equals(position);
    String radius = isTop ? "border-radius:12px 12px 0 0;" : "border-radius:0 0 12px 12px;";
    String border = isTop ? "border-bottom:1px solid #e9ecef;" : "border-top:1px solid #e9ecef;";
    String margin = isTop ? "margin-top:8px;" : "";
    String base = baseUrl.contains("?") ? baseUrl + "&" : baseUrl + "?";
%>
<div style="display:flex;justify-content:space-between;align-items:center;padding:12px 20px;background:#fff;<%= border %><%= radius %><%= margin %>">
    <span style="font-size:13px;color:#6c757d;">共 <%= totalCount %> 筆，第 <%= pageNum %>/<%= totalPages %> 頁</span>
    <div style="display:flex;gap:6px;">
        <% if (pageNum > 1) { %>
            <a href="<%= base %>page=1" class="btn btn-outline btn-sm">第一頁</a>
            <a href="<%= base %>page=<%= pageNum - 1 %>" class="btn btn-outline btn-sm">上一頁</a>
        <% } %>
        <% if (pageNum < totalPages) { %>
            <a href="<%= base %>page=<%= pageNum + 1 %>" class="btn btn-outline btn-sm">下一頁</a>
            <a href="<%= base %>page=<%= totalPages %>" class="btn btn-outline btn-sm">最後頁</a>
        <% } %>
    </div>
</div>
