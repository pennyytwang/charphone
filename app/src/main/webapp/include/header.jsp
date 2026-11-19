<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="util.HtmlUtil" %>
<%
    String pgTitle = (String) request.getAttribute("pageTitle");
    if (pgTitle == null) pgTitle = "CharPhone";
    String pgIcon = (String) request.getAttribute("pageIcon");
    if (pgIcon == null) pgIcon = "▣";
    String pgSubtitle = (String) request.getAttribute("pageSubtitle");
    model.User headerUser = (model.User) session.getAttribute("user");
    Boolean headerReadOnlyAttr = (Boolean) session.getAttribute("readOnly");
    boolean headerReadOnly = headerReadOnlyAttr != null
            ? headerReadOnlyAttr
            : (headerUser != null && (headerUser.isReadOnly() || headerUser.isTemporary()));
    String headerCsrf = (String) session.getAttribute("csrfToken");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="<%= headerCsrf != null ? headerCsrf : "" %>">
    <title><%= HtmlUtil.escape(pgTitle) %> - CharPhone</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=20261112-ai-markdown">
    <script src="${pageContext.request.contextPath}/js/common.js"></script>
    <script>
    function fmtNum(n){var s=parseFloat(n).toFixed(3);s=s.replace(/\.?0+$/,'');return s;}
    function fmtMoney(n){var v=parseFloat(n)||0;var s=v.toFixed(2);if(s.indexOf('.')===-1)return v.toLocaleString('en-US');var p=s.split('.');var i=parseInt(p[0]);var d=p[1].replace(/0+$/,'').replace(/\.$/,'');return d?i.toLocaleString('en-US')+'.'+d:i.toLocaleString('en-US');}
    function parseNumber(s){return parseFloat(String(s).replace(/,/g,''))||0;}
    function fmtQtyDisplay(n){var num=parseFloat(n);if(isNaN(num))return'';var parts=num.toString().split('.');parts[0]=parts[0].replace(/\B(?=(\d{3})+(?!\d))/g,',');return parts.join('.');}
    function formatMoneyInput(el){
        var pos=el.selectionStart,oldLen=el.value.length;
        var raw=el.value.replace(/[^0-9.]/g,'');
        var parts=raw.split('.');
        if(parts.length>2)raw=parts[0]+'.'+parts.slice(1).join('');
        var intP=parts[0],decP=parts.length>1?'.'+parts[1]:'';
        el.value=intP.replace(/\B(?=(\d{3})+(?!\d))/g,',')+decP;
        var diff=el.value.length-oldLen;
        el.setSelectionRange(pos+diff,pos+diff);
    }
    </script>
</head>
<body class="<%= headerReadOnly ? "readonly-mode" : "" %>">
    <% if (headerReadOnly) { %>
    <div class="readonly-banner">唯讀展示模式：可瀏覽資料，但無法新增、修改或刪除；部分客戶個資已遮蔽。</div>
    <% } %>
    <div class="page-title-bar">
        <div class="page-title-main"><%= HtmlUtil.escape(pgTitle) %></div>
    </div>
