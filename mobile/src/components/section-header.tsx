import { Pressable, StyleSheet, View } from "react-native";
import { AppText, Eyebrow } from "@/components/AppText";
import { colors, fonts, spacing } from "@/theme";

export function SectionHeader({ eyebrow, title, action, onAction }: { eyebrow?: string; title: string; action?: string; onAction?: () => void }) {
  return (
    <View style={styles.row}>
      <View style={styles.copy}>
        {eyebrow ? <Eyebrow>{eyebrow}</Eyebrow> : null}
        <AppText style={styles.title}>{title}</AppText>
      </View>
      {action && onAction ? (
        <Pressable accessibilityRole="button" accessibilityLabel={action} onPress={onAction} style={styles.action}>
          <AppText style={styles.actionText}>{action}</AppText>
          <AppText style={styles.actionArrow}>→</AppText>
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "flex-end", justifyContent: "space-between", gap: spacing.md },
  copy: { flex: 1, gap: spacing.xs },
  title: { fontSize: 15, lineHeight: 18, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.3, textTransform: "uppercase" },
  action: { minHeight: 44, flexDirection: "row", alignItems: "center", gap: spacing.xs, paddingLeft: spacing.md },
  actionText: { color: colors.roseSoft, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  actionArrow: { color: colors.roseSoft, fontSize: 14 }
});
