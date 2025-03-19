--@/home/fulcrum/BSUIR/MDISUBD/LR1/function.sql

-- 3
CREATE OR REPLACE FUNCTION check_even_odd_ratio RETURN VARCHAR2 IS
    even_count NUMBER;
    odd_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO even_count FROM MyTable WHERE MOD(val, 2) = 0;
    
    SELECT COUNT(*) INTO odd_count FROM MyTable WHERE MOD(val, 2) <> 0;

    IF even_count > odd_count THEN
        RETURN 'TRUE';
    ELSIF odd_count > even_count THEN
        RETURN 'FALSE';
    ELSE
        RETURN 'EQUAL';
    END IF;
END;
/

-- 4
CREATE OR REPLACE FUNCTION generate_insert_statement(p_id NUMBER) RETURN VARCHAR2 IS
    v_val NUMBER;
    v_stmt VARCHAR2(4000);
BEGIN
    SELECT val INTO v_val FROM MyTable WHERE id = p_id;

    v_stmt := 'INSERT INTO MyTable (id, val) VALUES (' || p_id || ', ' || v_val || ');';
    
    RETURN v_stmt;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'ERROR: ID not found.';
    WHEN VALUE_ERROR THEN
        RETURN 'ERROR: Invalid number format.';
    WHEN OTHERS THEN
        RETURN 'MY ERROR: ' || SQLERRM;
END;
/

-- 5

CREATE OR REPLACE PROCEDURE insert_mytable(p_id NUMBER, p_val NUMBER) IS
BEGIN
    INSERT INTO MyTable (id, val) VALUES (p_id, p_val);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('ERROR:  ID exists.'); 
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: VALUE.'); 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE update_mytable(p_id NUMBER, p_new_val NUMBER) IS
BEGIN
    UPDATE MyTable SET val = p_new_val WHERE id = p_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: NO DATA WITH THIS ID.'); 
    ELSE
        COMMIT;
    END IF;
EXCEPTION
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: VALUE.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE delete_mytable(p_id NUMBER) IS
BEGIN
    DELETE FROM MyTable WHERE id = p_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: NO DATA WITH THIS ID.'); 
    ELSE
        COMMIT;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/

-- 6
CREATE OR REPLACE FUNCTION calculate_total_compensation(
    p_monthly_salary NUMBER,
    p_bonus_percentage INTEGER
) RETURN NUMBER IS
    total_compensation NUMBER;
BEGIN
    IF p_monthly_salary < 0 THEN
        RAISE VALUE_ERROR;
    END IF;

    IF p_bonus_percentage < 0 THEN
        RAISE VALUE_ERROR;  
    END IF;

    IF p_monthly_salary IS NULL THEN
        total_compensation := 0;
        RETURN total_compensation;
    END IF;

    total_compensation := (1 + p_bonus_percentage / 100) * 12 * p_monthly_salary;

    RETURN total_compensation;

EXCEPTION
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: NEGATIV VALUE.');
        RETURN NULL; 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RETURN NULL;
END;
/