<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.User, java.sql.Timestamp, java.text.SimpleDateFormat" %>
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
    response.setHeader("Cache-Control", "no-store");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Referrer-Policy", "no-referrer");

    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"admin".equals(currentUser.getRole())) {
        response.sendRedirect("../login.jsp");
        return;
    }

    String rawToken = (String) session.getAttribute("newTokenPlain");
    String magicLink = (String) session.getAttribute("newTokenLink");
    String label = (String) session.getAttribute("newTokenLabel");
    Timestamp expiresAt = (Timestamp) session.getAttribute("newTokenExpiresAt");
    Integer maxUses = (Integer) session.getAttribute("newTokenMaxUses");
    Integer userId = (Integer) session.getAttribute("newTokenUserId");
    String hint = (String) session.getAttribute("newTokenHint");

    session.removeAttribute("newTokenPlain");
    session.removeAttribute("newTokenLink");
    session.removeAttribute("newTokenLabel");
    session.removeAttribute("newTokenExpiresAt");
    session.removeAttribute("newTokenMaxUses");
    session.removeAttribute("newTokenUserId");
    session.removeAttribute("newTokenHint");

    if (rawToken == null) {
        response.sendRedirect("user_list.jsp");
        return;
    }
    String expiresText = expiresAt != null
            ? new SimpleDateFormat("yyyy-MM-dd HH:mm").format(expiresAt) : "";
%>
<% request.setAttribute("pageTitle", "Token 已建立"); %>
<% request.setAttribute("pageIcon", "☏"); %>
<% request.setAttribute("pageSubtitle", "請立即複製，離開後無法再次顯示"); %>
<%@ include file="../include/header.jsp" %>
<div class="form-container" style="max-width:760px;">
    <h2>Token 已建立</h2>
    <div class="alert alert-danger" style="margin-bottom:20px;">
        基於安全考量，Token 明文只會顯示這一次。重新整理或離開本頁後將無法再次取得。
    </div>

    <div class="form-group">
        <label>Token 名稱</label>
        <div style="padding:10px 12px;background:#f8f9fa;border-radius:8px;"><%= esc(label) %></div>
    </div>
    <div class="form-group">
        <label>到期時間 / 使用次數</label>
        <div style="padding:10px 12px;background:#f8f9fa;border-radius:8px;">
            <%= esc(expiresText) %> ｜ <%= maxUses != null ? maxUses + " 次" : "不限次數" %>
            <span style="color:#6c757d;">（Token 提示：<%= esc(hint) %>）</span>
        </div>
    </div>

    <div class="form-group">
        <label>Magic Link（點擊即進確認頁）</label>
        <div style="display:flex;gap:8px;">
            <input type="text" id="magicLink" readonly value="<%= esc(magicLink) %>" style="flex:1;">
            <button type="button" class="btn btn-primary" onclick="copyValue('magicLink', this)">複製</button>
        </div>
    </div>
    <div class="form-group">
        <label>手動存取碼</label>
        <div style="display:flex;gap:8px;">
            <input type="text" id="rawToken" readonly value="<%= esc(rawToken) %>" style="flex:1;font-family:monospace;">
            <button type="button" class="btn btn-primary" onclick="copyValue('rawToken', this)">複製</button>
        </div>
    </div>

    <a href="token_list.jsp?userId=<%= userId != null ? userId : "" %>" class="btn-submit" style="display:inline-block;text-decoration:none;text-align:center;">返回 Token 管理</a>
    <a href="user_list.jsp" class="back-link">返回帳號清單</a>
</div>
<script>
function copyValue(id, btn) {
    var input = document.getElementById(id);
    input.select();
    input.setSelectionRange(0, 99999);
    try {
        navigator.clipboard.writeText(input.value).then(function() {
            var old = btn.textContent;
            btn.textContent = '已複製';
            setTimeout(function() { btn.textContent = old; }, 1500);
        });
    } catch (e) {
        document.execCommand('copy');
    }
}
</script>
<%@ include file="../include/footer.jsp" %>
