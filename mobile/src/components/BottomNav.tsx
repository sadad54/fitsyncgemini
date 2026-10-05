import { useEffect, useState } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import { router, usePathname } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import * as Haptics from "expo-haptics";
import Animated, { useAnimatedStyle, useSharedValue, withSpring } from "react-native-reanimated";
import { Compass, House, Images, Shirt, Sparkles, type LucideIcon } from "lucide-react-native";
import { AppText } from "@/components/AppText";
import { PressableScale, SPRING } from "@/components/motion";
import { colors, fonts, radius } from "@/theme";

type Tab = { href: string; label: string; icon: LucideIcon };
const LEFT: Tab[] = [
  { href: "/today", label: "Today", icon: House },
  { href: "/closet", label: "Closet", icon: Shirt }
];
const RIGHT: Tab[] = [
  { href: "/looks", label: "Looks", icon: Images },
  { href: "/discover", label: "Discover", icon: Compass }
];
// Slot order across the bar; index 2 is the centre action.
const SLOTS = [...LEFT, null, ...RIGHT];

export function BottomNav() {
  const pathname = usePathname();
  const insets = useSafeAreaInsets();
  const [width, setWidth] = useState(0);
  const activeIndex = SLOTS.findIndex((tab) => tab && pathname.startsWith(tab.href));
  const slot = width / SLOTS.length;
  const x = useSharedValue(0);

  useEffect(() => {
    if (slot && activeIndex >= 0) x.value = withSpring(activeIndex * slot, SPRING);
  }, [activeIndex, slot, x]);

  const indicator = useAnimatedStyle(() => ({ transform: [{ translateX: x.value }], opacity: activeIndex >= 0 ? 1 : 0 }));

  return (
    <View pointerEvents="box-none" style={[styles.wrap, { paddingBottom: Math.max(insets.bottom, 12) }]}>
      <View style={styles.bar} accessibilityRole="tablist" onLayout={(e) => setWidth(e.nativeEvent.layout.width - 12)}>
        {slot ? <Animated.View style={[styles.indicator, { width: slot }, indicator]}><View style={styles.indicatorPill} /></Animated.View> : null}
        {SLOTS.map((tab, index) => tab
          ? <TabButton key={tab.href} tab={tab} active={index === activeIndex} />
          : <StyleMeButton key="style" />)}
      </View>
    </View>
  );
}

function TabButton({ tab, active }: { tab: Tab; active: boolean }) {
  const Icon = tab.icon;
  return (
    <Pressable
      accessibilityRole="tab"
      accessibilityLabel={tab.label}
      accessibilityState={{ selected: active }}
      onPress={() => {
        if (active) return;
        if (process.env.EXPO_OS !== "web") Haptics.selectionAsync();
        router.navigate(tab.href as never);
      }}
      style={styles.item}
    >
      <Icon size={21} color={active ? colors.ink : colors.muted} strokeWidth={active ? 2.2 : 1.8} />
      <AppText style={[styles.label, active && styles.activeLabel]}>{tab.label}</AppText>
    </Pressable>
  );
}

function StyleMeButton() {
  return (
    <View style={styles.item}>
      <PressableScale
        accessibilityRole="button"
        accessibilityLabel="Style me"
        accessibilityHint="Create an outfit from your closet and see it on you"
        scaleTo={0.9}
        onPress={() => {
          if (process.env.EXPO_OS !== "web") Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
          router.push("/style");
        }}
        style={styles.fab}
      >
        <Sparkles size={22} color={colors.onAccent} strokeWidth={2} />
      </PressableScale>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { position: "absolute", left: 0, right: 0, bottom: 0, paddingHorizontal: 14 },
  bar: {
    flexDirection: "row", alignItems: "center", height: 68, paddingHorizontal: 6, borderRadius: radius.pill,
    backgroundColor: "rgba(255,255,255,0.96)", borderWidth: 1, borderColor: colors.stroke,
    boxShadow: "0 10px 30px rgba(23,20,15,0.12), 0 1px 2px rgba(23,20,15,0.06)"
  },
  indicator: { position: "absolute", left: 6, top: 6, bottom: 6, paddingHorizontal: 4 },
  indicatorPill: { flex: 1, borderRadius: radius.pill, backgroundColor: colors.canvas },
  item: { flex: 1, minHeight: 56, alignItems: "center", justifyContent: "center", gap: 3 },
  label: { color: colors.muted, fontSize: 11, lineHeight: 13, fontFamily: fonts.medium, fontWeight: "500" },
  activeLabel: { color: colors.ink, fontFamily: fonts.semibold, fontWeight: "600" },
  fab: {
    width: 56, height: 56, borderRadius: 28, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center",
    marginTop: -26, borderWidth: 4, borderColor: colors.canvas, boxShadow: "0 10px 24px rgba(46,68,214,0.38)"
  }
});
