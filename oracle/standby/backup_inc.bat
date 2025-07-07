::
::Crear backup RMAN 
::
@echo off
if %1.==. (
  echo falta definir sucursal 
  goto fin
)
if %2.==. ( 
  echo falta definir tipo de backup incremental [0=level 0, 1=level 1]
  goto fin
)
set SUC=%1
set LEVEL=%2
set current=%~dp0
rem for /f "tokens=2,3,4 delims=/- " %%a in ('echo %date%') do set fecha=%%c-%%b-%%a
if exist %systemroot%\system32\robocopy.exe ( set copiar=robocopy /e /purge ) else ( set copiar=xcopy /e /y )
set LOGGER=%current%lib\logger.exe -l 192.100.100.254 -a 514 -t STANDBY 
for /f "tokens=1 delims=, " %%a in ('%current%lib\getip') do set IPSERV=%%a
for /f "tokens=1 delims=, " %%a in ('%current%lib\getCurdate') do set FECHA=%%a
for /f "tokens=1 delims=, " %%a in ('echo %time%') do set hora=%%a
set LOGFILE=%temp%\backup_inc-%FECHA%.log

echo --------------------------------------------------------------------  >> %LOGFILE%
echo iniciando backup level %level% >> %LOGFILE%
echo iniciando backup level %LEVEL%
echo %fecha% %hora%   iniciando backup level %LEVEL% >> %LOGFILE%
@(
  echo backup as compressed backupset incremental level %level% database tag '%FECHA% %HORA% inc level %LEVEL%' plus archivelog tag '%FECHA% %HORA% inc level %LEVEL%';
  echo list backup of database summary;
  echo list backup of archivelog all summary;
  echo report obsolete;
) > %temp%\sql.sql
rman target sys/manager cmdfile=%temp%\sql.sql >> %LOGFILE%

echo verificando secuencia y rol de la base de datos
@(
  echo connect sys/manager as sysdba;
  echo set head off
  echo set echo off
  echo set linesize 515
  echo spool %temp%\estado.log;
  echo select max^(sequence#^) from v$archived_log;
  echo spool off;
  echo spool %temp%\modo.log;
  echo select database_role from v$database;
  echo exit;
) > %temp%\sql.sql
sqlplus /nolog @%temp%\sql.sql >> %LOGFILE%
FOR /F %%i in (%temp%\estado.log) do set SEQ=%%i
FOR /F %%i in (%temp%\modo.log) do set MODO=%%i

set log=date=%FECHA% %HORA%, suc=%SUC%, ip=%IPSERV%, tipo=PRIMARY, modo=%MODO%, operacion=RMAN_BACKUP_LEVEL_%LEVEL%, estado=OK, sequence=%SEQ%
echo %log%
echo %log% >> %LOGFILE%
%LOGGER% %log% >> %LOGFILE%
echo --------------------------------------------------------------------  >> %LOGFILE%


:fin