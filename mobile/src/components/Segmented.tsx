import { useEffect, useState } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import * as Haptics from "expo-haptics";
import Animated, { useAnimatedStyle, useSharedValue, withSpring } from "react-native-reanimated";
import { AppText } from "@/components/AppText";
import { SPRING } from "@/components/motion";
import { colors, fonts, radius } from "@/theme";

/** Segmented control with a spring-driven thumb. */
export function Segmented<T extends string>({ options, value, onChange }: { options: { value: T; label: string }[]; value: T; onChange: (value: T) => void }) {
  const [width, setWidth] = useState(0);
  const index = Math.max(0, options.findIndex((option) => option.value === value));
  const segment = width / options.length;
  const x = useSharedValue(0);
  useEffect(() => { x.value = withSpring(index * segment, SPRING); }, [index, segment, x]);
  const thumb = useAnimatedStyle(() => ({ transform: [{ translateX: x.value }] }));

  return (
    <View accessibilityRole="tablist" style={styles.track} onLayout={(e) => setWidth(e.nativeEvent.layout.width - 8)}>
      {segment ? <Animated.View style={[styles.thumb, { width: segment }, thumb]} /> : null}
      {options.map((option) => {
        const active = option.value === value;
        return (
          <Pressable key={option.value} accessibilityRole="tab" accessibilityState={{ selected: active }} accessibilityLabel={option.label}
            onPress={() => { if (!active) { if (process.env.EXPO_OS !== "web") Haptics.selectionAsync(); onChange(option.value); } }}
            style={styles.option}>
            <AppText style={[styles.label, active && styles.labelActive]}>{option.label}</AppText>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  track: { flexDirection: "row", height: 44, borderRadius: radius.pill, backgroundColor: colors.canvasSoft, padding: 4 },
  thumb: { position: "absolute", top: 4, bottom: 4, left: 4, borderRadius: radius.pill, backgroundColor: colors.surface, boxShadow: "0 1px 3px rgba(23,20,15,0.12)" },
  option: { flex: 1, alignItems: "center", justifyContent: "center" },
  label: { fontSize: 14, color: colors.muted, fontFamily: fonts.medium, fontWeight: "500" },
  labelActive: { color: colors.ink, fontFamily: fonts.semibold, fontWeight: "600" }
});
