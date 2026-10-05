import { ActivityIndicator, StyleSheet, View } from "react-native";
import * as Haptics from "expo-haptics";
import type { LucideIcon } from "@/icons";
import { AppText } from "@/components/AppText";
import { PressableScale } from "@/components/motion";
import { colors, fonts, radius, shadows, spacing } from "@/theme";

type Variant = "primary" | "accent" | "secondary" | "ghost" | "danger" | "stage";

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
  /** primary = ink · accent = volt (AI / try-on only) · stage = light button on the dark stage. */
  variant?: Variant;
  compact?: boolean;
  stretch?: boolean;
  accessibilityHint?: string;
}) {
  const Icon = typeof icon === "string" ? undefined : icon;
  const filled = variant === "primary" || variant === "accent" || variant === "stage";
  const fg = disabled && filled ? DISABLED_FG : FOREGROUND[variant];
  const inactive = disabled || loading;
  return (
    <PressableScale
      haptic={false}
      accessibilityRole="button"
      accessibilityLabel={title}
      accessibilityHint={accessibilityHint}
      accessibilityState={{ disabled: inactive, busy: loading }}
      disabled={inactive}
      scaleTo={0.96}
      onPress={() => {
        if (process.env.EXPO_OS !== "web") Haptics.impactAsync(variant === "accent" ? Haptics.ImpactFeedbackStyle.Medium : Haptics.ImpactFeedbackStyle.Light);
        onPress?.();
      }}
      style={[styles.base, styles[variant], compact && styles.compact, !stretch && styles.hug, disabled && (filled ? styles.disabledFilled : styles.disabled)]}
    >
      {loading ? <ActivityIndicator color={fg} /> : (
        <View style={styles.row}>
          {Icon ? <Icon size={compact ? 16 : 18} color={fg} strokeWidth={2.2} /> : null}
          <AppText numberOfLines={1} maxFontSizeMultiplier={1.3} style={[styles.label, compact && styles.labelCompact, { color: fg }]}>{title}</AppText>
        </View>
      )}
    </PressableScale>
  );
}

// A neutral grey reads as "off" on both the bone canvas and the dark stage.
const DISABLED_FG = "rgba(110,110,118,0.95)";

const FOREGROUND: Record<Variant, string> = {
  primary: colors.onInk,
  accent: colors.onAccent,
  secondary: colors.ink,
  ghost: colors.ink,
  danger: colors.danger,
  stage: colors.ink
};

const styles = StyleSheet.create({
  base: { minHeight: 56, borderRadius: radius.pill, alignItems: "center", justifyContent: "center", paddingHorizontal: spacing.xl },
  row: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  primary: { backgroundColor: colors.ink },
  accent: { backgroundColor: colors.accent, boxShadow: shadows.volt },
  secondary: { backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.strokeStrong },
  ghost: { backgroundColor: "transparent" },
  danger: { backgroundColor: colors.dangerWash },
  stage: { backgroundColor: colors.onStage },
  compact: { minHeight: 44, paddingHorizontal: spacing.lg },
  hug: { alignSelf: "flex-start" },
  disabled: { opacity: 0.38, boxShadow: "none" },
  disabledFilled: { backgroundColor: "rgba(120,120,128,0.18)", boxShadow: "none" },
  label: { fontSize: 16, lineHeight: 20, fontFamily: fonts.semibold, fontWeight: "600", letterSpacing: -0.1 },
  labelCompact: { fontSize: 15 }
});
