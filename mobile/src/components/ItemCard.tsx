import { router } from "expo-router";
import { StyleSheet, View } from "react-native";
import { Check } from "@/icons";
import { AppText } from "@/components/AppText";
import { Photo } from "@/components/Photo";
import { PressableScale } from "@/components/motion";
import { colors, fonts, radius, spacing } from "@/theme";
import type { ClothingItem } from "@/types/api";
import { mediaUrl } from "@/api/client";

export function ItemCard({
  item,
  width = "48%",
  selected,
  selecting,
  onPress,
  onLongPress
}: {
  item: ClothingItem;
  width?: number | `${number}%`;
  selected?: boolean;
  selecting?: boolean;
  onPress?: () => void;
  onLongPress?: () => void;
}) {
  const imageUrl = mediaUrl(item.image_url);
  return (
    <View style={[styles.cell, { width }]}>
      <PressableScale
        accessibilityRole="button"
        accessibilityLabel={`${item.name}, ${item.category}`}
        accessibilityState={{ selected }}
        onPress={onPress ?? (() => router.push(`/item/${item.id}`))}
        onLongPress={onLongPress}
        delayLongPress={280}
        style={styles.card}
      >
        <View style={[styles.media, selected && styles.mediaSelected]}>
          {imageUrl ? <Photo source={imageUrl} /> : <View style={styles.placeholder} />}
          {selecting ? (
            <View style={[styles.tick, selected && styles.tickOn]}>
              {selected ? <Check size={14} color={colors.ink} strokeWidth={3} /> : null}
            </View>
          ) : null}
        </View>
        <View style={styles.body}>
          <AppText numberOfLines={1} style={styles.name}>{item.name}</AppText>
          <View style={styles.metaRow}>
            <View style={[styles.colorDot, { backgroundColor: colorFromName(item.colors[0]) }]} />
            <AppText numberOfLines={1} style={styles.meta}>{item.subcategory || item.category}</AppText>
          </View>
        </View>
      </PressableScale>
    </View>
  );
}

export function colorFromName(name?: string) {
  const colorMap: Record<string, string> = {
    black: "#1F1D1B", white: "#F4F1EA", grey: "#8C8790", gray: "#8C8790", red: "#B23A32", blue: "#3D5F8F", navy: "#24324F",
    green: "#55704F", yellow: "#D2A93E", brown: "#7A5B48", beige: "#D5C3A6", cream: "#EDE2CC", pink: "#D17E96", purple: "#6F5A92", orange: "#D1773D"
  };
  return colorMap[name?.toLowerCase() ?? ""] ?? colors.canvasSoft;
}

const styles = StyleSheet.create({
  cell: { padding: 6 },
  card: { gap: spacing.sm },
  media: { width: "100%", aspectRatio: 0.8, borderRadius: radius.lg, overflow: "hidden", backgroundColor: colors.surface, borderWidth: 2.5, borderColor: "transparent" },
  mediaSelected: { borderColor: colors.ink },
  placeholder: { flex: 1, backgroundColor: colors.canvasSoft },
  tick: {
    position: "absolute", top: 10, right: 10, width: 24, height: 24, borderRadius: 12,
    borderWidth: 2, borderColor: colors.white, backgroundColor: "rgba(13,13,15,0.3)", alignItems: "center", justifyContent: "center"
  },
  tickOn: { backgroundColor: colors.accent, borderColor: colors.ink },
  body: { paddingHorizontal: 2, gap: 2 },
  name: { fontFamily: fonts.medium, fontWeight: "500", fontSize: 14, lineHeight: 19 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: 6 },
  colorDot: { width: 8, height: 8, borderRadius: 4, borderWidth: StyleSheet.hairlineWidth, borderColor: colors.strokeStrong },
  meta: { flex: 1, color: colors.muted, fontSize: 12, lineHeight: 16, textTransform: "capitalize" }
});
