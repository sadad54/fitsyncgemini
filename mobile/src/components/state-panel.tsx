import { StyleSheet, View } from "react-native";
import type { LucideIcon } from "lucide-react-native";
import { AppText, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Reveal } from "@/components/motion";
import { colors, radius, spacing } from "@/theme";

/** Empty / error / loading message with a single next step. */
export function StatePanel({ title, message, action, onAction, icon: Icon }: {
  icon?: LucideIcon | string; title: string; message: string; action?: string; onAction?: () => void;
}) {
  const Glyph = typeof Icon === "string" ? undefined : Icon;
  return (
    <Reveal>
      <View style={styles.panel}>
        {Glyph ? <View style={styles.badge}><Glyph size={22} color={colors.ink} strokeWidth={1.7} /></View> : null}
        <Title style={styles.title}>{title}</Title>
        <AppText selectable style={styles.message}>{message}</AppText>
        {action && onAction ? <Button title={action} onPress={onAction} compact stretch={false} /> : null}
      </View>
    </Reveal>
  );
}

const styles = StyleSheet.create({
  panel: { paddingVertical: spacing.xxl, gap: spacing.md, alignItems: "center" },
  badge: { width: 56, height: 56, borderRadius: radius.pill, backgroundColor: colors.surface, alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.stroke, marginBottom: spacing.xs },
  title: { fontSize: 26, lineHeight: 30, textAlign: "center" },
  message: { color: colors.muted, fontSize: 15, lineHeight: 22, textAlign: "center", maxWidth: 300, marginBottom: spacing.sm }
});
