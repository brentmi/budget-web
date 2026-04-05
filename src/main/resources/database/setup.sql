-- =============================================================================
-- Budget Web - Database Setup
-- Database: budget_web
-- =============================================================================

CREATE DATABASE IF NOT EXISTS budget_web
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE budget_web;

-- =============================================================================
-- AUTH / INFRASTRUCTURE TABLES
-- =============================================================================

CREATE TABLE IF NOT EXISTS operator (
    id             INT          NOT NULL AUTO_INCREMENT,
    username       VARCHAR(100) NOT NULL,
    password       VARCHAR(255) NOT NULL,
    name           VARCHAR(200) NOT NULL,
    email          VARCHAR(200) DEFAULT NULL,
    permission_set VARCHAR(64)  NOT NULL DEFAULT '10000',
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_operator_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS audit_log (
    id          BIGINT       NOT NULL AUTO_INCREMENT,
    when_date   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    type        VARCHAR(50)  NOT NULL,
    operator_id INT          DEFAULT NULL,
    msg         TEXT         DEFAULT NULL,
    source      VARCHAR(200) DEFAULT NULL,
    PRIMARY KEY (id),
    KEY idx_audit_when (when_date),
    KEY idx_audit_operator (operator_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================================
-- BUDGET TABLES
-- =============================================================================

-- Financial years (July 1 to June 30, Australian FY)
CREATE TABLE IF NOT EXISTS financial_year (
    id              INT           NOT NULL AUTO_INCREMENT,
    year_label      VARCHAR(9)    NOT NULL,         -- e.g. '2025-2026'
    start_date      DATE          NOT NULL,         -- e.g. 2025-07-01
    end_date        DATE          NOT NULL,         -- e.g. 2026-06-30
    opening_balance DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    target_gain     DECIMAL(12,2) NOT NULL DEFAULT 20000.00,
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_year_label (year_label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- One row per month per financial year (12 rows auto-created on year creation)
-- month_number: 1=July, 2=August, ... 12=June
CREATE TABLE IF NOT EXISTS budget_month (
    id            INT        NOT NULL AUTO_INCREMENT,
    year_id       INT        NOT NULL,
    month_number  TINYINT    NOT NULL,              -- 1=July ... 12=June
    is_reconciled TINYINT(1) NOT NULL DEFAULT 0,
    notes         TEXT       DEFAULT NULL,
    created_at    TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_month (year_id, month_number),
    CONSTRAINT fk_month_year FOREIGN KEY (year_id) REFERENCES financial_year (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Flexible line items per month
-- entry_type : DEBIT (money out) | CREDIT (money in)
-- category   : cc_payment | mortgage | misc | wages | rent | interest |
--              dividend | ato_refund | other
CREATE TABLE IF NOT EXISTS budget_entry (
    id          INT                    NOT NULL AUTO_INCREMENT,
    month_id    INT                    NOT NULL,
    entry_type  ENUM('DEBIT','CREDIT') NOT NULL,
    category    VARCHAR(50)            NOT NULL,
    description VARCHAR(500)           NOT NULL DEFAULT '',
    amount      DECIMAL(12,2)          NOT NULL DEFAULT 0.00,
    is_actual   TINYINT(1)             NOT NULL DEFAULT 0,   -- 0=estimate 1=actual
    sort_order  INT                    NOT NULL DEFAULT 0,
    created_at  TIMESTAMP              NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP              NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_entry_month (month_id),
    CONSTRAINT fk_entry_month FOREIGN KEY (month_id) REFERENCES budget_month (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Known recurring fixed expenses (mirrors FIXED_INPUT sheet)
-- section: known_fixed | flexible_fixed
CREATE TABLE IF NOT EXISTS fixed_input_item (
    id         INT                                         NOT NULL AUTO_INCREMENT,
    item_name  VARCHAR(200)                                NOT NULL,
    item_cost  DECIMAL(12,2)                               NOT NULL DEFAULT 0.00,
    frequency  ENUM('Monthly','Quarterly','Yearly','Weekly') NOT NULL,
    section    ENUM('known_fixed','flexible_fixed')        NOT NULL DEFAULT 'known_fixed',
    is_active  TINYINT(1)                                  NOT NULL DEFAULT 1,
    sort_order INT                                         NOT NULL DEFAULT 0,
    created_at TIMESTAMP                                   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP                                   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Superannuation balance history (mirrors SUPER sheet)
CREATE TABLE IF NOT EXISTS super_balance (
    id             INT           NOT NULL AUTO_INCREMENT,
    balance_date   DATE          NOT NULL,
    balance_amount DECIMAL(12,2) NOT NULL,
    notes          VARCHAR(500)  DEFAULT NULL,
    created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_super_date (balance_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Monthly interest income records (WORKSHEET current year + ARCHIVE historical)
CREATE TABLE IF NOT EXISTS interest_record (
    id          INT           NOT NULL AUTO_INCREMENT,
    record_date DATE          NOT NULL,
    net_amount  DECIMAL(12,2) NOT NULL,
    year_label  VARCHAR(9)    NOT NULL,             -- e.g. '2025-2026'
    created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_interest_date (record_date),
    KEY idx_interest_year (year_label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Worksheet reference items (CC estimates + subscriptions)
-- section: cc_estimate | subscription
CREATE TABLE IF NOT EXISTS worksheet_item (
    id         INT                              NOT NULL AUTO_INCREMENT,
    section    ENUM('cc_estimate','subscription') NOT NULL,
    item_name  VARCHAR(200)                     NOT NULL,
    amount     DECIMAL(12,2)                    NOT NULL DEFAULT 0.00,
    notes      VARCHAR(500)                     DEFAULT NULL,
    sort_order INT                              NOT NULL DEFAULT 0,
    is_active  TINYINT(1)                       NOT NULL DEFAULT 1,
    created_at TIMESTAMP                        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP                        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================================
-- SEED DATA
-- =============================================================================

-- Default admin operator (change password on first login)
INSERT INTO operator (username, password, name, email, permission_set)
VALUES ('admin', 'changeme', 'Administrator', '', '11111')
ON DUPLICATE KEY UPDATE id = id;

-- -----------------------------------------------------------------------
-- Financial years: 2025-2026 (current) and 2026-2027 (next)
-- Opening balance for 2025-2026 from Excel sheet B1 = 20000
-- Opening balance for 2026-2027 will be updated by the app when year is created
-- -----------------------------------------------------------------------
INSERT INTO financial_year (year_label, start_date, end_date, opening_balance, target_gain)
VALUES
    ('2025-2026', '2025-07-01', '2026-06-30', 20000.00, 20000.00),
    ('2026-2027', '2026-07-01', '2027-06-30', 0.00,     20000.00)
ON DUPLICATE KEY UPDATE year_label = year_label;

-- 12 months for 2025-2026 (month_number 1=July ... 12=June)
INSERT INTO budget_month (year_id, month_number)
SELECT fy.id, m.seq
FROM financial_year fy
CROSS JOIN (
    SELECT 1 AS seq UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
    UNION SELECT 5  UNION SELECT 6 UNION SELECT 7 UNION SELECT 8
    UNION SELECT 9  UNION SELECT 10 UNION SELECT 11 UNION SELECT 12
) AS m
WHERE fy.year_label = '2025-2026'
ON DUPLICATE KEY UPDATE month_number = month_number;

-- 12 months for 2026-2027
INSERT INTO budget_month (year_id, month_number)
SELECT fy.id, m.seq
FROM financial_year fy
CROSS JOIN (
    SELECT 1 AS seq UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
    UNION SELECT 5  UNION SELECT 6 UNION SELECT 7 UNION SELECT 8
    UNION SELECT 9  UNION SELECT 10 UNION SELECT 11 UNION SELECT 12
) AS m
WHERE fy.year_label = '2026-2027'
ON DUPLICATE KEY UPDATE month_number = month_number;

-- -----------------------------------------------------------------------
-- Fixed Input Items (from FIXED_INPUT sheet)
-- -----------------------------------------------------------------------
INSERT INTO fixed_input_item (item_name, item_cost, frequency, section, sort_order) VALUES
-- Known Fixed
('Strata',          1950.00, 'Quarterly', 'known_fixed',    1),
('Council',          390.00, 'Quarterly', 'known_fixed',    2),
('Water',            209.00, 'Quarterly', 'known_fixed',    3),
('Internet (NBN)',    80.00, 'Monthly',   'known_fixed',    4),
('Phone',             35.00, 'Monthly',   'known_fixed',    5),
('NRMA',              56.00, 'Monthly',   'known_fixed',    6),
('Car Rego',         661.00, 'Yearly',    'known_fixed',    7),
('Car Greenslip',    475.00, 'Yearly',    'known_fixed',    8),
('Car Insurance',   1200.00, 'Yearly',    'known_fixed',    9),
-- Flexible Fixed
('Electricity',      410.00, 'Quarterly', 'flexible_fixed', 1),
('Gas',              200.00, 'Quarterly', 'flexible_fixed', 2),
('Subscriptions',    160.00, 'Monthly',   'flexible_fixed', 3);

-- -----------------------------------------------------------------------
-- Worksheet Items (from WORKSHEET sheet)
-- -----------------------------------------------------------------------
INSERT INTO worksheet_item (section, item_name, amount, sort_order) VALUES
-- Subscriptions
('subscription', 'Netflix',    21.00, 1),
('subscription', 'HBO Max',    18.00, 2),
('subscription', 'Prime',      13.00, 3),
('subscription', 'Disney',     18.00, 4),
('subscription', 'GPT',        35.00, 5),
('subscription', 'Paramount',   9.00, 6),
('subscription', 'Medium',      8.00, 7),
('subscription', 'Apple',      25.00, 8),
('subscription', 'Google',     17.00, 9),
-- CC Estimates
('cc_estimate', 'Home contents insurance',  55.00,  1),
('cc_estimate', 'Petrol',                  100.00,  2),
('cc_estimate', 'Haircut',                  55.00,  3),
('cc_estimate', 'Digital subscriptions',   150.00,  4),
('cc_estimate', 'Gas (quarterly est.)',    183.00,  5),
('cc_estimate', 'Misc spending',          1200.00,  6),
('cc_estimate', 'Shopping',               200.00,   7);

-- -----------------------------------------------------------------------
-- Superannuation Balances (from SUPER sheet - HESTA fund)
-- -----------------------------------------------------------------------
INSERT INTO super_balance (balance_date, balance_amount) VALUES
('2018-06-30', 281423.06),
('2019-06-30', 311550.98),
('2020-06-30', 319803.68),
('2021-06-30', 395458.68),
('2022-06-30', 397404.23),
('2022-12-30', 416592.18),
('2023-01-30', 429783.00),
('2023-02-28', 429702.31),
('2023-03-31', 434607.30),
('2023-04-30', 442542.66),
('2023-05-30', 445541.38),
('2023-06-30', 449679.47),
('2023-07-31', 458295.53),
('2023-08-31', 460930.08),
('2023-09-30', 453919.59),
('2023-10-31', 446685.22),
('2023-11-30', 461396.89),
('2023-12-31', 475783.35),
('2024-01-31', 481979.45),
('2024-02-28', 493048.81),
('2024-03-31', 502527.38),
('2024-04-30', 497667.91),
('2024-05-31', 501815.86),
('2024-06-30', 509882.28),
('2024-07-31', 517159.93),
('2024-08-31', 521435.00),
('2024-09-30', 529953.33),
('2024-10-31', 537073.44),
('2024-11-30', 546466.06),
('2024-12-31', 547368.95),
('2025-01-31', 560942.19),
('2025-02-28', 557242.31),
('2025-03-31', 547631.04),
('2025-04-30', 557297.19),
('2025-05-31', 566963.33),
('2025-06-30', 576052.00),
('2025-07-31', 587883.46),
('2025-08-31', 597433.54),
('2025-09-30', 603711.00),
('2025-10-31', 613812.32),
('2025-11-30', 611841.93),
('2025-12-31', 615179.43),
('2026-01-31', 621265.36),
('2026-02-28', 627034.89),
('2026-03-31', 603296.07)
ON DUPLICATE KEY UPDATE balance_amount = VALUES(balance_amount);

-- -----------------------------------------------------------------------
-- Interest Records (from WORKSHEET col G/H - 2024-2025 financial year)
-- Note: Apr/May/Jun 2025 values approximate - update via the UI
-- -----------------------------------------------------------------------
INSERT INTO interest_record (record_date, net_amount, year_label) VALUES
('2024-07-31', 465.49, '2024-2025'),
('2024-08-31', 435.38, '2024-2025'),
('2024-09-30', 466.54, '2024-2025'),
('2024-10-31', 459.21, '2024-2025'),
('2024-11-30', 420.35, '2024-2025'),
('2024-12-31', 502.82, '2024-2025'),
('2025-01-31', 463.55, '2024-2025'),
('2025-02-28', 451.55, '2024-2025'),
('2025-03-31', 541.61, '2024-2025'),
('2025-04-30', 453.82, '2024-2025'),
('2025-05-31', 461.31, '2024-2025'),
('2025-06-30', 453.82, '2024-2025')
ON DUPLICATE KEY UPDATE net_amount = VALUES(net_amount);
