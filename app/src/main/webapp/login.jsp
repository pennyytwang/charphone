<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String csrf = (String) session.getAttribute("csrfToken");
    if (csrf == null) {
        byte[] b = new byte[32];
        new java.security.SecureRandom().nextBytes(b);
        csrf = java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(b);
        session.setAttribute("csrfToken", csrf);
    }
    String tab = request.getParameter("tab");
    if (tab == null) tab = "password";
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>登入 - CharPhone</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
        font-family: "Microsoft JhengHei", "Segoe UI", Arial, sans-serif;
        height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #0f0f1a url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1440 900"><defs><linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="%231a1a3e"/><stop offset="100%" stop-color="%230d0d1a"/></linearGradient></defs><rect fill="url(%23g)" width="1440" height="900"/><circle cx="200" cy="150" r="300" fill="%234361ee" opacity="0.08"/><circle cx="1200" cy="650" r="400" fill="%234361ee" opacity="0.06"/><circle cx="700" cy="450" r="250" fill="%237c4dff" opacity="0.05"/><path d="M0 900 L1440 700 L1440 900 Z" fill="%234361ee" opacity="0.03"/></svg>') no-repeat center/cover;
    }
    .login-card {
        background: rgba(255,255,255,0.97);
        border-radius: 16px;
        padding: 40px 40px 40px;
        width: 400px;
        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
    }
    .login-card h1 { font-size: 22px; font-weight: 700; color: #1a1a2e; text-align: center; margin-bottom: 4px; }
    .login-card .subtitle { text-align: center; color: #6c757d; font-size: 13px; margin-bottom: 24px; }
    .login-card .logo {
        width: 56px; height: 56px;
        background: linear-gradient(135deg, #4361ee, #7c4dff);
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 16px;
        color: #fff;
        font-size: 24px;
        font-weight: 800;
        box-shadow: 0 4px 12px rgba(67,97,238,0.3);
    }
    .login-tabs { display: flex; gap: 8px; margin-bottom: 22px; background: #f0f2f5; border-radius: 10px; padding: 4px; }
    .login-tab {
        flex: 1; padding: 9px 8px; border: none; border-radius: 8px;
        background: transparent; color: #6c757d; font-size: 13px; font-weight: 700;
        font-family: inherit; cursor: pointer; transition: all 0.15s;
    }
    .login-tab.active { background: #fff; color: #1a1a2e; box-shadow: 0 1px 4px rgba(0,0,0,0.08); }
    .form-group { margin-bottom: 20px; }
    .form-group label { display: block; font-size: 13px; font-weight: 600; color: #495057; margin-bottom: 6px; }
    .form-group input {
        width: 100%; padding: 12px 14px;
        border: 1.5px solid #e0e0e0; border-radius: 8px;
        font-size: 14px; font-family: inherit;
        transition: border-color 0.2s, box-shadow 0.2s;
        outline: none; background: #f8f9fc;
    }
    .form-group input:focus { border-color: #4361ee; box-shadow: 0 0 0 3px rgba(67,97,238,0.12); background: #fff; }
    .hint { font-size: 12px; color: #6c757d; line-height: 1.6; margin: -8px 0 18px; }
    .btn-login {
        width: 100%; padding: 13px;
        background: linear-gradient(135deg, #4361ee, #3a56d4);
        color: #fff; border: none; border-radius: 8px;
        font-size: 15px; font-weight: 700; font-family: inherit;
        cursor: pointer; transition: transform 0.15s, box-shadow 0.15s;
    }
    .btn-login:hover { transform: translateY(-1px); box-shadow: 0 6px 20px rgba(67,97,238,0.35); }
    .btn-login:active { transform: translateY(0); }
    .error-msg {
        background: #fff5f5; color: #d32f2f;
        padding: 10px 14px; border-radius: 8px;
        font-size: 13px; margin-bottom: 16px;
        text-align: center; border-left: 3px solid #d32f2f;
    }
    .login-footer { text-align: center; margin-top: 24px; font-size: 12px; color: #adb5bd; }
    @media (max-width: 480px) {
        .login-card { width: calc(100vw - 40px); padding: 32px 24px; border-radius: 14px; }
        .login-card h1 { font-size: 19px; }
        .form-group input { font-size: 16px; }
        .btn-login { font-size: 16px; }
    }
</style>
</head>
<body>
<div class="login-card">
    <div class="logo">CP</div>
    <h1>CharPhone 管理系統</h1>
    <p class="subtitle">請選擇登入方式</p>

    <%
        String error = request.getParameter("error");
        if ("failed".equals(error)) {
    %>
        <div class="error-msg">帳號或密碼錯誤，請重新輸入。</div>
    <% } else if ("empty".equals(error)) { %>
        <div class="error-msg">請輸入帳號與密碼。</div>
    <% } else if ("session_expired".equals(error)) { %>
        <div class="error-msg">登入狀態已失效，請重新登入。</div>
    <% } else if ("token_invalid".equals(error)) { %>
        <div class="error-msg">存取碼無效或已過期。</div>
    <% } else if ("token_empty".equals(error)) { %>
        <div class="error-msg">請輸入存取碼。</div>
    <% } %>

    <div class="login-tabs">
        <button type="button" class="login-tab <%= !"token".equals(tab) ? "active" : "" %>" id="tabPasswordBtn" onclick="switchTab('password')">帳號密碼</button>
        <button type="button" class="login-tab <%= "token".equals(tab) ? "active" : "" %>" id="tabTokenBtn" onclick="switchTab('token')">存取碼登入</button>
    </div>

    <div id="passwordPane" style="<%= "token".equals(tab) ? "display:none;" : "" %>">
        <form action="LoginServlet" method="POST">
            <input type="hidden" name="_csrf" value="<%= csrf != null ? csrf : "" %>">
            <div class="form-group">
                <label for="username">帳號</label>
                <input type="text" id="username" name="username" placeholder="請輸入帳號" autofocus>
            </div>
            <div class="form-group">
                <label for="password">密碼</label>
                <input type="password" id="password" name="password" placeholder="請輸入密碼">
            </div>
            <button type="submit" class="btn-login">登入系統</button>
        </form>
    </div>

    <div id="tokenPane" style="<%= "token".equals(tab) ? "" : "display:none;" %>">
        <form action="TokenLoginServlet" method="POST">
            <input type="hidden" name="_csrf" value="<%= csrf != null ? csrf : "" %>">
            <div class="form-group">
                <label for="token">存取碼</label>
                <input type="text" id="token" name="token" placeholder="cp_..." autocomplete="off" spellcheck="false" style="font-family:monospace;">
            </div>
            <p class="hint">
                面試／展示用的存取碼由管理員建立，可能設有到期時間與使用次數。
                若您收到的是 Magic Link，直接點擊連結即可。
            </p>
            <button type="submit" class="btn-login">以存取碼登入</button>
        </form>
    </div>

    <div class="login-footer">CharPhone 訂單管理系統 v2.0</div>
</div>
<script>
function switchTab(name) {
    var isToken = name === 'token';
    document.getElementById('passwordPane').style.display = isToken ? 'none' : 'block';
    document.getElementById('tokenPane').style.display = isToken ? 'block' : 'none';
    document.getElementById('tabPasswordBtn').classList.toggle('active', !isToken);
    document.getElementById('tabTokenBtn').classList.toggle('active', isToken);
    if (isToken) {
        document.getElementById('token').focus();
    } else {
        document.getElementById('username').focus();
    }
}
</script>
</body>
</html>
