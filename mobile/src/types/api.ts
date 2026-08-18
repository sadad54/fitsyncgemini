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
  status: "processing" | "completed" | "failed";
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
