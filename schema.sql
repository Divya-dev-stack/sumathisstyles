-- ============================================================
-- Sumathi's Style - Database Schema
-- Generated from db.php + manage_coins.php
-- ============================================================

CREATE DATABASE IF NOT EXISTS `product_db`;
USE `product_db`;

-- 1. PRODUCTS
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) DEFAULT '',
    price DECIMAL(10,2) DEFAULT 0,
    description TEXT,
    stock VARCHAR(50) DEFAULT 'Available',
    visible TINYINT(1) DEFAULT 1,
    photo VARCHAR(500) DEFAULT '',
    photos TEXT,
    highlights TEXT,
    price_tags TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    type VARCHAR(50) DEFAULT 'general',
    target_phone VARCHAR(20) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. ORDERS
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    mobile VARCHAR(20) DEFAULT '',
    product VARCHAR(255) DEFAULT '',
    amount DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'Ordered',
    notes TEXT,
    source VARCHAR(100) DEFAULT 'website',
    measurement TEXT,
    voice_note LONGTEXT,
    order_id VARCHAR(30) DEFAULT '',
    cancel_reason TEXT,
    payment_method VARCHAR(30) DEFAULT '',
    payment_status VARCHAR(30) DEFAULT 'Not Required',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. REVIEWS
CREATE TABLE IF NOT EXISTS reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    rating INT DEFAULT 5,
    review_text TEXT,
    source VARCHAR(100) DEFAULT 'website',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. CONTACTS
CREATE TABLE IF NOT EXISTS contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) DEFAULT '',
    email VARCHAR(255) DEFAULT '',
    service VARCHAR(255) DEFAULT '',
    message TEXT,
    source VARCHAR(100) DEFAULT 'website',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. DATA EXPORT REQUESTS
CREATE TABLE IF NOT EXISTS data_export_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) DEFAULT '',
    phone VARCHAR(20) DEFAULT '',
    email VARCHAR(255) DEFAULT '',
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. DATA REQUESTS (Privacy Center)
CREATE TABLE IF NOT EXISTS data_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) DEFAULT '',
    phone VARCHAR(20) DEFAULT '',
    email VARCHAR(255) DEFAULT '',
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. CONSENTS (Privacy Center)
CREATE TABLE IF NOT EXISTS consents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    consent_marketing TINYINT(1) DEFAULT 0,
    consent_order_notif TINYINT(1) DEFAULT 0,
    consent_location TINYINT(1) DEFAULT 0,
    consent_analytics TINYINT(1) DEFAULT 0,
    consent_whatsapp TINYINT(1) DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. GRIEVANCES
CREATE TABLE IF NOT EXISTS grievances (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) DEFAULT '',
    phone VARCHAR(20) DEFAULT '',
    email VARCHAR(255) DEFAULT '',
    subject VARCHAR(255) DEFAULT '',
    order_id VARCHAR(50) DEFAULT '',
    description TEXT,
    status VARCHAR(30) DEFAULT 'Open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. DEACTIVATED ACCOUNTS
CREATE TABLE IF NOT EXISTS deactivated_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    reason TEXT,
    deactivated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. DELETED ACCOUNTS
CREATE TABLE IF NOT EXISTS deleted_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 12. CUSTOMER COINS (Sumathi Style Coins - loyalty balance)
-- Used by manage_coins.php, not auto-created by db.php
CREATE TABLE IF NOT EXISTS customer_coins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mobile VARCHAR(20) NOT NULL,
    balance INT DEFAULT 0,
    UNIQUE KEY unique_mobile (mobile)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 13. COINS LEDGER (earn/redeem history)
-- Used by manage_coins.php, not auto-created by db.php
CREATE TABLE IF NOT EXISTS coins_ledger (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mobile VARCHAR(20) NOT NULL,
    order_id VARCHAR(30) DEFAULT '',
    type VARCHAR(10) NOT NULL, -- 'earn' or 'redeem'
    coins INT NOT NULL,
    order_amount DECIMAL(10,2) DEFAULT 0,
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;