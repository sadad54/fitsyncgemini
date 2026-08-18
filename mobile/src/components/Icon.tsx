import Svg, { Circle, Path } from "react-native-svg";
import { colors } from "@/theme";

// The design mockup draws exactly three icons as inline SVG (everything
// else is a plain text glyph — see the .dc.html source): a search
// magnifier, a four-point sparkle, and a thermometer. Reproduced here
// stroke-for-stroke rather than pulled from a library, since these three
// paths are the only ones actually specified.
export function SearchIcon({ size = 16, color = colors.muted, strokeWidth = 2 }: { size?: number; color?: string; strokeWidth?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Circle cx={11} cy={11} r={7} stroke={color} strokeWidth={strokeWidth} />
      <Path d="M16 16l5 5" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" />
    </Svg>
  );
}

export function SparkIcon({ size = 15, color = colors.roseSoft, strokeWidth = 2 }: { size?: number; color?: string; strokeWidth?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path d="M12 3l2 6 6 2-6 2-2 6-2-6-6-2 6-2z" stroke={color} strokeWidth={strokeWidth} strokeLinejoin="round" />
    </Svg>
  );
}

export function ThermometerIcon({ size = 13, color = colors.white, strokeWidth = 2 }: { size?: number; color?: string; strokeWidth?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path d="M12 3v11" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" />
      <Circle cx={12} cy={18} r={3} stroke={color} strokeWidth={strokeWidth} />
    </Svg>
  );
}
