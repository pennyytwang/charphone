package model;

import java.math.BigDecimal;
import java.util.Date;

public class Invoice {
    private int id;
    private int customerId;
    private String customerName;
    private int orderId;
    private String orderNumber;
    private String invoiceNumber;
    private BigDecimal amount;
    private Date issueDate;
    private Date dueDate;
    private int status;
    private int paymentStatus;
    private Date paymentDate;
    private BigDecimal receivedAmount;
    private String note;

    public Invoice() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getCustomerId() { return customerId; }
    public void setCustomerId(int customerId) { this.customerId = customerId; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }

    public String getOrderNumber() { return orderNumber; }
    public void setOrderNumber(String orderNumber) { this.orderNumber = orderNumber; }

    public String getInvoiceNumber() { return invoiceNumber; }
    public void setInvoiceNumber(String invoiceNumber) { this.invoiceNumber = invoiceNumber; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public Date getIssueDate() { return issueDate; }
    public void setIssueDate(Date issueDate) { this.issueDate = issueDate; }

    public Date getDueDate() { return dueDate; }
    public void setDueDate(Date dueDate) { this.dueDate = dueDate; }

    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }

    public int getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(int paymentStatus) { this.paymentStatus = paymentStatus; }

    public Date getPaymentDate() { return paymentDate; }
    public void setPaymentDate(Date paymentDate) { this.paymentDate = paymentDate; }

    public BigDecimal getReceivedAmount() { return receivedAmount; }
    public void setReceivedAmount(BigDecimal receivedAmount) { this.receivedAmount = receivedAmount; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}