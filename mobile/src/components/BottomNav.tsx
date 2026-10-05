import { useEffect, useState } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import { router, usePathname } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Animated, { Easing, interpolate, useAnimatedStyle, useReducedMotion, useSharedValue, withRepeat, withSpring, withTiming } from "react-native-reanimated";
import { Compass, House, Images, Shirt, type LucideIcon } from "@/icons";
import { BrandSpark } from "@/components/Logo";
import { AppText } from "@/components/AppText";
import { PressableScale, SPRING, haptic } from "@/components/motion";
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
const PAD = 6;

/** Floating ink dock. The volt centre button is the product's core loop: Style me. */
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
    <View pointerEvents="box-none" style={[styles.wrap, { paddingBottom: Math.max(insets.bottom - 6, 12) }]}>
      <View style={styles.bar} accessibilityRole="tablist" onLayout={(e) => setWidth(e.nativeEvent.layout.width - PAD * 2)}>
        {slot ? (
          <Animated.View pointerEvents="none" style={[styles.indicator, { width: slot }, indicator]}>
            <View style={styles.indicatorPill} />
          </Animated.View>
        ) : null}
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
        haptic.tick();
        router.navigate(tab.href as never);
      }}
      style={styles.item}
    >
      <Icon size={21} color={active ? colors.accent : colors.onStageMuted} strokeWidth={active ? 2.3 : 1.8} />
      <AppText maxFontSizeMultiplier={1.2} style={[styles.label, active && styles.activeLabel]}>{tab.label}</AppText>
    </Pressable>
  );
}

function StyleMeButton() {
  const reduced = useReducedMotion();
  const glow = useSharedValue(0);
  useEffect(() => {
    if (!reduced) glow.value = withRepeat(withTiming(1, { duration: 2200, easing: Easing.inOut(Easing.sin) }), -1, true);
  }, [reduced, glow]);
  const halo = useAnimatedStyle(() => ({ opacity: interpolate(glow.value, [0, 1], [0.25, 0.6]), transform: [{ scale: interpolate(glow.value, [0, 1], [1, 1.14]) }] }));
  return (
    <View style={styles.item}>
      <Animated.View pointerEvents="none" style={[styles.halo, halo]} />
      <PressableScale
        accessibilityRole="button"
        accessibilityLabel="Style me"
        accessibilityHint="Create an outfit from your closet and see it on you"
        haptic={false}
        scaleTo={0.88}
        onPress={() => {
          haptic.thud();
          router.push("/style");
        }}
        style={styles.fab}
      >
        <BrandSpark size={26} color={colors.onAccent} />
      </PressableScale>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { position: "absolute", left: 0, right: 0, bottom: 0, paddingHorizontal: 16 },
  bar: {
    flexDirection: "row", alignItems: "center", height: 70, paddingHorizontal: PAD, borderRadius: radius.pill,
    backgroundColor: colors.stage, borderWidth: 1, borderColor: "rgba(255,255,255,0.06)",
    boxShadow: "0 16px 40px rgba(13,13,15,0.35), 0 2px 6px rgba(13,13,15,0.2)"
  },
  indicator: { position: "absolute", left: PAD, top: 7, bottom: 7, paddingHorizontal: 5 },
  indicatorPill: { flex: 1, borderRadius: radius.pill, backgroundColor: colors.stageRaised },
  item: { flex: 1, minHeight: 56, alignItems: "center", justifyContent: "center", gap: 3 },
  label: { color: colors.onStageMuted, fontSize: 11, lineHeight: 13, fontFamily: fonts.medium, fontWeight: "500" },
  activeLabel: { color: colors.onStage, fontFamily: fonts.semibold, fontWeight: "600" },
  halo: { position: "absolute", top: -20, width: 66, height: 66, borderRadius: 33, backgroundColor: colors.accent },
  fab: {
    width: 60, height: 60, borderRadius: 30, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center",
    marginTop: -30, borderWidth: 4, borderColor: colors.stage
  }
});
