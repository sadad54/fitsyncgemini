# Supabase Setup Guide for FitSync Community Features

This guide will help you set up Supabase as the backend for the FitSync community features.

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create an account
2. Create a new project
3. Note down your project URL and anon key
pass:j9k87HRqK#Gd!32
## 2. Update Configuration

Update `lib/config/supabase_config.dart` with your actual Supabase credentials:

```dart
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

## 3. Database Schema

Run the following SQL in your Supabase SQL editor to create the required tables:

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar TEXT,
  bio TEXT,
  location TEXT,
  website TEXT,
  verified BOOLEAN DEFAULT FALSE,
  is_private BOOLEAN DEFAULT FALSE,
  style TEXT,
  interests TEXT[],
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view public profiles" ON users
  FOR SELECT USING (is_private = FALSE);

CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = id);
```

### Community Posts Table
```sql
CREATE TABLE community_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT,
  challenge_id UUID REFERENCES style_challenges(id),
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view posts" ON community_posts
  FOR SELECT USING (true);

CREATE POLICY "Users can create their own posts" ON community_posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own posts" ON community_posts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts" ON community_posts
  FOR DELETE USING (auth.uid() = user_id);
```

### Comments Table
```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view comments" ON comments
  FOR SELECT USING (true);

CREATE POLICY "Users can create comments" ON comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments" ON comments
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" ON comments
  FOR DELETE USING (auth.uid() = user_id);
```

### Style Challenges Table
```sql
CREATE TABLE style_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  color TEXT,
  participants_count INTEGER DEFAULT 0,
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE style_challenges ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view challenges" ON style_challenges
  FOR SELECT USING (true);
```

### Challenge Participants Table
```sql
CREATE TABLE challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES style_challenges(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);

-- Enable RLS
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view participants" ON challenge_participants
  FOR SELECT USING (true);

CREATE POLICY "Users can join challenges" ON challenge_participants
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave challenges" ON challenge_participants
  FOR DELETE USING (auth.uid() = user_id);
```

### Post Likes Table
```sql
CREATE TABLE post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Enable RLS
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view likes" ON post_likes
  FOR SELECT USING (true);

CREATE POLICY "Users can like posts" ON post_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike posts" ON post_likes
  FOR DELETE USING (auth.uid() = user_id);
```

### Comment Likes Table
```sql
CREATE TABLE comment_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(comment_id, user_id)
);

-- Enable RLS
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view comment likes" ON comment_likes
  FOR SELECT USING (true);

CREATE POLICY "Users can like comments" ON comment_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike comments" ON comment_likes
  FOR DELETE USING (auth.uid() = user_id);
```

### User Follows Table
```sql
CREATE TABLE user_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
  followed_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, followed_id)
);

-- Enable RLS
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view follows" ON user_follows
  FOR SELECT USING (true);

CREATE POLICY "Users can follow others" ON user_follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow others" ON user_follows
  FOR DELETE USING (auth.uid() = follower_id);
```

### Notifications Table
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  data JSONB,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);
```

### User Notification Settings Table
```sql
CREATE TABLE user_notification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  likes_enabled BOOLEAN DEFAULT TRUE,
  comments_enabled BOOLEAN DEFAULT TRUE,
  challenges_enabled BOOLEAN DEFAULT TRUE,
  mentions_enabled BOOLEAN DEFAULT TRUE,
  follows_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE user_notification_settings ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own settings" ON user_notification_settings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings" ON user_notification_settings
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings" ON user_notification_settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

## 4. Create RPC Functions

### Get Top Contributors Function
```sql
CREATE OR REPLACE FUNCTION get_top_contributors()
RETURNS TABLE (
  username TEXT,
  avatar TEXT,
  points INTEGER,
  rank INTEGER,
  verified BOOLEAN,
  style TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.username,
    u.avatar,
    u.points,
    ROW_NUMBER() OVER (ORDER BY u.points DESC) as rank,
    u.verified,
    u.style
  FROM users u
  ORDER BY u.points DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;
```

