::
::eliminar backup obsoleto RMAN
::
@echo off
if %1.==. (
  echo falta definir sucursal 
  goto fin
)
set SUC=%1
set current=%~dp0
rem for /f "tokens=2,3,4 delims=/- " %%a in ('echo %date%') do set fecha=%%c-%%b-%%a
if exist %systemroot%\system32\robocopy.exe ( set copiar=robocopy /e /purge ) else ( set copiar=xcopy /e /y )
set LOGGER=%current%lib\logger.exe -l 192.100.100.254 -a 514 -t STANDBY 
for /f "tokens=1 delims=, " %%a in ('%current%lib\getip') do set IPSERV=%%a
for /f "tokens=1 delims=, " %%a in ('%current%lib\getCurdate') do set FECHA=%%a
for /f "tokens=1 delims=, " %%a in ('echo %time%') do set hora=%%a
set LOGFILE=%temp%\standby_delete_archivelog-%FECHA%.log

echo --------------------------------------------------------------------  >> %LOGFILE%
echo iniciando backup full >> %LOGFILE%
echo iniciando backup full
echo %fecha% %hora%   iniciando backup full >> %LOGFILE%
@(
  echo delete force noprompt archivelog until time 'sysdate-30'; 
) > %temp%\sql.sql
rman target / cmdfile=%temp%\sql.sql >> %LOGFILE%

set log=date=%FECHA% %HORA%, suc=%SUC%, ip=%IPSERV%, tipo=STANDBY, modo=%MODO%, operacion=DELETE_ARCHIVLELOG, estado=OK, sequence=%SEQ%
echo %log%
echo %log% >> %LOGFILE%
%LOGGER% %log% >> %LOGFILE%
echo --------------------------------------------------------------------  >> %LOGFILE%


:fin
