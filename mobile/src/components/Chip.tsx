import { PropsWithChildren } from "react";
import { Pressable, StyleSheet } from "react-native";
import * as Haptics from "expo-haptics";
import { AppText } from "@/components/AppText";
import { colors, radius, spacing } from "@/theme";

export function Chip({ children, active, onPress }: PropsWithChildren<{ active?: boolean; onPress?: () => void }>) {
  const label = typeof children === "string" ? children : "Filter";
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ selected: active }}
      onPress={() => {
        if (process.env.EXPO_OS === "ios") Haptics.selectionAsync();
        onPress?.();
      }}
      style={({ pressed }) => [styles.chip, active && styles.active, pressed && styles.pressed]}
    >
      <AppText style={[styles.label, active && styles.activeLabel]}>{children}</AppText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  chip: {
    minHeight: 44,
    borderRadius: radius.pill,
    borderWidth: 1,
    borderColor: colors.stroke,
    backgroundColor: colors.surface,
    justifyContent: "center",
    paddingHorizontal: spacing.lg
  },
  active: { backgroundColor: colors.roseWash, borderColor: colors.rose },
  pressed: { opacity: 0.72 },
  label: { color: colors.inkSoft, fontSize: 14, fontWeight: "700", textTransform: "capitalize" },
  activeLabel: { color: colors.roseSoft }
});
