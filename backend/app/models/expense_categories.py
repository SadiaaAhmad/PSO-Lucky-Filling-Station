from sqlalchemy import Column, Integer, String, Boolean
from backend.app.database.base import Base

class ExpenseCategory(Base):
    __tablename__ = "expense_categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    type = Column(String(50), nullable=False) # OPERATING_EXPENSE, PERSONAL_DRAW, CHARITY, DISCOUNT
    is_active = Column(Boolean, default=True)
