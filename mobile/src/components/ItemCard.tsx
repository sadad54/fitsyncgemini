import { Link } from "expo-router";
import { Pressable, StyleSheet, View } from "react-native";
import { AppText } from "@/components/AppText";
import { Photo } from "@/components/Photo";
import { colors, fonts, spacing } from "@/theme";
import type { ClothingItem } from "@/types/api";
import { mediaUrl } from "@/api/client";

export function ItemCard({ item, width = "48%" }: { item: ClothingItem; width?: number | `${number}%` }) {
  const imageUrl = mediaUrl(item.image_url);
  return (
    <Link href={`/item/${item.id}`} asChild>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${item.name}, ${item.category}`}
        style={({ pressed }) => [styles.card, { width }, pressed && styles.pressed]}
      >
        <View style={styles.media}>
          {imageUrl ? <Photo source={imageUrl} /> : <View style={styles.placeholder} />}
          <View style={styles.categoryPill}><AppText style={styles.category}>{item.category}</AppText></View>
        </View>
        <View style={styles.body}>
          <AppText numberOfLines={2} style={styles.name}>{item.name}</AppText>
          <View style={styles.metaRow}>
            <View style={[styles.colorDot, { backgroundColor: colorFromName(item.colors[0]) }]} />
            <AppText numberOfLines={1} style={styles.meta}>{item.colors.slice(0, 2).join(" + ") || "neutral"}</AppText>
          </View>
        </View>
      </Pressable>
    </Link>
  );
}

export function colorFromName(name?: string) {
  const colorMap: Record<string, string> = {
    black: "#252329", white: "#EEE9E2", grey: "#8C8790", gray: "#8C8790", red: "#A54855", blue: "#526D91", green: "#64775C", yellow: "#C8A34A", brown: "#7A5B48", beige: "#CDBBA2", pink: "#B96A83", purple: "#745F8C", orange: "#C27445"
  };
  return colorMap[name?.toLowerCase() ?? ""] ?? colors.rose;
}

const styles = StyleSheet.create({
  card: { backgroundColor: colors.canvas, overflow: "hidden", borderRightWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke },
  pressed: { opacity: 0.8 },
  media: { width: "100%", aspectRatio: 0.88, backgroundColor: colors.surface },
  image: { width: "100%", height: "100%" },
  placeholder: { flex: 1, backgroundColor: colors.surface },
  categoryPill: { position: "absolute", top: 0, left: 0, backgroundColor: colors.strokeStrong, paddingHorizontal: 7, paddingVertical: 5 },
  category: { color: colors.canvas, fontSize: 8, lineHeight: 10, fontFamily: fonts.bold, fontWeight: "700", textTransform: "uppercase", letterSpacing: 0.9 },
  body: { paddingVertical: spacing.sm, paddingHorizontal: 2, gap: spacing.xs },
  name: { fontFamily: fonts.black, fontWeight: "800", fontSize: 13, lineHeight: 16, letterSpacing: -0.2 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: spacing.xs },
  colorDot: { width: 7, height: 7 },
  meta: { flex: 1, color: colors.muted, fontSize: 10, lineHeight: 13, fontFamily: fonts.regular, textTransform: "uppercase", letterSpacing: 0.5 }
});
