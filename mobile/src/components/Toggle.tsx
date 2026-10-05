import { Pressable, StyleSheet } from "react-native";
import Animated, { interpolateColor, useAnimatedStyle, useDerivedValue, withSpring } from "react-native-reanimated";
import { SPRING, haptic } from "@/components/motion";
import { colors } from "@/theme";

/** Ink track when on, with a volt knob — readable at a glance without relying on colour alone (knob position). */
export function Toggle({ value, onValueChange, accessibilityLabel }: { value: boolean; onValueChange: (next: boolean) => void; accessibilityLabel?: string }) {
  const progress = useDerivedValue(() => withSpring(value ? 1 : 0, SPRING), [value]);
  const track = useAnimatedStyle(() => ({ backgroundColor: interpolateColor(progress.value, [0, 1], [colors.canvasSoft, colors.ink]) }));
  const knob = useAnimatedStyle(() => ({
    backgroundColor: interpolateColor(progress.value, [0, 1], [colors.white, colors.accent]),
    transform: [{ translateX: progress.value * 22 }]
  }));

  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityLabel={accessibilityLabel}
      accessibilityState={{ checked: value }}
      hitSlop={8}
      onPress={() => {
        haptic.tick();
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
  track: { width: 54, height: 32, borderRadius: 16, padding: 3, justifyContent: "center", borderWidth: 1, borderColor: colors.strokeStrong },
  knob: { width: 24, height: 24, borderRadius: 12, boxShadow: "0 1px 3px rgba(13,13,15,0.3)" }
});
