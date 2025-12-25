-- ============================================================================
-- COMPLETE DATABASE MIGRATION SCRIPT
-- ============================================================================
-- This script handles BOTH fresh installations and existing database migrations
-- It safely adds missing columns without breaking existing data
--
-- Usage:
--   psql "postgresql://postgres:Dreem%4024@localhost:5432/booking_app" -f backend/database_migration.sql
-- ============================================================================

-- SECTION 1: Create or Update bookings table
-- ============================================================================

-- Create the bookings table if it doesn't exist
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    -- Original fields
    mrn VARCHAR(50),
    patient_name VARCHAR(200),
    patient_ward VARCHAR(100),
    procedure VARCHAR(200),
    type_of_booking VARCHAR(20) NOT NULL CHECK (type_of_booking IN ('OR', 'ICU')),
    urgency VARCHAR(10),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    outcome VARCHAR(20),
    consultant VARCHAR(200),
    consultant_phone VARCHAR(50),
    requesting_physician VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Enhanced fields
    requesting_physician_phone VARCHAR(50),
    anesthesia_team_contact VARCHAR(50),
    indication TEXT,
    requested_date TIMESTAMP,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- User tracking
    created_by_uid VARCHAR(100),
    created_by_name VARCHAR(100),
    created_by_role VARCHAR(50) CHECK (created_by_role IN ('applicant', 'anesthesia', 'icu_team', 'admin')),
    updated_by_uid VARCHAR(100),
    updated_by_name VARCHAR(100),
    updated_by_role VARCHAR(50) CHECK (updated_by_role IN ('applicant', 'anesthesia', 'icu_team', 'admin')),
    
    -- Additional metadata
    priority_notes TEXT,
    special_requirements TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- ICU bed assignment fields
    unit VARCHAR(100),
    room VARCHAR(100),
    
    -- Outcome tracking
    outcome_changed_at TIMESTAMP
);

-- Add missing columns to existing bookings table (for migrations)
DO $$
BEGIN
    -- Add patient_ward if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'patient_ward') THEN
        ALTER TABLE bookings ADD COLUMN patient_ward VARCHAR(100);
        RAISE NOTICE '✅ Added patient_ward column';
    END IF;
    
    -- Add requesting_physician_phone
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'requesting_physician_phone') THEN
        ALTER TABLE bookings ADD COLUMN requesting_physician_phone VARCHAR(50);
        RAISE NOTICE '✅ Added requesting_physician_phone column';
    END IF;
    
    -- Add anesthesia_team_contact
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'anesthesia_team_contact') THEN
        ALTER TABLE bookings ADD COLUMN anesthesia_team_contact VARCHAR(50);
        RAISE NOTICE '✅ Added anesthesia_team_contact column';
    END IF;
    
    -- Add indication
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'indication') THEN
        ALTER TABLE bookings ADD COLUMN indication TEXT;
        RAISE NOTICE '✅ Added indication column';
    END IF;
    
    -- Add requested_date
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'requested_date') THEN
        ALTER TABLE bookings ADD COLUMN requested_date TIMESTAMP;
        RAISE NOTICE '✅ Added requested_date column';
    END IF;
    
    -- Add last_updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'last_updated_at') THEN
        ALTER TABLE bookings ADD COLUMN last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
        RAISE NOTICE '✅ Added last_updated_at column';
    END IF;
    
    -- Add created_by_uid
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'created_by_uid') THEN
        ALTER TABLE bookings ADD COLUMN created_by_uid VARCHAR(100);
        RAISE NOTICE '✅ Added created_by_uid column';
    END IF;
    
    -- Add created_by_name
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'created_by_name') THEN
        ALTER TABLE bookings ADD COLUMN created_by_name VARCHAR(100);
        RAISE NOTICE '✅ Added created_by_name column';
    END IF;
    
    -- Add created_by_role
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'created_by_role') THEN
        ALTER TABLE bookings ADD COLUMN created_by_role VARCHAR(50);
        RAISE NOTICE '✅ Added created_by_role column';
    END IF;
    
    -- Add updated_by_uid
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'updated_by_uid') THEN
        ALTER TABLE bookings ADD COLUMN updated_by_uid VARCHAR(100);
        RAISE NOTICE '✅ Added updated_by_uid column';
    END IF;
    
    -- Add updated_by_name
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'updated_by_name') THEN
        ALTER TABLE bookings ADD COLUMN updated_by_name VARCHAR(100);
        RAISE NOTICE '✅ Added updated_by_name column';
    END IF;
    
    -- Add updated_by_role
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'updated_by_role') THEN
        ALTER TABLE bookings ADD COLUMN updated_by_role VARCHAR(50);
        RAISE NOTICE '✅ Added updated_by_role column';
    END IF;
    
    -- Add priority_notes
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'priority_notes') THEN
        ALTER TABLE bookings ADD COLUMN priority_notes TEXT;
        RAISE NOTICE '✅ Added priority_notes column';
    END IF;
    
    -- Add special_requirements
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'special_requirements') THEN
        ALTER TABLE bookings ADD COLUMN special_requirements TEXT;
        RAISE NOTICE '✅ Added special_requirements column';
    END IF;
    
    -- Add is_active
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'is_active') THEN
        ALTER TABLE bookings ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
        RAISE NOTICE '✅ Added is_active column';
    END IF;
    
    -- Add unit (ICU bed assignment)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'unit') THEN
        ALTER TABLE bookings ADD COLUMN unit VARCHAR(100);
        RAISE NOTICE '✅ Added unit column';
    END IF;
    
    -- Add room (ICU bed assignment)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'room') THEN
        ALTER TABLE bookings ADD COLUMN room VARCHAR(100);
        RAISE NOTICE '✅ Added room column';
    END IF;
    
    -- Add outcome_changed_at (outcome tracking)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'outcome_changed_at') THEN
        ALTER TABLE bookings ADD COLUMN outcome_changed_at TIMESTAMP;
        RAISE NOTICE '✅ Added outcome_changed_at column';
    END IF;
