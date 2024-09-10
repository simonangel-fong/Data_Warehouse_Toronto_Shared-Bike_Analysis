ALTER SESSION SET container=toronto_shared_bike;

EXEC dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS')|| ' Drop mv_temporal_summary.');
DROP MATERIALIZED VIEW app_admin.mv_temporal_summary;

EXEC dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS')|| ' Drop mv_station_summary.');
DROP MATERIALIZED VIEW app_admin.mv_station_summary;

EXEC dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS')|| ' Drop MV mv_user_summary.');
DROP MATERIALIZED VIEW app_admin.mv_user_summary;