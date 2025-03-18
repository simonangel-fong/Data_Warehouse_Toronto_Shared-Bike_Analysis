-- 
set sqlblanklines on

@CDB_config.sql
@PDB_Cleanup.sql
@PDB_Creation.sql
@TBSP_Creation.sql
@Schema_Creation.sql
@DW_Creation.sql
@ELT-Creation.sql
@MV_Creation.sql

exit