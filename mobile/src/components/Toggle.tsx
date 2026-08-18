import { Pressable, StyleSheet, View } from "react-native";
import Animated, { useAnimatedStyle, withTiming } from "react-native-reanimated";
import * as Haptics from "expo-haptics";
import { colors } from "@/theme";

// The Modernist system's toggle is a flat 46x26 rule-bordered track with a
// square knob — not the platform Switch, which can't be restyled to match
// (no radius, signal-red fill, instant-square knob).
export function Toggle({ value, onValueChange, accessibilityLabel }: { value: boolean; onValueChange: (next: boolean) => void; accessibilityLabel?: string }) {
  const knobStyle = useAnimatedStyle(() => ({
    left: withTiming(value ? 22 : 2, { duration: 280 })
  }));

  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityLabel={accessibilityLabel}
      accessibilityState={{ checked: value }}
      onPress={() => {
        if (process.env.EXPO_OS === "ios") Haptics.selectionAsync();
        onValueChange(!value);
      }}
      style={[styles.track, value && styles.trackActive]}
    >
      <Animated.View style={[styles.knob, knobStyle, value && styles.knobActive]} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  track: { width: 46, height: 26, borderWidth: 1, borderColor: colors.stroke, backgroundColor: colors.surfaceElevated, justifyContent: "center" },
  trackActive: { backgroundColor: colors.rose, borderColor: colors.rose },
  knob: { position: "absolute", top: 2, width: 20, height: 20, backgroundColor: colors.muted },
  knobActive: { backgroundColor: colors.white }
});
