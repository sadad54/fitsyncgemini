import { ScrollView, StyleSheet, View } from "react-native";
import { router } from "expo-router";
import Animated, { useAnimatedStyle, useSharedValue, withDelay, withTiming } from "react-native-reanimated";
import { useEffect } from "react";
import { ArrowUpRight, Flame, Heart, MapPin, MessageCircle, Star, Users } from "@/icons";
import { AppText, Caption, Display, Em, Heading, Punch, Title } from "@/components/AppText";
import { PressableScale, Reveal, SETTLE } from "@/components/motion";
import { PreviewNote } from "@/components/PreviewNote";
import { Screen } from "@/components/Screen";
import { SectionHeader } from "@/components/section-header";
import { SEED_CHALLENGES, SEED_POSTS, SEED_STORES, SEED_TRENDS } from "@/data/discover";
import { colors, fonts, layout, radius, spacing } from "@/theme";

const CHALLENGE_TONES = [
  { bg: colors.ink, fg: colors.onInk },
  { bg: colors.accent, fg: colors.onAccent },
  { bg: colors.flare, fg: colors.ink }
];

export default function Discover() {
  const maxGrowth = Math.max(...SEED_TRENDS.map((t) => t.growth));
  return (
    <Screen tabbed>
      <Reveal>
        <View style={styles.header}>
          <Punch style={styles.kicker}>Dress from your closet</Punch>
          <Display>Get <Em>inspired</Em></Display>
        </View>
      </Reveal>

      <Reveal delay={40}>
        <PreviewNote>Community, trends and stores show sample content while they're being connected.</PreviewNote>
      </Reveal>

      <Reveal delay={80}>
        <View style={styles.section}>
          <SectionHeader title="Challenges" action="All" onAction={() => router.push("/community")} />
          <ScrollView horizontal showsHorizontalScrollIndicator={false} snapToInterval={276} decelerationRate="fast"
            style={styles.bleed} contentContainerStyle={styles.carousel}>
            {SEED_CHALLENGES.map((challenge, i) => {
              const tone = CHALLENGE_TONES[i % CHALLENGE_TONES.length];
              return (
                <PressableScale key={challenge.id} accessibilityRole="button" accessibilityLabel={challenge.title}
                  onPress={() => router.push(`/community/challenge/${challenge.id}`)} style={[styles.challenge, { backgroundColor: tone.bg }]}>
                  <View style={styles.challengeTop}>
                    <View style={[styles.pill, { borderColor: tone.fg }]}><Punch style={[styles.pillText, { color: tone.fg }]}>{challenge.days} days left</Punch></View>
                    <ArrowUpRight size={20} color={tone.fg} />
                  </View>
                  <View style={styles.flexEnd}>
                    <Title style={[styles.challengeTitle, { color: tone.fg }]}>{challenge.title}</Title>
                    <View style={styles.challengeMeta}>
                      <Users size={14} color={tone.fg} />
                      <AppText style={[styles.challengeMetaText, { color: tone.fg }]}>{challenge.participants.toLocaleString()} styling · {challenge.difficulty}</AppText>
                    </View>
                  </View>
                </PressableScale>
              );
            })}
          </ScrollView>
        </View>
      </Reveal>

      <Reveal delay={140}>
        <View style={styles.section}>
          <SectionHeader title="Rising this week" action="All trends" onAction={() => router.push("/trends")} />
          <View style={styles.list}>
            {SEED_TRENDS.map((trend, i) => (
              <PressableScale key={trend.id} accessibilityRole="button" accessibilityLabel={`${trend.name}, up ${trend.growth} percent`}
                onPress={() => router.push(`/trends/${trend.id}`)} style={[styles.trend, i > 0 && styles.rowRule]}>
                <View style={[styles.swatch, { backgroundColor: trend.swatch }]} />
                <View style={styles.flex}>
                  <Heading>{trend.name}</Heading>
                  <Caption>{trend.category}</Caption>
                  <GrowthBar value={trend.growth / maxGrowth} delay={300 + i * 90} />
                </View>
                <View style={styles.growth}>
                  <Flame size={14} color={colors.flare} fill={colors.flare} />
                  <AppText style={styles.growthText}>+{trend.growth}%</AppText>
                </View>
              </PressableScale>
            ))}
          </View>
        </View>
      </Reveal>

      <Reveal delay={200}>
        <View style={styles.section}>
          <SectionHeader title="From the community" action="Feed" onAction={() => router.push("/community")} />
          {SEED_POSTS.slice(0, 3).map((post) => (
            <PressableScale key={post.id} accessibilityRole="button" accessibilityLabel={`Post by ${post.name}`}
              onPress={() => router.push(`/community/post/${post.id}`)} style={styles.post}>
              <View style={styles.avatar}><AppText style={styles.avatarText}>{post.initial}</AppText></View>
              <View style={styles.flex}>
                <View style={styles.postHead}>
                  <AppText style={styles.postName}>{post.name}</AppText>
                  <Caption>{post.ago}</Caption>
                </View>
                <AppText numberOfLines={2} style={styles.postCaption}>{post.caption}</AppText>
                <View style={styles.postMeta}>
                  <View style={styles.postStat}><Heart size={14} color={colors.muted} /><Caption>{post.likes}</Caption></View>
                  <View style={styles.postStat}><MessageCircle size={14} color={colors.muted} /><Caption>{post.comments}</Caption></View>
                  <View style={styles.postTag}><AppText style={styles.postTagText}>{post.tag}</AppText></View>
                </View>
              </View>
            </PressableScale>
          ))}
        </View>
      </Reveal>

      <Reveal delay={260}>
        <View style={styles.section}>
          <SectionHeader title="Shops near you" action="Map" onAction={() => router.push("/stores")} />
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.bleed} contentContainerStyle={styles.carousel}>
            {SEED_STORES.map((store) => (
              <PressableScale key={store.id} accessibilityRole="button" accessibilityLabel={store.name} onPress={() => router.push(`/stores/${store.id}`)} style={styles.store}>
                <View style={styles.storeIcon}><MapPin size={18} color={colors.ink} /></View>
                <Heading numberOfLines={1}>{store.name}</Heading>
                <Caption numberOfLines={1}>{store.category}</Caption>
                <View style={styles.storeMeta}>
                  <Star size={13} color={colors.ink} fill={colors.ink} />
                  <AppText style={styles.storeMetaText}>{store.rating.toFixed(1)} · {store.distance}</AppText>
                </View>
              </PressableScale>
            ))}
          </ScrollView>
        </View>
      </Reveal>
    </Screen>
  );
}

