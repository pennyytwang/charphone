<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>唯讀模式 - CharPhone</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: "Microsoft JhengHei", "Segoe UI", Arial, sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #f0f2f5;
            padding: 20px;
        }
        .card {
            background: #fff;
            border-radius: 14px;
            padding: 36px 32px;
            width: 440px;
            max-width: 100%;
            box-shadow: 0 12px 40px rgba(0,0,0,0.12);
            text-align: center;
        }
        .icon {
            width: 54px; height: 54px;
            margin: 0 auto 16px;
            border-radius: 50%;
            background: #fff3e0;
            color: #e65100;
            display: flex; align-items: center; justify-content: center;
            font-size: 26px;
        }
        h1 { font-size: 20px; color: #1a1a2e; margin-bottom: 10px; }
        p { font-size: 14px; color: #6c757d; line-height: 1.7; margin-bottom: 22px; }
        .btn {
            display: inline-block;
            padding: 10px 22px;
            border-radius: 8px;
            background: #4361ee;
            color: #fff;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
        }
    </style>
</head>
<body>
<div class="card">
    <div class="icon">!</div>
    <h1>此帳號為唯讀模式</h1>
    <p>展示帳號僅能瀏覽資料，無法新增、修改或刪除。<br>如需完整功能，請聯絡系統管理員。</p>
    <a class="btn" href="<%= request.getContextPath() %>/index.jsp" target="_top">返回首頁</a>
</div>
</body>
</html>
