package model;

import java.math.BigDecimal;

public class InventoryTransaction {
    private int id;
    private String transactionNumber;
    private int warehouseId;
    private String warehouseName;
    private int itemId;
    private String itemCode;
    private String itemName;
    private int transactionType;
    private BigDecimal quantity;
    private BigDecimal balanceBefore;
    private BigDecimal balanceAfter;
    private String refType;
    private Integer refId;
    private Integer orderId;
    private Integer productionId;
    private String orderNumber;
    private String productionNumber;
    private String note;
    private Integer createdBy;
    private String createdAt;

    public InventoryTransaction() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getTransactionNumber() { return transactionNumber; }
    public void setTransactionNumber(String transactionNumber) { this.transactionNumber = transactionNumber; }

    public int getWarehouseId() { return warehouseId; }
    public void setWarehouseId(int warehouseId) { this.warehouseId = warehouseId; }

    public String getWarehouseName() { return warehouseName; }
    public void setWarehouseName(String warehouseName) { this.warehouseName = warehouseName; }

    public int getItemId() { return itemId; }
    public void setItemId(int itemId) { this.itemId = itemId; }

    public String getItemCode() { return itemCode; }
    public void setItemCode(String itemCode) { this.itemCode = itemCode; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public int getTransactionType() { return transactionType; }
    public void setTransactionType(int transactionType) { this.transactionType = transactionType; }

    public BigDecimal getQuantity() { return quantity; }
    public void setQuantity(BigDecimal quantity) { this.quantity = quantity; }

    public BigDecimal getBalanceBefore() { return balanceBefore; }
    public void setBalanceBefore(BigDecimal balanceBefore) { this.balanceBefore = balanceBefore; }

    public BigDecimal getBalanceAfter() { return balanceAfter; }
    public void setBalanceAfter(BigDecimal balanceAfter) { this.balanceAfter = balanceAfter; }

    public String getRefType() { return refType; }
    public void setRefType(String refType) { this.refType = refType; }

    public Integer getRefId() { return refId; }
    public void setRefId(Integer refId) { this.refId = refId; }

    public Integer getOrderId() { return orderId; }
    public void setOrderId(Integer orderId) { this.orderId = orderId; }

    public Integer getProductionId() { return productionId; }
    public void setProductionId(Integer productionId) { this.productionId = productionId; }

    public String getOrderNumber() { return orderNumber; }
    public void setOrderNumber(String orderNumber) { this.orderNumber = orderNumber; }

    public String getProductionNumber() { return productionNumber; }
    public void setProductionNumber(String productionNumber) { this.productionNumber = productionNumber; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public Integer getCreatedBy() { return createdBy; }
    public void setCreatedBy(Integer createdBy) { this.createdBy = createdBy; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
}
