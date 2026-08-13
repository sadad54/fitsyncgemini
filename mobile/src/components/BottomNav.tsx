import { Link, usePathname } from "expo-router";
import { Pressable, StyleSheet, View } from "react-native";
import { BlurView } from "expo-blur";
import * as Haptics from "expo-haptics";
import { Ionicons } from "@expo/vector-icons";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { AppText } from "@/components/AppText";
import { colors, radius, shadows, spacing } from "@/theme";

const tabs = [
  { href: "/home", label: "Home", icon: "home-outline", activeIcon: "home" },
  { href: "/closet", label: "Closet", icon: "shirt-outline", activeIcon: "shirt" },
  { href: "/generate", label: "Style", icon: "sparkles-outline", activeIcon: "sparkles" },
  { href: "/saved", label: "Looks", icon: "bookmark-outline", activeIcon: "bookmark" },
  { href: "/profile", label: "You", icon: "person-outline", activeIcon: "person" }
] as const;

export function BottomNav() {
  const pathname = usePathname();
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.positioner, styles.pointerBoxNone, { bottom: Math.max(insets.bottom, spacing.md) }]}>
      <BlurView intensity={45} tint="light" style={styles.rail}>
        {tabs.map((tab) => {
          const active = pathname === tab.href;
          return (
            <Link key={tab.href} href={tab.href} asChild>
              <Pressable
                accessibilityRole="tab"
                accessibilityLabel={tab.label}
                accessibilityState={{ selected: active }}
                onPressIn={() => process.env.EXPO_OS === "ios" && Haptics.selectionAsync()}
                style={({ pressed }) => [styles.item, active && styles.itemActive, pressed && styles.pressed]}
              >
                <Ionicons name={active ? tab.activeIcon : tab.icon} size={21} color={active ? colors.roseSoft : colors.muted} />
                <AppText style={[styles.label, active && styles.activeLabel]}>{tab.label}</AppText>
              </Pressable>
            </Link>
          );
        })}
      </BlurView>
    </View>
  );
}

const styles = StyleSheet.create({
  positioner: { position: "absolute", left: spacing.lg, right: spacing.lg, zIndex: 100 },
  pointerBoxNone: { pointerEvents: "box-none" },
  rail: {
    minHeight: 70,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    borderRadius: radius.xl,
    borderCurve: "continuous",
    borderWidth: 1,
    borderColor: colors.strokeStrong,
    overflow: "hidden",
    padding: spacing.sm,
    backgroundColor: "rgba(255, 255, 255, 0.84)",
    boxShadow: shadows.floating
  },
  item: { flex: 1, minHeight: 52, minWidth: 54, borderRadius: radius.lg, alignItems: "center", justifyContent: "center", gap: spacing.xxs },
  itemActive: { backgroundColor: colors.roseWash },
  pressed: { opacity: 0.68 },
  label: { color: colors.muted, fontSize: 11, lineHeight: 14, fontWeight: "700" },
  activeLabel: { color: colors.roseSoft }
});
