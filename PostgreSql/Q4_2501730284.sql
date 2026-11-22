
CREATE OR REPLACE PROCEDURE doctor_appointment_summary(
    p_from DATE,
    p_to DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_doctor_id INT;
    v_doctor_name VARCHAR(60);
    v_specialization VARCHAR(40);
    v_fee NUMERIC(8,2);

    -- Explicit cursor for doctors
    cur_doctors CURSOR FOR
        SELECT doctor_id, doctor_name,
               specialization, consultation_fee
        FROM doctors
        ORDER BY doctor_id;

BEGIN
    OPEN cur_doctors;

    LOOP
        FETCH cur_doctors INTO
            v_doctor_id,
            v_doctor_name,
            v_specialization,
            v_fee;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Doctor: %, Specialization: %, Fee: %',
            v_doctor_name, v_specialization, v_fee;
    END LOOP;

    CLOSE cur_doctors;
END;
$$;


--task2:


CREATE OR REPLACE PROCEDURE doctor_appointment_summary(
    p_from DATE,
    p_to DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_doctor_id INT;
    v_doctor_name VARCHAR(60);
    v_specialization VARCHAR(40);
    v_fee NUMERIC(8,2);
    v_appt_status VARCHAR(12);

    v_total INT;
    v_completed INT;
    v_cancelled INT;
    v_scheduled INT;
    v_revenue NUMERIC(10,2);

    cur_doctors CURSOR FOR
        SELECT doctor_id, doctor_name,
               specialization, consultation_fee
        FROM doctors
        ORDER BY doctor_id;

    cur_appts CURSOR (c_doc INT) FOR
        SELECT appt_status
        FROM appointments
        WHERE doctor_id = c_doc
        AND appt_date BETWEEN p_from AND p_to;

BEGIN
    OPEN cur_doctors;

    LOOP
        FETCH cur_doctors INTO
            v_doctor_id,
            v_doctor_name,
            v_specialization,
            v_fee;

        EXIT WHEN NOT FOUND;

        v_total := 0;
        v_completed := 0;
        v_cancelled := 0;
        v_scheduled := 0;

        OPEN cur_appts(v_doctor_id);

        LOOP
            FETCH cur_appts INTO v_appt_status;

            EXIT WHEN NOT FOUND;

            v_total := v_total + 1;

            IF v_appt_status = 'COMPLETED' THEN
                v_completed := v_completed + 1;
            ELSIF v_appt_status = 'CANCELLED' THEN
                v_cancelled := v_cancelled + 1;
            ELSIF v_appt_status = 'SCHEDULED' THEN
                v_scheduled := v_scheduled + 1;
            END IF;
        END LOOP;

        CLOSE cur_appts;

        v_revenue := v_completed * v_fee;

        RAISE NOTICE
        '% (%): Total=% Completed=% Cancelled=% Scheduled=% Revenue=%',
        v_doctor_name,
        v_specialization,
        v_total,
        v_completed,
        v_cancelled,
        v_scheduled,
        v_revenue;

    END LOOP;

    CLOSE cur_doctors;
END;
$$;

--task3:


CREATE OR REPLACE PROCEDURE doctor_appointment_summary(
    p_from DATE,
    p_to DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_doctor_id INT;
    v_doctor_name VARCHAR(60);
    v_specialization VARCHAR(40);
    v_fee NUMERIC(8,2);
    v_appt_status VARCHAR(12);

    v_total INT;
    v_completed INT;
    v_cancelled INT;
    v_scheduled INT;
    v_revenue NUMERIC(10,2);

    cur_doctors CURSOR FOR
        SELECT doctor_id, doctor_name,
               specialization, consultation_fee
        FROM doctors
        ORDER BY doctor_id;

    cur_appts CURSOR (c_doc INT) FOR
        SELECT appt_status
        FROM appointments
        WHERE doctor_id = c_doc
        AND appt_date BETWEEN p_from AND p_to;

BEGIN
    IF p_from > p_to THEN
        RAISE EXCEPTION 'Start date cannot be after end date';
    END IF;

    OPEN cur_doctors;

    LOOP
        FETCH cur_doctors INTO
            v_doctor_id,
            v_doctor_name,
            v_specialization,
            v_fee;

        EXIT WHEN NOT FOUND;

        v_total := 0;
        v_completed := 0;
        v_cancelled := 0;
        v_scheduled := 0;

        OPEN cur_appts(v_doctor_id);

        LOOP
            FETCH cur_appts INTO v_appt_status;
            EXIT WHEN NOT FOUND;

            v_total := v_total + 1;

            IF v_appt_status = 'COMPLETED' THEN
                v_completed := v_completed + 1;
            ELSIF v_appt_status = 'CANCELLED' THEN
                v_cancelled := v_cancelled + 1;
            ELSIF v_appt_status = 'SCHEDULED' THEN
                v_scheduled := v_scheduled + 1;
            END IF;
        END LOOP;

        CLOSE cur_appts;

        v_revenue := v_completed * v_fee;

        IF v_total = 0 THEN
            RAISE NOTICE '% (%): No appointments in this period',
                v_doctor_name, v_specialization;
        ELSE
            RAISE NOTICE
            '% (%): Total=% Completed=% Cancelled=% Scheduled=% Revenue=%',
            v_doctor_name,
            v_specialization,
            v_total,
            v_completed,
            v_cancelled,
            v_scheduled,
            v_revenue;
        END IF;

    END LOOP;

    CLOSE cur_doctors;
END;
$$;

--(A)
CALL doctor_appointment_summary('2026-10-01', '2026-10-31');

--(B)
CALL doctor_appointment_summary('2026-12-01', '2026-11-01');

--task4:


CREATE OR REPLACE PROCEDURE doctor_appointment_summary(
    p_from DATE,
    p_to DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_doctor_id INT;
    v_doctor_name VARCHAR(60);
    v_specialization VARCHAR(40);
    v_fee NUMERIC(8,2);
    v_appt_status VARCHAR(12);

    v_total INT;
    v_completed INT;
    v_cancelled INT;
    v_scheduled INT;
    v_revenue NUMERIC(10,2);

    v_grand_total INT := 0;
    v_grand_completed INT := 0;
    v_grand_revenue NUMERIC(12,2) := 0;

    cur_doctors CURSOR FOR
        SELECT doctor_id, doctor_name,
               specialization, consultation_fee
        FROM doctors
        ORDER BY doctor_id;

    cur_appts CURSOR (c_doc INT) FOR
        SELECT appt_status
        FROM appointments
        WHERE doctor_id = c_doc
        AND appt_date BETWEEN p_from AND p_to;

BEGIN
    IF p_from > p_to THEN
        RAISE EXCEPTION 'Start date cannot be after end date';
    END IF;

    RAISE NOTICE 'Doctor Appointment Summary: % to %',
        p_from, p_to;

    OPEN cur_doctors;

    LOOP
        FETCH cur_doctors INTO
            v_doctor_id,
            v_doctor_name,
            v_specialization,
            v_fee;

        EXIT WHEN NOT FOUND;

        v_total := 0;
        v_completed := 0;
        v_cancelled := 0;
        v_scheduled := 0;

        OPEN cur_appts(v_doctor_id);

        LOOP
            FETCH cur_appts INTO v_appt_status;
            EXIT WHEN NOT FOUND;

            v_total := v_total + 1;

            IF v_appt_status = 'COMPLETED' THEN
                v_completed := v_completed + 1;
            ELSIF v_appt_status = 'CANCELLED' THEN
                v_cancelled := v_cancelled + 1;
            ELSIF v_appt_status = 'SCHEDULED' THEN
                v_scheduled := v_scheduled + 1;
            END IF;
        END LOOP;

        CLOSE cur_appts;

        v_revenue := v_completed * v_fee;

        v_grand_total := v_grand_total + v_total;
        v_grand_completed := v_grand_completed + v_completed;
        v_grand_revenue := v_grand_revenue + v_revenue;

        IF v_total = 0 THEN
            RAISE NOTICE '% (%): No appointments in this period',
                v_doctor_name, v_specialization;
        ELSE
            RAISE NOTICE
            '% (%): Total=% Completed=% Cancelled=% Scheduled=% Revenue=%',
            v_doctor_name,
            v_specialization,
            v_total,
            v_completed,
            v_cancelled,
            v_scheduled,
            v_revenue;
        END IF;

    END LOOP;

    CLOSE cur_doctors;

    RAISE NOTICE
    'GRAND TOTAL: Appointments=% Completed=% Revenue=%',
    v_grand_total,
    v_grand_completed,
    v_grand_revenue;

END;
$$;

CALL doctor_appointment_summary('2026-10-01', '2026-10-31');

CALL doctor_appointment_summary('2026-11-01', '2026-11-30');

CALL doctor_appointment_summary('2026-12-01', '2026-11-01');