import { PropsWithChildren } from "react";
import { StyleSheet, View } from "react-native";
import type { LucideIcon } from "@/icons";
import { AppText } from "@/components/AppText";
import { PressableScale } from "@/components/motion";
import { colors, fonts, radius, spacing } from "@/theme";

export function Chip({ children, active, onPress, icon: Icon }: PropsWithChildren<{ active?: boolean; onPress?: () => void; icon?: LucideIcon }>) {
  const label = typeof children === "string" ? children : "Filter";
  return (
    <PressableScale
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ selected: active }}
      onPress={onPress}
      scaleTo={0.92}
      style={[styles.chip, active && styles.active]}
    >
      {active && !Icon ? <View style={styles.dot} /> : null}
      {Icon ? <Icon size={15} color={active ? colors.accent : colors.inkSoft} strokeWidth={2} /> : null}
      <AppText maxFontSizeMultiplier={1.3} style={[styles.label, active && styles.activeLabel]}>{typeof children === "string" ? capitalize(children) : children}</AppText>
    </PressableScale>
  );
}

const capitalize = (value: string) => value.charAt(0).toUpperCase() + value.slice(1);

const styles = StyleSheet.create({
  chip: {
    minHeight: 44, flexDirection: "row", alignItems: "center", gap: 7, paddingHorizontal: spacing.lg,
    borderRadius: radius.pill, borderWidth: 1, borderColor: colors.strokeStrong, backgroundColor: colors.surface
  },
  active: { backgroundColor: colors.ink, borderColor: colors.ink },
  dot: { width: 6, height: 6, borderRadius: 3, backgroundColor: colors.accent },
  label: { color: colors.inkSoft, fontSize: 14, lineHeight: 18, fontFamily: fonts.medium, fontWeight: "500" },
  activeLabel: { color: colors.onInk, fontFamily: fonts.semibold, fontWeight: "600" }
});
