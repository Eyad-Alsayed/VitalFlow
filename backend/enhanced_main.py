from fastapi import FastAPI, HTTPException, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
from zoneinfo import ZoneInfo
import logging
import bcrypt
import json
import csv
import io
from calendar import monthrange

from database import SessionLocal, engine
from enhanced_models import Base, Booking, BookingComment, UserSession, AuditLog, SystemSetting

# Riyadh timezone (GMT+3)
RIYADH_TZ = ZoneInfo("Asia/Riyadh")


def now_riyadh():
    """Get current time in Riyadh timezone"""
    return datetime.now(RIYADH_TZ)


# Custom JSON encoder for datetime with timezone
class DateTimeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            # Ensure timezone-aware datetime is serialized with offset
            if obj.tzinfo is None:
                # If naive, treat as Riyadh time
                obj = obj.replace(tzinfo=RIYADH_TZ)
            return obj.isoformat()
        return super().default(obj)


# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Enhanced OR/ICU Booking System", version="2.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Pydantic models for API
class BookingBase(BaseModel):
    mrn: Optional[str] = None
    patient_name: Optional[str] = None
    patient_ward: Optional[str] = None
    procedure: Optional[str] = None
    type_of_booking: str  # "OR" or "ICU"
    urgency: Optional[str] = None
    status: str = "pending"
    outcome: Optional[str] = None
    consultant: Optional[str] = None
    consultant_phone: Optional[str] = None
    requesting_physician: Optional[str] = None
    requesting_physician_phone: Optional[str] = None
    anesthesia_team_contact: Optional[str] = None
    indication: Optional[str] = None
    requested_date: Optional[datetime] = None
    priority_notes: Optional[str] = None
    special_requirements: Optional[str] = None
    unit: Optional[str] = None
    room: Optional[str] = None
    created_by_name: Optional[str] = None
    created_by_role: Optional[str] = None
    created_by_uid: Optional[str] = None
    updated_by_uid: Optional[str] = None


class BookingCreate(BookingBase):
    pass


class BookingUpdate(BaseModel):
    mrn: Optional[str] = None
    patient_name: Optional[str] = None
    patient_ward: Optional[str] = None
    procedure: Optional[str] = None
    urgency: Optional[str] = None
    status: Optional[str] = None
    outcome: Optional[str] = None
    consultant: Optional[str] = None
    consultant_phone: Optional[str] = None
    requesting_physician: Optional[str] = None
    requesting_physician_phone: Optional[str] = None
    anesthesia_team_contact: Optional[str] = None
    indication: Optional[str] = None
    requested_date: Optional[datetime] = None
    priority_notes: Optional[str] = None
    special_requirements: Optional[str] = None
    unit: Optional[str] = None
    room: Optional[str] = None
    updated_by_name: Optional[str] = None
    updated_by_role: Optional[str] = None
    updated_by_uid: Optional[str] = None


class BookingResponse(BookingBase):
    id: int
    created_at: datetime
    last_updated_at: Optional[datetime] = None
    is_active: bool = True

    class Config:
        from_attributes = True
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }


class CommentCreate(BaseModel):
    message: str
    author_name: str
    author_role: str
    is_internal: bool = False


class CommentResponse(BaseModel):
    id: int
    booking_id: int
    message: str
    author_name: str
    author_role: str
    created_at: datetime
    is_internal: bool

    class Config:
        from_attributes = True
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }


class UserSessionCreate(BaseModel):
    user_name: str
    user_role: str


# Legacy compatibility schemas (v1 mobile client)
class LegacyORBookingCreate(BaseModel):
    mrn: str
    patient_name: Optional[str] = None
    patient_ward: Optional[str] = None
    procedure: str
    urgency: str
    consultant: str
    consultant_phone: str
    requesting_physician: str
    requesting_physician_phone: str
    created_by_uid: str
    created_by_name: str
    created_by_role: str


class LegacyORBookingResponse(LegacyORBookingCreate):
    id: str
    status: str
    outcome: Optional[str] = None
    created_at: datetime
    last_updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class LegacyICUBookingCreate(BaseModel):
    mrn: str
    patient_name: Optional[str] = None
    patient_ward: Optional[str] = None
    indication: str
    urgency: str
    consultant: str
    consultant_phone: str
    requesting_physician: str
    requesting_physician_phone: str
    created_by_uid: str
    created_by_name: str
    created_by_role: str
    requested_date: Optional[datetime] = None


class LegacyICUBookingResponse(LegacyICUBookingCreate):
    id: str
    status: str
    unit: Optional[str] = None
    room: Optional[str] = None
    outcome: Optional[str] = None
    created_at: datetime
    last_updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class LegacyCommentCreate(BaseModel):
    booking_id: str
    context: str
    message: str
    author_uid: str
    author_name: str
    author_role: str


