import { StyleSheet } from "react-native";
import type { LucideIcon } from "lucide-react-native";
import { PressableScale } from "@/components/motion";
import { colors, radius } from "@/theme";

/** 44pt round icon control. `tone="glass"` sits on top of photos. */
export function IconButton({ icon: Icon, label, onPress, tone = "plain", size = 44, color, filled }: {
  icon: LucideIcon; label: string; onPress?: () => void; tone?: "plain" | "solid" | "glass" | "ink"; size?: number; color?: string; filled?: boolean;
}) {
  const fg = color ?? (tone === "ink" ? colors.onInk : colors.ink);
  return (
    <PressableScale
      accessibilityRole="button"
      accessibilityLabel={label}
      hitSlop={6}
      scaleTo={0.9}
      onPress={onPress}
      style={[styles.base, { width: size, height: size }, styles[tone]]}
    >
      <Icon size={20} color={fg} fill={filled ? fg : "transparent"} strokeWidth={1.9} />
    </PressableScale>
  );
}

const styles = StyleSheet.create({
  base: { borderRadius: radius.pill, alignItems: "center", justifyContent: "center" },
  plain: { backgroundColor: "transparent" },
  solid: { backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke },
  glass: { backgroundColor: "rgba(255,255,255,0.88)" },
  ink: { backgroundColor: colors.ink }
});
