package servlet;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

import dao.AiUiDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.AiUiConfig;
import model.AiUiTab;
import model.User;

/**
 * 企業AI 頁面內容管理。
 */
@WebServlet("/AiUiAdminServlet")
public class AiUiAdminServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOGGER = Logger.getLogger(AiUiAdminServlet.class.getName());

    private static final int MAX_TABS = 10;
    private static final Set<String> HERO_SIZES = Set.of("compact", "standard", "large");
    private static final Set<String> PAGE_WIDTHS = Set.of("narrow", "standard", "wide");
    private static final Set<String> TAB_TARGETS = Set.of("_self", "_blank");
    private static final Set<String> ACTIVE_KEYS = Set.of("", AiUiConfig.PAGE_ENTERPRISE, AiUiConfig.PAGE_KNOWLEDGE);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!requireAdmin(req, resp)) {
            return;
        }
        req.setAttribute("aiUi", new AiUiDao().load());
        req.getRequestDispatcher("/WEB-INF/ai_ui_admin.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!requireAdmin(req, resp)) {
            return;
        }

        String action = trim(req.getParameter("action"));
        if ("reset".equals(action)) {
            boolean ok = new AiUiDao().reset();
            LOGGER.info(() -> "AI page settings reset by " + username(req) + ", ok=" + ok);
            redirectWithMessage(req, resp, ok ? "已回復預設內容" : "回復預設失敗，請稍後再試");
            return;
        }

        AiUiConfig config = readConfig(req);
        List<String> errors = validate(config);
        if (!errors.isEmpty()) {
            req.setAttribute("aiUi", config);
            req.setAttribute("errors", errors);
            req.getRequestDispatcher("/WEB-INF/ai_ui_admin.jsp").forward(req, resp);
            return;
        }

        boolean ok = new AiUiDao().save(config, userId(req));
        LOGGER.info(() -> "AI page settings saved by " + username(req) + ", ok=" + ok);
        redirectWithMessage(req, resp, ok ? "已儲存企業AI 頁面內容" : "儲存失敗，請稍後再試");
    }

    private AiUiConfig readConfig(HttpServletRequest req) {
        AiUiConfig defaults = AiUiConfig.defaults();
        AiUiConfig config = AiUiConfig.defaults();

        config.set(AiUiConfig.K_PAGE_WIDTH, text(req, "pageWidth", defaults.get(AiUiConfig.K_PAGE_WIDTH)));

        config.set(AiUiConfig.K_ENTERPRISE_TITLE, text(req, "enterpriseTitle", defaults.getEnterpriseTitle()));
        config.set(AiUiConfig.K_ENTERPRISE_HERO_DESCRIPTION, text(req, "enterpriseHeroDescription", defaults.getEnterpriseHeroDescription()));
        config.set(AiUiConfig.K_ENTERPRISE_HERO_BADGE, text(req, "enterpriseHeroBadge", defaults.getEnterpriseHeroBadge()));
        config.set(AiUiConfig.K_ENTERPRISE_HERO_FROM, text(req, "enterpriseHeroFrom", defaults.getEnterpriseHeroFrom()));
        config.set(AiUiConfig.K_ENTERPRISE_HERO_TO, text(req, "enterpriseHeroTo", defaults.getEnterpriseHeroTo()));
        config.set(AiUiConfig.K_ENTERPRISE_HERO_TEXT, text(req, "enterpriseHeroText", defaults.getEnterpriseHeroText()));
        config.set(AiUiConfig.K_ENTERPRISE_HERO_SIZE, text(req, "enterpriseHeroSize", defaults.getEnterpriseHeroSize()));
        config.set(AiUiConfig.K_ENTERPRISE_READONLY_NOTICE, text(req, "enterpriseReadonlyNotice", defaults.getEnterpriseReadonlyNotice()));
        config.set(AiUiConfig.K_ENTERPRISE_CHAT_TITLE, text(req, "enterpriseChatTitle", defaults.getEnterpriseChatTitle()));
        config.set(AiUiConfig.K_ENTERPRISE_CHAT_HINT, text(req, "enterpriseChatHint", defaults.getEnterpriseChatHint()));
        config.set(AiUiConfig.K_ENTERPRISE_CHAT_BADGE, text(req, "enterpriseChatBadge", defaults.getEnterpriseChatBadge()));
        config.set(AiUiConfig.K_ENTERPRISE_WELCOME, text(req, "enterpriseWelcome", defaults.getEnterpriseWelcome()));
        config.set(AiUiConfig.K_ENTERPRISE_PLACEHOLDER, text(req, "enterprisePlaceholder", defaults.getEnterprisePlaceholder()));
        config.set(AiUiConfig.K_ENTERPRISE_SEND_BUTTON, text(req, "enterpriseSendButton", defaults.getEnterpriseSendButton()));
        config.set(AiUiConfig.K_ENTERPRISE_PRESET_TITLE, text(req, "enterprisePresetTitle", defaults.getEnterprisePresetTitle()));
        config.set(AiUiConfig.K_ENTERPRISE_PRESET_HINT, text(req, "enterprisePresetHint", defaults.getEnterprisePresetHint()));
        config.set(AiUiConfig.K_ENTERPRISE_PRESET_BADGE, text(req, "enterprisePresetBadge", defaults.getEnterprisePresetBadge()));

        config.set(AiUiConfig.K_KNOWLEDGE_TITLE, text(req, "knowledgeTitle", defaults.getKnowledgeTitle()));
        config.set(AiUiConfig.K_KNOWLEDGE_HERO_DESCRIPTION, text(req, "knowledgeHeroDescription", defaults.getKnowledgeHeroDescription()));
        config.set(AiUiConfig.K_KNOWLEDGE_HERO_BADGE, text(req, "knowledgeHeroBadge", defaults.getKnowledgeHeroBadge()));
        config.set(AiUiConfig.K_KNOWLEDGE_HERO_FROM, text(req, "knowledgeHeroFrom", defaults.getKnowledgeHeroFrom()));
        config.set(AiUiConfig.K_KNOWLEDGE_HERO_TO, text(req, "knowledgeHeroTo", defaults.getKnowledgeHeroTo()));
        config.set(AiUiConfig.K_KNOWLEDGE_HERO_TEXT, text(req, "knowledgeHeroText", defaults.getKnowledgeHeroText()));
        config.set(AiUiConfig.K_KNOWLEDGE_HERO_SIZE, text(req, "knowledgeHeroSize", defaults.getKnowledgeHeroSize()));
        config.set(AiUiConfig.K_KNOWLEDGE_READONLY_NOTICE, text(req, "knowledgeReadonlyNotice", defaults.getKnowledgeReadonlyNotice()));
        config.set(AiUiConfig.K_KNOWLEDGE_CARD_TITLE, text(req, "knowledgeCardTitle", defaults.getKnowledgeCardTitle()));
        config.set(AiUiConfig.K_KNOWLEDGE_CARD_HINT, text(req, "knowledgeCardHint", defaults.getKnowledgeCardHint()));
        config.set(AiUiConfig.K_KNOWLEDGE_CARD_BADGE, text(req, "knowledgeCardBadge", defaults.getKnowledgeCardBadge()));
        config.set(AiUiConfig.K_KNOWLEDGE_WELCOME, text(req, "knowledgeWelcome", defaults.getKnowledgeWelcome()));
        config.set(AiUiConfig.K_KNOWLEDGE_PLACEHOLDER, text(req, "knowledgePlaceholder", defaults.getKnowledgePlaceholder()));
        config.set(AiUiConfig.K_KNOWLEDGE_SEND_BUTTON, text(req, "knowledgeSendButton", defaults.getKnowledgeSendButton()));
        config.set(AiUiConfig.K_KNOWLEDGE_VIEW_ACTION, text(req, "knowledgeViewAction", defaults.getKnowledgeViewAction()));
        config.set(AiUiConfig.K_KNOWLEDGE_DOWNLOAD_ACTION, text(req, "knowledgeDownloadAction", defaults.getKnowledgeDownloadAction()));

        config.setTabs(readTabs(req));
        return config;
    }

    private List<AiUiTab> readTabs(HttpServletRequest req) {
        String[] labels = req.getParameterValues("tabLabel");
        String[] hrefs = req.getParameterValues("tabHref");
        String[] targets = req.getParameterValues("tabTarget");
        String[] activeKeys = req.getParameterValues("tabActiveKey");
        String[] visibles = req.getParameterValues("tabVisible");

        List<AiUiTab> tabs = new ArrayList<>();
        int count = labels == null ? 0 : labels.length;
        for (int i = 0; i < count; i++) {
            String label = trim(at(labels, i));
            String href = trim(at(hrefs, i));
            if (label.isEmpty() && href.isEmpty()) {
                continue;
            }
            String target = trim(at(targets, i));
            String activeKey = trim(at(activeKeys, i));
            String visible = trim(at(visibles, i));
            AiUiTab tab = new AiUiTab(
                    label,
                    href,
                    TAB_TARGETS.contains(target) ? target : "_self",
                    ACTIVE_KEYS.contains(activeKey) ? activeKey : "",
                    tabs.size(),
                    !"0".equals(visible)
            );
            tabs.add(tab);
        }
        return tabs;
    }

    private List<String> validate(AiUiConfig config) {
        List<String> errors = new ArrayList<>();
        requireText(errors, "企業AI 頁面標題", config.getEnterpriseTitle(), 100);
        requireText(errors, "企業AI 對話卡標題", config.getEnterpriseChatTitle(), 100);
        requireText(errors, "企業AI 快速測試標題", config.getEnterprisePresetTitle(), 100);
        requireText(errors, "企業AI 送出按鈕", config.getEnterpriseSendButton(), 30);
        requireText(errors, "AI 知識庫頁面標題", config.getKnowledgeTitle(), 100);
        requireText(errors, "AI 知識庫卡片標題", config.getKnowledgeCardTitle(), 100);
        requireText(errors, "AI 知識庫送出按鈕", config.getKnowledgeSendButton(), 30);
        requireText(errors, "AI 知識庫查看內容按鈕", config.getKnowledgeViewAction(), 30);
        requireText(errors, "AI 知識庫文件下載按鈕", config.getKnowledgeDownloadAction(), 30);

        checkLength(errors, "企業AI Hero 描述", config.getEnterpriseHeroDescription(), 2000);
        checkLength(errors, "企業AI Hero 標籤", config.getEnterpriseHeroBadge(), 80);
        checkLength(errors, "企業AI 對話提示", config.getEnterpriseChatHint(), 1000);
        checkLength(errors, "企業AI 歡迎詞", config.getEnterpriseWelcome(), 2000);
        checkLength(errors, "企業AI 輸入提示", config.getEnterprisePlaceholder(), 300);
        checkLength(errors, "企業AI 快速測試提示", config.getEnterprisePresetHint(), 1000);
        checkLength(errors, "企業AI 唯讀提示", config.getEnterpriseReadonlyNotice(), 1000);
        checkLength(errors, "AI 知識庫 Hero 描述", config.getKnowledgeHeroDescription(), 2000);
        checkLength(errors, "AI 知識庫 Hero 標籤", config.getKnowledgeHeroBadge(), 80);
        checkLength(errors, "AI 知識庫卡片提示", config.getKnowledgeCardHint(), 1000);
        checkLength(errors, "AI 知識庫歡迎詞", config.getKnowledgeWelcome(), 2000);
        checkLength(errors, "AI 知識庫輸入提示", config.getKnowledgePlaceholder(), 300);
        checkLength(errors, "AI 知識庫唯讀提示", config.getKnowledgeReadonlyNotice(), 1000);

        String rawPageWidth = config.get(AiUiConfig.K_PAGE_WIDTH).trim().toLowerCase(Locale.ROOT);
        if (!PAGE_WIDTHS.contains(rawPageWidth)) {
            errors.add("頁面寬度格式不正確");
        }
        String rawEnterpriseHeroSize = config.get(AiUiConfig.K_ENTERPRISE_HERO_SIZE).trim().toLowerCase(Locale.ROOT);
        if (!HERO_SIZES.contains(rawEnterpriseHeroSize)) {
            errors.add("企業AI Hero 大小格式不正確");
        }
        String rawKnowledgeHeroSize = config.get(AiUiConfig.K_KNOWLEDGE_HERO_SIZE).trim().toLowerCase(Locale.ROOT);
        if (!HERO_SIZES.contains(rawKnowledgeHeroSize)) {
            errors.add("AI 知識庫 Hero 大小格式不正確");
        }
        validateColor(errors, "企業AI Hero 起始色", config.get(AiUiConfig.K_ENTERPRISE_HERO_FROM));
        validateColor(errors, "企業AI Hero 結束色", config.get(AiUiConfig.K_ENTERPRISE_HERO_TO));
        validateColor(errors, "企業AI Hero 文字色", config.get(AiUiConfig.K_ENTERPRISE_HERO_TEXT));
        validateColor(errors, "AI 知識庫 Hero 起始色", config.get(AiUiConfig.K_KNOWLEDGE_HERO_FROM));
        validateColor(errors, "AI 知識庫 Hero 結束色", config.get(AiUiConfig.K_KNOWLEDGE_HERO_TO));
        validateColor(errors, "AI 知識庫 Hero 文字色", config.get(AiUiConfig.K_KNOWLEDGE_HERO_TEXT));

        List<AiUiTab> tabs = config.getTabs();
        if (tabs.isEmpty()) {
            errors.add("請至少保留一個頁籤");
        } else if (tabs.size() > MAX_TABS) {
            errors.add("頁籤最多 " + MAX_TABS + " 個");
        }
        for (int i = 0; i < tabs.size(); i++) {
            AiUiTab tab = tabs.get(i);
            int row = i + 1;
            requireText(errors, "第 " + row + " 個頁籤名稱", tab.getLabel(), 80);
            requireText(errors, "第 " + row + " 個頁籤連結", tab.getHref(), 255);
            if (!isSafeHref(tab.getHref())) {
                errors.add("第 " + row + " 個頁籤連結只允許站內相對路徑");
            }
        }
        return errors;
    }

    private void requireText(List<String> errors, String label, String value, int max) {
        if (value == null || value.isBlank()) {
            errors.add(label + "不可空白");
            return;
        }
        checkLength(errors, label, value, max);
    }

    private void checkLength(List<String> errors, String label, String value, int max) {
        if (value != null && value.length() > max) {
            errors.add(label + "不可超過 " + max + " 字");
        }
    }

    private void validateColor(List<String> errors, String label, String value) {
        if (value == null || !value.matches("^#[0-9a-fA-F]{6}$")) {
            errors.add(label + "需為 #RRGGBB 格式");
        }
    }

    private boolean isSafeHref(String href) {
        if (href == null || href.isBlank() || href.length() > 255) {
            return false;
        }
        String lower = href.toLowerCase(Locale.ROOT);
        if (lower.startsWith("//") || lower.startsWith("javascript:") || lower.startsWith("data:")) {
            return false;
        }
        if (href.contains("..") || href.contains("\\") || href.contains("\r") || href.contains("\n")) {
            return false;
        }
        return !lower.matches("^[a-z][a-z0-9+.-]*:.*");
    }

    private String text(HttpServletRequest req, String name, String defaultValue) {
        String value = req.getParameter(name);
        return value == null ? defaultValue : value.trim();
    }

    private String at(String[] values, int index) {
        return values != null && index < values.length ? values[index] : "";
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private boolean requireAdmin(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        Object user = session == null ? null : session.getAttribute("user");
        Object readOnly = session == null ? null : session.getAttribute("readOnly");
        if (user instanceof User u
                && "admin".equalsIgnoreCase(u.getRole())
                && !Boolean.TRUE.equals(readOnly)) {
            return true;
        }
        resp.sendError(HttpServletResponse.SC_FORBIDDEN, "僅限管理員使用");
        return false;
    }

    private int userId(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        Object user = session == null ? null : session.getAttribute("user");
        return user instanceof User u ? u.getId() : 0;
    }

    private String username(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        Object user = session == null ? null : session.getAttribute("user");
        return user instanceof User u ? u.getUsername() : "unknown";
    }

    private void redirectWithMessage(HttpServletRequest req, HttpServletResponse resp, String message)
            throws IOException {
        String encoded = URLEncoder.encode(message, StandardCharsets.UTF_8);
        resp.sendRedirect(req.getContextPath() + "/AiUiAdminServlet?message=" + encoded);
    }
}
