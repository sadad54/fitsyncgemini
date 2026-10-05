import { useEffect, useMemo, useRef } from "react";
import { StyleSheet, View } from "react-native";
import { router } from "expo-router";
import Animated, { useAnimatedStyle, useDerivedValue, withTiming } from "react-native-reanimated";
import { ArrowRight, Check, CloudSun, Heart, ImagePlus, Shirt, Shuffle, Sparkles, UserRound } from "lucide-react-native";
import { useCloset, useOutfits, useProfile, useSaveOutfit, useTryOns } from "@/api/queries";
import { mediaUrl } from "@/api/client";
import { AppText, Caption, Display, Eyebrow, Heading, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { IconButton } from "@/components/IconButton";
import { Photo } from "@/components/Photo";
import { PressableScale, Reveal, SETTLE, Skeleton } from "@/components/motion";
import { OutfitCollage } from "@/components/outfit-rail";
import { Screen } from "@/components/Screen";
import { SectionHeader } from "@/components/section-header";
import { tryOnHref, tryOnSubset } from "@/lib/tryon";
import { useStyleOutfit, weatherLabel } from "@/lib/useStyleOutfit";
import { useFitPhoto } from "@/store/fitPhoto";
import { colors, fonts, radius, spacing } from "@/theme";

function greeting() {
  const hour = new Date().getHours();
  return hour < 5 ? "Good evening" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening";
}

const isToday = (iso: string) => new Date(iso).toDateString() === new Date().toDateString();

export default function Today() {
  const profile = useProfile();
  const closet = useCloset();
  const outfits = useOutfits(false);
  const saved = useOutfits(true);
  const tryons = useTryOns();
  const save = useSaveOutfit();
  const fitPhoto = useFitPhoto();
  const { style, generate } = useStyleOutfit();
  const autoStyled = useRef(false);

  useEffect(() => { fitPhoto.load(); }, []);

  const items = closet.data?.items ?? [];
  const todays = generate.data ?? outfits.data?.outfits.find((outfit) => isToday(outfit.created_at));
  const lookItems = useMemo(() => todays ? items.filter((item) => todays.item_ids.includes(item.id)) : [], [todays, items]);
  const canTry = tryOnSubset(lookItems).length > 0;
  const firstName = profile.data?.display_name?.split(" ")[0];
  const isSaved = Boolean(todays?.saved || save.data?.id === todays?.id);
  const lastTryOn = tryons.data?.results.find((job) => job.status === "completed" && job.result_image_url);
  const fitting = tryons.data?.results.find((job) => job.status === "queued" || job.status === "processing");
  const weather = weatherLabel(todays?.weather_context);

  // Today's look is ready when you open the app: style one quietly if the
  // closet can support it and nothing was styled yet today.
  useEffect(() => {
    if (autoStyled.current || !outfits.isSuccess || !closet.isSuccess || todays || items.length < 2) return;
    autoStyled.current = true;
    style({ occasion: "casual", weather: true, askForLocation: false }).catch(() => {});
  }, [outfits.isSuccess, closet.isSuccess, todays, items.length]);

  const steps = [
    { done: items.length >= 3, label: "Add 3 pieces to your closet", action: () => router.push("/add-item") },
    { done: Boolean(fitPhoto.uri), label: "Add your fit photo", action: () => router.push("/profile") },
    { done: (tryons.data?.total ?? 0) > 0, label: "Try on your first look", action: () => router.push(todays && canTry ? tryOnHref(lookItems) : "/style") },
    { done: (saved.data?.total ?? 0) > 0, label: "Save a look you love", action: () => router.push("/style") }
  ];
  const showChecklist = closet.isSuccess && tryons.isSuccess && steps.some((step) => !step.done);
  const dateLine = new Date().toLocaleDateString(undefined, { weekday: "long", day: "numeric", month: "long" });

  return (
    <Screen tabbed refreshing={outfits.isRefetching} onRefresh={() => { outfits.refetch(); closet.refetch(); tryons.refetch(); }}>
      <Reveal>
        <View style={styles.header}>
          <View style={styles.headerCopy}>
            <Eyebrow>{dateLine}</Eyebrow>
            <Display style={styles.hello}>{greeting()}{firstName ? `,\n${firstName}` : ""}</Display>
          </View>
          <IconButton icon={UserRound} label="Profile and settings" tone="solid" onPress={() => router.push("/profile")} />
        </View>
      </Reveal>

      <Reveal delay={80}>
        {closet.isLoading || outfits.isLoading ? (
          <View style={styles.card}><Skeleton style={{ height: 320, borderRadius: radius.lg }} /><Skeleton style={{ height: 22, width: "60%" }} /></View>
        ) : items.length < 2 ? (
          <EmptyCloset count={items.length} />
        ) : (
          <View style={styles.card}>
            <View style={styles.cardTop}>
              <View style={styles.badge}><Sparkles size={13} color={colors.accent} strokeWidth={2.2} /><AppText style={styles.badgeText}>Today's look</AppText></View>
              {weather ? <View style={styles.weather}><CloudSun size={14} color={colors.inkSoft} /><AppText style={styles.weatherText}>{weather}</AppText></View> : null}
            </View>
            {todays && !generate.isPending ? (
              <>
                <OutfitCollage items={lookItems} animateKey={todays.id} height={330} />
                <View style={styles.copy}>
                  <Title style={styles.lookName}>{todays.name}</Title>
                  <AppText numberOfLines={3} style={styles.explain}>{todays.explanation}</AppText>
                </View>
                <View style={styles.actions}>
                  <View style={styles.flex}>
                    <Button title="Try it on" icon={Sparkles} variant="accent" disabled={!canTry}
                      onPress={() => router.push(tryOnHref(lookItems, "&auto=1"))} />
                  </View>
                  <IconButton icon={Shuffle} label="Style a different look" tone="solid" size={54}
                    onPress={() => style({ occasion: todays.occasion || "casual", weather: true, askForLocation: false }).catch(() => {})} />
                  <IconButton icon={Heart} label={isSaved ? "Saved to Looks" : "Save to Looks"} tone="solid" size={54}
                    color={isSaved ? colors.danger : colors.ink} filled={isSaved}
                    onPress={() => !isSaved && save.mutate(todays.id)} />
                </View>
                {!canTry ? <Caption>Try-on works with tops, bottoms and dresses — this look has none.</Caption> : null}
              </>
            ) : (
              <View style={styles.styling}>
                <Skeleton style={{ height: 330, borderRadius: radius.lg }} />
                <View style={styles.stylingRow}>
                  <Sparkles size={16} color={colors.accent} />
                  <AppText style={styles.stylingText}>{generate.isPending ? "Styling today's look from your closet…" : "Your look for today isn't styled yet."}</AppText>
                </View>
                {!generate.isPending ? <Button title="Style today's look" icon={Sparkles} onPress={() => style({ occasion: "casual", weather: true, askForLocation: true }).catch(() => {})} /> : null}
              </View>
            )}
            {generate.error ? <AppText selectable style={styles.error}>{generate.error.message}</AppText> : null}
          </View>
        )}
      </Reveal>

      {showChecklist ? <Reveal delay={140}><Checklist steps={steps} /></Reveal> : null}

      {fitting || lastTryOn ? (
        <Reveal delay={190}>
          <View style={styles.section}>
            <SectionHeader title="Continue" action="All looks" onAction={() => router.navigate("/looks")} />
            <PressableScale accessibilityRole="button" accessibilityLabel={fitting ? "Try-on in progress" : "Open your last try-on"}
              onPress={() => router.push(`/tryon?job=${(fitting ?? lastTryOn)!.id}`)} style={styles.continueRow}>
              <View style={styles.continueThumb}>
                {mediaUrl((fitting ?? lastTryOn)!.result_image_url ?? (fitting ?? lastTryOn)!.person_image_url)
                  ? <Photo source={mediaUrl((fitting ?? lastTryOn)!.result_image_url ?? (fitting ?? lastTryOn)!.person_image_url)!} /> : null}
              </View>
              <View style={styles.flex}>
                <Heading>{fitting ? "Fitting in progress" : "Your last try-on"}</Heading>
                <Caption>{fitting ? "We'll keep working if you leave." : new Date(lastTryOn!.created_at).toLocaleDateString(undefined, { day: "numeric", month: "short" })}</Caption>
              </View>
              <ArrowRight size={18} color={colors.inkSoft} />
            </PressableScale>
          </View>
        </Reveal>
      ) : null}

      <Reveal delay={240}>
        <PressableScale accessibilityRole="button" accessibilityLabel="Open Discover" onPress={() => router.navigate("/discover")} style={styles.discover}>
          <View style={styles.flex}>
            <Eyebrow style={styles.discoverEyebrow}>This week</Eyebrow>
            <Title style={styles.discoverTitle}>Monochrome week</Title>
            <AppText style={styles.discoverNote}>Style one colour head to toe — from what you already own.</AppText>
          </View>
          <View style={styles.discoverArrow}><ArrowRight size={20} color={colors.ink} /></View>
        </PressableScale>
      </Reveal>
    </Screen>
  );
}

function EmptyCloset({ count }: { count: number }) {
  return (
    <View style={[styles.card, styles.emptyCard]}>
      <View style={styles.emptyArt}>
        <View style={[styles.emptyTile, { transform: [{ rotate: "-8deg" }] }]}><Shirt size={30} color={colors.inkSoft} strokeWidth={1.4} /></View>
        <View style={[styles.emptyTile, styles.emptyTileFront, { transform: [{ rotate: "6deg" }] }]}><ImagePlus size={30} color={colors.accent} strokeWidth={1.4} /></View>
      </View>
      <Title style={styles.emptyTitle}>{count ? "One more piece and we can style you" : "Start with three pieces"}</Title>
      <AppText style={styles.emptyNote}>Photograph clothes you already own. FitSync styles outfits from them and shows them on you.</AppText>
      <Button title={count ? "Add another piece" : "Add your first piece"} icon={ImagePlus} onPress={() => router.push("/add-item")} />
    </View>
  );
}

function Checklist({ steps }: { steps: { done: boolean; label: string; action: () => void }[] }) {
  const done = steps.filter((step) => step.done).length;
  const progress = useDerivedValue(() => withTiming(done / steps.length, { duration: 900, easing: SETTLE }), [done]);
  const bar = useAnimatedStyle(() => ({ width: `${progress.value * 100}%` }));
  return (
    <View style={styles.checklist}>
      <View style={styles.checkHead}>
        <Heading>Getting started</Heading>
        <AppText style={styles.checkCount}>{done} of {steps.length}</AppText>
      </View>
      <View style={styles.track}><Animated.View style={[styles.trackFill, bar]} /></View>
      {steps.map((step) => (
        <PressableScale key={step.label} accessibilityRole="button" accessibilityLabel={step.label} accessibilityState={{ checked: step.done }}
          disabled={step.done} onPress={step.action} style={styles.checkRow}>
          <View style={[styles.checkDot, step.done && styles.checkDotDone]}>{step.done ? <Check size={13} color={colors.onInk} strokeWidth={3} /> : null}</View>
          <AppText style={[styles.checkLabel, step.done && styles.checkLabelDone]}>{step.label}</AppText>
          {!step.done ? <ArrowRight size={16} color={colors.muted} /> : null}
        </PressableScale>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  header: { flexDirection: "row", alignItems: "flex-start", justifyContent: "space-between", gap: spacing.md, paddingTop: spacing.md },
  headerCopy: { flex: 1, gap: spacing.xs },
  hello: { fontSize: 42, lineHeight: 44 },
  card: { backgroundColor: colors.surface, borderRadius: radius.xl, padding: spacing.md, gap: spacing.lg, boxShadow: "0 1px 2px rgba(23,20,15,0.04), 0 12px 32px rgba(23,20,15,0.07)" },
  cardTop: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: spacing.xs, paddingTop: spacing.xs },
  badge: { flexDirection: "row", alignItems: "center", gap: 6, backgroundColor: colors.accentWash, paddingHorizontal: spacing.md, height: 30, borderRadius: radius.pill },
  badgeText: { color: colors.accent, fontSize: 13, fontFamily: fonts.semibold, fontWeight: "600" },
  weather: { flexDirection: "row", alignItems: "center", gap: 6 },
  weatherText: { color: colors.inkSoft, fontSize: 13, fontFamily: fonts.medium, textTransform: "capitalize" },
  copy: { gap: spacing.xs, paddingHorizontal: spacing.xs },
  lookName: { fontSize: 30, lineHeight: 34 },
  explain: { color: colors.inkSoft, fontSize: 15, lineHeight: 22 },
  actions: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  styling: { gap: spacing.lg },
  stylingRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm, paddingHorizontal: spacing.xs },
  stylingText: { flex: 1, color: colors.inkSoft, fontSize: 15, fontFamily: fonts.medium },
  error: { color: colors.danger, fontSize: 14, paddingHorizontal: spacing.xs },
  emptyCard: { padding: spacing.xl, alignItems: "center" },
  emptyArt: { height: 130, width: 180, alignItems: "center", justifyContent: "center", marginBottom: spacing.sm },
  emptyTile: { position: "absolute", width: 92, height: 116, borderRadius: radius.lg, backgroundColor: colors.canvas, alignItems: "center", justifyContent: "center", left: 22, borderWidth: 1, borderColor: colors.stroke },
  emptyTileFront: { left: 70, top: 18, backgroundColor: colors.accentWash, borderColor: "transparent" },
  emptyTitle: { textAlign: "center", fontSize: 28, lineHeight: 32 },
  emptyNote: { textAlign: "center", color: colors.inkSoft, fontSize: 15, lineHeight: 22, marginBottom: spacing.sm },
  checklist: { backgroundColor: colors.surface, borderRadius: radius.xl, padding: spacing.lg, gap: spacing.sm },
  checkHead: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  checkCount: { color: colors.muted, fontSize: 14, fontFamily: fonts.medium, fontVariant: ["tabular-nums"] },
  track: { height: 6, borderRadius: 3, backgroundColor: colors.canvasSoft, overflow: "hidden", marginBottom: spacing.xs },
  trackFill: { height: 6, borderRadius: 3, backgroundColor: colors.accent },
  checkRow: { minHeight: 48, flexDirection: "row", alignItems: "center", gap: spacing.md },
  checkDot: { width: 24, height: 24, borderRadius: 12, borderWidth: 1.5, borderColor: colors.strokeStrong, alignItems: "center", justifyContent: "center" },
  checkDotDone: { backgroundColor: colors.ink, borderColor: colors.ink },
  checkLabel: { flex: 1, fontSize: 15, fontFamily: fonts.medium },
  checkLabelDone: { color: colors.muted, textDecorationLine: "line-through" },
  section: { gap: spacing.md },
  continueRow: { flexDirection: "row", alignItems: "center", gap: spacing.md, backgroundColor: colors.surface, borderRadius: radius.lg, padding: spacing.sm, paddingRight: spacing.lg },
  continueThumb: { width: 64, height: 80, borderRadius: radius.md, overflow: "hidden", backgroundColor: colors.canvasSoft },
  discover: { flexDirection: "row", alignItems: "center", gap: spacing.md, backgroundColor: colors.ink, borderRadius: radius.xl, padding: spacing.xl },
  discoverEyebrow: { color: "rgba(250,248,244,0.6)" },
  discoverTitle: { color: colors.onInk, fontSize: 30, lineHeight: 34, marginTop: 2 },
  discoverNote: { color: "rgba(250,248,244,0.75)", fontSize: 15, lineHeight: 21, marginTop: spacing.xs },
  discoverArrow: { width: 48, height: 48, borderRadius: 24, backgroundColor: colors.onInk, alignItems: "center", justifyContent: "center" }
});
