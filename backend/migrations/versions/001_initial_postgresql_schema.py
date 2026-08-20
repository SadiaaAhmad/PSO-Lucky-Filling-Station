"""Initial PostgreSQL Schema Migration (15 Tables)

Revision ID: 001_initial_postgresql_schema
Revises: 
Create Date: 2026-08-18

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '001_initial_postgresql_schema'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    # 1. products
    op.create_table(
        'products',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('code', sa.String(length=20), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('unit', sa.String(length=20), nullable=False, server_default='Liters'),
        sa.Column('default_margin_rate', sa.Numeric(precision=10, scale=4), nullable=False, server_default='6.5000'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('code')
    )

    # 2. tanks
    op.create_table(
        'tanks',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('tank_name', sa.String(length=50), nullable=False),
        sa.Column('product_id', sa.Integer(), nullable=False),
        sa.Column('capacity_liters', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # 3. dispensing_units
    op.create_table(
        'dispensing_units',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('unit_number', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=50), nullable=False),
        sa.Column('product_id', sa.Integer(), nullable=False),
        sa.Column('tank_id', sa.Integer(), nullable=False),
        sa.Column('is_active', sa.Boolean(), server_default='true'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.ForeignKeyConstraint(['tank_id'], ['tanks.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('unit_number')
    )

    # 4. customers
    op.create_table(
        'customers',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('account_no', sa.String(length=30), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('phone', sa.String(length=20), nullable=True),
        sa.Column('credit_limit', sa.Numeric(precision=12, scale=2), server_default='0.00'),
        sa.Column('opening_balance', sa.Numeric(precision=12, scale=2), server_default='0.00'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('account_no')
    )

    # 5. customer_vehicles
    op.create_table(
        'customer_vehicles',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('customer_id', sa.Integer(), nullable=False),
        sa.Column('vehicle_no', sa.String(length=50), nullable=False),
        sa.Column('driver_name', sa.String(length=100), nullable=True),
        sa.Column('notes', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['customer_id'], ['customers.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('customer_id', 'vehicle_no', name='unique_customer_vehicle')
    )

    # 6. daily_logs
    op.create_table(
        'daily_logs',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('log_date', sa.Date(), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='DRAFT'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('log_date')
    )

    # 7. nozzle_readings
    op.create_table(
        'nozzle_readings',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('daily_log_id', sa.Integer(), nullable=False),
        sa.Column('unit_id', sa.Integer(), nullable=False),
        sa.Column('opening_reading', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('closing_reading', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.CheckConstraint('closing_reading >= opening_reading', name='chk_nozzle_reading'),
        sa.ForeignKeyConstraint(['daily_log_id'], ['daily_logs.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['unit_id'], ['dispensing_units.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # 8. fuel_purchases
    op.create_table(
        'fuel_purchases',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('daily_log_id', sa.Integer(), nullable=False),
        sa.Column('product_id', sa.Integer(), nullable=False),
        sa.Column('tank_id', sa.Integer(), nullable=False),
        sa.Column('invoice_no', sa.String(length=50), nullable=True),
        sa.Column('purchase_liters', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('purchase_rate', sa.Numeric(precision=10, scale=4), nullable=False),
        sa.Column('sale_rate', sa.Numeric(precision=10, scale=4), nullable=False),
        sa.Column('rate_diff_per_ltr', sa.Numeric(precision=10, scale=4), server_default='0.0000'),
        sa.ForeignKeyConstraint(['daily_log_id'], ['daily_logs.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.ForeignKeyConstraint(['tank_id'], ['tanks.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # 9. daily_tank_stocks (with corrected testing loss stock formula)
    op.create_table(
        'daily_tank_stocks',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('daily_log_id', sa.Integer(), nullable=False),
        sa.Column('tank_id', sa.Integer(), nullable=False),
        sa.Column('product_id', sa.Integer(), nullable=False),
        sa.Column('opening_dip_liters', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('stock_in_purchase_liters', sa.Numeric(precision=12, scale=2), server_default='0.00'),
        sa.Column('testing_loss_liters', sa.Numeric(precision=12, scale=2), server_default='0.00'),
        sa.Column('net_sales_liters', sa.Numeric(precision=12, scale=2), server_default='0.00'),
        sa.Column('actual_dip_liters', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('purchase_rate', sa.Numeric(precision=10, scale=4), nullable=False),
        sa.ForeignKeyConstraint(['daily_log_id'], ['daily_logs.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.ForeignKeyConstraint(['tank_id'], ['tanks.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('daily_log_id', 'tank_id', name='unique_daily_tank_stock')
    )

    # 10. credit_transactions
    op.create_table(
        'credit_transactions',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('daily_log_id', sa.Integer(), nullable=False),
        sa.Column('customer_id', sa.Integer(), nullable=False),
        sa.Column('vehicle_id', sa.Integer(), nullable=True),
        sa.Column('product_id', sa.Integer(), nullable=True),
        sa.Column('transaction_type', sa.String(length=20), nullable=False),
        sa.Column('liters', sa.Numeric(precision=12, scale=2), server_default='0.00'),
        sa.Column('rate_per_ltr', sa.Numeric(precision=10, scale=4), server_default='0.0000'),
        sa.Column('amount', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('reference', sa.String(length=100), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['customer_id'], ['customers.id'], ),
        sa.ForeignKeyConstraint(['daily_log_id'], ['daily_logs.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.ForeignKeyConstraint(['vehicle_id'], ['customer_vehicles.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # 11. card_transactions
    op.create_table(
        'card_transactions',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('daily_log_id', sa.Integer(), nullable=False),
        sa.Column('card_type', sa.String(length=20), nullable=False),
        sa.Column('liters', sa.Numeric(precision=12, scale=2), server_default='0.00'),
        sa.Column('amount', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('bank_charges', sa.Numeric(precision=12, scale=2), server_default='0.00'),
        sa.ForeignKeyConstraint(['daily_log_id'], ['daily_logs.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # 12. expense_categories
    op.create_table(
        'expense_categories',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('type', sa.String(length=50), nullable=False),
        sa.Column('is_active', sa.Boolean(), server_default='true'),
        sa.PrimaryKeyConstraint('id')
    )

    # 13. accounts (Chart of Accounts)
    op.create_table(
        'accounts',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('account_code', sa.String(length=20), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('type', sa.String(length=20), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('is_active', sa.Boolean(), server_default='true'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('account_code')
    )

    # 14. journal_entries
    op.create_table(
        'journal_entries',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('entry_date', sa.Date(), nullable=False),
        sa.Column('daily_log_id', sa.Integer(), nullable=True),
        sa.Column('reference', sa.String(length=100), nullable=True),
        sa.Column('description', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['daily_log_id'], ['daily_logs.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )

    # 15. journal_lines
    op.create_table(
        'journal_lines',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('journal_entry_id', sa.Integer(), nullable=False),
        sa.Column('account_id', sa.Integer(), nullable=False),
        sa.Column('debit', sa.Numeric(precision=12, scale=2), server_default='0.00'),
        sa.Column('credit', sa.Numeric(precision=12, scale=2), server_default='0.00'),
        sa.Column('customer_id', sa.Integer(), nullable=True),
        sa.Column('vehicle_id', sa.Integer(), nullable=True),
        sa.Column('description', sa.String(length=255), nullable=True),
        sa.CheckConstraint('debit >= 0 AND credit >= 0 AND (debit > 0 OR credit > 0)', name='chk_journal_line_debit_credit'),
        sa.ForeignKeyConstraint(['account_id'], ['accounts.id'], ),
        sa.ForeignKeyConstraint(['customer_id'], ['customers.id'], ),
        sa.ForeignKeyConstraint(['journal_entry_id'], ['journal_entries.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['vehicle_id'], ['customer_vehicles.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

def downgrade() -> None:
    op.drop_table('journal_lines')
    op.drop_table('journal_entries')
    op.drop_table('accounts')
    op.drop_table('expense_categories')
    op.drop_table('card_transactions')
    op.drop_table('credit_transactions')
    op.drop_table('daily_tank_stocks')
    op.drop_table('fuel_purchases')
    op.drop_table('nozzle_readings')
    op.drop_table('daily_logs')
    op.drop_table('customer_vehicles')
    op.drop_table('customers')
    op.drop_table('dispensing_units')
    op.drop_table('tanks')
    op.drop_table('products')
