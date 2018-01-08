@ECHO OFF
CHCP 1251
REM Add TRUE value in line below to enable PAUSE command after stop executing batch
SET waitBeforeClose=
REM Delete value in line below to turn off logging
SET logFile="workspace.log"
SET logging=^> tmp.out ^&^& TYPE tmp.out ^&^& TYPE tmp.out ^>^> %logFile%
SET "LOG=CALL :log_proc "

REM To ask user if i want to start workspace
CHOICE /M "Do you want to open workspace?" /t 10 /D N
%LOG% "========================================================================="
%LOG% "Open workspace on %DATE% at %TIME%"
IF %errorlevel%==2 EXIT /B 0
REM To read txt file with spaces in name line by line
FOR /F "tokens=*" %%A IN ('TYPE "%~dp0/workspace_list.txt"') DO (
    REM Call label as function with read line as an argument
    CALL :start_with_delay %%A 
)
IF DEFINED waitBeforeClose PAUSE
%LOG% "========================================================================="
REM Go to end of file (exit batch file)
GOTO :EOF

:try_found_app_process
IF NOT ["%~4"] == [""] (
    REM Search with window name
    IF [%~x1] == [.bat] (
        REM search cmd.exe with window name
        ((TASKLIST /V | FIND /I "cmd.exe") | FIND /I "%~4" 1>NUL) && EXIT /B 0
    ) ELSE (
        REM search launched app with window name
        ((TASKLIST /V | FIND /I "%~xn1") | FIND /I "%~4" 1>NUL) && EXIT /B 0
    )
) ELSE (
    REM Search without window name
    IF [%~2] == [] (
        REM search launched app without argument
        (TASKLIST | FIND /I "%~xn1" 1>NUL) && EXIT /B 0
    ) ELSE (
        REM search launched app with that argument
        ((TASKLIST /V | FIND /I "%~xn1") | FIND /I "%~n2" 1>NUL) && EXIT /B 0
    )
    REM
)
EXIT /B 1

:start_with_delay
REM Clear status variable
SET status=
REM Try find running process before starting
(CALL :try_found_app_process %*) && (SET status=FOUND& GOTO :print_and_exit)
REM If app is not found, try start it (only one time)
REM Start app, if it`s path exists in PATH variable, 3 and 4 args not present
IF [%3] == [] IF [%4] == [] %~1 %~2

IF [%3] == [""] (
    REM Start without working directory
    START %4 %1 %2
) ELSE (
    REM Start with working directory
    START %4 /D %3 %1 %~2
)
REM Do cycle delaying 3 times while app trying to start
FOR /L %%i IN (1,1,3) DO (
    REM Try find starting process
    (CALL :try_found_app_process %*) && (SET status=START& GOTO :print_and_exit)
    REM Wait 5 seconds without any output
    TIMEOUT /T 5 /NOBREAK 1>NUL
)
SET status=NOT STARTED
:print_and_exit
REM Print status message
IF [%~2] == [] (
    %LOG% "[%status%] %~1"
) ELSE (
    %LOG% "[%status%] %~1 with %~xn2"
)
REM Exit from lable-like function
EXIT /B

:log_proc
ECHO %~1 %logging%
DEL /Q tmp.out
EXIT /B 0

REM Stolen from https://stackoverflow.com/questions/5534324/how-to-run-multiple-programs-using-batch-file
REM @ECHO OFF
REM START program1.exe
REM FOR /L %%i IN (1,1,100) DO (
REM  (TASKLIST | FIND /I "program.exe") && GOTO :startnext
REM   :: you might add here some delaying
REM )

REM :startnext
REM program2.exe
