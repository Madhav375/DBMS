Q1. Status Change Audit Trigger:

-- Q1: STATUS CHANGE AUDIT TRIGGER

CREATE TABLE patient_status_audit (
    audit_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id),
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    changed_by VARCHAR(50) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--  PART 2: STATUS CHANGE AUDIT FUNCTION AND TRIGGER

CREATE OR REPLACE FUNCTION fn_log_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO patient_status_audit
    (patient_id, old_status, new_status)
    VALUES
    (NEW.patient_id, OLD.status, NEW.status);

    RETURN NEW;

END;
$$;

CREATE TRIGGER trg_patient_status_audit
AFTER UPDATE OF status ON patients
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION fn_log_status_change();


--  PART 3: BLOCK DISCHARGED PATIENT

CREATE OR REPLACE FUNCTION fn_block_discharged()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF OLD.status = 'DISCHARGED'
       AND NEW.status <> 'REGISTERED' THEN

        RAISE EXCEPTION
        'Patient % is DISCHARGED. Re-register before changing status to %.',
        OLD.patient_id, NEW.status;

    END IF;

    RETURN NEW;

END;
$$;

CREATE TRIGGER trg_block_discharged
BEFORE UPDATE OF status ON patients
FOR EACH ROW
EXECUTE FUNCTION fn_block_discharged();


-- Q1 PART 4: TEST CASES

-- T1: Status changes (1 audit row)
UPDATE patients
SET status = 'ADMITTED'
WHERE patient_id = 1;


-- T2: Same status (NO audit row)
UPDATE patients
SET status = 'ADMITTED'
WHERE patient_id = 1;


-- T3: Different column changes (NO audit row)
UPDATE patients
SET phone = '9810000044'
WHERE patient_id = 4;


-- T4: Status changes (1 audit row)
UPDATE patients
SET status = 'UNDER_TREATMENT'
WHERE patient_id = 2;

-- T5: Discharged patient moved to ADMITTED -> ERROR
UPDATE patients
SET status = 'ADMITTED'
WHERE patient_id = 5;

-- T6: Discharged patient re-registered (1 audit row)
UPDATE patients
SET status = 'REGISTERED'
WHERE patient_id = 5;


-- FINAL AUDIT TABLE
SELECT audit_id, patient_id, old_status,
       new_status, changed_by, changed_at
FROM patient_status_audit
ORDER BY audit_id;
