@echo off
set h=%TIME:~0,2%
set m=%TIME:~3,2%
if %m% leq 9 set m=0%m:~1,1%
if %h% leq 9 set h=0%h:~1,1%
set datestr=%date:~6,4%_%date:~3,2%_%date:~0,2%_%h%%m%

set /p vers=<"BuildNo.inc"
set arc=273_sources_%datestr%_%vers%.rar

"C:\Program Files (x86)\WinRAR\WinRAR.exe" a "%arc%" *.* C:\Comp\DeaTools\*.* -r -ed -v1G -m1 -msrar;zip;jpg;jpeg;png;mp3 -x*.exe -x"*\for-client\*.*" -x"\data\" -x"*\__history\*" -x"*\__recovery\*" -xlog*.txt -x"Dcu"


if %errorlevel%==0 (
   echo %TIME% ��娢�஢���� �ᯥ譮 �����襭�
   call D:\Dropbox\Utils\mf.cmd %arc%
   move  %arc% for-client\src\
  ) else (
   echo ----------------------------------
   echo %TIME% ��娢�஢���� �� �뫮 �����襭�!
  )