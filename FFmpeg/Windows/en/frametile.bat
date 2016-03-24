@echo off
rem Frame Tiling with ffmpeg 2014.05.09  lastmod 2016.02.08
rem                  by Coffey
rem                  ffmpeg 2.2.1 - 
rem -------------------------------------------------------

setlocal

rem # default variables
rem #-------------------------------
rem # pathFFMPEG: path to ffmpeg.exe
rem # fontFile  : fullpath to fontfile
rem # mesPause  : Pause (wait any key) when showing message [yes/no]
rem # encParams : encode parameter
rem # fps       : fps [24/30/23.976(24000/1001)/29.97(30000/1001)]
rem # marker    : current frame marker [box/dot/none]
rem # showInfo  : show frame info [pts/timecode/droptimecode/none]
rem # forceCFR  : force CFR(constant frame rate) [yes/no]
rem # vWidth    : width of a tile (pixel)
rem # vHeight   : height of a tile (pixel)
rem # audioTrack: enable audio track [yes/no]
rem # startNumber : start number of frame info [0/1]
rem # previewTimecode: draw timecode on preview tile [yes/no]
rem # outFileSuffix: new file suffix
rem # modDate   : modified date (use for help)
rem # debugFlag : debug mode [yes/no]

    set pathFFMPEG=ffmpeg.exe
    set fontFile=C:\Windows\Fonts\arial.ttf
    set mesPause=no
    set encParams=-preset:v veryfast -c:v libx264 -c:a aac -b:a 128k -ac 2
    set fps=24000/1001
    set marker=box
    set showInfo=pts
    set forceCFR=no
    set vWidth=256
    set vHeight=144
    set audioTrack=yes
    set startNumber=0
    set previewTimecode=no
    set outFileSuffix=-tiles
    set modDate=20160208
    
    set debugFlag=no

rem # escape special character
set fontFile=%fontFile:\=\\%
set fontFile=%fontFile::=\:%
set fontFile=%fontFile:,=\,%
set fontFile=%fontFile:'=\'%
set fontFile=%fontFile:[=\[%
set fontFile=%fontFile:]=\]%

rem # check exist ffmpeg.exe
for %%I in ("ffmpeg.exe") do set findPath=%%~$PATH:%I
if not exist %pathFFMPEG% (
  if not "%findPath%"=="" (
    set pathFFMPEG=%findPath%
  ) else (
    echo FFmpeg not found
    echo check a value 'pathFFMPEG' or ffmpeg.exe location
    if "%mesPause%"=="yes" pause
    goto end
  )
)
echo ^<ffmpeg location: %pathFFMPEG%^>

if "%~1"=="" goto help
set flags=
set helpFlag=

set seekPoint=
set outFrames=
set outDuration=
set outFile=""

set args=%*
set args=%args:,=$comma$%
set args=%args:;=$semicolon$%
call :loop1 %%args%%
if "%helpFlag%"=="yes" goto help
goto end

:loop1
  set argument="%~1"
  if %argument%=="" goto loop1end
  set argument=%argument:$comma$=,%
  set argument=%argument:$semicolon$=;%
  call :parse %%argument%%
  if errorlevel 1 call :maketile %%argument%%
  shift
  goto loop1
:loop1end
  exit /b

rem # parse option ===================================================
:parse
if "%~1"=="-h" (
  set helpFlag=yes
  exit /b 0
)
if "%~1"=="--help" (
  set helpFlag=yes
  exit /b 0
)

