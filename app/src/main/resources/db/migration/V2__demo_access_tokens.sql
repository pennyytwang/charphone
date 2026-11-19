-- =====================================================================
-- V2: 使用者生命週期 + 存取 token + 登入稽核
-- =====================================================================

ALTER TABLE users
    ADD COLUMN account_type VARCHAR(20) NOT NULL DEFAULT 'normal' COMMENT 'normal / temporary',
    ADD COLUMN expires_at DATETIME NULL COMMENT '暫時帳號到期時間',
    ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1=啟用 0=停用',
    ADD COLUMN read_only TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1=全站唯讀',
    ADD COLUMN created_by INT NULL COMMENT '建立者 user id',
    ADD INDEX idx_users_expires (expires_at);

CREATE TABLE IF NOT EXISTS access_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token_hash CHAR(64) NOT NULL COMMENT 'SHA-256/HMAC hex，不存明文',
    token_hint VARCHAR(20) NOT NULL COMMENT '顯示用，例如 cp_ab12…9f3c',
    label VARCHAR(100) NOT NULL COMMENT '用途，例如 104 面試官-王先生',
    scopes VARCHAR(100) NOT NULL DEFAULT 'read_only',
    expires_at DATETIME NOT NULL,
    max_uses INT NULL COMMENT 'NULL=不限次數',
    used_count INT NOT NULL DEFAULT 0,
    last_used_at DATETIME NULL,
    last_used_ip VARCHAR(45) NULL,
    revoked_at DATETIME NULL,
    created_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_access_token_hash (token_hash),
    KEY idx_access_token_user (user_id),
    KEY idx_access_token_expires (expires_at),
    CONSTRAINT fk_access_token_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS login_audit (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    attempted_username VARCHAR(50) NULL,
    token_hint VARCHAR(20) NULL,
    auth_method VARCHAR(20) NOT NULL COMMENT 'password / token',
    result VARCHAR(20) NOT NULL COMMENT 'success / failed',
    reason VARCHAR(100) NULL,
    ip VARCHAR(45) NULL,
    user_agent VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_login_audit_created (created_at),
    KEY idx_login_audit_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
