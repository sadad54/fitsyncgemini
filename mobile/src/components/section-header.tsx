import { Pressable, StyleSheet, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { AppText, Eyebrow } from "@/components/AppText";
import { colors, spacing } from "@/theme";

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
          <Ionicons name="arrow-forward" size={16} color={colors.roseSoft} />
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "flex-end", justifyContent: "space-between", gap: spacing.md },
  copy: { flex: 1, gap: spacing.xs },
  title: { fontSize: 23, lineHeight: 28, fontWeight: "800" },
  action: { minHeight: 44, flexDirection: "row", alignItems: "center", gap: spacing.xs, paddingLeft: spacing.md },
  actionText: { color: colors.roseSoft, fontSize: 14, fontWeight: "700" }
});
