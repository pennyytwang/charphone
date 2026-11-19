<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.UserDao, dao.AccessTokenDao, model.User, model.AccessToken, java.util.List, java.text.SimpleDateFormat" %>
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
<% request.setAttribute("pageTitle", "Token 管理"); %>
<% request.setAttribute("pageIcon", "☏"); %>
<% request.setAttribute("pageSubtitle", "管理存取碼與 Magic Link"); %>
<%@ include file="../include/header.jsp" %>
<%
    String userIdParam = request.getParameter("userId");
    User target = null;
    List<AccessToken> tokens = java.util.Collections.emptyList();
    try {
        int userId = Integer.parseInt(userIdParam);
        target = new UserDao().getUserById(userId);
        if (target != null) {
            tokens = new AccessTokenDao().listByUser(userId);
        }
    } catch (Exception e) {
        target = null;
    }
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");
    long now = System.currentTimeMillis();
%>

<%
    String msg = request.getParameter("message");
    String error = request.getParameter("error");
    if ("revoked".equals(msg)) {
%>
    <div class="alert alert-success">Token 已撤銷。</div>
<% } else if (error != null) { %>
    <div class="alert alert-danger">
        <%
            if ("expiry_required".equals(error)) out.print("請填寫到期時間。");
            else if ("expiry_past".equals(error)) out.print("到期時間必須晚於現在。");
            else if ("expiry_exceeds_user".equals(error)) out.print("Token 到期時間不可晚於帳號到期時間。");
            else if ("label_required".equals(error)) out.print("請填寫 Token 名稱。");
            else if ("label_too_long".equals(error)) out.print("Token 名稱不可超過 100 字。");
            else if ("max_uses_invalid".equals(error)) out.print("使用次數必須大於 0。");
            else if ("user_inactive".equals(error)) out.print("此帳號已停用，無法建立 Token。");
            else if ("user_not_found".equals(error)) out.print("找不到該帳號。");
            else if ("revoke_failed".equals(error)) out.print("撤銷失敗，請稍後再試。");
            else if ("token_failed".equals(error)) out.print("Token 建立失敗，請稍後再試。");
            else out.print("操作失敗，請稍後再試。");
        %>
    </div>
<% } %>

<% if (target == null) { %>
    <div class="alert alert-danger">找不到該帳號。</div>
    <a href="user_list.jsp" class="back-link">返回帳號清單</a>
<% } else { %>
<div class="form-container" style="margin-bottom:24px;">
    <h2>建立新 Token</h2>
    <p style="color:#6c757d;font-size:13px;margin-top:-6px;margin-bottom:18px;">
        帳號：<b><%= esc(target.getUsername()) %></b>
        <%= target.isTemporary() ? "（暫時帳號，唯讀）" : "" %>
        ｜到期：<%= target.getExpiresAt() != null ? sdf.format(target.getExpiresAt()) : "無" %>
    </p>
    <form action="../TokenAdminServlet" method="POST">
        <input type="hidden" name="action" value="create">
        <input type="hidden" name="userId" value="<%= target.getId() %>">
        <div class="form-group">
            <label>Token 名稱（用途）</label>
            <input type="text" name="label" required maxlength="100" placeholder="例如：104 面試官-王先生">
        </div>
        <div class="form-group">
            <label>到期時間</label>
            <input type="datetime-local" name="expiresAt" required>
        </div>
        <div class="form-group">
            <label>使用次數上限（留空 = 不限）</label>
            <input type="number" name="maxUses" min="1" step="1" placeholder="例如：1">
        </div>
        <button type="submit" class="btn-submit">產生 Token</button>
        <a href="user_list.jsp" class="back-link">返回帳號清單</a>
    </form>
</div>

<div class="table-container">
<table>
    <thead>
        <tr>
            <th>Token</th>
            <th>名稱</th>
            <th>到期時間</th>
            <th>使用次數</th>
            <th>最後使用</th>
            <th>狀態</th>
            <th>操作</th>
        </tr>
    </thead>
    <tbody>
    <% for (AccessToken t : tokens) {
        boolean revoked = t.isRevoked();
        boolean expired = t.isExpired(now);
        boolean exhausted = t.isExhausted();
        String statusText;
        String statusClass;
        if (revoked) { statusText = "已撤銷"; statusClass = "badge-gray"; }
        else if (expired) { statusText = "已過期"; statusClass = "badge-gray"; }
        else if (exhausted) { statusText = "已用完"; statusClass = "badge-gray"; }
        else { statusText = "有效"; statusClass = "badge-green"; }
    %>
        <tr>
            <td><code><%= esc(t.getTokenHint()) %></code></td>
            <td><%= esc(t.getLabel()) %></td>
            <td><%= t.getExpiresAt() != null ? sdf.format(t.getExpiresAt()) : "" %></td>
            <td><%= t.getUsedCount() %> / <%= t.getMaxUses() != null ? t.getMaxUses() : "不限" %></td>
            <td><%= t.getLastUsedAt() != null ? sdf.format(t.getLastUsedAt()) : "—" %></td>
            <td><span class="badge <%= statusClass %>"><%= statusText %></span></td>
            <td>
                <div class="actions">
                    <% if (!revoked) { %>
                    <form action="../TokenAdminServlet" method="POST" style="display:inline;" onsubmit="return confirm('確定撤銷此 Token？')">
                        <input type="hidden" name="action" value="revoke">
                        <input type="hidden" name="tokenId" value="<%= t.getId() %>">
                        <button type="submit" class="btn btn-danger" style="padding:4px 12px;font-size:12px;">撤銷</button>
                    </form>
                    <details style="display:inline-block;">
                        <summary style="cursor:pointer;color:#4361ee;font-size:12px;display:inline;">重新產生</summary>
                        <form action="../TokenAdminServlet" method="POST" style="margin-top:8px;display:flex;gap:6px;flex-wrap:wrap;align-items:center;">
                            <input type="hidden" name="action" value="regenerate">
                            <input type="hidden" name="tokenId" value="<%= t.getId() %>">
                            <input type="text" name="label" value="<%= esc(t.getLabel()) %>" maxlength="100" style="width:180px;padding:5px 8px;border:1px solid #ddd;border-radius:6px;">
                            <input type="datetime-local" name="expiresAt" required style="padding:5px 8px;border:1px solid #ddd;border-radius:6px;">
                            <input type="number" name="maxUses" min="1" step="1" placeholder="次數" value="<%= t.getMaxUses() != null ? t.getMaxUses() : "" %>" style="width:80px;padding:5px 8px;border:1px solid #ddd;border-radius:6px;">
                            <button type="submit" class="btn btn-primary" style="padding:5px 12px;font-size:12px;">產生</button>
                        </form>
                    </details>
                    <% } %>
                </div>
            </td>
        </tr>
    <% } %>
    <% if (tokens.isEmpty()) { %>
        <tr><td colspan="7" style="text-align:center;color:#6c757d;">尚無 Token</td></tr>
    <% } %>
    </tbody>
</table>
</div>
<% } %>
<%@ include file="../include/footer.jsp" %>
