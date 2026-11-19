package model;

import java.math.BigDecimal;

public class InventoryItem {
    private int id;
    private String itemCode;
    private String itemName;
    private int itemType;
    private Integer productId;
    private String productName;
    private String unit;
    private BigDecimal unitCost;
    private BigDecimal safetyStock;
    private int status;
    private String note;

    public InventoryItem() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getItemCode() { return itemCode; }
    public void setItemCode(String itemCode) { this.itemCode = itemCode; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public int getItemType() { return itemType; }
    public void setItemType(int itemType) { this.itemType = itemType; }

    public Integer getProductId() { return productId; }
    public void setProductId(Integer productId) { this.productId = productId; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }

    public BigDecimal getUnitCost() { return unitCost; }
    public void setUnitCost(BigDecimal unitCost) { this.unitCost = unitCost; }

    public BigDecimal getSafetyStock() { return safetyStock; }
    public void setSafetyStock(BigDecimal safetyStock) { this.safetyStock = safetyStock; }

    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
