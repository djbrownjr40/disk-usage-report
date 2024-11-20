@echo off
setlocal

REM Set variables
set "THRESHOLD=1"
set "LOG_FILE=C:\"
set "EMAIL_TO=user@xyz"
set "SMTP_SERVER=smtp.xyz.com"
set "SMTP_USER=user@xyz.com"
set "SMTP_PASS=password"

REM Initialize variables
set "FREE_SPACE=0"
set "TOTAL_SPACE=0"

REM Get disk usage using PowerShell
for /f "tokens=1,2" %%a in ('powershell -command "Get-PSDrive C | Select-Object @{Name='Free';Expression={($_.Used)}}, @{Name='Total';Expression={($_.Used + $_.Free)}}"') do (
    set "FREE_SPACE=%%a"
    set "TOTAL_SPACE=%%b"
)

REM Output values for debugging
echo FREE_SPACE: %FREE_SPACE%
echo TOTAL_SPACE: %TOTAL_SPACE%

REM Check if the variables were set correctly
if "%FREE_SPACE%"=="0" (
    echo Error: Could not retrieve FreeSpace or it is 0.
    exit /b 1
) else (
    echo Free space is available.
)

if "%TOTAL_SPACE%"=="0" (
    echo Error: Could not retrieve TotalSpace or it is 0.
    exit /b 1
) else (
    echo Total space is available.
)

REM Calculate used space and percentage using PowerShell
for /f "tokens=1" %%u in ('powershell -command "[math]::Round((%TOTAL_SPACE% - %FREE_SPACE%) * 100 / %TOTAL_SPACE%)"') do set "USAGE_PERCENT=%%u"

REM Convert spaces to GB using PowerShell
for /f "tokens=1" %%g in ('powershell -command "[math]::Round(%FREE_SPACE% / 1GB)"') do set "FREE_SPACE_GB=%%g"
for /f "tokens=1" %%h in ('powershell -command "[math]::Round(%TOTAL_SPACE% / 1GB)"') do set "TOTAL_SPACE_GB=%%h"
set /a "USED_SPACE_GB=%TOTAL_SPACE_GB% - %FREE_SPACE_GB%"

REM Log the usage
echo Disk Usage Report - %DATE% %TIME% >> "%LOG_FILE%"
echo Total Space: %TOTAL_SPACE_GB% GB >> "%LOG_FILE%"
echo Used Space: %USED_SPACE_GB% GB >> "%LOG_FILE%"
echo Free Space: %FREE_SPACE_GB% GB >> "%LOG_FILE%"
echo Usage Percentage: %USAGE_PERCENT%%% >> "%LOG_FILE%"

REM Check if usage exceeds threshold
if %USAGE_PERCENT% GEQ %THRESHOLD% (
    powershell -Command "Send-MailMessage -From '%SMTP_USER%' -To '%EMAIL_TO%' -Subject 'Disk Usage Alert' -Body 'Disk usage has reached %USAGE_PERCENT%%%. Check the logs for details.' -SmtpServer '%SMTP_SERVER%' -Port 587 -UseSsl -Credential (New-Object System.Management.Automation.PSCredential('%SMTP_USER%', (ConvertTo-SecureString '%SMTP_PASS%' -AsPlainText -Force)))"
)

endlocal
