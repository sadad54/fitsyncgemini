import { useEffect } from "react";
import { View } from "react-native";
import Svg, { Path, Rect } from "react-native-svg";
import Animated, { interpolate, useAnimatedStyle, useReducedMotion, useSharedValue, withDelay, withSpring, withTiming } from "react-native-reanimated";
import { POP, SETTLE } from "@/components/motion";
import { colors } from "@/theme";

// Geometry mirrors brand/build_logo.py (256-unit grid). Keep the two in sync.
const HOOK = "M122 67.5A29.5 29.5 0 1 0 92.5 38A9.5 9.5 0 0 0 111.5 38A10.5 10.5 0 1 1 122 48.5Z";
const HOOK_NECK = "M112.5 49h19v33h-19z";

function sparkPath(cx: number, cy: number, r: number, k = 0.18) {
  const d = r * k;
  return `M${cx} ${cy - r}Q${cx + d} ${cy - d} ${cx + r} ${cy}Q${cx + d} ${cy + d} ${cx} ${cy + r}Q${cx - d} ${cy + d} ${cx - r} ${cy}Q${cx - d} ${cy - d} ${cx} ${cy - r}Z`;
}
const SPARK = sparkPath(184, 159, 34);
const SPARK_OUTLINE = sparkPath(184, 159, 41, 0.26);

type Tone = "light" | "dark" | "mono";

/**
 * The Flairwise mark: an F on a hanger (your clothes) with the volt AI sparkle.
 * light = ink F + outlined volt sparkle (for bone/white) · dark = bone F + volt sparkle · mono = one colour.
 * `small` drops the hook for sizes ≤ 24.
 */
export function LogoMark({ size = 40, tone = "dark", color, small = false, hideSpark = false }: {
  size?: number; tone?: Tone; color?: string; small?: boolean; hideSpark?: boolean;
}) {
  const f = color ?? (tone === "dark" ? colors.onStage : colors.ink);
  const spark = tone === "mono" ? f : colors.accent;
  return (
    <View accessible accessibilityRole="image" accessibilityLabel="Flairwise" style={{ width: size, height: size }}>
    <Svg width={size} height={size} viewBox="0 0 256 256">
      <Rect x={56} y={74} width={30} height={160} rx={8} fill={f} />
      <Rect x={56} y={74} width={132} height={28} rx={8} fill={f} />
      <Rect x={56} y={146} width={84} height={26} rx={8} fill={f} />
      {small ? null : <><Path d={HOOK} fill={f} /><Path d={HOOK_NECK} fill={f} /></>}
      {hideSpark ? null : <>
        {tone === "light" ? <Path d={SPARK_OUTLINE} fill={colors.ink} /> : null}
        <Path d={SPARK} fill={spark} />
      </>}
    </Svg>
    </View>
  );
}

/** The brand's four-point AI sparkle on its own, centred — use in place of a generic sparkles icon. */
export function BrandSpark({ size = 24, color = colors.ink }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 80 80">
      <Path d={sparkPath(40, 40, 36)} fill={color} />
    </Svg>
  );
}

/** Animated mark: the F + hanger rises in, then the sparkle pops on (Reduce Motion: static). */
export function AnimatedLogoMark({ size = 96, delay = 0, tone = "dark" }: { size?: number; delay?: number; tone?: Tone }) {
  const reduced = useReducedMotion();
  const body = useSharedValue(reduced ? 1 : 0);
  const spark = useSharedValue(reduced ? 1 : 0);
  useEffect(() => {
    if (reduced) return;
    body.value = withDelay(delay, withTiming(1, { duration: 650, easing: SETTLE }));
    spark.value = withDelay(delay + 520, withSpring(1, POP));
  }, [reduced, delay, body, spark]);
  const bodyStyle = useAnimatedStyle(() => ({ opacity: body.value, transform: [{ translateY: (1 - body.value) * 18 }] }));
  const sparkStyle = useAnimatedStyle(() => ({
    opacity: Math.min(1, spark.value * 2),
    transform: [{ scale: interpolate(spark.value, [0, 1], [0.2, 1]) }, { rotate: `${interpolate(spark.value, [0, 1], [-90, 0])}deg` }]
  }));
  // The sparkle sits at (184,159) on the 256 grid; size its own box around that point.
  const s = (size * 76) / 256;
  return (
    <View style={{ width: size, height: size }}>
      <Animated.View style={bodyStyle}><LogoMark size={size} tone={tone} hideSpark /></Animated.View>
      <Animated.View style={[{ position: "absolute", left: (size * 184) / 256 - s / 2, top: (size * 159) / 256 - s / 2 }, sparkStyle]}>
        <BrandSpark size={s} color={tone === "mono" ? colors.ink : colors.accent} />
      </Animated.View>
    </View>
  );
}
