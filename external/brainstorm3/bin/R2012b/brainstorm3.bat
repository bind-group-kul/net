@ECHO.
@SET MATLABROOT=

@REM ===== MATLAB 64bit =====
@SET MKEY="HKLM\SOFTWARE\MathWorks\MATLAB\8.0"
@FOR /F "skip=2 tokens=2*" %%A IN ('REG QUERY %MKEY% /v MATLABROOT 2^>NUL') DO @SET MATLABROOT=%%B
@IF DEFINED MATLABROOT (
    @ECHO Matlab R2012b found:
    @SET MATLABROOT
    GOTO :TEST_JAVA
)

@REM ===== MATLAB 32bit =====
@SET MKEY="HKLM\SOFTWARE\Wow6432Node\MathWorks\MATLAB\8.0"
@FOR /F "skip=2 tokens=2*" %%A IN ('REG QUERY %MKEY% /v MATLABROOT 2^>NUL') DO @SET MATLABROOT=%%B
@IF DEFINED MATLABROOT (
    @ECHO Matlab R2012b found:
    @ECHO     %MATLABROOT%
    @GOTO :TEST_JAVA
)
@ECHO Matlab R2012b not found.

@REM ===== MCR 64bit =====
@SET MKEY="HKLM\SOFTWARE\MathWorks\MATLAB Compiler Runtime\8.0"
@FOR /F "skip=2 tokens=2*" %%A IN ('REG QUERY %MKEY% /v MATLABROOT 2^>NUL') DO @SET MATLABROOT=%%B\v80
@IF DEFINED MATLABROOT (
    @ECHO Matlab Compiler Runtime 8.0 found:
    @SET MATLABROOT
    @GOTO :TEST_JAVA
)

@REM ===== MCR 32bit =====
@SET MKEY="HKLM\SOFTWARE\Wow6432Node\MathWorks\MATLAB Compiler Runtime\8.0"
@FOR /F "skip=2 tokens=2*" %%A IN ('REG QUERY %MKEY% /v MATLABROOT 2^>NUL') DO @SET MATLABROOT=%%B\v80
@IF DEFINED MATLABROOT (
    @ECHO Matlab Compiler Runtime 8.0 found:
    @SET MATLABROOT
    @GOTO :TEST_JAVA
)

@REM ===== MATLAB NOT FOUND =====
@ECHO.
@ECHO ERROR: Matlab R2012b does not seem to be installed on your computer.
@ECHO    1) Go to the Brainstorm website
@ECHO    2) Download the Matlab Compiler Runtime (R2012b).
@ECHO.
@pause
@GOTO :END

@REM ===== DETECT JAVA =====
:TEST_JAVA
@IF EXIST "%MATLABROOT%\sys\java\jre\win64" (
    @SET JAVA_EXE="%MATLABROOT%\sys\java\jre\win64\jre\bin\java.exe"
    GOTO :RUN_JAVA
)
@IF EXIST "%MATLABROOT%\sys\java\jre\win32" (
    @SET JAVA_EXE="%MATLABROOT%\sys\java\jre\win32\jre\bin\java.exe"
    GOTO :RUN_JAVA
)

@REM ===== JAVA NOT FOUND =====
@ECHO.
@ECHO ERROR: java.exe was not found in "%MATLABROOT%\sys\java\jre\<arch>\jre\bin"
@ECHO.
@pause
@GOTO :END

@REM ===== START BRAINSTORM =====
:RUN_JAVA
@ECHO.
@ECHO Please wait...
@ECHO.
@%JAVA_EXE% -jar brainstorm3.jar

:END