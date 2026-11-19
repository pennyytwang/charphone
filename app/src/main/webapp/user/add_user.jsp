<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"admin".equals(currentUser.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<% request.setAttribute("pageTitle", "新增帳號"); %>
<% request.setAttribute("pageIcon", "☏"); %>
<% request.setAttribute("pageSubtitle", "建立使用者帳號"); %>
<%@ include file="../include/header.jsp" %>
<div class="form-container">
    <h2>新增帳號</h2>
    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">新增失敗，請稍後再試。</div>
    <% } else if ("duplicate".equals(error)) { %>
        <div class="error-msg">此帳號名稱已被使用。</div>
    <% } else if ("password_required".equals(error)) { %>
        <div class="error-msg">一般帳號必須設定密碼。</div>
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
    <% } %>
    <form action="../UserServlet" method="POST">
        <div class="form-group">
            <label>帳號</label>
            <input type="text" name="username" required maxlength="50">
        </div>
        <div class="form-group">
            <label>密碼 <span id="passwordHint" style="font-weight:400;color:#6c757d;">（一般帳號必填）</span></label>
            <input type="password" name="password" autocomplete="new-password">
        </div>
        <div class="form-group">
            <label>顯示名稱</label>
            <input type="text" name="displayName" placeholder="例如: 王大明" maxlength="100">
        </div>
        <div class="form-group">
            <label>角色</label>
            <select name="role">
                <option value="user">一般使用者</option>
                <option value="admin">系統管理員</option>
            </select>
        </div>
        <div class="form-group">
            <label>帳號類型</label>
            <select name="accountType" id="accountType" onchange="syncAccountType()">
                <option value="normal">一般帳號（無到期）</option>
                <option value="temporary">暫時帳號（到期後失效、全站唯讀）</option>
            </select>
        </div>
        <div class="form-group" id="expiryGroup" style="display:none;">
            <label>到期時間</label>
            <input type="datetime-local" name="expiresAt" id="expiresAt">
        </div>
        <div class="form-group">
            <label>狀態</label>
            <select name="isActive">
                <option value="1">啟用</option>
                <option value="0">停用</option>
            </select>
        </div>
        <div class="form-group" id="readOnlyGroup">
            <label style="display:flex;align-items:center;gap:8px;font-weight:400;">
                <input type="checkbox" name="readOnly" value="true" style="width:auto;">
                唯讀模式（暫時帳號一律強制唯讀）
            </label>
        </div>
        <button type="submit" class="btn-submit">確認新增</button>
        <a href="user_list.jsp" class="back-link">返回帳號清單</a>
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
        : '（一般帳號必填）';
}
syncAccountType();
</script>
<%@ include file="../include/footer.jsp" %>
