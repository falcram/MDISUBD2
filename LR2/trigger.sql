--@/home/fulcrum/BSUIR/MDISUBD/LR2/trigger.sql

-- 2. Реализация автоинкрементного ключа и проверок уникальности


create sequence seq_students
start with 1
increment by 1
nocache;
/

create or replace trigger trg_students_autoinc
before insert on students
for each row
declare
    v_count number;
begin
    if :new.id is null then
        loop
            select seq_students.nextval into :new.id from dual;
            select count(*) into v_count
            from students
            where id = :new.id;
            exit when v_count = 0;
        end loop;
    end if;
end auto_increment_student_id;
/

create sequence seq_groups
start with 1
increment by 1
nocache;
/

create or replace trigger trg_groups_autoinc
before insert on groups
for each row
declare
    v_count number;
begin
    if :new.id is null then
        loop
            select seq_groups.nextval into :new.id from dual;
            select count(*) into v_count
            from groups
            where id = :new.id;
            exit when v_count = 0;
        end loop;
    end if;
end auto_increment_group_id;
/


CREATE OR REPLACE TRIGGER trg_check_unique_group_id
BEFORE INSERT ON GROUPS
FOR EACH ROW
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM GROUPS WHERE ID = :NEW.ID;
  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20002, ' THIS GROUP ID EXISTS!');
  END IF;
END;
/


CREATE OR REPLACE trigger check_group_name
BEFOR INSERT ON groups
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT count(*) INTO v_count
    FROM groups
    WHERE name = :new.name;

    IF v_count > 0 THEN
        raise_application_error(-20003, 'THIS GROUP NAME EXISTS');
    END IF;
END check_group_name;
/


-- Триггер проверки уникальности ID в STUDENTS (для демонстрации, так как PK уже обеспечивает уникальность)
CREATE OR REPLACE TRIGGER trg_check_unique_student_id
BEFORE INSERT ON STUDENTS
FOR EACH ROW
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM STUDENTS WHERE ID = :NEW.ID;
  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'THIS STUDENT ID EXISTS !');
  END IF;
END;
/

--------------------------------------------------------
-- 3. Триггер для каскадного удаления студентов при удалении группы
--------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_cascade_delete_students
BEFORE DELETE ON GROUPS
FOR EACH ROW
BEGIN
  DELETE FROM STUDENTS WHERE GROUP_ID = :OLD.ID;
END trg_cascade_delete_students;
/

--------------------------------------------------------
-- 4. Триггер для журналирования действий над таблицей STUDENTS
--------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_students_log
AFTER INSERT OR UPDATE OR DELETE ON STUDENTS
FOR EACH ROW
BEGIN
  IF INSERTING THEN
    INSERT INTO STUDENTS_LOG (STUDENT_ID, OPERATION, NEW_NAME, NEW_GROUP)
    VALUES (:NEW.ID, 'INSERT', :NEW.NAME, :NEW.GROUP_ID);
  ELSIF UPDATING THEN
    INSERT INTO STUDENTS_LOG (STUDENT_ID, OPERATION, OLD_NAME, NEW_NAME, OLD_GROUP, NEW_GROUP)
    VALUES (:OLD.ID, 'UPDATE', :OLD.NAME, :NEW.NAME, :OLD.GROUP_ID, :NEW.GROUP_ID);
  ELSIF DELETING THEN
    INSERT INTO STUDENTS_LOG (STUDENT_ID, OPERATION, OLD_NAME, OLD_GROUP)
    VALUES (:OLD.ID, 'DELETE', :OLD.NAME, :OLD.GROUP_ID);
  END IF;
END;
/

--------------------------------------------------------
-- 5. Процедура для восстановления информации в таблице STUDENTS
--------------------------------------------------------

-- Процедура принимает два параметра:
-- p_restore_time - исходное время восстановления,
-- p_offset - временное смещение (типа INTERVAL DAY TO SECOND),
-- итоговое время восстановления вычисляется как p_restore_time + p_offset.
CREATE OR REPLACE PROCEDURE RESTORE_STUDENTS(p_restore_time TIMESTAMP, p_offset INTERVAL DAY TO SECOND) IS
  v_effective_time TIMESTAMP;
BEGIN
  v_effective_time := p_restore_time + p_offset;
  
  -- Очистка таблицы STUDENTS
  DELETE FROM STUDENTS;
  
  -- Восстановление данных: для каждого STUDENT_ID выбирается последнее изменение до v_effective_time,
  -- если последняя операция не DELETE – запись вставляется.
  INSERT INTO STUDENTS (ID, NAME, GROUP_ID)
  SELECT l.STUDENT_ID,
         CASE WHEN s.OPERATION IN ('INSERT','UPDATE') THEN s.NEW_NAME ELSE s.OLD_NAME END AS NAME,
         CASE WHEN s.OPERATION IN ('INSERT','UPDATE') THEN s.NEW_GROUP ELSE s.OLD_GROUP END AS GROUP_ID
  FROM (
    SELECT STUDENT_ID, MAX(CHANGED_AT) AS max_time
    FROM STUDENTS_LOG
    WHERE CHANGED_AT <= v_effective_time
    GROUP BY STUDENT_ID
  ) l
  JOIN STUDENTS_LOG s
    ON s.STUDENT_ID = l.STUDENT_ID AND s.CHANGED_AT = l.max_time
  WHERE s.OPERATION <> 'DELETE';
  
  COMMIT;
END;
/


--------------------------------------------------------
-- 6. Триггер для обновления количества студентов (C_VAL) в таблице GROUPS
--------------------------------------------------------

CREATE OR REPLACE TYPE num_table as table of number;
/

CREATE OR REPLACE TRIGGER update_group_student_count_compound
FOR INSERT OR UPDATE OR DELETE ON students
COMPOUND TRIGGER

  affected_groups num_table := num_table();

AFTER EACH ROW IS
BEGIN
  IF INSERTING THEN
    IF :NEW.group_id IS NOT NULL THEN
      affected_groups.EXTEND;
      affected_groups(affected_groups.COUNT) := :NEW.group_id;
    END IF;

  ELSIF DELETING THEN
    IF :OLD.group_id IS NOT NULL THEN
      affected_groups.EXTEND;
      affected_groups(affected_groups.COUNT) := :OLD.group_id;
    END IF;

  ELSIF UPDATING THEN
    IF :OLD.group_id IS NOT NULL THEN
      affected_groups.EXTEND;
      affected_groups(affected_groups.COUNT) := :OLD.group_id;
    END IF;
    IF :NEW.group_id IS NOT NULL THEN
      affected_groups.EXTEND;
      affected_groups(affected_groups.COUNT) := :NEW.group_id;
    END IF;
  END IF;
END AFTER EACH ROW;

AFTER STATEMENT IS
BEGIN
  FOR rec IN (
    SELECT DISTINCT column_value AS group_id
    FROM TABLE(affected_groups)
  ) LOOP
    DECLARE
      v_exist NUMBER;
    BEGIN
      SELECT COUNT(*) INTO v_exist
      FROM groups
      WHERE id = rec.group_id;

      IF v_exist > 0 THEN
        UPDATE groups
          SET c_val = (SELECT COUNT(*) FROM students WHERE group_id = rec.group_id)
        WHERE id = rec.group_id;

        DBMS_OUTPUT.PUT_LINE('Updated group_id=' || rec.group_id);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END LOOP;
END AFTER STATEMENT;
END;
/