<%@ page import="model.User" %>
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
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    Boolean readOnlyAttr = (Boolean) session.getAttribute("readOnly");
    boolean isReadOnly = readOnlyAttr != null
            ? readOnlyAttr
            : (user.isTemporary() || user.isReadOnly());
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>CharPhone 管理系統</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><rect width='48' height='48' rx='10' fill='%234361ee'/><text x='24' y='34' fill='%23fff' font-size='28' font-weight='800' text-anchor='middle'>C</text></svg>">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: "Microsoft JhengHei", "Segoe UI", Arial, sans-serif;
            background: #f0f2f5;
        }

        /* ---- Sidebar ---- */
        .sidebar {
            width: 240px;
            background: linear-gradient(180deg, #1a1a3e 0%, #0d0d1a 100%);
            color: #fff;
            display: flex;
            flex-direction: column;
            position: fixed;
            top: 0; left: 0; bottom: 0;
            z-index: 100;
            transition: width 0.25s ease;
            overflow: hidden;
        }
        .sidebar.collapsed { width: 60px; }

        .sidebar-header {
            display: flex;
            align-items: flex-start;
            padding: 14px 12px 6px 16px;
            gap: 6px;
        }
        .sidebar-brand {
            display: flex;
            align-items: center;
            gap: 10px;
            min-width: 0;
            flex: 1;
        }
        .sidebar-brand .logo {
            width: 34px; height: 34px;
            flex-shrink: 0;
            background: linear-gradient(135deg, #4361ee, #7c4dff);
            border-radius: 9px;
            display: flex; align-items: center; justify-content: center;
            font-size: 15px; font-weight: 800;
        }
        .sidebar-brand .brand-text { overflow: hidden; white-space: nowrap; }
        .sidebar.collapsed .brand-text,
        .sidebar.collapsed .sidebar-user .info,
        .sidebar.collapsed .nav-section a span:not(.icon),
        .sidebar.collapsed .nav-section .section-title,
        .sidebar.collapsed .page-title { display: none; }

        .sidebar-brand h2 { font-size: 15px; font-weight: 700; }
        .sidebar-brand .version { font-size: 10px; color: rgba(255,255,255,0.4); }

        .sidebar-toggle {
            flex-shrink: 0;
            width: 28px; height: 28px; margin-top: 2px;
            background: rgba(255,255,255,0.08);
            border: none; border-radius: 6px;
            color: rgba(255,255,255,0.5);
            font-size: 15px; cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            transition: background 0.15s, color 0.15s;
        }
        .sidebar-toggle:hover { background: rgba(255,255,255,0.15); color: #fff; }

        .page-title {
            padding: 2px 20px 10px;
            font-size: 12px;
            color: rgba(255,255,255,0.35);
            letter-spacing: 0.5px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .sidebar-user {
            padding: 10px 16px;
            border-top: 1px solid rgba(255,255,255,0.06);
            border-bottom: 1px solid rgba(255,255,255,0.06);
            display: flex; align-items: center; gap: 10px;
            flex-shrink: 0;
        }
        .sidebar-user .avatar {
            width: 30px; height: 30px; flex-shrink: 0;
            border-radius: 50%;
            background: linear-gradient(135deg, #4361ee, #7c4dff);
            display: flex; align-items: center; justify-content: center;
            font-size: 12px; font-weight: 700;
        }
        .sidebar-user .info { flex: 1; overflow: hidden; }
        .sidebar-user .info .name { font-size: 12px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .sidebar-user .info .role { font-size: 10px; color: rgba(255,255,255,0.5); }
        .sidebar-user .logout { color: rgba(255,255,255,0.3); text-decoration: none; font-size: 16px; flex-shrink: 0; transition: color 0.15s; }
        .sidebar-user .logout:hover { color: #ff6b6b; }

        .nav-scroll { flex: 1; overflow-y: auto; padding-bottom: 12px; }
        .nav-scroll::-webkit-scrollbar { width: 4px; }
        .nav-scroll::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 4px; }

        .nav-section { padding: 8px 0 2px; }
        .nav-section .section-title {
            padding: 4px 20px 6px; font-size: 10px; font-weight: 700;
            text-transform: uppercase; letter-spacing: 1px; color: rgba(255,255,255,0.25);
            white-space: nowrap;
        }
        .nav-section a {
            display: flex; align-items: center; gap: 10px; padding: 8px 20px;
            color: rgba(255,255,255,0.65); text-decoration: none; font-size: 13px; font-weight: 500;
            transition: all 0.15s; border-left: 3px solid transparent;
            white-space: nowrap;
        }
        .sidebar.collapsed .nav-section a { justify-content: center; padding: 10px 0; }

        .nav-section a:hover { background: rgba(255,255,255,0.06); color: #fff; }
        .nav-section a.active { background: rgba(67,97,238,0.15); color: #fff; border-left-color: #4361ee; }
        .sidebar.collapsed .nav-section a.active { border-left-color: transparent; }
        .nav-section a .icon { width: 24px; text-align: center; font-size: 15px; flex-shrink: 0; }
        .nav-section.sub a { padding-left: 44px; font-size: 12px; }

        /* ---- Button-style nav items ---- */
        .nav-section a.nav-btn {
            margin: 4px 12px;
            padding: 10px 14px;
            border-radius: 8px;
            background: linear-gradient(135deg, rgba(67,97,238,0.18) 0%, rgba(124,77,255,0.12) 100%);
            color: rgba(255,255,255,0.9);
            font-weight: 600;
            font-size: 13px;
            border-left: none;
            transition: all 0.2s;
        }
        .nav-section a.nav-btn:hover {
            background: linear-gradient(135deg, rgba(67,97,238,0.35) 0%, rgba(124,77,255,0.25) 100%);
            color: #fff;
            transform: translateX(2px);
        }
        .nav-section a.nav-btn.active {
            background: linear-gradient(135deg, #4361ee 0%, #7c4dff 100%);
            color: #fff;
            box-shadow: 0 2px 8px rgba(67,97,238,0.3);
        }
        .sidebar.collapsed .nav-section a.nav-btn {
            margin: 4px 6px;
            padding: 10px 0;
            justify-content: center;
        }

        /* ---- Main content ---- */
        .main-content {
            margin-left: 240px;
            min-height: 100vh;
            transition: margin-left 0.25s ease;
        }
        .main-content.sidebar-collapsed { margin-left: 60px; }

        .content-frame {
            padding: 8px;
            height: 100vh;
        }
        .content-frame iframe {
            width: 100%;
            height: 100%;
            border: none;
            background: transparent;
            border-radius: 8px;
        }

        /* ---- Mobile drawer ---- */
        .sidebar-backdrop {
            display: none;
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0,0,0,0.45);
            z-index: 99;
        }
        .sidebar-backdrop.show { display: block; }

        .mobile-menu-btn {
            display: none;
            position: fixed;
            top: 12px; left: 12px;
            z-index: 130;
            width: 44px; height: 44px;
            border: none; border-radius: 10px;
            background: linear-gradient(135deg, #4361ee, #7c4dff);
            color: #fff; font-size: 20px;
            cursor: pointer;
            align-items: center; justify-content: center;
            box-shadow: 0 3px 12px rgba(67,97,238,0.45);
        }

        @media (max-width: 767px) {
            .sidebar {
                transform: translateX(-100%);
                box-shadow: none;
                transition: transform 0.25s ease;
            }
            .sidebar.open {
                transform: translateX(0);
                box-shadow: 4px 0 24px rgba(0,0,0,0.35);
            }
            .main-content, .main-content.sidebar-collapsed { margin-left: 0; }
            .mobile-menu-btn { display: flex; }
            .content-frame { padding: 6px; height: calc(100vh - 0px); }
            .content-frame iframe { border-radius: 6px; }
            .sidebar-toggle { display: none; }
        }
    </style>
</head>
<body>
<div class="sidebar-backdrop" id="sidebarBackdrop" onclick="closeMobileSidebar()"></div>
<button class="mobile-menu-btn" id="mobileMenuBtn" onclick="toggleMobileSidebar()" title="選單">☰</button>
<div class="sidebar" id="sidebar">
    <div class="sidebar-header">
        <div class="sidebar-brand">
            <div class="logo">CP</div>
            <div class="brand-text">
                <h2>CharPhone</h2>
                <div class="version">管理系統 v2.0</div>
            </div>
        </div>
        <button class="sidebar-toggle" id="sidebarToggle" onclick="toggleSidebar()" title="切換側邊欄">☰</button>
    </div>

    <div class="page-title" id="pageTitleInSidebar">儀表板</div>

    <div class="sidebar-user">
        <%
            String displayName = user.getDisplayName();
            String avatarText = (displayName != null && !displayName.isBlank()) ? String.valueOf(displayName.charAt(0)) : "U";
        %>
        <div class="avatar"><%= esc(avatarText) %></div>
        <div class="info">
            <div class="name"><%= esc((displayName != null && !displayName.isBlank()) ? displayName : user.getUsername()) %></div>
            <div class="role"><%= isReadOnly ? "唯讀使用者" : ("admin".equals(user.getRole()) ? "系統管理員" : "一般使用者") %></div>
        </div>
        <a href="LogoutServlet" class="logout" title="登出">✕</a>
    </div>

    <div class="nav-scroll">
        <div class="nav-section">
            <div class="section-title">主要功能</div>
            <a class="nav-btn" href="order/order_list.jsp" target="content"><span class="icon">☰</span>訂單管理</a>
            <a class="nav-btn" href="dashboard/dashboard.jsp" target="content"><span class="icon">■</span>儀表板</a>
        </div>
        <div class="nav-section">
            <div class="section-title">個別功能管理</div>
            <a href="production/production_list.jsp" target="content"><span class="icon">⚙</span>生產管理</a>
            <a href="delivery/delivery_list.jsp" target="content"><span class="icon">▶</span>出貨管理</a>
            <a href="invoice/invoice_list.jsp" target="content"><span class="icon">$</span>應收帳款</a>
            <a href="inventory/inventory_list.jsp" target="content"><span class="icon">■</span>存貨管理</a>
        </div>
        <div class="nav-section">
            <div class="section-title">其它功能</div>
            <a href="simulation/simulation.jsp?tab=2" target="content"><span class="icon">▶</span>出貨試算</a>
        </div>
        <div class="nav-section">
            <div class="section-title">基本資料</div>
            <a href="customer/customer_list.jsp" target="content"><span class="icon">☉</span>客戶管理</a>
            <a href="product/product_list.jsp" target="content"><span class="icon">★</span>品項管理</a>
        </div>
        <% if ("admin".equals(user.getRole()) && !isReadOnly) { %>
        <div class="nav-section">
            <div class="section-title">系統設定</div>
            <a href="user/user_list.jsp" target="content"><span class="icon">☏</span>帳號管理</a>
        </div>
        <% } %>
        <div class="nav-section">
            <div class="section-title">AI 功能</div>
            <a href="ai.jsp" target="content"><span class="icon">✦</span>企業AI</a>
            <a href="AiProxyServlet" target="_blank" rel="noopener"><span class="icon">⚙</span>AI 技術測試</a>
            <% if ("admin".equals(user.getRole()) && !isReadOnly) { %>
            <a href="AiAdminServlet/" target="content"><span class="icon">▣</span>AI 管理</a>
            <% } %>
        </div>
    </div>
</div>

<div class="main-content" id="mainContent">
    <div class="content-frame">
        <iframe name="content" src="dashboard/dashboard.jsp" onload="updatePageTitle(this)"></iframe>
    </div>
</div>

<script>
function isMobileView() {
    return window.innerWidth <= 767;
}

function toggleSidebar() {
    var s = document.getElementById('sidebar');
    var m = document.getElementById('mainContent');
    var collapsed = s.classList.toggle('collapsed');
    m.classList.toggle('sidebar-collapsed', collapsed);
    localStorage.setItem('sidebarCollapsed', collapsed ? '1' : '0');
}

function openMobileSidebar() {
    document.getElementById('sidebar').classList.add('open');
    document.getElementById('sidebarBackdrop').classList.add('show');
    document.getElementById('mobileMenuBtn').textContent = '✕';
}

function closeMobileSidebar() {
    document.getElementById('sidebar').classList.remove('open');
    document.getElementById('sidebarBackdrop').classList.remove('show');
    document.getElementById('mobileMenuBtn').textContent = '☰';
}

function toggleMobileSidebar() {
    var s = document.getElementById('sidebar');
    if (s.classList.contains('open')) {
        closeMobileSidebar();
    } else {
        openMobileSidebar();
    }
}

function onNavToggleClick() {
    if (isMobileView()) {
        toggleMobileSidebar();
    } else {
        toggleSidebar();
    }
}

function updatePageTitle(frame) {
    try {
        var t = frame.contentDocument.title;
        if (t) {
            document.getElementById('pageTitleInSidebar').textContent = t.replace(' - CharPhone', '');
        }
    } catch(e) {}
}

document.getElementById('sidebarToggle').onclick = onNavToggleClick;
document.querySelectorAll('#sidebar .nav-scroll a').forEach(function(a) {
    a.addEventListener('click', function() {
        if (isMobileView()) {
            closeMobileSidebar();
        }
    });
});
window.addEventListener('resize', function() {
    if (!isMobileView()) {
        closeMobileSidebar();
    }
});

(function() {
    if (localStorage.getItem('sidebarCollapsed') === '1') {
        document.getElementById('sidebar').classList.add('collapsed');
        document.getElementById('mainContent').classList.add('sidebar-collapsed');
    }
})();
</script>
<jsp:include page="include/footer.jsp" />
