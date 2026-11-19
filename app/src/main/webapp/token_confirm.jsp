<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
    String token = (String) request.getAttribute("token");
    if (token == null || token.trim().isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String csrf = (String) session.getAttribute("csrfToken");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="referrer" content="no-referrer">
    <title>確認登入 - CharPhone</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: "Microsoft JhengHei", "Segoe UI", Arial, sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #0f0f1a;
            padding: 20px;
        }
        .card {
            background: #fff;
            border-radius: 16px;
            padding: 40px;
            width: 420px;
            max-width: 100%;
            box-shadow: 0 20px 60px rgba(0,0,0,0.35);
        }
        .logo {
            width: 56px; height: 56px;
            background: linear-gradient(135deg, #4361ee, #7c4dff);
            border-radius: 14px;
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 16px;
            color: #fff; font-size: 24px; font-weight: 800;
        }
        h1 { font-size: 20px; color: #1a1a2e; text-align: center; margin-bottom: 8px; }
        p { font-size: 14px; color: #6c757d; text-align: center; line-height: 1.6; }
        .notice {
            margin: 22px 0;
            padding: 12px 14px;
            border-radius: 8px;
            background: #fff8e1;
            color: #8a6d3b;
            font-size: 13px;
            line-height: 1.5;
        }
        .btn {
            width: 100%;
            padding: 13px;
            border: none;
            border-radius: 8px;
            background: linear-gradient(135deg, #4361ee, #3a56d4);
            color: #fff;
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            font-family: inherit;
        }
        .btn:hover { box-shadow: 0 6px 20px rgba(67,97,238,0.35); }
        .cancel {
            display: block;
            text-align: center;
            margin-top: 16px;
            color: #adb5bd;
            text-decoration: none;
            font-size: 13px;
        }
    </style>
</head>
<body>
<div class="card">
    <div class="logo">CP</div>
    <h1>確認使用存取連結</h1>
    <p>您即將以唯讀帳號登入 CharPhone 展示系統。</p>
    <div class="notice">
        為避免通訊軟體或信箱自動預覽連結時誤用您的存取碼，請按下下方按鈕完成登入。
        若這不是您本人取得的連結，請直接關閉本頁。
    </div>
    <form action="<%= request.getContextPath() %>/AccessServlet" method="POST">
        <input type="hidden" name="token" value="<%= esc(token) %>">
        <input type="hidden" name="_csrf" value="<%= esc(csrf) %>">
        <button type="submit" class="btn">確認登入</button>
    </form>
    <a class="cancel" href="<%= request.getContextPath() %>/login.jsp">返回登入頁</a>
</div>
</body>
</html>
