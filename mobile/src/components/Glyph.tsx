import { StyleSheet, View } from "react-native";
import { colors } from "@/theme";

// The Modernist system builds its ~15 icons from one square with per-corner
// radius, not an icon library. Each shape is a CSS `border-radius` corner
// pattern (e.g. "0 0 50% 50%" for a half-moon); this mirrors that here with
// RN's four discrete corner-radius props.
const CORNERS: Record<string, [number, number, number, number]> = {
  square: [0, 0, 0, 0],
  circle: [50, 50, 50, 50],
  moonDown: [0, 0, 50, 50],
  moonUp: [50, 50, 0, 0],
  moonLeft: [50, 0, 0, 50],
  moonRight: [0, 50, 50, 0],
  diamond: [50, 0, 50, 0],
  leaf: [50, 0, 0, 0],
  drop: [0, 50, 0, 0],
  home: [50, 50, 50, 0],
  closet: [0, 0, 50, 50],
  style: [50, 0, 0, 0],
  looks: [50, 0, 50, 0],
  you: [50, 50, 0, 0]
};

export function Glyph({ shape, size = 20, color = colors.ink, strokeWidth = 2 }: { shape: keyof typeof CORNERS; size?: number; color?: string; strokeWidth?: number }) {
  const [tl, tr, br, bl] = CORNERS[shape] ?? CORNERS.square;
  // CSS `border-radius: 50%` on a square means each corner's radius is 50%
  // of the box's full side length — that's what turns 4 corners into a
  // circle. Halving it here would cap out at a quarter-circle max.
  const px = (pct: number) => (pct / 100) * size;
  return (
    <View
      style={[
        styles.base,
        {
          width: size,
          height: size,
          borderWidth: strokeWidth,
          borderColor: color,
          borderTopLeftRadius: px(tl),
          borderTopRightRadius: px(tr),
          borderBottomRightRadius: px(br),
          borderBottomLeftRadius: px(bl)
        }
      ]}
    />
  );
}

const styles = StyleSheet.create({
  base: { backgroundColor: "transparent" }
});
