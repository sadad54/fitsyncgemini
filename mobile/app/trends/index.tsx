import { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, View } from "react-native";
import { Redirect, router } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_INSIGHTS, SEED_TRENDS, TREND_CATEGORIES } from "@/data/discover";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

export default function TrendsFeed() {
  const token = useAuthStore((state) => state.token);
  const closet = useCloset();
  const [category, setCategory] = useState("All");

  const photos = useMemo(
    () => (closet.data?.items ?? []).map((item) => mediaUrl(item.image_url)).filter(Boolean) as string[],
    [closet.data]
  );

  const trends = useMemo(
    () => SEED_TRENDS.filter((trend) => category === "All" || trend.category === category),
    [category]
  );

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen scroll bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.headerWrap}>
        <PushHeader
          title="Trends"
          onBack={() => router.back()}
          rule="none"
          actionGlyph="→"
          onAction={() => router.push("/stores")}
          actionLabel="Nearby stores"
        />
      </View>

      <View style={styles.hero}>
        <Eyebrow>Trends</Eyebrow>
        <Title style={styles.heroTitle}>What's moving this season</Title>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.catRail}>
        {TREND_CATEGORIES.map((label) => {
          const active = category === label;
          return (
            <Pressable
              key={label}
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
              onPress={() => setCategory(label)}
              style={[styles.cat, active && styles.catActive]}
            >
              <AppText style={[styles.catLabel, active && styles.catLabelActive]}>{label}</AppText>
            </Pressable>
          );
        })}
      </ScrollView>

      {trends.map((trend) => (
        <Pressable
          key={trend.id}
          accessibilityRole="button"
          accessibilityLabel={trend.name}
          onPress={() => router.push(`/trends/${trend.id}`)}
          style={styles.trendRow}
        >
          <View style={[styles.swatch, { backgroundColor: trend.swatch }]} />
          <View style={styles.trendCopy}>
            <AppText style={styles.trendName}>{trend.name}</AppText>
            <AppText style={styles.trendCategory}>{trend.category}</AppText>
          </View>
          <AppText style={styles.growth}>
            +{trend.growth}
            <AppText style={styles.growthPct}>%</AppText>
          </AppText>
        </Pressable>
      ))}

      {SEED_INSIGHTS.map((insight, index) => {
        const image = photos[index % Math.max(photos.length, 1)];
        return (
          <View key={insight.id} style={styles.insight}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={insight.title}
              onPress={() => router.push(`/trends/${insight.id}`)}
              style={styles.insightMedia}
            >
              {image ? <Photo source={image} /> : <View style={styles.mediaPlaceholder} />}
              <View style={styles.scoreBadge}>
                <AppText style={styles.scoreBadgeText}>Trend score {insight.score}</AppText>
              </View>
            </Pressable>
            <View style={styles.insightBody}>
              <AppText style={styles.insightTitle}>{insight.title}</AppText>
              <AppText style={styles.insightBlurb}>{insight.blurb}</AppText>
              <View style={styles.tagRow}>
                {insight.tags.map((tag) => (
                  <View key={tag} style={styles.tag}>
                    <AppText style={styles.tagText}>{tag}</AppText>
                  </View>
                ))}
              </View>
              <View style={styles.popularityRow}>
                <AppText style={styles.popularity}>{insight.popularity}%</AppText>
                <AppText style={styles.popularityLabel}>popularity among people like you</AppText>
              </View>
            </View>
          </View>
        );
      })}
      <View style={{ height: 40 }} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  headerWrap: { paddingHorizontal: spacing.xl, paddingTop: spacing.sm },
  hero: { paddingHorizontal: spacing.xl, paddingBottom: spacing.lg, borderBottomWidth: 2, borderColor: colors.strokeStrong, gap: spacing.xs },
  heroTitle: { fontSize: 40, lineHeight: 37 },
  catRail: { flexGrow: 0, borderBottomWidth: 1, borderColor: colors.stroke },
  cat: { paddingHorizontal: spacing.md, paddingVertical: spacing.md, borderRightWidth: 1, borderColor: colors.stroke, justifyContent: "center" },
  catActive: { backgroundColor: colors.rose, borderColor: colors.rose },
  catLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  catLabelActive: { color: colors.white },
  trendRow: { flexDirection: "row", alignItems: "center", gap: spacing.md, paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, borderBottomWidth: 1, borderColor: colors.stroke },
  swatch: { width: 34, height: 34 },
  trendCopy: { flex: 1 },
  trendName: { fontSize: 17, lineHeight: 19, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.4 },
  trendCategory: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase", marginTop: 6 },
  growth: { color: colors.roseSoft, fontSize: 30, lineHeight: 30, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -1, fontVariant: ["tabular-nums"] },
  growthPct: { fontSize: 14, fontFamily: fonts.black, fontWeight: "800" },
  insight: { borderBottomWidth: 1, borderColor: colors.stroke },
  insightMedia: { height: 250, backgroundColor: colors.surface, overflow: "hidden" },
  mediaPlaceholder: { flex: 1, backgroundColor: colors.surface },
  scoreBadge: { position: "absolute", left: 0, bottom: 0, backgroundColor: colors.rose, paddingHorizontal: 11, paddingVertical: 8 },
  scoreBadgeText: { color: colors.white, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  insightBody: { paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.lg },
  insightTitle: { fontSize: 25, lineHeight: 25, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.7, textTransform: "uppercase" },
  insightBlurb: { color: colors.muted, fontSize: 13, lineHeight: 20, marginTop: spacing.sm },
  tagRow: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs, marginTop: 13 },
  tag: { borderWidth: 1, borderColor: colors.stroke, paddingHorizontal: 10, paddingVertical: 8 },
  tagText: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  popularityRow: { flexDirection: "row", alignItems: "baseline", gap: spacing.sm, marginTop: spacing.md, borderTopWidth: 1, borderColor: colors.stroke, paddingTop: spacing.md },
  popularity: { fontSize: 26, lineHeight: 26, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.7, fontVariant: ["tabular-nums"] },
  popularityLabel: { flex: 1, color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" }
});
