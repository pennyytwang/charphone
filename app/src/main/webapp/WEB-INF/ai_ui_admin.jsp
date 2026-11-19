<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="model.AiUiConfig" %>
<%@ page import="model.AiUiTab" %>
<%@ page import="util.HtmlUtil" %>
<%
    AiUiConfig aiUi = (AiUiConfig) request.getAttribute("aiUi");
    if (aiUi == null) aiUi = AiUiConfig.defaults();
    @SuppressWarnings("unchecked")
    List<String> errors = (List<String>) request.getAttribute("errors");
    String message = request.getParameter("message");
    String csrf = (String) session.getAttribute("csrfToken");
    List<AiUiTab> tabs = new ArrayList<>(aiUi.getTabs());
    if (tabs.isEmpty()) {
        tabs.add(new AiUiTab("", "", "_self", "", 0, true));
    }
%>
<% request.setAttribute("pageTitle", "企業AI 頁面內容"); %>
<% request.setAttribute("pageIcon", "✦"); %>
<% request.setAttribute("pageSubtitle", "AI 管理"); %>
<%@ include file="/include/header.jsp" %>
<style>
    .ai-ui-admin { max-width: 1180px; margin: 0 auto; }
    .ai-ui-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 16px; }
    .ai-ui-head h2 { margin: 0 0 6px; font-size: 22px; color: #1a1a2e; }
    .ai-ui-head p { margin: 0; font-size: 13px; color: #6c757d; line-height: 1.7; }
    .ai-ui-section { background: #fff; border-radius: 12px; padding: 20px 22px; margin-bottom: 16px; box-shadow: 0 1px 4px rgba(0,0,0,0.06); }
    .ai-ui-section h3 { margin: 0 0 4px; font-size: 16px; color: #1a1a2e; }
    .ai-ui-section .section-desc { margin: 0 0 16px; font-size: 12px; color: #6c757d; }
    .field-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px 18px; }
    .field-grid .full { grid-column: 1 / -1; }
    .field label { display: block; margin-bottom: 5px; font-size: 12px; font-weight: 700; color: #495057; }
    .field input[type=text], .field input[type=number], .field select, .field textarea {
        width: 100%; padding: 9px 11px; border: 1.5px solid #e0e3e8; border-radius: 8px;
        font-family: inherit; font-size: 13px; color: #1a1a2e; background: #fff; outline: none;
    }
    .field textarea { min-height: 76px; resize: vertical; line-height: 1.6; }
    .field input:focus, .field select:focus, .field textarea:focus { border-color: #4361ee; box-shadow: 0 0 0 3px rgba(67,97,238,0.10); }
    .field .hint { margin-top: 4px; font-size: 11px; color: #8a94a6; }
    .color-row { display: flex; align-items: center; gap: 8px; }
    .color-row input[type=text] { flex: 1; }
    .color-row input[type=color] { width: 42px; height: 37px; padding: 2px; border: 1.5px solid #e0e3e8; border-radius: 8px; background: #fff; cursor: pointer; }
    .tab-table { width: 100%; border-collapse: collapse; }
    .tab-table th, .tab-table td { padding: 8px 6px; border-bottom: 1px solid #eef1f5; text-align: left; vertical-align: middle; }
    .tab-table th { font-size: 11px; color: #6c757d; font-weight: 700; white-space: nowrap; }
    .tab-table input, .tab-table select { width: 100%; padding: 8px 9px; border: 1.5px solid #e0e3e8; border-radius: 7px; font-family: inherit; font-size: 12px; }
    .tab-table .tab-actions { white-space: nowrap; width: 120px; }
    .icon-btn { border: 1px solid #dbe1e8; background: #f8fafc; border-radius: 6px; padding: 4px 7px; cursor: pointer; color: #495057; font-size: 12px; }
    .icon-btn:hover { border-color: #4361ee; color: #4361ee; }
    .icon-btn.danger:hover { border-color: #dc3545; color: #dc3545; }
    .ai-ui-actions { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; margin-top: 18px; }
    .alert { border-radius: 10px; padding: 12px 14px; margin-bottom: 14px; font-size: 13px; line-height: 1.6; }
    .alert.error { background: #fff5f5; border: 1px solid #ffd6d6; color: #b42318; }
    .alert.success { background: #f0fdf4; border: 1px solid #bbf7d0; color: #166534; }
    .alert ul { margin: 0; padding-left: 20px; }
    .preview-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
    .preview-item { border: 1px solid #e9ecef; border-radius: 10px; padding: 12px; background: #f8f9fc; }
    .preview-item .preview-label { font-size: 11px; color: #6c757d; margin-bottom: 8px; font-weight: 700; }
    .hero-preview { border-radius: 10px; padding: 20px 24px; color: #fff; overflow: hidden; }
    .hero-preview h3 { margin: 0 0 6px; font-size: 18px; }
    .hero-preview p { margin: 0; font-size: 12px; opacity: 0.9; line-height: 1.6; }
    .hero-preview .preview-badge { display: inline-block; margin-top: 8px; padding: 3px 8px; border-radius: 999px; background: rgba(255,255,255,0.18); font-size: 10px; font-weight: 700; }
    .inline-actions { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
    @media (max-width: 900px) {
        .field-grid, .preview-grid { grid-template-columns: 1fr; }
        .ai-ui-head { flex-direction: column; }
        .tab-table { display: block; overflow-x: auto; }
    }
</style>

<div class="ai-ui-admin">
    <div class="ai-ui-head">
        <div>
            <h2>企業AI 頁面內容</h2>
            <p>管理「企業AI」與「AI 知識庫」頁面的標題、描述、頁籤、歡迎詞、輸入提示與 Hero 樣式。儲存後重新整理頁面即可看到。</p>
        </div>
        <a class="btn btn-outline" href="AiAdminServlet/">返回 AI 管理</a>
    </div>

    <% if (message != null && !message.isBlank()) { %>
    <div class="alert success"><%= HtmlUtil.escape(message) %></div>
    <% } %>

    <% if (errors != null && !errors.isEmpty()) { %>
    <div class="alert error">
        <ul>
            <% for (String error : errors) { %>
            <li><%= HtmlUtil.escape(error) %></li>
            <% } %>
        </ul>
    </div>
    <% } %>

    <form method="post" action="AiUiAdminServlet" id="aiUiForm">
        <input type="hidden" name="_csrf" value="<%= HtmlUtil.escape(csrf) %>">
        <input type="hidden" name="action" value="save">

        <div class="ai-ui-section">
            <h3>共用設定</h3>
            <p class="section-desc">兩個 AI 頁面共用。</p>
            <div class="field-grid">
                <div class="field">
                    <label for="pageWidth">頁面最大寬度</label>
                    <select id="pageWidth" name="pageWidth">
                        <option value="narrow" <%= "narrow".equals(aiUi.getPageWidth()) ? "selected" : "" %>>窄（900px）</option>
                        <option value="standard" <%= "standard".equals(aiUi.getPageWidth()) ? "selected" : "" %>>標準（1120px）</option>
                        <option value="wide" <%= "wide".equals(aiUi.getPageWidth()) ? "selected" : "" %>>寬（1320px）</option>
                    </select>
                </div>
            </div>
        </div>

        <div class="ai-ui-section">
            <h3>頁籤</h3>
            <p class="section-desc">頁籤會同時顯示在兩個 AI 頁面。連結只允許站內相對路徑；至少保留一個頁籤，最多 10 個。</p>
            <table class="tab-table">
                <thead>
                <tr>
                    <th>名稱</th>
                    <th>連結</th>
                    <th>開法</th>
                    <th>對應頁面</th>
                    <th>顯示</th>
                    <th>操作</th>
                </tr>
                </thead>
                <tbody id="tabRows">
                <% for (AiUiTab tab : tabs) { %>
                <tr class="tab-row">
                    <td><input type="text" name="tabLabel" value="<%= HtmlUtil.escape(tab.getLabel()) %>" maxlength="80" placeholder="企業AI"></td>
                    <td><input type="text" name="tabHref" value="<%= HtmlUtil.escape(tab.getHref()) %>" maxlength="255" placeholder="ai.jsp"></td>
                    <td>
                        <select name="tabTarget">
                            <option value="_self" <%= "_self".equals(tab.getTarget()) ? "selected" : "" %>>同頁</option>
                            <option value="_blank" <%= "_blank".equals(tab.getTarget()) ? "selected" : "" %>>另開</option>
                        </select>
                    </td>
                    <td>
                        <select name="tabActiveKey">
                            <option value="" <%= tab.getActiveKey() == null || tab.getActiveKey().isBlank() ? "selected" : "" %>>無</option>
                            <option value="enterprise" <%= "enterprise".equals(tab.getActiveKey()) ? "selected" : "" %>>企業AI</option>
                            <option value="knowledge" <%= "knowledge".equals(tab.getActiveKey()) ? "selected" : "" %>>AI 知識庫</option>
                        </select>
                    </td>
                    <td>
                        <select name="tabVisible">
                            <option value="1" <%= tab.isVisible() ? "selected" : "" %>>顯示</option>
                            <option value="0" <%= !tab.isVisible() ? "selected" : "" %>>隱藏</option>
                        </select>
                    </td>
                    <td class="tab-actions">
                        <button type="button" class="icon-btn" onclick="moveTabRow(this, -1)" title="上移">↑</button>
                        <button type="button" class="icon-btn" onclick="moveTabRow(this, 1)" title="下移">↓</button>
                        <button type="button" class="icon-btn danger" onclick="removeTabRow(this)" title="刪除">刪除</button>
                    </td>
                </tr>
                <% } %>
                </tbody>
            </table>
            <div class="ai-ui-actions">
                <button type="button" class="btn btn-outline" onclick="addTabRow()">新增頁籤</button>
            </div>
        </div>

        <div class="ai-ui-section">
            <h3>企業AI</h3>
            <p class="section-desc">企業AI 頁面的 Hero、對話卡與快速測試區塊。</p>
            <div class="field-grid">
                <div class="field">
                    <label for="enterpriseTitle">頁面標題</label>
                    <input type="text" id="enterpriseTitle" name="enterpriseTitle" value="<%= HtmlUtil.escape(aiUi.getEnterpriseTitle()) %>" maxlength="100" required>
                </div>
                <div class="field">
                    <label for="enterpriseHeroBadge">Hero 標籤</label>
                    <input type="text" id="enterpriseHeroBadge" name="enterpriseHeroBadge" value="<%= HtmlUtil.escape(aiUi.getEnterpriseHeroBadge()) %>" maxlength="80">
                </div>
                <div class="field full">
                    <label for="enterpriseHeroDescription">Hero 描述</label>
                    <textarea id="enterpriseHeroDescription" name="enterpriseHeroDescription" maxlength="2000"><%= HtmlUtil.escape(aiUi.getEnterpriseHeroDescription()) %></textarea>
                </div>
                <div class="field">
                    <label>Hero 起始色</label>
                    <div class="color-row">
                        <input type="text" name="enterpriseHeroFrom" id="enterpriseHeroFrom" value="<%= HtmlUtil.escape(aiUi.getEnterpriseHeroFrom()) %>" maxlength="7" pattern="#[0-9a-fA-F]{6}">
                        <input type="color" value="<%= HtmlUtil.escape(aiUi.getEnterpriseHeroFrom()) %>" data-color-for="enterpriseHeroFrom" aria-label="企業AI Hero 起始色">
                    </div>
                </div>
                <div class="field">
                    <label>Hero 結束色</label>
                    <div class="color-row">
                        <input type="text" name="enterpriseHeroTo" id="enterpriseHeroTo" value="<%= HtmlUtil.escape(aiUi.getEnterpriseHeroTo()) %>" maxlength="7" pattern="#[0-9a-fA-F]{6}">
                        <input type="color" value="<%= HtmlUtil.escape(aiUi.getEnterpriseHeroTo()) %>" data-color-for="enterpriseHeroTo" aria-label="企業AI Hero 結束色">
                    </div>
                </div>
                <div class="field">
                    <label>Hero 文字色</label>
                    <div class="color-row">
                        <input type="text" name="enterpriseHeroText" id="enterpriseHeroText" value="<%= HtmlUtil.escape(aiUi.getEnterpriseHeroText()) %>" maxlength="7" pattern="#[0-9a-fA-F]{6}">
                        <input type="color" value="<%= HtmlUtil.escape(aiUi.getEnterpriseHeroText()) %>" data-color-for="enterpriseHeroText" aria-label="企業AI Hero 文字色">
                    </div>
                </div>
                <div class="field">
                    <label for="enterpriseHeroSize">Hero 大小</label>
                    <select id="enterpriseHeroSize" name="enterpriseHeroSize">
                        <option value="compact" <%= "compact".equals(aiUi.getEnterpriseHeroSize()) ? "selected" : "" %>>精簡</option>
                        <option value="standard" <%= "standard".equals(aiUi.getEnterpriseHeroSize()) ? "selected" : "" %>>標準</option>
                        <option value="large" <%= "large".equals(aiUi.getEnterpriseHeroSize()) ? "selected" : "" %>>大</option>
                    </select>
                </div>
                <div class="field">
                    <label for="enterpriseChatTitle">對話卡標題</label>
                    <input type="text" id="enterpriseChatTitle" name="enterpriseChatTitle" value="<%= HtmlUtil.escape(aiUi.getEnterpriseChatTitle()) %>" maxlength="100">
                </div>
                <div class="field">
                    <label for="enterpriseChatBadge">對話卡 badge</label>
                    <input type="text" id="enterpriseChatBadge" name="enterpriseChatBadge" value="<%= HtmlUtil.escape(aiUi.getEnterpriseChatBadge()) %>" maxlength="80">
                </div>
                <div class="field full">
                    <label for="enterpriseChatHint">對話卡提示</label>
                    <textarea id="enterpriseChatHint" name="enterpriseChatHint" maxlength="1000"><%= HtmlUtil.escape(aiUi.getEnterpriseChatHint()) %></textarea>
                </div>
                <div class="field full">
                    <label for="enterpriseWelcome">預設歡迎詞</label>
                    <textarea id="enterpriseWelcome" name="enterpriseWelcome" maxlength="2000"><%= HtmlUtil.escape(aiUi.getEnterpriseWelcome()) %></textarea>
                </div>
                <div class="field">
                    <label for="enterprisePlaceholder">輸入框 placeholder</label>
                    <input type="text" id="enterprisePlaceholder" name="enterprisePlaceholder" value="<%= HtmlUtil.escape(aiUi.getEnterprisePlaceholder()) %>" maxlength="300">
                </div>
                <div class="field">
                    <label for="enterpriseSendButton">送出按鈕文字</label>
                    <input type="text" id="enterpriseSendButton" name="enterpriseSendButton" value="<%= HtmlUtil.escape(aiUi.getEnterpriseSendButton()) %>" maxlength="30">
                </div>
                <div class="field">
                    <label for="enterprisePresetTitle">快速測試標題</label>
                    <input type="text" id="enterprisePresetTitle" name="enterprisePresetTitle" value="<%= HtmlUtil.escape(aiUi.getEnterprisePresetTitle()) %>" maxlength="100">
                </div>
                <div class="field">
                    <label for="enterprisePresetBadge">快速測試 badge</label>
                    <input type="text" id="enterprisePresetBadge" name="enterprisePresetBadge" value="<%= HtmlUtil.escape(aiUi.getEnterprisePresetBadge()) %>" maxlength="80">
                </div>
                <div class="field full">
                    <label for="enterprisePresetHint">快速測試提示</label>
                    <textarea id="enterprisePresetHint" name="enterprisePresetHint" maxlength="1000"><%= HtmlUtil.escape(aiUi.getEnterprisePresetHint()) %></textarea>
                </div>
                <div class="field full">
                    <label for="enterpriseReadonlyNotice">唯讀提示</label>
                    <textarea id="enterpriseReadonlyNotice" name="enterpriseReadonlyNotice" maxlength="1000"><%= HtmlUtil.escape(aiUi.getEnterpriseReadonlyNotice()) %></textarea>
                </div>
            </div>
        </div>

        <div class="ai-ui-section">
            <h3>AI 知識庫</h3>
            <p class="section-desc">AI 知識庫頁面的 Hero 與知識庫問答卡片。</p>
            <div class="field-grid">
                <div class="field">
                    <label for="knowledgeTitle">頁面標題</label>
                    <input type="text" id="knowledgeTitle" name="knowledgeTitle" value="<%= HtmlUtil.escape(aiUi.getKnowledgeTitle()) %>" maxlength="100" required>
                </div>
                <div class="field">
                    <label for="knowledgeHeroBadge">Hero 標籤</label>
                    <input type="text" id="knowledgeHeroBadge" name="knowledgeHeroBadge" value="<%= HtmlUtil.escape(aiUi.getKnowledgeHeroBadge()) %>" maxlength="80">
                </div>
                <div class="field full">
                    <label for="knowledgeHeroDescription">Hero 描述</label>
                    <textarea id="knowledgeHeroDescription" name="knowledgeHeroDescription" maxlength="2000"><%= HtmlUtil.escape(aiUi.getKnowledgeHeroDescription()) %></textarea>
                </div>
                <div class="field">
                    <label>Hero 起始色</label>
                    <div class="color-row">
                        <input type="text" name="knowledgeHeroFrom" id="knowledgeHeroFrom" value="<%= HtmlUtil.escape(aiUi.getKnowledgeHeroFrom()) %>" maxlength="7" pattern="#[0-9a-fA-F]{6}">
                        <input type="color" value="<%= HtmlUtil.escape(aiUi.getKnowledgeHeroFrom()) %>" data-color-for="knowledgeHeroFrom" aria-label="AI 知識庫 Hero 起始色">
                    </div>
                </div>
                <div class="field">
                    <label>Hero 結束色</label>
                    <div class="color-row">
                        <input type="text" name="knowledgeHeroTo" id="knowledgeHeroTo" value="<%= HtmlUtil.escape(aiUi.getKnowledgeHeroTo()) %>" maxlength="7" pattern="#[0-9a-fA-F]{6}">
                        <input type="color" value="<%= HtmlUtil.escape(aiUi.getKnowledgeHeroTo()) %>" data-color-for="knowledgeHeroTo" aria-label="AI 知識庫 Hero 結束色">
                    </div>
                </div>
                <div class="field">
                    <label>Hero 文字色</label>
                    <div class="color-row">
                        <input type="text" name="knowledgeHeroText" id="knowledgeHeroText" value="<%= HtmlUtil.escape(aiUi.getKnowledgeHeroText()) %>" maxlength="7" pattern="#[0-9a-fA-F]{6}">
                        <input type="color" value="<%= HtmlUtil.escape(aiUi.getKnowledgeHeroText()) %>" data-color-for="knowledgeHeroText" aria-label="AI 知識庫 Hero 文字色">
                    </div>
                </div>
                <div class="field">
                    <label for="knowledgeHeroSize">Hero 大小</label>
                    <select id="knowledgeHeroSize" name="knowledgeHeroSize">
                        <option value="compact" <%= "compact".equals(aiUi.getKnowledgeHeroSize()) ? "selected" : "" %>>精簡</option>
                        <option value="standard" <%= "standard".equals(aiUi.getKnowledgeHeroSize()) ? "selected" : "" %>>標準</option>
                        <option value="large" <%= "large".equals(aiUi.getKnowledgeHeroSize()) ? "selected" : "" %>>大</option>
                    </select>
                </div>
                <div class="field">
                    <label for="knowledgeCardTitle">知識庫問答卡標題</label>
                    <input type="text" id="knowledgeCardTitle" name="knowledgeCardTitle" value="<%= HtmlUtil.escape(aiUi.getKnowledgeCardTitle()) %>" maxlength="100">
                </div>
                <div class="field">
                    <label for="knowledgeCardBadge">知識庫問答卡 badge</label>
                    <input type="text" id="knowledgeCardBadge" name="knowledgeCardBadge" value="<%= HtmlUtil.escape(aiUi.getKnowledgeCardBadge()) %>" maxlength="80">
                </div>
                <div class="field full">
                    <label for="knowledgeCardHint">知識庫問答卡提示</label>
                    <textarea id="knowledgeCardHint" name="knowledgeCardHint" maxlength="1000"><%= HtmlUtil.escape(aiUi.getKnowledgeCardHint()) %></textarea>
                </div>
                <div class="field full">
                    <label for="knowledgeWelcome">預設歡迎詞</label>
                    <textarea id="knowledgeWelcome" name="knowledgeWelcome" maxlength="2000"><%= HtmlUtil.escape(aiUi.getKnowledgeWelcome()) %></textarea>
                </div>
                <div class="field">
                    <label for="knowledgePlaceholder">輸入框 placeholder</label>
                    <input type="text" id="knowledgePlaceholder" name="knowledgePlaceholder" value="<%= HtmlUtil.escape(aiUi.getKnowledgePlaceholder()) %>" maxlength="300">
                </div>
                <div class="field">
                    <label for="knowledgeSendButton">送出按鈕文字</label>
                    <input type="text" id="knowledgeSendButton" name="knowledgeSendButton" value="<%= HtmlUtil.escape(aiUi.getKnowledgeSendButton()) %>" maxlength="30">
                </div>
                <div class="field">
                    <label for="knowledgeViewAction">查看內容按鈕</label>
                    <input type="text" id="knowledgeViewAction" name="knowledgeViewAction" value="<%= HtmlUtil.escape(aiUi.getKnowledgeViewAction()) %>" maxlength="30">
                </div>
                <div class="field">
                    <label for="knowledgeDownloadAction">文件下載按鈕</label>
                    <input type="text" id="knowledgeDownloadAction" name="knowledgeDownloadAction" value="<%= HtmlUtil.escape(aiUi.getKnowledgeDownloadAction()) %>" maxlength="30">
                </div>
                <div class="field full">
                    <label for="knowledgeReadonlyNotice">唯讀提示</label>
                    <textarea id="knowledgeReadonlyNotice" name="knowledgeReadonlyNotice" maxlength="1000"><%= HtmlUtil.escape(aiUi.getKnowledgeReadonlyNotice()) %></textarea>
                </div>
            </div>
        </div>

        <div class="ai-ui-section">
            <h3>即時預覽</h3>
            <p class="section-desc">預覽只顯示 Hero 區塊；實際頁面會套用完整版面。</p>
            <div class="preview-grid">
                <div class="preview-item">
                    <div class="preview-label">企業AI</div>
                    <div class="hero-preview" id="enterprisePreview">
                        <h3 id="enterprisePreviewTitle"></h3>
                        <p id="enterprisePreviewDesc"></p>
                        <span class="preview-badge" id="enterprisePreviewBadge"></span>
                    </div>
                </div>
                <div class="preview-item">
                    <div class="preview-label">AI 知識庫</div>
                    <div class="hero-preview" id="knowledgePreview">
                        <h3 id="knowledgePreviewTitle"></h3>
                        <p id="knowledgePreviewDesc"></p>
                        <span class="preview-badge" id="knowledgePreviewBadge"></span>
                    </div>
                </div>
            </div>
        </div>

        <div class="ai-ui-actions">
            <button type="submit" class="btn btn-primary">儲存設定</button>
            <a class="btn btn-outline" href="ai.jsp" target="_blank" rel="noopener">開啟企業AI</a>
            <a class="btn btn-outline" href="ai_knowledge.jsp" target="_blank" rel="noopener">開啟 AI 知識庫</a>
        </div>
    </form>

    <form method="post" action="AiUiAdminServlet" onsubmit="return confirm('確定要刪除所有自訂內容並回復預設值嗎？');">
        <input type="hidden" name="_csrf" value="<%= HtmlUtil.escape(csrf) %>">
        <input type="hidden" name="action" value="reset">
        <div class="ai-ui-actions">
            <button type="submit" class="btn btn-outline" style="border-color:#f0b4b4;color:#b42318;">回復預設</button>
        </div>
    </form>

    <template id="tabRowTemplate">
        <tr class="tab-row">
            <td><input type="text" name="tabLabel" maxlength="80" placeholder="新頁籤"></td>
            <td><input type="text" name="tabHref" maxlength="255" placeholder="ai.jsp"></td>
            <td>
                <select name="tabTarget">
                    <option value="_self">同頁</option>
                    <option value="_blank">另開</option>
                </select>
            </td>
            <td>
                <select name="tabActiveKey">
                    <option value="">無</option>
                    <option value="enterprise">企業AI</option>
                    <option value="knowledge">AI 知識庫</option>
                </select>
            </td>
            <td>
                <select name="tabVisible">
                    <option value="1">顯示</option>
                    <option value="0">隱藏</option>
                </select>
            </td>
            <td class="tab-actions">
                <button type="button" class="icon-btn" onclick="moveTabRow(this, -1)" title="上移">↑</button>
                <button type="button" class="icon-btn" onclick="moveTabRow(this, 1)" title="下移">↓</button>
                <button type="button" class="icon-btn danger" onclick="removeTabRow(this)" title="刪除">刪除</button>
            </td>
        </tr>
    </template>
</div>

<script>
(function () {
    var MAX_TABS = 10;
    var rows = document.getElementById('tabRows');
    var template = document.getElementById('tabRowTemplate');

    window.addTabRow = function () {
        if (rows.querySelectorAll('.tab-row').length >= MAX_TABS) {
            alert('頁籤最多 ' + MAX_TABS + ' 個');
            return;
        }
        rows.appendChild(template.content.cloneNode(true));
    };

    window.removeTabRow = function (button) {
        if (rows.querySelectorAll('.tab-row').length <= 1) {
            alert('請至少保留一個頁籤');
            return;
        }
        button.closest('.tab-row').remove();
    };

    window.moveTabRow = function (button, direction) {
        var row = button.closest('.tab-row');
        if (!row) {
            return;
        }
        if (direction < 0 && row.previousElementSibling) {
            rows.insertBefore(row, row.previousElementSibling);
        } else if (direction > 0 && row.nextElementSibling) {
            rows.insertBefore(row.nextElementSibling, row);
        }
    };

    function bindColorPickers() {
        document.querySelectorAll('input[type=color][data-color-for]').forEach(function (picker) {
            var text = document.getElementById(picker.getAttribute('data-color-for'));
            if (!text) {
                return;
            }
            picker.value = text.value || picker.value;
            picker.addEventListener('input', function () {
                text.value = picker.value;
                updatePreviewFromInputs();
            });
            text.addEventListener('input', function () {
                if (/^#[0-9a-fA-F]{6}$/.test(text.value)) {
                    picker.value = text.value;
                }
                updatePreviewFromInputs();
            });
        });
    }

    function sizePadding(size) {
        return size === 'compact' ? '14px 18px' : (size === 'large' ? '26px 30px' : '20px 24px');
    }

    function sizeTitle(size) {
        return size === 'compact' ? '16px' : (size === 'large' ? '22px' : '18px');
    }

    function updatePreview(prefix) {
        var title = document.getElementById(prefix + 'Title');
        var desc = document.getElementById(prefix + 'HeroDescription');
        var badge = document.getElementById(prefix + 'HeroBadge');
        var from = document.getElementById(prefix + 'HeroFrom');
        var to = document.getElementById(prefix + 'HeroTo');
        var color = document.getElementById(prefix + 'HeroText');
        var size = document.getElementById(prefix + 'HeroSize');
        var preview = document.getElementById(prefix + 'Preview');
        if (!preview || !from || !to || !color || !size) {
            return;
        }
        preview.style.background = 'linear-gradient(135deg, ' + (from.value || '#4361ee') + ' 0%, ' + (to.value || '#7c4dff') + ' 100%)';
        preview.style.color = color.value || '#ffffff';
        preview.style.padding = sizePadding(size.value);
        var titleEl = document.getElementById(prefix + 'PreviewTitle');
        var descEl = document.getElementById(prefix + 'PreviewDesc');
        var badgeEl = document.getElementById(prefix + 'PreviewBadge');
        titleEl.textContent = title ? title.value : '';
        titleEl.style.fontSize = sizeTitle(size.value);
        descEl.textContent = desc ? desc.value : '';
        badgeEl.textContent = badge ? badge.value : '';
        badgeEl.style.display = badge && badge.value.trim() ? 'inline-block' : 'none';
    }

    function updatePreviewFromInputs() {
        updatePreview('enterprise');
        updatePreview('knowledge');
    }

    document.querySelectorAll('#aiUiForm input, #aiUiForm textarea, #aiUiForm select').forEach(function (input) {
        input.addEventListener('input', updatePreviewFromInputs);
        input.addEventListener('change', updatePreviewFromInputs);
    });

    bindColorPickers();
    updatePreviewFromInputs();
})();
</script>
<%@ include file="/include/footer.jsp" %>
