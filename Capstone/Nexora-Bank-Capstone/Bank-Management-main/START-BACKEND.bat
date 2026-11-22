@echo off
cd /d "%~dp0backend"
if not exist .env (
  echo Missing backend\.env. Copy backend\.env.example to backend\.env and enter your MySQL password first.
  pause
  exit /b 1
)
npm start
pause
