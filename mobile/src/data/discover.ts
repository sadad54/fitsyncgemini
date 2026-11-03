/**
 * View models for Community, Trends and Stores, and the pure functions that
 * build them from API responses. Screens render these shapes; keeping the
 * mapping here makes it unit-testable (see discover.test.ts).
 */
import type { CommunityComment, CommunityPost, FashionTrend, Place, StyleChallenge } from "@/types/api";

export type FeedTab = "Following" | "Discover" | "Challenges";

export type Post = {
  id: string;
  authorId: string;
  name: string;
  handle: string;
  initial: string;
  ago: string;
  tag: string;
  likes: number;
  comments: number;
  liked: boolean;
  following: boolean;
  caption: string;
  imageUrl: string | null;
};

export type Comment = { id: string; name: string; initial: string; ago: string; text: string };

export type ChallengeShape = "square" | "circle" | "moonDown";

export type Challenge = {
  id: string;
  title: string;
  description: string;
  difficulty: string;
  shape: ChallengeShape;
  reward: string;
  participants: number;
  days: number | null;
  joined: boolean;
  imageUrl: string | null;
};

export type Trend = { id: string; name: string; category: string; growth: number; swatch: string };

export type Insight = { id: string; title: string; score: number; popularity: number; blurb: string; tags: string[] };

export type Store = {
  id: string;
  name: string;
  category: string;
  rating: number | null;
  price: number;
  distance: string;
  address: string;
  open: boolean | null;
};

const FALLBACK_SWATCH = "#3a3a3c";
const SHAPES: ChallengeShape[] = ["square", "circle", "moonDown"];

export function timeAgo(iso: string, now: Date = new Date()): string {
  const seconds = Math.max(0, Math.round((now.getTime() - new Date(iso).getTime()) / 1000));
  if (!Number.isFinite(seconds)) return "";
  if (seconds < 60) return "now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d`;
  return `${Math.floor(days / 7)}w`;
}

export function initialOf(name: string): string {
  return (name.trim()[0] ?? "?").toUpperCase();
}

export function handleOf(name: string): string {
  const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, "");
  return `@${slug || "member"}`;
}

export function capitalize(value: string): string {
  return value ? value[0].toUpperCase() + value.slice(1) : value;
}

export function toPost(post: CommunityPost, now?: Date): Post {
  return {
    id: post.id,
    authorId: post.user_id,
    name: post.author_name,
    handle: handleOf(post.author_name),
    initial: initialOf(post.author_name),
    ago: timeAgo(post.created_at, now),
    tag: post.tags[0] ?? "",
    likes: post.likes_count,
    comments: post.comments_count,
    liked: post.liked,
    following: post.following,
    caption: post.content,
    imageUrl: post.image_url ?? null
  };
}

export function toComment(comment: CommunityComment, now?: Date): Comment {
  return {
    id: comment.id,
    name: comment.author_name,
    initial: initialOf(comment.author_name),
    ago: timeAgo(comment.created_at, now),
    text: comment.content
  };
}

export function toChallenge(challenge: StyleChallenge, index = 0): Challenge {
  return {
    id: challenge.id,
    title: challenge.title,
    description: challenge.description,
    difficulty: capitalize(challenge.difficulty),
    shape: SHAPES[index % SHAPES.length],
    reward: challenge.reward,
    participants: challenge.participants_count,
    days: challenge.days_left,
    joined: challenge.joined,
    imageUrl: challenge.image_url ?? null
  };
}

export function daysLeftLabel(days: number | null): string {
  if (days === null) return "Ongoing";
  if (days === 0) return "Last day";
  return `${days} ${days === 1 ? "day" : "days"} left`;
}

export function toTrend(trend: FashionTrend): Trend {
  return {
    id: trend.id,
    name: trend.name,
    category: capitalize(trend.category),
    growth: Math.round(trend.popularity_percentage),
    swatch: trend.color_palette.find((c) => /^#[0-9a-f]{3,8}$/i.test(c)) ?? FALLBACK_SWATCH
  };
}

export function toInsight(trend: FashionTrend): Insight {
  return {
    id: trend.id,
    title: trend.name,
    // confidence_score is stored as 0–1 by the trends service
    score: Math.round((trend.confidence_score <= 1 ? trend.confidence_score * 100 : trend.confidence_score)),
    popularity: Math.round(trend.popularity_percentage),
    blurb: trend.description,
    tags: trend.style_tags.slice(0, 4)
  };
}

export function trendCategories(trends: Trend[]): string[] {
  return ["All", ...Array.from(new Set(trends.map((t) => t.category))).sort()];
}

export function formatDistance(metres?: number): string {
  if (metres === undefined || !Number.isFinite(metres)) return "";
  if (metres < 1000) return `${Math.round(metres / 10) * 10} m`;
  return `${(metres / 1000).toFixed(metres < 10_000 ? 1 : 0)} km`;
}

export function toStore(place: Place): Store {
  return {
    id: place.id,
    name: place.name,
    category: place.category ?? "Fashion",
    rating: typeof place.rating === "number" && place.rating > 0 ? place.rating : null,
    price: Math.max(0, Math.min(4, place.price_level ?? 0)),
    distance: formatDistance(place.distance_m),
    address: place.address ?? "",
    open: place.is_open ?? null
  };
}

/** Google returns "Monday: 10:00 AM – 9:00 PM"; split it into [day, hours]. */
export function splitHours(lines: string[]): Array<[string, string]> {
  return lines.map((line) => {
    const index = line.indexOf(":");
    return index === -1 ? [line, ""] : [line.slice(0, index).trim(), line.slice(index + 1).trim()];
  });
}
