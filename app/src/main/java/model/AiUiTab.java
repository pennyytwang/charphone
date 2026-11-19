package model;

/**
 * 企業AI 頁面的可設定頁籤。
 */
public class AiUiTab {

    private int id;
    private String label;
    private String href;
    private String target;
    private String activeKey;
    private int sortOrder;
    private boolean visible;

    public AiUiTab() {
    }

    public AiUiTab(String label, String href, String target, String activeKey, int sortOrder, boolean visible) {
        this.label = label;
        this.href = href;
        this.target = target;
        this.activeKey = activeKey;
        this.sortOrder = sortOrder;
        this.visible = visible;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public String getHref() {
        return href;
    }

    public void setHref(String href) {
        this.href = href;
    }

    public String getTarget() {
        return target;
    }

    public void setTarget(String target) {
        this.target = target;
    }

    public String getActiveKey() {
        return activeKey;
    }

    public void setActiveKey(String activeKey) {
        this.activeKey = activeKey;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(int sortOrder) {
        this.sortOrder = sortOrder;
    }

    public boolean isVisible() {
        return visible;
    }

    public void setVisible(boolean visible) {
        this.visible = visible;
    }
}
