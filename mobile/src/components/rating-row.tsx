import { StyleSheet, View } from "react-native";
import { ThumbsDown, ThumbsUp } from "lucide-react-native";
import { AppText } from "@/components/AppText";
import { PressableScale } from "@/components/motion";
import { colors, fonts, radius, spacing } from "@/theme";

/**
 * Two-tap feedback instead of five stars: easier to answer, and still maps
 * onto the backend's 1–5 rating (down = 2, up = 5).
 */
export function RatingRow({ value, onChange, disabled }: { value: number; onChange: (value: number) => void; disabled?: boolean }) {
  const up = value >= 4;
  const down = value > 0 && value < 4;
  return (
    <View style={styles.row}>
      <AppText style={styles.label}>{value ? "Thanks — your stylist is learning" : "How's this look?"}</AppText>
      <View style={styles.buttons}>
        <Thumb active={down} disabled={disabled} label="Not for me" onPress={() => onChange(2)}>
          <ThumbsDown size={18} color={down ? colors.onInk : colors.inkSoft} strokeWidth={1.9} />
        </Thumb>
        <Thumb active={up} disabled={disabled} label="Love it" onPress={() => onChange(5)}>
          <ThumbsUp size={18} color={up ? colors.onInk : colors.inkSoft} strokeWidth={1.9} />
        </Thumb>
      </View>
    </View>
  );
}

function Thumb({ active, disabled, label, onPress, children }: { active: boolean; disabled?: boolean; label: string; onPress: () => void; children: React.ReactNode }) {
  return (
    <PressableScale accessibilityRole="button" accessibilityLabel={label} accessibilityState={{ selected: active, disabled }} disabled={disabled} onPress={onPress} scaleTo={0.88}
      style={[styles.thumb, active && styles.thumbActive]}>
      {children}
    </PressableScale>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: spacing.md },
  label: { flex: 1, color: colors.inkSoft, fontSize: 14, fontFamily: fonts.medium },
  buttons: { flexDirection: "row", gap: spacing.sm },
  thumb: { width: 44, height: 44, borderRadius: radius.pill, alignItems: "center", justifyContent: "center", backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke },
  thumbActive: { backgroundColor: colors.ink, borderColor: colors.ink }
});
