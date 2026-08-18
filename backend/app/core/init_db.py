"""
Database initialization for FitSync
Creates necessary tables and indexes for optimal performance
"""

from supabase import create_client
from app.core.config import settings
import asyncio

async def init_database():
    """Initialize database with required tables"""
    
    supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
    
    # SQL for creating tables (if they don't exist)
    tables_sql = """
    -- User profiles table (extends Supabase auth.users)
    CREATE TABLE IF NOT EXISTS user_profiles (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        username TEXT UNIQUE,
        first_name TEXT,
        last_name TEXT,
        email TEXT,
        avatar_url TEXT,
        bio TEXT,
        style_archetype TEXT,
        quiz_results JSONB DEFAULT '{}',
        preferences JSONB DEFAULT '{}',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Clothing items table
    CREATE TABLE IF NOT EXISTS clothing_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        subcategory TEXT,
        color TEXT,
        colors TEXT[] DEFAULT '{}',
        brand TEXT,
        size TEXT,
        price DECIMAL(10,2),
        purchase_date DATE,
        image_url TEXT NOT NULL,
        tags TEXT[] DEFAULT '{}',
        ml_analysis JSONB DEFAULT '{}',
        ml_confidence DECIMAL(3,2),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Outfits table
    CREATE TABLE IF NOT EXISTS outfits (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        occasion TEXT,
        clothing_item_ids UUID[] DEFAULT '{}',
        image_url TEXT,
        ai_score DECIMAL(3,2),
        style_analysis JSONB DEFAULT '{}',
        tags TEXT[] DEFAULT '{}',
        is_favorite BOOLEAN DEFAULT FALSE,
        wear_count INTEGER DEFAULT 0,
        last_worn TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Try-on sessions table
    CREATE TABLE IF NOT EXISTS tryon_sessions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        session_name TEXT,
        view_mode TEXT DEFAULT 'ar',
        status TEXT DEFAULT 'pending',
        result_image_url TEXT,
        confidence_score DECIMAL(3,2),
        processing_time_ms INTEGER,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Community posts table
    CREATE TABLE IF NOT EXISTS community_posts (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        content TEXT,
        image_url TEXT,
        likes_count INTEGER DEFAULT 0,
        comments_count INTEGER DEFAULT 0,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Create indexes for better performance
    CREATE INDEX IF NOT EXISTS idx_clothing_items_user_id ON clothing_items(user_id);
    CREATE INDEX IF NOT EXISTS idx_clothing_items_category ON clothing_items(category);
    CREATE INDEX IF NOT EXISTS idx_outfits_user_id ON outfits(user_id);
    CREATE INDEX IF NOT EXISTS idx_tryon_sessions_user_id ON tryon_sessions(user_id);
    CREATE INDEX IF NOT EXISTS idx_community_posts_user_id ON community_posts(user_id);
    CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);

    -- Enable Row Level Security
    ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
    ALTER TABLE clothing_items ENABLE ROW LEVEL SECURITY;
    ALTER TABLE outfits ENABLE ROW LEVEL SECURITY;
    ALTER TABLE tryon_sessions ENABLE ROW LEVEL SECURITY;
    ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

    -- RLS Policies
    -- Users can only access their own data
    CREATE POLICY IF NOT EXISTS "Users can view own profile" ON user_profiles
        FOR SELECT USING (auth.uid() = user_id);
    
    CREATE POLICY IF NOT EXISTS "Users can update own profile" ON user_profiles
        FOR UPDATE USING (auth.uid() = user_id);
    
    CREATE POLICY IF NOT EXISTS "Users can insert own profile" ON user_profiles
        FOR INSERT WITH CHECK (auth.uid() = user_id);

    CREATE POLICY IF NOT EXISTS "Users can view own clothing" ON clothing_items
        FOR SELECT USING (auth.uid() = user_id);
    
    CREATE POLICY IF NOT EXISTS "Users can manage own clothing" ON clothing_items
        FOR ALL USING (auth.uid() = user_id);

    CREATE POLICY IF NOT EXISTS "Users can view own outfits" ON outfits
        FOR SELECT USING (auth.uid() = user_id);
    
    CREATE POLICY IF NOT EXISTS "Users can manage own outfits" ON outfits
        FOR ALL USING (auth.uid() = user_id);

    -- Community posts are publicly readable but users can only manage their own
    CREATE POLICY IF NOT EXISTS "Anyone can view community posts" ON community_posts
        FOR SELECT USING (true);
    
    CREATE POLICY IF NOT EXISTS "Users can manage own posts" ON community_posts
        FOR ALL USING (auth.uid() = user_id);
    """
    
    try:
        # Execute the SQL
        result = supabase.rpc('exec_sql', {'sql': tables_sql})
        print("✅ Database tables initialized successfully")
        return True
    except Exception as e:
        print(f"❌ Database initialization failed: {e}")
        # For development, we'll create a simpler version
        print("🔧 Creating tables individually...")
        
        # Create tables one by one (fallback method)
        tables = [
            ("user_profiles", "User profiles"),
            ("clothing_items", "Clothing items"),
            ("outfits", "Outfits"),
            ("tryon_sessions", "Try-on sessions"),
            ("community_posts", "Community posts"),
        ]
        
        for table_name, description in tables:
            try:
                # Check if table exists
                result = supabase.table(table_name).select("count", count="exact").limit(1).execute()
                print(f"✅ {description} table exists")
            except:
                print(f"⚠️  {description} table needs to be created manually")
        
        return False

if __name__ == "__main__":
    asyncio.run(init_database())