import { useMemo } from "react";
import { Pressable, ScrollView, StyleSheet, View } from "react-native";
import { router } from "expo-router";
import { useCloset, useClosetStats, useProfile, useSavedOutfits } from "@/api/queries";
import { mediaUrl } from "@/api/client";
import { AppText, Display, Eyebrow } from "@/components/AppText";
import { Button } from "@/components/Button";
import { SparkIcon } from "@/components/Icon";
import { Photo } from "@/components/Photo";
import { Reveal } from "@/components/motion";
import { Screen } from "@/components/Screen";
import { colors, fonts, spacing } from "@/theme";

export default function Home() {
  const profile = useProfile();
  const stats = useClosetStats();
  const saved = useSavedOutfits();
  const closet = useCloset();

  const latest = saved.data?.outfits[0];
  const items = closet.data?.items ?? [];
  const latestItems = useMemo(() => latest ? items.filter((item) => latest.item_ids.includes(item.id)) : [], [latest, items]);
  const railItems = (latestItems.length ? latestItems : items).slice(0, 6);
  const missing = stats.data?.missing_essentials ?? [];
  const firstName = profile.data?.display_name?.split(" ")[0] || "there";

  return (
    <Screen scroll bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.topRow}>
        <View>
          <Eyebrow>Good to see you, {firstName}</Eyebrow>
          <AppText style={styles.date}>Your closet is ready</AppText>
        </View>
        <Pressable accessibilityRole="button" accessibilityLabel="Open profile" onPress={() => router.push("/profile")} style={styles.avatar}>
          <AppText style={styles.avatarText}>{firstName.slice(0, 1).toUpperCase()}</AppText>
        </Pressable>
      </View>

      <Reveal>
        <View style={styles.hero}>
          <Display style={styles.heroTitle}>Tonight's edit is already in your closet.</Display>
          <AppText style={styles.heroNote}>A living edit of your wardrobe—styled for real plans, real weather, and your own taste.</AppText>
        </View>
      </Reveal>

      <Reveal delay={60}>
        <View style={styles.railSection}>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.rail}>
            {railItems.length ? railItems.map((item) => {
              const url = mediaUrl(item.image_url);
              return (
                <Pressable key={item.id} accessibilityRole="button" accessibilityLabel={item.name} onPress={() => router.push(`/item/${item.id}`)} style={styles.railItem}>
                  {url ? <Photo source={url} /> : <View style={styles.railPlaceholder} />}
                  <AppText numberOfLines={1} style={styles.railLabel}>{item.name}</AppText>
                </Pressable>
              );
            }) : (
              <View style={styles.railEmpty}><AppText style={styles.railEmptyText}>Add your first piece</AppText></View>
            )}
          </ScrollView>
          <View style={styles.railFooter}>
            <SparkIcon size={13} color={colors.roseSoft} />
            <AppText style={styles.railFooterText}>{latest ? `Latest saved edit · ${latestItems.length} pieces` : items.length ? "Your wardrobe rail" : "Add your first piece"}</AppText>
          </View>
        </View>
      </Reveal>

      <View style={styles.metrics}>
        <Metric value={stats.data?.total_items ?? 0} label="pieces catalogued" />
        <Metric value={saved.data?.total ?? 0} label="looks on repeat" />
      </View>

      <Reveal delay={120}>
        <View style={styles.stylistCard}>
          <View style={styles.stylistTop}>
            <SparkIcon size={13} color={colors.roseSoft} />
            <Eyebrow>Today's stylist note</Eyebrow>
          </View>
          <AppText style={styles.stylistTitle}>{missing.length ? "Your next useful additions" : "Your closet is ready to style"}</AppText>
          <AppText style={styles.stylistNote}>{missing.length ? `Adding ${missing.slice(0, 2).join(" and ")} would unlock more complete combinations.` : "Pick the occasion and let FitSync assemble a wearable look from your logged pieces."}</AppText>
          <Button title={items.length ? "Style my next look" : "Add my first piece"} icon="sparkles" onPress={() => router.push(items.length ? "/generate" : "/add-item")} />
        </View>
      </Reveal>

      <View style={styles.section}>
        <AppText style={styles.sectionLabel}>Shortcuts</AppText>
        <QuickAction num="01" title="Add a piece" note="Camera or library" onPress={() => router.push("/add-item")} />
        <QuickAction num="02" title="Open closet" note={`${items.length} pieces logged`} onPress={() => router.push("/closet")} />
        <QuickAction num="03" title="Saved looks" note={`${saved.data?.total ?? 0} ready to repeat`} onPress={() => router.push("/saved")} />
        <QuickAction num="04" title="Virtual try-on" note="Preview a look on your photo" onPress={() => router.push("/tryon?from=look")} />
        <QuickAction num="05" title="Community" note="See what people are wearing" onPress={() => router.push("/community")} />
        <QuickAction num="06" title="Trends & nearby" note="Quiet crimson is up 34%" onPress={() => router.push("/trends")} />
      </View>

      {latest ? (
        <Reveal delay={180}>
          <Pressable accessibilityRole="button" accessibilityLabel="Open saved looks" onPress={() => router.push("/saved")} style={styles.latest}>
            <View style={styles.latestCopy}>
              <Eyebrow>{latest.occasion} · {Math.round(latest.score * 100)}% match</Eyebrow>
              <AppText style={styles.latestName}>{latest.name}</AppText>
              <AppText numberOfLines={3} style={styles.latestNote}>{latest.explanation}</AppText>
            </View>
            <View style={styles.latestMedia}>
              {mediaUrl(latestItems[0]?.image_url) ? <Photo source={mediaUrl(latestItems[0]!.image_url)!} /> : null}
            </View>
          </Pressable>
        </Reveal>
      ) : null}
      <View style={{ height: 40 }} />
    </Screen>
  );
}

