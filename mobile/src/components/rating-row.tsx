import { StyleSheet, View } from "react-native";
import { ThumbsDown, ThumbsUp } from "@/icons";
import { AppText } from "@/components/AppText";
import { POP, PressableScale } from "@/components/motion";
import Animated, { useAnimatedStyle, useSharedValue, withSequence, withSpring } from "react-native-reanimated";
import { colors, fonts, radius, spacing } from "@/theme";

/**
 * Two-tap feedback instead of five stars: easier to answer, and still maps
 * onto the backend's 1–5 rating (down = 2, up = 5).
 */
export function RatingRow({ value, onChange, disabled, tone = "light" }: { value: number; onChange: (value: number) => void; disabled?: boolean; tone?: "light" | "stage" }) {
  const up = value >= 4;
  const down = value > 0 && value < 4;
  const stage = tone === "stage";
  const idle = stage ? colors.onStageMuted : colors.inkSoft;
  return (
    <View style={styles.row}>
      <AppText style={[styles.label, stage && { color: colors.onStageMuted }]}>{value ? "Noted — your stylist is learning" : "How's this look?"}</AppText>
      <View style={styles.buttons}>
        <Thumb active={down} disabled={disabled} label="Not for me" stage={stage} onPress={() => onChange(2)}>
          <ThumbsDown size={18} color={down ? colors.onInk : idle} strokeWidth={1.9} />
        </Thumb>
        <Thumb active={up} love disabled={disabled} label="Love it" stage={stage} onPress={() => onChange(5)}>
          <ThumbsUp size={18} color={up ? colors.onAccent : idle} strokeWidth={1.9} />
        </Thumb>
      </View>
    </View>
  );
}

function Thumb({ active, love, stage, disabled, label, onPress, children }: { active: boolean; love?: boolean; stage: boolean; disabled?: boolean; label: string; onPress: () => void; children: React.ReactNode }) {
  const pop = useSharedValue(1);
  const style = useAnimatedStyle(() => ({ transform: [{ scale: pop.value }] }));
  return (
    <PressableScale accessibilityRole="button" accessibilityLabel={label} accessibilityState={{ selected: active, disabled }} disabled={disabled} scaleTo={0.86}
      onPress={() => { pop.value = withSequence(withSpring(1.18, POP), withSpring(1, POP)); onPress(); }}
      style={[styles.thumb, stage && styles.thumbStage, active && (love ? styles.thumbLove : styles.thumbActive)]}>
      <Animated.View style={style}>{children}</Animated.View>
    </PressableScale>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: spacing.md },
  label: { flex: 1, color: colors.inkSoft, fontSize: 14, fontFamily: fonts.medium },
  buttons: { flexDirection: "row", gap: spacing.sm },
  thumb: { width: 48, height: 48, borderRadius: radius.pill, alignItems: "center", justifyContent: "center", backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke },
  thumbStage: { backgroundColor: colors.stageRaised, borderColor: colors.stageLine },
  thumbActive: { backgroundColor: colors.ink, borderColor: colors.ink },
  thumbLove: { backgroundColor: colors.accent, borderColor: colors.accent }
});