### Get User Stats Function
```sql
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid UUID)
RETURNS TABLE (
  total_posts INTEGER,
  total_likes INTEGER,
  total_comments INTEGER,
  challenges_won INTEGER,
  days_active INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(posts.count, 0) as total_posts,
    COALESCE(likes.count, 0) as total_likes,
    COALESCE(comments.count, 0) as total_comments,
    COALESCE(challenges.count, 0) as challenges_won,
    EXTRACT(DAY FROM NOW() - u.created_at)::INTEGER as days_active
  FROM users u
  LEFT JOIN (
    SELECT user_id, COUNT(*) as count 
    FROM community_posts 
    WHERE user_id = user_uuid 
    GROUP BY user_id
  ) posts ON posts.user_id = u.id
  LEFT JOIN (
    SELECT user_id, COUNT(*) as count 
    FROM post_likes 
    WHERE user_id = user_uuid 
    GROUP BY user_id
  ) likes ON likes.user_id = u.id
  LEFT JOIN (
    SELECT user_id, COUNT(*) as count 
    FROM comments 
    WHERE user_id = user_uuid 
    GROUP BY user_id
  ) comments ON comments.user_id = u.id
  LEFT JOIN (
    SELECT user_id, COUNT(*) as count 
    FROM challenge_participants 
    WHERE user_id = user_uuid 
    GROUP BY user_id
  ) challenges ON challenges.user_id = u.id
  WHERE u.id = user_uuid;
END;
$$ LANGUAGE plpgsql;
```

## 5. Create Storage Buckets

1. Go to Storage in your Supabase dashboard
2. Create a bucket named `community-images` with public access
3. Create a bucket named `user-avatars` with public access

## 6. Set Up Real-time Subscriptions

Enable real-time for the following tables in your Supabase dashboard:
- `community_posts`
- `comments`
- `notifications`

## 7. Initialize Supabase in Your App

Add this to your `main.dart`:

```dart
import 'package:your_app/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(MyApp());
}
```

## 8. Update Services

The services are already set up with Supabase placeholders. You just need to:

1. Replace the TODO comments with actual Supabase calls
2. Add proper error handling
3. Implement real-time subscriptions

## 9. Environment Variables (Optional)

For better security, you can use environment variables:

1. Create a `.env` file in your project root:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

2. Add `flutter_dotenv` to your dependencies
3. Update the config to use environment variables

## 10. Testing

1. Test user authentication
2. Test creating posts
3. Test real-time updates
4. Test image uploads
5. Test notifications

## Next Steps

1. Implement user authentication
2. Set up proper error handling
3. Add loading states
4. Implement real-time features
5. Add proper validation
6. Set up automated testing

## Troubleshooting

- Make sure your Supabase project is active
- Check that all tables have the correct RLS policies
- Verify your API keys are correct
- Check the Supabase logs for any errors
- Ensure your storage buckets are properly configured

