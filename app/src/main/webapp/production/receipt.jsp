<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.math.BigDecimal, util.NumberUtil, dao.ProductionDao, model.Production" %>
<% request.setAttribute("pageTitle", "生產入庫"); %>
<% request.setAttribute("pageIcon", "⚙"); %>
<% request.setAttribute("pageSubtitle", "登錄成品入庫"); %>
<%@ include file="../include/header.jsp" %>

<div class="form-container">
    <h2>生產入庫</h2>

    <%
        String idStr = request.getParameter("id");
        if (idStr == null || idStr.isEmpty()) {
            out.println("<div class='error-msg'>無效的工單編號。</div>");
        } else {
            String error = request.getParameter("error");
            if ("failed".equals(error)) {
    %>
        <div class="error-msg">入庫失敗，請稍後再試。</div>
    <% } else if ("invalid_qty".equals(error)) { %>
        <div class="error-msg">入庫數量必須大於 0。</div>
    <% } else if ("exceed".equals(error)) { %>
        <div class="error-msg">入庫數量不能超過已製造數量。</div>
    <% } else if ("create_failed".equals(error)) { %>
        <div class="error-msg">建立庫存品項失敗。</div>
    <% }

        int productionId = Integer.parseInt(idStr);
        ProductionDao dao = new ProductionDao();
        Production p = dao.getProductionById(productionId);
        if (p == null) {
            out.println("<div class='error-msg'>找不到此工單。</div>");
            return;
        }

        String prodNumber = p.getProductionNumber();
        String productName = p.getProductName();
        String unit = p.getPriceType() == 1 ? "kg" : "pcs";
        BigDecimal manufacturedQty = p.getManufacturedQty() != null ? p.getManufacturedQty() : BigDecimal.ZERO;
        int status = p.getStatus();
        int productId = p.getProductId();

        BigDecimal netReceived = dao.getNetReceivedQty(productionId);
        BigDecimal currentStock = dao.getStockForProduct(productId);
    %>

    <div class="order-info">
        <span><b>工單編號：</b><%= prodNumber %></span>
        <span><b>品項：</b><%= productName %></span>
        <span><b>單位：</b><%= unit %></span>
    </div>
    <div class="order-info" style="margin-top:8px;background:#fff5f5;border-left-color:#28a745;">
        <span><b>已製造：</b><%= NumberUtil.fmtQty(manufacturedQty.doubleValue()) %> <%= unit %></span>
        <span><b>已入庫：</b><%= NumberUtil.fmtQty(netReceived.doubleValue()) %> <%= unit %></span>
        <span><b>待入庫：</b><%= NumberUtil.fmtQty(manufacturedQty.subtract(netReceived).doubleValue()) %> <%= unit %></span>
        <span style="margin-left:20px;"><b>成品倉庫存：</b><%= NumberUtil.fmtQty(currentStock.doubleValue()) %> <%= unit %></span>
    </div>

    <% if (status == 3) { %>
        <div class="error-msg">此工單已取消，無法入庫。</div>
    <% } else if (manufacturedQty.compareTo(BigDecimal.ZERO) <= 0) { %>
        <div class="error-msg">此工單尚無已製造數量，無法入庫。</div>
    <% } else if (manufacturedQty.subtract(netReceived).compareTo(BigDecimal.ZERO) <= 0) { %>
        <div class="error-msg">生產的數量已全數入庫。</div>
    <% } else { %>

    <form action="<%= request.getContextPath() %>/ProductionReceiptServlet" method="POST">
        <input type="hidden" name="productionId" value="<%= productionId %>">
        <input type="hidden" name="orderId" value="<%= request.getParameter("orderId") != null ? request.getParameter("orderId") : "" %>">

        <div class="form-group">
            <label>入庫數量 (<%= unit %>)</label>
            <input type="number" name="quantity" step="any" 
                   value="<%= NumberUtil.fmtQty(manufacturedQty.subtract(netReceived).doubleValue()) %>"
                   max="<%= NumberUtil.fmtQty(manufacturedQty.subtract(netReceived).doubleValue()) %>"
                   required>
            <small style="color:#6c757d;font-size:12px;">最多可入庫：<%= NumberUtil.fmtQty(manufacturedQty.subtract(netReceived).doubleValue()) %> <%= unit %></small>
        </div>

        <div class="form-group">
            <label>備註</label>
            <input type="text" name="note" value="生產入庫：<%= prodNumber %>" placeholder="入庫備註">
        </div>

        <button type="submit" class="btn-submit">確認入庫</button>
        <a href="production_list.jsp?orderId=<%= request.getParameter("orderId") != null ? request.getParameter("orderId") : "" %>" class="back-link">返回工單列表</a>
    </form>

    <% }
    } %>
</div>

<%@ include file="../include/footer.jsp" %>