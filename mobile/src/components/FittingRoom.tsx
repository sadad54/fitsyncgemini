import { useEffect, useRef, useState } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import Animated, {
  Easing,
  FadeIn,
  FadeInDown,
  FadeOut,
  FadeOutUp,
  cancelAnimation,
  interpolate,
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withDelay,
  withRepeat,
  withSequence,
  withSpring,
  withTiming,
  type SharedValue
} from "react-native-reanimated";
import { AppText, Punch } from "@/components/AppText";
import { Photo } from "@/components/Photo";
import { POP, PulseDot, SETTLE, haptic } from "@/components/motion";
import { colors, fonts, radius, spacing } from "@/theme";

const PHASES = ["Reading your pose", "Mapping the garment", "Draping the fabric", "Matching the light", "Finishing details"];
const GRID_LINES = 9;

/**
 * The try-on stage — the product's hero moment. Three states, one surface:
 *  - idle:      the person photo inside a volt viewfinder
 *  - fitting:   a volt scan beam sweeps a measuring grid while status copy cycles
 *  - revealed:  the result wipes down over the original like falling fabric,
 *               a short volt burst and an "ON YOU" stamp land; press and hold
 *               to compare with the original.
 */
export function FittingRoom({
  personUri,
  resultUri,
  working,
  status,
  placeholder
}: {
  personUri?: string | null;
  resultUri?: string | null;
  working: boolean;
  status?: string;
  placeholder?: React.ReactNode;
}) {
  const reduced = useReducedMotion();
  const [height, setHeight] = useState(0);
  const [holding, setHolding] = useState(false);
  const [celebrate, setCelebrate] = useState(0);
  const reveal = useSharedValue(resultUri ? 1 : 0);
  const scan = useSharedValue(0);
  const frame = useSharedValue(working ? 1 : 0);
  const revealedFor = useRef<string | null>(resultUri ?? null);
  const sawWorking = useRef(false);
  // Only a job we saw queued/processing counts — not the brief loading state when reopening one.
  if (working && (status === "queued" || status === "processing")) sawWorking.current = true;

  // Scan loop + viewfinder tighten while the job runs.
  useEffect(() => {
    frame.value = withTiming(working ? 1 : 0, { duration: 600, easing: SETTLE });
    if (working && !reduced) {
      scan.value = 0;
      scan.value = withRepeat(withSequence(
        withTiming(1, { duration: 2000, easing: Easing.inOut(Easing.cubic) }),
        withTiming(0, { duration: 2000, easing: Easing.inOut(Easing.cubic) })
      ), -1);
    } else {
      cancelAnimation(scan);
    }
  }, [working, reduced, scan, frame]);

  // Reveal wipe + celebration when a new result arrives (not when reopening an old one).
  useEffect(() => {
    if (!resultUri) { reveal.value = 0; revealedFor.current = null; return; }
    if (revealedFor.current === resultUri) return;
    revealedFor.current = resultUri;
    reveal.value = 0;
    reveal.value = withTiming(1, { duration: reduced ? 0 : 1400, easing: SETTLE });
    // Only celebrate a result we watched being made, not one reopened from Looks.
    if (!sawWorking.current) return;
    const timer = setTimeout(() => { haptic.success(); setCelebrate((n) => n + 1); }, reduced ? 0 : 1150);
    return () => clearTimeout(timer);
  }, [resultUri, reduced, reveal]);

  const scanStyle = useAnimatedStyle(() => ({ transform: [{ translateY: interpolate(scan.value, [0, 1], [-60, height - 30]) }] }));
  const revealStyle = useAnimatedStyle(() => ({ height: reveal.value * height }));
  const edgeStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: reveal.value * height - 2 }],
    opacity: interpolate(reveal.value, [0, 0.04, 0.92, 1], [0, 1, 1, 0])
  }));
  const hasImage = Boolean(personUri || resultUri);
  const showFrame = hasImage && !resultUri;

  return (
    <Pressable
      accessibilityRole="image"
      accessibilityLabel={resultUri ? "Try-on result. Press and hold to see your original photo." : working ? "Fitting the outfit onto your photo" : "Your try-on photo"}
      disabled={!resultUri}
      onPressIn={() => resultUri && setHolding(true)}
      onPressOut={() => setHolding(false)}
      style={styles.stage}
      onLayout={(e) => setHeight(e.nativeEvent.layout.height)}
    >
      {hasImage ? (
        <>
          {personUri ? <Photo source={personUri} transition={0} /> : null}
          {resultUri ? (
            <Animated.View style={[styles.revealMask, revealStyle, holding && styles.hidden]}>
              <View style={{ height }}>
                <Photo source={resultUri} transition={0} />
              </View>
            </Animated.View>
          ) : null}
          {resultUri ? (
            <Animated.View pointerEvents="none" style={[styles.revealEdge, edgeStyle]}>
              <LinearGradient colors={["rgba(212,255,58,0)", "rgba(212,255,58,0.55)"]} style={styles.edgeGlow} />
              <View style={styles.edgeLine} />
            </Animated.View>
          ) : null}
        </>
      ) : placeholder}

      {working ? (
        <Animated.View entering={FadeIn.duration(300)} exiting={FadeOut.duration(500)} pointerEvents="none" style={StyleSheet.absoluteFill}>
          <View style={styles.veil} />
          <Grid />
          <Animated.View style={[styles.scan, scanStyle]}>
            <LinearGradient colors={["rgba(212,255,58,0)", "rgba(212,255,58,0.32)", "rgba(212,255,58,0)"]} style={StyleSheet.absoluteFill} />
            <View style={styles.scanLine} />
          </Animated.View>
          <StatusPill status={status} />
        </Animated.View>
      ) : null}

      {showFrame ? <Viewfinder frame={frame} /> : null}

      {resultUri && !working ? (
        <>
          <Animated.View entering={reduced ? FadeIn : FadeIn.delay(1200).duration(400)} pointerEvents="none" style={styles.compare}>
            <AppText style={styles.compareText}>{holding ? "Original" : "Hold to compare"}</AppText>
          </Animated.View>
          {celebrate ? <Stamp key={`stamp-${celebrate}`} /> : null}
          {celebrate && !reduced ? <Burst key={`burst-${celebrate}`} /> : null}
        </>
      ) : null}
    </Pressable>
  );
}