class LegacyCommentResponse(LegacyCommentCreate):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True


class MRNCheckResponse(BaseModel):
    has_active: bool
    active_booking: Optional[dict] = None


class LegacyStatusUpdate(BaseModel):
    status: str


class ICURescheduleUpdate(BaseModel):
    status: str
    requested_date: datetime


class ICUConfirmUpdate(BaseModel):
    unit: str
    room: str


# Helper function to log changes
def log_booking_change(
    db: Session,
    booking_id: int,
    action: str,
    field_changed: Optional[str] = None,
    old_value: Optional[str] = None,
    new_value: Optional[str] = None,
    changed_by_name: Optional[str] = None,
    changed_by_role: Optional[str] = None,
    notes: Optional[str] = None,
):
    audit_log = AuditLog(
        booking_id=booking_id,
        action=action,
        field_changed=field_changed,
        old_value=old_value,
        new_value=new_value,
        changed_by_name=changed_by_name,
        changed_by_role=changed_by_role,
        notes=notes,
    )
    db.add(audit_log)


def _parse_legacy_booking_id(booking_id: str) -> int:
    try:
        return int(booking_id)
    except (TypeError, ValueError):
        raise HTTPException(status_code=400, detail="Invalid booking id format")


def _booking_to_legacy_or(booking: Booking) -> LegacyORBookingResponse:
    return LegacyORBookingResponse(
        id=str(booking.id),
        mrn=booking.mrn or "",
        patient_name=booking.patient_name,
        patient_ward=booking.patient_ward,
        procedure=booking.procedure or "",
        urgency=booking.urgency or "",
        consultant=booking.consultant or "",
        consultant_phone=booking.consultant_phone or "",
        requesting_physician=booking.requesting_physician or "",
        requesting_physician_phone=booking.requesting_physician_phone or "",
        created_by_uid=booking.created_by_uid or "",
        created_by_name=booking.created_by_name or "",
        created_by_role=booking.created_by_role or "",
        status=booking.status,
        outcome=booking.outcome,
        created_at=booking.created_at,
        last_updated_at=booking.last_updated_at,
    )


def _booking_to_legacy_icu(booking: Booking) -> LegacyICUBookingResponse:
    return LegacyICUBookingResponse(
        id=str(booking.id),
        mrn=booking.mrn or "",
        patient_name=booking.patient_name,
        patient_ward=booking.patient_ward,
        indication=booking.indication or booking.procedure or "",
        urgency=booking.urgency or "",
        consultant=booking.consultant or "",
        consultant_phone=booking.consultant_phone or "",
        requesting_physician=booking.requesting_physician or "",
        requesting_physician_phone=booking.requesting_physician_phone or "",
        created_by_uid=booking.created_by_uid or "",
        created_by_name=booking.created_by_name or "",
        created_by_role=booking.created_by_role or "",
        status=booking.status,
        unit=booking.unit,
        room=booking.room,
        outcome=booking.outcome,
        requested_date=booking.requested_date,
        created_at=booking.created_at,
        last_updated_at=booking.last_updated_at,
    )


def _comment_to_legacy(comment: BookingComment) -> LegacyCommentResponse:
    return LegacyCommentResponse(
        id=str(comment.id),
        booking_id=str(comment.booking_id),
        context=comment.context or "",
        message=comment.message,
        author_uid=comment.author_uid or "",
        author_name=comment.author_name,
        author_role=comment.author_role,
        created_at=comment.created_at or now_riyadh(),
    )


def _get_booking_or_404(
    db: Session, booking_id: int, expected_type: Optional[str] = None
) -> Booking:
    query = db.query(Booking).filter(Booking.id == booking_id)
    if expected_type:
        query = query.filter(Booking.type_of_booking == expected_type)
    booking = query.first()
    if booking is None:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


# NEW: Active booking helper (based on your agreed definitions)
def has_active_booking(db: Session, mrn: str, booking_type: str):
    """
    Returns the active booking for the MRN and type_of_booking (OR/ICU)
    or None if no active booking exists.

    Active OR:   outcome is None
    Active ICU:  status in ['pending', 'no_bed_available']
    """
    if not mrn:
        return None  # cannot check duplicates without MRN

    if booking_type == "OR":
        return (
            db.query(Booking)
            .filter(
                Booking.mrn == mrn,
                Booking.type_of_booking == "OR",
                Booking.is_active == True,
                Booking.outcome.is_(None),
            )
            .first()
        )

    if booking_type == "ICU":
        return (
            db.query(Booking)
            .filter(
                Booking.mrn == mrn,
                Booking.type_of_booking == "ICU",
                Booking.is_active == True,
                Booking.status.in_(["pending", "no_bed_available"]),
            )
            .first()
        )

    return None


