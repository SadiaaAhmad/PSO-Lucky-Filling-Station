from typing import Optional
from decimal import Decimal
from datetime import datetime
from backend.app.schemas.common import BaseSchema

class ActivityItem(BaseSchema):
    id: int
    activity_type: str
    title: str
    subtitle: str
    amount: Optional[Decimal] = None
    amount_sign: str
    timestamp: datetime
    entity_type: str
    entity_id: int
    daily_log_id: Optional[int] = None
