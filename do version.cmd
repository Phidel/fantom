@echo off
set /p vers=<"BuildNo.inc"
set arc=Fantom_%vers%.rar
"C:\Program Files (x86)\WinRAR\WinRAR.exe" a "%arc%" Fantom.exe 
rem TelegramHelper.exe data.abs

rem call D:\Dropbox\Utils\mfu.cmd %arc%

cd fantom
gh release upload 1.0 ..\%arc%
cd ..

move %arc% for-client\ > nul

rem сообщение поместить в буфер обмена
nircmd.exe clipboard set "https://github.com/Phidel/fantom/releases/download/1.0/%arc%"
echo ok - https://github.com/Phidel/fantom/releases/download/1.0/%arc%