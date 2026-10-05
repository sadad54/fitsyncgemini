import { ActivityIndicator, StyleSheet, View } from "react-native";
import * as Haptics from "expo-haptics";
import type { LucideIcon } from "lucide-react-native";
import { AppText } from "@/components/AppText";
import { PressableScale } from "@/components/motion";
import { colors, fonts, radius, spacing } from "@/theme";

type Variant = "primary" | "accent" | "secondary" | "ghost" | "danger";

export function Button({
  title,
  onPress,
  disabled,
  loading,
  icon,
  variant = "primary",
  compact = false,
  stretch = true,
  accessibilityHint
}: {
  title: string;
  onPress?: () => void;
  disabled?: boolean;
  loading?: boolean;
  /** A lucide icon component. Legacy string names are ignored. */
  icon?: LucideIcon | string;
  variant?: Variant;
  compact?: boolean;
  stretch?: boolean;
  accessibilityHint?: string;
}) {
  const Icon = typeof icon === "string" ? undefined : icon;
  const fg = FOREGROUND[variant];
  const inactive = disabled || loading;
  return (
    <PressableScale
      haptic={false}
      accessibilityRole="button"
      accessibilityLabel={title}
      accessibilityHint={accessibilityHint}
      accessibilityState={{ disabled: inactive, busy: loading }}
      disabled={inactive}
      onPress={() => {
        if (process.env.EXPO_OS !== "web") Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        onPress?.();
      }}
      style={[styles.base, styles[variant], compact && styles.compact, !stretch && styles.hug, disabled && styles.disabled]}
    >
      {loading ? <ActivityIndicator color={fg} /> : (
        <View style={styles.row}>
          {Icon ? <Icon size={compact ? 16 : 18} color={fg} strokeWidth={2} /> : null}
          <AppText style={[styles.label, compact && styles.labelCompact, { color: fg }]}>{title}</AppText>
        </View>
      )}
    </PressableScale>
  );
}

const FOREGROUND: Record<Variant, string> = {
  primary: colors.onInk,
  accent: colors.onAccent,
  secondary: colors.ink,
  ghost: colors.ink,
  danger: colors.danger
};

const styles = StyleSheet.create({
  base: { minHeight: 54, borderRadius: radius.pill, alignItems: "center", justifyContent: "center", paddingHorizontal: spacing.xl },
  row: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  primary: { backgroundColor: colors.ink },
  accent: { backgroundColor: colors.accent, boxShadow: "0 8px 22px rgba(46,68,214,0.28)" },
  secondary: { backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.strokeStrong },
  ghost: { backgroundColor: "transparent" },
  danger: { backgroundColor: colors.dangerWash },
  compact: { minHeight: 44, paddingHorizontal: spacing.lg },
  hug: { alignSelf: "flex-start" },
  disabled: { opacity: 0.4 },
  label: { fontSize: 16, lineHeight: 20, fontFamily: fonts.semibold, fontWeight: "600", letterSpacing: -0.1 },
  labelCompact: { fontSize: 15 }
});
