import { useMemo } from "react";
import { ScrollView, StyleSheet, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { LinearGradient } from "expo-linear-gradient";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText, Display, Punch } from "@/components/AppText";
import { Button } from "@/components/Button";
import { PressableScale, Reveal } from "@/components/motion";
import { Photo } from "@/components/Photo";
import { PreviewNote } from "@/components/PreviewNote";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_TREND_DETAIL, SEED_TRENDS } from "@/data/discover";
import { Flame, Sparkles } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, layout, radius, spacing } from "@/theme";

export default function TrendDetail() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const closet = useCloset();

  const trend = SEED_TRENDS.find((entry) => entry.id === id);
  const detail = trend ? { ...SEED_TREND_DETAIL, name: trend.name, category: trend.category, growth: trend.growth } : SEED_TREND_DETAIL;
  const items = closet.data?.items ?? [];
  // Match the trend's palette against the member's own pieces.
  const matches = useMemo(() => {
    const paletteNames = detail.palette.map((entry) => entry.name.toLowerCase());
    const matched = items.filter((item) => item.colors.some((color) => paletteNames.includes(color.toLowerCase())));
    return (matched.length ? matched : items).slice(0, 3);
  }, [items, detail.palette]);
  const heroImage = mediaUrl(items[0]?.image_url);

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen footer={<Button title="Style a look around this" icon={Sparkles} variant="accent" onPress={() => router.push("/style")} />}>
      <PushHeader title="Trend" onBack={() => router.back()} />
      <Reveal>
        <View style={styles.hero}>
          {heroImage ? <Photo source={heroImage} /> : <View style={styles.placeholder} />}
          <LinearGradient colors={["rgba(13,13,15,0)", "rgba(13,13,15,0.82)"]} style={styles.fade} />
          <View style={styles.heroCopy}>
            <View style={styles.growth}><Flame size={13} color={colors.ink} fill={colors.ink} /><Punch style={styles.growthText}>+{detail.growth}% this season</Punch></View>
            <Punch style={styles.category}>{detail.category}</Punch>
            <Display style={styles.title}>{detail.name}</Display>
          </View>
        </View>
      </Reveal>
      <PreviewNote />
      <AppText style={styles.description}>{detail.description}</AppText>

      <View style={styles.section}>
        <Punch style={styles.label}>Palette</Punch>
        <View style={styles.palette}>
          {detail.palette.map((entry) => (
            <View key={entry.name} style={styles.paletteCell}>
              <View style={[styles.paletteSwatch, { backgroundColor: entry.value }]} />
              <AppText style={styles.paletteName}>{entry.name}</AppText>
            </View>
          ))}
        </View>
        <View style={styles.tags}>{detail.tags.map((tag) => <View key={tag} style={styles.tag}><AppText style={styles.tagText}>{tag}</AppText></View>)}</View>
      </View>

      <View style={styles.section}>
        <Punch style={styles.label}>{matches.length ? `From your closet · ${matches.length} pieces already fit` : "Nothing in your closet fits this yet"}</Punch>
        {matches.length ? (
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.bleed} contentContainerStyle={styles.rail}>
            {matches.map((item) => (
              <PressableScale key={item.id} accessibilityRole="button" accessibilityLabel={item.name} onPress={() => router.push(`/item/${item.id}`)} style={styles.tile}>
                <View style={styles.tileMedia}>{mediaUrl(item.image_url) ? <Photo source={mediaUrl(item.image_url)!} /> : <View style={styles.placeholder} />}</View>
                <AppText numberOfLines={1} style={styles.tileName}>{item.name}</AppText>
              </PressableScale>
            ))}
          </ScrollView>
        ) : null}
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  hero: { height: 340, borderRadius: radius.xl, overflow: "hidden", backgroundColor: colors.stage },
  placeholder: { flex: 1, backgroundColor: colors.canvasSoft },
  fade: { position: "absolute", left: 0, right: 0, bottom: 0, height: "70%" },
  heroCopy: { position: "absolute", left: spacing.xl, right: spacing.xl, bottom: spacing.xl, gap: spacing.sm },
  growth: { flexDirection: "row", alignItems: "center", gap: 5, alignSelf: "flex-start", backgroundColor: colors.accent, borderRadius: radius.pill, paddingHorizontal: 10, height: 28 },
  growthText: { fontSize: 9, lineHeight: 11 },
  category: { color: colors.onStageMuted, fontSize: 10 },
  title: { color: colors.onStage, fontSize: 46, lineHeight: 46 },
  description: { color: colors.inkSoft, fontSize: 16, lineHeight: 24 },
  section: { gap: spacing.md },
  label: { color: colors.muted },
  palette: { flexDirection: "row", gap: spacing.sm },
  paletteCell: { flex: 1, gap: 6 },
  paletteSwatch: { height: 64, borderRadius: radius.md, borderWidth: 1, borderColor: colors.stroke },
  paletteName: { color: colors.inkSoft, fontSize: 12, fontFamily: fonts.medium },
  tags: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  tag: { backgroundColor: colors.surface, borderRadius: radius.pill, paddingHorizontal: spacing.md, height: 30, justifyContent: "center", borderWidth: 1, borderColor: colors.stroke },
  tagText: { fontSize: 12, color: colors.inkSoft, fontFamily: fonts.medium },
  bleed: { marginHorizontal: -layout.gutter },
  rail: { paddingHorizontal: layout.gutter, gap: spacing.md },
  tile: { width: 124, gap: spacing.xs },
  tileMedia: { height: 156, borderRadius: radius.lg, overflow: "hidden", backgroundColor: colors.surface },
  tileName: { fontSize: 13, fontFamily: fonts.medium }
});
