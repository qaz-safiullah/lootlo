-- ==========================================
-- LOOTLO MARKETPLACE DATABASE INITIALIZATION
-- ==========================================

-- Create and select the database
CREATE DATABASE IF NOT EXISTS lootlo_db;
USE lootlo_db;

-- ------------------------------------------
-- 1. USERS TABLE
-- ------------------------------------------
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    community_score INT DEFAULT 0,
    lat DECIMAL(10, 8),
    lng DECIMAL(11, 8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------
-- 2. ITEMS TABLE
-- ------------------------------------------
CREATE TABLE items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    city VARCHAR(100),
    address VARCHAR(255),
    phone VARCHAR(20), -- Directly included in initial layout
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    status ENUM('draft', 'available', 'promised', 'completed') DEFAULT 'available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ------------------------------------------
-- 3. ITEM IMAGES TABLE
-- ------------------------------------------
CREATE TABLE item_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    is_main BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
);

-- ------------------------------------------
-- 4. REQUESTS TABLE (With Dual-Confirmation)
-- ------------------------------------------
CREATE TABLE requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    requester_id INT NOT NULL,
    status ENUM('pending', 'proposed', 'accepted', 'rejected', 'completed') DEFAULT 'pending',
    proposed_time DATETIME,
    giver_confirmed BOOLEAN DEFAULT FALSE,
    taker_confirmed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
    FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ------------------------------------------
-- 5. SAVED ITEMS TABLE
-- ------------------------------------------
CREATE TABLE saved_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    item_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_save (user_id, item_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
);

-- ==========================================
-- UTILITY & VERIFICATION QUERIES
-- ==========================================
-- Un-comment these lines to verify data state during development:

-- SELECT * FROM users;
-- SELECT * FROM items;
-- SELECT * FROM item_images;
-- SELECT * FROM requests;
-- SELECT * FROM saved_items;