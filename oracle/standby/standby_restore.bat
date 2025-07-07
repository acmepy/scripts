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
set TAIL=%BKP%\lib\tail
set LOGFILE=%temp%\restore-%FECHA%.log
echo --------------------------------------------------------------------  >> %LOGFILE%
echo %fecha% %hora%  iniciando >> %LOGFILE%

echo verificando que este en modo READ ONLY
@(
   echo connect / as sysdba;
   echo set head off
   echo set echo off
   echo set linesize 515
   echo spool %temp%\openmode.log;
   echo select replace^(open_mode, ' ', '_'^) from v$database;
   echo exit
) > %temp%\sql.sql
sqlplus /nolog @%temp%\sql.sql >> %LOGFILE%
FOR /F %%i in (%temp%\openmode.log) do set LOGMODE=%%i
if %LOGMODE%.==READ_ONLY. goto restore
%logger% Date=%fecha% %hora%, suc=%suc%, estado=%LOGMODE%, sequence=%SEQ%, estado=FAIL, msg=La base de datos en modo %LOGMODE%  >> %LOGFILE%
echo La Base de datos no esta en modo solo lectura
goto fin

:restore
  set ARCIVELOG=C:\oraclexe\app\oracle\fast_recovery_area\XE\ARCHIVELOG
  set ARCLOGBKP=%BKP%\ARCHIVELOG
  echo copiando archivelog
  %copiar% %ARCLOGBKP% %ARCIVELOG% >> %LOGFILE%

  echo recuperando desde archivelog
  @(
    echo connect / as sysdba;
    echo set head off
    echo set echo off
    echo set linesize 515
    echo recover standby database;
    echo auto
    echo alter database open read only;
    echo spool %temp%\openmode.log;
    echo select replace^(open_mode, ' ', '_'^) from v$database;
    echo exit;
  ) > %temp%\sql.sql
  sqlplus /nolog @%temp%\sql.sql >> %LOGFILE%
  FOR /F %%i in (%temp%\openmode.log) do set LOGMODE=%%i
  echo %LOGMODE%
  if %LOGMODE%.==READ_ONLY. (
    call :status
  )
  goto fin

:status
  echo verificando estado
  @(
    echo connect / as sysdba;
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
  sqlplus /nolog @%temp%\sql.sql >> %LOGFILE%
  FOR /F %%i in (%temp%\estado.log) do set SEQ=%%i
  FOR /F %%i in (%temp%\modo.log) do set MODO=%%i

  set log=date=%fecha% %hora%, suc=%suc%, ip=%IPSERV%, tipo=STANBY, modo=%MODO%, operacion=RESTORE, estado=OK, sequence=%SEQ%
  echo %log%
  echo %log% >> %LOGFILE%
  %LOGGER% %log% >> %LOGFILE%

  for /f "tokens=1 delims=, " %%a in ('%current%lib\getCurdate') do set FECHA=%%a
  for /f "tokens=1 delims=, " %%a in ('echo %time%') do set hora=%%a

  echo %FECHA% %HORA% finalizado >> %LOGFILE%
  echo -------------------------------------------------------------------- >> %LOGFILE%
:fin
