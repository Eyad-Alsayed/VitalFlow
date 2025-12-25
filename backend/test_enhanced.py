import psycopg2
from sqlalchemy import create_engine, text
from database import DATABASE_URL
import sys

def test_enhanced_connection():
    """Test connection to PostgreSQL and enhanced table structure"""
    
    print("Enhanced OR/ICU Booking System - Database Connection Test")
    print("=" * 60)
    
    try:
        # Test direct psycopg2 connection
        print("\n1. Testing direct PostgreSQL connection...")
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()
        
        # Test basic connection
        cursor.execute("SELECT version();")
        result = cursor.fetchone()
        if result:
            version = result[0]
            print(f"   ✓ Connected to PostgreSQL: {version[:50]}...")
        
        # Test database
        cursor.execute("SELECT current_database();")
        result = cursor.fetchone()
        if result:
            db_name = result[0]
            print(f"   ✓ Connected to database: {db_name}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"   ✗ Direct connection failed: {e}")
        return False
    
    try:
        # Test SQLAlchemy connection
        print("\n2. Testing SQLAlchemy connection...")
        engine = create_engine(DATABASE_URL)
        
        with engine.connect() as connection:
            result = connection.execute(text("SELECT 1"))
            if result.fetchone():
                print("   ✓ SQLAlchemy connection successful")
        
    except Exception as e:
        print(f"   ✗ SQLAlchemy connection failed: {e}")
        return False
    
    try:
        # Test enhanced table structure
        print("\n3. Checking enhanced table structure...")
        
        with engine.connect() as connection:
            # Check if tables exist
            tables_query = text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name IN ('bookings', 'booking_comments', 'user_sessions', 'audit_logs')
                ORDER BY table_name
            """)
            
            result = connection.execute(tables_query)
            existing_tables = [row[0] for row in result.fetchall()]
            
            expected_tables = ['audit_logs', 'booking_comments', 'bookings', 'user_sessions']
            
            print(f"   Expected tables: {expected_tables}")
            print(f"   Existing tables: {existing_tables}")
            
            if set(existing_tables) == set(expected_tables):
                print("   ✓ All enhanced tables exist")
            elif 'bookings' in existing_tables:
                print("   ⚠ Basic 'bookings' table exists, but enhanced tables missing")
                print("     Run enhanced_migration.sql to create full schema")
            else:
                print("   ⚠ No tables found - run enhanced_migration.sql or start API to create tables")
            
            # Check bookings table structure
            if 'bookings' in existing_tables:
                columns_query = text("""
                    SELECT column_name, data_type, character_maximum_length, is_nullable 
                    FROM information_schema.columns 
                    WHERE table_name = 'bookings' 
                    AND table_schema = 'public'
                    ORDER BY ordinal_position
                """)
                
                result = connection.execute(columns_query)
                columns = result.fetchall()
                
                print(f"\n   Bookings table structure ({len(columns)} columns):")
                enhanced_columns = ['created_by_name', 'created_by_role', 'priority_notes', 'is_active']
                
                has_enhanced = False
                for col in columns:
                    column_name, data_type, max_length, nullable = col
                    if column_name in enhanced_columns:
                        has_enhanced = True
                    
                    length_info = f"({max_length})" if max_length else ""
                    null_info = "NULL" if nullable == 'YES' else "NOT NULL"
                    print(f"     {column_name}: {data_type}{length_info} {null_info}")
                
                if has_enhanced:
                    print("   ✓ Enhanced columns detected")
                else:
                    print("   ⚠ Basic table structure - consider running enhanced_migration.sql")
        
    except Exception as e:
        print(f"   ✗ Table structure check failed: {e}")
        return False
    
    try:
        # Test sample data operations
        print("\n4. Testing data operations...")
        
        with engine.connect() as connection:
            # Count existing bookings
            count_query = text("SELECT COUNT(*) FROM bookings WHERE is_active = true")
            result = connection.execute(count_query)
            count = result.fetchone()
            if count:
                booking_count = count[0]
                print(f"   ✓ Found {booking_count} active booking(s)")
            
            # Test comments table if it exists
            if 'booking_comments' in existing_tables:
                comment_count_query = text("SELECT COUNT(*) FROM booking_comments")
                result = connection.execute(comment_count_query)
                count = result.fetchone()
                if count:
                    comment_count = count[0]
                    print(f"   ✓ Found {comment_count} comment(s)")
        
    except Exception as e:
        print(f"   ⚠ Data operations test: {e}")
    
    print("\n" + "=" * 60)
    print("✓ Enhanced database connection test completed successfully!")
    print("\nNext steps:")
    print("1. Update your PostgreSQL password in database.py if not done already")
    print("2. Run enhanced_migration.sql in pgAdmin 4 for full schema (optional)")
    print("3. Start the enhanced API server: python enhanced_main.py")
    print("4. Access API documentation at: http://localhost:8000/docs")
    
    return True

if __name__ == "__main__":
    try:
        if test_enhanced_connection():
            sys.exit(0)
        else:
            sys.exit(1)
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        sys.exit(1)