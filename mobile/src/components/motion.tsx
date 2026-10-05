import { PropsWithChildren, ReactNode, useEffect } from "react";
import { Pressable, PressableProps, StyleProp, StyleSheet, View, ViewStyle } from "react-native";
import * as Haptics from "expo-haptics";
import { LinearGradient } from "expo-linear-gradient";
import Animated, {
  Easing,
  FadeInDown,
  interpolate,
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withDelay,
  withRepeat,
  withSpring,
  withTiming
} from "react-native-reanimated";
import { colors, radius } from "@/theme";

/** House easing: fast out, long gentle settle — fabric landing, not a bounce. */
export const SETTLE = Easing.bezier(0.22, 1, 0.36, 1);
export const SPRING = { damping: 18, stiffness: 220, mass: 0.9 };
/** A livelier spring for "pop" moments (success, selection). */
export const POP = { damping: 11, stiffness: 260, mass: 0.8 };

const native = process.env.EXPO_OS !== "web";

export const haptic = {
  tick: () => { if (native) Haptics.selectionAsync(); },
  tap: () => { if (native) Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); },
  thud: () => { if (native) Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium); },
  success: () => { if (native) Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success); }
};

/** Staggered entrance. Pass `index` to cascade lists. */
export function Reveal({ children, delay = 0, index, style }: PropsWithChildren<{ delay?: number; index?: number; style?: StyleProp<ViewStyle> }>) {
  const reduced = useReducedMotion();
  const total = delay + Math.min(index ?? 0, 10) * 55;
  if (!native || reduced) return <View style={style}>{children}</View>;
  return (
    <Animated.View style={style} entering={FadeInDown.delay(total).duration(560).easing(SETTLE).withInitialValues({ transform: [{ translateY: 22 }] })}>
      {children}
    </Animated.View>
  );
}

/** Pressable that compresses on touch with a spring, plus a haptic tick. */
export function PressableScale({
  children,
  style,
  onPress,
  haptic: withHaptic = true,
  scaleTo = 0.97,
  ...props
}: Omit<PressableProps, "style" | "children"> & { children: ReactNode; style?: StyleProp<ViewStyle>; haptic?: boolean; scaleTo?: number }) {
  const pressed = useSharedValue(0);
  const animated = useAnimatedStyle(() => ({ transform: [{ scale: interpolate(pressed.value, [0, 1], [1, scaleTo]) }] }));
  return (
    <Pressable
      {...props}
      onPressIn={(e) => { pressed.value = withSpring(1, SPRING); props.onPressIn?.(e); }}
      onPressOut={(e) => { pressed.value = withSpring(0, SPRING); props.onPressOut?.(e); }}
      onPress={(e) => {
        if (withHaptic) haptic.tick();
        onPress?.(e);
      }}
    >
      <Animated.View style={[style, animated]}>{children}</Animated.View>
    </Pressable>
  );
}

/** Loading placeholder with a travelling sheen. `tone="stage"` for dark surfaces. */
export function Skeleton({ style, tone = "light" }: { style?: StyleProp<ViewStyle>; tone?: "light" | "stage" }) {
  const t = useSharedValue(0);
  const reduced = useReducedMotion();
  useEffect(() => {
    if (!reduced) t.value = withRepeat(withTiming(1, { duration: 1400, easing: Easing.inOut(Easing.quad) }), -1, false);
  }, [reduced, t]);
  const sheen = useAnimatedStyle(() => ({ transform: [{ translateX: interpolate(t.value, [0, 1], [-260, 420]) }] }));
  const stage = tone === "stage";
  return (
    <View style={[{ backgroundColor: stage ? colors.stageRaised : colors.canvasSoft, borderRadius: radius.md, overflow: "hidden" }, style]}>
      {reduced ? null : (
        <Animated.View style={[styles.sheen, sheen]}>
          <LinearGradient start={{ x: 0, y: 0.5 }} end={{ x: 1, y: 0.5 }} style={StyleSheet.absoluteFill}
            colors={stage ? ["rgba(255,255,255,0)", "rgba(255,255,255,0.07)", "rgba(255,255,255,0)"] : ["rgba(255,255,255,0)", "rgba(255,255,255,0.75)", "rgba(255,255,255,0)"]} />
        </Animated.View>
      )}
    </View>
  );
}

/** Gentle breathing scale, used on the AI accent mark while work is happening. */
export function Breathe({ children, active = true }: PropsWithChildren<{ active?: boolean }>) {
  const t = useSharedValue(0);
  const reduced = useReducedMotion();
  useEffect(() => {
    t.value = active && !reduced ? withRepeat(withTiming(1, { duration: 1400, easing: Easing.inOut(Easing.sin) }), -1, true) : withTiming(0);
  }, [active, reduced, t]);
  const animated = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(t.value, [0, 1], [1, 1.14]) }, { rotate: `${interpolate(t.value, [0, 1], [0, 18])}deg` }]
  }));
  return <Animated.View style={animated}>{children}</Animated.View>;
}

/** A small volt dot that pulses — "live", "working", "AI is on it". */
export function PulseDot({ size = 8, color = colors.accent }: { size?: number; color?: string }) {
  const t = useSharedValue(0);
  const reduced = useReducedMotion();
  useEffect(() => {
    if (!reduced) t.value = withRepeat(withTiming(1, { duration: 1300, easing: Easing.out(Easing.quad) }), -1, false);
  }, [reduced, t]);
  const ring = useAnimatedStyle(() => ({ opacity: interpolate(t.value, [0, 1], [0.7, 0]), transform: [{ scale: interpolate(t.value, [0, 1], [1, 2.6]) }] }));
  return (
    <View style={{ width: size, height: size }}>
      <Animated.View style={[{ position: "absolute", width: size, height: size, borderRadius: size / 2, backgroundColor: color }, ring]} />
      <View style={{ width: size, height: size, borderRadius: size / 2, backgroundColor: color }} />
    </View>
  );
}

/** Animated number count-up for stats. */
export function useCountUp(target: number, delay = 0) {
  const v = useSharedValue(0);
  const reduced = useReducedMotion();
  useEffect(() => {
    v.value = reduced ? target : withDelay(delay, withTiming(target, { duration: 900, easing: SETTLE }));
  }, [target, delay, reduced, v]);
  return v;
}

const styles = StyleSheet.create({
  sheen: { position: "absolute", top: 0, bottom: 0, width: 220 }
});
