@echo off
setlocal
::
:: formato sucursales.txt
:: <usuario>/<clave>@<base de datos>
::
for /f "tokens=*" %%a in (sucursales.txt) do call :process %%a
goto :fin

:process
set VAR1=%1
for /f "tokens=2 delims=@" %%b in ("%VAR1%") do echo Procesando %%b
if exist "%tmp%\exe.sql" ( del %tmp%\exe.sql )
@(
  echo set linesize 1000
  echo begin actualiza_datos_ruc; end;
  echo /
  echo select ^(select count^(0^) from sifen_datos_ruc ^) local, ^(select count^(0^) from sifen_datos_ruc@origen ^) central from dual;
  echo exit;
  echo /
)> %tmp%\exe.sql
sqlplus %VAR1% @%tmp%\exe.sql
goto :EOF


:fin
