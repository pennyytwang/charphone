<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.UserDao, model.User, java.text.SimpleDateFormat" %>
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
<% request.setAttribute("pageTitle", "編輯帳號"); %>
<% request.setAttribute("pageIcon", "☏"); %>
<% request.setAttribute("pageSubtitle", "修改帳號資料"); %>
<%@ include file="../include/header.jsp" %>
<%
    String idStr = request.getParameter("id");
    User u = null;
    if (idStr != null && !idStr.isEmpty()) {
        try {
            UserDao dao = new UserDao();
            u = dao.getUserById(Integer.parseInt(idStr));
        } catch (Exception e) {
            out.println("<div class='error-msg'>找不到該帳號。</div>");
        }
    }
    if (u == null) {
        out.println("<div class='error-msg'>無效的帳號編號。</div>");
    } else {
        String expiresValue = "";
        if (u.getExpiresAt() != null) {
            expiresValue = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm").format(u.getExpiresAt());
        }
%>
<div class="form-container">
    <h2>編輯帳號</h2>
    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">更新失敗，請稍後再試。</div>
    <% } else if ("duplicate".equals(error)) { %>
        <div class="error-msg">此帳號名稱已被使用。</div>
    <% } else if ("expiry_required".equals(error)) { %>
        <div class="error-msg">暫時帳號必須填寫到期時間。</div>
    <% } else if ("expiry_past".equals(error)) { %>
        <div class="error-msg">到期時間必須晚於現在。</div>
    <% } else if ("username_required".equals(error)) { %>
        <div class="error-msg">請輸入帳號名稱。</div>
    <% } else if ("username_too_long".equals(error)) { %>
        <div class="error-msg">帳號名稱不可超過 50 字。</div>
    <% } else if ("display_too_long".equals(error)) { %>
        <div class="error-msg">顯示名稱不可超過 100 字。</div>
    <% } else if ("self_deactivate".equals(error)) { %>
        <div class="error-msg">不可停用目前登入的帳號。</div>
    <% } else if ("self_demote".equals(error)) { %>
        <div class="error-msg">不可將目前登入的帳號降為一般使用者。</div>
    <% } %>
    <form action="../UserServlet" method="POST">
        <input type="hidden" name="id" value="<%= u.getId() %>">
        <div class="form-group">
            <label>帳號</label>
            <input type="text" name="username" value="<%= esc(u.getUsername()) %>" required maxlength="50">
        </div>
        <div class="form-group">
            <label>新密碼 <span id="passwordHint" style="font-weight:400;color:#6c757d;">（留空不變）</span></label>
            <input type="password" name="password" placeholder="輸入新密碼" autocomplete="new-password">
        </div>
        <div class="form-group">
            <label>顯示名稱</label>
            <input type="text" name="displayName" value="<%= esc(u.getDisplayName()) %>" maxlength="100">
        </div>
        <div class="form-group">
            <label>角色</label>
            <select name="role">
                <option value="user" <%= "user".equals(u.getRole()) ? "selected" : "" %>>一般使用者</option>
                <option value="admin" <%= "admin".equals(u.getRole()) ? "selected" : "" %>>系統管理員</option>
            </select>
        </div>
        <div class="form-group">
            <label>帳號類型</label>
            <select name="accountType" id="accountType" onchange="syncAccountType()">
                <option value="normal" <%= !u.isTemporary() ? "selected" : "" %>>一般帳號（無到期）</option>
                <option value="temporary" <%= u.isTemporary() ? "selected" : "" %>>暫時帳號（到期後失效、全站唯讀）</option>
            </select>
        </div>
        <div class="form-group" id="expiryGroup" style="display:none;">
            <label>到期時間</label>
            <input type="datetime-local" name="expiresAt" id="expiresAt" value="<%= expiresValue %>">
        </div>
        <div class="form-group">
            <label>狀態</label>
            <select name="isActive">
                <option value="1" <%= u.isActive() ? "selected" : "" %>>啟用</option>
                <option value="0" <%= !u.isActive() ? "selected" : "" %>>停用</option>
            </select>
        </div>
        <div class="form-group" id="readOnlyGroup">
            <label style="display:flex;align-items:center;gap:8px;font-weight:400;">
                <input type="checkbox" name="readOnly" value="true" style="width:auto;" <%= u.isReadOnly() ? "checked" : "" %>>
                唯讀模式（暫時帳號一律強制唯讀）
            </label>
        </div>
        <button type="submit" class="btn-submit">儲存修改</button>
        <a href="user_list.jsp" class="back-link">返回帳號清單</a>
        <a href="token_list.jsp?userId=<%= u.getId() %>" class="back-link">管理此帳號的 Token</a>
    </form>
</div>
<script>
function syncAccountType() {
    var type = document.getElementById('accountType').value;
    var temporary = type === 'temporary';
    document.getElementById('expiryGroup').style.display = temporary ? 'block' : 'none';
    document.getElementById('expiresAt').required = temporary;
    document.getElementById('readOnlyGroup').style.display = temporary ? 'none' : 'block';
    document.getElementById('passwordHint').textContent = temporary
        ? '（可留空，改用 Token 登入）'
        : '（留空不變）';
}
syncAccountType();
</script>
<% } %>
<%@ include file="../include/footer.jsp" %>