function Metric({ value, label }: { value: number; label: string }) {
  return (
    <View style={styles.metric}>
      <AppText selectable style={styles.metricValue}>{value}</AppText>
      <AppText style={styles.metricLabel}>{label}</AppText>
    </View>
  );
}

function QuickAction({ num, title, note, onPress }: { num: string; title: string; note: string; onPress: () => void }) {
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={title} onPress={onPress} style={styles.quick}>
      <AppText style={styles.quickNum}>{num}</AppText>
      <View style={styles.quickCopy}>
        <AppText style={styles.quickTitle}>{title}</AppText>
        <AppText style={styles.quickNote}>{note}</AppText>
      </View>
      <AppText style={styles.quickArrow}>→</AppText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  topRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", gap: spacing.lg, paddingHorizontal: spacing.xl, paddingBottom: spacing.lg },
  date: { color: colors.ink, fontSize: 13, lineHeight: 18, marginTop: spacing.xs, fontFamily: fonts.medium },
  avatar: { width: 42, height: 42, borderWidth: 2, borderColor: colors.strokeStrong, alignItems: "center", justifyContent: "center" },
  avatarText: { color: colors.ink, fontFamily: fonts.black, fontWeight: "800", fontSize: 15 },
  hero: { paddingHorizontal: spacing.xl, paddingBottom: spacing.xl, borderBottomWidth: 2, borderColor: colors.strokeStrong, gap: spacing.md },
  heroTitle: { fontSize: 42, lineHeight: 40 },
  heroNote: { color: colors.muted, fontSize: 13, lineHeight: 20 },
  railSection: { borderBottomWidth: 1, borderColor: colors.stroke },
  rail: { flexGrow: 0 },
  railItem: { width: 126, height: 168, borderRightWidth: 1, borderColor: colors.stroke, backgroundColor: colors.surface, justifyContent: "flex-end" },
  railImage: { ...StyleSheet.absoluteFillObject },
  railPlaceholder: { ...StyleSheet.absoluteFillObject, backgroundColor: colors.surface },
  railLabel: { position: "absolute", left: spacing.sm, bottom: spacing.sm, color: colors.white, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  railEmpty: { width: "100%", height: 168, alignItems: "center", justifyContent: "center" },
  railEmptyText: { color: colors.muted, fontSize: 13 },
  railFooter: { flexDirection: "row", alignItems: "center", gap: spacing.sm, paddingHorizontal: spacing.xl, paddingVertical: spacing.md, borderTopWidth: 1, borderColor: colors.stroke },
  spark: { width: 8, height: 8, backgroundColor: colors.roseSoft, transform: [{ rotate: "45deg" }] },
  railFooterText: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  metrics: { flexDirection: "row", borderBottomWidth: 1, borderColor: colors.stroke },
  metric: { flex: 1, paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, borderRightWidth: 1, borderColor: colors.stroke },
  metricValue: { fontSize: 46, lineHeight: 42, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -1.4, fontVariant: ["tabular-nums"] },
  metricLabel: { color: colors.muted, fontSize: 9, lineHeight: 13, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase", marginTop: spacing.xs },
  stylistCard: { backgroundColor: colors.surface, borderBottomWidth: 1, borderColor: colors.stroke, paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, gap: spacing.sm },
  stylistTop: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  stylistTitle: { fontSize: 24, lineHeight: 26, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.6, marginTop: spacing.xs },
  stylistNote: { color: colors.muted, fontSize: 13, lineHeight: 20 },
  section: { paddingTop: spacing.xs },
  sectionLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6, textTransform: "uppercase", paddingHorizontal: spacing.xl, paddingVertical: spacing.md },
  quick: { flexDirection: "row", alignItems: "center", gap: spacing.md, paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, borderTopWidth: 1, borderColor: colors.stroke },
  quickNum: { color: colors.roseSoft, fontFamily: fonts.black, fontWeight: "800", fontSize: 11, fontVariant: ["tabular-nums"] },
  quickCopy: { flex: 1, gap: spacing.xxs },
  quickTitle: { fontFamily: fonts.black, fontWeight: "800", fontSize: 15, letterSpacing: -0.2 },
  quickNote: { color: colors.muted, fontSize: 11, lineHeight: 15, marginTop: 2 },
  quickArrow: { color: colors.muted, fontSize: 15 },
  latest: { flexDirection: "row", borderTopWidth: 2, borderColor: colors.strokeStrong, marginTop: spacing.lg },
  latestCopy: { flex: 1, padding: spacing.xl, gap: spacing.sm },
  latestName: { fontSize: 21, lineHeight: 23, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.5, textTransform: "uppercase" },
  latestNote: { color: colors.muted, fontSize: 12, lineHeight: 18 },
  latestMedia: { width: 104, backgroundColor: colors.surface, borderLeftWidth: 1, borderColor: colors.stroke, overflow: "hidden" }
});