For more help, refer to the [Supabase documentation](https://supabase.com/docs).
# Supabase Setup Guide for FitSync App

This guide will help you set up Supabase as the backend for the entire FitSync application.

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create an account
2. Create a new project
3. Note down your project URL and anon key
pass:j9k87HRqK#Gd!32

## 2. Update Configuration

Update `lib/config/supabase_config.dart` with your actual Supabase credentials:

```dart
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

## 3. Database Schema

Run the following SQL in your Supabase SQL editor to create the required tables:

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar TEXT,
  bio TEXT,
  location TEXT,
  website TEXT,
  verified BOOLEAN DEFAULT FALSE,
  is_private BOOLEAN DEFAULT FALSE,
  style TEXT,
  interests TEXT[],
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view public profiles" ON users
  FOR SELECT USING (is_private = FALSE);

CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = id);
```

### User Profiles Table
```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  profile_image_url TEXT,
  style_archetype TEXT,
  quiz_results JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### Clothing Items Table
```sql
CREATE TABLE clothing_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  sub_category TEXT NOT NULL,
  image_url TEXT NOT NULL,
  colors TEXT[] DEFAULT '{}',
  brand TEXT,
  price DECIMAL(10,2),
  purchase_location TEXT,
  purchase_date DATE,
  tags TEXT[] DEFAULT '{}',
  ml_confidence DECIMAL(3,2),
  ml_analysis JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE clothing_items ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own clothing items" ON clothing_items
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own clothing items" ON clothing_items
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own clothing items" ON clothing_items
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own clothing items" ON clothing_items
  FOR DELETE USING (auth.uid() = user_id);
```

### Outfits Table
```sql
CREATE TABLE outfits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  occasion TEXT NOT NULL,
  item_ids UUID[] DEFAULT '{}',
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

-- Enable RLS
ALTER TABLE outfits ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own outfits" ON outfits
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own outfits" ON outfits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own outfits" ON outfits
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own outfits" ON outfits
  FOR DELETE USING (auth.uid() = user_id);
```

### Quiz Questions Table
```sql
CREATE TABLE quiz_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  options TEXT[] NOT NULL,
  category TEXT,
  weight INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view quiz questions" ON quiz_questions
  FOR SELECT USING (true);
```

### Quiz Results Table
```sql
CREATE TABLE quiz_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  answers JSONB NOT NULL,
  style_archetype TEXT,
  confidence_score DECIMAL(3,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE quiz_results ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own quiz results" ON quiz_results
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own quiz results" ON quiz_results
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### Virtual Try-On Sessions Table
```sql
CREATE TABLE try_on_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  session_name TEXT,
  view_mode TEXT NOT NULL DEFAULT 'ar',
  status TEXT NOT NULL DEFAULT 'pending',
  processing_progress DECIMAL(3,2) DEFAULT 0,
  error_message TEXT,
  result_image_url TEXT,
  confidence_score DECIMAL(3,2),
  processing_time_ms INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS
ALTER TABLE try_on_sessions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own try-on sessions" ON try_on_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own try-on sessions" ON try_on_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own try-on sessions" ON try_on_sessions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own try-on sessions" ON try_on_sessions
  FOR DELETE USING (auth.uid() = user_id);
```

### Try-On Outfit Attempts Table
```sql
CREATE TABLE try_on_outfit_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES try_on_sessions(id) ON DELETE CASCADE,
  outfit_name TEXT NOT NULL,
  occasion TEXT,
  clothing_items JSONB NOT NULL,
  confidence_score DECIMAL(3,2),
  fit_analysis JSONB,
  color_analysis JSONB,
  style_score DECIMAL(3,2),
  user_rating INTEGER CHECK (user_rating >= 1 AND user_rating <= 5),
  is_favorite BOOLEAN DEFAULT FALSE,
  is_shared BOOLEAN DEFAULT FALSE,
  processing_time_ms INTEGER,
  result_image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE try_on_outfit_attempts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own outfit attempts" ON try_on_outfit_attempts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM try_on_sessions 
      WHERE try_on_sessions.id = try_on_outfit_attempts.session_id 
      AND try_on_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create their own outfit attempts" ON try_on_outfit_attempts
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM try_on_sessions 
      WHERE try_on_sessions.id = try_on_outfit_attempts.session_id 
      AND try_on_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own outfit attempts" ON try_on_outfit_attempts
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM try_on_sessions 
      WHERE try_on_sessions.id = try_on_outfit_attempts.session_id 
      AND try_on_sessions.user_id = auth.uid()
    )
  );
```

### Try-On Preferences Table
```sql
CREATE TABLE try_on_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  default_view_mode TEXT NOT NULL DEFAULT 'ar',
  auto_save_results BOOLEAN DEFAULT TRUE,
  share_anonymously BOOLEAN DEFAULT FALSE,
  enabled_features JSONB DEFAULT '{}',
  processing_quality TEXT NOT NULL DEFAULT 'high',
  max_processing_time INTEGER DEFAULT 30000,
  store_images BOOLEAN DEFAULT TRUE,
  allow_analytics BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE try_on_preferences ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own preferences" ON try_on_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences" ON try_on_preferences
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preferences" ON try_on_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### Trending Styles Table
```sql
CREATE TABLE trending_styles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  growth_percentage DECIMAL(5,2) NOT NULL,
  color_hex TEXT NOT NULL,
  description TEXT,
  category TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE trending_styles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view trending styles" ON trending_styles
  FOR SELECT USING (true);
```

### Style Trends Analytics Table
```sql
CREATE TABLE style_trends_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  style_id UUID REFERENCES trending_styles(id) ON DELETE CASCADE,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  usage_count INTEGER DEFAULT 0,
  growth_rate DECIMAL(5,2),
  popularity_score DECIMAL(3,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE style_trends_analytics ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view style trends analytics" ON style_trends_analytics
  FOR SELECT USING (true);
```

### Nearby Locations Table
```sql
CREATE TABLE nearby_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  category TEXT,
  rating DECIMAL(2,1),
  price_level INTEGER CHECK (price_level >= 1 AND price_level <= 4),
  opening_hours JSONB,
  phone TEXT,
  website TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE nearby_locations ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view nearby locations" ON nearby_locations
  FOR SELECT USING (true);
```

### User Location History Table
```sql
CREATE TABLE user_location_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  accuracy DECIMAL(10,2),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_location_history ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own location history" ON user_location_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own location history" ON user_location_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### Outfit Suggestions Table
```sql
CREATE TABLE outfit_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  occasion TEXT NOT NULL,
  weather_condition TEXT,
  temperature DECIMAL(4,1),
  suggested_items JSONB NOT NULL,
  confidence_score DECIMAL(3,2),
  is_used BOOLEAN DEFAULT FALSE,
  feedback_rating INTEGER CHECK (feedback_rating >= 1 AND feedback_rating <= 5),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE outfit_suggestions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own outfit suggestions" ON outfit_suggestions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own outfit suggestions" ON outfit_suggestions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own outfit suggestions" ON outfit_suggestions
  FOR UPDATE USING (auth.uid() = user_id);
```

### User Settings Table
```sql
CREATE TABLE user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  theme TEXT DEFAULT 'light',
  language TEXT DEFAULT 'en',
  notifications_enabled BOOLEAN DEFAULT TRUE,
  location_sharing_enabled BOOLEAN DEFAULT FALSE,
  analytics_enabled BOOLEAN DEFAULT TRUE,
  privacy_level TEXT DEFAULT 'public',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own settings" ON user_settings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings" ON user_settings
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings" ON user_settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### Community Posts Table
```sql
CREATE TABLE community_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT,
  challenge_id UUID REFERENCES style_challenges(id),
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view posts" ON community_posts
  FOR SELECT USING (true);

CREATE POLICY "Users can create their own posts" ON community_posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own posts" ON community_posts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts" ON community_posts
  FOR DELETE USING (auth.uid() = user_id);
```

### Comments Table
```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view comments" ON comments
  FOR SELECT USING (true);

CREATE POLICY "Users can create comments" ON comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments" ON comments
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" ON comments
  FOR DELETE USING (auth.uid() = user_id);
```

### Style Challenges Table
```sql
CREATE TABLE style_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  color TEXT,
  participants_count INTEGER DEFAULT 0,
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE style_challenges ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view challenges" ON style_challenges
  FOR SELECT USING (true);
```

### Challenge Participants Table
```sql
CREATE TABLE challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES style_challenges(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);

-- Enable RLS
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view participants" ON challenge_participants
  FOR SELECT USING (true);

CREATE POLICY "Users can join challenges" ON challenge_participants
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave challenges" ON challenge_participants
  FOR DELETE USING (auth.uid() = user_id);
```

### Post Likes Table
```sql
CREATE TABLE post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Enable RLS
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view likes" ON post_likes
  FOR SELECT USING (true);

CREATE POLICY "Users can like posts" ON post_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike posts" ON post_likes
  FOR DELETE USING (auth.uid() = user_id);
```

### Comment Likes Table
```sql
CREATE TABLE comment_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(comment_id, user_id)
);

-- Enable RLS
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view comment likes" ON comment_likes
  FOR SELECT USING (true);

CREATE POLICY "Users can like comments" ON comment_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike comments" ON comment_likes
  FOR DELETE USING (auth.uid() = user_id);
```

### User Follows Table
```sql
CREATE TABLE user_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
  followed_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, followed_id)
);

