import { StyleSheet, View } from "react-native";
import { Image } from "expo-image";
import { Ionicons } from "@expo/vector-icons";
import { mediaUrl } from "@/api/client";
import type { ClothingItem } from "@/types/api";
import { colors, radius, shadows, spacing } from "@/theme";

export function OutfitRail({ items, compact = false }: { items: ClothingItem[]; compact?: boolean }) {
  const shown = items.slice(0, 4);
  if (!shown.length) {
    return (
      <View style={[styles.empty, compact && styles.compactEmpty]}>
        <Ionicons name="shirt-outline" size={compact ? 22 : 34} color={colors.roseSoft} />
      </View>
    );
  }

  return (
    <View style={[styles.rail, compact && styles.compactRail]}>
      {shown.map((item, index) => {
        const url = mediaUrl(item.image_url);
        return (
          <View key={item.id} style={[styles.frame, compact && styles.compactFrame, { marginLeft: index ? (compact ? -12 : -18) : 0, zIndex: shown.length - index, transform: [{ rotate: `${(index - 1.5) * 2.2}deg` }] }]}>
            {url ? <Image accessible={false} source={url} style={styles.image} contentFit="cover" transition={160} cachePolicy="memory-disk" /> : <Ionicons name="shirt-outline" size={22} color={colors.faint} />}
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  rail: { minHeight: 152, flexDirection: "row", alignItems: "center", justifyContent: "center", paddingHorizontal: spacing.lg },
  compactRail: { minHeight: 72, justifyContent: "flex-start", paddingHorizontal: 0 },
  frame: { width: 104, height: 138, borderRadius: radius.lg, borderCurve: "continuous", borderWidth: 2, borderColor: colors.strokeStrong, backgroundColor: colors.surfaceElevated, overflow: "hidden", alignItems: "center", justifyContent: "center", boxShadow: shadows.card },
  compactFrame: { width: 58, height: 72, borderRadius: radius.md, borderWidth: 1 },
  image: { width: "100%", height: "100%" },
  empty: { height: 152, borderRadius: radius.lg, borderWidth: 1, borderStyle: "dashed", borderColor: colors.strokeStrong, backgroundColor: colors.roseWash, alignItems: "center", justifyContent: "center" },
  compactEmpty: { height: 72, width: 72 }
});
