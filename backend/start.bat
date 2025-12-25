@echo off
REM Backend startup script for VitalFlow App (Windows)

echo Starting VitalFlow Backend...

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo Python is not installed or not in PATH. Please install Python 3.8+ and try again.
    pause
    exit /b 1
)

REM Navigate to backend directory
cd /d "%~dp0"

REM Check if virtual environment exists
if not exist "venv\" (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Install dependencies
echo Installing Python dependencies...
pip install -r requirements.txt

REM Start the server
echo.
echo Starting FastAPI server on http://localhost:8000
echo API documentation will be available at: http://localhost:8000/docs
echo Press Ctrl+C to stop the server
echo.

python main.py

pause