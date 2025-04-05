ALTER SESSION SET CONTAINER=toronto_shared_bike;
show con_name
show user

CREATE ROLE apiTesterRole;
GRANT SELECT ON DW_SCHEMA.MV_USER_SEGMENTATION TO apiTesterRole;

CREATE USER apiTester1 IDENTIFIED BY "apiTester123";
GRANT create session, apiTesterRole TO apiTester1;