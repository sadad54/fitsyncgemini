import { Pressable, StyleSheet, View } from "react-native";
import { ArrowRight } from "@/icons";
import { AppText, Punch, Title } from "@/components/AppText";
import { colors, fonts, spacing } from "@/theme";

export function SectionHeader({ eyebrow, title, action, onAction }: { eyebrow?: string; title: string; action?: string; onAction?: () => void }) {
  return (
    <View style={styles.row}>
      <View style={styles.copy}>
        {eyebrow ? <Punch style={styles.eyebrow}>{eyebrow}</Punch> : null}
        <Title style={styles.title}>{title}</Title>
      </View>
      {action && onAction ? (
        <Pressable accessibilityRole="button" accessibilityLabel={action} onPress={onAction} hitSlop={8} style={styles.action}>
          <AppText style={styles.actionText}>{action}</AppText>
          <View style={styles.arrow}><ArrowRight size={13} color={colors.onInk} strokeWidth={2.4} /></View>
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "flex-end", justifyContent: "space-between", gap: spacing.md },
  copy: { flex: 1, gap: 4 },
  eyebrow: { color: colors.muted },
  title: { fontSize: 26, lineHeight: 30 },
  action: { minHeight: 44, flexDirection: "row", alignItems: "center", gap: 6 },
  actionText: { color: colors.ink, fontSize: 14, fontFamily: fonts.semibold, fontWeight: "600" },
  arrow: { width: 22, height: 22, borderRadius: 11, backgroundColor: colors.ink, alignItems: "center", justifyContent: "center" }
});
