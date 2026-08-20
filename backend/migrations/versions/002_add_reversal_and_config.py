"""add reversal and config

Revision ID: 002_add_reversal_and_config
Revises: 001_initial_postgresql_schema
Create Date: 2026-08-19 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '002_add_reversal_and_config'
down_revision = '001_initial_postgresql_schema'
branch_labels = None
depends_on = None

def upgrade() -> None:
    # Add reversal columns to existing tables
    tables = [
        'nozzle_readings',
        'fuel_purchases',
        'daily_tank_stocks',
        'credit_transactions',
        'card_transactions',
        'journal_entries'
    ]
    
    for table in tables:
        op.add_column(table, sa.Column('is_reversed', sa.Boolean(), server_default='false', nullable=False))
        op.add_column(table, sa.Column('reversed_at', sa.DateTime(timezone=True), nullable=True))
        op.add_column(table, sa.Column('reversal_reason', sa.String(length=255), nullable=True))

    # Create station_configs table
    op.create_table('station_configs',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('station_name', sa.String(length=100), nullable=True),
        sa.Column('station_id', sa.String(length=50), nullable=True),
        sa.Column('address', sa.Text(), nullable=True),
        sa.Column('license_no', sa.String(length=50), nullable=True),
        sa.Column('contact_phone', sa.String(length=20), nullable=True),
        sa.Column('hsd_current_rate', sa.Numeric(precision=10, scale=4), nullable=True),
        sa.Column('pmg_current_rate', sa.Numeric(precision=10, scale=4), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )

def downgrade() -> None:
    op.drop_table('station_configs')
    
    tables = [
        'nozzle_readings',
        'fuel_purchases',
        'daily_tank_stocks',
        'credit_transactions',
        'card_transactions',
        'journal_entries'
    ]
    
    for table in tables:
        op.drop_column(table, 'reversal_reason')
        op.drop_column(table, 'reversed_at')
        op.drop_column(table, 'is_reversed')
