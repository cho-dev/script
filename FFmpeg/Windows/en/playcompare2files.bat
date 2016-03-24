@echo off
rem ================================================
rem playcompare2files.bat
rem     compare 2 movie files.
rem              by Coffey 2014.12.08  mod 2016.03.23
rem ================================================

setlocal

rem ================================================
rem ffplayPath          : filepath to ffplay.exe
rem ffmpegPaht          : filepath to ffmpeg.exe
rem ffplayOptions       : ffplay option
rem ffmpegOptions       : ffmpeg option
rem ffmpegMetaOptions   : ffmpeg metadata option
rem ffmpegEncodeOptions : ffmpeg encode option
rem frameOffset         : delay of second movie (frame)
rem sensitivity         : sensitivity of difference
rem ================================================
set ffplayPath=ffplay.exe
set ffmpegPath=ffmpeg.exe
set ffplayOptions=-autoexit -analyzeduration 30000000 -probesize 30M
set ffmpegOptions=-analyzeduration 30000000 -probesize 30M
set ffmpegMetaOptions=-metadata:s:a:0 language=jpn
set ffmpegEncodeOptions=-c:v libx264 -x264-params crf=22 -c:a aac -b:a 128k
set frameOffset=0
set sensitivity=1

set modDate=20160323

set inFile1=
set inFile2=
set outFile=
set flags=
set helpFlag=
set videoFramerate=24

if "%~1"=="" (
  call :help
  goto end
)

rem ***** parse command line *****
set args=%*
set args=%args:,=$comma$%
set args=%args:;=$semicolon$%
call :loop1 %%args%%
goto end

:loop1
  set argument="%~1"
  if %argument%=="" goto loop1end
  set argument=%argument:$comma$=,%
  set argument=%argument:$semicolon$=;%
  call :parse %%argument%%
  shift
  goto loop1
:loop1end
  call :play %%argument%%
  exit /b

:parse

if "%flags%"=="ofs" (
  set "frameOffset=%~1"
  set flags=
  exit /b 0
)
if "%flags%"=="s" (
  set "sensitivity=%~1"
  set flags=
  exit /b 0
)
if "%flags%"=="o" (
  set outFile="%~1"
  set flags=
  exit /b 0
)
if "%~1"=="--ofs" (
  set flags=ofs
  exit /b 0
)
if "%~1"=="-s" (
  set flags=s
  exit /b 0
)
if "%~1"=="-o" (
  set flags=o
  exit /b 0
)
if "%~1"=="-h" (
  set helpFlag=yes
  exit /b 0
)
if "%~1"=="--help" (
  set helpFlag=yes
  exit /b 0
)
if "%~1"=="/?" (
  set helpFlag=yes
  exit /b 0
)
if "%inFile1%"=="" (
  set "inFile1=%~1"
  exit /b 0
)
if "%inFile2%"=="" (
  set "inFile2=%~1"
  exit /b 0
)
exit /b 0

:play

if "%helpFlag%"=="yes" (
  call :help
  exit /b 0
)
if "%inFile1%"=="" (
  echo Input File1 is not defined.
  exit /b 0
)
if "%inFile2%"=="" (
  echo Input File2 is not defined.
  exit /b 0
)

set inFile1e=%infile1%
set inFile1e=%inFile1e:\=\\\\%
set inFile1e=%inFile1e::=\\\:%
set inFile1e=%inFile1e:,=\\\,%
set inFile1e=%inFile1e:'=\\\'%
set inFile1e=%inFile1e:[=\\\[%
set inFile1e=%inFile1e:]=\\\]%

set inFile2e=%infile2%
set inFile2e=%inFile2e:\=\\\\%
set inFile2e=%inFile2e::=\\\:%
set inFile2e=%inFile2e:,=\\\,%
set inFile2e=%inFile2e:'=\\\'%
set inFile2e=%inFile2e:[=\\\[%
set inFile2e=%inFile2e:]=\\\]%

if "%outFile%"=="" (
  goto makefile0
) else (
  goto makefile1
)

:makefile0
@echo on
"%ffplayPath%" %ffplayOptions% -f lavfi -graph ^
movie="%inFile1e%",scale=640:360,setsar=1,fifo,split[v0][v01],^
movie="%inFile2e%",scale=640:360,setsar=1,^
setpts=PTS+%frameOffset%/(FRAME_RATE*TB),fifo,split[v1][v12],^
amovie="%inFile1e%"[out1],^
[v01][v12]blend=c0_expr='clip(125.5-((B-A)*%sensitivity%/2),16,235)'^
:c1_expr='clip(128-((B-A)*%sensitivity%/2),16,240)'^
:c2_expr='clip(128-((B-A)*%sensitivity%/2),16,240)'[v4],^
[v0]pad=1280:720:0:0[v5],[v5][v1]overlay=640:0[v6],[v6][v4]overlay=320:360 ^
"%inFile1%, %inFile2%"
@echo off
goto playend

:makefile1
@echo on
"%ffmpegPath%" %ffmpegOptions% -filter_complex ^
movie="%inFile1e%",scale=640:360,setsar=1,fifo,split[v0][v01],^
movie="%inFile2e%",scale=640:360,setsar=1,^
setpts=PTS+%frameOffset%/(FRAME_RATE*TB),select='gte(pts,0)',^
fifo,split[v1][v12],^
amovie="%inFile1e%"[aout1],^
amovie="%inFile2e%",asetpts=PTS+%frameOffset%*SR/%videoFramerate%,^
aselect='gte(pts,0)',afifo[aout2],^
[v01][v12]blend=c0_expr='clip(125.5-((B-A)*%sensitivity%/2),16,235)'^
:c1_expr='clip(128-((B-A)*%sensitivity%/2),16,240)'^
:c2_expr='clip(128-((B-A)*%sensitivity%/2),16,240)'[v4],^
[v0]pad=1280:720:0:0[v5],[v5][v1]overlay=640:0[v6],[v6][v4]overlay=320:360[vout] ^
-map [vout] -map [aout1] -map [aout2] ^
%ffmpegMetaOptions% %ffmpegEncodeOptions% %outFile%
@echo off
goto playend

:playend
exit /b

:help
rem # show help ======================================================
echo ^<windows batch script. ver %modDate% by Coffey^>
echo ^<ffplayPath=%ffplayPath%^>
echo ^<ffmpegPath=%ffmpegPath%^>
echo Compare 2 movie files.
echo.
echo Usage:
echo     playcompare2files [option] filename1 filename2
echo Option:
echo     --ofs          : frame offset of second file. ^(default 0^)
echo     -s             : sensitivity of difference ^(default 1^)
echo     -o ^<filename^>  : output filename.
echo                      ^(immediate play without -o option^)
echo.
echo left side is filename1, right side is filename2,
echo         center bottom is difference.
echo.
echo Example:
echo     playcompare2files --ofs -3 foo.mp4 bar.mp4
echo         --^> compare foo.mp4 with bar.mp4
echo             bar.mp4 starts 3 frames fast.
exit /b

:end
rem pause
endlocal

