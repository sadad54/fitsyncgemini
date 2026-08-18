/**
 * Seed content for Community, Trends and Locations.
 *
 * These three feature areas have Supabase tables provisioned but no rebuilt
 * backend service yet (unlike auth/clothing/outfits/tryon, which are live).
 * The copy and numbers here mirror the Claude Design source exactly so the
 * screens render as designed; swap each `SEED_*` export for a real query as
 * the corresponding endpoint comes online — the screen components already
 * read through these shapes, so nothing else has to change.
 */

export type FeedTab = "Following" | "Discover" | "Challenges";

export type Post = {
  id: string;
  name: string;
  handle: string;
  initial: string;
  ago: string;
  tag: string;
  likes: number;
  comments: number;
  following: boolean;
  caption: string;
};

export type Comment = {
  id: string;
  name: string;
  initial: string;
  ago: string;
  text: string;
  likes: number;
};

export type Challenge = {
  id: string;
  title: string;
  difficulty: string;
  shape: "square" | "circle" | "moonDown";
  reward: string;
  participants: number;
  days: number;
};

export type Trend = {
  id: string;
  name: string;
  category: string;
  growth: number;
  swatch: string;
};

export type Insight = {
  id: string;
  title: string;
  score: number;
  popularity: number;
  blurb: string;
  tags: string[];
};

export type Store = {
  id: string;
  name: string;
  category: string;
  rating: number;
  price: number;
  distance: string;
  address: string;
};

export type TryOnHistoryEntry = {
  id: string;
  name: string;
  occasion: string;
  date: string;
  pieces: number;
  height: number;
};

export const FIT_PHASES = [
  "Reading your pose…",
  "Mapping shoulders and waist…",
  "Layering the pieces…",
  "Checking break over the boot…"
];

export const ZONES = ["full body", "upper", "footwear", "lower"];

export const LAYER_ROLES = ["base layer", "mid layer", "footwear", "outer layer"];

export const FIT_MODES: Array<{ id: string; label: string }> = [
  { id: "true", label: "True to size" },
  { id: "up", label: "Size up" },
  { id: "tailor", label: "As tailored" }
];

export const SEED_HISTORY: TryOnHistoryEntry[] = [
  { id: "h1", name: "Gallery opening", occasion: "Dinner", date: "12 Aug", pieces: 4, height: 214 },
  { id: "h2", name: "Monochrome test", occasion: "Everyday", date: "09 Aug", pieces: 3, height: 242 },
  { id: "h3", name: "Desk to dinner", occasion: "Work", date: "04 Aug", pieces: 4, height: 196 },
  { id: "h4", name: "Cold morning", occasion: "Travel", date: "28 Jul", pieces: 5, height: 226 }
];

export const SEED_POSTS: Post[] = [
  {
    id: "p1",
    name: "Rina Ferrer",
    handle: "@rinaf",
    initial: "R",
    ago: "4h",
    tag: "Monochrome week",
    likes: 214,
    comments: 18,
    following: true,
    caption: "Three pieces, one tone. The cape does all the talking so everything under it can stay plain."
  },
  {
    id: "p2",
    name: "Theo Mbeki",
    handle: "@theom",
    initial: "T",
    ago: "9h",
    tag: "",
    likes: 96,
    comments: 7,
    following: true,
    caption: "Everyday Edit, ninth day running. Linen dress, flat boot, nothing else to decide."
  },
  {
    id: "p3",
    name: "Junie Park",
    handle: "@junie",
    initial: "J",
    ago: "1d",
    tag: "Second-hand only",
    likes: 341,
    comments: 44,
    following: false,
    caption: "Olive trouser was £14 at the Sunday market. Everything above it I already owned."
  }
];

export const SEED_COMMENTS: Comment[] = [
  { id: "c1", name: "Theo Mbeki", initial: "T", ago: "3h", text: "The cape length is exactly right. What's the fabric?", likes: 12 },
  { id: "c2", name: "Junie Park", initial: "J", ago: "2h", text: "Saved this. Trying it with the charcoal blazer instead of the cape.", likes: 8 },
  { id: "c3", name: "Amara Diallo", initial: "A", ago: "48m", text: "Day four of monochrome and I'm still not bored. Good challenge.", likes: 3 }
];

