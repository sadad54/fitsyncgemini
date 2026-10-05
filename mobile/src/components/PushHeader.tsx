import { StyleSheet, View } from "react-native";
import { ChevronLeft, RotateCcw, X, type LucideIcon } from "@/icons";
import { AppText } from "@/components/AppText";
import { IconButton } from "@/components/IconButton";
import { colors, typography, spacing } from "@/theme";

/** Shared header for pushed screens: back, centred punch title, optional action. */
export function PushHeader({
  title,
  onBack,
  backGlyph,
  actionIcon,
  actionGlyph,
  onAction,
  actionLabel,
  tone = "light"
}: {
  title: string;
  onBack: () => void;
  /** "✕" renders a close control for modals; anything else renders back. */
  backGlyph?: string;
  actionIcon?: LucideIcon;
  /** Legacy glyph; "↻" maps to a reset icon. */
  actionGlyph?: string;
  onAction?: () => void;
  actionLabel?: string;
  actionAccent?: boolean;
  rule?: "strong" | "none";
  tone?: "light" | "stage";
}) {
  const close = backGlyph === "✕";
  const Action = actionIcon ?? (actionGlyph === "↻" ? RotateCcw : undefined);
  const stage = tone === "stage";
  const buttonTone = stage ? "stage" : "solid";
  return (
    <View style={styles.row}>
      <IconButton icon={close ? X : ChevronLeft} label={close ? "Close" : "Back"} onPress={onBack} tone={buttonTone} />
      <AppText accessibilityRole="header" numberOfLines={1} maxFontSizeMultiplier={1.3} style={[styles.title, stage && styles.titleStage]}>{title}</AppText>
      {Action && onAction ? (
        <IconButton icon={Action} label={actionLabel ?? "Action"} onPress={onAction} tone={buttonTone} />
      ) : <View style={styles.spacer} />}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { minHeight: 52, flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: spacing.md },
  title: { flex: 1, textAlign: "center", color: colors.ink, fontSize: 12, lineHeight: 16, ...typography.punch, letterSpacing: 2 },
  titleStage: { color: colors.onStage },
  spacer: { width: 44 }
});