# NEW: Standardized duplicate error builder
def duplicate_error(message: str, booking: Booking):
    """Standardized duplicate booking error message."""
    return HTTPException(
        status_code=409,
        detail={
            "message": message,
            "existing_booking": {
                "id": booking.id,
                "status": booking.status,
                "outcome": booking.outcome,
                "urgency": booking.urgency,
                "created_at": booking.created_at.isoformat()
                if booking.created_at
                else None,
            },
        },
    )


# API Endpoints
@app.get("/")
async def root():
    return {"message": "Enhanced OR/ICU Booking System API", "version": "2.0.0"}


# Booking endpoints
@app.post("/bookings/", response_model=BookingResponse)
def create_booking(booking: BookingCreate, db: Session = Depends(get_db)):
    # Prevent duplicate active bookings for same MRN and type_of_booking
    if booking.mrn and booking.type_of_booking:
        existing = has_active_booking(db, booking.mrn, booking.type_of_booking)
        if existing:
            raise duplicate_error(
                f"An active {booking.type_of_booking} booking already exists for this MRN.",
                existing,
            )

    db_booking = Booking(**booking.dict())
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)

    # Log the creation
    log_booking_change(
        db,
        db_booking.id,
        "created",
        changed_by_name=booking.created_by_name,
        changed_by_role=booking.created_by_role,
        notes=f"New {booking.type_of_booking} booking created",
    )
    db.commit()

    return db_booking


@app.get("/bookings/", response_model=List[BookingResponse])
def get_bookings(
    skip: int = 0,
    limit: int = 100,
    type_filter: Optional[str] = None,
    status_filter: Optional[str] = None,
    active_only: bool = True,
    db: Session = Depends(get_db),
):
    query = db.query(Booking)

    if active_only:
        query = query.filter(Booking.is_active == True)
    if type_filter:
        query = query.filter(Booking.type_of_booking == type_filter)
    if status_filter:
        query = query.filter(Booking.status == status_filter)

    bookings = (
        query.order_by(Booking.created_at.desc()).offset(skip).limit(limit).all()
    )
    return bookings


@app.get("/bookings/{booking_id}", response_model=BookingResponse)
def get_booking(booking_id: int, db: Session = Depends(get_db)):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if booking is None:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


