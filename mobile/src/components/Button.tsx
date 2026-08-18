import { Pressable, StyleSheet } from "react-native";
import * as Haptics from "expo-haptics";
import { AppText } from "@/components/AppText";
import { colors, fonts, spacing } from "@/theme";

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
  // Kept for call-site compatibility; the Modernist system uses a trailing
  // text glyph instead of an icon library, so this only toggles it on.
  icon?: string;
  variant?: "primary" | "secondary" | "ghost" | "danger";
  compact?: boolean;
  accessibilityHint?: string;
}) {
  const handlePress = () => {
    if (process.env.EXPO_OS === "ios") Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onPress?.();
  };

  const glyph = glyphFor(icon, variant);

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
      <AppText
        style={[
          styles.label,
          variant === "ghost" && styles.ghostLabel,
          variant === "secondary" && styles.secondaryLabel,
          variant === "danger" && styles.dangerLabel
        ]}
      >
        {title}
      </AppText>
      {glyph ? (
        <AppText
          style={[styles.glyph, variant === "ghost" && styles.ghostLabel, variant === "secondary" && styles.secondaryLabel]}
        >
          {glyph}
        </AppText>
      ) : null}
    </Pressable>
  );
}

// The Modernist system swaps an icon library for a single trailing text
// glyph, chosen from what the caller's icon name implies.
function glyphFor(icon: string | undefined, variant: "primary" | "secondary" | "ghost" | "danger") {
  if (icon?.includes("checkmark")) return icon.includes("circle") ? "✓" : variant === "primary" ? "→" : "✓";
  if (icon?.includes("trash") || icon?.includes("close")) return "✕";
  if (icon?.includes("refresh")) return "↻";
  if (icon?.includes("log-out")) return "";
  if (variant === "primary") return "→";
  return "";
}

const styles = StyleSheet.create({
  pressable: {
    minHeight: 54,
    backgroundColor: colors.rose,
    alignItems: "center",
    justifyContent: "space-between",
    flexDirection: "row",
    paddingHorizontal: spacing.lg
  },
  compact: { minHeight: 48 },
  secondary: { backgroundColor: "transparent", borderWidth: 2, borderColor: colors.strokeStrong },
  ghost: { backgroundColor: "transparent", borderWidth: 0, borderBottomWidth: 1, borderColor: colors.stroke, justifyContent: "flex-start", gap: spacing.sm },
  danger: { backgroundColor: "transparent", borderWidth: 2, borderColor: colors.rose },
  disabled: { opacity: 0.45 },
  pressed: { opacity: 0.82 },
  label: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 13, letterSpacing: 1.3, textTransform: "uppercase" },
  glyph: { color: colors.white, fontSize: 17, fontFamily: fonts.regular },
  ghostLabel: { color: colors.muted },
  secondaryLabel: { color: colors.ink },
  dangerLabel: { color: colors.roseSoft }
});
