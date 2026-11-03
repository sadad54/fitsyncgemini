export type Profile = {
  user_id: string;
  display_name?: string | null;
  style_preferences: string[];
  favorite_colors: string[];
  sizes: Record<string, string>;
  onboarding_complete: boolean;
  created_at: string;
  updated_at: string;
};

export type ClothingCategory =
  | "tops"
  | "bottoms"
  | "dresses"
  | "outerwear"
  | "footwear"
  | "accessories"
  | "activewear"
  | "unknown";

export type ClothingItem = {
  id: string;
  user_id: string;
  name: string;
  image_url?: string | null;
  category: ClothingCategory;
  subcategory?: string | null;
  colors: string[];
  tags: string[];
  seasons: string[];
  occasions: string[];
  brand?: string | null;
  notes?: string | null;
  analysis: Record<string, unknown>;
  created_at: string;
  updated_at: string;
};

export type ClosetStats = {
  total_items: number;
  by_category: Record<string, number>;
  missing_essentials: string[];
};

export type TryOnResult = {
  id: string;
  user_id: string;
  item_ids: string[];
  person_image_url?: string | null;
  result_image_url?: string | null;
  status: "queued" | "processing" | "completed" | "failed";
  render_kind?: "diffusion" | "legacy_preview";
  expires_at?: string | null;
  confidence_score?: number | null;
  error_message?: string | null;
  created_at: string;
  updated_at: string;
};

export type Outfit = {
  id: string;
  user_id: string;
  name: string;
  item_ids: string[];
  occasion: string;
  weather_context?: Record<string, unknown> | null;
  score: number;
  explanation: string;
  saved: boolean;
  favorited: boolean;
  created_at: string;
  updated_at: string;
};


// ---- Discover: community, challenges, trends, stores ------------------------

export type CommunityPost = {
  id: string;
  user_id: string;
  author_name: string;
  content: string;
  image_url?: string | null;
  tags: string[];
  challenge_id?: string | null;
  likes_count: number;
  comments_count: number;
  liked: boolean;
  following: boolean;
  created_at: string;
};

export type CommunityComment = {
  id: string;
  post_id: string;
  user_id: string;
  author_name: string;
  content: string;
  created_at: string;
};

export type CommunityMember = {
  user_id: string;
  name: string;
  style_tags: string[];
  posts_count: number;
  followers_count: number;
  challenges_count: number;
  following: boolean;
  is_self: boolean;
  posts: CommunityPost[];
};

export type StyleChallenge = {
  id: string;
  title: string;
  description: string;
  reward: string;
  difficulty: string;
  category?: string | null;
  color?: string | null;
  image_url?: string | null;
  participants_count: number;
  days_left: number | null;
  joined: boolean;
};

export type StyleChallengeDetail = StyleChallenge & {
  entries: CommunityPost[];
  recent_participants: string[];
};

export type FashionTrend = {
  id: string;
  name: string;
  description: string;
  category: string;
  confidence_score: number;
  popularity_percentage: number;
  season?: string | null;
  color_palette: string[];
  style_tags: string[];
  image_url?: string | null;
  created_at: string;
  updated_at: string;
};

export type Place = {
  id: string;
  name: string;
  rating?: number | null;
  price_level?: number | null;
  category?: string | null;
  address?: string | null;
  is_open?: boolean | null;
  location?: { lat: number; lng: number } | null;
  distance_m?: number;
};

export type NearbyPlaces = {
  places: Place[];
  total_count: number;
  error?: "provider_unavailable";
};

export type PlaceDetails = {
  id: string;
  name?: string | null;
  rating?: number | null;
  review_count?: number;
  address?: string | null;
  location?: { lat: number; lng: number } | null;
  price_level?: number | null;
  website?: string | null;
  phone?: string | null;
  opening_hours: string[];
  reviews: Array<{ author?: string | null; rating?: number | null; text?: string | null; time?: string | null }>;
};
