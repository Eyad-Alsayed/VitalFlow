from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from zoneinfo import ZoneInfo
import enum

from database import Base

# Riyadh timezone (GMT+3)
RIYADH_TZ = ZoneInfo("Asia/Riyadh")

def now_riyadh():
    """Get current time in Riyadh timezone"""
    return datetime.now(RIYADH_TZ)

# Enums for better data integrity (optional - can also use strings)
class BookingType(str, enum.Enum):
    OR = "OR"
    ICU = "ICU"

class UrgencyLevel(str, enum.Enum):
    # OR urgencies
    E1 = "E1"  # Within 1 hour
    E2 = "E2"  # Within 6 hours  
    E3 = "E3"  # Within 24 hours
    # ICU urgencies
    CRITICAL = "Critical"
    ELECTIVE = "Elective"

class BookingStatus(str, enum.Enum):
    # Common statuses
    PENDING = "pending"
    SEEN_ACCEPTED = "seen_accepted" 
    AWAITING_RESOURCES = "awaiting_resources"
    # OR specific
    OPERATION_DONE = "operation_done"
    # ICU specific  
    CONFIRMED = "confirmed"
    NO_BED_AVAILABLE = "no_bed_available"
    REJECTED = "rejected"
    # Common outcomes
    NOT_REQUESTED = "not_requested"
    POSTPONED = "postponed"

class BookingOutcome(str, enum.Enum):
    EXECUTED = "executed"
    CANCELLED = "cancelled" 
    POSTPONED = "postponed"
    COMPLETED = "completed"

# Main Bookings Table (Your Design + Enhancements)
class Booking(Base):
    __tablename__ = "bookings"
    
    # Your original fields
    id = Column(Integer, primary_key=True, autoincrement=True)
    mrn = Column(String(50))
    patient_name = Column(String(200))
    patient_ward = Column(String(100))
    procedure = Column(String(200))
    type_of_booking = Column(String(20))  # "OR" or "ICU"
    urgency = Column(String(10))
    status = Column(String(50))
    outcome = Column(String(20))
    consultant = Column(String(200))
    consultant_phone = Column(String(50))
    requesting_physician = Column(String(200))
    created_at = Column(DateTime, default=now_riyadh)
    
    # Enhanced fields
    requesting_physician_phone = Column(String(50))
    anesthesia_team_contact = Column(String(50))  # For OR bookings
    indication = Column(Text)  # Alternative to procedure for ICU
    requested_date = Column(DateTime)  # For scheduled procedures
    last_updated_at = Column(DateTime, default=now_riyadh)
    
    # User tracking
    created_by_uid = Column(String(100))
    created_by_name = Column(String(100))
    created_by_role = Column(String(50))  # "applicant", "anesthesia", "icu_team"
    updated_by_uid = Column(String(100))
    updated_by_name = Column(String(100))
    updated_by_role = Column(String(50))
    
    # Additional metadata
    priority_notes = Column(Text)
    special_requirements = Column(Text)
    is_active = Column(Boolean, default=True)
    
    # ICU bed assignment fields
    unit = Column(String(100))  # ICU unit assignment (e.g., "ICU-A", "CCU")
    room = Column(String(100))  # Room/bed assignment (e.g., "Room 101", "Bed 5")
    
    # Outcome tracking
    outcome_changed_at = Column(DateTime)  # Timestamp when outcome was last changed
    
    # Relationships
    comments = relationship("BookingComment", back_populates="booking", cascade="all, delete-orphan")

# Comments Table (My Design)
class BookingComment(Base):
    __tablename__ = "booking_comments"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    booking_id = Column(Integer, ForeignKey('bookings.id'), nullable=False)
    message = Column(Text, nullable=False)
    context = Column(String(20))  # Legacy context hint ("or"/"icu")
    author_name = Column(String(100), nullable=False)
    author_role = Column(String(50), nullable=False)  # "applicant", "anesthesia", "icu_team"
    author_uid = Column(String(100))
    created_at = Column(DateTime, default=now_riyadh)
    is_internal = Column(Boolean, default=False)  # Internal staff notes vs public comments
    
    # Relationship
    booking = relationship("Booking", back_populates="comments")

# User Sessions Table (Simple user management)
class UserSession(Base):
    __tablename__ = "user_sessions"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_name = Column(String(100), nullable=False)
    user_role = Column(String(50), nullable=False)
    last_login = Column(DateTime, default=now_riyadh)
    is_active = Column(Boolean, default=True)

# Audit Log Table (Track all changes)
class AuditLog(Base):
    __tablename__ = "audit_logs"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    booking_id = Column(Integer, ForeignKey('bookings.id'))
    action = Column(String(50))  # "created", "status_updated", "cancelled", etc.
    field_changed = Column(String(50))
    old_value = Column(String(200))
    new_value = Column(String(200))
    changed_by_name = Column(String(100))
    changed_by_role = Column(String(50))
    timestamp = Column(DateTime, default=now_riyadh)
    notes = Column(Text)

# System Settings Table (Store configuration like passwords)
class SystemSetting(Base):
    __tablename__ = "system_settings"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    setting_key = Column(String(100), unique=True, nullable=False)
    setting_value = Column(Text, nullable=False)
    updated_at = Column(DateTime, default=now_riyadh)
