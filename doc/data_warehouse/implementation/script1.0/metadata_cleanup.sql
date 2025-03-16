-- SQL script to create tables for metadata
-- sys, cdb

ALTER SESSION set container=toronto_shared_bike;
show user;
show con_name;

DROP TRIGGER app_admin.trg_update_metadata_dim_time;

DROP TABLE app_admin.metadata_column;
DROP TABLE app_admin.metadata_table;
