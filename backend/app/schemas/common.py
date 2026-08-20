from typing import Generic, TypeVar, List, Optional
from pydantic import BaseModel, ConfigDict

T = TypeVar("T")

class BaseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

class MessageResponse(BaseModel):
    message: str

class PaginatedResponse(BaseModel, Generic[T]):
    total: int
    items: List[T]
    skip: int
    limit: int

class ReversalRequest(BaseModel):
    reason: str = "User requested reversal"
