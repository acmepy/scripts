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
for /f "tokens=1 delims=, " %%a in ('%current%lib\getCurdate') do set FECHA=%%a
for /f "tokens=1 delims=, " %%a in ('echo %time%') do set HORA=%%a
set ORADATA="C:\oraclexe\app\oracle\oradata"
set BKPDATA="%BKP%\oradata"
set STANDBY=%BKP%
set ARCHIVELOG=C:\oraclexe\app\oracle\fast_recovery_area\XE\ARCHIVELOG
set ARCLOGBKP=%BKP%\ARCHIVELOG
for /f "tokens=1 delims=, " %%a in ('%BKP%\lib\getip') do set IPSERV=%%a
set LOGFILE=%temp%\standby-%FECHA%.log

echo cerrando base de datos
@(
  echo connect / as sysdba;
  echo shutdown immediate;
  echo exit;
) > %temp%\sql.sql
sqlplus /nolog @%temp%\sql.sql  > %LOGFILE%

echo limpiando carpetas oradata y archivelog
rmdir /q /s %ORADATA%
mkdir %ORADATA%
rmdir /q /s %ARCHIVELOG%
mkdir %ARCHIVELOG%

echo copiando carpeta oradata
rem robocopy %BKPDATA% %ORADATA% /e /purge 
%copiar% %BKPDATA% %ORADATA% >> %LOGFILE%

echo copiando carpeta archivelog
rem robocopy %BKP%\ARCHIVELOG %ARCHIVELOG% /e /purge 
%copiar% %BKP%\ARCHIVELOG %ARCHIVELOG% >> %LOGFILE%

echo montando base de datos en modo standby
@(
  echo connect / as sysdba;
  echo startup nomount
  echo alter database mount standby database;
  echo recover standby database;
  echo auto
  echo alter database open read only;
  echo exit;
) > %temp%\sql.sql
sqlplus /nolog @%temp%\sql.sql >> %LOGFILE%

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

set log=date=%FECHA% %HORA%, suc=%SUC%, ip=%IPSERV%, tipo=STANDBY, modo=%MODO%, operacion=CREATE_STANDBY, estado=OK, sequence=%SEQ%
echo %log%
echo %log% >> %LOGFILE%
%LOGGER% %log% >> %LOGFILE%

:fin