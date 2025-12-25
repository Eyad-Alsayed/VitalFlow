from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List, Optional
import uvicorn

from database import get_db, engine
from simple_models import Booking, Base
from pydantic import BaseModel

# Create tables (will use existing table if it exists)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Medical Booking API", version="1.0.0")

# CORS for Flutter web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:8080", "*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models for API
class BookingCreate(BaseModel):
    mrn: Optional[str] = None
    patient_name: Optional[str] = None
    procedure: Optional[str] = None
    type_of_booking: str  # "OR" or "ICU"
    urgency: str
    status: str = "pending"
    outcome: Optional[str] = None
    consultant: Optional[str] = None
    consultant_phone: Optional[str] = None
    requesting_physician: Optional[str] = None

class BookingResponse(BaseModel):
    id: int
    mrn: Optional[str]
    patient_name: Optional[str]
    procedure: Optional[str]
    type_of_booking: str
    urgency: str
    status: str
    outcome: Optional[str]
    consultant: Optional[str]
    consultant_phone: Optional[str]
    requesting_physician: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

# API Endpoints
@app.get("/")
async def root():
    return {"message": "Medical Booking API is running!"}

@app.get("/api/bookings", response_model=List[BookingResponse])
async def get_all_bookings(db: Session = Depends(get_db)):
    """Get all bookings"""
    bookings = db.query(Booking).order_by(Booking.created_at.desc()).all()
    return bookings

@app.get("/api/bookings/or", response_model=List[BookingResponse])
async def get_or_bookings(db: Session = Depends(get_db)):
    """Get only OR bookings"""
    bookings = db.query(Booking).filter(Booking.type_of_booking == "OR").order_by(Booking.created_at.desc()).all()
    return bookings

@app.get("/api/bookings/icu", response_model=List[BookingResponse])
async def get_icu_bookings(db: Session = Depends(get_db)):
    """Get only ICU bookings"""
    bookings = db.query(Booking).filter(Booking.type_of_booking == "ICU").order_by(Booking.created_at.desc()).all()
    return bookings

@app.post("/api/bookings", response_model=BookingResponse)
async def create_booking(booking: BookingCreate, db: Session = Depends(get_db)):
    """Create a new booking"""
    db_booking = Booking(**booking.dict())
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)
    return db_booking

@app.get("/api/bookings/{booking_id}", response_model=BookingResponse)
async def get_booking(booking_id: int, db: Session = Depends(get_db)):
    """Get a specific booking by ID"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking

@app.put("/api/bookings/{booking_id}/status")
async def update_booking_status(booking_id: int, status_update: dict, db: Session = Depends(get_db)):
    """Update booking status"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Update status
    if "status" in status_update:
        booking.status = status_update["status"]
    if "outcome" in status_update:
        booking.outcome = status_update["outcome"]
    
    db.commit()
    return {"message": "Booking updated successfully"}

@app.delete("/api/bookings/{booking_id}")
async def delete_booking(booking_id: int, db: Session = Depends(get_db)):
    """Delete a booking"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    db.delete(booking)
    db.commit()
    return {"message": "Booking deleted successfully"}

# Test endpoints
@app.get("/api/test-connection")
async def test_connection(db: Session = Depends(get_db)):
    """Test database connection"""
    try:
        # Try to count bookings
        count = db.query(Booking).count()
        return {"status": "connected", "total_bookings": count}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)