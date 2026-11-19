package model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * 企業AI 頁面內容設定。
 */
public final class AiUiConfig {

    public static final String PAGE_ENTERPRISE = "enterprise";
    public static final String PAGE_KNOWLEDGE = "knowledge";

    public static final String K_PAGE_WIDTH = "shared.page_width";

    public static final String K_ENTERPRISE_TITLE = "enterprise.title";
    public static final String K_ENTERPRISE_HERO_DESCRIPTION = "enterprise.hero_description";
    public static final String K_ENTERPRISE_HERO_BADGE = "enterprise.hero_badge";
    public static final String K_ENTERPRISE_HERO_FROM = "enterprise.hero_from";
    public static final String K_ENTERPRISE_HERO_TO = "enterprise.hero_to";
    public static final String K_ENTERPRISE_HERO_TEXT = "enterprise.hero_text";
    public static final String K_ENTERPRISE_HERO_SIZE = "enterprise.hero_size";
    public static final String K_ENTERPRISE_READONLY_NOTICE = "enterprise.readonly_notice";
    public static final String K_ENTERPRISE_CHAT_TITLE = "enterprise.chat_title";
    public static final String K_ENTERPRISE_CHAT_HINT = "enterprise.chat_hint";
    public static final String K_ENTERPRISE_CHAT_BADGE = "enterprise.chat_badge";
    public static final String K_ENTERPRISE_WELCOME = "enterprise.welcome";
    public static final String K_ENTERPRISE_PLACEHOLDER = "enterprise.placeholder";
    public static final String K_ENTERPRISE_SEND_BUTTON = "enterprise.send_button";
    public static final String K_ENTERPRISE_PRESET_TITLE = "enterprise.preset_title";
    public static final String K_ENTERPRISE_PRESET_HINT = "enterprise.preset_hint";
    public static final String K_ENTERPRISE_PRESET_BADGE = "enterprise.preset_badge";

    public static final String K_KNOWLEDGE_TITLE = "knowledge.title";
    public static final String K_KNOWLEDGE_HERO_DESCRIPTION = "knowledge.hero_description";
    public static final String K_KNOWLEDGE_HERO_BADGE = "knowledge.hero_badge";
    public static final String K_KNOWLEDGE_HERO_FROM = "knowledge.hero_from";
    public static final String K_KNOWLEDGE_HERO_TO = "knowledge.hero_to";
    public static final String K_KNOWLEDGE_HERO_TEXT = "knowledge.hero_text";
    public static final String K_KNOWLEDGE_HERO_SIZE = "knowledge.hero_size";
    public static final String K_KNOWLEDGE_READONLY_NOTICE = "knowledge.readonly_notice";
    public static final String K_KNOWLEDGE_CARD_TITLE = "knowledge.card_title";
    public static final String K_KNOWLEDGE_CARD_HINT = "knowledge.card_hint";
    public static final String K_KNOWLEDGE_CARD_BADGE = "knowledge.card_badge";
    public static final String K_KNOWLEDGE_WELCOME = "knowledge.welcome";
    public static final String K_KNOWLEDGE_PLACEHOLDER = "knowledge.placeholder";
    public static final String K_KNOWLEDGE_SEND_BUTTON = "knowledge.send_button";
    public static final String K_KNOWLEDGE_VIEW_ACTION = "knowledge.view_action";
    public static final String K_KNOWLEDGE_DOWNLOAD_ACTION = "knowledge.download_action";

    private static final Map<String, String> DEFAULTS = createDefaults();
    private static final List<AiUiTab> DEFAULT_TABS = List.of(
            new AiUiTab("企業AI", "ai.jsp", "_self", PAGE_ENTERPRISE, 0, true),
            new AiUiTab("AI 知識庫", "ai_knowledge.jsp", "_self", PAGE_KNOWLEDGE, 1, true)
    );

    private final Map<String, String> values = new LinkedHashMap<>(DEFAULTS);
    private List<AiUiTab> tabs = new ArrayList<>(DEFAULT_TABS);

    /**
     * 建立含預設值的設定物件。
     */
    public static AiUiConfig defaults() {
        return new AiUiConfig();
    }

    /**
     * 取得原始設定值。
     */
    public String get(String key) {
        String value = values.get(key);
        return value != null ? value : DEFAULTS.getOrDefault(key, "");
    }

    /**
     * 設定已知 key 的值；未知 key 會被忽略。
     */
    public void set(String key, String value) {
        if (DEFAULTS.containsKey(key)) {
            values.put(key, value == null ? "" : value);
        }
    }

    /**
     * 取得所有可儲存的設定值。
     */
    public Map<String, String> values() {
        return Collections.unmodifiableMap(values);
    }

    public List<AiUiTab> getTabs() {
        return Collections.unmodifiableList(tabs);
    }

