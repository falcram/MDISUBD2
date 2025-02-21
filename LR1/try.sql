--@/home/fulcrum/BSUIR/MDISUBD/LR1/try.sql

SELECT COUNT(*) FROM MyTable;
SELECT * FROM MyTable ORDER BY id FETCH FIRST 5 ROWS ONLY;
SELECT generate_insert_statement(5000) FROM dual;
SELECT generate_insert_statement(-1) FROM dual;
SELECT generate_insert_statement('A') FROM dual;
SELECT generate_insert_statement() FROM dual;
/
BEGIN
 insert_mytable(100, 123);
END;
/
BEGIN
 insert_mytable(10000, 1);
END;
/
SELECT calculate_total_compensation(20,10) FROM dual;
SELECT calculate_total_compensation(-20,10) FROM dual;