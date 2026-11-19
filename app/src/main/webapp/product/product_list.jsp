<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, dao.ProductDao, model.Product, util.NumberUtil" %>
<% request.setAttribute("pageTitle", "品項管理"); %>
<% request.setAttribute("pageIcon", "★"); %>
<% request.setAttribute("pageSubtitle", "產品品項與計價設定"); %>
<%@ include file="../include/header.jsp" %>
<%@ taglib prefix="my" tagdir="/WEB-INF/tags" %>

<%
    String contextPath = request.getContextPath();
    String keyword = request.getParameter("keyword");
    String msg = request.getParameter("message");

    int pageNum = 1;
    int pageSize = 20;
    String pageParam = request.getParameter("page");
    if (pageParam != null) {
        try { pageNum = Integer.parseInt(pageParam); if (pageNum < 1) pageNum = 1; } catch (NumberFormatException e) {}
    }
    int startIdx = (pageNum - 1) * pageSize;
    int totalPages = 1;
    int filteredIdx = 0;
    int displayed = 0;
    String baseUrl = "product_list.jsp?submitted=1"
        + (keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword.trim(), java.nio.charset.StandardCharsets.UTF_8) : "");
%>

<div id="successMsg" class="alert alert-success" style="display:<%= "success".equals(msg) ? "block" : "none" %>">品項資料已儲存！</div>

<form class="filter-bar" method="GET">
    <div class="field">
        <label>關鍵字</label>
        <input type="text" name="keyword" value="<%= keyword != null ? keyword : "" %>" placeholder="品項名稱/編號">
    </div>
    <button type="submit" class="btn-search">查詢</button>
    <a href="product_list.jsp" class="btn-clear">清除</a>
</form>

<div style="display:flex;justify-content:flex-end;margin-bottom:16px;">
    <button onclick="openAddModal()" class="btn btn-primary">+ 新增品項</button>
</div>

<div class="table-container" style="display:flex;flex-direction:column;padding:0;">
<table style="order:2;width:100%;">
    <thead>
        <tr>
            <th>序號</th>
            <th>編號</th>
            <th>產品編號</th>
            <th>產品名稱</th>
            <th>計價方式</th>
            <th>單個重量(kg)</th>
            <th>代工單價</th>
            <th>備註</th>
            <th>操作</th>
        </tr>
    </thead>
    <tbody>
        <%
            totalPages = 1;
            filteredIdx = 0;
            displayed = 0;

            ProductDao productDao = new ProductDao();
            List<Product> products = productDao.getFilteredProducts(keyword);
            boolean hasData = false;
            for (Product p : products) {
                    hasData = true;

                    filteredIdx++;
                    if (filteredIdx <= startIdx) continue;
                    if (displayed >= pageSize) continue;
                    displayed++;
        %>
                    <tr>
                        <td><%= filteredIdx %></td>
                        <td><%= p.getId() %></td>
                        <td><%= p.getProductCode() != null ? p.getProductCode() : "-" %></td>
                        <td><b><%= p.getProductName() %></b></td>
                        <td><%= p.getPriceType() == 1 ? "按重量" : "按個數" %></td>
                        <td><%= p.getUnitWeight() != null ? NumberUtil.fmtQty(p.getUnitWeight().doubleValue()) : "-" %></td>
                        <td><%= p.getUnitPrice() != null ? NumberUtil.fmtMoney(p.getUnitPrice()) : "-" %></td>
                        <td><%= p.getDescription() != null ? p.getDescription() : "-" %></td>
                        <td>
                            <button onclick="openEditModal(<%= p.getId() %>)" class="btn btn-primary btn-sm">編輯</button>
                        </td>
                    </tr>
        <% 
            }
            if (!hasData) {
        %>
                    <tr>
                        <td colspan="9">
                            <div class="empty-state">
                                <p>尚無品項資料</p>
                            </div>
                        </td>
                    </tr>
            <%
            }
            totalPages = filteredIdx > 0 ? (int) Math.ceil((double) filteredIdx / pageSize) : 1;
            if (pageNum > totalPages) pageNum = totalPages;
        %>
    </tbody>
</table>
<div style="order:1;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= totalPages %>" totalCount="<%= filteredIdx %>" baseUrl="<%= baseUrl %>" position="top"/></div>
<div style="order:3;"><my:pagination pageNum="<%= pageNum %>" totalPages="<%= totalPages %>" totalCount="<%= filteredIdx %>" baseUrl="<%= baseUrl %>"/></div>
</div>

<script>
var CTX = '<%= contextPath %>';

var formHTML = '<form id="productForm" onsubmit="return false;">'
    + '<input type="hidden" id="productId" name="id">'
    + '<div class="form-group"><label>產品編號：</label><input type="text" id="productCode" name="productCode" placeholder="例如: P-001"></div>'
    + '<div class="form-group"><label>產品名稱：</label><input type="text" id="productName" name="productName" placeholder="例如: 法蘭盤" required></div>'
    + '<div class="form-group"><label>計價方式：</label><select id="priceType" name="priceType"><option value="2">按個數 (pcs)</option><option value="1">按重量 (kg)</option></select></div>'
    + '<div class="form-group"><label>單個重量 (kg)：</label><input type="number" id="unitWeight" name="unitWeight" step="any" placeholder="例如: 1.500"></div>'
    + '<div class="form-group"><label>代工單價：</label><input type="number" id="unitPrice" name="unitPrice" step="any" placeholder="例如: 50.00"></div>'
    + '<div class="form-group"><label>備註：</label><textarea id="description" name="description" rows="3" placeholder="廠內備註事項..."></textarea></div>'
    + '<button type="button" class="btn-submit" onclick="submitForm()" id="submitBtn">確認新增</button>'
    + '</form>';

