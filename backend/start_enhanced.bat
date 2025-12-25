@echo off
echo ====================================
echo Enhanced OR/ICU Booking System Setup
echo ====================================

echo.
echo Step 1: Updating database password...
echo Please update the password in database.py file:
echo   Open: backend\database.py
echo   Find: postgresql://postgres:YOUR_PASSWORD_HERE@localhost/booking_app
echo   Replace YOUR_PASSWORD_HERE with your actual PostgreSQL password

echo.
echo Step 2: Creating Python virtual environment...
if not exist "venv" (
    python -m venv venv
    echo Virtual environment created.
) else (
    echo Virtual environment already exists.
)

echo.
echo Step 3: Activating virtual environment and installing packages...
call venv\Scripts\activate
pip install -r requirements.txt

echo.
echo Step 4: Database setup options:
echo   Option A: Run enhanced_migration.sql in pgAdmin 4 (recommended)
echo   Option B: Let the API create tables automatically
echo.
echo Choose option A for full database schema with constraints and indexes.

echo.
echo Step 5: Testing database connection...
python test_connection.py

echo.
echo Step 6: Starting enhanced API server...
echo The API will be available at: http://localhost:8000
echo API documentation at: http://localhost:8000/docs
echo.

python enhanced_main.py

pause