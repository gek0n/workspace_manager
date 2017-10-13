@ECHO OFF

REM To ask if i want to close workspace
CHOICE /M "Do you want to close workspace?" /t 5 /D y
if %errorlevel%==2 exit /b 0
REM To read txt file with spaces in name line by line
FOR /F "tokens=*" %%A IN ('TYPE "%~dp0/workspace_list.txt"') DO (
    REM Call label as function with read line as an argument
    CALL :stop_with_delay %%A 
)
REM Go to end of file (exit batch file)
GOTO :EOF
:try_found_app_process
REM If app argument is present
IF [%2] == [] (
    REM search launched app without argument
    FOR /F "delims=" %%V in ('^(TASKLIST ^| FIND /I "%~xn1"^)') DO (CALL :get_pid %%V && EXIT /B 0)
) ELSE (
    REM search launched app with that argument
    FOR /F "delims=" %%V in ('^(^(TASKLIST /V ^| FIND /I "%~xn1"^) ^| FIND /I "%~n2"^)') DO (CALL :get_pid %%V && EXIT /B 0)
)
REM The ^ character escaped other symbols in FOR argument, which placed inside single quotes
EXIT /B 1
:get_pid
REM Input string automatic split with spaces, so pid would be second param
IF [%2] == [] (
    SET pid=
    EXIT /B 1
) ELSE (
    SET pid=%2
    EXIT /B 0
)
:stop_with_delay
REM Clear status variable
SET status=
REM Clear pid variable
SET pid=
REM Try find running process before stopping
(CALL :try_found_app_process %*) || (SET status=NOT FOUND& GOTO :print_and_exit)
REM If app is found, try stop it (only one time)
TASKKILL /PID %pid%
REM Do cycle delaying 3 times while app trying to stop
FOR /L %%i IN (1,1,3) DO (
    REM Try find stopped process
    (CALL :try_found_app_process %*) || (SET status=STOP& GOTO :print_and_exit)
    REM Wait 5 seconds without any output
    TIMEOUT /T 5 /NOBREAK 1>NUL
)
SET status=NOT STOPPED
:print_and_exit
REM Print status message
IF [%2] == [] (
    ECHO [%status%] %1
) ELSE (
    ECHO [%status%] %1 with %~xn2
)
REM Exit from label-like function
EXIT /B