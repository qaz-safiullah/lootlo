-- ==========================================
-- LOOTLO MARKETPLACE: MASTER INITIALIZATION
-- ==========================================

DROP DATABASE IF EXISTS lootlo_db;
CREATE DATABASE lootlo_db;
USE lootlo_db;

-- ==========================================
-- 1. SCHEMA DEFINITION
-- ==========================================

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    community_score INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    city VARCHAR(100),
    address VARCHAR(255),
    phone VARCHAR(20),
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    status ENUM('draft', 'available', 'promised', 'completed') DEFAULT 'available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE item_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    is_main BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
);

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

ALTER TABLE users ADD COLUMN phone VARCHAR(20) DEFAULT NULL;

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
-- 2. SEEDING USERS
-- ==========================================
-- Passwords are set to a generic $2b$10$... hash representing 'password123'

INSERT INTO users (id, name, email, password, community_score) VALUES
(1, 'Safiullah', 'safi@test.com', '$2b$10$K7Z2vOasl70vWb766DsmZ.mbeOqW6bXqbywBGr6PAnrZ4mGzP0rDG', 85),
(2, 'Rafay', 'rafay@test.com', '$2b$10$K7Z2vOasl70vWb766DsmZ.mbeOqW6bXqbywBGr6PAnrZ4mGzP0rDG', 120),
(3, 'Ayesha', 'ayesha@test.com', '$2b$10$K7Z2vOasl70vWb766DsmZ.mbeOqW6bXqbywBGr6PAnrZ4mGzP0rDG', 45),
(4, 'Bilal', 'bilal@test.com', '$2b$10$K7Z2vOasl70vWb766DsmZ.mbeOqW6bXqbywBGr6PAnrZ4mGzP0rDG', 10);

-- ==========================================
-- 3. SEEDING ITEMS (All Karachi, All Categories)
-- ==========================================

INSERT INTO items (id, user_id, title, description, category, city, address, phone, lat, lng, status) VALUES
-- Safiullah (User 1)
(1, 1, 'Mechanical Keyboard (Blue Switches)', 'Upgraded to a quiet keyboard for office work. Giving away my tactile mechanical keyboard.', 'Electronics', 'Karachi', 'DHA Phase 6, near Jasmine Commercial', '+923001234567', 24.7938, 67.0642, 'available'),
(2, 1, 'Solid Wood Coffee Table', 'Moving out sale leftover. Sturdy dark oak coffee table. Has a few light tea ring stains.', 'Furniture', 'Karachi', 'Gulshan-e-Iqbal, Block 4', '+923001234567', 24.9180, 67.0971, 'available'),

-- Rafay (User 2)
(3, 2, 'University Calculus Textbook', 'Thomas Calculus 14th Edition. Clean pages. Perfect for engineering or math freshmen.', 'Books', 'Karachi', 'Block H, North Nazimabad', '+923129876543', 24.9372, 67.0424, 'available'),
(4, 2, 'Winter Fleece Hoodie (Large)', 'Brand new oversized hoodie in Navy Blue. Never worn, tags still attached.', 'Clothing', 'Karachi', 'PECHS Block 6, near Nursery', '+923129876543', 24.8615, 67.0735, 'promised'),

-- Ayesha (User 3)
(5, 3, 'Pre-loved Toddler Building Blocks', 'A bucket of mixed mega blocks and LEGO duplicates. Great for kids aged 2-5.', 'Toys', 'Karachi', 'Alamgir Road, Bahadurabad', '+923334567890', 24.8824, 67.0674, 'available'),
(6, 3, 'Socket Wrench Set (12 Pieces)', 'Standard metrics socket wrench set. Missing the 10mm piece, but all others work perfectly.', 'Tools', 'Karachi', 'Regal Chowk, Saddar', '+923334567890', 24.8612, 67.0261, 'completed'),

-- Bilal (User 4) - Adding the missing categories!
(7, 4, 'Sohrab Vintage Bicycle', 'Old cycle sitting in the garage. Needs new tires and some chain oil, but the frame is solid.', 'Vehicles', 'Karachi', 'Malir Cantt, near Check Post 2', '+923451112223', 24.8933, 67.1864, 'available'),
(8, 4, 'Pair of 5kg Dumbbells', 'Used cast iron dumbbells. Great for a beginner home workout setup.', 'Other', 'Karachi', 'Korangi Crossing, Sector 31', '+923451112223', 24.8315, 67.1245, 'available');

-- ==========================================
-- 4. SEEDING ITEM IMAGES
-- ==========================================

INSERT INTO item_images (item_id, image_url, is_main) VALUES
(1, 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?q=80&w=600', TRUE),
(1, 'https://images.unsplash.com/photo-1618384887929-16ec33fab9ef?q=80&w=600', FALSE),
(2, 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?q=80&w=600', TRUE),
(3, 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=600', TRUE),
(4, 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?q=80&w=600', TRUE),
(5, 'https://images.unsplash.com/photo-1515488042361-404e9250afef?q=80&w=600', TRUE),
(6, 'https://images.unsplash.com/photo-1581244277943-fe4a9c777189?q=80&w=600', TRUE),
(7, 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?q=80&w=600', TRUE),
(8, 'https://images.unsplash.com/photo-1638536532686-fac8fa030f57?q=80&w=600', TRUE);

-- ==========================================
-- 5. SEEDING REQUESTS (Testing the flow)
-- ==========================================

INSERT INTO requests (item_id, requester_id, status, proposed_time, giver_confirmed, taker_confirmed) VALUES
-- Bilal requests Calculus book from Rafay (Pending)
(3, 4, 'pending', '2026-06-01 15:30:00', FALSE, FALSE),
-- Safiullah requested the Hoodie from Rafay (Accepted)
(4, 1, 'accepted', '2026-05-30 18:00:00', TRUE, FALSE),
-- Bilal successfully claimed the socket wrenches from Ayesha (Completed)
(6, 4, 'completed', '2026-05-25 12:00:00', TRUE, TRUE);

-- ==========================================
-- 6. SEEDING SAVED ITEMS (Favorites)
-- ==========================================

INSERT INTO saved_items (user_id, item_id) VALUES
(1, 3), -- Safiullah saved the Calculus Book
(4, 1), -- Bilal saved the Mechanical Keyboard
(2, 7), -- Rafay saved the Vintage Bicycle
(3, 8); -- Ayesha saved the Dumbbells


-- ==========================================
-- BASIC SELECT QUERIES
-- ==========================================

-- View all registered users
SELECT * FROM users;

-- View all listed items
SELECT * FROM items;

-- View all images attached to items
SELECT * FROM item_images;

-- View all claim requests and their statuses
SELECT * FROM requests;

-- View all items saved/favorited by users
SELECT * FROM saved_items;


-- ==========================================
-- ADVANCED TESTING QUERIES (Highly Recommended)
-- ==========================================

-- 1. View Items with their Owner's Name (Great for feed testing)
SELECT 
    i.id AS item_id, 
    i.title, 
    i.status, 
    u.name AS owner_name, 
    i.city 
FROM items i
JOIN users u ON i.user_id = u.id;

-- 2. View Requests with Requester and Item Details
SELECT 
    r.id AS request_id,
    u.name AS requester_name,
    i.title AS requested_item,
    r.status,
    r.proposed_time
FROM requests r
JOIN users u ON r.requester_id = u.id
JOIN items i ON r.item_id = i.id;

-- 3. Check which user saved which item
SELECT 
    s.id AS save_id,
    u.name AS saved_by,
    i.title AS item_title
FROM saved_items s
JOIN users u ON s.user_id = u.id
JOIN items i ON s.item_id = i.id;