var overlay = document.createElement('div');
overlay.style.cssText = 'display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(200,200,200,0.5);z-index:9999;';
overlay.className = 'modal-overlay';

var box = document.createElement('div');
box.style.cssText = 'position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);background:#fff;border-radius:12px;box-shadow:0 8px 32px rgba(0,0,0,0.15);padding:30px 35px 35px;width:500px;max-width:90vw;max-height:85vh;overflow-y:auto;';
box.className = 'modal-wrap';

var closeBtn = document.createElement('button');
closeBtn.className = 'modal-close';
closeBtn.textContent = '\u00D7';
closeBtn.onclick = closeModal;

var title = document.createElement('h3');
title.id = 'modalTitle';
title.textContent = '新增品項';
title.style.cssText = 'cursor:move;user-select:none;';

var errDiv = document.createElement('div');
errDiv.id = 'formError';
errDiv.className = 'error-msg';
errDiv.style.display = 'none';

// Resize handle
var resizer = document.createElement('div');
resizer.style.cssText = 'position:absolute;right:0;bottom:0;width:16px;height:16px;cursor:se-resize;background:linear-gradient(135deg,transparent 50%,#999 50%,#999 55%,transparent 55%)';

box.appendChild(closeBtn);
box.appendChild(title);
box.appendChild(errDiv);
box.insertAdjacentHTML('beforeend', formHTML);
box.appendChild(resizer);
overlay.appendChild(box);
document.body.appendChild(overlay);

// --- Draggable ---
var dragActive = false, dragStartX, dragStartY, dragOrigLeft, dragOrigTop;
title.addEventListener('mousedown', function(e) {
    if (e.button !== 0) return;
    var rect = box.getBoundingClientRect();
    box.style.left = rect.left + 'px';
    box.style.top = rect.top + 'px';
    box.style.transform = 'none';
    dragStartX = e.clientX;
    dragStartY = e.clientY;
    dragOrigLeft = rect.left;
    dragOrigTop = rect.top;
    dragActive = true;
    e.preventDefault();
});
document.addEventListener('mousemove', function(e) {
    if (!dragActive) return;
    box.style.left = (dragOrigLeft + e.clientX - dragStartX) + 'px';
    box.style.top = (dragOrigTop + e.clientY - dragStartY) + 'px';
});
document.addEventListener('mouseup', function() { dragActive = false; });

// --- Resizable ---
var resizeActive = false, resizeStartX, resizeStartY, resizeOrigW, resizeOrigH;
resizer.addEventListener('mousedown', function(e) {
    if (e.button !== 0) return;
    resizeStartX = e.clientX;
    resizeStartY = e.clientY;
    resizeOrigW = box.offsetWidth;
    resizeOrigH = box.offsetHeight;
    resizeActive = true;
    box.style.maxWidth = 'none';
    box.style.maxHeight = 'none';
    e.preventDefault();
    e.stopPropagation();
});
document.addEventListener('mousemove', function(e) {
    if (!resizeActive) return;
    var w = Math.max(300, resizeOrigW + e.clientX - resizeStartX);
    var h = Math.max(200, resizeOrigH + e.clientY - resizeStartY);
    box.style.width = w + 'px';
    box.style.height = h + 'px';
});
document.addEventListener('mouseup', function() { resizeActive = false; });

function openAddModal() {
    overlay.style.display = 'block';
    title.textContent = '新增品項';
    document.getElementById('productForm').reset();
    document.getElementById('productId').value = '';
    errDiv.style.display = 'none';
    document.getElementById('submitBtn').textContent = '確認新增';
}

function openEditModal(id) {
    overlay.style.display = 'block';
    title.textContent = '編輯品項';
    errDiv.style.display = 'none';
    document.getElementById('submitBtn').textContent = '儲存修改';
    document.getElementById('productForm').reset();

    fetch(CTX + '/ProductServlet?action=get&id=' + id)
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (data.success) {
                document.getElementById('productId').value = data.id;
                document.getElementById('productCode').value = data.productCode || '';
                document.getElementById('productName').value = data.productName;
                document.getElementById('priceType').value = data.priceType;
                document.getElementById('unitWeight').value = data.unitWeight;
                document.getElementById('unitPrice').value = data.unitPrice;
                document.getElementById('description').value = data.description;
            } else {
                showError(data.error || '載入失敗');
            }
        })
        .catch(function() {
            showError('系統錯誤，無法載入資料');
        });
}

function closeModal() {
    overlay.style.display = 'none';
}

function showError(msg) {
    errDiv.textContent = msg;
    errDiv.style.display = 'block';
}

function submitForm() {
    var form = document.getElementById('productForm');
    var formData = new FormData(form);

    document.getElementById('submitBtn').disabled = true;

    fetch(CTX + '/ProductServlet', {
        method: 'POST',
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        body: formData
    })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.success) {
            closeModal();
            var msgEl = document.getElementById('successMsg');
            msgEl.style.display = 'block';
            setTimeout(function() {
                window.location.href = 'product_list.jsp';
            }, 500);
        } else {
            showError(data.error || '操作失敗');
            document.getElementById('submitBtn').disabled = false;
        }
    })
    .catch(function() {
        showError('系統錯誤，請稍後再試');
        document.getElementById('submitBtn').disabled = false;
    });
}
</script>

<%@ include file="../include/footer.jsp" %>
