@echo off
set LOGGER=%BKP%\logger.exe -l 192.100.100.254 -a 514 -t STANDBY
set LOGFILE=%temp%\standby_rw-%FECHA%.log

echo cambiando modo de la base de datos
@(
  echo connect / as sysdba;
  echo shutdown immediate;
  echo startup nomount
  echo alter database mount standby database;
  echo alter database activate standby database;
  echo select controlfile_type from v$database;
  echo alter database open;
  echo exit;
) > %temp%\sql.sql
sqlplus /nolog @%temp%\sql.sql > %LOGFILE%

echo verificando secuencia y rol de la base de datos
@(
  echo connect / as sysdba;
  echo set head off
  echo set echo off
  echo set linesize 515
  echo spool %temp%\estado.log;
  echo select max^(sequence#^) from v$archived_log;
  echo spool off;
  echo spool %temp%\modo.log;
  echo select replace^(database_role, ' ', '_'^) from v$database;
  echo exit;
) > %temp%\sql.sql
sqlplus /nolog @%temp%\sql.sql >> %LOGFILE%
FOR /F %%i in (%temp%\estado.log) do set SEQ=%%i
FOR /F %%i in (%temp%\modo.log) do set MODO=%%i

set log=date=%fecha% %hora%, suc=%suc%, ip=%IPSERV%, tipo=STANDBY, modo=%MODO%, estado=OK, sequence=%SEQ%
echo %log%
echo %log%  >> %LOGFILE%
%LOGGER% %log% >> %LOGFILE%

:fin