/** Four volt corner brackets; they draw in tighter while fitting. */
function Viewfinder({ frame }: { frame: SharedValue<number> }) {
  const inset = useAnimatedStyle(() => {
    const d = interpolate(frame.value, [0, 1], [14, 22]);
    return { top: d, left: d, right: d, bottom: d };
  });
  return (
    <Animated.View pointerEvents="none" style={[styles.finder, inset]}>
      <View style={[styles.corner, styles.tl]} />
      <View style={[styles.corner, styles.tr]} />
      <View style={[styles.corner, styles.bl]} />
      <View style={[styles.corner, styles.br]} />
    </Animated.View>
  );
}

function Grid() {
  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      {Array.from({ length: GRID_LINES }).map((_, i) => (
        <View key={`h${i}`} style={[styles.gridH, { top: `${((i + 1) / (GRID_LINES + 1)) * 100}%` }]} />
      ))}
      {[1, 2, 3].map((i) => <View key={`v${i}`} style={[styles.gridV, { left: `${i * 25}%` }]} />)}
    </View>
  );
}

function StatusPill({ status }: { status?: string }) {
  const [phase, setPhase] = useState(0);
  const [seconds, setSeconds] = useState(0);
  useEffect(() => {
    const cycle = setInterval(() => setPhase((p) => (p + 1) % PHASES.length), 2600);
    const clock = setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => { clearInterval(cycle); clearInterval(clock); };
  }, []);
  const label = status === "queued" ? "In the queue" : PHASES[phase];
  return (
    <View style={styles.pillWrap}>
      <View style={styles.pill} accessibilityLiveRegion="polite">
        <PulseDot />
        <Animated.View key={label} entering={FadeInDown.duration(320)} exiting={FadeOutUp.duration(220)} style={styles.pillCopy}>
          <AppText numberOfLines={1} style={styles.pillText}>{label}…</AppText>
        </Animated.View>
        <AppText style={styles.pillTime}>{seconds}s</AppText>
      </View>
      <AppText style={styles.pillHint}>Usually 30–60 seconds</AppText>
    </View>
  );
}

/** "ON YOU" label-maker stamp that pops onto the result. */
function Stamp() {
  const t = useSharedValue(0);
  useEffect(() => { t.value = withSpring(1, POP); }, [t]);
  const style = useAnimatedStyle(() => ({
    opacity: Math.min(1, t.value * 2),
    transform: [{ scale: interpolate(t.value, [0, 1], [1.6, 1]) }, { rotate: `${interpolate(t.value, [0, 1], [-14, -6])}deg` }]
  }));
  return (
    <Animated.View pointerEvents="none" style={[styles.stamp, style]}>
      <Punch style={styles.stampText}>On you</Punch>
    </Animated.View>
  );
}

const PARTICLES = Array.from({ length: 18 }, (_, i) => {
  const angle = (i / 18) * Math.PI * 2 + (i % 2 ? 0.17 : -0.11);
  const dist = 90 + ((i * 37) % 70);
  return { dx: Math.cos(angle) * dist, dy: Math.sin(angle) * dist - 30, size: 5 + (i % 3) * 3, volt: i % 3 !== 2, delay: (i % 4) * 30, spin: (i % 2 ? 1 : -1) * (90 + i * 10) };
});