END $$;

-- SECTION 2: Create comments table
-- ============================================================================

CREATE TABLE IF NOT EXISTS booking_comments (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    context VARCHAR(20),
    author_name VARCHAR(100) NOT NULL,
    author_role VARCHAR(50) NOT NULL CHECK (author_role IN ('applicant', 'anesthesia', 'icu_team', 'admin')),
    author_uid VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_internal BOOLEAN DEFAULT FALSE
);

-- Add missing columns to booking_comments (for migrations)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'booking_comments' AND column_name = 'context') THEN
        ALTER TABLE booking_comments ADD COLUMN context VARCHAR(20);
        RAISE NOTICE '✅ Added context column to booking_comments';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'booking_comments' AND column_name = 'author_uid') THEN
        ALTER TABLE booking_comments ADD COLUMN author_uid VARCHAR(100);
        RAISE NOTICE '✅ Added author_uid column to booking_comments';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'booking_comments' AND column_name = 'is_internal') THEN
        ALTER TABLE booking_comments ADD COLUMN is_internal BOOLEAN DEFAULT FALSE;
        RAISE NOTICE '✅ Added is_internal column to booking_comments';
    END IF;
END $$;

-- SECTION 3: Create user sessions table
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_sessions (
    id SERIAL PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    user_role VARCHAR(50) NOT NULL CHECK (user_role IN ('applicant', 'anesthesia', 'icu_team')),
    last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- SECTION 4: Create audit logs table
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER REFERENCES bookings(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL,
    field_changed VARCHAR(50),
    old_value VARCHAR(200),
    new_value VARCHAR(200),
    changed_by_name VARCHAR(100),
    changed_by_role VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- SECTION 4A: Create system settings table for passwords
-- ============================================================================

CREATE TABLE IF NOT EXISTS system_settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default staff password if not exists
INSERT INTO system_settings (setting_key, setting_value)
VALUES ('staff_password', '123')
ON CONFLICT (setting_key) DO NOTHING;

-- SECTION 5: Create indexes for performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_bookings_mrn ON bookings(mrn);
CREATE INDEX IF NOT EXISTS idx_bookings_type_status ON bookings(type_of_booking, status);
CREATE INDEX IF NOT EXISTS idx_bookings_created_at ON bookings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_active ON bookings(is_active);
CREATE INDEX IF NOT EXISTS idx_bookings_unit ON bookings(unit) WHERE unit IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_bookings_room ON bookings(room) WHERE room IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_comments_booking_id ON booking_comments(booking_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_booking_id ON audit_logs(booking_id);

-- SECTION 6: Insert sample data (optional - only for testing)
-- ============================================================================

-- Final success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ DATABASE MIGRATION COMPLETED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables created/updated:';
    RAISE NOTICE '  ✓ bookings (with all 29 columns including unit and room)';
    RAISE NOTICE '  ✓ booking_comments';
    RAISE NOTICE '  ✓ user_sessions';
    RAISE NOTICE '  ✓ audit_logs';
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes created for performance optimization';
    RAISE NOTICE '';
    RAISE NOTICE 'Your database is ready! Start the backend:';
    RAISE NOTICE '  cd backend';
    RAISE NOTICE '  python enhanced_main.py';
    RAISE NOTICE '';
END $$;

COMMIT;

-- =====================================================================
-- CONVERT ALL TIMESTAMP FIELDS TO TIMESTAMPTZ SAFELY (NO DATA LOSS)
-- =====================================================================

ALTER TABLE bookings 
    ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Riyadh',
    ALTER COLUMN last_updated_at TYPE TIMESTAMPTZ USING last_updated_at AT TIME ZONE 'Asia/Riyadh',
    ALTER COLUMN requested_date TYPE TIMESTAMPTZ USING requested_date AT TIME ZONE 'Asia/Riyadh';

ALTER TABLE booking_comments
    ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Riyadh';

ALTER TABLE user_sessions
    ALTER COLUMN last_login TYPE TIMESTAMPTZ USING last_login AT TIME ZONE 'Asia/Riyadh';

ALTER TABLE audit_logs
    ALTER COLUMN timestamp TYPE TIMESTAMPTZ USING timestamp AT TIME ZONE 'Asia/Riyadh';

ALTER TABLE system_settings
    ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'Asia/Riyadh';

RAISE NOTICE '⏱ TIMESTAMP fields successfully converted to TIMESTAMPTZ (Riyadh time).';
