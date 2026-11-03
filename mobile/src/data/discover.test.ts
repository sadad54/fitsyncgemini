import type { CommunityPost, FashionTrend, Place, StyleChallenge } from "@/types/api";
import {
  daysLeftLabel, formatDistance, handleOf, initialOf, splitHours, timeAgo, toChallenge, toInsight, toPost, toStore, toTrend, trendCategories
} from "@/data/discover";

const NOW = new Date("2026-11-03T12:00:00Z");

const post: CommunityPost = {
  id: "p1", user_id: "u1", author_name: "Rina Ferrer", content: "Three pieces, one tone.", image_url: null,
  tags: ["Monochrome week", "Look: Gallery opening"], challenge_id: "c1", likes_count: 12, comments_count: 3,
  liked: true, following: false, created_at: "2026-11-03T08:00:00Z"
};

const trend: FashionTrend = {
  id: "t1", name: "Quiet crimson", description: "One saturated red.", category: "outerwear", confidence_score: 0.88,
  popularity_percentage: 71.4, season: "fall", color_palette: ["crimson", "#9d2216"], style_tags: ["Autumn", "Tonal", "Evening", "Minimal", "Extra"],
  image_url: null, created_at: "", updated_at: ""
};

describe("timeAgo", () => {
  it.each([
    ["2026-11-03T11:59:30Z", "now"],
    ["2026-11-03T11:15:00Z", "45m"],
    ["2026-11-03T04:00:00Z", "8h"],
    ["2026-10-31T12:00:00Z", "3d"],
    ["2026-10-13T12:00:00Z", "3w"],
    ["2026-11-03T12:05:00Z", "now"] // clock skew never shows a negative age
  ])("%s -> %s", (iso, label) => expect(timeAgo(iso, NOW)).toBe(label));
});

describe("names", () => {
  it("builds initials and handles", () => {
    expect(initialOf(" rina")).toBe("R");
    expect(initialOf("")).toBe("?");
    expect(handleOf("Rina Ferrer")).toBe("@rinaferrer");
    expect(handleOf("✨✨")).toBe("@member");
  });
});

describe("toPost", () => {
  it("maps an API post to the card view model", () => {
    expect(toPost(post, NOW)).toEqual({
      id: "p1", authorId: "u1", name: "Rina Ferrer", handle: "@rinaferrer", initial: "R", ago: "4h",
      tag: "Monochrome week", likes: 12, comments: 3, liked: true, following: false, caption: "Three pieces, one tone.", imageUrl: null
    });
  });

  it("has no tag pill when the post is untagged", () => {
    expect(toPost({ ...post, tags: [] }, NOW).tag).toBe("");
  });
});

describe("challenges", () => {
  const challenge: StyleChallenge = {
    id: "c1", title: "Monochrome week", description: "", reward: "", difficulty: "hard", participants_count: 412,
    days_left: 1, joined: false, image_url: "/img.jpg"
  };

  it("capitalises difficulty and cycles card shapes", () => {
    expect(toChallenge(challenge, 0)).toMatchObject({ difficulty: "Hard", shape: "square", participants: 412, imageUrl: "/img.jpg" });
    expect(toChallenge(challenge, 4).shape).toBe("circle");
  });

  it.each([[null, "Ongoing"], [0, "Last day"], [1, "1 day left"], [5, "5 days left"]] as const)("days %s -> %s", (days, label) => {
    expect(daysLeftLabel(days)).toBe(label);
  });
});

describe("trends", () => {
  it("uses the first hex colour as the swatch and rounds popularity", () => {
    expect(toTrend(trend)).toEqual({ id: "t1", name: "Quiet crimson", category: "Outerwear", growth: 71, swatch: "#9d2216" });
  });

  it("falls back to a neutral swatch when the palette has no hex colour", () => {
    expect(toTrend({ ...trend, color_palette: ["crimson"] }).swatch).toBe("#3a3a3c");
  });

  it("scores 0–1 confidence out of 100 and keeps four tags", () => {
    expect(toInsight(trend)).toMatchObject({ score: 88, popularity: 71, tags: ["Autumn", "Tonal", "Evening", "Minimal"] });
  });

  it("builds sorted, de-duplicated category chips", () => {
    const list = [toTrend(trend), toTrend({ ...trend, id: "t2", category: "footwear" }), toTrend({ ...trend, id: "t3" })];
    expect(trendCategories(list)).toEqual(["All", "Footwear", "Outerwear"]);
  });
});

describe("stores", () => {
  it.each([[undefined, ""], [42, "40 m"], [950, "950 m"], [1240, "1.2 km"], [12_600, "13 km"]] as const)("distance %s -> %s", (m, label) => {
    expect(formatDistance(m)).toBe(label);
  });

  it("maps a place, hiding a zero rating and clamping price", () => {
    const place: Place = { id: "g1", name: "Atelier", rating: 0, price_level: 9, category: null, address: "Jalan Telawi", is_open: true, distance_m: 420 };
    expect(toStore(place)).toEqual({ id: "g1", name: "Atelier", category: "Fashion", rating: null, price: 4, distance: "420 m", address: "Jalan Telawi", open: true });
  });

  it("splits Google opening-hours lines on the first colon only", () => {
    expect(splitHours(["Monday: 10:00 AM – 9:00 PM", "Tuesday: Closed", "Holiday hours vary"])).toEqual([
      ["Monday", "10:00 AM – 9:00 PM"], ["Tuesday", "Closed"], ["Holiday hours vary", ""]
    ]);
  });
});
