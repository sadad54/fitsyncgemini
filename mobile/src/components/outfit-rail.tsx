import { StyleSheet, View } from "react-native";
import { mediaUrl } from "@/api/client";
import { Photo } from "@/components/Photo";
import type { ClothingItem } from "@/types/api";
import { colors } from "@/theme";

export function OutfitRail({ items, compact = false }: { items: ClothingItem[]; compact?: boolean }) {
  const shown = items.slice(0, 4);
  if (!shown.length) {
    return (
      <View style={[styles.empty, compact && styles.compactEmpty]}>
        <View style={styles.emptyMark} />
      </View>
    );
  }

  return (
    <View style={[styles.rail, compact && styles.compactRail]}>
      {shown.map((item) => {
        const url = mediaUrl(item.image_url);
        return (
          <View key={item.id} style={[styles.frame, compact && styles.compactFrame]}>
            {url ? <Photo source={url} transition={160} /> : <View style={styles.imagePlaceholder} />}
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  rail: { flexDirection: "row" },
  compactRail: { justifyContent: "flex-start" },
  frame: { width: 104, height: 138, borderRightWidth: 1, borderColor: colors.stroke, backgroundColor: colors.surface, overflow: "hidden" },
  compactFrame: { width: 58, height: 76 },
  image: { width: "100%", height: "100%" },
  imagePlaceholder: { flex: 1, backgroundColor: colors.surface },
  empty: { height: 138, borderWidth: 2, borderStyle: "dashed", borderColor: colors.strokeStrong, alignItems: "center", justifyContent: "center" },
  compactEmpty: { height: 76, width: 76 },
  emptyMark: { width: 22, height: 22, borderWidth: 2, borderColor: colors.roseSoft }
});
