from sqlalchemy import Column, Integer, String, Boolean, Text
from sqlalchemy.orm import relationship
from backend.app.database.base import Base

class Account(Base):
    __tablename__ = "accounts"

    id = Column(Integer, primary_key=True, index=True)
    account_code = Column(String(20), unique=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    type = Column(String(20), nullable=False) # ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)

    journal_lines = relationship("JournalLine", back_populates="account")
