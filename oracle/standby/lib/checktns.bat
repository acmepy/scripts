::
:: verificar si existe el tns
::

@echo off
if %1.==. ( 
  echo falta definir el tns
  goto fin
)
set tns=%1

for /f "tokens=1 delims=:" %%a in ('tnsping %tns%') do set xyz=%%a

echo %xyz%