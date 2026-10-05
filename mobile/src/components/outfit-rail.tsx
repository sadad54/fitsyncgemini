import { StyleSheet, View } from "react-native";
import Animated, { FadeIn, ZoomIn } from "react-native-reanimated";
import { Shirt } from "lucide-react-native";
import { mediaUrl } from "@/api/client";
import { Photo } from "@/components/Photo";
import { SETTLE } from "@/components/motion";
import type { ClothingItem } from "@/types/api";
import { colors, radius, spacing } from "@/theme";

/**
 * Editorial "flat lay": the outfit's pieces laid out like a stylist's board.
 * One tall hero piece plus a stacked column, each landing with a staggered
 * scale-in so a fresh outfit feels assembled, not loaded.
 */
export function OutfitCollage({ items, height = 300, animateKey }: { items: ClothingItem[]; height?: number; animateKey?: string }) {
  const shown = items.slice(0, 4);
  if (!shown.length) {
    return (
      <View style={[styles.empty, { height }]}>
        <Shirt size={28} color={colors.faint} strokeWidth={1.5} />
      </View>
    );
  }
  const [hero, ...rest] = shown;
  return (
    <View key={animateKey} style={[styles.board, { height }]}>
      <Tile item={hero} index={0} style={rest.length ? styles.hero : styles.solo} />
      {rest.length ? (
        <View style={styles.stack}>
          {rest.map((item, i) => <Tile key={item.id} item={item} index={i + 1} style={styles.stackTile} />)}
        </View>
      ) : null}
    </View>
  );
}

function Tile({ item, index, style }: { item: ClothingItem; index: number; style: object }) {
  const url = mediaUrl(item.image_url);
  return (
    <Animated.View
      entering={process.env.EXPO_OS === "web" ? FadeIn : ZoomIn.delay(index * 90).duration(480).easing(SETTLE).withInitialValues({ transform: [{ scale: 0.86 }] })}
      style={[styles.tile, style]}
    >
      {url ? <Photo source={url} contentFit="cover" /> : <View style={styles.placeholder} />}
    </Animated.View>
  );
}

/** Compact horizontal strip, for list rows. */
export function OutfitRail({ items, compact = false }: { items: ClothingItem[]; compact?: boolean }) {
  const size = compact ? 52 : 92;
  return (
    <View style={styles.rail}>
      {items.slice(0, 4).map((item, i) => {
        const url = mediaUrl(item.image_url);
        return (
          <View key={item.id} style={[styles.railTile, { width: size, height: size * 1.25, marginLeft: i ? -spacing.sm : 0, zIndex: 10 - i }]}>
            {url ? <Photo source={url} /> : <View style={styles.placeholder} />}
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  board: { flexDirection: "row", gap: spacing.sm },
  tile: { borderRadius: radius.lg, overflow: "hidden", backgroundColor: colors.surface },
  hero: { flex: 1.25 },
  solo: { flex: 1 },
  stack: { flex: 1, gap: spacing.sm },
  stackTile: { flex: 1 },
  placeholder: { flex: 1, backgroundColor: colors.canvasSoft },
  empty: { borderRadius: radius.lg, borderWidth: 1, borderStyle: "dashed", borderColor: colors.strokeStrong, alignItems: "center", justifyContent: "center" },
  rail: { flexDirection: "row" },
  railTile: { borderRadius: radius.md, overflow: "hidden", backgroundColor: colors.surface, borderWidth: 2, borderColor: colors.canvas }
});
