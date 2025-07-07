for /f "tokens=1,2 delims= " %%a in ('echo %date%') do (
  if %%b.==. (
    for /f "tokens=1,2,3 delims=/-" %%x in ('echo %%a') do echo %%z-%%y-%%x
  ) else (
    for /f "tokens=1,2,3 delims=/-" %%x in ('echo %%b') do echo %%z-%%y-%%x
  )
)
