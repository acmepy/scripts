@echo off
set ip_address_string="IPv4"
for /f "usebackq tokens=2 delims=:" %%f in (`ipconfig ^| findstr /c:%ip_address_string%`) do set ip=%%f
if %ip%.==. (
    for /f "usebackq tokens=2 delims=:" %%x in (`ipconfig ^| findstr /c:IP`) do set ip=%%x
)
echo %ip%