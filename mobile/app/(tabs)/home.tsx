import { useMemo } from "react";
import { Pressable, ScrollView, StyleSheet, View } from "react-native";
import { router } from "expo-router";
import { useCloset, useClosetStats, useProfile, useSavedOutfits } from "@/api/queries";
import { mediaUrl } from "@/api/client";
import { AppText, Display, Eyebrow } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Glyph } from "@/components/Glyph";
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
  const hasItems = items.length > 0;

  const heroTitle = !hasItems
    ? "Your closet starts here."
    : latest
      ? "Tonight's edit is already in your closet."
      : "Your closet is stocked. Time to style it.";
  const heroNote = !hasItems
    ? "Photograph your first piece and FitSync starts styling from what you actually own — not a catalog."
    : latest
      ? "A living edit of your wardrobe—styled for real plans, real weather, and your own taste."
      : `${items.length} ${items.length === 1 ? "piece" : "pieces"} logged. Let FitSync assemble your first look.`;

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
          <Display style={styles.heroTitle}>{heroTitle}</Display>
          <AppText style={styles.heroNote}>{heroNote}</AppText>
        </View>
      </Reveal>

      {latest ? (
        <Reveal delay={60}>
          <Pressable accessibilityRole="button" accessibilityLabel="Open saved looks" onPress={() => router.push("/saved")} style={styles.latest}>
            <View style={styles.latestMedia}>
              {mediaUrl(latestItems[0]?.image_url) ? <Photo source={mediaUrl(latestItems[0]!.image_url)!} /> : null}
            </View>
            <View style={styles.latestCopy}>
              <Eyebrow>{latest.occasion} · {Math.round(latest.score * 100)}% match</Eyebrow>
              <AppText style={styles.latestName}>{latest.name}</AppText>
              <AppText numberOfLines={2} style={styles.latestNote}>{latest.explanation}</AppText>
              <AppText style={styles.latestCta}>Open saved looks →</AppText>
            </View>
          </Pressable>
        </Reveal>
      ) : null}

      <Reveal delay={latest ? 100 : 60}>
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
              <Pressable accessibilityRole="button" accessibilityLabel="Add your first piece" onPress={() => router.push("/add-item")} style={styles.railEmpty}>
                <AppText style={styles.railEmptyText}>Add your first piece →</AppText>
              </Pressable>
            )}
          </ScrollView>
          <View style={styles.railFooter}>
            <SparkIcon size={13} color={colors.roseSoft} />
            <AppText style={styles.railFooterText}>{latest ? `Latest saved edit · ${latestItems.length} pieces` : items.length ? "Your wardrobe rail" : "Add your first piece"}</AppText>
          </View>
        </View>
      </Reveal>

      {hasItems ? (
        <View style={styles.metrics}>
          <Metric value={stats.data?.total_items ?? 0} label="pieces catalogued" />
          <Metric value={saved.data?.total ?? 0} label="looks on repeat" />
        </View>
      ) : null}

      <Reveal delay={hasItems ? 140 : 100}>
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
        <View style={styles.tileGrid}>
          <Tile shape="diamond" title="Saved looks" note={`${saved.data?.total ?? 0} ready`} onPress={() => router.push("/saved")} />
          <Tile shape="moonLeft" title="Try-on" note="Preview a look" onPress={() => router.push("/tryon?from=look")} />
          <Tile shape="leaf" title="Community" note="What people wear" onPress={() => router.push("/community")} />
          <Tile shape="drop" title="Trends" note="What's rising" onPress={() => router.push("/trends")} />
        </View>
      </View>
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

function Tile({ shape, title, note, onPress }: { shape: Parameters<typeof Glyph>[0]["shape"]; title: string; note: string; onPress: () => void }) {
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={title} onPress={onPress} style={styles.tile}>
      <Glyph shape={shape} size={18} strokeWidth={2} color={colors.roseSoft} />
      <AppText style={styles.tileTitle}>{title}</AppText>
      <AppText style={styles.tileNote}>{note}</AppText>
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
  latest: { borderBottomWidth: 2, borderColor: colors.strokeStrong },
  latestMedia: { width: "100%", height: 240, backgroundColor: colors.surface },
  latestCopy: { padding: spacing.xl, gap: spacing.sm },
  latestName: { fontSize: 26, lineHeight: 27, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.6, textTransform: "uppercase" },
  latestNote: { color: colors.muted, fontSize: 13, lineHeight: 19 },
  latestCta: { color: colors.roseSoft, fontSize: 11, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase", marginTop: spacing.xs },
  railSection: { borderBottomWidth: 1, borderColor: colors.stroke },
  rail: { flexGrow: 0 },
  railItem: { width: 126, height: 168, borderRightWidth: 1, borderColor: colors.stroke, backgroundColor: colors.surface, justifyContent: "flex-end" },
  railPlaceholder: { ...StyleSheet.absoluteFillObject, backgroundColor: colors.surface },
  railLabel: { position: "absolute", left: spacing.sm, bottom: spacing.sm, color: colors.white, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  railEmpty: { width: "100%", height: 168, alignItems: "center", justifyContent: "center" },
  railEmptyText: { color: colors.roseSoft, fontSize: 13, fontFamily: fonts.bold, fontWeight: "700" },
  railFooter: { flexDirection: "row", alignItems: "center", gap: spacing.sm, paddingHorizontal: spacing.xl, paddingVertical: spacing.md, borderTopWidth: 1, borderColor: colors.stroke },
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
  tileGrid: { flexDirection: "row", flexWrap: "wrap", borderTopWidth: 1, borderColor: colors.stroke },
  tile: { width: "50%", paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, gap: spacing.xs, borderRightWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke },
  tileTitle: { fontFamily: fonts.black, fontWeight: "800", fontSize: 13, letterSpacing: -0.1, marginTop: spacing.xs },
  tileNote: { color: colors.muted, fontSize: 10, lineHeight: 14 }
});