@app.put("/bookings/{booking_id}", response_model=BookingResponse)
def update_booking(
    booking_id: int, booking_update: BookingUpdate, db: Session = Depends(get_db)
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if booking is None:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Track changes for audit log
    changes = []
    update_data = booking_update.dict(exclude_unset=True)

    for field, new_value in update_data.items():
        if field in ["updated_by_name", "updated_by_role", "updated_by_uid"]:
            continue

        old_value = getattr(booking, field, None)
        if old_value != new_value:
            changes.append(
                {
                    "field": field,
                    "old_value": str(old_value) if old_value is not None else None,
                    "new_value": str(new_value) if new_value is not None else None,
                }
            )

    # Update booking
    for field, value in update_data.items():
        setattr(booking, field, value)

    setattr(booking, "last_updated_at", now_riyadh())
    db.commit()
    db.refresh(booking)

    # Log changes
    for change in changes:
        log_booking_change(
            db,
            booking_id,
            "field_updated",
            field_changed=change["field"],
            old_value=change["old_value"],
            new_value=change["new_value"],
            changed_by_name=booking_update.updated_by_name,
            changed_by_role=booking_update.updated_by_role,
        )

    if changes:
        db.commit()

    return booking


@app.delete("/bookings/{booking_id}")
def soft_delete_booking(
    booking_id: int,
    deleted_by_name: Optional[str] = None,
    deleted_by_role: Optional[str] = None,
    db: Session = Depends(get_db),
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if booking is None:
        raise HTTPException(status_code=404, detail="Booking not found")

    setattr(booking, "is_active", False)
    setattr(booking, "last_updated_at", now_riyadh())
    db.commit()

    # Log deletion
    log_booking_change(
        db,
        booking_id,
        "soft_deleted",
        changed_by_name=deleted_by_name,
        changed_by_role=deleted_by_role,
        notes="Booking soft deleted",
    )
    db.commit()

    return {"message": "Booking deleted successfully"}


# Comment endpoints
@app.post("/bookings/{booking_id}/comments/", response_model=CommentResponse)
def add_comment(
    booking_id: int, comment: CommentCreate, db: Session = Depends(get_db)
):
    # Verify booking exists
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if booking is None:
        raise HTTPException(status_code=404, detail="Booking not found")

    db_comment = BookingComment(
        booking_id=booking_id,
        context=(booking.type_of_booking or "").lower() or None,
        **comment.dict(),
    )
    db.add(db_comment)
    db.commit()
    db.refresh(db_comment)

    # Log comment addition
    log_booking_change(
        db,
        booking_id,
        "comment_added",
        changed_by_name=comment.author_name,
        changed_by_role=comment.author_role,
        notes=f"{'Internal' if comment.is_internal else 'Public'} comment added",
    )
    db.commit()

    return db_comment


@app.get("/bookings/{booking_id}/comments/", response_model=List[CommentResponse])
def get_comments(
    booking_id: int, include_internal: bool = False, db: Session = Depends(get_db)
):
    query = db.query(BookingComment).filter(BookingComment.booking_id == booking_id)

    if not include_internal:
        query = query.filter(BookingComment.is_internal == False)

    comments = query.order_by(BookingComment.created_at.desc()).all()
    return comments


# Legacy compatibility endpoints (/api/*) used by the Flutter v1 client

# MRN Validation Endpoints
@app.get("/api/check-mrn/or/{mrn}", response_model=MRNCheckResponse)
def check_or_mrn(mrn: str, db: Session = Depends(get_db)):
    """Check if MRN has an active OR booking"""
    active_booking = (
        db.query(Booking)
        .filter(
            Booking.mrn == mrn,
            Booking.type_of_booking == "OR",
            Booking.is_active == True,
            # Active if outcome is NULL or NOT in completed/cancelled states
            ~Booking.outcome.in_(['cancelled', 'executed', 'OR Done', 'completed']) | (Booking.outcome == None)
        )
        .first()
    )
    
    if active_booking:
        return MRNCheckResponse(
            has_active=True,
            active_booking={
                "id": active_booking.id,
                "patient_name": active_booking.patient_name,
                "procedure": active_booking.procedure,
                "status": active_booking.status,
                "outcome": active_booking.outcome,
                "urgency": active_booking.urgency,
                "created_at": active_booking.created_at.isoformat() if active_booking.created_at else None,
                "requested_date": active_booking.requested_date.isoformat() if active_booking.requested_date else None
            }
        )
    return MRNCheckResponse(has_active=False)


@app.get("/api/check-mrn/icu/{mrn}", response_model=MRNCheckResponse)
def check_icu_mrn(mrn: str, db: Session = Depends(get_db)):
    """Check if MRN has an active ICU request"""
    active_request = (
        db.query(Booking)
        .filter(
            Booking.mrn == mrn,
            Booking.type_of_booking == "ICU",
            Booking.is_active == True,
            # Active if status is 'pending' or 'no_bed_available'
            Booking.status.in_(['pending', 'no_bed_available'])
        )
        .first()
    )
    
    if active_request:
        return MRNCheckResponse(
            has_active=True,
            active_booking={
                "id": active_request.id,
                "patient_name": active_request.patient_name,
                "indication": active_request.indication,
                "status": active_request.status,
                "urgency": active_request.urgency,
                "created_at": active_request.created_at.isoformat() if active_request.created_at else None,
                "requested_date": active_request.requested_date.isoformat() if active_request.requested_date else None
            }
        )
    return MRNCheckResponse(has_active=False)


@app.post("/api/or-bookings", response_model=LegacyORBookingResponse)
def legacy_create_or_booking(
    booking: LegacyORBookingCreate, db: Session = Depends(get_db)
):
    # Prevent duplicate active OR booking
    existing = has_active_booking(db, booking.mrn, "OR")
    if existing:
        raise duplicate_error(
            "An active OR booking already exists for this MRN.",
            existing,
        )

    db_booking = Booking(
        mrn=booking.mrn,
        patient_name=booking.patient_name,
        patient_ward=booking.patient_ward,
        procedure=booking.procedure,
        type_of_booking="OR",
        urgency=booking.urgency,
        status="pending",
        consultant=booking.consultant,
        consultant_phone=booking.consultant_phone,
        requesting_physician=booking.requesting_physician,
        requesting_physician_phone=booking.requesting_physician_phone,
        created_by_uid=booking.created_by_uid,
        created_by_name=booking.created_by_name,
        created_by_role=booking.created_by_role,
        last_updated_at=now_riyadh(),
    )
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)

    log_booking_change(
        db,
        db_booking.id,
        "created",
        changed_by_name=booking.created_by_name,
        changed_by_role=booking.created_by_role,
        notes="Legacy OR booking created",
    )
    db.commit()

    return _booking_to_legacy_or(db_booking)


@app.get("/api/or-bookings", response_model=List[LegacyORBookingResponse])
def legacy_get_or_bookings(db: Session = Depends(get_db)):
    bookings = (
        db.query(Booking)
        .filter(Booking.type_of_booking == "OR", Booking.is_active == True)
        .order_by(Booking.created_at.desc())
        .all()
    )
    return [_booking_to_legacy_or(b) for b in bookings]


@app.get("/api/or-bookings/{booking_id}", response_model=LegacyORBookingResponse)
def legacy_get_or_booking(booking_id: str, db: Session = Depends(get_db)):
    internal_id = _parse_legacy_booking_id(booking_id)
    booking = _get_booking_or_404(db, internal_id, expected_type="OR")
    return _booking_to_legacy_or(booking)


@app.put("/api/or-bookings/{booking_id}/status")
def legacy_update_or_status(
    booking_id: str, status_update: LegacyStatusUpdate, db: Session = Depends(get_db)
):
    internal_id = _parse_legacy_booking_id(booking_id)
    booking = _get_booking_or_404(db, internal_id, expected_type="OR")
    old_status = booking.status
    booking.status = status_update.status
    booking.last_updated_at = now_riyadh()
    db.commit()

    log_booking_change(
        db,
        booking.id,
        "status_updated",
        field_changed="status",
        old_value=old_status,
        new_value=booking.status,
    )
    db.commit()

    return {"message": "Status updated successfully"}


@app.post("/api/icu-requests", response_model=LegacyICUBookingResponse)
def legacy_create_icu_request(
    request: LegacyICUBookingCreate, db: Session = Depends(get_db)
):
    # Prevent duplicate active ICU request
    existing = has_active_booking(db, request.mrn, "ICU")
    if existing:
        raise duplicate_error(
            "An active ICU request already exists for this MRN.",
            existing,
        )

    db_booking = Booking(
        mrn=request.mrn,
        patient_name=request.patient_name,
        patient_ward=request.patient_ward,
        indication=request.indication,
        procedure=request.indication,
        type_of_booking="ICU",
        urgency=request.urgency,
        status="pending",
        consultant=request.consultant,
        consultant_phone=request.consultant_phone,
        requesting_physician=request.requesting_physician,
        requesting_physician_phone=request.requesting_physician_phone,
        requested_date=request.requested_date,
        created_by_uid=request.created_by_uid,
        created_by_name=request.created_by_name,
        created_by_role=request.created_by_role,
        last_updated_at=now_riyadh(),
    )
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)

    log_booking_change(
        db,
        db_booking.id,
        "created",
        changed_by_name=request.created_by_name,
        changed_by_role=request.created_by_role,
        notes="Legacy ICU request created",
    )
    db.commit()

    return _booking_to_legacy_icu(db_booking)


