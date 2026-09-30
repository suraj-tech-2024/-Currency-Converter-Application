-- ============================================================
-- Currency Converter Database Schema
-- Complete database setup for User Registration, Login, and Currency Conversion
-- ============================================================

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS conversion_history;

DROP TABLE IF EXISTS users;

-- ============================================================
-- TABLE: users
-- Purpose: Store user registration and login credentials
-- ============================================================
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,

-- Indexes for faster lookups
INDEX idx_username (username), INDEX idx_email (email) );

-- ============================================================
-- TABLE: conversion_history
-- Purpose: Store all currency conversion transactions
-- ============================================================
CREATE TABLE conversion_history (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    amount DECIMAL(38, 2) NOT NULL,
    from_currency VARCHAR(10) NOT NULL,
    to_currency VARCHAR(10) NOT NULL,
    result DECIMAL(38, 2) NOT NULL,
    exchange_rate DECIMAL(20, 10) DEFAULT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

-- Foreign key constraint
FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,

-- Indexes for faster queries
INDEX idx_user_id (user_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_currencies (from_currency, to_currency)
);

-- ============================================================
-- SAMPLE DATA (for testing)
-- ============================================================

-- Insert sample users (passwords are BCrypt encoded: "password123")
INSERT INTO
    users (
        username,
        email,
        password,
        created_at
    )
VALUES (
        'john_doe',
        'john@example.com',
        '$2a$10$ZvXC.pqFPYyZ5h3mQ8lKk.xHc5jXKfN8VmJ5xLwYfJhBvQzX8.8Ga',
        CURRENT_TIMESTAMP
    ),
    (
        'jane_smith',
        'jane@example.com',
        '$2a$10$ZvXC.pqFPYyZ5h3mQ8lKk.xHc5jXKfN8VmJ5xLwYfJhBvQzX8.8Ga',
        CURRENT_TIMESTAMP
    ),
    (
        'admin_user',
        'admin@example.com',
        '$2a$10$ZvXC.pqFPYyZ5h3mQ8lKk.xHc5jXKfN8VmJ5xLwYfJhBvQzX8.8Ga',
        CURRENT_TIMESTAMP
    );

-- Insert sample conversion history
INSERT INTO
    conversion_history (
        user_id,
        amount,
        from_currency,
        to_currency,
        result,
        exchange_rate,
        timestamp
    )
VALUES (
        1,
        100.00,
        'USD',
        'INR',
        8300.00,
        83.0000000000,
        CURRENT_TIMESTAMP
    ),
    (
        1,
        50.00,
        'EUR',
        'USD',
        55.00,
        1.1000000000,
        CURRENT_TIMESTAMP - INTERVAL 1 DAY
    ),
    (
        2,
        1000.00,
        'INR',
        'USD',
        12.05,
        0.0120500000,
        CURRENT_TIMESTAMP - INTERVAL 2 DAY
    ),
    (
        2,
        200.00,
        'USD',
        'EUR',
        181.82,
        0.9091000000,
        CURRENT_TIMESTAMP - INTERVAL 3 DAY
    ),
    (
        3,
        75.00,
        'EUR',
        'INR',
        6825.00,
        91.0000000000,
        CURRENT_TIMESTAMP - INTERVAL 4 DAY
    );

-- ============================================================
-- USEFUL QUERIES
-- ============================================================

-- Query 1: View all users
-- SELECT id, username, email, created_at, is_active FROM users;

-- Query 2: View all conversions with user details
-- SELECT u.username, ch.amount, ch.from_currency, ch.to_currency,
--        ch.result, ch.timestamp
-- FROM conversion_history ch
-- JOIN users u ON ch.user_id = u.id
-- ORDER BY ch.timestamp DESC;

-- Query 3: Get user statistics
-- SELECT u.username,
--        COUNT(ch.id) as total_conversions,
--        SUM(ch.amount) as total_amount_converted,
--        MIN(ch.timestamp) as first_conversion,
--        MAX(ch.timestamp) as last_conversion
-- FROM users u
-- LEFT JOIN conversion_history ch ON u.id = ch.user_id
-- GROUP BY u.username;

-- Query 4: Find conversions by currency pair
-- SELECT * FROM conversion_history
-- WHERE from_currency = 'USD' AND to_currency = 'INR'
-- ORDER BY timestamp DESC;

-- Query 5: User login verification (username lookup)
-- SELECT id, username, email, password, is_active
-- FROM users
-- WHERE username = 'john_doe';

-- ============================================================
-- DATABASE SCHEMA DESCRIPTION
-- ============================================================

/*
USERS TABLE:
- id: Unique identifier for each user
- username: Unique username for login
- email: Unique email address
- password: BCrypt hashed password
- created_at: Account creation timestamp
- last_login: Last successful login time
- is_active: Account status flag

CONVERSION_HISTORY TABLE:
- id: Unique identifier for each conversion
- user_id: References the user who made the conversion
- amount: Original amount to convert
- from_currency: Source currency code (USD, EUR, INR, etc.)
- to_currency: Target currency code
- result: Converted amount
- exchange_rate: Rate used for conversion
- timestamp: When the conversion was performed

RELATIONSHIPS:
- One user can have many conversion histories (1:N)
- Conversion history must belong to a user
- Deleting a user cascades to delete their conversion history
*/