import { Pressable, StyleSheet, ViewStyle } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { LinearGradient } from "expo-linear-gradient";
import { AppText } from "@/components/AppText";
import { colors, gradients, radius, spacing } from "@/theme";

type IconName = keyof typeof Ionicons.glyphMap;

export function Button({
  title,
  onPress,
  disabled,
  icon,
  variant = "primary",
  compact = false,
  accessibilityHint
}: {
  title: string;
  onPress?: () => void;
  disabled?: boolean;
  icon?: IconName;
  variant?: "primary" | "secondary" | "ghost" | "danger";
  compact?: boolean;
  accessibilityHint?: string;
}) {
  const handlePress = () => {
    if (process.env.EXPO_OS === "ios") Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onPress?.();
  };

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={title}
      accessibilityHint={accessibilityHint}
      accessibilityState={{ disabled }}
      onPress={handlePress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.pressable,
        compact && styles.compact,
        variant !== "primary" && styles[variant],
        disabled && styles.disabled,
        pressed && styles.pressed
      ]}
    >
      {variant === "primary" ? <LinearGradient colors={gradients.rose} style={StyleSheet.absoluteFill as ViewStyle} /> : null}
      {icon ? <Ionicons name={icon} size={compact ? 17 : 19} color={variant === "ghost" ? colors.inkSoft : variant === "secondary" ? colors.ink : colors.white} /> : null}
      <AppText style={[styles.label, variant === "ghost" && styles.ghostLabel, variant === "secondary" && styles.secondaryLabel]}>{title}</AppText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  pressable: {
    minHeight: 52,
    borderRadius: radius.pill,
    alignItems: "center",
    justifyContent: "center",
    flexDirection: "row",
    gap: spacing.sm,
    paddingHorizontal: spacing.xl,
    overflow: "hidden",
    borderCurve: "continuous"
  },
  compact: { minHeight: 44, paddingHorizontal: spacing.lg },
  secondary: { backgroundColor: colors.surfaceElevated, borderWidth: 1, borderColor: colors.strokeStrong },
  ghost: { backgroundColor: "transparent", borderWidth: 1, borderColor: colors.stroke },
  danger: { backgroundColor: colors.dangerWash, borderWidth: 1, borderColor: colors.danger },
  disabled: { opacity: 0.42 },
  pressed: { opacity: 0.82, transform: [{ scale: 0.98 }] },
  label: { color: colors.white, fontWeight: "800", fontSize: 15 },
  ghostLabel: { color: colors.inkSoft },
  secondaryLabel: { color: colors.ink }
});
