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
