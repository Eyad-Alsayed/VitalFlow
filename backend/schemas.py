from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from models import ORUrgency, ORStatus, ICUUrgency, ICUStatus

# OR Booking schemas
class ORBookingBase(BaseModel):
    mrn: str
    patient_name: Optional[str] = None
    patient_ward: Optional[str] = None
    procedure: str
    urgency: ORUrgency
    consultant: str
    consultant_phone: str
    requesting_physician: str
    requesting_physician_phone: str
    created_by_uid: str
    created_by_name: str
    created_by_role: str

class ORBookingCreate(ORBookingBase):
    pass

class ORBookingUpdate(BaseModel):
    status: Optional[ORStatus] = None

class ORBookingResponse(ORBookingBase):
    id: str
    status: ORStatus
    outcome: Optional[str] = None
    outcome_changed_at: Optional[datetime] = None
    created_at: datetime
    last_updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True

# ICU Request schemas
class ICURequestBase(BaseModel):
    mrn: str
    patient_name: Optional[str] = None
    patient_ward: Optional[str] = None
    indication: str
    urgency: ICUUrgency
    consultant: str
    consultant_phone: str
    requesting_physician: str
    requesting_physician_phone: str
    created_by_uid: str
    created_by_name: str
    created_by_role: str
    requested_date: Optional[datetime] = None

class ICURequestCreate(ICURequestBase):
    pass

class ICURequestUpdate(BaseModel):
    status: Optional[ICUStatus] = None

class ICURequestResponse(ICURequestBase):
    id: str
    status: ICUStatus
    unit: Optional[str] = None
    room: Optional[str] = None
    outcome: Optional[str] = None
    created_at: datetime
    last_updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True

# Comment schemas
class CommentBase(BaseModel):
    booking_id: str
    context: str
    message: str
    author_uid: str
    author_name: str
    author_role: str

class CommentCreate(CommentBase):
    pass

class CommentResponse(CommentBase):
    id: str
    created_at: datetime
    
    class Config:
        from_attributes = True