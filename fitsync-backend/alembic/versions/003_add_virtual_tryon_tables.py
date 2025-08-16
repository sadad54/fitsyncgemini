"""Add virtual try-on tables

Revision ID: 003
Revises: 002
Create Date: 2025-01-20 15:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import sqlite

# revision identifiers
revision = '003'
down_revision = '002'
branch_labels = None
depends_on = None


def upgrade():
    # Create tryon_sessions table
    op.create_table('tryon_sessions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('session_name', sa.String(length=200), nullable=True),
        sa.Column('view_mode', sa.String(length=20), nullable=True),
        sa.Column('device_info', sa.JSON(), nullable=True),
        sa.Column('status', sa.String(length=20), nullable=True),
        sa.Column('processing_progress', sa.Float(), nullable=True),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('result_image_url', sa.String(length=500), nullable=True),
        sa.Column('confidence_score', sa.Float(), nullable=True),
        sa.Column('processing_time_ms', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_tryon_sessions_id'), 'tryon_sessions', ['id'], unique=False)

    # Create tryon_outfit_attempts table
    op.create_table('tryon_outfit_attempts',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('session_id', sa.String(), nullable=False),
        sa.Column('outfit_name', sa.String(length=200), nullable=False),
        sa.Column('occasion', sa.String(length=100), nullable=True),
        sa.Column('clothing_items', sa.JSON(), nullable=True),
        sa.Column('confidence_score', sa.Float(), nullable=True),
        sa.Column('fit_analysis', sa.JSON(), nullable=True),
        sa.Column('color_analysis', sa.JSON(), nullable=True),
        sa.Column('style_score', sa.Float(), nullable=True),
        sa.Column('user_rating', sa.Integer(), nullable=True),
        sa.Column('is_favorite', sa.Boolean(), nullable=True),
        sa.Column('is_shared', sa.Boolean(), nullable=True),
        sa.Column('processing_time_ms', sa.Integer(), nullable=True),
        sa.Column('result_image_url', sa.String(length=500), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['session_id'], ['tryon_sessions.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_tryon_outfit_attempts_id'), 'tryon_outfit_attempts', ['id'], unique=False)

    # Create tryon_features table
    op.create_table('tryon_features',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('description', sa.String(length=500), nullable=False),
        sa.Column('is_premium', sa.Boolean(), nullable=True),
        sa.Column('processing_cost', sa.Float(), nullable=True),
        sa.Column('accuracy_improvement', sa.Float(), nullable=True),
        sa.Column('is_available', sa.Boolean(), nullable=True),
        sa.Column('requires_gpu', sa.Boolean(), nullable=True),
        sa.Column('min_device_capability', sa.String(length=50), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_tryon_features_id'), 'tryon_features', ['id'], unique=False)

    # Create user_tryon_preferences table
    op.create_table('user_tryon_preferences',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('default_view_mode', sa.String(length=20), nullable=True),
        sa.Column('auto_save_results', sa.Boolean(), nullable=True),
        sa.Column('share_anonymously', sa.Boolean(), nullable=True),
        sa.Column('enabled_features', sa.JSON(), nullable=True),
        sa.Column('processing_quality', sa.String(length=20), nullable=True),
        sa.Column('max_processing_time', sa.Integer(), nullable=True),
        sa.Column('store_images', sa.Boolean(), nullable=True),
        sa.Column('allow_analytics', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id')
    )
    op.create_index(op.f('ix_user_tryon_preferences_id'), 'user_tryon_preferences', ['id'], unique=False)

    # Create tryon_analytics table
    op.create_table('tryon_analytics',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('session_id', sa.String(), nullable=False),
        sa.Column('total_outfits_tried', sa.Integer(), nullable=True),
        sa.Column('session_duration_seconds', sa.Integer(), nullable=True),
        sa.Column('user_interactions', sa.JSON(), nullable=True),
        sa.Column('average_processing_time', sa.Float(), nullable=True),
        sa.Column('success_rate', sa.Float(), nullable=True),
        sa.Column('error_count', sa.Integer(), nullable=True),
        sa.Column('session_rating', sa.Integer(), nullable=True),
        sa.Column('completion_rate', sa.Float(), nullable=True),
        sa.Column('device_performance', sa.JSON(), nullable=True),
        sa.Column('network_stats', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['session_id'], ['tryon_sessions.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_tryon_analytics_id'), 'tryon_analytics', ['id'], unique=False)

    # Insert default try-on features
    op.execute("""
        INSERT INTO tryon_features (id, name, description, is_premium, processing_cost, accuracy_improvement, is_available, requires_gpu) VALUES
        ('lighting', 'Smart Lighting', 'Adjusts colors based on environment', 0, 0.1, 0.15, 1, 0),
        ('fit', 'Fit Analysis', 'Real-time fit assessment', 0, 0.3, 0.25, 1, 1),
        ('movement', 'Movement Tracking', 'See how clothes move with you', 1, 0.5, 0.35, 1, 1),
        ('color_match', 'Color Matching', 'Advanced color analysis and matching', 0, 0.2, 0.20, 1, 0),
        ('size_recommendation', 'Size Recommendation', 'AI-powered size suggestions', 1, 0.4, 0.30, 1, 1)
    """)


def downgrade():
    # Drop tables in reverse order
    op.drop_index(op.f('ix_tryon_analytics_id'), table_name='tryon_analytics')
    op.drop_table('tryon_analytics')
    
    op.drop_index(op.f('ix_user_tryon_preferences_id'), table_name='user_tryon_preferences')
    op.drop_table('user_tryon_preferences')
    
    op.drop_index(op.f('ix_tryon_features_id'), table_name='tryon_features')
    op.drop_table('tryon_features')
    
    op.drop_index(op.f('ix_tryon_outfit_attempts_id'), table_name='tryon_outfit_attempts')
    op.drop_table('tryon_outfit_attempts')
    
    op.drop_index(op.f('ix_tryon_sessions_id'), table_name='tryon_sessions')
    op.drop_table('tryon_sessions')
