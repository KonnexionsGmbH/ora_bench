/*
    ora_bench - database setup.
*/

SET ECHO OFF
SET FEEDBACK OFF
SET HEADING OFF
SET LINESIZE 200
SET PAGESIZE 0
SET SERVEROUTPUT ON FORMAT WRAPPED SIZE UNLIMITED
SET TAB          OFF
SET VERIFY       OFF
WHENEVER SQLERROR EXIT sql.sqlcode ROLLBACK;

BEGIN
    DBMS_OUTPUT.put_line ('================================================================================');
    DBMS_OUTPUT.put_line ('Current user is now: ' || USER);
    DBMS_OUTPUT.put_line ('================================================================================');
    DBMS_OUTPUT.put_line ('Start run_bench_setup.sql');
END;
/

DECLARE
    l_username                     VARCHAR2 (128);
    l_sql_stmnt                    VARCHAR2 (4000);
BEGIN
    DBMS_OUTPUT.put_line ('================================================================================');
    DBMS_OUTPUT.put_line ('Adding database schema SCOTT ...');
    DBMS_OUTPUT.put_line ('<------------------------------------------------------------------------------>');

    SELECT USERNAME
      INTO l_username
      FROM SYS.ALL_USERS
     WHERE USERNAME = 'SCOTT';

    DBMS_OUTPUT.put_line ('Database schema SCOTT is already existing !!!');
EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
        l_sql_stmnt := 'CREATE USER SCOTT IDENTIFIED BY regit';
        EXECUTE IMMEDIATE l_sql_stmnt;
        DBMS_OUTPUT.put_line ('Executed: ' || l_sql_stmnt);
END;
/

DECLARE
    l_sql_stmnt                    VARCHAR2 (4000);
BEGIN
    DBMS_OUTPUT.put_line ('================================================================================');
    DBMS_OUTPUT.put_line ('Granting privileges to schema SCOTT ...');
    DBMS_OUTPUT.put_line ('<------------------------------------------------------------------------------>');

    l_sql_stmnt := 'GRANT ALTER SYSTEM TO SCOTT';
    EXECUTE IMMEDIATE l_sql_stmnt;
    DBMS_OUTPUT.put_line ('Executed: ' || l_sql_stmnt);

    l_sql_stmnt := 'GRANT CREATE PROCEDURE TO SCOTT';
    EXECUTE IMMEDIATE l_sql_stmnt;
    DBMS_OUTPUT.put_line ('Executed: ' || l_sql_stmnt);

    l_sql_stmnt := 'GRANT CREATE SESSION TO SCOTT';
    EXECUTE IMMEDIATE l_sql_stmnt;
    DBMS_OUTPUT.put_line ('Executed: ' || l_sql_stmnt);

    l_sql_stmnt := 'GRANT CREATE TABLE TO SCOTT';
    EXECUTE IMMEDIATE l_sql_stmnt;
    DBMS_OUTPUT.put_line ('Executed: ' || l_sql_stmnt);

    l_sql_stmnt := 'GRANT UNLIMITED TABLESPACE TO SCOTT';
    EXECUTE IMMEDIATE l_sql_stmnt;
    DBMS_OUTPUT.put_line ('Executed: ' || l_sql_stmnt);
END;
/


BEGIN
    DBMS_OUTPUT.put_line ('--------------------------------------------------------------------------------');
    DBMS_OUTPUT.put_line ('End   run_bench_setup.sql');
    DBMS_OUTPUT.put_line ('================================================================================');
END;
/

EXIT
