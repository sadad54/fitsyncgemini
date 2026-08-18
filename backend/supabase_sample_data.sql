-- ==========================================
-- SAMPLE DATA POPULATION FOR FITSYNC
-- ==========================================

-- 1. Sample Users (Fashion Enthusiasts)
-- ==========================================
INSERT INTO public.users (id, username, display_name, email, avatar, bio, location, website, verified, style, interests, points, phone, gender, height_cm, weight_kg, body_type, skin_tone) VALUES 
(gen_random_uuid(), 'fashionista_jane', 'Jane Thompson', 'jane.thompson@email.com', 'https://images.unsplash.com/photo-1494790108755-2616b332c8f2?w=150', 'Fashion blogger & style influencer ✨ Sharing daily outfit inspiration', 'New York, NY', 'https://janestyle.com', true, 'Chic & Modern', ARRAY['Fashion', 'Photography', 'Travel'], 1250, '+1-555-0123', 'female', 165, 55.5, 'pear', 'light'),
(gen_random_uuid(), 'style_guru_mike', 'Michael Chen', 'mike.chen@email.com', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', 'Mens fashion consultant | Minimalist style advocate | NYC', 'New York, NY', NULL, false, 'Minimalist', ARRAY['Menswear', 'Minimalism', 'Design'], 980, '+1-555-0124', 'male', 180, 75.0, 'athletic', 'medium'),
(gen_random_uuid(), 'chic_explorer', 'Emma Rodriguez', 'emma.rodriguez@email.com', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150', 'Vintage lover 🌟 Thrift finds & sustainable fashion', 'Los Angeles, CA', 'https://emmavintage.com', true, 'Vintage Revival', ARRAY['Vintage', 'Sustainability', 'Art'], 875, '+1-555-0125', 'female', 170, 60.0, 'hourglass', 'medium'),
(gen_random_uuid(), 'trendy_alex', 'Alex Park', 'alex.park@email.com', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150', 'Street style photographer | Fashion week regular', 'London, UK', NULL, false, 'Streetwear', ARRAY['Photography', 'Streetwear', 'Music'], 650, '+44-555-0126', 'male', 175, 70.0, 'slim', 'light'),
(gen_random_uuid(), 'boho_bella', 'Isabella Martinez', 'bella.martinez@email.com', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150', 'Boho soul ✌️ Free spirit with a love for flowing fabrics', 'Austin, TX', 'https://bohobella.etsy.com', false, 'Bohemian', ARRAY['Boho', 'Music', 'Nature'], 720, '+1-555-0127', 'female', 162, 58.0, 'apple', 'olive'),
(gen_random_uuid(), 'dapper_david', 'David Johnson', 'david.johnson@email.com', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', 'Classic menswear enthusiast | Suit specialist', 'Chicago, IL', NULL, false, 'Classic Gentleman', ARRAY['Formal Wear', 'Watches', 'Business'], 540, '+1-555-0128', 'male', 185, 82.0, 'broad', 'light'),
(gen_random_uuid(), 'urban_sophia', 'Sophia Kim', 'sophia.kim@email.com', 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=150', 'K-fashion lover | Seoul street style', 'Seoul, South Korea', 'https://urbansophia.blog', true, 'K-Fashion', ARRAY['K-Pop', 'Street Fashion', 'Beauty'], 890, '+82-555-0129', 'female', 158, 50.0, 'petite', 'light'),
(gen_random_uuid(), 'casual_chris', 'Christopher Lee', 'chris.lee@email.com', 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150', 'Comfort meets style | Work from home fashion', 'San Francisco, CA', NULL, false, 'Casual Comfort', ARRAY['Tech', 'Comfort', 'Gaming'], 420, '+1-555-0130', 'male', 172, 68.0, 'average', 'medium');

-- 2. Style Challenges
-- ==========================================
INSERT INTO public.style_challenges (id, title, description, image_url, color, participants_count, start_date, end_date, active, reward, difficulty_level, category) VALUES 
(gen_random_uuid(), 'Summer Vibes Challenge', 'Show off your best summer outfits and inspire others! Think bright colors, lightweight fabrics, and sun-ready accessories.', 'https://images.unsplash.com/photo-1506629905607-bb5c07bef3ea?w=400', '#FF6B6B', 234, now() - interval '5 days', now() + interval '10 days', true, '🏆 Summer Style Crown + 500 points', 'easy', 'seasonal'),
(gen_random_uuid(), 'Vintage Revival Challenge', 'Mix vintage pieces with modern fashion for unique looks. Show us how you blend decades of style!', 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400', '#4ECDC4', 156, now() - interval '3 days', now() + interval '8 days', true, '✨ Vintage Master Badge + 750 points', 'medium', 'style'),
(gen_random_uuid(), 'Monochrome Monday', 'Create stunning outfits using only one color palette. Master the art of tonal dressing.', 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400', '#95A5A6', 89, now() - interval '1 day', now() + interval '6 days', true, '🎨 Color Master Badge + 300 points', 'medium', 'color'),
(gen_random_uuid(), 'Sustainable Style Week', 'Showcase eco-friendly fashion choices. Thrift finds, upcycled pieces, and sustainable brands welcome!', 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=400', '#27AE60', 78, now() + interval '1 day', now() + interval '15 days', true, '🌱 Eco Warrior Badge + 1000 points', 'hard', 'sustainability'),
(gen_random_uuid(), 'Office to Evening', 'Transform your work look into evening glamour. Show your styling versatility!', 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400', '#8E44AD', 112, now() + interval '2 days', now() + interval '12 days', true, '💼 Style Transformer Badge + 600 points', 'medium', 'occasion');

-- 3. Community Posts
-- ==========================================
WITH user_ids AS (
  SELECT id, username FROM public.users LIMIT 8
),
challenge_ids AS (
  SELECT id, title FROM public.style_challenges LIMIT 5
)
INSERT INTO public.community_posts (id, user_id, image_url, caption, challenge_id, likes_count, comments_count, tags, location, weather_condition) 
SELECT 
  gen_random_uuid(),
  u.id,
  post_data.image_url,
  post_data.caption,
  c.id,
  post_data.likes_count,
  post_data.comments_count,
  post_data.tags,
  post_data.location,
  post_data.weather_condition
FROM user_ids u
CROSS JOIN (
  VALUES 
    ('https://images.unsplash.com/photo-1445205170230-053b83016050?w=400', 'Perfect summer day calls for this flowy maxi dress! 🌞 The floral print gives me major vacation vibes ✨ #SummerStyle #FloralDress #OOTD', 42, 8, ARRAY['summer', 'floral', 'dress', 'vacation'], 'Central Park, NYC', 'sunny'),
    ('https://images.unsplash.com/photo-1617137984095-74e4e5e3613f?w=400', 'Keeping it minimal today with this monochrome look. Sometimes less really is more 👌 #MinimalStyle #Monochrome #LessIsMore', 67, 12, ARRAY['minimal', 'monochrome', 'simple', 'clean'], 'Brooklyn, NY', 'cloudy'),
    ('https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400', 'Found this amazing vintage leather jacket at a thrift store! Paired it with modern pieces for the perfect blend 💎 #VintageFinds #ThriftStyle #SustainableFashion', 89, 15, ARRAY['vintage', 'thrift', 'leather', 'sustainable'], 'Venice Beach, CA', 'partly_cloudy')
) AS post_data(image_url, caption, likes_count, comments_count, tags, location, weather_condition)
CROSS JOIN challenge_ids c
WHERE (u.username = 'fashionista_jane' AND post_data.caption LIKE '%summer%') 
   OR (u.username = 'style_guru_mike' AND post_data.caption LIKE '%minimal%')
   OR (u.username = 'chic_explorer' AND post_data.caption LIKE '%vintage%');

-- Add more varied posts
INSERT INTO public.community_posts (id, user_id, image_url, caption, likes_count, comments_count, tags, location, weather_condition)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM public.users WHERE username = 'trendy_alex'),
  'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400',
  'Street style captured in the heart of London! This oversized blazer is giving me boss vibes 💼✨ #StreetStyle #London #Blazer',
  34, 6, ARRAY['street', 'blazer', 'london', 'boss'], 'Shoreditch, London', 'rainy'
UNION ALL
SELECT 
  gen_random_uuid(),
  (SELECT id FROM public.users WHERE username = 'boho_bella'),
  'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=400',
  'Channeling my inner goddess with this bohemian ensemble 🌸 Flowing fabrics and earth tones are my weakness! #BohoVibes #Goddess #EarthTones',
  56, 9, ARRAY['boho', 'flowing', 'earth_tones', 'goddess'], 'Austin, TX', 'sunny'
UNION ALL
SELECT 
  gen_random_uuid(),
  (SELECT id FROM public.users WHERE username = 'dapper_david'),
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
  'Three-piece suit for todays board meeting. Classic never goes out of style 👔 #ClassicMenswear #ThreePiece #BusinessStyle',
  28, 4, ARRAY['classic', 'suit', 'business', 'formal'], 'Downtown Chicago', 'clear';

-- 4. Sample Clothing Items
-- ==========================================
INSERT INTO public.clothing_items (user_id, name, category, sub_category, image_url, colors, brand, price, tags, ml_confidence)
SELECT 
  u.id,
  item_data.name,
  item_data.category,
  item_data.sub_category,
  item_data.image_url,
  item_data.colors,
  item_data.brand,
  item_data.price,
  item_data.tags,
  item_data.ml_confidence
FROM (SELECT id FROM public.users LIMIT 5) u
CROSS JOIN (
  VALUES 
    ('Floral Summer Dress', 'dresses', 'maxi_dress', 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=300', ARRAY['blue', 'white', 'floral'], 'Zara', 89.99, ARRAY['summer', 'floral', 'casual', 'comfortable'], 0.95),
    ('Classic White Blazer', 'outerwear', 'blazer', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=300', ARRAY['white'], 'H&M', 79.99, ARRAY['professional', 'versatile', 'classic'], 0.92),
    ('High-Waisted Jeans', 'bottoms', 'jeans', 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=300', ARRAY['blue', 'denim'], 'Levis', 98.00, ARRAY['casual', 'denim', 'high_waist'], 0.88),
    ('Silk Blouse', 'tops', 'blouse', 'https://images.unsplash.com/photo-1564257577-60ad6c8e8509?w=300', ARRAY['cream', 'beige'], 'Mango', 65.50, ARRAY['elegant', 'silk', 'work'], 0.90),
    ('Leather Ankle Boots', 'shoes', 'boots', 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=300', ARRAY['black', 'leather'], 'Dr. Martens', 150.00, ARRAY['leather', 'ankle', 'versatile'], 0.94)
) AS item_data(name, category, sub_category, image_url, colors, brand, price, tags, ml_confidence);

-- 5. Sample Outfits
-- ==========================================
INSERT INTO public.outfits (user_id, name, occasion, image_url, ai_score, tags, is_favorite)
SELECT 
  u.id,
  outfit_data.name,
  outfit_data.occasion,
  outfit_data.image_url,
  outfit_data.ai_score,
  outfit_data.tags,
  outfit_data.is_favorite
FROM (SELECT id FROM public.users LIMIT 3) u
CROSS JOIN (
  VALUES 
    ('Brunch Date Perfect', 'casual', 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=300', 8.5, ARRAY['casual', 'brunch', 'feminine'], true),
    ('Business Meeting Ready', 'professional', 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=300', 9.2, ARRAY['professional', 'confident', 'polished'], true),
    ('Weekend Vibes', 'casual', 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=300', 7.8, ARRAY['casual', 'weekend', 'comfortable'], false)
) AS outfit_data(name, occasion, image_url, ai_score, tags, is_favorite);

-- 6. Fashion Insights/Trends
-- ==========================================
INSERT INTO public.fashion_insights (title, description, category, trend_score, popularity_percentage, season, color_palette, style_tags, image_url)
VALUES 
('Oversized Blazers Trending', 'Oversized blazers are making a huge comeback this season. Perfect for both casual and professional looks.', 'outerwear', 8.7, 78, 'fall', ARRAY['#2C3E50', '#ECF0F1', '#BDC3C7'], ARRAY['oversized', 'blazer', 'professional', 'casual'], 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400'),
('Sustainable Fashion Movement', 'Eco-conscious fashion choices are becoming mainstream. Consumers prioritize ethical brands and second-hand finds.', 'sustainability', 9.1, 82, 'all', ARRAY['#27AE60', '#2ECC71', '#E8F5E8'], ARRAY['sustainable', 'eco', 'ethical', 'thrift'], 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=400'),
('Y2K Revival', 'Early 2000s fashion is back! Think low-rise jeans, metallic fabrics, and chunky sneakers.', 'vintage', 7.9, 65, 'all', ARRAY['#E74C3C', '#F39C12', '#9B59B6'], ARRAY['y2k', 'metallic', 'retro', 'nostalgic'], 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400'),
('Cottagecore Aesthetic', 'Romantic, rural-inspired fashion with floral prints, puffy sleeves, and vintage silhouettes.', 'aesthetic', 8.3, 71, 'spring', ARRAY['#F8C471', '#D5A6BD', '#A9DFBF'], ARRAY['cottagecore', 'romantic', 'vintage', 'floral'], 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=400'),
('Monochromatic Dressing', 'Single-color outfits create sophisticated, cohesive looks. Perfect for minimalist wardrobes.', 'color_theory', 8.0, 69, 'all', ARRAY['#2C3E50', '#ECF0F1', '#BDC3C7'], ARRAY['monochrome', 'minimalist', 'sophisticated', 'cohesive'], 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400');

-- 7. Sample Comments
-- ==========================================
INSERT INTO public.comments (post_id, user_id, content, likes_count)
SELECT 
  p.id,
  u.id,
  comment_data.content,
  comment_data.likes_count
FROM public.community_posts p
CROSS JOIN (SELECT id FROM public.users ORDER BY random() LIMIT 3) u
CROSS JOIN (
  VALUES 
    ('Love this look! Where did you get that dress?', 5),
    ('You have such great style! 😍', 12),
    ('This is giving me major inspiration for my weekend outfit!', 8),
    ('Absolutely stunning! The colors work so well together', 15),
    ('Need those shoes in my life! 👠', 7)
) AS comment_data(content, likes_count)
WHERE random() < 0.3;

-- 8. Sample Post Likes
-- ==========================================
INSERT INTO public.post_likes (post_id, user_id)
SELECT DISTINCT
  p.id,
  u.id
FROM public.community_posts p
CROSS JOIN (SELECT id FROM public.users) u
WHERE random() < 0.4;

-- 9. Sample User Follows
-- ==========================================
INSERT INTO public.user_follows (follower_id, followed_id)
SELECT DISTINCT
  u1.id,
  u2.id
FROM (SELECT id FROM public.users) u1
CROSS JOIN (SELECT id FROM public.users) u2
WHERE u1.id != u2.id AND random() < 0.3;

-- 10. Sample Challenge Participants
-- ==========================================
INSERT INTO public.challenge_participants (challenge_id, user_id)
SELECT DISTINCT
  c.id,
  u.id
FROM public.style_challenges c
CROSS JOIN (SELECT id FROM public.users) u
WHERE random() < 0.6;

-- 11. Weather Cache Sample Data
-- ==========================================
INSERT INTO public.weather_cache (city, country_code, temperature, humidity, wind_speed, weather_condition, weather_description, icon_code)
VALUES 
('New York', 'US', 22.5, 65, 15.2, 'Clear', 'Clear sky', '01d'),
('Los Angeles', 'US', 28.0, 45, 8.7, 'Sunny', 'Sunny day', '01d'),
('London', 'GB', 15.3, 78, 12.1, 'Cloudy', 'Overcast clouds', '04d'),
('Paris', 'FR', 18.7, 72, 10.5, 'Partly Cloudy', 'Few clouds', '02d'),
('Tokyo', 'JP', 25.2, 68, 7.3, 'Clear', 'Clear sky', '01d'),
('Sydney', 'AU', 23.8, 55, 11.8, 'Sunny', 'Sunny day', '01d');

-- Update user profile data
-- ==========================================
INSERT INTO public.user_profiles (user_id, first_name, last_name, email, profile_image_url, style_archetype)
SELECT 
  u.id,
  split_part(u.display_name, ' ', 1),
  split_part(u.display_name, ' ', 2),
  u.email,
  u.avatar,
  u.style
FROM public.users u;

-- Create some user settings
-- ==========================================
INSERT INTO public.user_settings (user_id, theme, language, notifications_enabled, location_sharing_enabled, analytics_enabled, privacy_level)
SELECT 
  id,
  CASE WHEN random() > 0.5 THEN 'dark' ELSE 'light' END,
  'en',
  true,
  CASE WHEN random() > 0.7 THEN true ELSE false END,
  CASE WHEN random() > 0.3 THEN true ELSE false END,
  CASE WHEN random() > 0.8 THEN 'private' ELSE 'public' END
FROM public.users;