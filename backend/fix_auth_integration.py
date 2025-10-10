#!/usr/bin/env python3
"""
Fix authentication integration between Supabase and FastAPI
This script addresses the dual authentication system issues
"""

import os
from pathlib import Path

def create_unified_auth_service():
    """Create a unified authentication service that works with both Supabase and FastAPI"""
    
    auth_service_content = '''
from typing import Optional, Dict, Any
from fastapi import HTTPException, status
from supabase import create_client, Client
from app.core.config import settings
import jwt
from datetime import datetime, timedelta

class UnifiedAuthService:
    """Unified authentication service for Supabase + FastAPI integration"""
    
    def __init__(self):
        self.supabase: Client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_ROLE_KEY
        )
    
    async def verify_supabase_token(self, token: str) -> Optional[Dict[str, Any]]:
        """Verify Supabase JWT token and return user data"""
        try:
            # Verify the JWT token with Supabase
            user_response = self.supabase.auth.get_user(token)
            
            if user_response.user:
                return {
                    "id": user_response.user.id,
                    "email": user_response.user.email,
                    "user_metadata": user_response.user.user_metadata or {},
                    "app_metadata": user_response.user.app_metadata or {},
                }
            return None
        except Exception as e:
            print(f"Token verification failed: {e}")
            return None
    
    async def create_backend_user_profile(self, supabase_user: Dict[str, Any]) -> Dict[str, Any]:
        """Create or update user profile in backend database"""
        try:
            # Check if user already exists in backend
            existing_user = self.supabase.table("user_profiles").select("*").eq("user_id", supabase_user["id"]).execute()
            
            user_data = {
                "user_id": supabase_user["id"],
                "email": supabase_user["email"],
                "first_name": supabase_user["user_metadata"].get("first_name", ""),
                "last_name": supabase_user["user_metadata"].get("last_name", ""),
                "username": supabase_user["user_metadata"].get("username", supabase_user["email"].split("@")[0]),
                "updated_at": datetime.utcnow().isoformat(),
            }
            
            if existing_user.data:
                # Update existing user
                result = self.supabase.table("user_profiles").update(user_data).eq("user_id", supabase_user["id"]).execute()
            else:
                # Create new user profile
                user_data["created_at"] = datetime.utcnow().isoformat()
                result = self.supabase.table("user_profiles").insert(user_data).execute()
            
            return result.data[0] if result.data else user_data
        except Exception as e:
            print(f"Failed to create/update user profile: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create user profile"
            )
    
    async def get_current_user_from_token(self, token: str) -> Dict[str, Any]:
        """Get current user data from token"""
        # Remove 'Bearer ' prefix if present
        if token.startswith("Bearer "):
            token = token[7:]
        
        # Verify Supabase token
        supabase_user = await self.verify_supabase_token(token)
        if not supabase_user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token"
            )
        
        # Ensure user profile exists in backend
        user_profile = await self.create_backend_user_profile(supabase_user)
        
        return {
            "id": supabase_user["id"],
            "email": supabase_user["email"],
            "username": user_profile.get("username", supabase_user["email"].split("@")[0]),
            "first_name": user_profile.get("first_name", ""),
            "last_name": user_profile.get("last_name", ""),
            "profile": user_profile,
        }

# Global instance
auth_service = UnifiedAuthService()
'''
    
    # Write the auth service
    auth_service_path = Path("app/services/unified_auth_service.py")
    auth_service_path.parent.mkdir(parents=True, exist_ok=True)
    auth_service_path.write_text(auth_service_content.strip())
    print(f"✅ Created unified auth service: {auth_service_path}")

def update_auth_dependencies():
    """Update authentication dependencies to use unified service"""
    
    dependencies_content = '''
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Dict, Any
from app.services.unified_auth_service import auth_service

security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """Get current authenticated user"""
    try:
        return await auth_service.get_current_user_from_token(credentials.credentials)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed"
        )

async def get_optional_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any] | None:
    """Get current user if authenticated, None otherwise"""
    try:
        return await auth_service.get_current_user_from_token(credentials.credentials)
    except:
        return None

# Image validation
async def validate_image_file(file):
    """Validate uploaded image file"""
    if not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image"
        )
    
    # Check file size (10MB limit)
    file_size = 0
    chunk_size = 1024
    while chunk := await file.read(chunk_size):
        file_size += len(chunk)
        if file_size > 10 * 1024 * 1024:  # 10MB
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File too large. Maximum size is 10MB"
            )
    
    # Reset file pointer
    await file.seek(0)
    return file
'''
    
    # Write updated dependencies
    deps_path = Path("app/api/dependencies.py")
    deps_path.write_text(dependencies_content.strip())
    print(f"✅ Updated auth dependencies: {deps_path}")

def create_database_init_script():
    """Create database initialization script"""
    
    init_script_content = '''
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
'''
    
    # Write database init script
    init_path = Path("app/core/init_db.py")
    init_path.write_text(init_script_content.strip())
    print(f"✅ Created database init script: {init_path}")

def main():
    """Run all authentication fixes"""
    print("🔧 Fixing FitSync authentication integration...\n")
    
    create_unified_auth_service()
    update_auth_dependencies()
    create_database_init_script()
    
    print("\n✅ Authentication integration fixes completed!")
    print("\n📋 Next steps:")
    print("1. Update your .env file with Supabase credentials")
    print("2. Run: python app/core/init_db.py")
    print("3. Test with: python test_full_integration.py")
    print("4. Start backend: ./start_backend.sh")

if __name__ == "__main__":
    main()