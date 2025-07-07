::
::restaurar archivelog en standby
::
@echo off
if %1.==. ( 
  echo falta definir sucursal 
  goto fin
)
if %2.==. ( 
  echo falta definir carpeta de backup
  goto fin
)
set SUC=%1
set BKP=%2
set current=%~dp0
rem for /f "tokens=2,3,4 delims=/- " %%a in ('echo %date%') do set fecha=%%c-%%b-%%a
if exist %systemroot%\system32\robocopy.exe ( set copiar=robocopy /e /purge ) else ( set copiar=xcopy /s /e /y )
set LOGGER=%current%lib\logger.exe -l 192.100.100.254 -a 514 -t STANDBY
for /f "tokens=1 delims=, " %%a in ('%current%lib\getip') do set IPSERV=%%a
for /f "tokens=1 delims=, " %%a in ('%current%lib\getCurdate') do set FECHA=%%a
for /f "tokens=1 delims=, " %%a in ('echo %time%') do set hora=%%a
set ARCHIVELOG=C:\oraclexe\app\oracle\fast_recovery_area\XE\ARCHIVELOG
set BKPARCHIVELOG=%BKP%\ARCHIVELOG
set logfile=%temp%\backup-%FECHA%.log

cd %STANDBY%\
echo -------------------------------------------------------------------- >> %logfile%
echo %fecha% %hora% iniciando >> %logfile%

echo generando archivelog
@(
  echo connect sys/manager as sysdba;
  echo alter system archive log current;
  echo exit;
) > %temp%\sql.sql
sqlplus /nolog @%temp%\sql.sql >> %logfile%

echo copiando archivelog
rem robocopy %ARCHIVELOG% %BKPARCHIVELOG% /e /purge 
%copiar% %ARCHIVELOG% %BKPARCHIVELOG% >> %logfile%

@(
  echo connect sys/manager as sysdba;
  echo set head off
  echo set echo off
  echo set linesize 515
  echo spool %temp%\estado.log;
  echo select sequence# from v$archived_log where first_time = ^(select max^(first_time^) from v$archived_log^);
  echo spool off;
  echo spool %temp%\modo.log;
  echo select replace^(database_role, ' ', '_'^) from v$database;
  echo exit;
) > %temp%\sql.sql
sqlplus /nolog @%temp%\sql.sql >> %logfile%
FOR /F %%i in (%temp%\estado.log) do set SEQ=%%i
FOR /F %%i in (%temp%\modo.log) do set MODO=%%i


set log=date=%fecha% %hora%, suc=%suc%, ip=%IPSERV%, tipo=PRIMARY, modo=%MODO%, operacion=ARCHIVELOG, estado=OK, sequence=%SEQ%
echo %log%
echo %log% >> %logfile%
%LOGGER% %log% >> %temp%\backup.log
echo %fecha% %hora% finalizado >> %logfile%
echo -------------------------------------------------------------------- >> %logfile%
