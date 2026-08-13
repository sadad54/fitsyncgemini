import { PropsWithChildren } from "react";
import { ScrollView, StyleProp, StyleSheet, View, ViewStyle } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { LinearGradient } from "expo-linear-gradient";
import { colors, spacing } from "@/theme";

export function Screen({
  children,
  scroll = true,
  contentStyle,
  bottomInset = true
}: PropsWithChildren<{
  scroll?: boolean;
  contentStyle?: StyleProp<ViewStyle>;
  bottomInset?: boolean;
}>) {
  const content = <View style={[styles.content, bottomInset && styles.bottomInset, contentStyle]}>{children}</View>;

  return (
    <LinearGradient colors={[colors.canvasSoft, colors.canvas]} style={styles.root}>
      <StatusBar style="dark" />
      <View style={[styles.ambientRose, styles.pointerNone]} />
      <View style={[styles.ambientPlum, styles.pointerNone]} />
      <SafeAreaView style={styles.safe} edges={["top", "left", "right"]}>
        {scroll ? (
          <ScrollView
            contentInsetAdjustmentBehavior="automatic"
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
            contentContainerStyle={styles.scroll}
          >
            {content}
          </ScrollView>
        ) : content}
      </SafeAreaView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.canvas, overflow: "hidden" },
  safe: { flex: 1 },
  scroll: { flexGrow: 1 },
  content: { flex: 1, paddingHorizontal: spacing.xl, paddingTop: spacing.lg, gap: spacing.xl },
  bottomInset: { paddingBottom: 118 },
  ambientRose: {
    position: "absolute",
    width: 220,
    height: 220,
    borderRadius: 220,
    backgroundColor: colors.roseWash,
    top: -150,
    right: -120
  },
  ambientPlum: {
    position: "absolute",
    width: 180,
    height: 180,
    borderRadius: 180,
    backgroundColor: colors.plumWash,
    bottom: 80,
    left: -140
  },
  pointerNone: { pointerEvents: "none" }
});
