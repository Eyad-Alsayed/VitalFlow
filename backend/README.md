# Backend Setup Instructions

## Prerequisites
- Python 3.8+
- Database (PostgreSQL, MySQL, SQL Server, or SQLite)
- pip (Python package manager)

## Setup Steps

### 1. Database Setup

Create a database for the application. The backend supports multiple database types via SQLAlchemy.

**Set the DATABASE_URL environment variable:**

```bash
# Windows PowerShell
$env:DATABASE_URL = "your_database_connection_string"

# Linux/macOS
export DATABASE_URL="your_database_connection_string"
```

**Connection string examples:**
| Database | Format |
|----------|--------|
| PostgreSQL | `postgresql://user:pass@host:5432/dbname` |
| MySQL | `mysql+pymysql://user:pass@host:3306/dbname` |
| SQL Server | `mssql+pyodbc://user:pass@host:1433/dbname?driver=ODBC+Driver+17+for+SQL+Server` |
| SQLite | `sqlite:///./database.db` |

### 2. Backend Setup

1. Navigate to backend directory:
   ```bash
   cd backend
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run the FastAPI server:
   ```bash
   python main.py
   ```
   
   Server will start at: http://localhost:8000
   API documentation: http://localhost:8000/docs

### 3. Frontend Setup

1. Navigate to Flutter project root:
   ```bash
   cd ..
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the Flutter web app:
   ```bash
   flutter run -d chrome
   ```

## API Endpoints

### OR Bookings
- GET `/api/or-bookings` - Get all OR bookings
- POST `/api/or-bookings` - Create new OR booking
- GET `/api/or-bookings/{id}` - Get specific OR booking
- PUT `/api/or-bookings/{id}/status` - Update OR booking status

### ICU Requests
- GET `/api/icu-requests` - Get all ICU requests
- POST `/api/icu-requests` - Create new ICU request
- GET `/api/icu-requests/{id}` - Get specific ICU request
- PUT `/api/icu-requests/{id}/status` - Update ICU request status

### Comments
- GET `/api/comments?booking_id={id}&context={or|icu}` - Get comments
- POST `/api/comments` - Create new comment

## Database Schema

The backend automatically creates these tables on first run:
- `or_bookings` - Operating room booking requests
- `icu_requests` - ICU bed requests  
- `comments` - Comments for both OR and ICU requests
- `staff_passwords` - Hashed staff passwords

## Features

- User authentication (role-based)
- OR booking management
- ICU request management
- Comments system
- Status management with role-based permissions

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Database connection errors | Verify DATABASE_URL is set and database is running |
| CORS errors | Check that your frontend URL is in the CORS origins list in `main.py` |
| Port conflicts | Backend uses port 8000, change in `main.py` if needed |
| Missing tables | Tables are auto-created on first run |

## Production Deployment

For production deployment:
1. Use environment variables for database credentials
2. Set up proper CORS origins (remove "*")
3. Add authentication middleware
4. Use a production WSGI server like Gunicorn
5. Set up SSL certificates
6. Deploy behind a reverse proxy (nginx/Apache)
