import { StyleSheet, View } from "react-native";
import { ChevronLeft, RotateCcw, X, type LucideIcon } from "lucide-react-native";
import { AppText } from "@/components/AppText";
import { IconButton } from "@/components/IconButton";
import { colors, fonts, spacing } from "@/theme";

/** Shared header for pushed screens: back, centred title, optional action. */
export function PushHeader({
  title,
  onBack,
  backGlyph,
  actionIcon,
  actionGlyph,
  onAction,
  actionLabel
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
}) {
  const close = backGlyph === "✕";
  const Action = actionIcon ?? (actionGlyph === "↻" ? RotateCcw : undefined);
  return (
    <View style={styles.row}>
      <IconButton icon={close ? X : ChevronLeft} label={close ? "Close" : "Back"} onPress={onBack} tone="solid" />
      <AppText numberOfLines={1} style={styles.title}>{title}</AppText>
      {Action && onAction ? (
        <IconButton icon={Action} label={actionLabel ?? "Action"} onPress={onAction} tone="solid" />
      ) : <View style={styles.spacer} />}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { minHeight: 52, flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: spacing.md },
  title: { flex: 1, textAlign: "center", color: colors.ink, fontSize: 16, fontFamily: fonts.semibold, fontWeight: "600" },
  spacer: { width: 44 }
});
