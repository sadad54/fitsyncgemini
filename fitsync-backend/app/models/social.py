from sqlalchemy import Column, Integer, String, DateTime, Boolean, Float, Text, JSON, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class ChallengeStatusEnum(enum.Enum):
    ACTIVE = "active"
    COMPLETED = "completed"
    EXPIRED = "expired"
    CANCELLED = "cancelled"

class ChallengeTypeEnum(enum.Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    SEASONAL = "seasonal"
    CUSTOM = "custom"

class FashionChallenge(Base):
    __tablename__ = "fashion_challenges"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    challenge_type = Column(Enum(ChallengeTypeEnum), nullable=False)
    theme = Column(String(100))  # "Summer Vibes", "Monochrome", etc.
    requirements = Column(JSON)  # Specific requirements for the challenge
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    status = Column(Enum(ChallengeStatusEnum), default=ChallengeStatusEnum.ACTIVE)
    
    # Participation
    max_participants = Column(Integer)
    current_participants = Column(Integer, default=0)
    prize_description = Column(Text)
    
    # Social features
    hashtag = Column(String(100))
    is_featured = Column(Boolean, default=False)
    created_by = Column(Integer, ForeignKey("users.id"))
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    creator = relationship("User")
    submissions = relationship("ChallengeSubmission", back_populates="challenge")

class ChallengeSubmission(Base):
    __tablename__ = "challenge_submissions"
    
    id = Column(Integer, primary_key=True, index=True)
    challenge_id = Column(Integer, ForeignKey("fashion_challenges.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    outfit_id = Column(Integer, ForeignKey("outfit_combinations.id"), nullable=False)
    
    # Submission details
    title = Column(String(200))
    description = Column(Text)
    image_url = Column(String(500))
    tags = Column(JSON)  # Additional tags for the submission
    
    # Voting and scoring
    votes_count = Column(Integer, default=0)
    score = Column(Float, default=0.0)
    is_winner = Column(Boolean, default=False)
    
    # Status
    is_approved = Column(Boolean, default=True)
    is_featured = Column(Boolean, default=False)
    
    # Metadata
    submitted_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    challenge = relationship("FashionChallenge", back_populates="submissions")
    user = relationship("User")
    outfit = relationship("OutfitCombination")
    votes = relationship("ChallengeVote", back_populates="submission")

class ChallengeVote(Base):
    __tablename__ = "challenge_votes"
    
    id = Column(Integer, primary_key=True, index=True)
    submission_id = Column(Integer, ForeignKey("challenge_submissions.id"), nullable=False)
    voter_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    vote_score = Column(Float)  # 1-5 scale
    comment = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    submission = relationship("ChallengeSubmission", back_populates="votes")
    voter = relationship("User")

class StylePost(Base):
    __tablename__ = "style_posts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    outfit_id = Column(Integer, ForeignKey("outfit_combinations.id"), nullable=False)
    
    # Post content
    title = Column(String(200))
    caption = Column(Text)
    hashtags = Column(JSON)  # List of hashtags
    location = Column(String(200))
    latitude = Column(Float)
    longitude = Column(Float)
    
    # Engagement metrics
    likes_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)
    shares_count = Column(Integer, default=0)
    views_count = Column(Integer, default=0)
    
    # Visibility
    is_public = Column(Boolean, default=True)
    is_featured = Column(Boolean, default=False)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User")
    outfit = relationship("OutfitCombination")
    likes = relationship("PostLike", back_populates="post")
    comments = relationship("PostComment", back_populates="post")

class PostLike(Base):
    __tablename__ = "post_likes"
    
    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("style_posts.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    post = relationship("StylePost", back_populates="likes")
    user = relationship("User")

class PostComment(Base):
    __tablename__ = "post_comments"
    
    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("style_posts.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    parent_comment_id = Column(Integer, ForeignKey("post_comments.id"))  # For replies
    
    # Comment content
    content = Column(Text, nullable=False)
    likes_count = Column(Integer, default=0)
    
    # Status
    is_edited = Column(Boolean, default=False)
    is_deleted = Column(Boolean, default=False)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    post = relationship("StylePost", back_populates="comments")
    user = relationship("User")
    parent_comment = relationship("PostComment", remote_side=[id])
    replies = relationship("PostComment")

class StyleInspiration(Base):
    __tablename__ = "style_inspirations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(200))
    description = Column(Text)
    
    # Inspiration content
    image_url = Column(String(500))
    source_url = Column(String(500))  # Original source if applicable
    tags = Column(JSON)  # Style tags, colors, etc.
    
    # Style attributes
    style_archetype = Column(String(100))
    color_palette = Column(JSON)
    occasion = Column(String(100))
    season = Column(String(100))
    
    # Social features
    is_public = Column(Boolean, default=True)
    likes_count = Column(Integer, default=0)
    saves_count = Column(Integer, default=0)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User")

class StyleEvent(Base):
    __tablename__ = "style_events"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    
    # Event details
    event_type = Column(String(100))  # "fashion_show", "meetup", "workshop"
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime)
    location = Column(String(200))
    latitude = Column(Float)
    longitude = Column(Float)
    
    # Event management
    organizer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    max_attendees = Column(Integer)
    current_attendees = Column(Integer, default=0)
    is_public = Column(Boolean, default=True)
    
    # Event features
    dress_code = Column(String(200))
    tags = Column(JSON)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    organizer = relationship("User")
    attendees = relationship("EventAttendance", back_populates="event")

class EventAttendance(Base):
    __tablename__ = "event_attendances"
    
    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("style_events.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String(50))  # "confirmed", "maybe", "declined"
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    event = relationship("StyleEvent", back_populates="attendees")
    user = relationship("User")
