import { StyleSheet, View } from "react-native";
import type { LucideIcon } from "@/icons";
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
        {Glyph ? (
          <View style={styles.badgeWrap}>
            <View style={styles.badgeBack} />
            <View style={styles.badge}><Glyph size={24} color={colors.accent} strokeWidth={1.8} /></View>
          </View>
        ) : null}
        <Title style={styles.title}>{title}</Title>
        <AppText selectable style={styles.message}>{message}</AppText>
        {action && onAction ? <Button title={action} onPress={onAction} compact stretch={false} /> : null}
      </View>
    </Reveal>
  );
}

const styles = StyleSheet.create({
  panel: { paddingVertical: spacing.xxl, gap: spacing.md, alignItems: "center" },
  badgeWrap: { width: 76, height: 76, alignItems: "center", justifyContent: "center", marginBottom: spacing.sm },
  badgeBack: { position: "absolute", width: 64, height: 64, borderRadius: radius.lg, backgroundColor: colors.accent, transform: [{ rotate: "12deg" }, { translateX: 6 }, { translateY: 4 }] },
  badge: { width: 64, height: 64, borderRadius: radius.lg, backgroundColor: colors.ink, alignItems: "center", justifyContent: "center", transform: [{ rotate: "-4deg" }] },
  title: { fontSize: 28, lineHeight: 32, textAlign: "center" },
  message: { color: colors.muted, fontSize: 15, lineHeight: 22, textAlign: "center", maxWidth: 300, marginBottom: spacing.sm }
});
