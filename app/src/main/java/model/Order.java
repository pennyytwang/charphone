package model;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.Date;

public class Order {
    private int id;
    private int customerId;
    private String customerName;
    private String orderNumber;
    private int productId;
    private String productName;
    private int priceType;
    private BigDecimal unitPrice;
    private BigDecimal unitWeight;
    private BigDecimal quantity;
    private BigDecimal totalAmount;
    private BigDecimal actualAmount;
    private String amountDiffReason;
    private Date orderDate;
    private Date deliveryDate;
    private Date expectedDeliveryDate;
    private int status;
    private int closeStatus;
    private String note;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    private BigDecimal invoicedSum;

    public Order() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getCustomerId() { return customerId; }
    public void setCustomerId(int customerId) { this.customerId = customerId; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getOrderNumber() { return orderNumber; }
    public void setOrderNumber(String orderNumber) { this.orderNumber = orderNumber; }

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

    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }

    public BigDecimal getActualAmount() { return actualAmount; }
    public void setActualAmount(BigDecimal actualAmount) { this.actualAmount = actualAmount; }

    public String getAmountDiffReason() { return amountDiffReason; }
    public void setAmountDiffReason(String amountDiffReason) { this.amountDiffReason = amountDiffReason; }

    public Date getOrderDate() { return orderDate; }
    public void setOrderDate(Date orderDate) { this.orderDate = orderDate; }

    public Date getDeliveryDate() { return deliveryDate; }
    public void setDeliveryDate(Date deliveryDate) { this.deliveryDate = deliveryDate; }

    public Date getExpectedDeliveryDate() { return expectedDeliveryDate; }
    public void setExpectedDeliveryDate(Date expectedDeliveryDate) { this.expectedDeliveryDate = expectedDeliveryDate; }

    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }

    public int getCloseStatus() { return closeStatus; }
    public void setCloseStatus(int closeStatus) { this.closeStatus = closeStatus; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }

    public BigDecimal getInvoicedSum() { return invoicedSum; }
    public void setInvoicedSum(BigDecimal invoicedSum) { this.invoicedSum = invoicedSum; }
}
