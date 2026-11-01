-- =====================================================================
-- LIBRARY MANAGEMENT SYSTEM - SUPABASE SCHEMA
-- Simple, Clean, & Production-Ready
-- =====================================================================

DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS fine_payment CASCADE;
DROP TABLE IF EXISTS borrow_transaction CASCADE;
DROP TABLE IF EXISTS book CASCADE;
DROP TABLE IF EXISTS category CASCADE;
DROP TABLE IF EXISTS member CASCADE;
DROP TABLE IF EXISTS staff CASCADE;

CREATE TABLE audit_log (
    audit_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name  VARCHAR(50) NOT NULL,
    action      VARCHAR(10) NOT NULL CHECK (action IN ('ADD','EDIT','DELETE','RESTORE')),
    record_id   VARCHAR(60),
    old_values  JSONB,
    new_values  JSONB,
    action_by   VARCHAR(100) DEFAULT 'system',
    action_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE category (
    category_id SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE book (
    book_id       VARCHAR(20) PRIMARY KEY, -- e.g., 'BOK-001' or ISBN
    title         VARCHAR(255) NOT NULL,
    author        VARCHAR(255) NOT NULL,
    publisher     VARCHAR(150),
    publish_year  INT,
    category_id   INT REFERENCES category(category_id),
    total_copies  INT NOT NULL DEFAULT 1 CHECK (total_copies >= 0),
    available_copies INT NOT NULL DEFAULT 1 CHECK (available_copies >= 0),
    shelf_location VARCHAR(50),            -- e.g., 'Shelf A-3'
    is_deleted    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE member (
    member_id     VARCHAR(20) PRIMARY KEY, -- e.g., 'MEM-2026-001'
    firstname     VARCHAR(50) NOT NULL,
    lastname      VARCHAR(50) NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    phone         VARCHAR(25),
    address       TEXT,
    membership_status VARCHAR(20) DEFAULT 'Active' CHECK (membership_status IN ('Active', 'Suspended', 'Expired')),
    is_deleted    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE staff (
    staff_id      VARCHAR(20) PRIMARY KEY, -- e.g., 'STF-001'
    firstname     VARCHAR(50) NOT NULL,
    lastname      VARCHAR(50) NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    role          VARCHAR(50) DEFAULT 'Librarian' CHECK (role IN ('Admin', 'Librarian', 'Assistant')),
    is_deleted    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE borrow_transaction (
    transaction_id SERIAL PRIMARY KEY,
    book_id        VARCHAR(20) NOT NULL REFERENCES book(book_id),
    member_id      VARCHAR(20) NOT NULL REFERENCES member(member_id),
    staff_id       VARCHAR(20) REFERENCES staff(staff_id),
    borrow_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date       DATE NOT NULL,
    return_date    DATE,                       -- NULL means still borrowed
    status         VARCHAR(20) DEFAULT 'Borrowed' CHECK (status IN ('Borrowed', 'Returned', 'Overdue', 'Lost')),
    is_deleted     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE fine_payment (
    payment_id     SERIAL PRIMARY KEY,
    transaction_id INT NOT NULL REFERENCES borrow_transaction(transaction_id),
    amount         DECIMAL(10,2) NOT NULL CHECK (amount >= 0.0),
    payment_date   DATE DEFAULT CURRENT_DATE,
    payment_status VARCHAR(20) DEFAULT 'Paid' CHECK (payment_status IN ('Pending', 'Paid', 'Waived')),
    is_deleted     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ DEFAULT now()
);

-- =====================================================================
-- HELPER VIEWS FOR EASY FRONTEND FETCHING (Active rows only)
-- =====================================================================

CREATE VIEW v_active_books AS 
SELECT b.*, c.name AS category_name 
FROM book b 
LEFT JOIN category c ON b.category_id = c.category_id 
WHERE NOT b.is_deleted;

CREATE VIEW v_active_members AS 
SELECT * FROM member WHERE NOT is_deleted;

CREATE VIEW v_active_staff AS 
SELECT * FROM staff WHERE NOT is_deleted;

CREATE VIEW v_active_borrow_transactions AS 
SELECT t.*, b.title AS book_title, 
       m.firstname || ' ' || m.lastname AS member_name 
FROM borrow_transaction t
JOIN book b ON t.book_id = b.book_id
JOIN member m ON t.member_id = m.member_id
WHERE NOT t.is_deleted;