<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<% request.setAttribute("pageTitle", "儀表板"); %>
<% request.setAttribute("pageIcon", "■"); %>
<% request.setAttribute("pageSubtitle", "經營數據總覽"); %>
<jsp:include page="../include/header.jsp" />
<style>
    * { box-sizing: border-box; }
    body {
        font-family: "Microsoft JhengHei", "Segoe UI", Arial, sans-serif;
        margin: 0;
        padding: 30px;
        background: #f0f2f5;
        color: #1a1a2e;
    }
    .welcome-banner {
        background: linear-gradient(135deg, #4361ee, #7c4dff);
        border-radius: 12px; padding: 28px 32px; color: #fff; margin-bottom: 24px;
    }
    .welcome-banner h3 { font-size: 20px; font-weight: 700; margin: 0 0 6px 0; }
    .welcome-banner p { font-size: 14px; opacity: 0.8; margin: 0; }
    .dashboard-cards {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
        gap: 16px;
        margin-bottom: 24px;
    }
    .dashboard-card {
        background: #fff; border-radius: 10px; padding: 20px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.06);
    }
    .dashboard-card .card-label {
        font-size: 12px; color: #6c757d; font-weight: 600;
        text-transform: uppercase; letter-spacing: 0.3px;
    }
    .dashboard-card .card-value {
        font-size: 28px; font-weight: 700; color: #1a1a2e; margin-top: 6px;
    }
    .dashboard-card .card-link {
        display: inline-block; margin-top: 12px; font-size: 12px;
        color: #4361ee; text-decoration: none; font-weight: 600;
    }
    .dashboard-card .card-link:hover { text-decoration: underline; }
    .card-warn { border-left: 4px solid #f57f17; }
    .card-danger { border-left: 4px solid #c62828; }
    .card-warn .card-value { color: #f57f17; }
    .card-danger .card-value { color: #c62828; }
    .card-dev { border-left: 4px solid #9e9e9e; }
    .card-dev .card-value { color: #9e9e9e; font-size: 16px; font-weight: 600; }
    @media (max-width: 767px) {
        body { padding: 14px; }
        .welcome-banner { padding: 20px; }
        .welcome-banner h3 { font-size: 17px; }
        .dashboard-cards { grid-template-columns: 1fr; gap: 12px; }
    }
</style>
    <div class="dashboard-cards">
        <div class="dashboard-card">
            <div class="card-label">進行中訂單</div>
            <div class="card-value" id="orderCount">-</div>
            <a href="../order/order_list.jsp" class="card-link" target="content">檢視訂單 &rarr;</a>
        </div>
        <div class="dashboard-card">
            <div class="card-label">進行中工單</div>
            <div class="card-value" id="prodCount">-</div>
            <a href="../production/production_list.jsp?status=0%2C1" class="card-link" target="content">檢視工單 &rarr;</a>
        </div>
        <div class="dashboard-card">
            <div class="card-label">已出貨未收款</div>
            <div class="card-value" id="invCount">-</div>
            <a href="../invoice/invoice_list.jsp?unpaid=1" class="card-link" target="content">檢視帳款 &rarr;</a>
        </div>
        <div class="dashboard-card card-warn card-dev">
            <div class="card-label">低於安全庫存</div>
            <div class="card-value">開發中</div>
        </div>
        <div class="dashboard-card card-danger card-dev">
            <div class="card-label">高風險訂單</div>
            <div class="card-value">開發中</div>
        </div>
    </div>
    <script>
        fetch('../DashboardDataServlet')
            .then(function(r) { return r.json(); })
            .then(function(d) {
                document.getElementById('orderCount').textContent = d.orderCount;
                document.getElementById('prodCount').textContent = d.prodCount;
                document.getElementById('invCount').textContent = d.invCount;
            })
            .catch(function() {
                document.getElementById('orderCount').textContent = '?';
                document.getElementById('prodCount').textContent = '?';
                document.getElementById('invCount').textContent = '?';
            });
    </script>
<jsp:include page="../include/footer.jsp" />
