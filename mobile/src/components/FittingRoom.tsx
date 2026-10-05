import { useEffect, useRef, useState } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import * as Haptics from "expo-haptics";
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
  withRepeat,
  withSequence,
  withTiming
} from "react-native-reanimated";
import { Sparkles } from "lucide-react-native";
import { AppText } from "@/components/AppText";
import { Photo } from "@/components/Photo";
import { SETTLE } from "@/components/motion";
import { colors, fonts, radius, spacing } from "@/theme";

const PHASES = ["Reading your pose", "Mapping the garment", "Draping the fabric", "Matching the light", "Finishing details"];

/**
 * The try-on stage. Three states, one surface:
 *  - idle:      the person photo
 *  - fitting:   a cobalt scan line sweeps the photo while status copy cycles
 *  - revealed:  the result wipes down over the original like falling fabric;
 *               press and hold to compare with the original.
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
  const reveal = useSharedValue(resultUri ? 1 : 0);
  const scan = useSharedValue(0);
  const revealedFor = useRef<string | null>(resultUri ?? null);

  // Scan line loop while the job runs.
  useEffect(() => {
    if (working && !reduced) {
      scan.value = 0;
      scan.value = withRepeat(withSequence(
        withTiming(1, { duration: 1900, easing: Easing.inOut(Easing.cubic) }),
        withTiming(0, { duration: 1900, easing: Easing.inOut(Easing.cubic) })
      ), -1);
    } else {
      cancelAnimation(scan);
    }
  }, [working, reduced, scan]);

  // Reveal wipe when a new result arrives.
  useEffect(() => {
    if (!resultUri) { reveal.value = 0; revealedFor.current = null; return; }
    if (revealedFor.current === resultUri) return;
    revealedFor.current = resultUri;
    reveal.value = 0;
    reveal.value = withTiming(1, { duration: reduced ? 0 : 1300, easing: SETTLE });
    if (process.env.EXPO_OS !== "web") Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  }, [resultUri, reduced, reveal]);

  const scanStyle = useAnimatedStyle(() => ({ transform: [{ translateY: interpolate(scan.value, [0, 1], [-40, height]) }] }));
  const revealStyle = useAnimatedStyle(() => ({ height: reveal.value * height }));
  const edgeStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: reveal.value * height - 2 }],
    opacity: interpolate(reveal.value, [0, 0.05, 0.9, 1], [0, 1, 1, 0])
  }));

  const hasImage = Boolean(personUri || resultUri);

  return (
    <Pressable
      accessibilityRole="image"
      accessibilityLabel={resultUri ? "Try-on result. Press and hold to see your original photo." : "Your try-on photo"}
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
          {resultUri ? <Animated.View pointerEvents="none" style={[styles.revealEdge, edgeStyle]} /> : null}
        </>
      ) : placeholder}

      {working ? (
        <Animated.View entering={FadeIn.duration(300)} exiting={FadeOut.duration(400)} pointerEvents="none" style={StyleSheet.absoluteFill}>
          <View style={styles.veil} />
          <Animated.View style={[styles.scan, scanStyle]}>
            <LinearGradient colors={["rgba(46,68,214,0)", "rgba(46,68,214,0.35)", "rgba(46,68,214,0)"]} style={StyleSheet.absoluteFill} />
            <View style={styles.scanLine} />
          </Animated.View>
          <StatusPill status={status} />
        </Animated.View>
      ) : null}

      {resultUri && !working ? (
        <Animated.View entering={FadeIn.delay(1100).duration(400)} pointerEvents="none" style={styles.tag}>
          <AppText style={styles.tagText}>{holding ? "Original" : "Hold to compare"}</AppText>
        </Animated.View>
      ) : null}
    </Pressable>
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
      <View style={styles.pill}>
        <Sparkles size={14} color={colors.accent} strokeWidth={2.2} />
        <Animated.View key={label} entering={FadeInDown.duration(320)} exiting={FadeOutUp.duration(220)}>
          <AppText style={styles.pillText}>{label}…</AppText>
        </Animated.View>
        <AppText style={styles.pillTime}>{seconds}s</AppText>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  stage: { width: "100%", aspectRatio: 3 / 4, borderRadius: radius.xl, overflow: "hidden", backgroundColor: colors.canvasSoft },
  revealMask: { position: "absolute", left: 0, right: 0, top: 0, overflow: "hidden" },
  revealEdge: { position: "absolute", left: 0, right: 0, top: 0, height: 3, backgroundColor: colors.white, boxShadow: "0 0 18px rgba(255,255,255,0.9)" },
  hidden: { opacity: 0 },
  veil: { position: "absolute", top: 0, right: 0, bottom: 0, left: 0, backgroundColor: "rgba(245,242,236,0.28)" },
  scan: { position: "absolute", left: 0, right: 0, height: 80 },
  scanLine: { position: "absolute", left: 0, right: 0, top: 39, height: 2, backgroundColor: colors.accent, boxShadow: "0 0 14px rgba(46,68,214,0.9)" },
  pillWrap: { position: "absolute", left: 0, right: 0, bottom: spacing.lg, alignItems: "center" },
  pill: {
    flexDirection: "row", alignItems: "center", gap: spacing.sm, paddingHorizontal: spacing.lg, height: 40, borderRadius: radius.pill,
    backgroundColor: "rgba(255,255,255,0.94)", boxShadow: "0 6px 18px rgba(23,20,15,0.15)"
  },
  pillText: { fontSize: 14, fontFamily: fonts.medium, fontWeight: "500" },
  pillTime: { fontSize: 13, color: colors.muted, fontVariant: ["tabular-nums"], fontFamily: fonts.regular },
  tag: { position: "absolute", top: spacing.md, left: spacing.md, paddingHorizontal: spacing.md, height: 30, borderRadius: radius.pill, backgroundColor: "rgba(23,20,15,0.6)", justifyContent: "center" },
  tagText: { color: colors.white, fontSize: 12, fontFamily: fonts.medium }
});
