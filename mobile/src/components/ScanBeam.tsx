import { useEffect, useState } from "react";
import { StyleSheet, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import Animated, { Easing, interpolate, useAnimatedStyle, useReducedMotion, useSharedValue, withRepeat, withSequence, withTiming } from "react-native-reanimated";
import { colors } from "@/theme";

/**
 * The volt scan beam — Flairwise's "AI at work" signature — sweeping its parent.
 * Place inside a relatively positioned container with overflow hidden.
 */
export function ScanBeam({ duration = 1800 }: { duration?: number }) {
  const reduced = useReducedMotion();
  const [height, setHeight] = useState(0);
  const t = useSharedValue(0);
  useEffect(() => {
    if (reduced) return;
    t.value = withRepeat(withSequence(
      withTiming(1, { duration, easing: Easing.inOut(Easing.cubic) }),
      withTiming(0, { duration, easing: Easing.inOut(Easing.cubic) })
    ), -1);
  }, [reduced, duration, t]);
  const style = useAnimatedStyle(() => ({ transform: [{ translateY: interpolate(t.value, [0, 1], [-40, height - 40]) }] }));
  if (reduced) return null;
  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill} onLayout={(e) => setHeight(e.nativeEvent.layout.height)}>
      <Animated.View style={[styles.beam, style]}>
        <LinearGradient colors={["rgba(212,255,58,0)", "rgba(212,255,58,0.26)", "rgba(212,255,58,0)"]} style={StyleSheet.absoluteFill} />
        <View style={styles.line} />
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  beam: { position: "absolute", left: 0, right: 0, height: 80 },
  line: { position: "absolute", left: 0, right: 0, top: 39, height: 2, backgroundColor: colors.accent, boxShadow: "0 0 14px rgba(212,255,58,0.9)" }
});
