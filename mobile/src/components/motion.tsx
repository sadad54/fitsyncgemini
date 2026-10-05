import { PropsWithChildren, ReactNode, useEffect } from "react";
import { Pressable, PressableProps, StyleProp, View, ViewStyle } from "react-native";
import * as Haptics from "expo-haptics";
import Animated, {
  Easing,
  FadeInDown,
  interpolate,
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withRepeat,
  withSpring,
  withTiming
} from "react-native-reanimated";
import { colors, radius } from "@/theme";

/** House easing: fast out, long gentle settle — fabric landing, not a bounce. */
export const SETTLE = Easing.bezier(0.22, 1, 0.36, 1);
export const SPRING = { damping: 18, stiffness: 220, mass: 0.9 };

/** Staggered entrance. Pass `index` to cascade lists. */
export function Reveal({ children, delay = 0, index, style }: PropsWithChildren<{ delay?: number; index?: number; style?: StyleProp<ViewStyle> }>) {
  const reduced = useReducedMotion();
  const total = delay + (index ?? 0) * 55;
  if (process.env.EXPO_OS === "web" || reduced) return <View style={style}>{children}</View>;
  return (
    <Animated.View style={style} entering={FadeInDown.delay(total).duration(520).easing(SETTLE).withInitialValues({ transform: [{ translateY: 18 }] })}>
      {children}
    </Animated.View>
  );
}

/** Pressable that compresses on touch with a spring, plus a haptic tick. */
export function PressableScale({
  children,
  style,
  onPress,
  haptic = true,
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
        if (haptic && process.env.EXPO_OS !== "web") Haptics.selectionAsync();
        onPress?.(e);
      }}
    >
      <Animated.View style={[style, animated]}>{children}</Animated.View>
    </Pressable>
  );
}

/** Loading placeholder with a soft travelling sheen. */
export function Skeleton({ style }: { style?: StyleProp<ViewStyle> }) {
  const t = useSharedValue(0);
  const reduced = useReducedMotion();
  useEffect(() => {
    if (!reduced) t.value = withRepeat(withTiming(1, { duration: 1100, easing: Easing.inOut(Easing.quad) }), -1, true);
  }, [reduced, t]);
  const animated = useAnimatedStyle(() => ({ opacity: interpolate(t.value, [0, 1], [0.55, 1]) }));
  return <Animated.View style={[{ backgroundColor: colors.canvasSoft, borderRadius: radius.md }, style, animated]} />;
}

/** Gentle breathing scale, used on the AI accent mark while work is happening. */
export function Breathe({ children, active = true }: PropsWithChildren<{ active?: boolean }>) {
  const t = useSharedValue(0);
  const reduced = useReducedMotion();
  useEffect(() => {
    t.value = active && !reduced ? withRepeat(withTiming(1, { duration: 1400, easing: Easing.inOut(Easing.sin) }), -1, true) : withTiming(0);
  }, [active, reduced, t]);
  const animated = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(t.value, [0, 1], [1, 1.12]) }, { rotate: `${interpolate(t.value, [0, 1], [0, 18])}deg` }]
  }));
  return <Animated.View style={animated}>{children}</Animated.View>;
}
