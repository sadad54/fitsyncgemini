import { useMemo } from "react";
import { Pressable, ScrollView, StyleSheet, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText, Eyebrow } from "@/components/AppText";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_TREND_DETAIL, SEED_TRENDS } from "@/data/discover";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

export default function TrendDetail() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const closet = useCloset();

  const trend = SEED_TRENDS.find((entry) => entry.id === id);
  const detail = trend
    ? { ...SEED_TREND_DETAIL, name: trend.name, category: trend.category, growth: trend.growth }
    : SEED_TREND_DETAIL;

  const items = closet.data?.items ?? [];
  // Match the trend's palette against the member's own pieces.
  const matches = useMemo(() => {
    const paletteNames = detail.palette.map((entry) => entry.name.toLowerCase());
    const matched = items.filter((item) =>
      item.colors.some((color) => paletteNames.includes(color.toLowerCase()))
    );
    return (matched.length ? matched : items).slice(0, 3);
  }, [items, detail.palette]);

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen scroll bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.headerWrap}>
        <PushHeader title="Trend" onBack={() => router.back()} />
      </View>

      <View style={styles.hero}>
        {mediaUrl(items[0]?.image_url) ? <Photo source={mediaUrl(items[0]!.image_url)!} /> : <View style={styles.mediaPlaceholder} />}
        <View style={styles.growthBadge}>
          <AppText style={styles.growthBadgeText}>+{detail.growth}% this season</AppText>
        </View>
      </View>

      <View style={styles.body}>
        <Eyebrow style={styles.category}>{detail.category}</Eyebrow>
        <AppText style={styles.title}>{detail.name}</AppText>
        <AppText style={styles.description}>{detail.description}</AppText>
      </View>

      <View style={styles.paletteSection}>
        <AppText style={styles.sectionLabel}>Palette</AppText>
        <View style={styles.palette}>
          {detail.palette.map((entry) => (
            <View key={entry.name} style={styles.paletteCell}>
              <View style={[styles.paletteSwatch, { backgroundColor: entry.value }]} />
              <AppText style={styles.paletteName}>{entry.name}</AppText>
            </View>
          ))}
        </View>
        <View style={styles.tagRow}>
          {detail.tags.map((tag) => (
            <View key={tag} style={styles.tag}>
              <AppText style={styles.tagText}>{tag}</AppText>
            </View>
          ))}
        </View>
      </View>

      <AppText style={styles.closetLabel}>
        {matches.length ? `From your closet — ${matches.length} pieces already fit` : "Nothing in your closet fits this yet"}
      </AppText>
      {matches.length ? (
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.closetRail}>
          {matches.map((item) => (
            <Pressable
              key={item.id}
              accessibilityRole="button"
              accessibilityLabel={item.name}
              onPress={() => router.push(`/item/${item.id}`)}
              style={styles.closetTile}
            >
              {mediaUrl(item.image_url) ? <Photo source={mediaUrl(item.image_url)!} /> : <View style={styles.mediaPlaceholder} />}
              <AppText numberOfLines={1} style={styles.closetName}>{item.name}</AppText>
            </Pressable>
          ))}
        </ScrollView>
      ) : null}

      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Style a look around this"
        onPress={() => router.push("/generate")}
        style={styles.primary}
      >
        <AppText style={styles.primaryLabel}>Style a look around this</AppText>
        <AppText style={styles.primaryGlyph}>→</AppText>
      </Pressable>
      <View style={{ height: 40 }} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  headerWrap: { paddingHorizontal: spacing.xl, paddingTop: spacing.sm },
  hero: { height: 232, backgroundColor: colors.surface, overflow: "hidden" },
  mediaPlaceholder: { flex: 1, backgroundColor: colors.surface },
  growthBadge: { position: "absolute", left: 0, bottom: 0, backgroundColor: colors.rose, paddingHorizontal: 11, paddingVertical: 8 },
  growthBadgeText: { color: colors.white, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  body: { paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.lg, borderBottomWidth: 1, borderColor: colors.stroke },
  category: { color: colors.muted },
  title: { fontSize: 36, lineHeight: 34, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -1.4, textTransform: "uppercase", marginTop: spacing.md },
  description: { color: colors.muted, fontSize: 14, lineHeight: 22, marginTop: spacing.md },
  paletteSection: { paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, borderBottomWidth: 1, borderColor: colors.stroke },
  sectionLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6, textTransform: "uppercase" },
  palette: { flexDirection: "row", gap: spacing.md, marginTop: 13 },
  paletteCell: { flex: 1, gap: 6 },
  paletteSwatch: { width: "100%", height: 44 },
  paletteName: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  tagRow: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs, marginTop: spacing.lg },
  tag: { borderWidth: 1, borderColor: colors.stroke, paddingHorizontal: 10, paddingVertical: 8 },
  tagText: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  closetLabel: { color: colors.roseSoft, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6, textTransform: "uppercase", paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.sm },
  closetRail: { flexGrow: 0, borderTopWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke },
  closetTile: { width: 118, height: 154, borderRightWidth: 1, borderColor: colors.stroke, backgroundColor: colors.surface, overflow: "hidden" },
  closetName: { position: "absolute", left: spacing.sm, bottom: spacing.sm, color: colors.white, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  primary: { height: 56, backgroundColor: colors.rose, flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: spacing.xl },
  primaryLabel: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 13, letterSpacing: 1.3, textTransform: "uppercase" },
  primaryGlyph: { color: colors.white, fontSize: 17 }
});
