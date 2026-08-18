-- ==========================================
-- FITSYNC SUPABASE DATABASE ENHANCEMENTS
-- ==========================================

-- 1. Add missing columns to existing tables
-- ==========================================

-- Add missing columns to users table for better profile management
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS email text UNIQUE,
ADD COLUMN IF NOT EXISTS phone text,
ADD COLUMN IF NOT EXISTS date_of_birth date,
ADD COLUMN IF NOT EXISTS gender text CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
ADD COLUMN IF NOT EXISTS height_cm integer,
ADD COLUMN IF NOT EXISTS weight_kg numeric,
ADD COLUMN IF NOT EXISTS body_type text,
ADD COLUMN IF NOT EXISTS skin_tone text,
ADD COLUMN IF NOT EXISTS follower_count integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS following_count integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS posts_count integer DEFAULT 0;

-- Add missing columns to community_posts for better social features
ALTER TABLE public.community_posts 
ADD COLUMN IF NOT EXISTS tags text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS location text,
ADD COLUMN IF NOT EXISTS weather_condition text,
ADD COLUMN IF NOT EXISTS is_featured boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS engagement_score numeric DEFAULT 0;

-- Add missing columns to style_challenges
ALTER TABLE public.style_challenges 
ADD COLUMN IF NOT EXISTS reward text,
ADD COLUMN IF NOT EXISTS difficulty_level text DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
ADD COLUMN IF NOT EXISTS category text DEFAULT 'general',
ADD COLUMN IF NOT EXISTS min_participants integer DEFAULT 1,
ADD COLUMN IF NOT EXISTS max_participants integer;

-- 2. Create missing tables
-- ==========================================

-- Weather data cache table
CREATE TABLE IF NOT EXISTS public.weather_cache (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  city text NOT NULL,
  country_code text NOT NULL,
  temperature numeric NOT NULL,
  humidity integer,
  wind_speed numeric,
  weather_condition text NOT NULL,
  weather_description text,
  icon_code text,
  cached_at timestamp with time zone DEFAULT now(),
  expires_at timestamp with time zone DEFAULT (now() + interval '1 hour'),
  CONSTRAINT weather_cache_pkey PRIMARY KEY (id)
);

-- Fashion trends data
CREATE TABLE IF NOT EXISTS public.fashion_insights (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  category text NOT NULL,
  trend_score numeric DEFAULT 0,
  popularity_percentage numeric DEFAULT 0,
  season text CHECK (season IN ('spring', 'summer', 'fall', 'winter', 'all')),
  color_palette text[] DEFAULT '{}',
  style_tags text[] DEFAULT '{}',
  image_url text,
  source text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT fashion_insights_pkey PRIMARY KEY (id)
);

-- User activity tracking
CREATE TABLE IF NOT EXISTS public.user_activity_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id),
  activity_type text NOT NULL,
  activity_data jsonb DEFAULT '{}',
  ip_address inet,
  user_agent text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_activity_logs_pkey PRIMARY KEY (id)
);

-- Clothing recommendations
CREATE TABLE IF NOT EXISTS public.clothing_recommendations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id),
  recommended_item_id uuid REFERENCES public.clothing_items(id),
  reason text,
  confidence_score numeric DEFAULT 0,
  recommendation_type text CHECK (recommendation_type IN ('similar_style', 'color_match', 'occasion_based', 'weather_based', 'trending')),
  is_clicked boolean DEFAULT false,
  is_purchased boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT clothing_recommendations_pkey PRIMARY KEY (id)
);

-- Style archives for saving outfits
CREATE TABLE IF NOT EXISTS public.style_archives (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id),
  outfit_id uuid REFERENCES public.outfits(id),
  archive_name text,
  notes text,
  mood text,
  event_type text,
  archived_at timestamp with time zone DEFAULT now(),
  CONSTRAINT style_archives_pkey PRIMARY KEY (id)
);