if "%flags%"=="d" (
  if "%~1"=="timecode" (
    set showInfo=timecode
  )
  if "%~1"=="droptimecode" (
    set showInfo=droptimecode
  )
  if "%~1"=="pts" (
    set showInfo=pts
  )
  if "%~1"=="none" (
    set showInfo=none
  )
  set flags=
  exit /b 0
)
if "%flags%"=="f" (
  if "%~1"=="24" set fps=24
  if "%~1"=="25" set fps=25
  if "%~1"=="30" set fps=30
  if "%~1"=="23.976" set fps=24000/1001
  if "%~1"=="23.98" set fps=24000/1001
  if "%~1"=="29.97" set fps=30000/1001
  if "%~1"=="24000/1001" set fps=24000/1001
  if "%~1"=="30000/1001" set fps=30000/1001
  if "%~1"=="film" set fps=24
  if "%~1"=="pal" set fps=25
  if "%~1"=="ntsc-mono" set fps=30
  if "%~1"=="ntsc-film" set fps=24000/1001
  if "%~1"=="ntsc-anime" set fps=24000/1001
  if "%~1"=="ntsc" set fps=30000/1001
  set flags=
  exit /b 0
)
if "%flags%"=="m" (
  if "%~1"=="box" (
    set marker=box
  )
  if "%~1"=="dot" (
    set marker=dot
  )
  if "%~1"=="none" (
    set marker=none
  )
  set flags=
  exit /b 0
)
if "%flags%"=="o" (
  set outFile="%~1"
  set flags=
  exit /b 0
)
if "%flags%"=="ss" (
  set "seekPoint=%~1"
  set flags=
  exit /b 0
)
if "%flags%"=="frames" (
  set "outFrames=%~1"
  set flags=
  exit /b 0
)
if "%flags%"=="t" (
  set "outDuration=%~1"
  set flags=
  exit /b 0
)

if "%~1"=="-an" (
  set audioTrack=no
  exit /b 0
)
if "%~1"=="-c" (
  set forceCFR=yes
  exit /b 0
)
if "%~1"=="-d" (
  set flags=d
  exit /b 0
)
if "%~1"=="-f" (
  set flags=f
  exit /b 0
)
if "%~1"=="-m" (
  set flags=m
  exit /b 0
)
if "%~1"=="-o" (
  set flags=o
  exit /b 0
)
if "%~1"=="-pt" (
  set previewTimecode=yes
  exit /b 0
)
if "%~1"=="-ptn" (
  set previewTimecode=no
  exit /b 0
)
if "%~1"=="-ss" (
  set flags=ss
  exit /b 0
)
if "%~1"=="-frames" (
  set flags=frames
  exit /b 0
)
if "%~1"=="-t" (
  set flags=t
  exit /b 0
)
if "%~1"=="-f30" (
  set fps=30
  exit /b 0
)
if "%~1"=="-f24" (
  set fps=24
  exit /b 0
)
if "%~1"=="-verbose" (
  set debugFlag=yes
  exit /b 0
)
exit /b 1

rem # make tile  =====================================================
:maketile
if not exist "%~1" (
  echo error: file not exist. skipped.
  echo        filename = [%1]
  if "%mesPause%"=="yes" pause
  exit /b
)

set inFile="%~1"
if %outFile%=="" (
  set outFile="%~dpn1%outFileSuffix%.mp4"
  if %inFile%==%outFile% (
    echo error: same output filename as input.
    if "%mesPause%"=="yes" pause
    exit /b
  )
)

set markerParams=null
if "%marker%"=="box" (
  set markerParams=drawbox=0:0:%vWidth%:%vHeight%:color=red@0.5:t=2
)
if "%marker%"=="dot" (
  set markerParams=drawtext=fontfile='%fontFile%':x=2:y=26:fontsize=18:fontcolor=yellow:box=1:boxcolor=black@0.4:text="*"
)

set fpsTimecode=24
if "%fps%"=="30" set fpsTimecode=30
if "%fps%"=="30000/1001" set fpsTimecode=30

