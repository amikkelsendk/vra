@echo off
REM https://serverfault.com/questions/1119066/generate-sha256-hash-of-a-string-from-windows-command-line

if [%1]==[] goto usage

set STRING="%*"
set TMPFILE="%TMP%\hash-%RANDOM%.tmp"
echo | set /p=%STRING% > %TMPFILE%
certutil -hashfile %TMPFILE% SHA512 | findstr /v "hash"
del %TMPFILE%
goto :eof

:usage
echo Usage: %0 string to be hashed