-- Social interactions tracking
CREATE TABLE IF NOT EXISTS public.user_interactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id),
  target_user_id uuid REFERENCES public.users(id),
  interaction_type text NOT NULL CHECK (interaction_type IN ('view_profile', 'follow', 'unfollow', 'block', 'report')),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_interactions_pkey PRIMARY KEY (id)
);

-- 3. Create indexes for better performance
-- ==========================================

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_community_posts_user_id ON public.community_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_community_posts_created_at ON public.community_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON public.post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON public.post_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_clothing_items_user_id ON public.clothing_items(user_id);
CREATE INDEX IF NOT EXISTS idx_clothing_items_category ON public.clothing_items(category);
CREATE INDEX IF NOT EXISTS idx_outfits_user_id ON public.outfits(user_id);
CREATE INDEX IF NOT EXISTS idx_style_challenges_active ON public.style_challenges(active);
CREATE INDEX IF NOT EXISTS idx_weather_cache_city ON public.weather_cache(city, expires_at);

-- 4. Add triggers for automatic counting
-- ==========================================

-- Function to update follower counts
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Update follower count for followed user
    UPDATE public.users 
    SET follower_count = follower_count + 1 
    WHERE id = NEW.followed_id;
    
    -- Update following count for follower user
    UPDATE public.users 
    SET following_count = following_count + 1 
    WHERE id = NEW.follower_id;
    
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Update follower count for followed user
    UPDATE public.users 
    SET follower_count = follower_count - 1 
    WHERE id = OLD.followed_id;
    
    -- Update following count for follower user
    UPDATE public.users 
    SET following_count = following_count - 1 
    WHERE id = OLD.follower_id;
    
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for follow counts
DROP TRIGGER IF EXISTS trigger_update_follow_counts ON public.user_follows;
CREATE TRIGGER trigger_update_follow_counts
  AFTER INSERT OR DELETE ON public.user_follows
  FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

-- Function to update post counts
CREATE OR REPLACE FUNCTION update_post_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.users 
    SET posts_count = posts_count + 1 
    WHERE id = NEW.user_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.users 
    SET posts_count = posts_count - 1 
    WHERE id = OLD.user_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for post counts
DROP TRIGGER IF EXISTS trigger_update_post_counts ON public.community_posts;
CREATE TRIGGER trigger_update_post_counts
  AFTER INSERT OR DELETE ON public.community_posts
  FOR EACH ROW EXECUTE FUNCTION update_post_counts();

-- Function to update like counts
CREATE OR REPLACE FUNCTION update_like_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.community_posts 
    SET likes_count = likes_count + 1 
    WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.community_posts 
    SET likes_count = likes_count - 1 
    WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for like counts
DROP TRIGGER IF EXISTS trigger_update_like_counts ON public.post_likes;
CREATE TRIGGER trigger_update_like_counts
  AFTER INSERT OR DELETE ON public.post_likes
  FOR EACH ROW EXECUTE FUNCTION update_like_counts();

-- Function to update comment counts
CREATE OR REPLACE FUNCTION update_comment_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.community_posts 
    SET comments_count = comments_count + 1 
    WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.community_posts 
    SET comments_count = comments_count - 1 
    WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for comment counts
DROP TRIGGER IF EXISTS trigger_update_comment_counts ON public.comments;
CREATE TRIGGER trigger_update_comment_counts
  AFTER INSERT OR DELETE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION update_comment_counts();

-- Function to update challenge participants
CREATE OR REPLACE FUNCTION update_challenge_participants()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.style_challenges 
    SET participants_count = participants_count + 1 
    WHERE id = NEW.challenge_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.style_challenges 
    SET participants_count = participants_count - 1 
    WHERE id = OLD.challenge_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for challenge participants
DROP TRIGGER IF EXISTS trigger_update_challenge_participants ON public.challenge_participants;
CREATE TRIGGER trigger_update_challenge_participants
  AFTER INSERT OR DELETE ON public.challenge_participants
  FOR EACH ROW EXECUTE FUNCTION update_challenge_participants();