-- ============================================================
-- FINALIZED SQL FILE
-- Project: Personal Credit Health and Debt Repayment Planning System
-- DBMS: MySQL 8.x
-- Source basis: PES2UG24CS625_PES2UG24CS621_5K_DBMS_REVIEW1(3).pdf
--
-- IMPORTANT CONSISTENCY NOTE:
-- This script follows the SIX-table implementation visible in the
-- submitted Review 1 PDF: USER, FINANCIAL_PROFILE, LOAN, REPAYMENT,
-- REPAYMENT_PLAN and PLAN_PAYMENT. Do not combine it with the older
-- ER diagram containing BANK_ACCOUNT, INCOME, EXPENSE, CREDIT_SCORE,
-- etc. That is a different schema and would not match this SQL.
--
-- The PDF contains DESCRIBE/SHOW output and screenshots of selected
-- operations, not every original CREATE TABLE statement. Therefore,
-- the CREATE TABLE definitions below are reconstructed to match the
-- column names, data types, keys and relationships visible in those
-- screenshots. Demo seed rows are clearly identified below.
-- ============================================================

-- 1. DATABASE CREATION
CREATE DATABASE IF NOT EXISTS credit_health_db;
USE credit_health_db;

-- 2. TABLE CREATION (DDL)
-- Parent table
CREATE TABLE IF NOT EXISTS `user` (
    user_id VARCHAR(10) NOT NULL,
    PRIMARY KEY (user_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS financial_profile (
    profile_id INT NOT NULL AUTO_INCREMENT,
    user_id VARCHAR(10) NOT NULL,
    monthly_income_usd DECIMAL(12,2) NOT NULL,
    monthly_expenses_usd DECIMAL(12,2) NOT NULL,
    savings_usd DECIMAL(12,2) NOT NULL,
    has_loan VARCHAR(3) NOT NULL,
    debt_to_income_ratio DECIMAL(6,2) NOT NULL,
    credit_score INT NOT NULL,
    record_date DATE NOT NULL,
    PRIMARY KEY (profile_id),
    CONSTRAINT fk_financial_profile_user
        FOREIGN KEY (user_id) REFERENCES `user` (user_id),
    CONSTRAINT chk_profile_income CHECK (monthly_income_usd >= 0),
    CONSTRAINT chk_profile_expenses CHECK (monthly_expenses_usd >= 0),
    CONSTRAINT chk_profile_savings CHECK (savings_usd >= 0),
    CONSTRAINT chk_profile_has_loan CHECK (has_loan IN ('Yes','No')),
    CONSTRAINT chk_profile_credit_score CHECK (credit_score BETWEEN 300 AND 850)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS loan (
    loan_id VARCHAR(10) NOT NULL,
    user_id VARCHAR(10) NOT NULL,
    loan_type VARCHAR(20) NOT NULL,
    loan_amount_usd DECIMAL(14,2) NOT NULL,
    loan_term_months INT NOT NULL,
    monthly_emi_usd DECIMAL(12,2) NOT NULL,
    loan_interest_rate DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (loan_id),
    CONSTRAINT fk_loan_user
        FOREIGN KEY (user_id) REFERENCES `user` (user_id),
    CONSTRAINT chk_loan_amount CHECK (loan_amount_usd > 0),
    CONSTRAINT chk_loan_term CHECK (loan_term_months > 0),
    CONSTRAINT chk_loan_emi CHECK (monthly_emi_usd >= 0),
    CONSTRAINT chk_loan_interest CHECK (loan_interest_rate >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS repayment (
    payment_id VARCHAR(20) NOT NULL,
    loan_id VARCHAR(10) NOT NULL,
    installment_number INT NOT NULL,
    due_date DATE NOT NULL,
    payment_date DATE NOT NULL,
    amount_due_usd DECIMAL(12,2) NOT NULL,
    amount_paid_usd DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(20) NOT NULL,
    days_late INT NOT NULL,
    remaining_balance_usd DECIMAL(14,2) NOT NULL,
    PRIMARY KEY (payment_id),
    CONSTRAINT fk_repayment_loan
        FOREIGN KEY (loan_id) REFERENCES loan (loan_id),
    CONSTRAINT chk_repayment_installment CHECK (installment_number > 0),
    CONSTRAINT chk_repayment_due CHECK (amount_due_usd >= 0),
    CONSTRAINT chk_repayment_paid CHECK (amount_paid_usd >= 0),
    CONSTRAINT chk_repayment_late CHECK (days_late >= 0),
    CONSTRAINT chk_repayment_balance CHECK (remaining_balance_usd >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS repayment_plan (
    plan_id INT NOT NULL AUTO_INCREMENT,
    user_id VARCHAR(10) NOT NULL,
    plan_date DATE NOT NULL,
    total_months INT NOT NULL,
    monthly_available_amount DECIMAL(12,2) NOT NULL,
    risk_level VARCHAR(10) NOT NULL,
    PRIMARY KEY (plan_id),
    CONSTRAINT fk_repayment_plan_user
        FOREIGN KEY (user_id) REFERENCES `user` (user_id),
    CONSTRAINT chk_plan_months CHECK (total_months > 0),
    CONSTRAINT chk_plan_available CHECK (monthly_available_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS plan_payment (
    plan_payment_id INT NOT NULL AUTO_INCREMENT,
    plan_id INT NOT NULL,
    loan_id VARCHAR(10) NOT NULL,
    due_month DATE NOT NULL,
    planned_amount_usd DECIMAL(12,2) NOT NULL,
    priority_order INT NOT NULL,
    PRIMARY KEY (plan_payment_id),
    CONSTRAINT fk_plan_payment_plan
        FOREIGN KEY (plan_id) REFERENCES repayment_plan (plan_id),
    CONSTRAINT fk_plan_payment_loan
        FOREIGN KEY (loan_id) REFERENCES loan (loan_id),
    CONSTRAINT chk_planned_amount CHECK (planned_amount_usd >= 0),
    CONSTRAINT chk_priority_order CHECK (priority_order > 0)
) ENGINE=InnoDB;

-- 3. ALTER TABLE (as demonstrated in the Review 1 PDF)
ALTER TABLE repayment_plan
    ADD COLUMN plan_status VARCHAR(15) NOT NULL DEFAULT 'Active';

-- If running this complete script more than once on an existing DB,
-- the ALTER above may report that plan_status already exists. In that
-- case, skip this ALTER statement; do not delete the column.

-- 4. VERIFY TABLES AND TABLE STRUCTURES
SHOW TABLES;
DESCRIBE `user`;
DESCRIBE financial_profile;
DESCRIBE loan;
DESCRIBE repayment;
DESCRIBE repayment_plan;
DESCRIBE plan_payment;

-- 5. VERIFY PRIMARY KEYS
SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'credit_health_db'
  AND CONSTRAINT_NAME = 'PRIMARY'
ORDER BY TABLE_NAME;

-- 6. VERIFY FOREIGN KEYS
SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME,
       REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'credit_health_db'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ============================================================
-- 7. DEMONSTRATION DATA
-- These are minimal demo prerequisite rows so the later DML examples
-- can execute from a fresh database. They are not claimed to be the
-- complete original dataset. Replace them with your team's actual rows
-- if those are available in your project database/backup.
-- ============================================================

INSERT INTO `user` (user_id)
VALUES ('U03941')
ON DUPLICATE KEY UPDATE user_id = VALUES(user_id);

INSERT INTO financial_profile
    (user_id, monthly_income_usd, monthly_expenses_usd, savings_usd,
     has_loan, debt_to_income_ratio, credit_score, record_date)
SELECT 'U03941', 5000.00, 2500.00, 4000.00, 'Yes', 35.00, 720, '2026-08-24'
WHERE NOT EXISTS (
    SELECT 1 FROM financial_profile
    WHERE user_id = 'U03941' AND record_date = '2026-08-24'
);

INSERT INTO loan
    (loan_id, user_id, loan_type, loan_amount_usd, loan_term_months,
     monthly_emi_usd, loan_interest_rate)
VALUES ('L03941', 'U03941', 'Personal', 10000.00, 24, 500.00, 8.50)
ON DUPLICATE KEY UPDATE loan_id = VALUES(loan_id);

-- 8. DML: INSERT INTO REPAYMENT_PLAN (values/IDs follow the PDF example)
INSERT INTO repayment_plan
    (plan_id, user_id, plan_date, total_months,
     monthly_available_amount, risk_level, plan_status)
VALUES
    (1, 'U03941', '2026-08-24', 12, 2339.46, 'High', 'Active')
ON DUPLICATE KEY UPDATE
    user_id = VALUES(user_id),
    plan_date = VALUES(plan_date),
    total_months = VALUES(total_months),
    monthly_available_amount = VALUES(monthly_available_amount),
    risk_level = VALUES(risk_level),
    plan_status = VALUES(plan_status);

SELECT plan_id, user_id, plan_date, total_months,
       monthly_available_amount, risk_level, plan_status
FROM repayment_plan
WHERE plan_id = 1;

-- 9. DML: INSERT INTO PLAN_PAYMENT (PDF example)
INSERT INTO plan_payment
    (plan_id, loan_id, due_month, planned_amount_usd, priority_order)
VALUES
    (1, 'L03941', '2026-09-01', 794.82, 1);

SELECT plan_payment_id, plan_id, loan_id, due_month,
       planned_amount_usd, priority_order
FROM plan_payment
WHERE plan_id = 1;

-- 10. UPDATE OPERATION (PDF example: update planned amount)
UPDATE plan_payment
SET planned_amount_usd = 874.30
WHERE plan_id = 1
  AND loan_id = 'L03941'
  AND due_month = '2026-09-01';

SELECT plan_payment_id, plan_id, loan_id, due_month,
       planned_amount_usd, priority_order
FROM plan_payment
WHERE plan_id = 1;

-- 11. JOIN QUERY: REPAYMENT_PLAN AND PLAN_PAYMENT
SELECT rp.plan_id, rp.user_id, rp.plan_date, rp.total_months,
       rp.monthly_available_amount, rp.risk_level, rp.plan_status,
       pp.plan_payment_id, pp.loan_id, pp.due_month,
       pp.planned_amount_usd, pp.priority_order
FROM repayment_plan AS rp
JOIN plan_payment AS pp ON pp.plan_id = rp.plan_id
WHERE rp.plan_id = 1
ORDER BY pp.priority_order;

-- 12. DELETE OPERATION (PDF example)
-- This deletes only the demonstration plan-payment row.
DELETE FROM plan_payment
WHERE plan_id = 1 AND loan_id = 'L03941';

SELECT * FROM plan_payment WHERE plan_id = 1;

-- Reinsert the row so the subsequent trigger test / demonstration can
-- be run independently if needed.
INSERT INTO plan_payment
    (plan_id, loan_id, due_month, planned_amount_usd, priority_order)
VALUES
    (1, 'L03941', '2026-09-01', 794.82, 1);

-- 13. TRANSACTION: UPDATE + ROLLBACK (PDF example)
START TRANSACTION;

UPDATE repayment_plan
SET plan_status = 'Paused'
WHERE plan_id = 1;

SELECT plan_id, user_id, plan_status
FROM repayment_plan
WHERE plan_id = 1;

ROLLBACK;

SELECT plan_id, user_id, plan_status
FROM repayment_plan
WHERE plan_id = 1;

-- ============================================================
-- 14. STORED PROCEDURE (matches the procedure shown in the PDF)
-- ============================================================
DROP PROCEDURE IF EXISTS GetUserCreditHealth;
DELIMITER //
CREATE PROCEDURE GetUserCreditHealth(IN p_user_id VARCHAR(16))
BEGIN
    SELECT
        fp.user_id,
        fp.credit_score,
        fp.monthly_income_usd,
        fp.monthly_expenses_usd,
        fp.savings_usd,
        fp.debt_to_income_ratio,
        fp.has_loan,
        COUNT(l.loan_id) AS total_loans,
        ROUND(COALESCE(SUM(l.loan_amount_usd), 0), 2) AS total_loan_amount,
        ROUND(COALESCE(SUM(l.monthly_emi_usd), 0), 2) AS total_monthly_emi
    FROM financial_profile AS fp
    LEFT JOIN loan AS l ON l.user_id = fp.user_id
    WHERE fp.user_id = p_user_id
    GROUP BY
        fp.user_id,
        fp.credit_score,
        fp.monthly_income_usd,
        fp.monthly_expenses_usd,
        fp.savings_usd,
        fp.debt_to_income_ratio,
        fp.has_loan;
END //
DELIMITER ;

-- Execute and verify the stored procedure
CALL GetUserCreditHealth('U03941');
SHOW CREATE PROCEDURE GetUserCreditHealth;

-- ============================================================
-- 15. TRIGGER (matches the validation logic shown in the PDF)
-- ============================================================
DROP TRIGGER IF EXISTS trg_validate_plan_payment;
DELIMITER //
CREATE TRIGGER trg_validate_plan_payment
BEFORE INSERT ON plan_payment
FOR EACH ROW
BEGIN
    DECLARE v_available_amount DECIMAL(12,2);

    SELECT monthly_available_amount
    INTO v_available_amount
    FROM repayment_plan
    WHERE plan_id = NEW.plan_id;

    IF NEW.planned_amount_usd > v_available_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Planned payment exceeds monthly available amount';
    END IF;
END //
DELIMITER ;

-- Verify trigger definition
SHOW CREATE TRIGGER trg_validate_plan_payment;

-- 16. TEST THE TRIGGER
-- Expected result: this INSERT must fail with SQLSTATE 45000 because
-- 5000.00 is greater than the plan's monthly available amount (2339.46).
-- Run this statement separately if your SQL client stops on errors.
INSERT INTO plan_payment
    (plan_id, loan_id, due_month, planned_amount_usd, priority_order)
VALUES
    (1, 'L03941', '2026-10-01', 5000.00, 2);

-- Verify that the invalid payment was not inserted (expected count: 0)
SELECT COUNT(*) AS invalid_payment_inserted
FROM plan_payment
WHERE plan_id = 1
  AND planned_amount_usd = 5000.00;

-- ============================================================
-- 17. INDEXES (the eight index categories listed in the PDF)
-- ============================================================
CREATE INDEX idx_financial_profile_user
    ON financial_profile (user_id);

CREATE INDEX idx_loan_user
    ON loan (user_id);

CREATE INDEX idx_repayment_loan
    ON repayment (loan_id);

CREATE INDEX idx_repayment_status
    ON repayment (payment_status);

CREATE INDEX idx_repayment_due_date
    ON repayment (due_date);

CREATE INDEX idx_repayment_plan_user
    ON repayment_plan (user_id);

CREATE INDEX idx_plan_payment_plan
    ON plan_payment (plan_id);

CREATE INDEX idx_plan_payment_loan
    ON plan_payment (loan_id);

-- Verify indexes
SHOW INDEX FROM financial_profile;
SHOW INDEX FROM loan;
SHOW INDEX FROM repayment;
SHOW INDEX FROM repayment_plan;
SHOW INDEX FROM plan_payment;

-- ============================================================
-- END OF FINALIZED SQL FILE
-- ============================================================
