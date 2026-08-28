@echo off
call "C:\BuildTools\Common7\Tools\VsDevCmd.bat" -arch=x64
if errorlevel 1 (
  echo VSDEVCMD_FAILED
  exit /b 1
)
cd /d "C:\Users\Pedro\Desktop\tibia-server\canary"
cmake --build --preset windows-release --target canary
echo BUILD_EXIT_CODE=%errorlevel%
