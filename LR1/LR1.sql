--docker run -d --name oracle-xe   -p 1521:1521 -p 5500:5500   -e ORACLE_PASSWORD=MySecurePassword   container-registry.oracle.com/database/express:21.3.0-xe
--sqlplus system/12345678@//localhost:1521/XEPDB1
--@/home/fulcrum/BSUIR/MDISUBD/LR1/LR1.sql

CREATE TABLE MyTable (
    id NUMBER PRIMARY KEY, 
    val NUMBER
);

DECLARE
    v_id NUMBER := 1;
BEGIN
    FOR i IN 1..10000 LOOP
        INSERT INTO MyTable (id, val) 
        VALUES (v_id, TRUNC(DBMS_RANDOM.VALUE(1, 10000)));
        v_id := v_id + 1;
    END LOOP;
    COMMIT;
END;
/

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

CREATE OR REPLACE FUNCTION generate_insert_statement(p_id NUMBER) RETURN VARCHAR2 IS
    v_val NUMBER;
    v_stmt VARCHAR2(4000);
BEGIN
    SELECT val INTO v_val FROM MyTable WHERE id = p_id;

    v_stmt := 'INSERT INTO MyTable (id, val) VALUES (' || p_id || ', ' || v_val || ');';
    
    RETURN v_stmt;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'ERROR: ID не найден.';
END;
/

CREATE OR REPLACE PROCEDURE insert_mytable(p_id NUMBER, p_val NUMBER) IS
BEGIN
    INSERT INTO MyTable (id, val) VALUES (p_id, p_val);
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE update_mytable(p_id NUMBER, p_new_val NUMBER) IS
BEGIN
    UPDATE MyTable SET val = p_new_val WHERE id = p_id;
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE delete_mytable(p_id NUMBER) IS
BEGIN
    DELETE FROM MyTable WHERE id = p_id;
    COMMIT;
END;
/

CREATE OR REPLACE FUNCTION calculate_total_reward(
    monthly_salary NUMBER, 
    annual_bonus_percent NUMBER
) RETURN NUMBER IS
    total_reward NUMBER;
BEGIN
    IF monthly_salary <= 0 OR annual_bonus_percent < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Ошибка: Неверные входные данные.');
    END IF;

    total_reward := (1 + annual_bonus_percent / 100) * 12 * monthly_salary;
    
    RETURN total_reward;
END;
/

