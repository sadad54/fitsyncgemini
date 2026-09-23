import { PropsWithChildren } from "react";
import { View } from "react-native";
import Animated, { Easing, FadeInDown, useReducedMotion } from "react-native-reanimated";

// Confident, architectural deceleration — no spring overshoot. Matches the
// Modernist system's flat, measured character rather than a playful bounce.
const ARRIVAL = Easing.bezier(0.16, 1, 0.3, 1);

export function Reveal({ children, delay = 0 }: PropsWithChildren<{ delay?: number }>) {
  const reducedMotion = useReducedMotion();
  if (process.env.EXPO_OS === "web" || reducedMotion) return <View>{children}</View>;
  return (
    <Animated.View entering={FadeInDown.delay(delay).duration(420).easing(ARRIVAL)}>
      {children}
    </Animated.View>
  );
}
