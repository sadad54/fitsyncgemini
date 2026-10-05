import { Pressable, StyleSheet, View } from "react-native";
import { ChevronRight } from "lucide-react-native";
import { AppText, Title } from "@/components/AppText";
import { colors, fonts, spacing } from "@/theme";

export function SectionHeader({ eyebrow, title, action, onAction }: { eyebrow?: string; title: string; action?: string; onAction?: () => void }) {
  return (
    <View style={styles.row}>
      <View style={styles.copy}>
        {eyebrow ? <AppText style={styles.eyebrow}>{eyebrow}</AppText> : null}
        <Title style={styles.title}>{title}</Title>
      </View>
      {action && onAction ? (
        <Pressable accessibilityRole="button" accessibilityLabel={action} onPress={onAction} hitSlop={8} style={styles.action}>
          <AppText style={styles.actionText}>{action}</AppText>
          <ChevronRight size={16} color={colors.inkSoft} />
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "flex-end", justifyContent: "space-between", gap: spacing.md },
  copy: { flex: 1, gap: 2 },
  eyebrow: { color: colors.muted, fontSize: 13, fontFamily: fonts.medium },
  title: { fontSize: 24, lineHeight: 28 },
  action: { minHeight: 44, flexDirection: "row", alignItems: "center", gap: 2 },
  actionText: { color: colors.inkSoft, fontSize: 14, fontFamily: fonts.medium, fontWeight: "500" }
});
