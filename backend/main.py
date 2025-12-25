from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List, Optional
import uvicorn
import uuid

from database import get_db, engine
from models import ORBooking, ICUBedRequest, Comment, Base, ICUStatus
from schemas import (
    ORBookingCreate, ORBookingResponse, ORBookingUpdate,
    ICURequestCreate, ICURequestResponse, ICURequestUpdate,
    CommentCreate, CommentResponse
)

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="VitalFlow API", version="1.0.0")

# CORS for Flutter web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:8080", "*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OR Booking endpoints
@app.post("/api/or-bookings", response_model=ORBookingResponse)
async def create_or_booking(booking: ORBookingCreate, db: Session = Depends(get_db)):
    db_booking = ORBooking(
        id=str(uuid.uuid4()),
        **booking.dict(),
        created_at=datetime.utcnow(),
        last_updated_at=datetime.utcnow()
    )
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)
    return db_booking

@app.get("/api/or-bookings", response_model=List[ORBookingResponse])
async def get_or_bookings(db: Session = Depends(get_db)):
    return db.query(ORBooking).order_by(ORBooking.created_at.desc()).all()

@app.get("/api/or-bookings/{booking_id}", response_model=ORBookingResponse)
async def get_or_booking(booking_id: str, db: Session = Depends(get_db)):
    booking = db.query(ORBooking).filter(ORBooking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking

@app.put("/api/or-bookings/{booking_id}/status")
async def update_or_status(booking_id: str, status_update: dict, db: Session = Depends(get_db)):
    booking = db.query(ORBooking).filter(ORBooking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Update using SQLAlchemy update method
    db.query(ORBooking).filter(ORBooking.id == booking_id).update({
        ORBooking.status: status_update["status"],
        ORBooking.last_updated_at: datetime.utcnow()
    })
    db.commit()
    return {"message": "Status updated successfully"}

@app.put("/api/or-bookings/{booking_id}/outcome")
async def update_or_outcome(booking_id: str, outcome_update: dict, db: Session = Depends(get_db)):
    booking = db.query(ORBooking).filter(ORBooking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    db.query(ORBooking).filter(ORBooking.id == booking_id).update({
        ORBooking.outcome: outcome_update.get("outcome"),
        ORBooking.outcome_changed_at: datetime.utcnow(),
        ORBooking.last_updated_at: datetime.utcnow()
    })
    db.commit()
    return {"message": "Outcome updated successfully"}

# ICU Bed Request endpoints
@app.post("/api/icu-requests", response_model=ICURequestResponse)
async def create_icu_request(request: ICURequestCreate, db: Session = Depends(get_db)):
    db_request = ICUBedRequest(
        id=str(uuid.uuid4()),
        **request.dict(),
        created_at=datetime.utcnow(),
        last_updated_at=datetime.utcnow()
    )
    db.add(db_request)
    db.commit()
    db.refresh(db_request)
    return db_request

@app.get("/api/icu-requests", response_model=List[ICURequestResponse])
async def get_icu_requests(db: Session = Depends(get_db)):
    return db.query(ICUBedRequest).order_by(ICUBedRequest.created_at.desc()).all()

@app.get("/api/icu-requests/{request_id}", response_model=ICURequestResponse)
async def get_icu_request(request_id: str, db: Session = Depends(get_db)):
    request = db.query(ICUBedRequest).filter(ICUBedRequest.id == request_id).first()
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")
    return request

@app.put("/api/icu-requests/{request_id}/status")
async def update_icu_status(request_id: str, status_update: dict, db: Session = Depends(get_db)):
    request = db.query(ICUBedRequest).filter(ICUBedRequest.id == request_id).first()
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")
    
    # Validate status value against enum
    status_value = status_update.get("status")
    try:
        validated_status = ICUStatus(status_value)
    except ValueError:
        raise HTTPException(status_code=422, detail=f"Invalid status: {status_value}. Valid values: {[s.value for s in ICUStatus]}")
    
    # Update using SQLAlchemy update method
    db.query(ICUBedRequest).filter(ICUBedRequest.id == request_id).update({
        ICUBedRequest.status: validated_status,
        ICUBedRequest.last_updated_at: datetime.utcnow()
    })
    db.commit()
    return {"message": "Status updated successfully"}

@app.post("/api/icu-requests/{request_id}/confirm")
async def confirm_icu_request(request_id: str, confirm_data: dict, db: Session = Depends(get_db)):
    """Confirm an ICU request with unit and room assignment."""
    request = db.query(ICUBedRequest).filter(ICUBedRequest.id == request_id).first()
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")
    
    # Update with confirmation details
    db.query(ICUBedRequest).filter(ICUBedRequest.id == request_id).update({
        ICUBedRequest.status: ICUStatus.CONFIRMED,
        ICUBedRequest.unit: confirm_data.get("unit"),
        ICUBedRequest.room: confirm_data.get("room"),
        ICUBedRequest.last_updated_at: datetime.utcnow()
    })
    db.commit()
    db.refresh(request)
    return request

@app.put("/api/icu-requests/{request_id}/outcome")
async def update_icu_outcome(request_id: str, outcome_data: dict, db: Session = Depends(get_db)):
    """Update the outcome of an ICU request (Admitted, Back to Ward, etc.)."""
    request = db.query(ICUBedRequest).filter(ICUBedRequest.id == request_id).first()
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")
    
    db.query(ICUBedRequest).filter(ICUBedRequest.id == request_id).update({
        ICUBedRequest.outcome: outcome_data.get("outcome"),
        ICUBedRequest.last_updated_at: datetime.utcnow()
    })
    db.commit()
    return {"message": "Outcome updated successfully"}

# Comments endpoints
@app.post("/api/comments", response_model=CommentResponse)
async def create_comment(comment: CommentCreate, db: Session = Depends(get_db)):
    db_comment = Comment(
        id=str(uuid.uuid4()),
        **comment.dict(),
        created_at=datetime.utcnow()
    )
    db.add(db_comment)
    db.commit()
    db.refresh(db_comment)
    return db_comment

@app.get("/api/comments")
async def get_comments(booking_id: str, context: str, db: Session = Depends(get_db)):
    comments = db.query(Comment).filter(
        Comment.booking_id == booking_id,
        Comment.context == context
    ).order_by(Comment.created_at.asc()).all()
    return comments

# Staff password management
# Simple in-memory password storage for testing (use database in production)
_staff_password = "staff123"  # Default staff password

@app.put("/api/admin/staff-password")
async def update_staff_password(password_data: dict):
    global _staff_password
    new_password = password_data.get("password")
    if not new_password or len(new_password) < 4:
        raise HTTPException(status_code=400, detail="Password must be at least 4 characters")
    _staff_password = new_password
    return {"message": "Staff password updated successfully"}

@app.post("/api/admin/verify-staff-password")
async def verify_staff_password(password_data: dict):
    password = password_data.get("password")
    if password == _staff_password:
        return {"valid": True}
    return {"valid": False}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)