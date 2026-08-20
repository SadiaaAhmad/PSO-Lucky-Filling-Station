from decimal import Decimal
from sqlalchemy.orm import Session
from backend.app.models.journal import JournalEntry, JournalLine
from backend.app.models.accounts import Account

class UnbalancedJournalError(Exception):
    """Raised when a journal entry's total debits do not equal total credits."""
    pass

class AccountingEngine:
    def __init__(self, db: Session):
        self.db = db
        self._accounts_cache = {}

    def get_account_by_code(self, code: str) -> Account:
        if code not in self._accounts_cache:
            acc = self.db.query(Account).filter(Account.account_code == code).first()
            if not acc:
                raise ValueError(f"Account code '{code}' not found in Chart of Accounts.")
            self._accounts_cache[code] = acc
        return self._accounts_cache[code]

    def create_balanced_journal(
        self,
        entry_date,
        description: str,
        line_specs: list[dict],
        daily_log_id: int = None,
        reference: str = None
    ) -> JournalEntry:
        """
        Creates a journal entry and enforces the invariant: SUM(Debits) == SUM(Credits).
        Rolls back and raises UnbalancedJournalError if debits != credits.
        """
        total_debit = Decimal("0.00")
        total_credit = Decimal("0.00")

        lines_to_add = []
        for spec in line_specs:
            acc_code = spec["account_code"]
            account = self.get_account_by_code(acc_code)
            debit = Decimal(str(spec.get("debit", 0))).quantize(Decimal("0.01"))
            credit = Decimal(str(spec.get("credit", 0))).quantize(Decimal("0.01"))

            total_debit += debit
            total_credit += credit

            line = JournalLine(
                account_id=account.id,
                debit=debit,
                credit=credit,
                customer_id=spec.get("customer_id"),
                vehicle_id=spec.get("vehicle_id"),
                description=spec.get("description", description)
            )
            lines_to_add.append(line)

        # STRICT INVARIANT ASSERTION
        if total_debit != total_credit:
            self.db.rollback()
            raise UnbalancedJournalError(
                f"Journal Entry Unbalanced for '{description}'! Total Debit: {total_debit}, Total Credit: {total_credit}"
            )

        journal_entry = JournalEntry(
            entry_date=entry_date,
            daily_log_id=daily_log_id,
            reference=reference,
            description=description,
            lines=lines_to_add
        )

        self.db.add(journal_entry)
        self.db.flush()
        return journal_entry


    def reverse_journal_entry(self, original_entry_id: int, reason: str):
        import logging
        from datetime import datetime
        from backend.app.models.journal import JournalEntry, JournalLine
        logger = logging.getLogger(__name__)
        logger.info(f"[LEDGER] Reversing journal entry {original_entry_id}")
        
        orig = self.db.query(JournalEntry).filter(JournalEntry.id == original_entry_id).first()
        if not orig: raise ValueError("Not found")
        
        new_entry = JournalEntry(
            entry_date=datetime.utcnow().date(),
            daily_log_id=orig.daily_log_id,
            reference=f"REV-{orig.reference}" if orig.reference else "REV",
            description=f"REVERSAL: {orig.description}"
        )
        self.db.add(new_entry)
        self.db.flush()
        
        for line in orig.lines:
            new_line = JournalLine(
                journal_entry_id=new_entry.id,
                account_id=line.account_id,
                debit=line.credit,
                credit=line.debit,
                customer_id=line.customer_id,
                vehicle_id=line.vehicle_id,
                description=f"REVERSAL: {line.description}"
            )
            self.db.add(new_line)
            
        orig.is_reversed = True
        orig.reversed_at = datetime.utcnow()
        orig.reversal_reason = reason
        self.db.commit()
        self.db.refresh(new_entry)
        return new_entry