@app.get("/api/icu-requests", response_model=List[LegacyICUBookingResponse])
def legacy_get_icu_requests(db: Session = Depends(get_db)):
    bookings = (
        db.query(Booking)
        .filter(Booking.type_of_booking == "ICU", Booking.is_active == True)
        .order_by(Booking.created_at.desc())
        .all()
    )
    return [_booking_to_legacy_icu(b) for b in bookings]


@app.get("/api/icu-requests/{booking_id}", response_model=LegacyICUBookingResponse)
def legacy_get_icu_request(booking_id: str, db: Session = Depends(get_db)):
    internal_id = _parse_legacy_booking_id(booking_id)
    booking = _get_booking_or_404(db, internal_id, expected_type="ICU")
    return _booking_to_legacy_icu(booking)


@app.put("/api/icu-requests/{booking_id}/status")
def legacy_update_icu_status(
    booking_id: str, status_update: LegacyStatusUpdate, db: Session = Depends(get_db)
):
    internal_id = _parse_legacy_booking_id(booking_id)
    booking = _get_booking_or_404(db, internal_id, expected_type="ICU")
    old_status = booking.status
    booking.status = status_update.status
    booking.last_updated_at = now_riyadh()
    db.commit()

    log_booking_change(
        db,
        booking.id,
        "status_updated",
        field_changed="status",
        old_value=old_status,
        new_value=booking.status,
    )
    db.commit()

    return {"message": "Status updated successfully"}


@app.put("/api/icu-requests/{booking_id}")
def legacy_reschedule_icu_request(
    booking_id: str, reschedule: ICURescheduleUpdate, db: Session = Depends(get_db)
):
    internal_id = _parse_legacy_booking_id(booking_id)
    booking = _get_booking_or_404(db, internal_id, expected_type="ICU")
    old_status = booking.status
    old_date = booking.requested_date

    booking.status = reschedule.status
    booking.requested_date = reschedule.requested_date
    booking.last_updated_at = now_riyadh()
    db.commit()

    log_booking_change(
        db,
        booking.id,
        "rescheduled",
        field_changed="status,requested_date",
        old_value=f"{old_status},{old_date}",
        new_value=f"{reschedule.status},{reschedule.requested_date}",
        notes="ICU request rescheduled",
    )
    db.commit()

    return {"message": "ICU request rescheduled successfully"}


