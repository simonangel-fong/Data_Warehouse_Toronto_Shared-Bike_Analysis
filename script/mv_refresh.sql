
SET SERVEROUTPUT ON;
ALTER SESSION SET container=toronto_shared_bike;

EXEC dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS')|| ' Refresh MV mv_temporal_summary.');
EXEC DBMS_MVIEW.refresh('app_admin.mv_temporal_summary');

EXEC dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS')|| ' Refresh MV mv_station_summary.');
EXEC DBMS_MVIEW.refresh('app_admin.mv_station_summary');

EXEC dbms_output.put_line(to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS')|| ' Refresh MV mv_user_summary.');
EXEC DBMS_MVIEW.refresh('app_admin.mv_user_summary');