export const SEED_CHALLENGES: Challenge[] = [
  { id: "ch1", title: "Monochrome week", difficulty: "Medium", shape: "square", reward: "Featured slot on Discover for the top entry.", participants: 412, days: 5 },
  { id: "ch2", title: "Second-hand only", difficulty: "Easy", shape: "circle", reward: "A resale credit for three qualifying posts.", participants: 1180, days: 12 },
  { id: "ch3", title: "Five pieces, seven days", difficulty: "Hard", shape: "moonDown", reward: "Wardrobe audit with a FitSync stylist.", participants: 206, days: 2 }
];

export const SEED_TRENDS: Trend[] = [
  { id: "t1", name: "Quiet crimson", category: "Outerwear", growth: 34, swatch: "#9d2216" },
  { id: "t2", name: "Bone-on-bone", category: "Layering", growth: 27, swatch: "#E8D9C8" },
  { id: "t3", name: "Long olive line", category: "Bottoms", growth: 19, swatch: "#6E7552" },
  { id: "t4", name: "Hard-toe boot", category: "Footwear", growth: 12, swatch: "#242128" }
];

export const TREND_CATEGORIES = ["All", "Outerwear", "Layering", "Bottoms", "Footwear"];

export const SEED_INSIGHTS: Insight[] = [
  {
    id: "i1",
    title: "The one-color outfit is doing the work",
    score: 88,
    popularity: 71,
    blurb: "Dressing in a single tone from shoulder to shoe reads considered without needing a new purchase — texture carries the contrast.",
    tags: ["Autumn", "Minimal", "Tonal"]
  },
  {
    id: "i2",
    title: "Tailoring, worn loose",
    score: 74,
    popularity: 58,
    blurb: "The blazer stays, the fit relaxes. Shoulders sit wider and trousers break long over a flat shoe.",
    tags: ["Autumn", "Workwear", "Relaxed"]
  }
];

export const SEED_TREND_DETAIL = {
  category: "Outerwear",
  name: "Quiet crimson",
  growth: 34,
  description:
    "One saturated red against otherwise muted dressing. It reads deliberate rather than loud because everything around it stays in the bone-to-charcoal range — the same logic your own closet already runs on.",
  palette: [
    { name: "crimson", value: "#9d2216" },
    { name: "bone", value: "#E8D9C8" },
    { name: "charcoal", value: "#3a3a3c" },
    { name: "ink", value: "#242128" }
  ],
  tags: ["Autumn", "Evening", "Tonal", "One statement"]
};

export const SEED_STORES: Store[] = [
  { id: "s1", name: "Atelier Seven", category: "Independent · womenswear", rating: 4.6, price: 3, distance: "0.4 mi", address: "41 Fell Street, Hayes Valley" },
  { id: "s2", name: "Margate & Sons", category: "Tailoring · alterations", rating: 4.9, price: 4, distance: "0.7 mi", address: "12 Octavia Boulevard" },
  { id: "s3", name: "The Sunday Rail", category: "Second-hand · curated", rating: 4.2, price: 1, distance: "1.1 mi", address: "388 Divisadero Street" },
  { id: "s4", name: "North Field Supply", category: "Workwear · unisex", rating: 4.0, price: 2, distance: "1.4 mi", address: "55 Gough Street" }
];

export const SEED_HOURS: Array<[string, string]> = [
  ["Monday", "Closed"],
  ["Tuesday", "11:00 — 18:00"],
  ["Wednesday", "11:00 — 18:00"],
  ["Thursday", "11:00 — 19:00"],
  ["Friday", "11:00 — 19:00"],
  ["Saturday", "10:00 — 19:00"],
  ["Sunday", "12:00 — 17:00"]
];

export const SEED_MEMBER = {
  initial: "R",
  handle: "@rinaf",
  name: "Rina Ferrer",
  bio: "Monochrome, workwear, one good coat.",
  posts: 48,
  followers: "1.2k",
  challenges: 6
};

export const SEED_POST_PICKS = [
  { id: "a", name: "Gallery opening" },
  { id: "b", name: "Desk to dinner" },
  { id: "c", name: "Cold morning" }
];

export const SEED_TAG_CHIPS = ["Monochrome week", "Second-hand only", "Five pieces", "No tag"];

export const SEED_AVATAR_ROW = ["R", "T", "J", "A", "+8"];
