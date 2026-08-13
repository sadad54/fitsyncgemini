import { useMemo } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import { router } from "expo-router";
import { LinearGradient } from "expo-linear-gradient";
import { StatusBar } from "expo-status-bar";
import { Ionicons } from "@expo/vector-icons";
import { SafeAreaView } from "react-native-safe-area-context";
import Animated, { Extrapolation, interpolate, useAnimatedScrollHandler, useAnimatedStyle, useReducedMotion, useSharedValue } from "react-native-reanimated";
import { useCloset, useClosetStats, useProfile, useSavedOutfits } from "@/api/queries";
import { AppText, Display, Eyebrow } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Reveal } from "@/components/motion";
import { OutfitRail } from "@/components/outfit-rail";
import { SectionHeader } from "@/components/section-header";
import { colors, gradients, radius, shadows, spacing } from "@/theme";

export default function Home() {
  const profile = useProfile();
  const stats = useClosetStats();
  const saved = useSavedOutfits();
  const closet = useCloset();
  const scrollY = useSharedValue(0);
  const reducedMotion = useReducedMotion();
  const scrollHandler = useAnimatedScrollHandler((event) => { scrollY.value = event.contentOffset.y; });
  const heroMotion = useAnimatedStyle(() => ({
    transform: reducedMotion ? [] : [
      { translateY: interpolate(scrollY.value, [0, 300], [0, 82], Extrapolation.CLAMP) },
      { scale: interpolate(scrollY.value, [-100, 0, 300], [1.06, 1, 0.94], Extrapolation.CLAMP) }
    ],
    opacity: interpolate(scrollY.value, [0, 330], [1, 0.42], Extrapolation.CLAMP)
  }));

  const latest = saved.data?.outfits[0];
  const items = closet.data?.items ?? [];
  const latestItems = useMemo(() => latest ? items.filter((item) => latest.item_ids.includes(item.id)) : [], [latest, items]);
  const missing = stats.data?.missing_essentials ?? [];
  const firstName = profile.data?.display_name?.split(" ")[0] || "there";

  return (
    <LinearGradient colors={gradients.hero} style={styles.root}>
      <StatusBar style="dark" />
      <SafeAreaView style={styles.safe} edges={["top", "left", "right"]}>
        <Animated.ScrollView
          contentInsetAdjustmentBehavior="automatic"
          onScroll={scrollHandler}
          scrollEventThrottle={16}
          showsVerticalScrollIndicator={false}
          contentContainerStyle={styles.scroll}
        >
          <Animated.View style={[styles.hero, heroMotion]}>
            <View style={styles.topRow}>
              <View>
                <Eyebrow>Good to see you, {firstName}</Eyebrow>
                <AppText style={styles.date}>Your closet is ready</AppText>
              </View>
              <Pressable accessibilityRole="button" accessibilityLabel="Open profile" onPress={() => router.push("/profile")} style={styles.avatar}>
                <AppText style={styles.avatarText}>{firstName.slice(0, 1).toUpperCase()}</AppText>
              </Pressable>
            </View>

            <View style={styles.heroCopy}>
              <Display>Wear more of what you love.</Display>
              <AppText style={styles.heroNote}>A living edit of your wardrobe—styled for real plans, real weather, and your own taste.</AppText>
            </View>

            <View style={styles.wardrobeStage}>
              <View style={styles.glow} />
              <OutfitRail items={latestItems.length ? latestItems : items.slice(0, 4)} />
              <View style={styles.stageBadge}>
                <Ionicons name="sparkles" size={15} color={colors.gold} />
                <AppText style={styles.stageBadgeText}>{latest ? "Latest saved edit" : items.length ? "Your wardrobe rail" : "Add your first piece"}</AppText>
              </View>
            </View>
          </Animated.View>

          <View style={styles.content}>
            <Reveal>
              <View style={styles.metrics}>
                <Metric value={stats.data?.total_items ?? 0} label="pieces catalogued" tone="rose" icon="shirt-outline" />
                <Metric value={saved.data?.total ?? 0} label="looks on repeat" tone="gold" icon="bookmark-outline" />
              </View>
            </Reveal>

            <Reveal delay={70}>
              <LinearGradient colors={gradients.surface} style={styles.stylistCard}>
                <View style={styles.stylistTop}>
                  <View style={styles.stylistIcon}><Ionicons name="sparkles" size={22} color={colors.roseSoft} /></View>
                  <View style={styles.stylistCopy}>
                    <Eyebrow>Today’s stylist note</Eyebrow>
                    <AppText style={styles.stylistTitle}>{missing.length ? "Your next useful additions" : "Your closet is ready to style"}</AppText>
                  </View>
                </View>
                <AppText style={styles.stylistNote}>{missing.length ? `Adding ${missing.slice(0, 2).join(" and ")} would unlock more complete combinations.` : "Pick the occasion and let FitSync assemble a wearable look from your logged pieces."}</AppText>
                <Button title={items.length ? "Style my next look" : "Add my first piece"} onPress={() => router.push(items.length ? "/generate" : "/add-item")} />
              </LinearGradient>
            </Reveal>

            <Reveal delay={130}>
              <View style={styles.section}>
                <SectionHeader eyebrow="Shortcuts" title="Keep the closet moving" />
                <View style={styles.quickGrid}>
                  <QuickAction title="Add a piece" note="Camera or library" icon="camera-outline" tone="rose" onPress={() => router.push("/add-item")} />
                  <QuickAction title="Open closet" note={`${items.length} pieces logged`} icon="grid-outline" tone="plum" onPress={() => router.push("/closet")} />
                  <QuickAction title="Saved looks" note={`${saved.data?.total ?? 0} ready to repeat`} icon="bookmark-outline" tone="gold" onPress={() => router.push("/saved")} />
                </View>
              </View>
            </Reveal>

            {latest ? (
              <Reveal delay={190}>
                <Pressable accessibilityRole="button" accessibilityLabel="Open saved looks" onPress={() => router.push("/saved")} style={({ pressed }) => [styles.latest, pressed && styles.pressed]}>
                  <View style={styles.latestCopy}>
                    <Eyebrow>{latest.occasion} · {Math.round(latest.score * 100)}% match</Eyebrow>
                    <AppText style={styles.latestName}>{latest.name}</AppText>
                    <AppText numberOfLines={3} style={styles.latestNote}>{latest.explanation}</AppText>
                  </View>
                  <OutfitRail items={latestItems} compact />
                </Pressable>
              </Reveal>
            ) : null}
          </View>
        </Animated.ScrollView>
      </SafeAreaView>
    </LinearGradient>
  );
}

