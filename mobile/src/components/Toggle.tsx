import { Pressable, StyleSheet } from "react-native";
import Animated, { interpolateColor, useAnimatedStyle, useDerivedValue, withSpring } from "react-native-reanimated";
import * as Haptics from "expo-haptics";
import { SPRING } from "@/components/motion";
import { colors } from "@/theme";

export function Toggle({ value, onValueChange, accessibilityLabel }: { value: boolean; onValueChange: (next: boolean) => void; accessibilityLabel?: string }) {
  const progress = useDerivedValue(() => withSpring(value ? 1 : 0, SPRING), [value]);
  const track = useAnimatedStyle(() => ({ backgroundColor: interpolateColor(progress.value, [0, 1], [colors.canvasSoft, colors.ink]) }));
  const knob = useAnimatedStyle(() => ({ transform: [{ translateX: progress.value * 20 }] }));

  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityLabel={accessibilityLabel}
      accessibilityState={{ checked: value }}
      hitSlop={8}
      onPress={() => {
        if (process.env.EXPO_OS !== "web") Haptics.selectionAsync();
        onValueChange(!value);
      }}
    >
      <Animated.View style={[styles.track, track]}>
        <Animated.View style={[styles.knob, knob]} />
      </Animated.View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  track: { width: 50, height: 30, borderRadius: 15, padding: 3, justifyContent: "center" },
  knob: { width: 24, height: 24, borderRadius: 12, backgroundColor: colors.white, boxShadow: "0 1px 3px rgba(23,20,15,0.25)" }
});