function GrowthBar({ value, delay }: { value: number; delay: number }) {
  const w = useSharedValue(0);
  useEffect(() => { w.value = withDelay(delay, withTiming(value, { duration: 900, easing: SETTLE })); }, [value, delay, w]);
  const fill = useAnimatedStyle(() => ({ width: `${w.value * 100}%` }));
  return <View style={styles.bar}><Animated.View style={[styles.barFill, fill]} /></View>;
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  flexEnd: { gap: spacing.sm },
  header: { paddingTop: spacing.md, gap: spacing.xs },
  kicker: { color: colors.muted },
  preview: { flexDirection: "row", gap: spacing.sm, alignItems: "flex-start", padding: spacing.md, borderRadius: radius.md, backgroundColor: colors.surface, borderWidth: 1, borderStyle: "dashed", borderColor: colors.strokeStrong, marginTop: -spacing.md },
  previewText: { flex: 1, fontSize: 13, lineHeight: 18, color: colors.inkSoft },
  section: { gap: spacing.md },
  bleed: { marginHorizontal: -layout.gutter },
  carousel: { paddingHorizontal: layout.gutter, gap: spacing.md },
  challenge: { width: 264, height: 220, borderRadius: radius.xl, padding: spacing.lg, justifyContent: "space-between" },
  challengeTop: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  pill: { borderWidth: 1, borderRadius: radius.pill, paddingHorizontal: spacing.md, height: 28, justifyContent: "center" },
  pillText: { fontSize: 9, lineHeight: 11 },
  challengeTitle: { fontSize: 32, lineHeight: 34 },
  challengeMeta: { flexDirection: "row", alignItems: "center", gap: 6 },
  challengeMetaText: { fontSize: 13 },
  list: { backgroundColor: colors.surface, borderRadius: radius.xl, paddingHorizontal: spacing.lg, borderWidth: 1, borderColor: colors.stroke },
  rowRule: { borderTopWidth: 1, borderColor: colors.stroke },
  trend: { flexDirection: "row", alignItems: "center", gap: spacing.md, paddingVertical: spacing.lg },
  swatch: { width: 48, height: 48, borderRadius: radius.md, borderWidth: 1, borderColor: colors.stroke },
  bar: { height: 4, borderRadius: 2, backgroundColor: colors.canvasSoft, marginTop: spacing.sm, overflow: "hidden" },
  barFill: { height: 4, borderRadius: 2, backgroundColor: colors.ink, borderRightWidth: 4, borderColor: colors.accent },
  growth: { flexDirection: "row", alignItems: "center", gap: 3 },
  growthText: { fontSize: 14, fontFamily: fonts.semibold, fontVariant: ["tabular-nums"] },
  post: { flexDirection: "row", gap: spacing.md, padding: spacing.lg, borderRadius: radius.xl, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke },
  avatar: { width: 40, height: 40, borderRadius: 20, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center" },
  avatarText: { fontFamily: fonts.serif, fontSize: 20 },
  postHead: { flexDirection: "row", justifyContent: "space-between", alignItems: "baseline" },
  postName: { fontSize: 15, fontFamily: fonts.semibold, fontWeight: "600" },
  postCaption: { fontSize: 15, lineHeight: 21, color: colors.inkSoft, marginTop: 2 },
  postMeta: { flexDirection: "row", alignItems: "center", gap: spacing.md, marginTop: spacing.sm },
  postStat: { flexDirection: "row", alignItems: "center", gap: 4 },
  postTag: { marginLeft: "auto", backgroundColor: colors.canvas, borderRadius: radius.pill, paddingHorizontal: spacing.sm, height: 24, justifyContent: "center" },
  postTagText: { fontSize: 12, color: colors.inkSoft, fontFamily: fonts.medium },
  store: { width: 180, padding: spacing.lg, borderRadius: radius.xl, backgroundColor: colors.surface, gap: 2, borderWidth: 1, borderColor: colors.stroke },
  storeIcon: { width: 40, height: 40, borderRadius: 20, backgroundColor: colors.canvas, alignItems: "center", justifyContent: "center", marginBottom: spacing.sm },
  storeMeta: { flexDirection: "row", alignItems: "center", gap: 4, marginTop: spacing.xs },
  storeMetaText: { fontSize: 13, color: colors.inkSoft }
});
