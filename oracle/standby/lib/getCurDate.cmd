@echo off

if %1.==. (
  set deli=-
) else ( 
  set deli=%1
)

for /f "tokens=1,2 delims= " %%a in ('echo %date%') do (
  if %%b.==. (
    for /f "tokens=1,2,3 delims=/-" %%x in ('echo %%a') do echo %%z%deli%%%y%deli%%%x
  ) else (
    for /f "tokens=1,2,3 delims=/-" %%x in ('echo %%b') do echo %%z%deli%%%y%deli%%%x
  )
)
