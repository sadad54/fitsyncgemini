import { Modal, Pressable, StyleSheet, View } from "react-native";
import Animated, { FadeIn, FadeOut, SlideInDown, SlideOutDown } from "react-native-reanimated";
import { Title, AppText } from "@/components/AppText";
import { Button } from "@/components/Button";
import { SETTLE } from "@/components/motion";
import { colors, radius, spacing } from "@/theme";

/** Bottom-sheet confirmation; the destructive action sits in the thumb zone. */
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
    <Modal visible={visible} transparent animationType="none" onRequestClose={onCancel} statusBarTranslucent>
      <Animated.View entering={FadeIn.duration(180)} exiting={FadeOut.duration(160)} style={styles.scrim}>
        <Pressable style={StyleSheet.absoluteFill} accessibilityRole="button" accessibilityLabel="Dismiss" onPress={onCancel} />
        <Animated.View entering={SlideInDown.duration(380).easing(SETTLE)} exiting={SlideOutDown.duration(200)} style={styles.sheet}>
          <View style={styles.grabber} />
          <Title style={styles.title}>{title}</Title>
          <AppText style={styles.body}>{body}</AppText>
          <View style={styles.actions}>
            <Button title={confirmLabel} variant={destructive ? "danger" : "primary"} onPress={onConfirm} />
            <Button title={cancelLabel} variant="ghost" onPress={onCancel} />
          </View>
        </Animated.View>
      </Animated.View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  scrim: { flex: 1, backgroundColor: colors.scrim, justifyContent: "flex-end" },
  sheet: {
    backgroundColor: colors.canvas, borderTopLeftRadius: radius.xl, borderTopRightRadius: radius.xl,
    paddingHorizontal: spacing.xl, paddingTop: spacing.md, paddingBottom: spacing.xxxl, gap: spacing.sm
  },
  grabber: { alignSelf: "center", width: 40, height: 5, borderRadius: 3, backgroundColor: colors.strokeStrong, marginBottom: spacing.md },
  title: { fontSize: 30, lineHeight: 34 },
  body: { color: colors.inkSoft, fontSize: 15, lineHeight: 22 },
  actions: { marginTop: spacing.lg, gap: spacing.xs }
});
