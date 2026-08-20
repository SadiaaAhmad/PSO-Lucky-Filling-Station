from datetime import date
from decimal import Decimal
from typing import Dict, Any
from sqlalchemy import extract
from sqlalchemy.orm import Session
from backend.app.models.daily_logs import DailyLog
from backend.app.models.nozzle_readings import NozzleReading
from backend.app.models.daily_tank_stocks import DailyTankStock
from backend.app.models.credit_transactions import CreditTransaction
from backend.app.models.card_transactions import CardTransaction
from backend.app.models.accounts import Account
from backend.app.models.journal import JournalEntry, JournalLine

import logging
logger = logging.getLogger(__name__)

class ReportService:
    @staticmethod
    def generate_monthly_profit_loss(db: Session, year: int, month: int) -> Dict[str, Any]:
        """
        Dynamically calculate Profit & Loss Statement for any month from double-entry journal lines:
        - Revenue Accounts (4000 series)
        - Expense Accounts (5000 series)
        - Net Profit = Total Revenue - Total Expenses
        """
        revenue_accounts = db.query(Account).filter(Account.type == "REVENUE").all()
        rev_ids = [a.id for a in revenue_accounts]

        revenue_lines = (
            db.query(JournalLine)
            .join(JournalEntry)
            .filter(
                extract('year', JournalEntry.entry_date) == year,
                extract('month', JournalEntry.entry_date) == month,
                JournalLine.account_id.in_(rev_ids)
            )
            .all()
        )

        revenue_breakdown = {}
        for line in revenue_lines:
            acc_name = line.account.name
            amount = line.credit - line.debit
            revenue_breakdown[acc_name] = revenue_breakdown.get(acc_name, Decimal("0.00")) + amount

        total_income = sum(revenue_breakdown.values(), Decimal("0.00"))

        expense_accounts = db.query(Account).filter(Account.type == "EXPENSE").all()
        exp_ids = [a.id for a in expense_accounts]

        expense_lines = (
            db.query(JournalLine)
            .join(JournalEntry)
            .filter(
                extract('year', JournalEntry.entry_date) == year,
                extract('month', JournalEntry.entry_date) == month,
                JournalLine.account_id.in_(exp_ids)
            )
            .all()
        )

        expense_breakdown = {}
        for line in expense_lines:
            acc_name = line.account.name
            amount = line.debit - line.credit
            expense_breakdown[acc_name] = expense_breakdown.get(acc_name, Decimal("0.00")) + amount

        total_expenses = sum(expense_breakdown.values(), Decimal("0.00"))
        net_profit = total_income - total_expenses

        return {
            "year": year,
            "month": month,
            "revenue_breakdown": {k: float(v) for k, v in revenue_breakdown.items()},
            "total_income": float(total_income),
            "expense_breakdown": {k: float(v) for k, v in expense_breakdown.items()},
            "total_expenses": float(total_expenses),
            "net_profit": float(net_profit),
        }

    @staticmethod
    def generate_daily_summary(db: Session, log_date: date) -> Dict[str, Any]:
        """
        Generate operational and financial summary for a single daily log date.
        """
        daily_log = db.query(DailyLog).filter(DailyLog.log_date == log_date).first()
        if not daily_log:
            raise ValueError(f"No daily log found for date {log_date}.")

        nozzle_readings = db.query(NozzleReading).filter(NozzleReading.daily_log_id == daily_log.id).all()
        tank_stocks = db.query(DailyTankStock).filter(DailyTankStock.daily_log_id == daily_log.id).all()
        credit_sales = db.query(CreditTransaction).filter(CreditTransaction.daily_log_id == daily_log.id, CreditTransaction.transaction_type == "CREDIT_SALE").all()
        credit_recoveries = db.query(CreditTransaction).filter(CreditTransaction.daily_log_id == daily_log.id, CreditTransaction.transaction_type == "CREDIT_RECOVERY").all()
        card_sales = db.query(CardTransaction).filter(CardTransaction.daily_log_id == daily_log.id).all()

        total_gross_liters = sum((n.gross_sale_liters for n in nozzle_readings), Decimal("0.00"))
        total_credit_sales_pkr = sum((c.amount for c in credit_sales), Decimal("0.00"))
        total_recoveries_pkr = sum((r.amount for r in credit_recoveries), Decimal("0.00"))
        total_card_sales_pkr = sum((cd.amount for cd in card_sales), Decimal("0.00"))

        return {
            "log_date": str(log_date),
            "status": daily_log.status,
            "total_nozzles_recorded": len(nozzle_readings),
            "total_gross_liters_dispensed": float(total_gross_liters),
            "tank_stocks_recorded": len(tank_stocks),
            "total_credit_sales_pkr": float(total_credit_sales_pkr),
            "total_credit_recoveries_pkr": float(total_recoveries_pkr),
            "total_card_sales_pkr": float(total_card_sales_pkr),
        }

    @staticmethod
    def get_latest_monthly_profit_loss(db: Session) -> Dict[str, Any]:
        """Find the most recent month with general ledger entries and return its P&L statement."""
        latest_entry = db.query(JournalEntry).order_by(JournalEntry.entry_date.desc()).first()
        if latest_entry:
            return ReportService.generate_monthly_profit_loss(db, latest_entry.entry_date.year, latest_entry.entry_date.month)
        return ReportService.generate_monthly_profit_loss(db, 2026, 7)

    @staticmethod
    def get_latest_daily_summary(db: Session) -> Dict[str, Any]:
        """Find the most recent daily log and return its operational summary."""
        latest_log = db.query(DailyLog).order_by(DailyLog.log_date.desc()).first()
        if latest_log:
            return ReportService.generate_daily_summary(db, latest_log.log_date)
        raise ValueError("No daily logs found.")
