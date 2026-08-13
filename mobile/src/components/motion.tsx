import { PropsWithChildren } from "react";
import { View } from "react-native";
import Animated, { FadeInDown, useReducedMotion } from "react-native-reanimated";

export function Reveal({ children, delay = 0 }: PropsWithChildren<{ delay?: number }>) {
  const reducedMotion = useReducedMotion();
  if (process.env.EXPO_OS === "web" || reducedMotion) return <View>{children}</View>;
  return (
    <Animated.View entering={FadeInDown.delay(delay).duration(420).springify().damping(18)}>
      {children}
    </Animated.View>
  );
}
