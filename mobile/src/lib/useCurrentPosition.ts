import { useCallback, useEffect, useState } from "react";
import * as Location from "expo-location";
import { withTimeout } from "@/lib/useStyleOutfit";

export type PositionState =
  | { status: "locating" }
  | { status: "ready"; latitude: number; longitude: number }
  | { status: "denied" }
  | { status: "unavailable" };

/**
 * The device's position for "near you" lists. `ask: false` only reads it when
 * permission was already granted, so passive surfaces never pop a prompt.
 */
export function useCurrentPosition(ask: boolean) {
  const [state, setState] = useState<PositionState>({ status: "locating" });

  const locate = useCallback(async (prompt: boolean) => {
    setState({ status: "locating" });
    try {
      const permission = prompt
        ? await withTimeout(Location.requestForegroundPermissionsAsync(), 8000)
        : await withTimeout(Location.getForegroundPermissionsAsync(), 3000);
      if (!permission.granted) return setState({ status: "denied" });
      const position = await withTimeout(Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced }), 8000);
      setState({ status: "ready", latitude: position.coords.latitude, longitude: position.coords.longitude });
    } catch {
      setState({ status: "unavailable" });
    }
  }, []);

  useEffect(() => { locate(ask); }, [ask, locate]);

  return { position: state, retry: () => locate(true) };
}