    public void setTabs(List<AiUiTab> tabs) {
        this.tabs = tabs == null ? new ArrayList<>() : new ArrayList<>(tabs);
    }

    public List<AiUiTab> getVisibleTabs() {
        return tabs.stream().filter(AiUiTab::isVisible).toList();
    }

    public String getPageWidth() {
        return oneOf(get(K_PAGE_WIDTH), "narrow", "standard", "wide", "standard");
    }

    public String getPageMaxWidthPx() {
        return switch (getPageWidth()) {
            case "narrow" -> "900px";
            case "wide" -> "1320px";
            default -> "1120px";
        };
    }

    public String getEnterpriseTitle() { return get(K_ENTERPRISE_TITLE); }
    public String getEnterpriseHeroDescription() { return get(K_ENTERPRISE_HERO_DESCRIPTION); }
    public String getEnterpriseHeroBadge() { return get(K_ENTERPRISE_HERO_BADGE); }
    public String getEnterpriseHeroFrom() { return color(get(K_ENTERPRISE_HERO_FROM), "#4361ee"); }
    public String getEnterpriseHeroTo() { return color(get(K_ENTERPRISE_HERO_TO), "#7c4dff"); }
    public String getEnterpriseHeroText() { return color(get(K_ENTERPRISE_HERO_TEXT), "#ffffff"); }
    public String getEnterpriseHeroSize() {
        return oneOf(get(K_ENTERPRISE_HERO_SIZE), "compact", "standard", "large", "standard");
    }
    public String getEnterpriseHeroPadding() { return heroPadding(getEnterpriseHeroSize()); }
    public String getEnterpriseHeroTitleSize() { return heroTitleSize(getEnterpriseHeroSize()); }
    public String getEnterpriseReadonlyNotice() { return get(K_ENTERPRISE_READONLY_NOTICE); }
    public String getEnterpriseChatTitle() { return get(K_ENTERPRISE_CHAT_TITLE); }
    public String getEnterpriseChatHint() { return get(K_ENTERPRISE_CHAT_HINT); }
    public String getEnterpriseChatBadge() { return get(K_ENTERPRISE_CHAT_BADGE); }
    public String getEnterpriseWelcome() { return get(K_ENTERPRISE_WELCOME); }
    public String getEnterprisePlaceholder() { return get(K_ENTERPRISE_PLACEHOLDER); }
    public String getEnterpriseSendButton() { return get(K_ENTERPRISE_SEND_BUTTON); }
    public String getEnterprisePresetTitle() { return get(K_ENTERPRISE_PRESET_TITLE); }
    public String getEnterprisePresetHint() { return get(K_ENTERPRISE_PRESET_HINT); }
    public String getEnterprisePresetBadge() { return get(K_ENTERPRISE_PRESET_BADGE); }

    public String getKnowledgeTitle() { return get(K_KNOWLEDGE_TITLE); }
    public String getKnowledgeHeroDescription() { return get(K_KNOWLEDGE_HERO_DESCRIPTION); }
    public String getKnowledgeHeroBadge() { return get(K_KNOWLEDGE_HERO_BADGE); }
    public String getKnowledgeHeroFrom() { return color(get(K_KNOWLEDGE_HERO_FROM), "#0f766e"); }
    public String getKnowledgeHeroTo() { return color(get(K_KNOWLEDGE_HERO_TO), "#0ea5e9"); }
    public String getKnowledgeHeroText() { return color(get(K_KNOWLEDGE_HERO_TEXT), "#ffffff"); }
    public String getKnowledgeHeroSize() {
        return oneOf(get(K_KNOWLEDGE_HERO_SIZE), "compact", "standard", "large", "standard");
    }
    public String getKnowledgeHeroPadding() { return heroPadding(getKnowledgeHeroSize()); }
    public String getKnowledgeHeroTitleSize() { return heroTitleSize(getKnowledgeHeroSize()); }
    public String getKnowledgeReadonlyNotice() { return get(K_KNOWLEDGE_READONLY_NOTICE); }
    public String getKnowledgeCardTitle() { return get(K_KNOWLEDGE_CARD_TITLE); }
    public String getKnowledgeCardHint() { return get(K_KNOWLEDGE_CARD_HINT); }
    public String getKnowledgeCardBadge() { return get(K_KNOWLEDGE_CARD_BADGE); }
    public String getKnowledgeWelcome() { return get(K_KNOWLEDGE_WELCOME); }
    public String getKnowledgePlaceholder() { return get(K_KNOWLEDGE_PLACEHOLDER); }
    public String getKnowledgeSendButton() { return get(K_KNOWLEDGE_SEND_BUTTON); }
    public String getKnowledgeViewAction() { return get(K_KNOWLEDGE_VIEW_ACTION); }
    public String getKnowledgeDownloadAction() { return get(K_KNOWLEDGE_DOWNLOAD_ACTION); }