@app.post("/api/icu-requests/{booking_id}/confirm")
def legacy_confirm_icu_request(
    booking_id: str, confirm: ICUConfirmUpdate, db: Session = Depends(get_db)
):
    """
    Confirm an ICU request and assign unit and room.
    This endpoint updates the status to 'confirmed' and sets the unit and room fields.
    """
    internal_id = _parse_legacy_booking_id(booking_id)
    booking = _get_booking_or_404(db, internal_id, expected_type="ICU")

    old_status = booking.status
    old_unit = booking.unit
    old_room = booking.room

    # Update booking with confirmation details
    booking.status = "confirmed"
    booking.unit = confirm.unit
    booking.room = confirm.room
    booking.last_updated_at = now_riyadh()
    db.commit()

    # Log the confirmation
    log_booking_change(
        db,
        booking.id,
        "confirmed",
        field_changed="status,unit,room",
        old_value=f"{old_status},{old_unit},{old_room}",
        new_value=f"confirmed,{confirm.unit},{confirm.room}",
        notes=f"ICU bed confirmed in {confirm.unit}, {confirm.room}",
    )
    db.commit()

    return _booking_to_legacy_icu(booking)


@app.put("/api/icu-requests/{booking_id}/outcome")
def update_icu_outcome(
    booking_id: str, outcome_data: dict, db: Session = Depends(get_db)
):
    """
    Update the outcome field for an ICU request.
    Used to mark requests as 'Admitted', 'Back to Ward', or 'OR Cancelled'.
    """
    internal_id = _parse_legacy_booking_id(booking_id)
    booking = _get_booking_or_404(db, internal_id, expected_type="ICU")

    outcome = outcome_data.get("outcome")
    if not outcome:
        raise HTTPException(status_code=400, detail="Outcome is required")

    old_outcome = booking.outcome
    booking.outcome = outcome
    booking.outcome_changed_at = now_riyadh()
    booking.last_updated_at = now_riyadh()
    db.commit()

    # Log the outcome update
    log_booking_change(
        db,
        booking.id,
        "outcome_updated",
        field_changed="outcome",
        old_value=old_outcome or "",
        new_value=outcome,
        notes=f"ICU outcome set to: {outcome}",
    )
    db.commit()

    return {"message": "Outcome updated successfully", "outcome": outcome}


@app.put("/api/or-bookings/{booking_id}/outcome")
def update_or_booking_outcome(
    booking_id: str, payload: dict, db: Session = Depends(get_db)
):
    """Update the outcome of an OR booking."""
    internal_id = _parse_legacy_booking_id(booking_id)
    booking = _get_booking_or_404(db, internal_id)

    outcome = payload.get("outcome")
    if not outcome:
        raise HTTPException(status_code=400, detail="Outcome is required")

    old_outcome = booking.outcome
    booking.outcome = outcome
    booking.outcome_changed_at = now_riyadh()

    # Log the outcome update
    log_booking_change(
        db,
        booking.id,
        "outcome_updated",
        field_changed="outcome",
        old_value=old_outcome or "",
        new_value=outcome,
        notes=f"OR outcome set to: {outcome}",
    )
    db.commit()

    return {"message": "Outcome updated successfully", "outcome": outcome}


@app.post("/api/comments", response_model=LegacyCommentResponse)
def legacy_create_comment(comment: LegacyCommentCreate, db: Session = Depends(get_db)):
    internal_id = _parse_legacy_booking_id(comment.booking_id)
    booking = _get_booking_or_404(db, internal_id)

    db_comment = BookingComment(
        booking_id=booking.id,
        message=comment.message,
        context=comment.context,
        author_uid=comment.author_uid,
        author_name=comment.author_name,
        author_role=comment.author_role,
        is_internal=False,
    )
    db.add(db_comment)
    db.commit()
    db.refresh(db_comment)

    log_booking_change(
        db,
        booking.id,
        "comment_added",
        changed_by_name=comment.author_name,
        changed_by_role=comment.author_role,
        notes="Legacy comment added",
    )
    db.commit()

    return _comment_to_legacy(db_comment)


