import { StyleSheet } from "react-native";
import type { LucideIcon } from "@/icons";
import { PressableScale } from "@/components/motion";
import { colors, radius } from "@/theme";

/**
 * 44pt round icon control.
 * plain · solid (white chip) · glass (on photos) · ink · stage (on the dark stage) · accent (volt)
 */
export function IconButton({ icon: Icon, label, onPress, tone = "plain", size = 44, color, filled }: {
  icon: LucideIcon; label: string; onPress?: () => void; tone?: "plain" | "solid" | "glass" | "ink" | "stage" | "accent"; size?: number; color?: string; filled?: boolean;
}) {
  const fg = color ?? (tone === "ink" || tone === "stage" ? colors.onInk : colors.ink);
  // Small visual sizes still get a 44pt touch target.
  const slop = Math.max(6, Math.ceil((44 - size) / 2));
  return (
    <PressableScale
      accessibilityRole="button"
      accessibilityLabel={label}
      hitSlop={slop}
      scaleTo={0.88}
      onPress={onPress}
      style={[styles.base, { width: size, height: size }, styles[tone]]}
    >
      <Icon size={Math.min(20, Math.round(size * 0.44))} color={fg} fill={filled ? fg : "transparent"} strokeWidth={1.9} />
    </PressableScale>
  );
}

const styles = StyleSheet.create({
  base: { borderRadius: radius.pill, alignItems: "center", justifyContent: "center" },
  plain: { backgroundColor: "transparent" },
  solid: { backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke },
  glass: { backgroundColor: "rgba(255,255,255,0.9)" },
  ink: { backgroundColor: colors.ink },
  stage: { backgroundColor: "rgba(246,246,242,0.1)", borderWidth: 1, borderColor: colors.stageLine },
  accent: { backgroundColor: colors.accent }
});
