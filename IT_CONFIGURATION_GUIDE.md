# IT Department Configuration Guide

## VitalFlow - Medical Services Management System

This document provides instructions for your IT department to configure and deploy VitalFlow with your hospital's local data warehouse.

---

## Quick Start Checklist

- [ ] Configure database connection string
- [ ] Set backend API server URL in Flutter app
- [ ] Set admin password
- [ ] Run database migrations
- [ ] Test the connection
- [ ] Deploy to production

---

## 1. Database Configuration

### Backend Database Setup

The backend requires a database connection. Edit the environment variable `DATABASE_URL` on your server.

**File:** `backend/database.py`

**Supported Databases:**
| Database | Connection String Format |
|----------|-------------------------|
| PostgreSQL | `postgresql://username:password@host:port/database_name` |
| MySQL | `mysql+pymysql://username:password@host:port/database_name` |
| SQL Server | `mssql+pyodbc://username:password@host:port/database_name?driver=ODBC+Driver+17+for+SQL+Server` |
| SQLite | `sqlite:///path/to/database.db` |

**Example - Setting Environment Variable:**

**Windows (PowerShell):**
```powershell
$env:DATABASE_URL = "postgresql://db_user:db_password@hospital-db-server:5432/medical_services"
```

**Linux/macOS:**
```bash
export DATABASE_URL="postgresql://db_user:db_password@hospital-db-server:5432/medical_services"
```

**Docker/Container:**
```yaml
environment:
  - DATABASE_URL=postgresql://db_user:db_password@hospital-db-server:5432/medical_services
```

---

## 2. Frontend API Configuration

### Configure Backend Server URL

The Flutter app needs to know where the backend API is hosted.

**Files to update:**
- `lib/services/api_service.dart`
- `lib/services/enhanced_api_service.dart`

**Find this line and update the URL:**
```dart
static const String baseUrl = 'http://localhost:8000';  // TODO: Configure your server URL
```

**Change to your server:**
```dart
static const String baseUrl = 'https://medical-api.yourhospital.local';
```

**Examples:**
| Environment | URL Example |
|-------------|-------------|
| Local Development | `http://localhost:8000` |
| Internal Server | `http://192.168.1.100:8000` |
| Hospital Domain | `https://medical-api.hospital.local` |
| Cloud Hosted | `https://vitalflow-api.yourdomain.com` |

---

## 3. Admin Password Configuration

### Set Admin Password

**File:** `lib/services/auth_service.dart`

**Find this line:**
```dart
const String adminPassword = 'CHANGE_ME_ADMIN_PASSWORD';  // TODO: Set secure admin password
```

**Change to your secure password:**
```dart
const String adminPassword = 'YourSecureAdminPassword123!';
```

> ⚠️ **Security Note:** For production, consider implementing proper authentication via the backend API instead of hardcoded passwords.

---

## 4. Database Schema Migration

### Create Required Tables

Run the migration SQL to create the necessary tables in your database.

**Migration file:** `backend/database_migration.sql`

**Using psql (PostgreSQL):**
```bash
psql -h hostname -U username -d database_name -f backend/database_migration.sql
```

**Using MySQL:**
```bash
mysql -h hostname -u username -p database_name < backend/database_migration.sql
```

**Tables Created:**
| Table | Purpose |
|-------|---------|
| `or_bookings` | Operating Room booking requests |
| `icu_requests` | ICU bed requests |
| `comments` | Comments/notes for bookings |
| `staff_passwords` | Hashed staff passwords |

---

## 5. Running the Backend Server

### Development Mode
```bash
cd backend
pip install -r requirements.txt
python main.py
```

### Production Mode (with Gunicorn)
```bash
cd backend
pip install -r requirements.txt
gunicorn main:app --workers 4 --bind 0.0.0.0:8000
```

### Docker Deployment
```bash
docker build -t vitalflow-backend .
docker run -d -p 8000:8000 -e DATABASE_URL="your_connection_string" vitalflow-backend
```

---

## 6. Running the Flutter Frontend

### Web Build
```bash
flutter pub get
flutter build web
```

### Deploy Web Build
Copy the contents of `build/web/` to your web server.

### Mobile Build
```bash
flutter build apk  # Android
flutter build ios  # iOS
```

---

## 7. API Endpoints Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/or-bookings` | GET | List all OR bookings |
| `/api/or-bookings` | POST | Create new OR booking |
| `/api/or-bookings/{id}` | GET | Get specific OR booking |
| `/api/or-bookings/{id}/status` | PUT | Update OR booking status |
| `/api/icu-requests` | GET | List all ICU requests |
| `/api/icu-requests` | POST | Create new ICU request |
| `/api/icu-requests/{id}` | GET | Get specific ICU request |
| `/api/icu-requests/{id}/status` | PUT | Update ICU request status |
| `/api/comments` | GET/POST | Manage booking comments |
| `/docs` | GET | Swagger API documentation |

---

## 8. Security Recommendations

1. **Use HTTPS** for all production deployments
2. **Change default passwords** immediately
3. **Restrict CORS origins** in `backend/main.py` to your frontend domain only
4. **Enable database SSL** for remote connections
5. **Implement rate limiting** for API endpoints
6. **Regular backups** of the database
7. **Network isolation** - backend should only be accessible from frontend servers

### Update CORS Settings

**File:** `backend/main.py`

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-frontend-domain.hospital.local"],  # Update this!
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 9. Troubleshooting

| Issue | Solution |
|-------|----------|
| Database connection error | Verify DATABASE_URL is set correctly |
| API not reachable | Check firewall rules and server is running |
| CORS errors | Update allowed origins in backend/main.py |
| Tables not found | Run the database migration SQL |
| Authentication fails | Verify passwords are configured correctly |

---

## 10. Support Contact

For technical support regarding this application, contact your system administrator or the development team.

---

## Version Information

- **Application:** VitalFlow Medical Services
- **Backend:** Python FastAPI
- **Frontend:** Flutter
- **Database:** Any SQLAlchemy-compatible database (PostgreSQL, MySQL, SQL Server, SQLite)
