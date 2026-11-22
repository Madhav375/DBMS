
CREATE OR REPLACE PROCEDURE register_patient(
    p_name VARCHAR,
    p_dob DATE,
    p_gender CHAR,
    p_phone VARCHAR,
    INOUT p_patient_id INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- (a) 
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RAISE EXCEPTION 'Patient name cannot be empty';
    END IF;



    -- (b) 
    IF p_dob > CURRENT_DATE THEN
        RAISE EXCEPTION 'Date of birth cannot be in the future';
    END IF;

    -- (c)
    IF p_phone !~ '^[0-9]{10}$' THEN
        RAISE EXCEPTION 'Phone number must contain exactly 10 digits';
    END IF;

    -- (d) 
    IF EXISTS (
        SELECT 1
        FROM patients
        WHERE phone = p_phone
    ) THEN
        RAISE EXCEPTION 'Phone number % is already registered', p_phone;
    END IF;

    -- (e) 
    INSERT INTO patients (patient_name, dob, gender, phone)
    VALUES (TRIM(p_name), p_dob, p_gender, p_phone)
    RETURNING patient_id INTO p_patient_id;

    RAISE NOTICE 'Patient % registered with ID %',
        p_name, p_patient_id;
END;
$$;


-- task2:


CREATE OR REPLACE PROCEDURE add_treatment(
    p_patient_id INT,
    p_doctor_id INT,
    p_diagnosis VARCHAR,
    p_cost NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_fee NUMERIC;
    v_bill_amount NUMERIC;
BEGIN
    SELECT status INTO v_status
    FROM patients
    WHERE patient_id = p_patient_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Patient % does not exist', p_patient_id;
    END IF;

    IF v_status = 'DISCHARGED' THEN
        RAISE EXCEPTION 'Patient % is DISCHARGED', p_patient_id;
    END IF;

    SELECT consultation_fee INTO v_fee
    FROM doctors
    WHERE doctor_id = p_doctor_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Doctor % does not exist', p_doctor_id;
    END IF;

    IF p_cost IS NULL OR p_cost <= 0 THEN
        RAISE EXCEPTION 'Invalid cost';
    END IF;

    INSERT INTO treatments
    (patient_id, doctor_id, diagnosis, cost)
    VALUES
    (p_patient_id, p_doctor_id, p_diagnosis, p_cost);

    v_bill_amount := p_cost + v_fee;

    INSERT INTO billing (patient_id, amount, amount_paid)
    VALUES (p_patient_id, v_bill_amount, 0);

    IF v_status <> 'UNDER_TREATMENT' THEN
        UPDATE patients
        SET status = 'UNDER_TREATMENT'
        WHERE patient_id = p_patient_id;
    END IF;

    RAISE NOTICE 'Bill amount generated: %', v_bill_amount;
END;
$$;

--task3:

CREATE OR REPLACE PROCEDURE discharge_patient(
    p_patient_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_outstanding NUMERIC;
    v_status VARCHAR(20);
BEGIN
    SELECT status INTO v_status
    FROM patients
    WHERE patient_id = p_patient_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Patient % does not exist', p_patient_id;
    END IF;

    SELECT COALESCE(SUM(amount - amount_paid), 0)
    INTO v_outstanding
    FROM billing
    WHERE patient_id = p_patient_id;

    IF v_outstanding > 0 THEN
        RAISE EXCEPTION 'Outstanding dues: %', v_outstanding;
    END IF;

    UPDATE patients
    SET status = 'DISCHARGED'
    WHERE patient_id = p_patient_id
      AND status <> 'DISCHARGED';

    RAISE NOTICE 'Patient % discharged successfully', p_patient_id;
END;
$$;


CALL register_patient('Meera Joshi', '1998-03-15', 'F', '9810000006');

CALL register_patient('Test Future', '2030-01-01', 'M', '9810000007');

CALL register_patient('Bad Phone', '1990-01-01', 'M', '98100');

CALL register_patient('Dup Phone', '1990-01-01', 'M', '9810000006');

CALL add_treatment(6, 4, 'Eczema', 3000);

CALL add_treatment(6, 9, 'Eczema', 3000);

CALL add_treatment(6, 4, 'Eczema', 0);

UPDATE billing
SET amount_paid = amount
WHERE patient_id = 6;


CALL add_treatment(6, 4, 'Rash', 1000);

SELECT patient_id, patient_name, status
FROM patients
WHERE patient_id = 6;


SELECT audit_id, patient_id, old_status, new_status,
       changed_by, changed_at
FROM patient_status_audit
WHERE patient_id = 6
ORDER BY audit_id;

SELECT COUNT(*) AS total_treatments
FROM treatments
WHERE patient_id = 6;

SELECT bill_id, patient_id, amount, amount_paid,
       amount - amount_paid AS remaining_balance
FROM billing
WHERE patient_id = 6;