@app.get("/api/comments", response_model=List[LegacyCommentResponse])
def legacy_get_comments(
    booking_id: str = Query(...),
    context: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    internal_id = _parse_legacy_booking_id(booking_id)
    _get_booking_or_404(db, internal_id)

    query = db.query(BookingComment).filter(BookingComment.booking_id == internal_id)
    if context:
        query = query.filter(BookingComment.context == context)

    comments = query.order_by(BookingComment.created_at.asc()).all()
    return [_comment_to_legacy(comment) for comment in comments]


# User session endpoints
@app.post("/sessions/", response_model=dict)
def create_session(user_session: UserSessionCreate, db: Session = Depends(get_db)):
    # Check if user already has an active session
    existing_session = (
        db.query(UserSession)
        .filter(
            UserSession.user_name == user_session.user_name,
            UserSession.is_active == True,
        )
        .first()
    )

    if existing_session:
        setattr(existing_session, "last_login", now_riyadh())
        db.commit()
        return {
            "message": "Session updated",
            "user": user_session.user_name,
            "role": user_session.user_role,
        }

    # Create new session
    db_session = UserSession(**user_session.dict())
    db.add(db_session)
    db.commit()

    return {
        "message": "Session created",
        "user": user_session.user_name,
        "role": user_session.user_role,
    }


@app.get("/sessions/active")
def get_active_sessions(db: Session = Depends(get_db)):
    sessions = db.query(UserSession).filter(UserSession.is_active == True).all()
    return [
        {"user_name": s.user_name, "user_role": s.user_role, "last_login": s.last_login}
        for s in sessions
    ]


# Statistics and reporting endpoints
@app.get("/bookings/stats/summary")
def get_booking_stats(db: Session = Depends(get_db)):
    total_bookings = db.query(Booking).filter(Booking.is_active == True).count()
    or_bookings = (
        db.query(Booking)
        .filter(Booking.type_of_booking == "OR", Booking.is_active == True)
        .count()
    )
    icu_bookings = (
        db.query(Booking)
        .filter(Booking.type_of_booking == "ICU", Booking.is_active == True)
        .count()
    )

    pending_bookings = (
        db.query(Booking)
        .filter(Booking.status == "pending", Booking.is_active == True)
        .count()
    )

    return {
        "total_active_bookings": total_bookings,
        "or_bookings": or_bookings,
        "icu_bookings": icu_bookings,
        "pending_bookings": pending_bookings,
    }


@app.get("/bookings/{booking_id}/audit-log")
def get_booking_audit_log(booking_id: int, db: Session = Depends(get_db)):
    # Verify booking exists
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if booking is None:
        raise HTTPException(status_code=404, detail="Booking not found")

    audit_logs = (
        db.query(AuditLog)
        .filter(AuditLog.booking_id == booking_id)
        .order_by(AuditLog.timestamp.desc())
        .all()
    )

    return [
        {
            "action": log.action,
            "field_changed": log.field_changed,
            "old_value": log.old_value,
            "new_value": log.new_value,
            "changed_by": f"{log.changed_by_name} ({log.changed_by_role})"
            if getattr(log, "changed_by_name", None)
            else None,
            "timestamp": log.timestamp,
            "notes": log.notes,
        }
        for log in audit_logs
    ]


# Export endpoints for admin
@app.get("/api/export/or-bookings")
def export_or_bookings(
    month: int = Query(..., ge=1, le=12),
    year: int = Query(...),
    db: Session = Depends(get_db),
):
    """
    Export OR bookings for a specific month as CSV.
    Query params: month (1-12), year (e.g., 2025)
    """
    # Get first and last day of the month
    first_day = datetime(year, month, 1)
    last_day_num = monthrange(year, month)[1]
    last_day = datetime(year, month, last_day_num, 23, 59, 59)

    # Query OR bookings for the month
    bookings = (
        db.query(Booking)
        .filter(
            Booking.type_of_booking == "OR",
            Booking.created_at >= first_day,
            Booking.created_at <= last_day,
        )
        .order_by(Booking.created_at.asc())
        .all()
    )

    # Create CSV in memory
    output = io.StringIO()
    writer = csv.writer(output)

    # Write header
    writer.writerow(
        [
            "ID",
            "MRN",
            "Patient Name",
            "Patient Ward",
            "Procedure",
            "Urgency",
            "Status",
            "Consultant",
            "Consultant Phone",
            "Requesting Physician",
            "Requesting Physician Phone",
            "Anesthesia Contact",
            "Requested Date",
            "Created At",
            "Created By",
            "Outcome",
        ]
    )

    # Write data rows
    for b in bookings:
        writer.writerow(
            [
                b.id,
                b.mrn or "",
                b.patient_name or "",
                b.patient_ward or "",
                b.procedure or "",
                b.urgency or "",
                b.status,
                b.consultant or "",
                b.consultant_phone or "",
                b.requesting_physician or "",
                b.requesting_physician_phone or "",
                b.anesthesia_team_contact or "",
                b.requested_date.strftime("%Y-%m-%d")
                if b.requested_date
                else "",
                b.created_at.strftime("%Y-%m-%d %H:%M:%S") if b.created_at else "",
                f"{b.created_by_name} ({b.created_by_role})" if b.created_by_name else "",
                b.outcome or "",
            ]
        )

    # Prepare response
    output.seek(0)
    filename = f"OR_Registry_{year}_{month:02d}.csv"

    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@app.get("/api/export/icu-requests")
def export_icu_requests(
    month: int = Query(..., ge=1, le=12),
    year: int = Query(...),
    db: Session = Depends(get_db),
):
    """
    Export ICU requests for a specific month as CSV.
    Query params: month (1-12), year (e.g., 2025)
    """
    # Get first and last day of the month
    first_day = datetime(year, month, 1)
    last_day_num = monthrange(year, month)[1]
    last_day = datetime(year, month, last_day_num, 23, 59, 59)

    # Query ICU bookings for the month
    bookings = (
        db.query(Booking)
        .filter(
            Booking.type_of_booking == "ICU",
            Booking.created_at >= first_day,
            Booking.created_at <= last_day,
        )
        .order_by(Booking.created_at.asc())
        .all()
    )

    # Create CSV in memory
    output = io.StringIO()
    writer = csv.writer(output)

    # Write header
    writer.writerow(
        [
            "ID",
            "MRN",
            "Patient Name",
            "Patient Ward",
            "Indication",
            "Urgency",
            "Status",
            "Unit",
            "Room",
            "Outcome",
            "Consultant",
            "Consultant Phone",
            "Requesting Physician",
            "Requesting Physician Phone",
            "Requested Date",
            "Created At",
            "Created By",
        ]
    )

    # Write data rows
    for b in bookings:
        writer.writerow(
            [
                b.id,
                b.mrn or "",
                b.patient_name or "",
                b.patient_ward or "",
                b.indication or "",
                b.urgency or "",
                b.status,
                b.unit or "",
                b.room or "",
                b.outcome or "",
                b.consultant or "",
                b.consultant_phone or "",
                b.requesting_physician or "",
                b.requesting_physician_phone or "",
                b.requested_date.strftime("%Y-%m-%d")
                if b.requested_date
                else "",
                b.created_at.strftime("%Y-%m-%d %H:%M:%S") if b.created_at else "",
                f"{b.created_by_name} ({b.created_by_role})" if b.created_by_name else "",
            ]
        )

    # Prepare response
    output.seek(0)
    filename = f"ICU_Registry_{year}_{month:02d}.csv"

    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


# Admin - Password Management
@app.post("/api/admin/verify-staff-password")
def verify_staff_password(credentials: dict, db: Session = Depends(get_db)):
    """Verify staff password (returns true/false instead of exposing password)"""
    password = credentials.get("password")
    if not password:
        raise HTTPException(status_code=400, detail="Password is required")

    setting = (
        db.query(SystemSetting)
        .filter(SystemSetting.setting_key == "staff_password")
        .first()
    )
    if not setting:
        # Create default hashed password if not exists
        hashed = bcrypt.hashpw("123".encode("utf-8"), bcrypt.gensalt())
        setting = SystemSetting(
            setting_key="staff_password", setting_value=hashed.decode("utf-8")
        )
        db.add(setting)
        db.commit()

    # Verify password
    try:
        is_valid = bcrypt.checkpw(
            password.encode("utf-8"), setting.setting_value.encode("utf-8")
        )
        return {"valid": is_valid}
    except Exception:
        # If stored password is not hashed (legacy), do direct comparison and then hash it
        if password == setting.setting_value:
            # Migrate to hashed password
            hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())
            setting.setting_value = hashed.decode("utf-8")
            setting.updated_at = now_riyadh()
            db.commit()
            return {"valid": True}
        return {"valid": False}


@app.put("/api/admin/staff-password")
def update_staff_password(password_update: dict, db: Session = Depends(get_db)):
    """Update the staff password (admin only) - stores hashed password"""
    new_password = password_update.get("password")
    if not new_password or len(new_password) < 3:
        raise HTTPException(
            status_code=400, detail="Password must be at least 3 characters"
        )

    # Hash the new password with bcrypt
    hashed_password = bcrypt.hashpw(new_password.encode("utf-8"), bcrypt.gensalt())

    setting = (
        db.query(SystemSetting)
        .filter(SystemSetting.setting_key == "staff_password")
        .first()
    )
    if not setting:
        setting = SystemSetting(
            setting_key="staff_password", setting_value=hashed_password.decode("utf-8")
        )
        db.add(setting)
    else:
        setting.setting_value = hashed_password.decode("utf-8")
        setting.updated_at = now_riyadh()

    db.commit()
    return {"message": "Staff password updated successfully"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
