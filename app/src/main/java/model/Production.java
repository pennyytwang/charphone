package model;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.Date;

public class Production {
    private int id;
    private int orderId;
    private String orderNumber;
    private String customerName;
    private String productionNumber;
    private int productId;
    private String productName;
    private int priceType;
    private BigDecimal unitPrice;
    private BigDecimal unitWeight;
    private BigDecimal quantity;
    private BigDecimal producedQty;
    private BigDecimal manufacturedQty;
    private BigDecimal orderQuantity;
    private int status;
    private int closeStatus;
    private Date startDate;
    private Date targetDate;
    private Date completedDate;
    private String note;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    public Production() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }

    public String getOrderNumber() { return orderNumber; }
    public void setOrderNumber(String orderNumber) { this.orderNumber = orderNumber; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getProductionNumber() { return productionNumber; }
    public void setProductionNumber(String productionNumber) { this.productionNumber = productionNumber; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public int getPriceType() { return priceType; }
    public void setPriceType(int priceType) { this.priceType = priceType; }

    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }

    public BigDecimal getUnitWeight() { return unitWeight; }
    public void setUnitWeight(BigDecimal unitWeight) { this.unitWeight = unitWeight; }

    public BigDecimal getQuantity() { return quantity; }
    public void setQuantity(BigDecimal quantity) { this.quantity = quantity; }

    public BigDecimal getProducedQty() { return producedQty; }
    public void setProducedQty(BigDecimal producedQty) { this.producedQty = producedQty; }

    public BigDecimal getManufacturedQty() { return manufacturedQty; }
    public void setManufacturedQty(BigDecimal manufacturedQty) { this.manufacturedQty = manufacturedQty; }

    public BigDecimal getOrderQuantity() { return orderQuantity; }
    public void setOrderQuantity(BigDecimal orderQuantity) { this.orderQuantity = orderQuantity; }

    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }

    public int getCloseStatus() { return closeStatus; }
    public void setCloseStatus(int closeStatus) { this.closeStatus = closeStatus; }

    public Date getStartDate() { return startDate; }
    public void setStartDate(Date startDate) { this.startDate = startDate; }

    public Date getTargetDate() { return targetDate; }
    public void setTargetDate(Date targetDate) { this.targetDate = targetDate; }

    public Date getCompletedDate() { return completedDate; }
    public void setCompletedDate(Date completedDate) { this.completedDate = completedDate; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }
}
