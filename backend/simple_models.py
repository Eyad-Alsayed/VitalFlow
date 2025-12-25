from sqlalchemy import Column, Integer, String, DateTime, Text
from datetime import datetime
import enum

from database import Base

class BookingType(str, enum.Enum):
    OR = "OR"
    ICU = "ICU"

class UrgencyLevel(str, enum.Enum):
    E1 = "E1"
    E2 = "E2"
    E3 = "E3"
    CRITICAL = "Critical"
    ELECTIVE = "Elective"

class BookingStatus(str, enum.Enum):
    PENDING = "pending"
    SEEN_ACCEPTED = "seen_accepted"
    AWAITING_RESOURCES = "awaiting_resources"
    OPERATION_DONE = "operation_done"
    CONFIRMED = "confirmed"
    NO_BED_AVAILABLE = "no_bed_available"
    REJECTED = "rejected"
    NOT_REQUESTED = "not_requested"

class BookingOutcome(str, enum.Enum):
    EXECUTED = "executed"
    CANCELLED = "cancelled"
    POSTPONED = "postponed"

class Booking(Base):
    __tablename__ = "bookings"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    mrn = Column(String(50))
    patient_name = Column(String(200))
    procedure = Column(String(200))
    type_of_booking = Column(String(20))  # OR / ICU
    urgency = Column(String(10))
    status = Column(String(50))
    outcome = Column(String(20))          # executed / cancelled / postponed
    consultant = Column(String(200))
    consultant_phone = Column(String(50))
    requesting_physician = Column(String(200))
    created_at = Column(DateTime, default=datetime.utcnow)

# Keep the old models for backwards compatibility if needed
# but we'll primarily use the new Booking model