::
:: configurar y generar archivos de la base primaria
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

:: verificando que exista el tns del standby
:: echo verificando que exista el tns del standby
:: for /f "tokens=1 delims=, " %%a in ('%current%lib\checktns standby') do set check=%%a
:: if %check%.==TNS-03505. (
::   echo Debe agregar el standby al tns del primario
:: )

set LOGGER=%current%lib\logger.exe -l 192.100.100.254 -a 514 -t STANDBY
for /f "tokens=1 delims=, " %%a in ('%current%lib\getip') do set IPSERV=%%a
for /f "tokens=1 delims=, " %%a in ('%current%lib\getCurdate') do set FECHA=%%a
for /f "tokens=1 delims=, " %%a in ('echo %time%') do set HORA=%%a
set ORACLEXE=c:\oraclexe
set ORADATA="C:\oraclexe\app\oracle\oradata"
set ARCHIVELOG=C:\oraclexe\app\oracle\fast_recovery_area\XE\ARCHIVELOG
set BKPDATA=%BKP%\oradata
set BKPARCHIVELOG=%BKP%\ARCHIVELOG
set LOGFILE=%temp%\primario-%FECHA%.log

echo limpiando carpetas y archivos
if not exist %BKP% mkdir %BKP%
if exist %ORACLEXE%\CONTROL.DBF del %ORACLEXE%\CONTROL.DBF
if exist %BKPDATA% rmdir /s /q %BKPDATA%
if exist %BKPARCHIVELOG% rmdir /s /q %BKPARCHIVELOG%
if not exist %BKPDATA% mkdir %BKPDATA%
if not exist %BKPARCHIVELOG% mkdir %BKPARCHIVELOG%
if exist %systemroot%\system32\robocopy.exe ( set copiar=robocopy /e /purge ) else ( set copiar=xcopy /s /e /y )

echo cerrando base de datos
@(
  echo conn sys/manager as sysdba;
  echo shutdown immediate;
  echo startup mount;
  echo alter database archivelog;
  echo alter database open;
  echo shutdown immediate;
  echo exit;
) > %temp%\sql.sql
sqlplus /nolog @%temp%\sql.sql > %LOGFILE%

echo copiando archivos
%copiar% %ORADATA% %BKPDATA% >> %LOGFILE%

echo creando archivo de control
@(
  echo conn sys/manager as sysdba;
  echo startup mount;
  echo alter database create standby controlfile as '%ORACLEXE%\CONTROL.DBF';
  echo alter database open;
  echo alter system archive log current;
  echo alter system switch LOGFILE;
  echo exit;
) > %temp%\sql.sql
sqlplus /nolog @%temp%\sql.sql >> %LOGFILE%

echo copiando archivo de control y archivelog
move %BKPDATA%\XE\CONTROL.DBF %BKPDATA%\XE\CONTROL_OLD.DBF  >> %LOGFILE%
rem %copiar% %ORACLEXE%\CONTROL.DBF %BKPDATA%\XE\  >> %LOGFILE%
copy %ORACLEXE%\CONTROL.DBF %BKPDATA%\XE\
%copiar% %ARCHIVELOG% %BKPARCHIVELOG% >> %LOGFILE%

echo verificando secuencia y rol de la base de datos
@(
  echo conn sys/manager as sysdba;
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
set log=date=%FECHA% %HORA%, suc=%suc%, ip=%IPSERV%, tipo=PRIMARY, modo=%MODO%, operacion=CREATE_PRIMARY, estado=OK, sequence=%SEQ%
echo %log%
echo %log%  >> %LOGFILE%
%LOGGER% %log%

:fin