set timecodeParams=
set fnumberParams=""
set fnumber1Params=""
set ptsParams=""
if "%showInfo%"=="timecode" (
  set timecodeParams=timecode_rate=%fpsTimecode%:timecode='00\:00\:00\:00':
  set fnumberParams='%%{n}-%%{pict_type}'
  set fnumber1Params='%%{n}'
)
if "%showInfo%"=="droptimecode" (
  set timecodeParams=timecode_rate=%fpsTimecode%:timecode='00\:00\:00\:00':
  if "%fpsTimecode%"=="30" (
    set timecodeParams=timecode_rate=%fpsTimecode%:timecode='00\:00\:00\;00':
  )
  set fnumberParams='%%{n}-%%{pict_type}'
  set fnumber1Params='%%{n}'
)
if "%showInfo%"=="pts" (
  set ptsParams='%%{pts\:hms}'
  set fnumberParams='%%{n}-%%{pict_type}'
  set fnumber1Params='%%{n}'
)

set cfrParams=null
rem set cfrParams=yadif=1
if "%forceCFR%"=="yes" (
  set cfrParams=fps=%fps%
)

set audioTrackParams=
if "%audioTrack%"=="yes" (
  set audioTrackParams=-map 0:a
)

set seekParams=
if not "%seekPoint%"=="" (
  set seekParams=-ss %seekPoint%
)
set outFramesParams=
if not "%outFrames%"=="" (
  set outFramesParams=-frames:v %outFrames%
)
set outDurationParams=
if not "%outDuration%"=="" (
  set outDurationParams=-t %outDuration%
)

if "%debugFlag%"=="yes" (
  echo current directory:
  cd
  echo ----------------------------
  echo pathFFMPEG=%pathFFMPEG%
  echo inFile=%inFile%
  echo outFile=%outFile%
  echo fps=%fps%
  echo marker=%marker%
  echo showInfo=%showInfo%
  echo forceCFR=%forceCFR%
  echo audioTrack=%audioTrack%
  echo startNumber=%startNumber%
  echo previewTimecode=%previewTimecode%
  echo outFileSuffix=%outFileSuffix%
  echo modDate=%modDate%
  echo ----------------------------
  echo markerParams=%markerParams%
  echo ptsParams=%ptsParams%
  echo timecodeParams=%timecodeParams%
  echo fnumberParams=%fnumberParams%
  echo cfrParams=%cfrParams%
  echo audioTrackParams=%audioTrackParams%
  echo seekParams=%seekParams%
  echo outFramesParams=%outFramesParams%
  echo outDurationParams=%outDurationParams%
  echo encParams=%encParams%
  pause
)

if "%fpsTimecode%"=="30" goto fps30

rem x=140 ({pts:flt})
:fps24
if "%previewTimecode%"=="yes" goto fps24preview
@echo on
"%pathFFMPEG%" -analyzeduration 30000000 -probesize 30M %seekParams% -i %inFile% ^
-filter_complex [0:v]%cfrParams%,scale=%vWidth%:%vHeight%:flags=lanczos,split[v1][v2],^
[v1]drawtext=fontfile='%fontFile%':x=2:y=2:fontsize=24:fontcolor=white:^
%timecodeParams%text=%ptsParams%:box=1:boxcolor=black@0.4,^
drawtext=fontfile='%fontFile%':x=162:y=2:fontsize=20:fontcolor=yellow:start_number=%startNumber%:^
text=%fnumberParams%:box=1:boxcolor=black@0.4,^
tile=layout=5x5:padding=2:nb_frames=24,%cfrParams%[vtile],^
[v2]fifo,split[v21][v22],[v21]pad=%vWidth%*5+8:%vHeight%*5+8:0:0[v3],^
[v3][vtile]overlay[vtile1],[vtile1][v22]overlay=%vWidth%*4+8:%vHeight%*4+8,split[v23][v4],^
[v23]crop=%vWidth%:%vHeight%:'mod(mod(n,24),5)*(%vWidth%+2)':'trunc(mod(n,24)/5)*(%vHeight%+2)',^
%markerParams%[v5],^
[v4][v5]overlay='mod(mod(n,24),5)*(%vWidth%+2)':'trunc(mod(n,24)/5)*(%vHeight%+2)'[vout]^
 -map [vout] %audioTrackParams% %encParams% -vsync 0 -r 120000/1001 ^
