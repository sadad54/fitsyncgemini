import { Pressable, StyleSheet, View } from "react-native";
import { AppText } from "@/components/AppText";
import { colors, fonts, spacing } from "@/theme";

/**
 * The header every pushed (non-tab) screen shares: a square outlined back
 * control, a tracked-out micro label, and an optional trailing action that
 * keeps the title optically centered when absent.
 */
export function PushHeader({
  title,
  onBack,
  backGlyph = "←",
  actionGlyph,
  onAction,
  actionLabel,
  actionAccent = false,
  rule = "strong"
}: {
  title: string;
  onBack: () => void;
  backGlyph?: string;
  actionGlyph?: string;
  onAction?: () => void;
  actionLabel?: string;
  actionAccent?: boolean;
  rule?: "strong" | "none";
}) {
  return (
    <View style={[styles.row, rule === "strong" && styles.ruled]}>
      <Pressable accessibilityRole="button" accessibilityLabel="Back" onPress={onBack} style={styles.iconButton}>
        <AppText style={styles.backGlyph}>{backGlyph}</AppText>
      </Pressable>
      <AppText style={styles.title}>{title}</AppText>
      {actionGlyph && onAction ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={actionLabel ?? "Action"}
          onPress={onAction}
          style={[styles.iconButton, actionAccent && styles.iconButtonAccent]}
        >
          <AppText style={[styles.actionGlyph, actionAccent && styles.actionGlyphAccent]}>{actionGlyph}</AppText>
        </Pressable>
      ) : (
        <View style={styles.spacer} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { minHeight: 40, flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingBottom: spacing.lg },
  ruled: { borderBottomWidth: 2, borderColor: colors.strokeStrong },
  iconButton: { width: 40, height: 40, alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.stroke },
  iconButtonAccent: { borderColor: colors.rose },
  backGlyph: { color: colors.ink, fontSize: 16 },
  actionGlyph: { color: colors.muted, fontSize: 14 },
  actionGlyphAccent: { color: colors.roseSoft },
  title: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6, textTransform: "uppercase" },
  spacer: { width: 40 }
});
