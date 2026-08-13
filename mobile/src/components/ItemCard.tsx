import { Link } from "expo-router";
import { Pressable, StyleSheet, View } from "react-native";
import { Image } from "expo-image";
import { Ionicons } from "@expo/vector-icons";
import { AppText } from "@/components/AppText";
import { colors, radius, shadows, spacing } from "@/theme";
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
          {imageUrl ? <Image accessible={false} source={imageUrl} style={styles.image} contentFit="cover" transition={180} cachePolicy="memory-disk" /> : <View style={styles.placeholder}><Ionicons name="shirt-outline" size={28} color={colors.faint} /></View>}
          <View style={styles.categoryPill}><AppText style={styles.category}>{item.category}</AppText></View>
        </View>
        <View style={styles.body}>
          <AppText numberOfLines={2} style={styles.name}>{item.name}</AppText>
          <View style={styles.metaRow}>
            <View style={[styles.colorDot, { backgroundColor: colorFromName(item.colors[0]) }]} />
            <AppText numberOfLines={1} style={styles.meta}>{item.colors.slice(0, 2).join(" + ") || "neutral"}</AppText>
            <Ionicons name="chevron-forward" size={14} color={colors.faint} />
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
  card: { backgroundColor: colors.surface, borderRadius: radius.lg, borderCurve: "continuous", borderWidth: 1, borderColor: colors.stroke, overflow: "hidden", boxShadow: shadows.card },
  pressed: { opacity: 0.76, transform: [{ scale: 0.985 }] },
  media: { width: "100%", aspectRatio: 0.88, backgroundColor: colors.surfaceElevated },
  image: { width: "100%", height: "100%" },
  placeholder: { flex: 1, alignItems: "center", justifyContent: "center" },
  categoryPill: { position: "absolute", top: spacing.sm, left: spacing.sm, borderRadius: radius.pill, backgroundColor: "rgba(16, 15, 20, 0.72)", paddingHorizontal: spacing.sm, paddingVertical: spacing.xs },
  category: { color: colors.inkSoft, fontSize: 10, lineHeight: 13, fontWeight: "800", textTransform: "uppercase", letterSpacing: 0.7 },
  body: { padding: spacing.md, gap: spacing.sm },
  name: { fontWeight: "800", lineHeight: 21 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: spacing.xs },
  colorDot: { width: 9, height: 9, borderRadius: 5, borderWidth: 1, borderColor: colors.strokeStrong },
  meta: { flex: 1, color: colors.muted, fontSize: 12, lineHeight: 16, textTransform: "capitalize" }
});
