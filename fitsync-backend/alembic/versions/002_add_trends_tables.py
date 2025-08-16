"""Add trends and social tables

Revision ID: 002
Revises: 001
Create Date: 2025-01-20 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import sqlite

# revision identifiers
revision = '002'
down_revision = '001'  # Replace with your latest revision
branch_labels = None
depends_on = None


def upgrade():
    # Create fashion_trends table
    op.create_table('fashion_trends',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('trend_name', sa.String(length=200), nullable=False),
        sa.Column('trend_description', sa.Text(), nullable=True),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('popularity_score', sa.Float(), nullable=True),
        sa.Column('growth_rate', sa.Float(), nullable=True),
        sa.Column('direction', sa.String(length=10), nullable=True),
        sa.Column('engagement', sa.Integer(), nullable=True),
        sa.Column('posts_count', sa.Integer(), nullable=True),
        sa.Column('social_mentions', sa.Integer(), nullable=True),
        sa.Column('hashtag_count', sa.Integer(), nullable=True),
        sa.Column('tags', sa.JSON(), nullable=True),
        sa.Column('image_url', sa.String(length=500), nullable=True),
        sa.Column('confidence_level', sa.Float(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_fashion_trends_id'), 'fashion_trends', ['id'], unique=False)
    op.create_index(op.f('ix_fashion_trends_trend_name'), 'fashion_trends', ['trend_name'], unique=False)

    # Create style_influencers table
    op.create_table('style_influencers',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('handle', sa.String(length=100), nullable=False),
        sa.Column('bio', sa.Text(), nullable=True),
        sa.Column('profile_image_url', sa.String(length=500), nullable=True),
        sa.Column('followers_count', sa.Integer(), nullable=True),
        sa.Column('engagement_rate', sa.Float(), nullable=True),
        sa.Column('influence_score', sa.Float(), nullable=True),
        sa.Column('trend_setter_type', sa.String(length=100), nullable=True),
        sa.Column('recent_trend', sa.String(length=200), nullable=True),
        sa.Column('location', sa.String(length=200), nullable=True),
        sa.Column('scope', sa.String(length=20), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('handle')
    )
    op.create_index(op.f('ix_style_influencers_id'), 'style_influencers', ['id'], unique=False)

    # Create explore_content table
    op.create_table('explore_content',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('content_type', sa.String(length=50), nullable=True),
        sa.Column('author_id', sa.Integer(), nullable=True),
        sa.Column('author_name', sa.String(length=100), nullable=False),
        sa.Column('author_avatar_url', sa.String(length=500), nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('image_url', sa.String(length=500), nullable=False),
        sa.Column('tags', sa.JSON(), nullable=True),
        sa.Column('likes_count', sa.Integer(), nullable=True),
        sa.Column('views_count', sa.Integer(), nullable=True),
        sa.Column('shares_count', sa.Integer(), nullable=True),
        sa.Column('comments_count', sa.Integer(), nullable=True),
        sa.Column('category', sa.String(length=50), nullable=True),
        sa.Column('style_archetype', sa.String(length=50), nullable=True),
        sa.Column('is_trending', sa.Boolean(), nullable=True),
        sa.Column('trending_score', sa.Float(), nullable=True),
        sa.Column('is_public', sa.Boolean(), nullable=True),
        sa.Column('is_featured', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['author_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_explore_content_id'), 'explore_content', ['id'], unique=False)

    # Create nearby_locations table
    op.create_table('nearby_locations',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('location_type', sa.String(length=20), nullable=False),
        sa.Column('name', sa.String(length=200), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('image_url', sa.String(length=500), nullable=True),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('address', sa.String(length=500), nullable=True),
        sa.Column('city', sa.String(length=100), nullable=True),
        sa.Column('country', sa.String(length=100), nullable=True),
        sa.Column('location_metadata', sa.JSON(), nullable=True),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('is_public', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_nearby_locations_id'), 'nearby_locations', ['id'], unique=False)
    op.create_index(op.f('ix_nearby_locations_latitude'), 'nearby_locations', ['latitude'], unique=False)
    op.create_index(op.f('ix_nearby_locations_longitude'), 'nearby_locations', ['longitude'], unique=False)

    # Create trend_insights table
    op.create_table('trend_insights',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('trending_items', sa.JSON(), nullable=True),
        sa.Column('declining_items', sa.JSON(), nullable=True),
        sa.Column('scope', sa.String(length=20), nullable=True),
        sa.Column('timeframe', sa.String(length=20), nullable=True),
        sa.Column('confidence_score', sa.Float(), nullable=True),
        sa.Column('data_points', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('valid_until', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_trend_insights_id'), 'trend_insights', ['id'], unique=False)


def downgrade():
    # Drop tables in reverse order
    op.drop_index(op.f('ix_trend_insights_id'), table_name='trend_insights')
    op.drop_table('trend_insights')
    
    op.drop_index(op.f('ix_nearby_locations_longitude'), table_name='nearby_locations')
    op.drop_index(op.f('ix_nearby_locations_latitude'), table_name='nearby_locations')
    op.drop_index(op.f('ix_nearby_locations_id'), table_name='nearby_locations')
    op.drop_table('nearby_locations')
    
    op.drop_index(op.f('ix_explore_content_id'), table_name='explore_content')
    op.drop_table('explore_content')
    
    op.drop_index(op.f('ix_style_influencers_id'), table_name='style_influencers')
    op.drop_table('style_influencers')
    
    op.drop_index(op.f('ix_fashion_trends_trend_name'), table_name='fashion_trends')
    op.drop_index(op.f('ix_fashion_trends_id'), table_name='fashion_trends')
    op.drop_table('fashion_trends')
