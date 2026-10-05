import { useEffect } from "react";
import { StyleSheet, View } from "react-native";
import { StatusBar } from "expo-status-bar";
import { LinearGradient } from "expo-linear-gradient";
import Animated, {
  Easing,
  FadeIn,
  interpolate,
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withDelay,
  withTiming,
  type SharedValue
} from "react-native-reanimated";
import { scheduleOnRN } from "react-native-worklets";
import { Em, Title } from "@/components/AppText";
import { AnimatedLogoMark } from "@/components/Logo";
import { SETTLE } from "@/components/motion";
import { colors, fonts } from "@/theme";

const WORD = "FLAIRWISE".split("");

/**
 * Branded boot: the wordmark rises letter by letter, a volt scan line sweeps
 * across it (the same beam as the fitting room), then the stage lifts away.
 * `ready` = app state is hydrated; the splash holds until then, then exits.
 */
export function BootSplash({ ready, onDone }: { ready: boolean; onDone: () => void }) {
  const reduced = useReducedMotion();
  const intro = useSharedValue(0);
  const scan = useSharedValue(0);
  const exit = useSharedValue(0);

  useEffect(() => {
    if (reduced) { intro.value = 1; return; }
    intro.value = withTiming(1, { duration: 900, easing: SETTLE });
    scan.value = withDelay(500, withTiming(1, { duration: 750, easing: Easing.inOut(Easing.cubic) }));
  }, [reduced, intro, scan]);

  useEffect(() => {
    if (!ready) return;
    const wait = reduced ? 150 : 1450;
    const timer = setTimeout(() => {
      exit.value = withTiming(1, { duration: reduced ? 150 : 520, easing: Easing.in(Easing.cubic) }, (finished) => { if (finished) scheduleOnRN(onDone); });
    }, wait);
    return () => clearTimeout(timer);
  }, [ready, reduced, exit, onDone]);

  const root = useAnimatedStyle(() => ({ opacity: interpolate(exit.value, [0, 0.4, 1], [1, 1, 0]) }));
  const lockup = useAnimatedStyle(() => ({ transform: [{ scale: interpolate(exit.value, [0, 1], [1, 1.08]) }, { translateY: interpolate(exit.value, [0, 1], [0, -20]) }] }));
  const beam = useAnimatedStyle(() => ({ opacity: interpolate(scan.value, [0, 0.08, 0.9, 1], [0, 1, 1, 0]), transform: [{ translateX: interpolate(scan.value, [0, 1], [-170, 170]) }] }));
  const tag = useAnimatedStyle(() => ({ opacity: interpolate(scan.value, [0.6, 1], [0, 1], "clamp"), transform: [{ translateY: interpolate(scan.value, [0.6, 1], [8, 0], "clamp") }] }));

  return (
    <Animated.View style={[styles.root, root]} accessibilityLabel="Flairwise is loading" accessible>
      <StatusBar style="light" />
      <LinearGradient colors={["#1B1B21", colors.stage, colors.stage]} style={StyleSheet.absoluteFill} />
      <Animated.View style={[styles.lockup, lockup]}>
        <AnimatedLogoMark size={112} />
        <View style={styles.wordRow}>
          {WORD.map((letter, i) => <Letter key={i} letter={letter} index={i} intro={intro} reduced={reduced} />)}
          <Animated.View pointerEvents="none" style={[styles.beam, beam]}>
            <LinearGradient start={{ x: 0, y: 0.5 }} end={{ x: 1, y: 0.5 }} colors={["rgba(212,255,58,0)", "rgba(212,255,58,0.35)", "rgba(212,255,58,0)"]} style={StyleSheet.absoluteFill} />
            <View style={styles.beamLine} />
          </Animated.View>
        </View>
        <Animated.View style={tag}>
          <Title style={styles.tagline}>Your closet, <Em style={styles.taglineEm}>on you.</Em></Title>
        </Animated.View>
      </Animated.View>
      <Animated.View entering={FadeIn.delay(reduced ? 0 : 900)} style={styles.foot}>
        <View style={styles.footDot} />
      </Animated.View>
    </Animated.View>
  );
}

function Letter({ letter, index, intro, reduced }: { letter: string; index: number; intro: SharedValue<number>; reduced: boolean }) {
  const start = index * 0.07;
  const style = useAnimatedStyle(() => {
    const p = reduced ? 1 : interpolate(intro.value, [start, start + 0.45], [0, 1], "clamp");
    return { opacity: p, transform: [{ translateY: (1 - p) * 26 }] };
  });
  // "WISE" carries the volt — your flair, made wise by the AI stylist.
  return <Animated.Text allowFontScaling={false} style={[styles.letter, index >= 5 && styles.letterVolt, style]}>{letter}</Animated.Text>;
}

/** Plain stage shown for the few frames before fonts are ready. */
export function BootBlank() {
  return <View style={styles.root}><StatusBar style="light" /></View>;
}

const styles = StyleSheet.create({
  root: { ...StyleSheet.absoluteFill, backgroundColor: colors.stage, alignItems: "center", justifyContent: "center", zIndex: 100 },
  lockup: { alignItems: "center", gap: 14 },
  wordRow: { flexDirection: "row", overflow: "hidden", paddingVertical: 4, paddingHorizontal: 6 },
  letter: { fontFamily: fonts.punch, fontSize: 40, lineHeight: 46, letterSpacing: 1.5, color: colors.onStage },
  letterVolt: { color: colors.accent },
  beam: { position: "absolute", top: 0, bottom: 0, left: "50%", width: 80, marginLeft: -40, alignItems: "center" },
  beamLine: { position: "absolute", top: 0, bottom: 0, width: 2, backgroundColor: colors.accent, boxShadow: "0 0 14px rgba(212,255,58,0.95)" },
  tagline: { color: colors.onStageMuted, fontSize: 24, lineHeight: 28, textAlign: "center" },
  taglineEm: { color: colors.onStage },
  foot: { position: "absolute", bottom: 56 },
  footDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: colors.accent }
});
