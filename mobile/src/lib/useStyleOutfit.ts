import { useState } from "react";
import * as Location from "expo-location";
import * as Haptics from "expo-haptics";
import { useGenerateOutfit } from "@/api/queries";

// expo-location can hang (notably on web) instead of resolving. Weather is a
// nice-to-have, so it never blocks generating a look.
function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("timeout")), ms);
    promise.then(
      (value) => { clearTimeout(timer); resolve(value); },
      (error) => { clearTimeout(timer); reject(error); }
    );
  });
}

export const OCCASIONS = [
  { id: "casual", label: "Everyday" },
  { id: "work", label: "Work" },
  { id: "date", label: "Date night" },
  { id: "dinner", label: "Dinner" },
  { id: "travel", label: "Travel" },
  { id: "workout", label: "Move" }
] as const;

/**
 * Generates an outfit from the user's closet.
 * `askForLocation: false` only uses weather if permission was already granted,
 * so passive surfaces (Today) never pop a permission prompt.
 */
export function useStyleOutfit() {
  const generate = useGenerateOutfit();
  const [locationNote, setLocationNote] = useState<string | null>(null);

  async function style({ occasion, weather, askForLocation }: { occasion: string; weather: boolean; askForLocation: boolean }) {
    setLocationNote(null);
    let input: { use_weather?: boolean; latitude?: number; longitude?: number } = { use_weather: false };
    if (weather) {
      try {
        const permission = askForLocation
          ? await withTimeout(Location.requestForegroundPermissionsAsync(), 6000)
          : await withTimeout(Location.getForegroundPermissionsAsync(), 3000);
        if (permission.granted) {
          const position = await withTimeout(Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced }), 6000);
          input = { use_weather: true, latitude: position.coords.latitude, longitude: position.coords.longitude };
        } else if (askForLocation) {
          setLocationNote("Location is off, so this look skips the weather.");
        }
      } catch {
        if (askForLocation) setLocationNote("Couldn't read the weather in time, so this look skips it.");
      }
    }
    const outfit = await generate.mutateAsync({ occasion, ...input });
    if (process.env.EXPO_OS !== "web") Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    return outfit;
  }

  return { style, generate, locationNote };
}

export function weatherLabel(context?: Record<string, unknown> | null) {
  if (!context || typeof context.temperature !== "number") return null;
  const condition = typeof context.condition === "string" ? context.condition
    : typeof context.description === "string" ? context.description : null;
  return `${Math.round(context.temperature)}°${condition ? ` · ${condition}` : ""}`;
}
