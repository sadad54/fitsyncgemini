import type { ClothingItem } from "@/types/api";

const UPPER = ["tops", "outerwear"];

/** Garments the try-on model can render. */
export function isTryOnable(item: ClothingItem) {
  return [...UPPER, "bottoms", "dresses"].includes(item.category);
}

/**
 * The model renders one dress, one top/bottom, or a top + bottom pair.
 * Reduce a full outfit (which may include shoes, accessories, layers) to the
 * best renderable subset so "Try it on" is always one tap.
 */
export function tryOnSubset(items: ClothingItem[]): ClothingItem[] {
  const dress = items.find((item) => item.category === "dresses");
  if (dress) return [dress];
  const top = items.find((item) => item.category === "tops") ?? items.find((item) => item.category === "outerwear");
  const bottom = items.find((item) => item.category === "bottoms");
  return [top, bottom].filter(Boolean) as ClothingItem[];
}

export function isValidTryOnSelection(items: ClothingItem[]) {
  if (items.length < 1 || items.length > 2 || !items.every(isTryOnable)) return false;
  if (items.length === 1) return true;
  return items.filter((item) => item.category === "bottoms").length === 1 &&
    items.filter((item) => UPPER.includes(item.category)).length === 1;
}

export function tryOnHref(items: ClothingItem[], extra = "") {
  return `/tryon?items=${tryOnSubset(items).map((item) => item.id).join(",")}${extra}`;
}
