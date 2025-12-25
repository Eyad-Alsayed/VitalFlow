# Enhanced OR/ICU Booking System - Setup Guide

## 🎉 You now have BOTH features combined!

This enhanced system includes:
- **Your original simple table structure** (bookings table with all your fields)
- **My advanced features** (comments, user tracking, audit logs, enhanced API)

## 📊 Database Features

### Core Bookings Table (Your Design + Enhancements)
- Your original fields: `id`, `mrn`, `patient_name`, `procedure`, `type_of_booking`, `urgency`, `status`, `outcome`, `consultant`, `consultant_phone`, `requesting_physician`, `created_at`
- Enhanced fields: `requesting_physician_phone`, `anesthesia_team_contact`, `indication`, `requested_date`, `priority_notes`, `special_requirements`
- User tracking: `created_by_name`, `created_by_role`, `updated_by_name`, `updated_by_role`
- Management: `last_updated_at`, `is_active` (soft delete)

### Additional Tables
- **booking_comments**: Comments system with internal/public notes
- **user_sessions**: Simple user management and tracking
- **audit_logs**: Complete change history for all bookings

## 🚀 Quick Start

### Step 1: Update Database Connection
```bash
# Edit backend/database.py
# Replace YOUR_PASSWORD_HERE with your PostgreSQL password
```

### Step 2: Choose Setup Method

#### Option A: Full Enhanced Setup (Recommended)
```bash
# Windows
cd backend
start_enhanced.bat

# Linux/Mac  
cd backend
chmod +x start_enhanced.sh
./start_enhanced.sh
```

#### Option B: Manual Setup
```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate
# Activate (Linux/Mac)
source venv/bin/activate

# Install packages
pip install -r requirements.txt

# Test connection
python test_enhanced.py

# Start server
python enhanced_main.py
```

### Step 3: Database Schema Setup

#### Option A: Use Your Existing Table (Simplest)
Your existing `bookings` table will work! The API will adapt to whatever columns exist.

#### Option B: Enhanced Schema (Recommended)
Run `enhanced_migration.sql` in pgAdmin 4:
1. Open pgAdmin 4
2. Connect to your `booking_app` database  
3. Open Query Tool
4. Copy/paste content from `backend/enhanced_migration.sql`
5. Execute the script

## 📱 Frontend Updates

### Update Service Import
Replace your current API service with the enhanced version:

```dart
// In your screens, replace:
// import '../services/api_service.dart';
// With:
import '../services/enhanced_api_service.dart';

// Replace ApiService with EnhancedApiService
```

### User Session Setup
Add user login to your app:

```dart
// When user logs in
await EnhancedApiService.createSession('Dr. Smith', 'anesthesia');

// All subsequent API calls will include user info for tracking
```

## 🔧 API Features

The enhanced API provides all your original functionality plus:

### Original Features
- ✅ Get all bookings: `GET /bookings/`
- ✅ Filter by type: `GET /bookings/?type_filter=OR`
- ✅ Create booking: `POST /bookings/`
- ✅ Update booking: `PUT /bookings/{id}`
- ✅ Delete booking: `DELETE /bookings/{id}`

### New Features
- 📝 **Comments**: Add notes to any booking
- 👥 **User Tracking**: See who created/updated each booking  
- 📊 **Statistics**: Get booking counts and summaries
- 📜 **Audit Log**: Complete history of all changes
- 🔍 **Advanced Filtering**: Filter by status, type, active status
- 🔒 **Soft Delete**: Bookings are never permanently lost

### API Documentation
Once running, visit: `http://localhost:8000/docs`

## 🗂️ File Structure

```
backend/
├── enhanced_main.py        # Enhanced API server
├── enhanced_models.py      # Database models with all features
├── enhanced_migration.sql  # Database schema script
├── test_enhanced.py       # Connection test with table analysis
├── start_enhanced.bat/sh  # Setup scripts
├── database.py           # Database configuration
└── requirements.txt      # Python dependencies

lib/services/
├── enhanced_api_service.dart  # Enhanced Flutter API client
└── database_service.dart     # Your existing service (still works)

lib/models/
├── booking.dart    # Enhanced booking model
└── comment.dart    # New comment model
```

## 🎯 What You Can Do Now

### 1. All Your Original Features Work
- Create OR/ICU bookings
- Update status and outcomes  
- View booking lists
- Filter by type

### 2. Plus New Enhanced Features

#### Comments System
```dart
// Add a comment
await EnhancedApiService.addComment(bookingId, "Patient is stable");

// Get comments for a booking
final comments = await EnhancedApiService.getComments(bookingId);
```

#### User Tracking
```dart  
// Set current user (do this once when user logs in)
await EnhancedApiService.createSession("Dr. Smith", "anesthesia");

// All creates/updates will now track who did them
```

#### Advanced Filtering
```dart
// Get only OR bookings that are pending
final orBookings = await EnhancedApiService.getORBookings(statusFilter: "pending");

// Get statistics
final stats = await EnhancedApiService.getBookingStats();
// Returns: {"total_active_bookings": 15, "or_bookings": 8, "icu_bookings": 7, "pending_bookings": 3}
```

#### Audit Trail
```dart
// See complete history of changes for a booking
final auditLog = await EnhancedApiService.getAuditLog(bookingId);
// Shows who changed what and when
```

## 🔧 Customization

### Database Fields
The system is flexible - you can:
- Keep your existing simple table as-is
- Add enhanced columns gradually  
- Use the full enhanced schema
- Mix and match fields as needed

### User Roles
Currently supports:
- `applicant`: Users who create booking requests
- `anesthesia`: Anesthesia team members  
- `icu_team`: ICU team members

Easy to add more roles by updating the enum constraints.

## 🚨 Troubleshooting

### Connection Issues
```bash
# Test your connection
python test_enhanced.py

# Common fixes:
# 1. Update password in database.py
# 2. Ensure PostgreSQL is running
# 3. Verify database name is "booking_app"
```

### Missing Tables
The API will create basic tables automatically, but for full features run `enhanced_migration.sql`.

### Flutter Integration
If you get import errors, make sure you're using `enhanced_api_service.dart` instead of the old service.

## 🎉 Next Steps

1. **Test the connection**: Run `python test_enhanced.py`
2. **Start the API**: Run `python enhanced_main.py`  
3. **Visit the docs**: `http://localhost:8000/docs`
4. **Update your Flutter app**: Use `enhanced_api_service.dart`
5. **Add user login**: Set up user sessions for tracking

Your booking system now has enterprise-grade features while keeping the simplicity you wanted! 🚀