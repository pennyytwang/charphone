<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.User" %>
<%@ page import="model.AiUiConfig" %>
<%@ page import="model.AiUiTab" %>
<%@ page import="util.HtmlUtil" %>
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
    AiUiConfig aiUi = (AiUiConfig) request.getAttribute("aiUi");
    if (aiUi == null) aiUi = AiUiConfig.defaults();
    String pageKey = AiUiConfig.PAGE_KNOWLEDGE;
%>
<% request.setAttribute("pageTitle", aiUi.getKnowledgeTitle()); %>
<% request.setAttribute("pageIcon", "✦"); %>
<% request.setAttribute("pageSubtitle", "知識庫問答"); %>
<%@ include file="/include/header.jsp" %>
<style>
    .kb-shell { max-width: var(--ai-max-width, 1120px); margin: 0 auto; }
    .kb-hero {
        background: linear-gradient(135deg, var(--ai-hero-from, #0f766e) 0%, var(--ai-hero-to, #0ea5e9) 100%);
        border-radius: 12px;
        padding: var(--ai-hero-pad, 26px 30px);
        color: var(--ai-hero-color, #fff);
        margin-bottom: 18px;
        box-shadow: 0 8px 24px rgba(14,116,144,0.18);
    }
    .kb-hero h2 { margin: 0 0 6px; font-size: var(--ai-hero-title-size, 20px); }
    .kb-hero p { margin: 0; font-size: 13px; opacity: 0.9; line-height: 1.7; }
    .kb-hero .kb-mode {
        display: inline-block;
        margin-top: 12px;
        padding: 4px 10px;
        border-radius: 999px;
        background: rgba(255,255,255,0.16);
        font-size: 11px;
        font-weight: 700;
        letter-spacing: 0.4px;
    }
    .kb-card {
        background: #fff;
        border-radius: 12px;
        padding: 22px 24px;
        margin-bottom: 18px;
        box-shadow: 0 1px 4px rgba(0,0,0,0.06);
    }
    .kb-card-head {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        gap: 12px;
        margin-bottom: 14px;
    }
    .kb-card-title { font-size: 16px; font-weight: 700; color: #1a1a2e; }
    .kb-hint { margin-top: 4px; font-size: 12px; color: #6c757d; line-height: 1.6; }
    .kb-messages {
        min-height: 300px;
        max-height: 560px;
        overflow-y: auto;
        padding: 16px;
        border: 1px solid #e9ecef;
        border-radius: 10px;
        background: #f8f9fc;
    }
    .kb-msg { display: flex; gap: 10px; align-items: flex-start; margin-bottom: 14px; }
    .kb-msg:last-child { margin-bottom: 0; }
    .kb-msg.user { flex-direction: row-reverse; }
    .kb-avatar {
        flex: 0 0 30px;
        width: 30px;
        height: 30px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 11px;
        font-weight: 700;
        background: #e0f2fe;
        color: #0369a1;
    }
    .kb-msg.user .kb-avatar { background: #0f766e; color: #fff; }
    .kb-bubble {
        max-width: min(800px, 84%);
        padding: 11px 14px;
        border-radius: 12px;
        background: #fff;
        border: 1px solid #e9ecef;
        color: #1a1a2e;
        font-size: 14px;
        line-height: 1.75;
        white-space: pre-wrap;
        word-break: break-word;
    }
    .kb-msg.user .kb-bubble {
        background: #0f766e;
        border-color: #0f766e;
        color: #fff;
    }
    .kb-bubble.pending { color: #6c757d; }
    .kb-bubble.error {
        background: #fff5f5;
        border-color: #ffd6d6;
        color: #c62828;
    }
    .kb-meta {
        margin-top: 8px;
        font-size: 11px;
        color: #8a94a6;
        white-space: normal;
    }
    .kb-answer-actions {
        margin-top: 12px;
        padding-top: 10px;
        border-top: 1px dashed #dfe5ec;
        display: flex;
        align-items: center;
        gap: 8px;
        flex-wrap: wrap;
        white-space: normal;
    }
    .kb-action {
        display: inline-flex;
        align-items: center;
        padding: 6px 13px;
        border: 1px solid #99f6e4;
        border-radius: 999px;
        background: #f0fdfa;
        color: #0f766e;
        font-size: 12px;
        font-weight: 700;
        text-decoration: none;
    }
    .kb-action:hover { background: #ccfbf1; text-decoration: none; }
    .kb-action.secondary {
        border-color: #bae6fd;
        background: #f0f9ff;
        color: #0369a1;
    }
    .kb-action.secondary:hover { background: #e0f2fe; }
    .kb-composer { margin-top: 14px; }
    .kb-composer textarea {
        width: 100%;
        min-height: 86px;
        resize: vertical;
        padding: 12px 14px;
        border: 1.5px solid #e0e3e8;
        border-radius: 10px;
        background: #fff;
        color: #1a1a2e;
        font-family: inherit;
        font-size: 14px;
        line-height: 1.6;
        outline: none;
    }
    .kb-composer textarea:focus {
        border-color: #0f766e;
        box-shadow: 0 0 0 3px rgba(15,118,110,0.12);
    }
    .kb-composer-actions {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        margin-top: 10px;
    }
    .kb-status { font-size: 12px; color: #6c757d; }
    .kb-composer .btn-primary { background: #0f766e; }
    .kb-composer .btn-primary:hover { background: #115e59; }
    @media (max-width: 767px) {
        .kb-hero { padding: 20px; }
        .kb-hero h2 { font-size: 17px; }
        .kb-card { padding: 16px; }
        .kb-messages { min-height: 240px; max-height: 460px; padding: 12px; }
        .kb-bubble { max-width: 86%; font-size: 13px; }
        .kb-composer-actions { flex-direction: column-reverse; align-items: stretch; }
    }
</style>

<div class="kb-shell" style="--ai-max-width: <%= aiUi.getPageMaxWidthPx() %>;">
    <div class="kb-hero" style="--ai-hero-from: <%= aiUi.getKnowledgeHeroFrom() %>; --ai-hero-to: <%= aiUi.getKnowledgeHeroTo() %>; --ai-hero-color: <%= aiUi.getKnowledgeHeroText() %>; --ai-hero-pad: <%= aiUi.getKnowledgeHeroPadding() %>; --ai-hero-title-size: <%= aiUi.getKnowledgeHeroTitleSize() %>;">
        <h2><%= HtmlUtil.escape(aiUi.getKnowledgeTitle()) %></h2>
        <p><%= HtmlUtil.escape(aiUi.getKnowledgeHeroDescription()) %></p>
        <% if (!aiUi.getKnowledgeHeroBadge().isBlank()) { %>
        <span class="kb-mode"><%= HtmlUtil.escape(aiUi.getKnowledgeHeroBadge()) %></span>
        <% } %>
    </div>

    <% if (!aiUi.getVisibleTabs().isEmpty()) { %>
    <div class="tab-bar">
        <% for (AiUiTab tab : aiUi.getVisibleTabs()) {
            boolean active = pageKey.equals(tab.getActiveKey());
            String target = "_blank".equals(tab.getTarget()) ? "_blank" : "_self";
        %>
        <a class="tab<%= active ? " active" : "" %>" href="<%= HtmlUtil.escape(tab.getHref()) %>" target="<%= target %>"<% if ("_blank".equals(target)) { %> rel="noopener"<% } %>><%= HtmlUtil.escape(tab.getLabel()) %></a>
        <% } %>
    </div>
    <% } %>

    <% if (isReadOnly) { %>
    <div class="info-box"><%= HtmlUtil.escape(aiUi.getKnowledgeReadonlyNotice()) %></div>
    <% } %>

    <div class="kb-card">
        <div class="kb-card-head">
            <div>
                <div class="kb-card-title"><%= HtmlUtil.escape(aiUi.getKnowledgeCardTitle()) %></div>
                <div class="kb-hint"><%= HtmlUtil.escape(aiUi.getKnowledgeCardHint()) %></div>
            </div>
            <% if (!aiUi.getKnowledgeCardBadge().isBlank()) { %>
            <span class="badge badge-blue"><%= HtmlUtil.escape(aiUi.getKnowledgeCardBadge()) %></span>
            <% } %>
        </div>

        <div class="kb-messages" id="kbMessages" aria-live="polite">
            <div class="kb-msg assistant">
                <div class="kb-avatar">AI</div>
                <div class="kb-bubble"><%= HtmlUtil.escape(aiUi.getKnowledgeWelcome()) %></div>
            </div>
        </div>

        <form class="kb-composer" id="kbForm">
            <textarea id="kbInput" placeholder="<%= HtmlUtil.escape(aiUi.getKnowledgePlaceholder()) %>" autocomplete="off" maxlength="1000"></textarea>
            <div class="kb-composer-actions">
                <span class="kb-status" id="kbStatus" aria-live="polite"></span>
                <button class="btn btn-primary" id="kbSendBtn" type="submit"><%= HtmlUtil.escape(aiUi.getKnowledgeSendButton()) %></button>
            </div>
        </form>
    </div>
</div>

<script src="<%= request.getContextPath() %>/js/vendor/marked.umd.js"></script>
<script src="<%= request.getContextPath() %>/js/vendor/purify.min.js"></script>
<script src="<%= request.getContextPath() %>/js/ai-format.js"></script>
<script>
(function () {
    var CTX = '<%= request.getContextPath() %>';
    var KB_URL = CTX + '/api/v1/rag/ask';
    var VIEW_ACTION = '<%= HtmlUtil.escapeJs(aiUi.getKnowledgeViewAction()) %>';
    var DOWNLOAD_ACTION = '<%= HtmlUtil.escapeJs(aiUi.getKnowledgeDownloadAction()) %>';

    var messagesEl = document.getElementById('kbMessages');
    var inputEl = document.getElementById('kbInput');
    var formEl = document.getElementById('kbForm');
    var sendBtn = document.getElementById('kbSendBtn');
    var statusEl = document.getElementById('kbStatus');
    var busy = false;

    function setBusy(value) {
        busy = value;
        inputEl.disabled = value;
        sendBtn.disabled = value;
    }

    function scrollToBottom() {
        messagesEl.scrollTop = messagesEl.scrollHeight;
    }

    function addMessage(role, text) {
        var row = document.createElement('div');
        row.className = 'kb-msg ' + role;

        var avatar = document.createElement('div');
        avatar.className = 'kb-avatar';
        avatar.textContent = role === 'user' ? '您' : 'AI';

        var bubble = document.createElement('div');
        bubble.className = 'kb-bubble';

        var content = document.createElement('div');
        content.textContent = text;

        bubble.appendChild(content);
        row.appendChild(avatar);
        row.appendChild(bubble);
        messagesEl.appendChild(row);
        scrollToBottom();
        return { row: row, bubble: bubble, content: content };
    }

    function appendMeta(bubble, text) {
        var meta = document.createElement('div');
        meta.className = 'kb-meta';
        meta.textContent = text;
        bubble.appendChild(meta);
    }

    function appendAnswerActions(bubble, sources) {
        if (!sources || !sources.length) {
            appendMeta(bubble, '知識庫沒有找到相關文件片段。');
            return;
        }

        var source = sources.find(function (item) {
            return item && item.docId;
        });
        if (!source) {
            appendMeta(bubble, '知識庫沒有找到可開啟的文件片段。');
            return;
        }

        var actions = document.createElement('div');
        actions.className = 'kb-answer-actions';

        var view = document.createElement('a');
        view.className = 'kb-action';
        view.href = CTX + '/api/v1/rag/documents/'
                + encodeURIComponent(source.docId) + '/viewer?chunk='
                + encodeURIComponent(source.chunkIndex != null ? source.chunkIndex : -1);
        view.textContent = VIEW_ACTION;
        view.target = '_blank';
        view.rel = 'noopener';
        actions.appendChild(view);

        if (source.downloadable) {
            var download = document.createElement('a');
            download.className = 'kb-action secondary';
            download.href = CTX + '/api/v1/rag/documents/'
                    + encodeURIComponent(source.docId) + '/download';
            download.textContent = DOWNLOAD_ACTION;
            download.setAttribute('download', '');
            actions.appendChild(download);
        }

        bubble.appendChild(actions);
    }

    async function readJson(resp) {
        var raw = await resp.text();
        try {
            return raw ? JSON.parse(raw) : {};
        } catch (e) {
            return { message: raw.slice(0, 300) };
        }
    }

    function errorText(status, data) {
        if (status === 401) {
            return '登入已失效，請重新整理頁面或重新登入。';
        }
        if (status === 403) {
            return '目前沒有權限使用知識庫問答。';
        }
        if (status === 429) {
            return '請求次數過多，請稍後再試。';
        }
        return data.message || data.error || '查詢失敗，請稍後再試。';
    }

    async function ask(question) {
        var text = String(question || '').trim();
        if (!text || busy) {
            return;
        }

        addMessage('user', text);
        inputEl.value = '';
        var pending = addMessage('assistant', '正在查詢知識庫，請稍候…');
        pending.bubble.classList.add('pending');
        setBusy(true);
        statusEl.textContent = '知識庫檢索中…';

        try {
            var params = new URLSearchParams();
            params.set('query', text);

            var resp = await fetch(KB_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: params.toString()
            });
            var data = await readJson(resp);

            if (!resp.ok) {
                pending.content.textContent = '查詢失敗（HTTP ' + resp.status + '）：' + errorText(resp.status, data);
                pending.bubble.classList.remove('pending');
                pending.bubble.classList.add('error');
                return;
            }

            pending.bubble.classList.remove('pending');
            var answer = data.answer || '知識庫沒有回傳答案。';
            if (window.CharPhoneAiFormat) {
                window.CharPhoneAiFormat.renderInto(pending.content, answer);
            } else {
                pending.content.textContent = answer;
            }

            appendAnswerActions(pending.bubble, data.sources || []);
        } catch (e) {
            pending.bubble.classList.remove('pending');
            pending.bubble.classList.add('error');
            pending.content.textContent = '查詢失敗：' + (e && e.message ? e.message : String(e));
        } finally {
            setBusy(false);
            statusEl.textContent = '';
            scrollToBottom();
        }
    }

    formEl.addEventListener('submit', function (event) {
        event.preventDefault();
        ask(inputEl.value);
    });

    inputEl.addEventListener('keydown', function (event) {
        if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
            event.preventDefault();
            ask(inputEl.value);
        }
    });
})();
</script>
<%@ include file="/include/footer.jsp" %>
