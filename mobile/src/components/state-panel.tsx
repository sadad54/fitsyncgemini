import { StyleSheet, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { AppText } from "@/components/AppText";
import { Button } from "@/components/Button";
import { colors, radius, spacing } from "@/theme";

export function StatePanel({ icon = "sparkles-outline", title, message, action, onAction }: { icon?: keyof typeof Ionicons.glyphMap; title: string; message: string; action?: string; onAction?: () => void }) {
  return (
    <View style={styles.panel}>
      <View style={styles.icon}><Ionicons name={icon} size={24} color={colors.roseSoft} /></View>
      <View style={styles.copy}>
        <AppText style={styles.title}>{title}</AppText>
        <AppText selectable style={styles.message}>{message}</AppText>
      </View>
      {action && onAction ? <Button title={action} onPress={onAction} variant="secondary" compact icon="refresh" /> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  panel: { backgroundColor: colors.surface, borderRadius: radius.lg, borderCurve: "continuous", borderWidth: 1, borderColor: colors.stroke, padding: spacing.xl, gap: spacing.lg, alignItems: "flex-start" },
  icon: { width: 48, height: 48, borderRadius: radius.md, backgroundColor: colors.roseWash, alignItems: "center", justifyContent: "center" },
  copy: { gap: spacing.xs },
  title: { fontSize: 18, lineHeight: 23, fontWeight: "800" },
  message: { color: colors.muted }
});
