CREATE OR REPLACE PACKAGE toronto_shared_bike AS

    -------- PDB --------
    PROCEDURE create_pdb(
        p_pdb_name IN VARCHAR2,
        p_pdb_path IN VARCHAR2,
        p_pdb_admin IN VARCHAR2,
        p_pdb_admin_pwd IN VARCHAR2
    );
   
    -------- User --------
    PROCEDURE create_admin(
        p_pdb_name IN varchar2,
        p_username IN varchar2, 
        p_user_pwd IN varchar2
    );
    
    -------- Log --------
    PROCEDURE create_log_directory(
        p_pdb_name IN VARCHAR2,
        p_log_dir_name IN VARCHAR2,
        p_log_path IN VARCHAR2
    );
    
    PROCEDURE write_log(
        p_log_dir IN VARCHAR2,
        p_log_file IN VARCHAR2,
        p_message IN VARCHAR2
    );
    
END toronto_shared_bike;
/

CREATE OR REPLACE PACKAGE BODY toronto_shared_bike AS
 
    -------- private variables --------
    pro_base_path VARCHAR2(100);
    pdb_path VARCHAR2(100);

    -- Function to get the project base path
    FUNCTION get_pro_base_path return VARCHAR2 IS
    BEGIN
        return nvl(
                  pro_base_path, 'Undefine'
               );
    END get_pro_base_path;
    -- Procedure to set the project base path
    PROCEDURE set_pro_base_path(
        p_pro_base_path IN VARCHAR2
    )IS
    BEGIN
        pro_base_path := p_pro_base_path;
    END set_pro_base_path;

    -- Function to get the pdb path
    FUNCTION get_pdb_path return VARCHAR2 IS
    BEGIN
        return pdb_path;
    EXCEPTION
        WHEN no_data_found THEN return null;
    END get_pdb_path;
    -- Procedure to set the pdb path
    PROCEDURE set_pdb_path(
        p_pdb_path IN VARCHAR2
    )IS
    BEGIN
        pdb_path := p_pdb_path;
    END set_pdb_path;

    ---------------- PDB ----------------
    -- Function to check whether pdb exists
    FUNCTION check_pdb_exists(
        p_pdb_name IN VARCHAR2
    )RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT
            COUNT(*)
        INTO v_count
        FROM
            dba_pdbs
        WHERE
            pdb_name = upper(p_pdb_name);

        IF v_count > 0 THEN RETURN 1;
     -- PDB exists
        ELSE RETURN 0;
     -- PDB does not exist
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
        -- Handle exception and return FALSE indicating that the check failed
         RETURN 0;
    END check_pdb_exists;

    -- Procedure to drop pdb
    PROCEDURE drop_pdb(p_pdb_name IN VARCHAR2) AS
        sql_cmd VARCHAR2(10) := '';
    BEGIN
        -- alter session to root
        sql_cmd := 'ALTER SESSION SET CONTAINER = CDB$ROOT';
        EXECUTE IMMEDIATE sql_cmd;
        DBMS_OUTPUT.PUT_LINE('Alter session to root');
        
        -- Close the PDB if it is open
        sql_cmd := 'ALTER PLUGGABLE DATABASE ' || p_pdb_name || ' CLOSE IMMEDIATE';
        EXECUTE IMMEDIATE sql_cmd;
        DBMS_OUTPUT.PUT_LINE('Close PDB');

        -- Drop the PDB, including data files
        EXECUTE IMMEDIATE 'DROP PLUGGABLE DATABASE ' || p_pdb_name || ' INCLUDING DATAFILES';
        DBMS_OUTPUT.PUT_LINE('DROP PDB');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Dropping PDB ' || p_pdb_name);
            dbms_output.put_line(sqlerrm);
    END drop_pdb;
    
    -- Procedure to create pdb
    PROCEDURE create_pdb(
        p_pdb_name IN VARCHAR2,
        p_pdb_path IN VARCHAR2,
        p_pdb_admin IN VARCHAR2,
        p_pdb_admin_pwd IN VARCHAR2
    ) AS    
        v_sql_cmd VARCHAR2(500);
        v_count NUMBER := 0;
    BEGIN
        -- alter session to root
        v_sql_cmd := 'ALTER SESSION SET container=cdb$root';
        EXECUTE IMMEDIATE v_sql_cmd;
        dbms_output.put_line('Alter session to root.');
        
        -- Query to check whether pdb exists.
        SELECT COUNT(*) INTO v_count
        FROM dba_pdbs
        WHERE pdb_name = upper(p_pdb_name);
    
        -- IF exists
        IF v_count > 0 THEN
            dbms_output.put_line('PDB exists.');
            
            -- Check if the pdb open
            SELECT count(*) INTO v_count
            FROM v$pdbs 
            WHERE name = upper(p_pdb_name)
            AND open_mode = 'READ WRITE';
            
            -- IF open
            IF v_count > 0 THEN
                dbms_output.put_line('PDB is opened.');
                
                -- close pdb
                v_sql_cmd := 'ALTER PLUGGABLE DATABASE ' || p_pdb_name || ' CLOSE IMMEDIATE';
                EXECUTE IMMEDIATE v_sql_cmd;
                dbms_output.put_line('PDB has been closed.');
                
            -- IF close
            ELSE 
                dbms_output.put_line('PDB is closed.');
            END IF;
            
            -- Drop PDB
            v_sql_cmd := 'DROP PLUGGABLE DATABASE ' || p_pdb_name || ' INCLUDING DATAFILES';
            EXECUTE IMMEDIATE v_sql_cmd;
            dbms_output.put_line('PDB has been dropped.');
        ELSE
            -- if not exist
            dbms_output.put_line('PDB does not exist.');
        END IF;
        
        -- Create pdb.
        v_sql_cmd := 'CREATE PLUGGABLE DATABASE ' || p_pdb_name || 
            ' ADMIN USER ' || p_pdb_admin || ' IDENTIFIED BY ' || p_pdb_admin_pwd || 
            ' ROLES=(DBA) DEFAULT TABLESPACE users ' || 
            ' DATAFILE ''' || p_pdb_path || p_pdb_name || '/users01.dbf''' || 
            ' SIZE 1M AUTOEXTEND ON NEXT 1M ' || 
            ' FILE_NAME_CONVERT=(''' || p_pdb_path || 'pdbseed/'', ''' || p_pdb_path || p_pdb_name || '/'' )';
        EXECUTE IMMEDIATE v_sql_cmd;
        dbms_output.put_line(p_pdb_name|| 'has been created.');
            
        -- Open PDB
        v_sql_cmd := 'ALTER PLUGGABLE DATABASE '|| p_pdb_name|| ' OPEN';
        EXECUTE IMMEDIATE v_sql_cmd;
        dbms_output.put_line(p_pdb_name|| ' has been opened.');
        
        -- Open PDB save state
        v_sql_cmd := 'ALTER PLUGGABLE DATABASE '|| p_pdb_name|| ' SAVE STATE';
        EXECUTE IMMEDIATE v_sql_cmd;
        dbms_output.put_line(p_pdb_name|| ' state has been saved.');
            
    EXCEPTION
        WHEN OTHERS THEN 
            -- output other error message
            dbms_output.put_line('Error: ');
            dbms_output.put_line(sqlerrm);
    END create_pdb;

    -- Procedure to create user
    PROCEDURE create_admin(
        p_pdb_name IN varchar2,
        p_username IN varchar2, 
        p_user_pwd IN varchar2
    )IS
        v_sql_cmd varchar(200);
    BEGIN
        -- alter session to pdb
        v_sql_cmd := 'ALTER SESSION SET container=' || p_pdb_name;
        EXECUTE IMMEDIATE v_sql_cmd;
        dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS:')||' Alter session to ' || p_pdb_name);
    
        -- create user
        v_sql_cmd := 'CREATE USER '|| p_username|| ' IDENTIFIED BY '|| p_user_pwd ||
            ' DEFAULT TABLESPACE users '||
            ' TEMPORARY TABLESPACE TEMP '||
            ' QUOTA UNLIMITED ON users';
        EXECUTE IMMEDIATE(v_sql_cmd);
        dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS:')||' Create user '||p_username);
    
        -- gran priv
        v_sql_cmd := 'grant create session to '||p_username;
        EXECUTE IMMEDIATE(v_sql_cmd);
        dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS:')||' Grant create session to '||p_username);
    
        -- gran priv
        v_sql_cmd := 'grant resouce, create table to '||p_username;
        EXECUTE IMMEDIATE(v_sql_cmd);
        dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS:')||' Grant resource to '||p_username);
    
        dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS:')||' Create user '||p_username||' completed.');
    EXCEPTION
        WHEN OTHERS THEN
        -- output error
        dbms_output.put_line('Error:');
        dbms_output.put_line(sqlerrm);
    END;

    ---------------- Log ----------------
    -- Procedure to create directory for logging.
    PROCEDURE create_log_directory(
        p_pdb_name IN VARCHAR2,
        p_log_dir_name IN VARCHAR2,
        p_log_path IN VARCHAR2
    )
    IS
        v_sql_cmd VARCHAR2(200);
        v_count number :=0;
    BEGIN
        -- Alter session to pdb
        v_sql_cmd := 'ALTER SESSION set container='||p_pdb_name;
        EXECUTE IMMEDIATE v_sql_cmd;
        dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS:')||' Alter session to PDB'||p_pdb_name);
        
        -- create dir
        v_sql_cmd := 'CREATE OR REPLACE DIRECTORY '|| p_log_dir_name|| ' AS '''||p_log_path|| '''';
        EXECUTE IMMEDIATE v_sql_cmd;
        dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS:')||' Log directory has been created.');
    EXCEPTION
        WHEN OTHERS THEN 
            -- output error
            dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS:')||' Error: ');
            dbms_output.put_line(sqlerrm);
    END create_log_directory;
    -- Procedure to write message to log file.
    PROCEDURE write_log(
            p_log_dir IN VARCHAR2,
            p_log_file IN VARCHAR2,
            p_message IN VARCHAR2
    )
    IS
        v_file utl_file.file_type;
        v_msg VARCHAR2(400);
    BEGIN
        -- ref of log file
        v_file := utl_file.fopen(upper(p_log_dir), p_log_file, 'A');
            
        -- message
        v_msg := to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS')|| ' '|| p_message;
            
        -- Write the message to the file
        utl_file.put_line(v_file, v_msg);
        -- Close the file
        utl_file.fclose(v_file);
        dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS')|| ' Write message to log file: ' || p_message);
    EXCEPTION
        WHEN OTHERS THEN
            -- output error
            dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS')|| ' Error:');
            dbms_output.put_line(sqlerrm);
    END write_log;

    ---------------- Warehouse ----------------
    

END toronto_shared_bike;
/
