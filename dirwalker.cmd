@ECHO OFF

setlocal enabledelayedexpansion

SET cmdTitle=DirWalker
SET curDate=%date:~10,4%%date:~7,2%%date:~4,2%

title %cmdTitle%

SET version="1.6"

SET origin=%~dp0
SET tempFolder=%TEMP%\%cmdTitle%%curDate%.tmp

IF EXIST %tempFolder% RMDIR /s /q %tempFolder%
MKDIR %tempFolder%
CD %tempFolder%

:: Visual Studio Home
SET VS_HOME=C:\Program Files (x86)\Microsoft Visual Studio 14.0

:: System Environment Path
:: ml.exe can be found in %VS_HOME%\VC\bin
SET PATH=%VS_HOME%\VC\bin;%VS_HOME%\Common7\IDE;%PATH%

:: Include File for Irvine32
SET INCLUDE=C:\Irvine;%INCLUDE%

:: Link Libraries for Irvine32 and Win32
SET LIB=%VS_HOME%\VC\LIB;C:\Irvine;%LIB%

:: Asm File to be Assembled
SET ASM_FILE=MD5-DirWalk

:: Path to Asm File to be Assembled
SET ASM_PATH="C:\Users\samke\Documents\Projects\VisualStudio Projects\Visual Studio 2015\Projects\Project32_VS2015"

:: -Zi
SET COMPILE_FLAGS=-nologo -c

ml %COMPILE_FLAGS% %ASM_PATH%\%ASM_FILE%.asm > NUL
REM IF ERRORLEVEL 1 GOTO QUIT


:: /DEBUG
SET LINK_FLAGS=/NOLOGO /SUBSYSTEM:CONSOLE

link %LINK_FLAGS% irvine32.lib kernel32.lib user32.lib %ASM_FILE%.obj


SET EXECUTE_FLAGS=

::/debugexe
REM devnev %ASM_FILE%.exe %EXECUTE_FLAGS%

SET input_op=" >> "

CALL :dispHeader

:MAIN_LOOP
SET answer=
SET /p answer=%input_op%

SET command=
SET param0=
SET param1=

FOR /f "tokens=1,2,3,4 delims= " %%A IN ("%answer%") DO (
   SET command=%%A
   CALL :toLower command
   SET param0=%%B
   SET param1=%%C
)

SET params=000

IF NOT DEFINED command GOTO :MAIN_LOOP
::IF DEFINED param0 SET params=10
::IF DEFINED param1 SET params=!params:~0,1!1

SET param0="!param0:"=!"
SET param1="!param1:"=!"

IF "%command%"=="exit" GOTO :QUIT

IF "%command%"=="clear" (
	CLS 
	CALL :dispHeader
)

IF "%command%"=="gui" (
	"!tempFolder!\!ASM_FILE!.exe" !param0! !param1!
)

IF "%command%"=="help" (
	ECHO.
	ECHO  CLEAR       Clears the screen.
	ECHO  EXIT        Quits the DirWalker program.
	ECHO  GUI         Starts interactive environment.
	ECHO  HASH        Computes the MD5 hash.
	ECHO  HELP        Displays command description.
	ECHO  MAN         Displays command usage.
	ECHO  SCAN        Scans directory and hashes each file.
	ECHO.
)

IF "%command%"=="man" (
	ECHO.
	IF /i !param0!=="clear" (
		ECHO  CLEAR       CLEAR && ECHO. && ECHO  Clears the screen.
		GOTO :manEnd
	)
	IF /i !param0!=="exit" (
		ECHO  EXIT        EXIT && ECHO. && ECHO  Quits the DirWalker program.
		GOTO :manEnd
	)
	IF /i !param0!=="gui" (
		ECHO  GUI         GUI && ECHO. && ECHO  Starts interactive environment.
		GOTO :manEnd
	)
	IF /i !param0!=="hash" (
		ECHO  HASH        HASH [filename] ?[filename] && ECHO. && ECHO  Computes the MD5 hash.
		GOTO :manEnd
	)
	IF /i !param0!=="help" (
		ECHO  HELP        HELP && ECHO. && ECHO  Displays command description.
		GOTO :manEnd
	)
	IF /i !param0!=="man" (
		ECHO  MAN         MAN [command] && ECHO. && ECHO  Displays command usage.
		GOTO :manEnd
	)
	IF /i !param0!=="scan" (
		ECHO  SCAN        SCAN [directory] ?[filename] && ECHO. && ECHO  Scans directory and hashes each file.
		GOTO :manEnd
	)
	:manEnd
	ECHO.
)

IF "%command%"=="scan" (
	TREE .
	FOR /r %%F IN (*) DO (
		ECHO %%F
	)
)

IF "%command%"=="hash" (
	ECHO.
	"!tempFolder!\!ASM_FILE!.exe"  !param0! !param1!
	ECHO. && ECHO.
)

GOTO :MAIN_LOOP

:QUIT
CD %origin%
ECHO %tempFolder%
RMDIR /s /q %tempFolder%

GOTO :END

:toLower
FOR %%C IN (a b c d e f g h i j k l m n o p q r s t u v w x y z) DO SET %1=!%1:%%C=%%C!
GOTO :eof

:dispHeader
ECHO.
ECHO  MD5 Directory Walker  ---  Version %version% 2016
ECHO.
GOTO :eof

:END
endlocal
GOTO :eof
