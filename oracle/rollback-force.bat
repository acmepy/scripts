@echo off
setlocal

::
:: formato sucursales.txt
:: <usuario>/<clave>@<base de datos>
::
for /f "tokens=*" %%a in (sucursales.txt) do (
  for /f "tokens=2 delims=@" %%b in ("%%a") do (
    echo Procesando %%b
  )
  del %tmp%\exe.sql
  del %tmp%\rollback.sql
  @(
    echo set linesize 1000
    echo spool %tmp%\rollback.sql
    echo select 'rollback force '''^|^|local_tran_id^|^|''';' from dba_2pc_pending where state = 'prepared';
    echo spool off;
    echo exit;
  )> %tmp%\exe.sql
 sqlplus %%a @%tmp%\exe.sql
 echo exit; >> %tmp%\rollback.sql
 sqlplus %%a @%tmp%\rollback.sql
)

