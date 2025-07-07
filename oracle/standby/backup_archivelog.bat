::
:: backup acumulativo de archivelog
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
if exist "%PROGRAMFILES%\WinRar\Rar.exe" (
  set rar="%PROGRAMFILES%\WinRar\Rar.exe"
) else (
  echo no se encuentra winrar
  goto fin
)
if exist %systemroot%\system32\robocopy.exe ( set copiar=robocopy /e /purge ) else ( set copiar=xcopy /e /y )
set ARCIVELOG=C:\oraclexe\app\oracle\fast_recovery_area\XE\ARCHIVELOG
set ARCLOGBKP=%BKP%\archivelog.rar 
set LOGGER=%current%lib\logger.exe -l 192.100.100.254 -a 514 -t STANDBY 
for /f "tokens=1 delims=, " %%a in ('%current%lib\getip') do set IPSERV=%%a
for /f "tokens=1 delims=, " %%a in ('%current%lib\getCurdate') do set FECHA=%%a
for /f "tokens=1 delims=, " %%a in ('echo %time%') do set hora=%%a
for /f "tokens=1 delims=, " %%a in ('%current%lib\getCurdate _') do set CARPETA=%%a
set LOGFILE=%temp%\backup_archivelog-%FECHA%.log

echo --------------------------------------------------------------------  >> %LOGFILE%
echo iniciando compresion de archivelog >> %LOGFILE%
echo iniciando compresion de archivelog
echo %fecha% %hora%   iniciando compresion de archivelog >> %LOGFILE%

%rar% a %ARCLOGBKP% %ARCHIVELOG%\%CARPETA%

set log=date=%FECHA% %HORA%, suc=%SUC%, ip=%IPSERV%, tipo=PRIMARY, modo=%MODO%, operacion=BACKUP_ARCHIVELOG, estado=OK, sequence=%SEQ%
echo %log%
echo %log% >> %LOGFILE%
%LOGGER% %log%
echo --------------------------------------------------------------------  >> %LOGFILE%


:fin