/** A short, light confetti burst — 18 views, one shared clock, ~1s. */
function Burst() {
  const t = useSharedValue(0);
  useEffect(() => { t.value = withTiming(1, { duration: 1100, easing: Easing.out(Easing.cubic) }); }, [t]);
  return (
    <View pointerEvents="none" style={styles.burst}>
      {PARTICLES.map((p, i) => <Particle key={i} t={t} {...p} />)}
    </View>
  );
}

function Particle({ t, dx, dy, size, volt, spin }: { t: SharedValue<number>; dx: number; dy: number; size: number; volt: boolean; delay: number; spin: number }) {
  const style = useAnimatedStyle(() => {
    const p = t.value;
    return {
      opacity: interpolate(p, [0, 0.1, 0.7, 1], [0, 1, 1, 0]),
      transform: [
        { translateX: dx * p },
        { translateY: dy * p + 60 * p * p },
        { rotate: `${spin * p}deg` },
        { scale: interpolate(p, [0, 0.2, 1], [0.2, 1, 0.6]) }
      ]
    };
  });
  return <Animated.View style={[styles.particle, { width: size, height: size * (volt ? 1 : 2.2), backgroundColor: volt ? colors.accent : colors.white }, style]} />;
}

// Export for reuse on other "done" moments.
export { Burst as SuccessBurst };

const C = 26;
const styles = StyleSheet.create({
  stage: { width: "100%", aspectRatio: 3 / 4, borderRadius: radius.xl, overflow: "hidden", backgroundColor: colors.stageRaised },
  revealMask: { position: "absolute", left: 0, right: 0, top: 0, overflow: "hidden" },
  revealEdge: { position: "absolute", left: 0, right: 0, top: -40, height: 42 },
  edgeGlow: { flex: 1 },
  edgeLine: { height: 3, backgroundColor: colors.accent, boxShadow: "0 0 18px rgba(212,255,58,0.95)" },
  hidden: { opacity: 0 },
  veil: { ...StyleSheet.absoluteFill, backgroundColor: "rgba(13,13,15,0.38)" },
  gridH: { position: "absolute", left: 0, right: 0, height: StyleSheet.hairlineWidth, backgroundColor: "rgba(212,255,58,0.16)" },
  gridV: { position: "absolute", top: 0, bottom: 0, width: StyleSheet.hairlineWidth, backgroundColor: "rgba(212,255,58,0.12)" },
  scan: { position: "absolute", left: 0, right: 0, height: 90 },
  scanLine: { position: "absolute", left: 0, right: 0, top: 44, height: 2, backgroundColor: colors.accent, boxShadow: "0 0 16px rgba(212,255,58,0.95)" },
  finder: { position: "absolute" },
  corner: { position: "absolute", width: C, height: C, borderColor: colors.accent },
  tl: { top: 0, left: 0, borderTopWidth: 3, borderLeftWidth: 3, borderTopLeftRadius: 10 },
  tr: { top: 0, right: 0, borderTopWidth: 3, borderRightWidth: 3, borderTopRightRadius: 10 },
  bl: { bottom: 0, left: 0, borderBottomWidth: 3, borderLeftWidth: 3, borderBottomLeftRadius: 10 },
  br: { bottom: 0, right: 0, borderBottomWidth: 3, borderRightWidth: 3, borderBottomRightRadius: 10 },
  pillWrap: { position: "absolute", left: spacing.lg, right: spacing.lg, bottom: spacing.xxl, alignItems: "center", gap: 6 },
  pill: {
    flexDirection: "row", alignItems: "center", gap: spacing.sm, paddingHorizontal: spacing.lg, height: 44, borderRadius: radius.pill,
    backgroundColor: "rgba(13,13,15,0.82)", borderWidth: 1, borderColor: "rgba(212,255,58,0.35)", maxWidth: "100%"
  },
  pillCopy: { flexShrink: 1 },
  pillText: { fontSize: 14, color: colors.onStage, fontFamily: fonts.medium, fontWeight: "500" },
  pillTime: { fontSize: 13, color: colors.accent, fontVariant: ["tabular-nums"], fontFamily: fonts.semibold },
  pillHint: { fontSize: 12, color: colors.onStage, opacity: 0.8, textShadowColor: "rgba(0,0,0,0.6)", textShadowRadius: 6 },
  compare: { position: "absolute", bottom: spacing.md, alignSelf: "center", paddingHorizontal: spacing.md, height: 32, borderRadius: radius.pill, backgroundColor: "rgba(13,13,15,0.72)", justifyContent: "center" },
  compareText: { color: colors.onStage, fontSize: 12, fontFamily: fonts.medium },
  stamp: { position: "absolute", top: spacing.lg, left: spacing.lg, backgroundColor: colors.accent, paddingHorizontal: 12, paddingVertical: 7, borderRadius: 6, borderWidth: 2, borderColor: colors.ink },
  stampText: { fontSize: 14, lineHeight: 17, letterSpacing: 2 },
  burst: { position: "absolute", top: "42%", left: "50%", width: 0, height: 0 },
  particle: { position: "absolute", borderRadius: 2 }
});
