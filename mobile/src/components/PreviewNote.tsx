import { StyleSheet, View } from "react-native";
import { AppText, Punch } from "@/components/AppText";
import { colors, radius, spacing } from "@/theme";

/**
 * Honest label for screens that still render sample data (src/data/discover.ts).
 * Keep it on every Discover sub-screen until the real services are connected.
 */
export function PreviewNote({ children = "Sample content while this feature is being connected." }: { children?: string }) {
  return (
    <View style={styles.note} accessibilityRole="text">
      <View style={styles.tag}><Punch style={styles.tagText}>Preview</Punch></View>
      <AppText style={styles.text}>{children}</AppText>
    </View>
  );
}

const styles = StyleSheet.create({
  note: {
    flexDirection: "row", alignItems: "center", gap: spacing.sm, padding: spacing.sm, paddingRight: spacing.md,
    borderRadius: radius.md, borderWidth: 1, borderStyle: "dashed", borderColor: colors.strokeStrong, backgroundColor: colors.surface
  },
  tag: { backgroundColor: colors.ink, borderRadius: 6, paddingHorizontal: 8, paddingVertical: 5 },
  tagText: { color: colors.accent, fontSize: 9, lineHeight: 11 },
  text: { flex: 1, fontSize: 13, lineHeight: 18, color: colors.inkSoft }
});
