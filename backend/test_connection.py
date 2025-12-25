#!/usr/bin/env python3
"""
Database Connection Test Script
Run this to verify your PostgreSQL connection before starting the main application.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import engine, DATABASE_URL
from models import Base
import sqlalchemy

def test_connection():
    """Test PostgreSQL connection and create tables if they don't exist."""
    
    print("🔍 Testing PostgreSQL Connection...")
    print(f"📡 Database URL: {DATABASE_URL.replace(':', ':*****@', 1) if '@' in DATABASE_URL else DATABASE_URL}")
    
    try:
        # Test basic connection
        print("⏳ Attempting to connect...")
        connection = engine.connect()
        print("✅ Connection successful!")
        
        # Get PostgreSQL version
        result = connection.execute(sqlalchemy.text("SELECT version()"))
        version = result.fetchone()[0]
        print(f"🐘 PostgreSQL Version: {version.split(',')[0]}")
        
        # Test database access
        result = connection.execute(sqlalchemy.text("SELECT current_database()"))
        db_name = result.fetchone()[0]
        print(f"🗄️  Connected to database: {db_name}")
        
        # Create tables
        print("📋 Creating tables...")
        Base.metadata.create_all(bind=engine)
        print("✅ Tables created successfully!")
        
        # List created tables
        result = connection.execute(sqlalchemy.text("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
        """))
        tables = [row[0] for row in result.fetchall()]
        print(f"📊 Tables in database: {', '.join(tables) if tables else 'None'}")
        
        connection.close()
        print("\n🎉 Database setup complete! You can now start the FastAPI server.")
        return True
        
    except Exception as e:
        print(f"\n❌ Connection failed: {str(e)}")
        print("\n🔧 Troubleshooting tips:")
        print("1. Make sure PostgreSQL service is running")
        print("2. Check your username and password in database.py")
        print("3. Verify the database 'medical_services' exists")
        print("4. Ensure PostgreSQL is listening on port 5432")
        print("\n💡 To create the database, run:")
        print("   psql -U postgres")
        print("   CREATE DATABASE medical_services;")
        return False

if __name__ == "__main__":
    success = test_connection()
    if not success:
        sys.exit(1)