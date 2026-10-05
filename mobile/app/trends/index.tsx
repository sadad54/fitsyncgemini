import { useMemo, useState } from "react";
import { ScrollView, StyleSheet, View } from "react-native";
import { Redirect, router } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText, Caption, Display, Em, Punch, Title } from "@/components/AppText";
import { Chip } from "@/components/Chip";
import { PressableScale, Reveal } from "@/components/motion";
import { Photo } from "@/components/Photo";
import { PreviewNote } from "@/components/PreviewNote";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_INSIGHTS, SEED_TRENDS, TREND_CATEGORIES } from "@/data/discover";
import { ArrowUpRight, Flame, MapPin } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, layout, radius, spacing } from "@/theme";

export default function TrendsFeed() {
  const token = useAuthStore((state) => state.token);
  const closet = useCloset();
  const [category, setCategory] = useState("All");
  const photos = useMemo(
    () => (closet.data?.items ?? []).map((item) => mediaUrl(item.image_url)).filter(Boolean) as string[],
    [closet.data]
  );
  const trends = useMemo(() => SEED_TRENDS.filter((trend) => category === "All" || trend.category === category), [category]);

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen>
      <PushHeader title="Trends" onBack={() => router.back()} actionIcon={MapPin} onAction={() => router.push("/stores")} actionLabel="Nearby stores" />
      <Reveal>
        <View style={styles.hero}>
          <Punch style={styles.kicker}>This season</Punch>
          <Display style={styles.heroTitle}>What's <Em>moving</Em></Display>
        </View>
      </Reveal>
      <PreviewNote />
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.bleed} contentContainerStyle={styles.chips}>
        {TREND_CATEGORIES.map((label) => <Chip key={label} active={category === label} onPress={() => setCategory(label)}>{label}</Chip>)}
      </ScrollView>

      <View style={styles.list}>
        {trends.map((trend, i) => (
          <PressableScale key={trend.id} accessibilityRole="button" accessibilityLabel={`${trend.name}, up ${trend.growth} percent`}
            onPress={() => router.push(`/trends/${trend.id}`)} style={[styles.row, i > 0 && styles.rowRule]}>
            <Punch style={styles.rank}>{String(i + 1).padStart(2, "0")}</Punch>
            <View style={[styles.swatch, { backgroundColor: trend.swatch }]} />
            <View style={styles.flex}>
              <AppText style={styles.trendName}>{trend.name}</AppText>
              <Caption>{trend.category}</Caption>
            </View>
            <View style={styles.growth}>
              <Flame size={13} color={colors.flare} fill={colors.flare} />
              <AppText style={styles.growthText}>+{trend.growth}%</AppText>
            </View>
          </PressableScale>
        ))}
      </View>

      {SEED_INSIGHTS.map((insight, index) => (
        <Reveal key={insight.id} index={index}>
          <PressableScale accessibilityRole="button" accessibilityLabel={insight.title} scaleTo={0.985} onPress={() => router.push(`/trends/${insight.id}`)} style={styles.insight}>
            <View style={styles.insightMedia}>
              {photos.length ? <Photo source={photos[index % photos.length]} /> : <View style={styles.placeholder} />}
              <View style={styles.score}><Punch style={styles.scoreText}>Trend score {insight.score}</Punch></View>
              <View style={styles.open}><ArrowUpRight size={18} color={colors.ink} /></View>
            </View>
            <View style={styles.insightBody}>
              <Title style={styles.insightTitle}>{insight.title}</Title>
              <AppText style={styles.blurb}>{insight.blurb}</AppText>
              <View style={styles.tags}>{insight.tags.map((tag) => <View key={tag} style={styles.tag}><AppText style={styles.tagText}>{tag}</AppText></View>)}</View>
              <View style={styles.popularity}>
                <AppText style={styles.popValue}>{insight.popularity}%</AppText>
                <Caption style={styles.flex}>popular with people who dress like you</Caption>
              </View>
            </View>
          </PressableScale>
        </Reveal>
      ))}
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  hero: { gap: spacing.xs },
  kicker: { color: colors.muted },
  heroTitle: { fontSize: 48, lineHeight: 48 },
  bleed: { marginHorizontal: -layout.gutter, flexGrow: 0 },
  chips: { paddingHorizontal: layout.gutter, gap: spacing.xs },
  list: { backgroundColor: colors.surface, borderRadius: radius.xl, paddingHorizontal: spacing.lg, borderWidth: 1, borderColor: colors.stroke },
  row: { flexDirection: "row", alignItems: "center", gap: spacing.md, paddingVertical: spacing.lg },
  rowRule: { borderTopWidth: 1, borderColor: colors.stroke },
  rank: { color: colors.muted, fontSize: 10, width: 18 },
  swatch: { width: 44, height: 44, borderRadius: radius.md, borderWidth: 1, borderColor: colors.stroke },
  trendName: { fontSize: 16, fontFamily: fonts.semibold, fontWeight: "600" },
  growth: { flexDirection: "row", alignItems: "center", gap: 4, backgroundColor: colors.flareWash, borderRadius: radius.pill, paddingHorizontal: 10, height: 30 },
  growthText: { fontSize: 14, fontFamily: fonts.semibold, fontVariant: ["tabular-nums"] },
  insight: { backgroundColor: colors.surface, borderRadius: radius.xl, overflow: "hidden", borderWidth: 1, borderColor: colors.stroke },
  insightMedia: { height: 240, backgroundColor: colors.canvasSoft },
  placeholder: { flex: 1, backgroundColor: colors.canvasSoft },
  score: { position: "absolute", left: spacing.md, top: spacing.md, backgroundColor: colors.accent, borderRadius: 6, paddingHorizontal: 9, paddingVertical: 6, borderWidth: 1.5, borderColor: colors.ink },
  scoreText: { fontSize: 9, lineHeight: 11 },
  open: { position: "absolute", right: spacing.md, top: spacing.md, width: 40, height: 40, borderRadius: 20, backgroundColor: colors.surface, alignItems: "center", justifyContent: "center" },
  insightBody: { padding: spacing.lg, gap: spacing.sm },
  insightTitle: { fontSize: 30, lineHeight: 32 },
  blurb: { color: colors.inkSoft, fontSize: 15, lineHeight: 22 },
  tags: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  tag: { backgroundColor: colors.canvas, borderRadius: radius.pill, paddingHorizontal: spacing.md, height: 28, justifyContent: "center" },
  tagText: { fontSize: 12, color: colors.inkSoft, fontFamily: fonts.medium },
  popularity: { flexDirection: "row", alignItems: "baseline", gap: spacing.sm, borderTopWidth: 1, borderColor: colors.stroke, paddingTop: spacing.md, marginTop: spacing.xs },
  popValue: { fontFamily: fonts.serif, fontSize: 32, lineHeight: 34 }
});