function Metric({ value, label, tone, icon }: { value: number; label: string; tone: "rose" | "gold"; icon: keyof typeof Ionicons.glyphMap }) {
  return (
    <View style={styles.metric}>
      <View style={[styles.metricIcon, tone === "rose" ? styles.metricRose : styles.metricGold]}><Ionicons name={icon} size={18} color={tone === "rose" ? colors.roseSoft : colors.gold} /></View>
      <AppText selectable style={styles.metricValue}>{value}</AppText>
      <AppText style={styles.metricLabel}>{label}</AppText>
    </View>
  );
}

function QuickAction({ title, note, icon, tone, onPress }: { title: string; note: string; icon: keyof typeof Ionicons.glyphMap; tone: "rose" | "plum" | "gold"; onPress: () => void }) {
  const toneStyle = tone === "rose" ? styles.quickRose : tone === "plum" ? styles.quickPlum : styles.quickGold;
  const iconColor = tone === "rose" ? colors.roseSoft : tone === "plum" ? "#B9A7FF" : colors.gold;
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={title} onPress={onPress} style={({ pressed }) => [styles.quick, pressed && styles.pressed]}>
      <View style={[styles.quickIcon, toneStyle]}><Ionicons name={icon} size={21} color={iconColor} /></View>
      <View style={styles.quickCopy}><AppText style={styles.quickTitle}>{title}</AppText><AppText style={styles.quickNote}>{note}</AppText></View>
      <Ionicons name="arrow-forward" size={17} color={colors.faint} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.canvas },
  safe: { flex: 1 },
  scroll: { paddingBottom: 120 },
  hero: { paddingHorizontal: spacing.xl, paddingTop: spacing.lg, gap: spacing.xl },
  topRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", gap: spacing.lg },
  date: { color: colors.muted, fontSize: 13, lineHeight: 18 },
  avatar: { width: 48, height: 48, borderRadius: 24, borderWidth: 1, borderColor: colors.roseSoft, backgroundColor: colors.roseWash, alignItems: "center", justifyContent: "center" },
  avatarText: { color: colors.roseSoft, fontWeight: "900" },
  heroCopy: { gap: spacing.md },
  heroNote: { color: colors.inkSoft, fontSize: 17, lineHeight: 26, maxWidth: 520 },
  wardrobeStage: { minHeight: 210, justifyContent: "center" },
  glow: { position: "absolute", width: 230, height: 150, borderRadius: 130, alignSelf: "center", backgroundColor: colors.roseWash, transform: [{ scaleX: 1.35 }] },
  stageBadge: { alignSelf: "center", flexDirection: "row", alignItems: "center", gap: spacing.xs, borderRadius: radius.pill, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.strokeStrong, paddingHorizontal: spacing.md, paddingVertical: spacing.sm, marginTop: -4 },
  stageBadgeText: { color: colors.inkSoft, fontSize: 12, lineHeight: 16, fontWeight: "700" },
  content: { paddingHorizontal: spacing.xl, paddingTop: spacing.xl, gap: spacing.xxl, backgroundColor: colors.canvas, borderTopLeftRadius: radius.xl, borderTopRightRadius: radius.xl, borderCurve: "continuous" },
  metrics: { flexDirection: "row", gap: spacing.md },
  metric: { flex: 1, minHeight: 156, backgroundColor: colors.surface, borderRadius: radius.lg, borderCurve: "continuous", borderWidth: 1, borderColor: colors.stroke, padding: spacing.lg, justifyContent: "space-between", boxShadow: shadows.card },
  metricIcon: { width: 40, height: 40, borderRadius: radius.md, alignItems: "center", justifyContent: "center" },
  metricRose: { backgroundColor: colors.roseWash },
  metricGold: { backgroundColor: colors.goldWash },
  metricValue: { fontSize: 38, lineHeight: 42, fontWeight: "900", fontVariant: ["tabular-nums"] },
  metricLabel: { color: colors.muted, fontSize: 13, lineHeight: 18 },
  stylistCard: { borderRadius: radius.xl, borderCurve: "continuous", borderWidth: 1, borderColor: colors.strokeStrong, padding: spacing.xl, gap: spacing.lg, overflow: "hidden", boxShadow: shadows.card },
  stylistTop: { flexDirection: "row", alignItems: "center", gap: spacing.md },
  stylistIcon: { width: 48, height: 48, borderRadius: radius.md, backgroundColor: colors.roseWash, alignItems: "center", justifyContent: "center" },
  stylistCopy: { flex: 1, gap: spacing.xs },
  stylistTitle: { fontSize: 19, lineHeight: 24, fontWeight: "800" },
  stylistNote: { color: colors.muted },
  section: { gap: spacing.lg },
  quickGrid: { gap: spacing.md },
  quick: { minHeight: 78, flexDirection: "row", alignItems: "center", gap: spacing.md, padding: spacing.md, backgroundColor: colors.surface, borderRadius: radius.lg, borderCurve: "continuous", borderWidth: 1, borderColor: colors.stroke },
  quickIcon: { width: 48, height: 48, borderRadius: radius.md, alignItems: "center", justifyContent: "center" },
  quickRose: { backgroundColor: colors.roseWash },
  quickPlum: { backgroundColor: colors.plumWash },
  quickGold: { backgroundColor: colors.goldWash },
  quickCopy: { flex: 1, gap: spacing.xxs },
  quickTitle: { fontWeight: "800" },
  quickNote: { color: colors.muted, fontSize: 13, lineHeight: 18 },
  latest: { flexDirection: "row", gap: spacing.lg, alignItems: "center", backgroundColor: colors.surface, borderRadius: radius.xl, borderCurve: "continuous", borderWidth: 1, borderColor: colors.stroke, padding: spacing.xl, boxShadow: shadows.card },
  latestCopy: { flex: 1, gap: spacing.sm },
  latestName: { fontSize: 21, lineHeight: 26, fontWeight: "900" },
  latestNote: { color: colors.muted, fontSize: 14, lineHeight: 20 },
  pressed: { opacity: 0.74, transform: [{ scale: 0.99 }] }
});
