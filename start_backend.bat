@echo off
title Fuel Station Accounting - FastAPI Backend Server
echo ============================================================
echo      Fuel Station Accounting - Automatic Server Launcher
echo ============================================================
echo.
echo Starting FastAPI Uvicorn Server on http://0.0.0.0:8000 ...
echo.
cd /d "%~dp0"
python -m uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
pause
