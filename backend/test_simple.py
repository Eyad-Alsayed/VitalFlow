#!/usr/bin/env python3
"""
Simple Database Connection Test
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import engine, DATABASE_URL
from simple_models import Base
import sqlalchemy

def test_simple_connection():
    """Test connection to your booking_app database"""
    
    print("🔍 Testing PostgreSQL Connection to booking_app...")
    print(f"📡 Database URL: {DATABASE_URL.split('@')[0]}@****/booking_app")
    
    try:
        # Test connection
        connection = engine.connect()
        print("✅ Connection successful!")
        
        # Check database
        result = connection.execute(sqlalchemy.text("SELECT current_database()"))
        db_name = result.fetchone()[0]
        print(f"🗄️  Connected to database: {db_name}")
        
        # Check if your bookings table exists
        result = connection.execute(sqlalchemy.text("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'bookings'
        """))
        
        table_exists = result.fetchone()
        if table_exists:
            print("✅ Your 'bookings' table found!")
            
            # Count existing records
            result = connection.execute(sqlalchemy.text("SELECT COUNT(*) FROM bookings"))
            count = result.fetchone()[0]
            print(f"📊 Current records in bookings table: {count}")
        else:
            print("❌ 'bookings' table not found!")
        
        connection.close()
        print("\n🎉 Ready to start the API server!")
        return True
        
    except Exception as e:
        print(f"\n❌ Connection failed: {str(e)}")
        
        if "password authentication failed" in str(e):
            print("\n🔧 Fix: Update your password in backend/database.py")
            print("   Change 'yourpassword' to your actual PostgreSQL password")
        elif "database \"booking_app\" does not exist" in str(e):
            print("\n🔧 Fix: Make sure you created the database named 'booking_app'")
        
        return False

if __name__ == "__main__":
    success = test_simple_connection()
    if success:
        print("\n▶️  Next step: Run 'python simple_main.py' to start the API server")
    else:
        print("\n❌ Please fix the connection issue first")
    
    input("\nPress Enter to exit...")