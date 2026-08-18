import { StyleSheet, View } from "react-native";
import { AppText } from "@/components/AppText";
import { Button } from "@/components/Button";
import { colors, fonts, spacing } from "@/theme";

export function StatePanel({ title, message, action, onAction }: { icon?: string; title: string; message: string; action?: string; onAction?: () => void }) {
  return (
    <View style={styles.panel}>
      <AppText style={styles.title}>{title.toUpperCase()}</AppText>
      <AppText selectable style={styles.message}>{message}</AppText>
      {action && onAction ? <Button title={action} onPress={onAction} variant="secondary" compact /> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  panel: { paddingVertical: spacing.xxl, gap: spacing.md, alignItems: "flex-start" },
  title: { color: colors.ink, fontSize: 26, lineHeight: 27, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.7 },
  message: { color: colors.muted, fontSize: 13, lineHeight: 20 }
});
