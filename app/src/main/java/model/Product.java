package model;

import java.math.BigDecimal;

public class Product {
    private int id;
    private String productCode;   // 產品編號
    private String productName;   // 產品名稱
    private int priceType;        // 1: 按重量, 2: 按個數
    private BigDecimal unitWeight; // 單個重量 (kg)
    private BigDecimal unitPrice;  // 代工單價
    private String description;    // 備註

    public Product() {}

    // Getters and Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getProductCode() { return productCode; }
    public void setProductCode(String productCode) { this.productCode = productCode; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public int getPriceType() { return priceType; }
    public void setPriceType(int priceType) { this.priceType = priceType; }

    public BigDecimal getUnitWeight() { return unitWeight; }
    public void setUnitWeight(BigDecimal unitWeight) { this.unitWeight = unitWeight; }

    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}

