import { PropsWithChildren, ReactNode } from "react";
import { RefreshControl, ScrollView, StyleProp, StyleSheet, View, ViewStyle } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { colors, layout, spacing } from "@/theme";

export function Screen({
  children,
  scroll = true,
  contentStyle,
  bottomInset = true,
  footer,
  refreshing,
  onRefresh,
  tabbed = false
}: PropsWithChildren<{
  scroll?: boolean;
  contentStyle?: StyleProp<ViewStyle>;
  bottomInset?: boolean;
  /** Pinned bottom action area (thumb zone), e.g. a primary CTA. */
  footer?: ReactNode;
  refreshing?: boolean;
  onRefresh?: () => void;
  /** Leaves room for the floating tab bar. */
  tabbed?: boolean;
}>) {
  const content = (
    <View style={[styles.content, bottomInset && styles.bottomInset, tabbed && styles.tabbed, contentStyle]}>{children}</View>
  );

  return (
    <View style={styles.root}>
      <StatusBar style="dark" />
      <SafeAreaView style={styles.safe} edges={footer ? ["top", "left", "right", "bottom"] : ["top", "left", "right"]}>
        {scroll ? (
          <ScrollView
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
            contentContainerStyle={styles.scroll}
            refreshControl={onRefresh ? <RefreshControl refreshing={Boolean(refreshing)} onRefresh={onRefresh} tintColor={colors.muted} /> : undefined}
          >
            {content}
          </ScrollView>
        ) : content}
        {footer ? <View style={styles.footer}>{footer}</View> : null}
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.canvas },
  safe: { flex: 1 },
  scroll: { flexGrow: 1 },
  content: { flex: 1, paddingHorizontal: layout.gutter, paddingTop: spacing.sm, gap: spacing.xxl },
  bottomInset: { paddingBottom: spacing.xxxl },
  tabbed: { paddingBottom: 120 },
  footer: { paddingHorizontal: layout.gutter, paddingTop: spacing.md, paddingBottom: spacing.sm, gap: spacing.sm, backgroundColor: colors.canvas, borderTopWidth: 1, borderColor: colors.stroke }
});
