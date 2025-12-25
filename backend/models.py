from sqlalchemy import Column, String, DateTime, Text, Enum
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import enum

from database import Base

class ORUrgency(str, enum.Enum):
    E1 = "e1"
    E2 = "e2"
    E3 = "e3"

class ORStatus(str, enum.Enum):
    PENDING = "pending"
    SEEN_ACCEPTED = "seenAccepted"
    AWAITING_RESOURCES = "awaitingResources"
    OPERATION_DONE = "opDone"
    POSTPONED = "postponed"
    CANCELLED = "cancelled"

class ICUUrgency(str, enum.Enum):
    CRITICAL = "critical"
    ELECTIVE = "elective"

class ICUStatus(str, enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    NO_BED_AVAILABLE = "noBedAvailable"
    NOT_REQUESTED = "notRequested"

class ORBooking(Base):
    __tablename__ = "or_bookings"
    
    id = Column(String, primary_key=True)
    mrn = Column(String, nullable=False)
    patient_name = Column(String, nullable=True)  # Optional patient name
    patient_ward = Column(String, nullable=True)  # Optional patient ward
    procedure = Column(Text, nullable=False)
    urgency = Column(Enum(ORUrgency), nullable=False)
    status = Column(Enum(ORStatus), default=ORStatus.PENDING)
    outcome = Column(String, nullable=True)  # Outcome (OR Done, OR Cancelled)
    outcome_changed_at = Column(DateTime, nullable=True)
    consultant = Column(String, nullable=False)
    consultant_phone = Column(String, nullable=False)
    requesting_physician = Column(String, nullable=False)
    requesting_physician_phone = Column(String, nullable=False)
    created_by_uid = Column(String, nullable=False)
    created_by_name = Column(String, nullable=False)
    created_by_role = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False)
    last_updated_at = Column(DateTime)

class ICUBedRequest(Base):
    __tablename__ = "icu_requests"
    
    id = Column(String, primary_key=True)
    mrn = Column(String, nullable=False)
    patient_name = Column(String, nullable=True)  # Patient name
    patient_ward = Column(String, nullable=True)  # Patient ward
    indication = Column(Text, nullable=False)
    urgency = Column(Enum(ICUUrgency), nullable=False)
    status = Column(Enum(ICUStatus), default=ICUStatus.PENDING)
    unit = Column(String, nullable=True)  # ICU unit assigned when confirmed
    room = Column(String, nullable=True)  # Room assigned when confirmed
    outcome = Column(String, nullable=True)  # Outcome after admission (Admitted, Back to Ward, etc.)
    consultant = Column(String, nullable=False)
    consultant_phone = Column(String, nullable=False)
    requesting_physician = Column(String, nullable=False)
    requesting_physician_phone = Column(String, nullable=False)
    requested_date = Column(DateTime)
    created_by_uid = Column(String, nullable=False)
    created_by_name = Column(String, nullable=False)
    created_by_role = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False)
    last_updated_at = Column(DateTime)

class Comment(Base):
    __tablename__ = "comments"
    
    id = Column(String, primary_key=True)
    booking_id = Column(String, nullable=False)
    context = Column(String, nullable=False)  # 'or' or 'icu'
    message = Column(Text, nullable=False)
    author_uid = Column(String, nullable=False)
    author_name = Column(String, nullable=False)
    author_role = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False)