    private static Map<String, String> createDefaults() {
        Map<String, String> map = new LinkedHashMap<>();
        map.put(K_PAGE_WIDTH, "standard");

        map.put(K_ENTERPRISE_TITLE, "企業AI");
        map.put(K_ENTERPRISE_HERO_DESCRIPTION, "用自然語言詢問訂單、出貨、帳款、庫存、生產與客戶資料。送出後由 enterprise AI Gateway 的 Agent 查詢 ERP 並彙整回答。");
        map.put(K_ENTERPRISE_HERO_BADGE, "預設模式：Agent 工具查詢");
        map.put(K_ENTERPRISE_HERO_FROM, "#4361ee");
        map.put(K_ENTERPRISE_HERO_TO, "#7c4dff");
        map.put(K_ENTERPRISE_HERO_TEXT, "#ffffff");
        map.put(K_ENTERPRISE_HERO_SIZE, "standard");
        map.put(K_ENTERPRISE_READONLY_NOTICE, "唯讀模式：AI 回覆可能包含客戶與營運資料，請依公司規範使用，勿將結果外傳。");
        map.put(K_ENTERPRISE_CHAT_TITLE, "對話測試");
        map.put(K_ENTERPRISE_CHAT_HINT, "Agent 模式：每次送出都是獨立查詢；需要查資料時會自動呼叫工具。");
        map.put(K_ENTERPRISE_CHAT_BADGE, "Agent");
        map.put(K_ENTERPRISE_WELCOME, "您好，我是 CharPhone 業務 AI 助理。可以問我「2026年8月有哪些訂單？」、「哪些帳還沒收到？」或直接點下方快速測試。");
        map.put(K_ENTERPRISE_PLACEHOLDER, "輸入業務問題，例如：目前有哪些訂單來不及交貨？");
        map.put(K_ENTERPRISE_SEND_BUTTON, "送出查詢");
        map.put(K_ENTERPRISE_PRESET_TITLE, "快速測試");
        map.put(K_ENTERPRISE_PRESET_HINT, "點選任一問題即送出 Agent 查詢；共 11 組常用業務情境。");
        map.put(K_ENTERPRISE_PRESET_BADGE, "11 組");

        map.put(K_KNOWLEDGE_TITLE, "AI 知識庫");
        map.put(K_KNOWLEDGE_HERO_DESCRIPTION, "用自然語言詢問公司知識庫文件。系統會先找出最相關的文件片段，再由 AI 根據這些內容整理回答。");
        map.put(K_KNOWLEDGE_HERO_BADGE, "知識庫問答 · 不提供文件管理");
        map.put(K_KNOWLEDGE_HERO_FROM, "#0f766e");
        map.put(K_KNOWLEDGE_HERO_TO, "#0ea5e9");
        map.put(K_KNOWLEDGE_HERO_TEXT, "#ffffff");
        map.put(K_KNOWLEDGE_HERO_SIZE, "standard");
        map.put(K_KNOWLEDGE_READONLY_NOTICE, "唯讀模式：AI 回答可能包含文件中的業務資料，請依公司規範使用，勿將結果外傳。");
        map.put(K_KNOWLEDGE_CARD_TITLE, "知識庫問答");
        map.put(K_KNOWLEDGE_CARD_HINT, "回答僅根據知識庫檢索到的內容；找不到資料時會明確說明。問題送出後由 AI Gateway 的 RAG 服務處理。");
        map.put(K_KNOWLEDGE_CARD_BADGE, "RAG");
        map.put(K_KNOWLEDGE_WELCOME, "您好，我可以協助查詢公司知識庫。請直接輸入問題，例如「說明鑄造流程」");
        map.put(K_KNOWLEDGE_PLACEHOLDER, "輸入知識庫問題，例如「說明鑄造流程」");
        map.put(K_KNOWLEDGE_SEND_BUTTON, "送出提問");
        map.put(K_KNOWLEDGE_VIEW_ACTION, "查看內容");
        map.put(K_KNOWLEDGE_DOWNLOAD_ACTION, "文件下載");
        return Collections.unmodifiableMap(map);
    }

    private static String oneOf(String value, String a, String b, String c, String fallback) {
        String normalized = value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
        return normalized.equals(a) || normalized.equals(b) || normalized.equals(c) ? normalized : fallback;
    }

    private static String color(String value, String fallback) {
        return value != null && value.matches("^#[0-9a-fA-F]{6}$") ? value : fallback;
    }

    private static String heroPadding(String size) {
        return switch (size) {
            case "compact" -> "20px 24px";
            case "large" -> "34px 38px";
            default -> "26px 30px";
        };
    }

    private static String heroTitleSize(String size) {
        return switch (size) {
            case "compact" -> "18px";
            case "large" -> "24px";
            default -> "20px";
        };
    }
}
