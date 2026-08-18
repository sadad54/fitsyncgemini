import { Modal, Pressable, StyleSheet, View } from "react-native";
import Animated, { FadeIn, SlideInDown } from "react-native-reanimated";
import { AppText } from "@/components/AppText";
import { colors, fonts, spacing } from "@/theme";

// The design's confirm dialog is a bottom sheet, not a system alert: dark
// scrim, red 2px top rule, uppercase title, split Cancel/Confirm row.
export function ConfirmDialog({
  visible,
  title,
  body,
  cancelLabel = "Cancel",
  confirmLabel = "Confirm",
  destructive = false,
  onCancel,
  onConfirm
}: {
  visible: boolean;
  title: string;
  body: string;
  cancelLabel?: string;
  confirmLabel?: string;
  destructive?: boolean;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  return (
    <Modal visible={visible} transparent animationType="none" onRequestClose={onCancel}>
      <Animated.View entering={FadeIn.duration(200)} style={styles.scrim}>
        <Pressable style={StyleSheet.absoluteFill} accessibilityRole="button" accessibilityLabel="Dismiss" onPress={onCancel} />
        <Animated.View entering={SlideInDown.duration(300).springify().damping(20)} style={styles.sheet}>
          <AppText style={styles.title}>{title}</AppText>
          <AppText style={styles.body}>{body}</AppText>
          <View style={styles.actions}>
            <Pressable accessibilityRole="button" accessibilityLabel={cancelLabel} onPress={onCancel} style={styles.cancel}>
              <AppText style={styles.cancelLabel}>{cancelLabel}</AppText>
            </Pressable>
            <Pressable accessibilityRole="button" accessibilityLabel={confirmLabel} onPress={onConfirm} style={[styles.confirm, destructive && styles.confirmDestructive]}>
              <AppText style={styles.confirmLabel}>{confirmLabel}</AppText>
            </Pressable>
          </View>
        </Animated.View>
      </Animated.View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  scrim: { flex: 1, backgroundColor: "rgba(13, 12, 11, 0.72)", justifyContent: "flex-end" },
  sheet: { backgroundColor: colors.canvas, borderTopWidth: 2, borderColor: colors.rose, paddingHorizontal: spacing.xl, paddingTop: spacing.xl, paddingBottom: spacing.xxl },
  title: { fontSize: 26, lineHeight: 26, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.6, textTransform: "uppercase" },
  body: { color: colors.muted, fontSize: 13, lineHeight: 20, marginTop: spacing.sm },
  actions: { flexDirection: "row", gap: spacing.sm, marginTop: spacing.lg },
  cancel: { flex: 1, height: 50, borderWidth: 2, borderColor: colors.strokeStrong, alignItems: "flex-start", justifyContent: "center", paddingHorizontal: spacing.md },
  cancelLabel: { color: colors.ink, fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: 1, textTransform: "uppercase" },
  confirm: { flex: 1, height: 50, backgroundColor: colors.rose, alignItems: "flex-start", justifyContent: "center", paddingHorizontal: spacing.md },
  confirmDestructive: { backgroundColor: colors.rose },
  confirmLabel: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: 1, textTransform: "uppercase" }
});
