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
    String pageKey = AiUiConfig.PAGE_ENTERPRISE;
%>
<% request.setAttribute("pageTitle", aiUi.getEnterpriseTitle()); %>
<% request.setAttribute("pageIcon", "✦"); %>
<% request.setAttribute("pageSubtitle", "企業資料對話與快速測試"); %>
<%@ include file="/include/header.jsp" %>
<style>
    .ai-shell { max-width: var(--ai-max-width, 1120px); margin: 0 auto; }
    .ai-hero {
        background: linear-gradient(135deg, var(--ai-hero-from, #4361ee) 0%, var(--ai-hero-to, #7c4dff) 100%);
        border-radius: 12px;
        padding: var(--ai-hero-pad, 26px 30px);
        color: var(--ai-hero-color, #fff);
        margin-bottom: 18px;
        box-shadow: 0 8px 24px rgba(67,97,238,0.18);
    }
    .ai-hero h2 { margin: 0 0 6px; font-size: var(--ai-hero-title-size, 20px); }
    .ai-hero p { margin: 0; font-size: 13px; opacity: 0.88; line-height: 1.7; }
    .ai-hero .ai-mode {
        display: inline-block;
        margin-top: 12px;
        padding: 4px 10px;
        border-radius: 999px;
        background: rgba(255,255,255,0.16);
        font-size: 11px;
        font-weight: 700;
        letter-spacing: 0.4px;
    }
    .ai-card {
        background: #fff;
        border-radius: 12px;
        padding: 22px 24px;
        margin-bottom: 18px;
        box-shadow: 0 1px 4px rgba(0,0,0,0.06);
    }
    .ai-card-head {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        gap: 12px;
        margin-bottom: 14px;
    }
    .ai-card-title { font-size: 16px; font-weight: 700; color: #1a1a2e; }
    .ai-hint { margin-top: 4px; font-size: 12px; color: #6c757d; line-height: 1.6; }
    .ai-messages {
        min-height: 260px;
        max-height: 520px;
        overflow-y: auto;
        padding: 16px;
        border: 1px solid #e9ecef;
        border-radius: 10px;
        background: #f8f9fc;
    }
    .ai-msg { display: flex; gap: 10px; align-items: flex-start; margin-bottom: 14px; }
    .ai-msg:last-child { margin-bottom: 0; }
    .ai-msg.user { flex-direction: row-reverse; }
    .ai-avatar {
        flex: 0 0 30px;
        width: 30px;
        height: 30px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 11px;
        font-weight: 700;
        background: #e8ecff;
        color: #4361ee;
    }
    .ai-msg.user .ai-avatar { background: #4361ee; color: #fff; }
    .ai-bubble {
        max-width: min(760px, 82%);
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
    .ai-msg.user .ai-bubble {
        background: #4361ee;
        border-color: #4361ee;
        color: #fff;
    }
    .ai-bubble.pending { color: #6c757d; }
    .ai-bubble.error {
        background: #fff5f5;
        border-color: #ffd6d6;
        color: #c62828;
    }
    .ai-meta {
        margin-top: 8px;
        font-size: 11px;
        color: #8a94a6;
        white-space: normal;
    }
    .ai-toolcalls {
        margin-top: 10px;
        padding-top: 8px;
        border-top: 1px dashed #e1e5ec;
        font-size: 11px;
        color: #495057;
        line-height: 1.8;
    }
    .ai-composer { margin-top: 14px; }
    .ai-composer textarea {
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
    .ai-composer textarea:focus {
        border-color: #4361ee;
        box-shadow: 0 0 0 3px rgba(67,97,238,0.12);
    }
    .ai-composer-actions {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        margin-top: 10px;
    }
    .ai-composer-left {
        display: flex;
        align-items: center;
        gap: 10px;
        min-width: 0;
        flex-wrap: wrap;
    }
    .ai-attach-btn { white-space: nowrap; }
    .ai-attachments {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
        margin-bottom: 10px;
    }
    .ai-attachments[hidden] { display: none; }
    .ai-attachment {
        display: flex;
        align-items: center;
        gap: 8px;
        max-width: 280px;
        padding: 6px 8px;
        border: 1px solid #dbe2ea;
        border-radius: 10px;
        background: #f8fafc;
    }
    .ai-attachment img {
        width: 48px;
        height: 48px;
        object-fit: cover;
        border-radius: 7px;
        border: 1px solid #e2e8f0;
        background: #fff;
    }
    .ai-attachment-meta {
        min-width: 0;
        flex: 1;
        font-size: 12px;
        color: #475569;
        line-height: 1.5;
    }
    .ai-attachment-name {
        display: block;
        max-width: 100%;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        font-weight: 700;
        color: #1e293b;
    }
    .ai-attachment-remove {
        flex: 0 0 auto;
        width: 28px;
        height: 28px;
        border: 0;
        border-radius: 50%;
        background: #e2e8f0;
        color: #475569;
        font-size: 18px;
        line-height: 1;
        cursor: pointer;
    }
    .ai-attachment-remove:hover { background: #cbd5e1; color: #1e293b; }
    .ai-msg-images {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
        margin-bottom: 8px;
    }
    .ai-msg-image {
        display: block;
        max-width: 100%;
        max-height: 220px;
        border-radius: 8px;
        object-fit: contain;
        background: rgba(255,255,255,0.12);
    }
    .ai-status { font-size: 12px; color: #6c757d; }
    .ai-presets {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
        gap: 10px;
    }
    .ai-preset {
        text-align: left;
        padding: 12px 14px;
        border: 1.5px solid #e4e8ef;
        border-radius: 10px;
        background: #f8fafc;
        font-family: inherit;
        cursor: pointer;
        transition: all 0.15s;
        min-height: 70px;
    }
    .ai-preset:hover {
        border-color: #4361ee;
        background: #eef2ff;
        transform: translateY(-1px);
    }
    .ai-preset:disabled { opacity: 0.55; cursor: wait; transform: none; }
    .ai-preset-tool {
        font-size: 11px;
        font-weight: 700;
        color: #4361ee;
        letter-spacing: 0.2px;
    }
    .ai-preset-q {
        margin-top: 5px;
        font-size: 13px;
        color: #1a1a2e;
        line-height: 1.55;
    }
    @media (max-width: 767px) {
        .ai-hero { padding: 20px; }
        .ai-hero h2 { font-size: 17px; }
        .ai-card { padding: 16px; }
        .ai-messages { min-height: 220px; max-height: 420px; padding: 12px; }
        .ai-bubble { max-width: 86%; font-size: 13px; }
        .ai-composer-actions { flex-direction: column-reverse; align-items: stretch; }
        .ai-presets { grid-template-columns: 1fr; }
    }
</style>

<div class="ai-shell" style="--ai-max-width: <%= aiUi.getPageMaxWidthPx() %>;">
    <div class="ai-hero" style="--ai-hero-from: <%= aiUi.getEnterpriseHeroFrom() %>; --ai-hero-to: <%= aiUi.getEnterpriseHeroTo() %>; --ai-hero-color: <%= aiUi.getEnterpriseHeroText() %>; --ai-hero-pad: <%= aiUi.getEnterpriseHeroPadding() %>; --ai-hero-title-size: <%= aiUi.getEnterpriseHeroTitleSize() %>;">
        <h2><%= HtmlUtil.escape(aiUi.getEnterpriseTitle()) %></h2>
        <p><%= HtmlUtil.escape(aiUi.getEnterpriseHeroDescription()) %></p>
        <% if (!aiUi.getEnterpriseHeroBadge().isBlank()) { %>
        <span class="ai-mode"><%= HtmlUtil.escape(aiUi.getEnterpriseHeroBadge()) %></span>
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
    <div class="info-box"><%= HtmlUtil.escape(aiUi.getEnterpriseReadonlyNotice()) %></div>
    <% } %>

    <div class="ai-card">
        <div class="ai-card-head">
            <div>
                <div class="ai-card-title"><%= HtmlUtil.escape(aiUi.getEnterpriseChatTitle()) %></div>
                <div class="ai-hint"><%= HtmlUtil.escape(aiUi.getEnterpriseChatHint()) %></div>
            </div>
            <% if (!aiUi.getEnterpriseChatBadge().isBlank()) { %>
            <span class="badge badge-blue"><%= HtmlUtil.escape(aiUi.getEnterpriseChatBadge()) %></span>
            <% } %>
        </div>

        <div class="ai-messages" id="chatMessages" aria-live="polite">
            <div class="ai-msg assistant">
                <div class="ai-avatar">AI</div>
                <div class="ai-bubble"><%= HtmlUtil.escape(aiUi.getEnterpriseWelcome()) %></div>
            </div>
        </div>

        <form class="ai-composer" id="chatForm">
            <div class="ai-attachments" id="chatAttachments" hidden></div>
            <textarea id="chatInput" placeholder="<%= HtmlUtil.escape(aiUi.getEnterprisePlaceholder()) %>" autocomplete="off"></textarea>
            <div class="ai-composer-actions">
                <div class="ai-composer-left">
                    <button class="btn btn-outline btn-sm ai-attach-btn" id="attachImageBtn" type="button" title="附加圖片（最多 3 張，可貼上）">附加圖片</button>
                    <input type="file" id="imageInput" accept="image/png,image/jpeg,image/webp" hidden>
                    <span class="ai-status" id="chatStatus" aria-live="polite"></span>
                </div>
                <button class="btn btn-primary" id="sendBtn" type="submit"><%= HtmlUtil.escape(aiUi.getEnterpriseSendButton()) %></button>
            </div>
        </form>
    </div>

    <div class="ai-card">
        <div class="ai-card-head">
            <div>
                <div class="ai-card-title"><%= HtmlUtil.escape(aiUi.getEnterprisePresetTitle()) %></div>
                <div class="ai-hint"><%= HtmlUtil.escape(aiUi.getEnterprisePresetHint()) %></div>
            </div>
            <% if (!aiUi.getEnterprisePresetBadge().isBlank()) { %>
            <span class="badge badge-gray"><%= HtmlUtil.escape(aiUi.getEnterprisePresetBadge()) %></span>
            <% } %>
        </div>
        <div class="ai-presets" id="presetGrid"></div>
    </div>
</div>

<script src="<%= request.getContextPath() %>/js/vendor/marked.umd.js"></script>
<script src="<%= request.getContextPath() %>/js/vendor/purify.min.js"></script>
<script src="<%= request.getContextPath() %>/js/ai-format.js"></script>
<script>
(function () {
    var CTX = '<%= request.getContextPath() %>';
    var AGENT_URL = CTX + '/api/v1/agent/run';

    var PRESETS = [
        { label: '2026年8月有哪些訂單？', tool: 'query_orders', msg: '2026年8月有哪些訂單？請彙整說明' },
        { label: '哪些訂單來不及交貨？', tool: 'query_risk_orders', msg: '目前有哪些訂單來不及交貨？請說明風險狀況' },
        { label: '哪些帳還沒收到？有逾期的嗎？', tool: 'query_receivables', msg: '現在有哪些帳還沒收到？有沒有逾期的？' },
        { label: '2026年各月營收？哪幾月是旺季？', tool: 'query_sales_summary', msg: '2026年各月營收如何？哪幾個月是旺季？' },
        { label: '前五大客戶是誰？各貢獻多少？', tool: 'query_sales_summary', msg: '前五大客戶是誰？各貢獻多少營收？' },
        { label: '查「範例科技」客戶資料', tool: 'query_customers', msg: '幫我查一下客戶資料，關鍵字「範例科技」' },
        { label: '2026年8月出貨紀錄', tool: 'query_deliveries', msg: '幫我查一下2026年8月的出貨紀錄' },
        { label: '公司營運狀況如何？', tool: 'query_dashboard_kpis', msg: '目前公司營運狀況如何？有哪些需要關注的指標？' },
        { label: '庫存有低於安全庫存的嗎？', tool: 'query_inventory', msg: '目前有哪些品項低於安全庫存？' },
        { label: '生產進度到哪了？', tool: 'query_production', msg: '目前生產進度如何？有哪些工單進行中？' },
        { label: '報價流程？折扣>10%？(RAG)', tool: 'query_knowledge', msg: '根據知識庫文件，公司的報價流程是什麼？折扣超過10%需要誰核准？' }
    ];

    var messagesEl = document.getElementById('chatMessages');
    var inputEl = document.getElementById('chatInput');
    var formEl = document.getElementById('chatForm');
    var sendBtn = document.getElementById('sendBtn');
    var statusEl = document.getElementById('chatStatus');
    var gridEl = document.getElementById('presetGrid');
    var attachBtn = document.getElementById('attachImageBtn');
    var imageInput = document.getElementById('imageInput');
    var attachmentsEl = document.getElementById('chatAttachments');
    var currentImages = [];
    var busy = false;
    var MAX_IMAGES = 3;

    function setBusy(value) {
        busy = value;
        inputEl.disabled = value;
        sendBtn.disabled = value;
        attachBtn.disabled = value;
        attachmentsEl.querySelectorAll('button').forEach(function (button) {
            button.disabled = value;
        });
        gridEl.querySelectorAll('button').forEach(function (button) {
            button.disabled = value;
        });
    }

    function scrollToBottom() {
        messagesEl.scrollTop = messagesEl.scrollHeight;
    }

    function formatBytes(bytes) {
        if (!bytes) return '0 KB';
        if (bytes < 1024 * 1024) return Math.max(1, Math.round(bytes / 1024)) + ' KB';
        return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
    }

    function renderAttachments() {
        attachmentsEl.textContent = '';
        attachmentsEl.hidden = currentImages.length === 0;
        currentImages.forEach(function (image, index) {
            var item = document.createElement('div');
            item.className = 'ai-attachment';

            var preview = document.createElement('img');
            preview.src = image.previewUrl;
            preview.alt = '待送出圖片預覽';

            var meta = document.createElement('div');
            meta.className = 'ai-attachment-meta';

            var name = document.createElement('span');
            name.className = 'ai-attachment-name';
            name.textContent = image.name || '圖片';

            var size = document.createElement('span');
            size.textContent = formatBytes(image.bytes) + ' · 已壓縮';

            meta.appendChild(name);
            meta.appendChild(size);

            var remove = document.createElement('button');
            remove.className = 'ai-attachment-remove';
            remove.type = 'button';
            remove.disabled = busy;
            remove.setAttribute('aria-label', '移除圖片');
            remove.textContent = '×';
            remove.addEventListener('click', function () {
                currentImages.splice(index, 1);
                renderAttachments();
                statusEl.textContent = '';
            });

            item.appendChild(preview);
            item.appendChild(meta);
            item.appendChild(remove);
            attachmentsEl.appendChild(item);
        });
    }

    function addAttachment(image) {
        if (currentImages.length >= MAX_IMAGES) {
            statusEl.textContent = '一次最多附上 ' + MAX_IMAGES + ' 張圖片';
            return;
        }
        currentImages.push(image);
        renderAttachments();
        if (!busy) {
            statusEl.textContent = '';
        }
    }

    function loadImageFile(file) {
        return new Promise(function (resolve, reject) {
            if (!file || !/^image\/(png|jpe?g|webp)$/.test((file.type || '').toLowerCase())) {
                reject(new Error('僅支援 PNG、JPEG、WEBP 圖片'));
                return;
            }
            if (file.size > 10 * 1024 * 1024) {
                reject(new Error('圖片不可超過 10MB'));
                return;
            }
            var objectUrl = URL.createObjectURL(file);
            var image = new Image();
            image.onload = function () {
                try {
                    var maxSide = 1600;
                    var scale = Math.min(1, maxSide / Math.max(image.width, image.height));
                    var canvas = document.createElement('canvas');
                    canvas.width = Math.max(1, Math.round(image.width * scale));
                    canvas.height = Math.max(1, Math.round(image.height * scale));
                    var ctx = canvas.getContext('2d');
                    ctx.fillStyle = '#ffffff';
                    ctx.fillRect(0, 0, canvas.width, canvas.height);
                    ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
                    var dataUrl = canvas.toDataURL('image/jpeg', 0.88);
                    var base64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
                    resolve({
                        mimeType: 'image/jpeg',
                        data: base64,
                        previewUrl: dataUrl,
                        name: file.name || '貼上的圖片',
                        bytes: Math.floor(base64.length * 3 / 4)
                    });
                } catch (e) {
                    reject(new Error('圖片處理失敗，請換一張圖片'));
                } finally {
                    URL.revokeObjectURL(objectUrl);
                }
            };
            image.onerror = function () {
                URL.revokeObjectURL(objectUrl);
                reject(new Error('無法讀取圖片，請換一張圖片'));
            };
            image.src = objectUrl;
        });
    }

    async function handleImageFile(file) {
        if (!file || busy) return;
        if (currentImages.length >= MAX_IMAGES) {
            statusEl.textContent = '一次最多附上 ' + MAX_IMAGES + ' 張圖片';
            return;
        }
        statusEl.textContent = '正在處理圖片…';
        try {
            var image = await loadImageFile(file);
            addAttachment(image);
        } catch (e) {
            statusEl.textContent = e && e.message ? e.message : '圖片處理失敗';
        }
    }

    function addMessage(role, text, imageUrls) {
        var row = document.createElement('div');
        row.className = 'ai-msg ' + role;

        var avatar = document.createElement('div');
        avatar.className = 'ai-avatar';
        avatar.textContent = role === 'user' ? '您' : 'AI';

        var bubble = document.createElement('div');
        bubble.className = 'ai-bubble';

        if (imageUrls && imageUrls.length) {
            var images = document.createElement('div');
            images.className = 'ai-msg-images';
            imageUrls.forEach(function (url) {
                var image = document.createElement('img');
                image.className = 'ai-msg-image';
                image.src = url;
                image.alt = '使用者附加圖片';
                images.appendChild(image);
            });
            bubble.appendChild(images);
        }

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
        meta.className = 'ai-meta';
        meta.textContent = text;
        bubble.appendChild(meta);
    }

    function appendToolCalls(bubble, calls) {
        if (!calls || !calls.length) {
            return;
        }
        var box = document.createElement('div');
        box.className = 'ai-toolcalls';
        calls.forEach(function (call) {
            var line = document.createElement('div');
            var ok = call.ok ? '✓' : '✕';
            var name = call.tool || call.name || 'tool';
            line.textContent = ok + ' ' + name + '（' + (call.latencyMs || 0) + ' ms）';
            box.appendChild(line);
        });
        bubble.appendChild(box);
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
            return '登入狀態已失效，請重新整理或重新登入。';
        }
        if (status === 403) {
            return '目前沒有權限，或請求被安全規則阻擋。';
        }
        if (status === 429) {
            return '請求過於頻繁，請稍後再試。';
        }
        return data.message || data.error || '查詢失敗，請稍後再試。';
    }

    async function ask(message) {
        var images = currentImages.slice();
        var text = String(message || '').trim();
        if ((!text && !images.length) || busy) {
            return;
        }
        if (!text) {
            text = '請說明這張圖片的內容';
        }

        addMessage('user', text, images.map(function (image) {
            return image.previewUrl;
        }));
        inputEl.value = '';
        var pending = addMessage('assistant', '正在查詢企業資料，Agent 需要數十秒…');
        pending.bubble.classList.add('pending');
        setBusy(true);
        statusEl.textContent = images.length ? 'Agent 分析圖片與企業資料中…' : 'Agent 查詢中…';

        try {
            var payload = { userMessage: text, maxToolRounds: 8 };
            if (images.length) {
                payload.images = images.map(function (image) {
                    return { mimeType: image.mimeType, data: image.data };
                });
            }
            var resp = await fetch(AGENT_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: JSON.stringify(payload)
            });
            var data = await readJson(resp);

            if (!resp.ok) {
                pending.content.textContent = '查詢失敗（HTTP ' + resp.status + '）：' + errorText(resp.status, data);
                pending.bubble.classList.add('error');
                return;
            }

            pending.bubble.classList.remove('pending');
            var answer = data.message || '（模型未回覆內容）';
            if (window.CharPhoneAiFormat) {
                window.CharPhoneAiFormat.renderInto(pending.content, answer);
            } else {
                pending.content.textContent = answer;
            }
            appendToolCalls(pending.bubble, data.toolCalls || []);

            var usage = data.usage || {};
            if (usage.model || usage.totalTokens) {
                appendMeta(pending.bubble, 'model=' + (usage.model || '-') + ' · tokens=' + (usage.totalTokens || 0));
            }
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

    function renderPresets() {
        PRESETS.forEach(function (preset) {
            var button = document.createElement('button');
            button.type = 'button';
            button.className = 'ai-preset';

            var tool = document.createElement('div');
            tool.className = 'ai-preset-tool';
            tool.textContent = preset.tool;

            var question = document.createElement('div');
            question.className = 'ai-preset-q';
            question.textContent = preset.label;

            button.appendChild(tool);
            button.appendChild(question);
            button.addEventListener('click', function () {
                ask(preset.msg);
            });
            gridEl.appendChild(button);
        });
    }

    attachBtn.addEventListener('click', function () {
        if (!busy) {
            imageInput.click();
        }
    });

    imageInput.addEventListener('change', function () {
        var file = imageInput.files && imageInput.files[0];
        imageInput.value = '';
        handleImageFile(file);
    });

    inputEl.addEventListener('paste', function (event) {
        var items = event.clipboardData && event.clipboardData.items;
        if (!items) return;
        for (var i = 0; i < items.length; i++) {
            if (items[i].type && items[i].type.indexOf('image/') === 0) {
                event.preventDefault();
                handleImageFile(items[i].getAsFile());
                return;
            }
        }
    });

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

    renderPresets();
})();
</script>
<%@ include file="/include/footer.jsp" %>
