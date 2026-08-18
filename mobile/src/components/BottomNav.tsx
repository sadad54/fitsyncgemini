import { Link, usePathname } from "expo-router";
import { Pressable, StyleSheet, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { AppText } from "@/components/AppText";
import { Glyph } from "@/components/Glyph";
import { colors, fonts, spacing } from "@/theme";

const tabs = [
  { href: "/home", label: "Home", shape: "square" },
  { href: "/closet", label: "Closet", shape: "moonDown" },
  { href: "/generate", label: "Style", shape: "circle" },
  { href: "/saved", label: "Looks", shape: "diamond" },
  { href: "/profile", label: "You", shape: "moonUp" }
] as const;

export function BottomNav() {
  const pathname = usePathname();
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.rail, { paddingBottom: Math.max(insets.bottom, spacing.md) }]}>
      {tabs.map((tab) => {
        const active = pathname === tab.href;
        return (
          <Link key={tab.href} href={tab.href} asChild>
            <Pressable accessibilityRole="tab" accessibilityLabel={tab.label} accessibilityState={{ selected: active }} style={styles.item}>
              <View style={[styles.bar, active && styles.barActive]} />
              <Glyph shape={tab.shape} size={17} strokeWidth={2} color={active ? colors.rose : colors.muted} />
              <AppText style={[styles.label, active && styles.activeLabel]}>{tab.label}</AppText>
            </Pressable>
          </Link>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  rail: {
    flexDirection: "row",
    backgroundColor: colors.canvas,
    borderTopWidth: 2,
    borderTopColor: colors.strokeStrong
  },
  item: { flex: 1, minHeight: 52, alignItems: "center", justifyContent: "center", gap: spacing.xs, paddingTop: spacing.md },
  bar: { position: "absolute", top: -2, left: 0, right: 0, height: 3, backgroundColor: "transparent" },
  barActive: { backgroundColor: colors.rose },
  label: { color: colors.muted, fontSize: 8, lineHeight: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  activeLabel: { color: colors.rose }
});
