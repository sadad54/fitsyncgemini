import { PropsWithChildren } from "react";
import { Pressable, StyleSheet } from "react-native";
import * as Haptics from "expo-haptics";
import { AppText } from "@/components/AppText";
import { colors, fonts, spacing } from "@/theme";

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
      style={[styles.chip, active && styles.active]}
    >
      <AppText style={[styles.label, active && styles.activeLabel]}>{children}</AppText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  chip: {
    minHeight: 40,
    borderWidth: 1,
    borderColor: colors.stroke,
    backgroundColor: "transparent",
    justifyContent: "center",
    paddingHorizontal: spacing.md
  },
  active: { backgroundColor: colors.rose, borderColor: colors.rose },
  label: { color: colors.muted, fontSize: 10, lineHeight: 13, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  activeLabel: { color: colors.white }
});
