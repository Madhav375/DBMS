-- Q2: TRANSACTIONS AND SAVEPOINTS
-- PART A: MANUAL TRANSACTION

BEGIN;
INSERT INTO treatments
(patient_id, doctor_id, diagnosis, cost)
VALUES
(2, 1, 'Follow-up ECG', 2500);

INSERT INTO billing
(patient_id, amount, amount_paid)
VALUES
(2, 2500, 0);

SAVEPOINT sp_treatment;

UPDATE billing
SET amount_paid = amount_paid + 10000
WHERE bill_id = 1;

SAVEPOINT sp_payment;

UPDATE billing
SET amount_paid = amount
WHERE patient_id = 2;

SELECT * FROM billing
WHERE patient_id = 2;

ROLLBACK TO SAVEPOINT sp_payment;

SELECT * FROM billing
WHERE patient_id = 2;

UPDATE billing
SET amount_paid = amount_paid + 1000
WHERE bill_id = 1;


SELECT * FROM billing;

ROLLBACK TO SAVEPOINT sp_payment;

COMMIT;

-- FINAL VERIFICATION

SELECT * FROM billing
ORDER BY bill_id;

SELECT COUNT(*) AS total_treatments
FROM treatments;



-- Q2 PART B: CREATE PAYMENT PROCEDURE

CREATE OR REPLACE PROCEDURE apply_payment(
    p_bill_id INT,
    p_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance NUMERIC;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Payment amount must be greater than zero';
    END IF;
    BEGIN

        UPDATE billing
        SET amount_paid = amount_paid + p_amount
        WHERE bill_id = p_bill_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Bill % not found', p_bill_id;
        END IF;
        SELECT amount - amount_paid
        INTO v_balance
        FROM billing
        WHERE bill_id = p_bill_id;

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'Payment rejected: Amount exceeds bill amount';
            RETURN;
    END;

    RAISE NOTICE 'Payment successful. Remaining balance: %',
    v_balance;
    COMMIT;

END;
$$;

CALL apply_payment(3, 1000);

CALL apply_payment(3, 5000);

CALL apply_payment(99, 100);