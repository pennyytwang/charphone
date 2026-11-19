-- =====================================================================
-- CharPhone 訂單管理系統 - 資料庫結構（schema only）
-- =====================================================================

-- =====================================================================
-- 1. 使用者管理表
-- =====================================================================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) DEFAULT NULL,
    display_name VARCHAR(100) DEFAULT NULL,
    role VARCHAR(20) DEFAULT 'user',
    email VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 2. 客戶管理表
-- =====================================================================
CREATE TABLE IF NOT EXISTS customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_number VARCHAR(20) DEFAULT NULL,
    customer_name VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    tax_id VARCHAR(20),
    contact_person VARCHAR(50),
    address VARCHAR(200),
    delivery_address VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uk_customer_number UNIQUE (customer_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_customer_number ON customers (customer_number);

-- =====================================================================
-- 3. 產品管理表
-- =====================================================================
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_code VARCHAR(50) UNIQUE,
    product_name VARCHAR(100) NOT NULL,
    price_type INT DEFAULT 1,
    unit_weight DECIMAL(10, 3),
    unit_price DECIMAL(10, 2),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 4. 訂單表
-- =====================================================================
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    product_id INT NOT NULL,
    price_type INT DEFAULT 1,
    unit_price DECIMAL(10, 2),
    unit_weight DECIMAL(10, 3),
    quantity DECIMAL(10, 3) NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL,
    order_date DATE NOT NULL,
    delivery_date DATE,
    expected_delivery_date DATE,
    actual_amount DECIMAL(12, 2),
    amount_diff_reason TEXT,
    status INT DEFAULT 0,
    close_status TINYINT DEFAULT 0 COMMENT '0=未結案 1=已結案',
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 5. 應收帳款表
-- =====================================================================
CREATE TABLE IF NOT EXISTS invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_id INT NOT NULL,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    amount DECIMAL(12, 2) NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE,
    status INT DEFAULT 0,
    payment_status TINYINT DEFAULT 0 COMMENT '0=未收款 1=已收款',
    payment_date DATE DEFAULT NULL COMMENT '收款日期',
    received_amount DECIMAL(12,2) DEFAULT NULL COMMENT '實收金額',
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 6. 生產排程表
-- =====================================================================
CREATE TABLE IF NOT EXISTS productions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    production_number VARCHAR(50) NOT NULL UNIQUE,
    product_id INT NOT NULL,
    price_type INT DEFAULT 1,
    unit_price DECIMAL(10, 2),
    unit_weight DECIMAL(10, 3),
    quantity DECIMAL(10, 3) NOT NULL,
    produced_qty DECIMAL(10, 3) DEFAULT 0,
    manufactured_qty DECIMAL(10, 3) DEFAULT 0,
    status INT DEFAULT 0,
    close_status INT DEFAULT 0,
    start_date DATE,
    target_date DATE,
    completed_date DATE,
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE RESTRICT,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 7. 出貨/送貨表
-- =====================================================================
CREATE TABLE IF NOT EXISTS deliveries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    delivery_number VARCHAR(50) NOT NULL UNIQUE,
    delivery_date DATE NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL,
    status INT DEFAULT 1,
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 8. 倉庫表
-- =====================================================================
CREATE TABLE IF NOT EXISTS warehouses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_code VARCHAR(20) NOT NULL UNIQUE,
    warehouse_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(50),
    phone VARCHAR(30),
    address VARCHAR(200),
    status INT DEFAULT 1,
    note TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 9. 庫存項目表
-- =====================================================================
CREATE TABLE IF NOT EXISTS inventory_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_code VARCHAR(50) NOT NULL UNIQUE,
    item_name VARCHAR(100) NOT NULL,
    item_type INT NOT NULL DEFAULT 1,
    product_id INT DEFAULT NULL,
    unit VARCHAR(10) NOT NULL DEFAULT 'pcs',
    unit_cost DECIMAL(12, 2) DEFAULT 0,
    safety_stock DECIMAL(10, 3) DEFAULT 0,
    status INT DEFAULT 1,
    note TEXT,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 10. 庫存統計表
-- =====================================================================
CREATE TABLE IF NOT EXISTS inventory_stock (
    id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (item_id) REFERENCES inventory_items(id) ON DELETE RESTRICT,
    UNIQUE KEY uk_wh_item (warehouse_id, item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 11. 庫存交易日誌表
-- =====================================================================
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_number VARCHAR(50) NOT NULL UNIQUE,
    warehouse_id INT NOT NULL,
    item_id INT NOT NULL,
    transaction_type INT NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL,
    balance_before DECIMAL(10, 3) NOT NULL,
    balance_after DECIMAL(10, 3) NOT NULL,
    ref_type VARCHAR(30) DEFAULT NULL,
    ref_id INT DEFAULT NULL,
    order_id INT DEFAULT NULL,
    production_id INT DEFAULT NULL,
    note TEXT,
    created_by INT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (item_id) REFERENCES inventory_items(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 初始化資料
-- =====================================================================

-- 第一位管理員由 Flyway placeholder 注入 BCrypt 雜湊；未提供 ADMIN_PASSWORD 時為停用值。
INSERT INTO users (username, password, display_name, role)
SELECT 'admin', '${adminPasswordHash}', '系統管理員', 'admin'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');
