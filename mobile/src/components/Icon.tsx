import { Search, Sparkles, Thermometer } from "lucide-react-native";
import { colors } from "@/theme";

// Legacy icon names kept for older screens; all now render lucide glyphs.
export function SearchIcon({ size = 16, color = colors.muted, strokeWidth = 2 }: { size?: number; color?: string; strokeWidth?: number }) {
  return <Search size={size} color={color} strokeWidth={strokeWidth} />;
}

export function SparkIcon({ size = 15, color = colors.accent, strokeWidth = 2 }: { size?: number; color?: string; strokeWidth?: number }) {
  return <Sparkles size={size} color={color} strokeWidth={strokeWidth} />;
}

export function ThermometerIcon({ size = 13, color = colors.ink, strokeWidth = 2 }: { size?: number; color?: string; strokeWidth?: number }) {
  return <Thermometer size={size} color={color} strokeWidth={strokeWidth} />;
}
