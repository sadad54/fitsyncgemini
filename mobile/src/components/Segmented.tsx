import { useEffect, useState } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import Animated, { useAnimatedStyle, useSharedValue, withSpring } from "react-native-reanimated";
import { AppText } from "@/components/AppText";
import { SPRING, haptic } from "@/components/motion";
import { colors, fonts, radius } from "@/theme";

/** Segmented control with a spring-driven thumb. */
export function Segmented<T extends string>({ options, value, onChange, tone = "light" }: { options: { value: T; label: string }[]; value: T; onChange: (value: T) => void; tone?: "light" | "stage" }) {
  const stage = tone === "stage";
  const [width, setWidth] = useState(0);
  const index = Math.max(0, options.findIndex((option) => option.value === value));
  const segment = width / options.length;
  const x = useSharedValue(0);
  useEffect(() => { x.value = withSpring(index * segment, SPRING); }, [index, segment, x]);
  const thumb = useAnimatedStyle(() => ({ transform: [{ translateX: x.value }] }));

  return (
    <View accessibilityRole="tablist" style={[styles.track, stage && styles.trackStage]} onLayout={(e) => setWidth(e.nativeEvent.layout.width - 8)}>
      {segment ? <Animated.View style={[styles.thumb, stage && styles.thumbStage, { width: segment }, thumb]} /> : null}
      {options.map((option) => {
        const active = option.value === value;
        return (
          <Pressable key={option.value} accessibilityRole="tab" accessibilityState={{ selected: active }} accessibilityLabel={option.label}
            onPress={() => { if (!active) { haptic.tick(); onChange(option.value); } }}
            style={styles.option}>
            <AppText maxFontSizeMultiplier={1.3} style={[styles.label, stage && styles.labelStage, active && (stage ? styles.labelActiveStage : styles.labelActive)]}>{option.label}</AppText>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  track: { flexDirection: "row", height: 48, borderRadius: radius.pill, backgroundColor: colors.canvasSoft, padding: 4 },
  thumb: { position: "absolute", top: 4, bottom: 4, left: 4, borderRadius: radius.pill, backgroundColor: colors.ink, boxShadow: "0 4px 12px rgba(13,13,15,0.22)" },
  trackStage: { backgroundColor: colors.stageRaised, borderWidth: 1, borderColor: colors.stageLine },
  thumbStage: { backgroundColor: colors.accent, boxShadow: "none" },
  labelStage: { color: colors.onStageMuted },
  labelActiveStage: { color: colors.onAccent, fontFamily: fonts.semibold, fontWeight: "600" },
  option: { flex: 1, alignItems: "center", justifyContent: "center" },
  label: { fontSize: 14, color: colors.muted, fontFamily: fonts.medium, fontWeight: "500" },
  labelActive: { color: colors.onInk, fontFamily: fonts.semibold, fontWeight: "600" }
});