%outFramesParams% %outDurationParams% %outFile%
@echo off
goto maketile_end

:fps24preview
@echo on
"%pathFFMPEG%" -analyzeduration 30000000 -probesize 30M %seekParams% -i %inFile% ^
-filter_complex [0:v]%cfrParams%,scale=%vWidth%:%vHeight%:flags=lanczos,split[v1][v2],^
[v1]drawtext=fontfile='%fontFile%':x=2:y=2:fontsize=24:fontcolor=white:^
%timecodeParams%text=%ptsParams%:box=1:boxcolor=black@0.4,^
drawtext=fontfile='%fontFile%':x=162:y=2:fontsize=20:fontcolor=yellow:start_number=%startNumber%:^
text=%fnumberParams%:box=1:boxcolor=black@0.4,^
tile=layout=5x5:padding=2:nb_frames=24,%cfrParams%[vtile],^
[v2]fifo,split[v21][v22],[v21]pad=%vWidth%*5+8:%vHeight%*5+8:0:0[v3],^
[v3][vtile]overlay[vtile1],[vtile1][v22]overlay=%vWidth%*4+8:%vHeight%*4+8,split[v23][v4],^
[v23]crop=%vWidth%:%vHeight%:'mod(mod(n,24),5)*(%vWidth%+2)':'trunc(mod(n,24)/5)*(%vHeight%+2)',^
%markerParams%[v5],^
[v4][v5]overlay='mod(mod(n,24),5)*(%vWidth%+2)':'trunc(mod(n,24)/5)*(%vHeight%+2)',^
drawtext=fontfile='%fontFile%':x=%vWidth%*4+8+2:y=%vHeight%*4+8+2:fontsize=24:fontcolor=white:^
%timecodeParams%text=%ptsParams%:box=1:boxcolor=black@0.4,^
drawtext=fontfile='%fontFile%':x=%vWidth%*4+8+162:y=%vHeight%*4+8+2:fontsize=20:fontcolor=yellow:start_number=%startNumber%:^
text=%fnumber1Params%:box=1:boxcolor=black@0.4[vout]^
 -map [vout] %audioTrackParams% %encParams% -vsync 0 -r 120000/1001 ^
%outFramesParams% %outDurationParams% %outFile%
@echo off
goto maketile_end

:fps30
if "%previewTimecode%"=="yes" goto fps30preview
@echo on
"%pathFFMPEG%" -analyzeduration 30000000 -probesize 30M %seekParams% -i %inFile% ^
-filter_complex [0:v]%cfrParams%,scale=%vWidth%:%vHeight%:flags=lanczos,split[v1][v2],^
[v1]drawtext=fontfile='%fontFile%':x=2:y=2:fontsize=24:fontcolor=white:^
%timecodeParams%text=%ptsParams%:box=1:boxcolor=black@0.4,^
drawtext=fontfile='%fontFile%':x=162:y=2:fontsize=20:fontcolor=yellow:start_number=%startNumber%:^
text=%fnumberParams%:box=1:boxcolor=black@0.4,^
tile=layout=6x6:padding=2:nb_frames=30,%cfrParams%[vtile],^
[v2]fifo,split[v21][v22],[v21]pad=%vWidth%*6+10:%vHeight%*6+10:0:0[v3],^
[v3][vtile]overlay[vtile1],[vtile1][v22]overlay=%vWidth%*5+10:%vHeight%*5+10,split[v23][v4],^
[v23]crop=%vWidth%:%vHeight%:'mod(mod(n,30),6)*(%vWidth%+2)':'trunc(mod(n,30)/6)*(%vHeight%+2)',^
%markerParams%[v5],^
[v4][v5]overlay='mod(mod(n,30),6)*(%vWidth%+2)':'trunc(mod(n,30)/6)*(%vHeight%+2)'[vout]^
 -map [vout] %audioTrackParams% %encParams% -vsync 0 -r 120000/1001 ^
