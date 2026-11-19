<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.math.BigDecimal, java.util.*, java.text.SimpleDateFormat, util.NumberUtil, dao.ProductDao, dao.ProductionDao, dao.SimulationDao, model.Product" %>
<% request.setAttribute("pageTitle", "出貨試算"); %>
<% request.setAttribute("pageIcon", "▶"); %>
<% request.setAttribute("pageSubtitle", "依庫存試算出貨量"); %>
<%@ include file="../include/header.jsp" %>
<style>
.sim-table { width:100%; border-collapse:collapse; font-size:13px; }
.sim-table th { background:#f0f4ff; padding:8px 10px; border:1px solid #ddd; text-align:center; font-size:13px; }
.sim-table td { padding:6px 10px; border:1px solid #ddd; text-align:right; }
.sim-table td:first-child, .sim-table td:nth-child(2) { text-align:left; }
.risk-high { background:#ffebee; color:#c62828; font-weight:bold; }
.risk-mid { background:#fff8e1; color:#f57f17; font-weight:bold; }
.risk-low { background:#e8f5e9; color:#2e7d32; font-weight:bold; }
.badge { display:inline-block; padding:2px 10px; border-radius:12px; font-size:12px; font-weight:bold; }
.badge-red { background:#ffcdd2; color:#b71c1c; }
.badge-yellow { background:#fff9c4; color:#f57f17; }
.badge-green { background:#c8e6c9; color:#1b5e20; }
</style>

<%
    String tab = request.getParameter("tab");
    if (tab == null || tab.isEmpty()) tab = "2";
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    String today = sdf.format(new java.util.Date());
    ProductDao prodDao = new ProductDao();
%>

<div class="form-container" style="max-width:1100px;">

    <div class="tab-bar">
        <a href="simulation.jsp?tab=2" class="tab <%= "2".equals(tab) ? "active" : "" %>">訂單交期風險</a>
        <a href="simulation.jsp?tab=3" class="tab <%= "3".equals(tab) ? "active" : "" %>">每日供需模擬</a>
        <a href="simulation.jsp?tab=1" class="tab <%= "1".equals(tab) ? "active" : "" %>">單品試算</a>
    </div>

<% if ("1".equals(tab)) { %>

    <!----- TAB 1: 單產品試算 ----->
    <form method="GET" action="simulation.jsp" style="display:flex;gap:12px;flex-wrap:wrap;align-items:flex-end;margin-bottom:20px;">
        <input type="hidden" name="tab" value="1">
        <div>
            <label style="display:block;font-size:13px;margin-bottom:4px;">產品</label>
            <select name="productId" style="padding:6px;border:1px solid #ccc;border-radius:4px;min-width:200px;">
                <option value="">-- 請選擇 --</option>
                <%
                    String selP1 = request.getParameter("productId");
                    for (Product prod : prodDao.getAllProducts()) {
                %>
                <option value="<%= prod.getId() %>" <%= (selP1 != null && selP1.equals(String.valueOf(prod.getId()))) ? "selected" : "" %>><%= prod.getProductName() %></option>
                <%
                    }
                %>
            </select>
        </div>
        <div>
            <label style="display:block;font-size:13px;margin-bottom:4px;">預計出貨日</label>
            <input type="date" name="deliveryDate" value="<%= request.getParameter("deliveryDate") != null ? request.getParameter("deliveryDate") : today %>" style="padding:6px;border:1px solid #ccc;border-radius:4px;">
        </div>
        <div>
            <label style="display:block;font-size:13px;margin-bottom:4px;">預計出貨量</label>
            <input type="number" name="deliveryQty" step="any" value="<%= request.getParameter("deliveryQty") != null ? request.getParameter("deliveryQty") : "" %>" style="padding:6px;border:1px solid #ccc;border-radius:4px;width:120px;">
        </div>
        <button type="submit" class="btn-submit" style="padding:6px 20px;">試算</button>
    </form>

    <%
        if (selP1 != null && !selP1.isEmpty()) {
            int productId = Integer.parseInt(selP1);
            String deliveryDateStr = request.getParameter("deliveryDate");
            String deliveryQtyStr = request.getParameter("deliveryQty");
            if (deliveryDateStr != null && !deliveryDateStr.isEmpty() && deliveryQtyStr != null && !deliveryQtyStr.isEmpty()) {
                try {
                    BigDecimal deliveryQty = new BigDecimal(deliveryQtyStr);
                    ProductionDao prodDao2 = new ProductionDao();
                    Product prod = prodDao.getProductById(productId);
                    String productName = prod != null ? prod.getProductName() : "";
                    BigDecimal currentStock = prodDao2.getStockForProduct(productId);
                    List<Map<String, Object>> prodList = prodDao2.getProductionsByProductAndDate(productId, deliveryDateStr);
                    BigDecimal potentialSupply = BigDecimal.ZERO;
                    for (Map<String, Object> row : prodList) {
                        BigDecimal planned = (BigDecimal) row.get("planned");
                        BigDecimal received = (BigDecimal) row.get("received");
                        BigDecimal remaining = planned.subtract(received);
                        row.put("remaining", remaining.compareTo(BigDecimal.ZERO) > 0 ? remaining : BigDecimal.ZERO);
                        if (remaining.compareTo(BigDecimal.ZERO) > 0) potentialSupply = potentialSupply.add(remaining);
                    }
                    BigDecimal totalAvailable = currentStock.add(potentialSupply);
                    boolean canDeliver = totalAvailable.compareTo(deliveryQty) >= 0;
    %>
    <div style="background:#fff;border:1px solid #ddd;border-radius:8px;padding:20px;margin-top:16px;">
        <h3 style="margin-top:0;">試算結果：<%= productName %></h3>
        <table style="width:100%;border-collapse:collapse;margin-bottom:16px;">
            <tr><td style="padding:8px;border-bottom:1px solid #eee;font-weight:bold;">目前 WH-FG 庫存</td><td style="padding:8px;border-bottom:1px solid #eee;text-align:right;"><%= NumberUtil.fmtQty(currentStock.doubleValue()) %></td></tr>
            <tr><td style="padding:8px;border-bottom:1px solid #eee;font-weight:bold;">到期前未入庫量</td><td style="padding:8px;border-bottom:1px solid #eee;text-align:right;color:#1976d2;">+ <%= NumberUtil.fmtQty(potentialSupply.doubleValue()) %></td></tr>
            <tr style="font-size:16px;"><td style="padding:8px;border-bottom:2px solid #333;font-weight:bold;">預計可供量</td><td style="padding:8px;border-bottom:2px solid #333;text-align:right;font-weight:bold;"><%= NumberUtil.fmtQty(totalAvailable.doubleValue()) %></td></tr>
            <tr><td style="padding:8px;font-weight:bold;">預計出貨量</td><td style="padding:8px;text-align:right;"><%= NumberUtil.fmtQty(deliveryQty.doubleValue()) %></td></tr>
        </table>
        <div style="text-align:center;padding:16px;border-radius:8px;font-size:18px;font-weight:bold;background:<%= canDeliver ? "#e8f5e9" : "#ffebee" %>;color:<%= canDeliver ? "#2e7d32" : "#c62828" %>;">
            <%= canDeliver ? "✅  可如期出貨" : "❌  可能短缺 " + NumberUtil.fmtQty(deliveryQty.subtract(totalAvailable).doubleValue()) + " 單位" %>
        </div>
        <% if (!prodList.isEmpty()) { %>
        <table class="sim-table" style="margin-top:16px;">
            <tr><th colspan="5">到期前工單</th></tr>
            <tr><th>計畫量</th><th>已入庫</th><th>待入庫</th></tr>
            <% for (Map<String, Object> row : prodList) { %>
            <tr><td><%= NumberUtil.fmtQty(((BigDecimal)row.get("planned")).doubleValue()) %></td><td><%= NumberUtil.fmtQty(((BigDecimal)row.get("received")).doubleValue()) %></td><td><%= NumberUtil.fmtQty(((BigDecimal)row.get("remaining")).doubleValue()) %></td></tr>
            <% } %>
        </table>
        <% } %>
    </div>
    <%
                } catch (Exception e) { out.println("<div class='error-msg'>" + e.getMessage() + "</div>"); e.printStackTrace(); }
            }
        }
    %>

<% } else if ("2".equals(tab)) { %>

    <!----- TAB 2: 訂單交期風險 ----->
    <%
        try {
            SimulationDao simDao = new SimulationDao();
            List<Map<String, Object>> rows = simDao.getOrderRiskAnalysis();
    %>
    <% if (rows.isEmpty()) { %>
        <div style="padding:40px;text-align:center;color:#888;">目前無未出貨訂單</div>
    <% } else { %>
    <table class="sim-table">
        <tr>
            <th>訂單編號</th>
            <th>客戶</th>
            <th>產品</th>
            <th>總量</th>
            <th>已出貨</th>
            <th>未出貨</th>
            <th>庫存</th>
            <th>將入庫</th>
            <th>可供量</th>
            <th>預期日</th>
            <th>風險</th>
        </tr>
        <% for (Map<String, Object> r : rows) {
            String riskClass = "risk-low";
            String badgeClass = "badge-green";
            String riskLabel = "低";
            if ("mid".equals(r.get("risk"))) { riskClass = "risk-mid"; badgeClass = "badge-yellow"; riskLabel = "中"; }
            else if ("high".equals(r.get("risk"))) { riskClass = "risk-high"; badgeClass = "badge-red"; riskLabel = "高"; }
        %>
        <tr class="<%= riskClass %>">
            <td><%= r.get("orderNumber") %></td>
            <td><%= r.get("customerName") %></td>
            <td><%= r.get("productName") %></td>
            <td><%= NumberUtil.fmtQty(((BigDecimal)r.get("totalQty")).doubleValue()) %></td>
            <td><%= NumberUtil.fmtQty(((BigDecimal)r.get("deliveredQty")).doubleValue()) %></td>
            <td><%= NumberUtil.fmtQty(((BigDecimal)r.get("remainingQty")).doubleValue()) %></td>
            <td><%= NumberUtil.fmtQty(((BigDecimal)r.get("stockQty")).doubleValue()) %></td>
            <td>+<%= NumberUtil.fmtQty(((BigDecimal)r.get("prodSupply")).doubleValue()) %></td>
            <td><%= NumberUtil.fmtQty(((BigDecimal)r.get("available")).doubleValue()) %></td>
            <td><%= r.get("expectedDate") != null ? r.get("expectedDate") : "-" %></td>
            <td><span class="badge <%= badgeClass %>"><%= riskLabel %></span></td>
        </tr>
        <% } %>
    </table>
    <% } %>
    <%
        } catch (Exception e) { e.printStackTrace(); }
    %>

<% } else if ("3".equals(tab)) { %>

    <!----- TAB 3: 每日供需模擬 ----->
    <form method="GET" action="simulation.jsp" style="display:flex;gap:12px;flex-wrap:wrap;align-items:flex-end;margin-bottom:20px;">
        <input type="hidden" name="tab" value="3">
        <div>
            <label style="display:block;font-size:13px;margin-bottom:4px;">產品</label>
            <select name="productId" style="padding:6px;border:1px solid #ccc;border-radius:4px;min-width:200px;">
                <option value="">-- 請選擇 --</option>
                <%
                    String selP3_dd = request.getParameter("productId");
                    for (Product prod : prodDao.getAllProducts()) {
                %>
                <option value="<%= prod.getId() %>" <%= (selP3_dd != null && selP3_dd.equals(String.valueOf(prod.getId()))) ? "selected" : "" %>><%= prod.getProductName() %></option>
                <%
                    }
                %>
            </select>
        </div>
        <div>
            <label style="display:block;font-size:13px;margin-bottom:4px;">起</label>
            <input type="date" name="dateFrom" value="<%= request.getParameter("dateFrom") != null ? request.getParameter("dateFrom") : today %>" style="padding:6px;border:1px solid #ccc;border-radius:4px;">
        </div>
        <div>
            <label style="display:block;font-size:13px;margin-bottom:4px;">迄</label>
            <%
                java.util.Calendar cal_tmp = java.util.Calendar.getInstance();
                cal_tmp.add(java.util.Calendar.DAY_OF_MONTH, 30);
                String defaultEnd = sdf.format(cal_tmp.getTime());
            %>
            <input type="date" name="dateTo" value="<%= request.getParameter("dateTo") != null ? request.getParameter("dateTo") : defaultEnd %>" style="padding:6px;border:1px solid #ccc;border-radius:4px;">
        </div>
        <button type="submit" class="btn-submit" style="padding:6px 20px;">模擬</button>
    </form>

    <%
        String selP3 = request.getParameter("productId");
        String dateFrom = request.getParameter("dateFrom");
        String dateTo = request.getParameter("dateTo");
        if (selP3 != null && !selP3.isEmpty() && dateFrom != null && !dateFrom.isEmpty() && dateTo != null && !dateTo.isEmpty()) {
            int productId3 = Integer.parseInt(selP3);
            Product prod3 = prodDao.getProductById(productId3);
            String productName3 = prod3 != null ? prod3.getProductName() : "";
            try {
                SimulationDao simDao3 = new SimulationDao();
                BigDecimal currentStock3 = simDao3.getStockForProduct3(productId3);
                Map<String, BigDecimal> supplyMap = simDao3.getSupplyMap(productId3, dateFrom, dateTo);
                Map<String, BigDecimal> demandMap = simDao3.getDemandMap(productId3, dateFrom, dateTo);

                // Build day-by-day simulation
                java.util.Date dFrom = sdf.parse(dateFrom);
                java.util.Date dTo = sdf.parse(dateTo);
                java.util.Calendar cal_sim = java.util.Calendar.getInstance();
                cal_sim.setTime(dFrom);

                BigDecimal runningStock = currentStock3;
                boolean hasShortfall = false;
    %>
    <div style="background:#fff;border:1px solid #ddd;border-radius:8px;padding:20px;">
        <h3 style="margin-top:0;">每日模擬：<%= productName3 %></h3>
        <p style="font-size:13px;color:#666;">期初庫存：<strong><%= NumberUtil.fmtQty(currentStock3.doubleValue()) %></strong> ｜ 模擬區間：<%= dateFrom %> ~ <%= dateTo %></p>
        <table class="sim-table">
            <tr>
                <th style="width:120px;">日期</th>
                <th style="width:100px;">期初庫存</th>
                <th style="width:110px;">完工入庫</th>
                <th style="width:110px;">訂單出貨</th>
                <th style="width:100px;">期末庫存</th>
                <th>狀態</th>
            </tr>
            <%
                while (!cal_sim.getTime().after(dTo)) {
                    String dateKey = sdf.format(cal_sim.getTime());
                    BigDecimal supply = supplyMap.getOrDefault(dateKey, BigDecimal.ZERO);
                    BigDecimal demand = demandMap.getOrDefault(dateKey, BigDecimal.ZERO);
                    BigDecimal opening = runningStock;
                    BigDecimal closing = opening.add(supply).subtract(demand);
                    String statusClass = "";
                    String statusLabel = "";
                    if (closing.compareTo(BigDecimal.ZERO) < 0) {
                        statusClass = "risk-high";
                        statusLabel = "⚠ 短缺 " + closing.abs();
                        hasShortfall = true;
                    } else if (closing.compareTo(BigDecimal.ZERO) == 0) {
                        statusClass = "risk-mid";
                        statusLabel = "⚡ 剛好用完";
                    } else {
                        statusLabel = "✅ 充足";
                    }
                    if (supply.compareTo(BigDecimal.ZERO) > 0 || demand.compareTo(BigDecimal.ZERO) > 0 || closing.compareTo(runningStock) != 0) {
            %>
            <tr class="<%= statusClass %>">
                <td><%= dateKey %></td>
                <td><%= NumberUtil.fmtQty(opening.doubleValue()) %></td>
                <td style="color:#2e7d32;"><%= supply.compareTo(BigDecimal.ZERO) > 0 ? "+" + NumberUtil.fmtQty(supply.doubleValue()) : "-" %></td>
                <td style="color:#c62828;"><%= demand.compareTo(BigDecimal.ZERO) > 0 ? "-" + NumberUtil.fmtQty(demand.doubleValue()) : "-" %></td>
                <td><%= NumberUtil.fmtQty(closing.doubleValue()) %></td>
                <td><%= statusLabel %></td>
            </tr>
            <%
                    }
                    runningStock = closing;
                    cal_sim.add(java.util.Calendar.DAY_OF_MONTH, 1);
                }
            %>
        </table>
        <% if (hasShortfall) { %>
            <div style="margin-top:16px;padding:12px;background:#ffebee;border-radius:8px;color:#c62828;font-weight:bold;text-align:center;">
                ❌ 模擬期間內將發生庫存不足！請檢視生產排程或調整交期。
            </div>
        <% } else { %>
            <div style="margin-top:16px;padding:12px;background:#e8f5e9;border-radius:8px;color:#2e7d32;font-weight:bold;text-align:center;">
                ✅ 模擬期間內庫存充足，可滿足訂單需求。
            </div>
        <% } %>
    </div>
    <%
            } catch (Exception e) { out.println("<div class='error-msg'>" + e.getMessage() + "</div>"); e.printStackTrace(); }
        }
    %>

<% } %>
</div>
<%@ include file="../include/footer.jsp" %>