-- Enable RLS
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view follows" ON user_follows
  FOR SELECT USING (true);

CREATE POLICY "Users can follow others" ON user_follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow others" ON user_follows
  FOR DELETE USING (auth.uid() = follower_id);
```

### Notifications Table
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  data JSONB,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);
```

### User Notification Settings Table
```sql
CREATE TABLE user_notification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  likes_enabled BOOLEAN DEFAULT TRUE,
  comments_enabled BOOLEAN DEFAULT TRUE,
  challenges_enabled BOOLEAN DEFAULT TRUE,
  mentions_enabled BOOLEAN DEFAULT TRUE,
  follows_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE user_notification_settings ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own settings" ON user_notification_settings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings" ON user_notification_settings
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings" ON user_notification_settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

## 4. Create RPC Functions

### Get Top Contributors Function
```sql
CREATE OR REPLACE FUNCTION get_top_contributors()
RETURNS TABLE (
  username TEXT,
  avatar TEXT,
  points INTEGER,
  rank INTEGER,
  verified BOOLEAN,
  style TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.username,
    u.avatar,
    u.points,
    ROW_NUMBER() OVER (ORDER BY u.points DESC) as rank,
    u.verified,
    u.style
  FROM users u
  ORDER BY u.points DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;
```

### Get User Stats Function
```sql
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid UUID)
RETURNS TABLE (
  total_posts INTEGER,
  total_likes INTEGER,
  total_comments INTEGER,
  challenges_won INTEGER,
  days_active INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(posts.count, 0) as total_posts,
    COALESCE(likes.count, 0) as total_likes,
    COALESCE(comments.count, 0) as total_comments,
    COALESCE(challenges.count, 0) as challenges_won,
    EXTRACT(DAY FROM NOW() - u.created_at)::INTEGER as days_active
  FROM users u
  LEFT JOIN (
    SELECT user_id, COUNT(*) as count 
    FROM community_posts 
    WHERE user_id = user_uuid 
    GROUP BY user_id
  ) posts ON posts.user_id = u.id
  LEFT JOIN (
    SELECT user_id, COUNT(*) as count 
    FROM post_likes 
    WHERE user_id = user_uuid 
    GROUP BY user_id
  ) likes ON likes.user_id = u.id
  LEFT JOIN (
    SELECT user_id, COUNT(*) as count 
    FROM comments 
    WHERE user_id = user_uuid 
    GROUP BY user_id
  ) comments ON comments.user_id = u.id
  LEFT JOIN (
    SELECT user_id, COUNT(*) as count 
    FROM challenge_participants 
    WHERE user_id = user_uuid 
    GROUP BY user_id
  ) challenges ON challenges.user_id = u.id
  WHERE u.id = user_uuid;
END;
$$ LANGUAGE plpgsql;
```

### Get Nearby Locations Function
```sql
CREATE OR REPLACE FUNCTION get_nearby_locations(
  user_lat DECIMAL(10,8),
  user_lng DECIMAL(11,8),
  radius_km INTEGER DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  address TEXT,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  category TEXT,
  rating DECIMAL(2,1),
  price_level INTEGER,
  distance_km DECIMAL(8,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    nl.id,
    nl.name,
    nl.address,
    nl.latitude,
    nl.longitude,
    nl.category,
    nl.rating,
    nl.price_level,
    (
      6371 * acos(
        cos(radians(user_lat)) * 
        cos(radians(nl.latitude)) * 
        cos(radians(nl.longitude) - radians(user_lng)) + 
        sin(radians(user_lat)) * 
        sin(radians(nl.latitude))
      )
    )::DECIMAL(8,2) as distance_km
  FROM nearby_locations nl
  WHERE nl.is_active = TRUE
  AND (
    6371 * acos(
      cos(radians(user_lat)) * 
      cos(radians(nl.latitude)) * 
      cos(radians(nl.longitude) - radians(user_lng)) + 
      sin(radians(user_lat)) * 
      sin(radians(nl.latitude))
    )
  ) <= radius_km
  ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;
```

### Get Outfit Suggestions Function
```sql
CREATE OR REPLACE FUNCTION get_outfit_suggestions(
  user_uuid UUID,
  occasion TEXT,
  weather_condition TEXT DEFAULT NULL,
  temperature DECIMAL(4,1) DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  occasion TEXT,
  suggested_items JSONB,
  confidence_score DECIMAL(3,2),
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    os.id,
    os.occasion,
    os.suggested_items,
    os.confidence_score,
    os.created_at
  FROM outfit_suggestions os
  WHERE os.user_id = user_uuid
  AND os.occasion = get_outfit_suggestions.occasion
  AND (get_outfit_suggestions.weather_condition IS NULL OR os.weather_condition = get_outfit_suggestions.weather_condition)
  AND (get_outfit_suggestions.temperature IS NULL OR os.temperature = get_outfit_suggestions.temperature)
  ORDER BY os.confidence_score DESC, os.created_at DESC
  LIMIT 5;
END;
$$ LANGUAGE plpgsql;
```

## 5. Create Storage Buckets

1. Go to Storage in your Supabase dashboard
2. Create the following buckets with public access:
   - `community-images` - For community posts
   - `user-avatars` - For user profile pictures
   - `clothing-items` - For clothing item images
   - `outfit-images` - For generated outfit images
   - `try-on-results` - For virtual try-on results
   - `quiz-images` - For quiz-related images

## 6. Set Up Real-time Subscriptions

Enable real-time for the following tables in your Supabase dashboard:
- `community_posts`
- `comments`
- `notifications`
- `try_on_sessions`
- `outfit_suggestions`

## 7. Initialize Supabase in Your App

Add this to your `main.dart`:

```dart
import 'package:your_app/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(MyApp());
}
```

## 8. Update Services

The services are already set up with Supabase placeholders. You just need to:

1. Replace the TODO comments with actual Supabase calls
2. Add proper error handling
3. Implement real-time subscriptions

## 9. Environment Variables (Optional)

For better security, you can use environment variables:

1. Create a `.env` file in your project root:

2. Add `flutter_dotenv` to your dependencies
3. Update the config to use environment variables

## 10. Testing

1. Test user authentication
2. Test creating clothing items
3. Test outfit creation and suggestions
4. Test virtual try-on sessions
5. Test quiz functionality
6. Test community features
7. Test location services
8. Test real-time updates
9. Test image uploads
10. Test notifications

## Next Steps

1. Implement user authentication
2. Set up proper error handling
3. Add loading states
4. Implement real-time features
5. Add proper validation
6. Set up automated testing
7. Implement image processing
8. Set up analytics tracking

## Troubleshooting

- Make sure your Supabase project is active
- Check that all tables have the correct RLS policies
- Verify your API keys are correct
- Check the Supabase logs for any errors
- Ensure your storage buckets are properly configured
- Test database connections and permissions

For more help, refer to the [Supabase documentation](https://supabase.com/docs).