%outFramesParams% %outDurationParams% %outFile%
@echo off
goto maketile_end

:fps30preview
@echo on
"%pathFFMPEG%" -analyzeduration 30000000 -probesize 30M %seekParams% -i %inFile% ^
-filter_complex [0:v]%cfrParams%,scale=%vWidth%:%vHeight%:flags=lanczos,split[v1][v2],^
[v1]drawtext=fontfile='%fontFile%':x=2:y=2:fontsize=24:fontcolor=white:^
%timecodeParams%text=%ptsParams%:box=1:boxcolor=black@0.4,^
drawtext=fontfile='%fontFile%':x=162:y=2:fontsize=20:fontcolor=yellow:start_number=%startNumber%:^
text=%fnumberParams%:box=1:boxcolor=black@0.4,^
tile=layout=6x6:padding=2:nb_frames=30,%cfrParams%[vtile],^
[v2]fifo,split[v21][v22],[v21]pad=%vWidth%*6+10:%vHeight%*6+10:0:0[v3],^
[v3][vtile]overlay[vtile1],[vtile1][v22]overlay=%vWidth%*5+10:%vHeight%*5+10,split[v23][v4],^
[v23]crop=%vWidth%:%vHeight%:'mod(mod(n,30),6)*(%vWidth%+2)':'trunc(mod(n,30)/6)*(%vHeight%+2)',^
%markerParams%[v5],^
[v4][v5]overlay='mod(mod(n,30),6)*(%vWidth%+2)':'trunc(mod(n,30)/6)*(%vHeight%+2)',^
drawtext=fontfile='%fontFile%':x=%vWidth%*5+10+2:y=%vHeight%*5+10+2:fontsize=24:fontcolor=white:^
%timecodeParams%text=%ptsParams%:box=1:boxcolor=black@0.4,^
drawtext=fontfile='%fontFile%':x=%vWidth%*5+10+162:y=%vHeight%*5+10+2:fontsize=20:fontcolor=yellow:start_number=%startNumber%:^
text=%fnumber1Params%:box=1:boxcolor=black@0.4[vout]^
 -map [vout] %audioTrackParams% %encParams% -vsync 0 -r 120000/1001 ^
%outFramesParams% %outDurationParams% %outFile%
@echo off
goto maketile_end

:maketile_end
exit /b

rem # show help ======================================================
:help
echo ^<windows batch script. ver %modDate% by Coffey^>
echo Usage:
echo     frametile [option] filename [[option] filename ...]
echo Option:
echo     -an            : disable audio  ^(default: enable^)
echo     -c             : enable force CFR^(constant frame rate^)
echo                      ^(default: disable^)
echo     -d ^<param^>     : display info [none/timecode/droptimecode/pts^(default^)]
echo     -f ^<param^>     : fps [23.976^(default^)/24/29.97/30]
echo     -m ^<param^>     : current frame marker [none/dot/box^(default^)]
echo     -o ^<filename^>  : output filename. 
echo                        output file should be set before input filename
echo     -ss ^<param^>    : seek point [hh:mm:ss or seconds]
echo     -t ^<param^>     : output length by time [hh:mm:ss or seconds]
echo     -frames ^<param^>: output length by frames
echo     -pt            : draw info on movie cell.
echo     -ptn           : no info on movie cell.
echo Default Output filename ^(without -o option^):
echo     ^<filename^>%outFileSuffix%.mp4
echo.
echo Example:
echo     frametile hogehoge.mp4
echo         --^> make a 5x5 tiled movie with pts info.
echo             output filename 'hogehoge-tiles.mp4'
echo     frametile -d timecode -m none -o bar.mp4 foo.mp4
echo         --^> show timecode, no marker, output filename 'bar.mp4'
if "%mesPause%"=="yes" pause

:end
if "%debugFlag%"=="yes" pause
endlocal

