package model;

import java.math.BigDecimal;
import java.util.Date;

public class Delivery {
    private int id;
    private int orderId;
    private String orderNumber;
    private String customerName;
    private String deliveryNumber;
    private Date deliveryDate;
    private BigDecimal quantity;
    private int status;
    private String note;

    public Delivery() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }

    public String getOrderNumber() { return orderNumber; }
    public void setOrderNumber(String orderNumber) { this.orderNumber = orderNumber; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getDeliveryNumber() { return deliveryNumber; }
    public void setDeliveryNumber(String deliveryNumber) { this.deliveryNumber = deliveryNumber; }

    public Date getDeliveryDate() { return deliveryDate; }
    public void setDeliveryDate(Date deliveryDate) { this.deliveryDate = deliveryDate; }

    public BigDecimal getQuantity() { return quantity; }
    public void setQuantity(BigDecimal quantity) { this.quantity = quantity; }

    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}