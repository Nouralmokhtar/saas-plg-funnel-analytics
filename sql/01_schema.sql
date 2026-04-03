-- =============================================
-- SCHEMA: Create tables for SaaS analytics
-- Run this first to set up your database
-- =============================================

DROP TABLE IF EXISTS product_events;
DROP TABLE IF EXISTS support_tickets;
DROP TABLE IF EXISTS feature_usage;
DROP TABLE IF EXISTS accounts;


CREATE TABLE accounts (
    account_id TEXT PRIMARY KEY,
    signup_date DATE NOT NULL,
    industry TEXT NOT NULL,
    company_size TEXT NOT NULL,
    source TEXT NOT NULL,            -- How they found us
    plan TEXT NOT NULL,              -- Free, Starter, Growth, Enterprise
    mrr REAL NOT NULL,              -- Monthly Recurring Revenue
    trial_end_date DATE NOT NULL,
    conversion_date DATE,           -- NULL if never converted
    churned TEXT NOT NULL,           -- Yes / No
    churn_date DATE                 -- NULL if still active
);


CREATE TABLE feature_usage (
    usage_id TEXT PRIMARY KEY,
    account_id TEXT NOT NULL,
    feature TEXT NOT NULL,
    usage_month TEXT NOT NULL,       -- YYYY-MM format
    times_used INTEGER NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);


CREATE TABLE support_tickets (
    ticket_id TEXT PRIMARY KEY,
    account_id TEXT NOT NULL,
    created_date DATE NOT NULL,
    category TEXT NOT NULL,
    priority TEXT NOT NULL,
    resolution_hours REAL,
    resolved TEXT NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);


CREATE TABLE product_events (
    event_id TEXT PRIMARY KEY,
    account_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    event_date DATE NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);


-- =============================================
-- LOAD DATA (SQLite)
-- =============================================
-- .mode csv
-- .import --skip 1 accounts.csv accounts
-- .import --skip 1 feature_usage.csv feature_usage
-- .import --skip 1 support_tickets.csv support_tickets
-- .import --skip 1 product_events.csv product_events
