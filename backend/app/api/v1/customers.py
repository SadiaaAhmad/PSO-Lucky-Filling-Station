from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from typing import List

from backend.app.database.session import get_db
from backend.app.schemas.customer import (
    CustomerCreate, CustomerResponse,
    CustomerVehicleCreate, CustomerVehicleResponse,
    CustomerBalanceResponse
)
from backend.app.services.customer_service import CustomerService

router = APIRouter(prefix="/customers", tags=["Customer Accounts"])

@router.post("/", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
def create_customer(payload: CustomerCreate, db: Session = Depends(get_db)):
    """Create a new customer credit account."""
    try:
        return CustomerService.create_customer(
            db,
            account_no=payload.account_no,
            name=payload.name,
            phone=payload.phone,
            credit_limit=payload.credit_limit,
            opening_balance=payload.opening_balance
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/{id}/vehicles", response_model=CustomerVehicleResponse, status_code=status.HTTP_201_CREATED)
def add_customer_vehicle(id: int, payload: CustomerVehicleCreate, db: Session = Depends(get_db)):
    """Register a vehicle to a customer account (1:N)."""
    try:
        return CustomerService.add_customer_vehicle(
            db,
            customer_id=id,
            vehicle_no=payload.vehicle_no,
            driver_name=payload.driver_name,
            notes=payload.notes
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.get("/{id}/balance", response_model=CustomerBalanceResponse)
def get_customer_balance(id: int, db: Session = Depends(get_db)):
    """Fetch dynamic customer credit balance and limit details."""
    try:
        return CustomerService.get_customer_balance(db, customer_id=id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

from backend.app.core.cache import api_cache

@router.get("/", response_model=List[CustomerResponse])
def list_customers(db: Session = Depends(get_db)):
    cache_key = "list_customers"
    cached = api_cache.get(cache_key)
    if cached is not None:
        return cached
    res = CustomerService.get_all_customers(db)
    api_cache.set(cache_key, res, ttl_seconds=120)
    return res

@router.get("/{id}", response_model=CustomerResponse)
def get_customer(id: int, db: Session = Depends(get_db)):
    try:
        return CustomerService.get_customer(db, id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

from backend.app.schemas.credit import CreditTransactionResponse

@router.get("/{id}/ledger", response_model=List[CreditTransactionResponse])
def get_customer_ledger(id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return CustomerService.get_customer_ledger(db, id, skip, limit)

@router.delete("/{id}")
@router.post("/{id}/delete")
def delete_customer(id: int, db: Session = Depends(get_db)):
    """Delete a customer account."""
    try:
        CustomerService.delete_customer(db, id)
        api_cache.clear()
        return {"detail": f"Customer {id} deleted successfully."}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
