import { useEffect, useMemo, useRef } from "react";
import { StyleSheet, View } from "react-native";
import { router } from "expo-router";
import Animated, { useAnimatedStyle, useDerivedValue, withTiming } from "react-native-reanimated";
import { ArrowRight, Check, CloudSun, Heart, ImagePlus, Shirt, Shuffle, Sparkles, UserRound } from "@/icons";
import { useCloset, useOutfits, useProfile, useSaveOutfit, useTryOns } from "@/api/queries";
import { mediaUrl } from "@/api/client";
import { AppText, Caption, Display, Em, Heading, Punch, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { IconButton } from "@/components/IconButton";
import { Photo } from "@/components/Photo";
import { PressableScale, PulseDot, Reveal, SETTLE, Skeleton } from "@/components/motion";
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
            <Punch style={styles.date}>{dateLine}</Punch>
            <Display style={styles.hello}>{greeting()}{firstName ? <>,{"\n"}<Em>{firstName}.</Em></> : "."}</Display>
          </View>
          <IconButton icon={UserRound} label="Profile and settings" tone="solid" onPress={() => router.push("/profile")} />
        </View>
      </Reveal>

      <Reveal delay={80}>
        {closet.isLoading || outfits.isLoading ? (
          <View style={styles.card}><Skeleton tone="stage" style={{ height: 330, borderRadius: radius.lg }} /><Skeleton tone="stage" style={{ height: 26, width: "60%" }} /></View>
        ) : items.length < 2 ? (
          <EmptyCloset count={items.length} />
        ) : (
          <View style={styles.card}>
            <View style={styles.cardTop}>
              <View style={styles.badge}><PulseDot size={7} /><Punch style={styles.badgeText}>Today's look</Punch></View>
              {weather ? <View style={styles.weather}><CloudSun size={14} color={colors.onStage} /><AppText style={styles.weatherText}>{weather}</AppText></View> : null}
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
                  <IconButton icon={Shuffle} label="Style a different look" tone="stage" size={56}
                    onPress={() => style({ occasion: todays.occasion || "casual", weather: true, askForLocation: false }).catch(() => {})} />
                  <IconButton icon={Heart} label={isSaved ? "Saved to Looks" : "Save to Looks"} tone="stage" size={56}
                    color={isSaved ? colors.flare : colors.onStage} filled={isSaved}
                    onPress={() => !isSaved && save.mutate(todays.id)} />
                </View>
                {!canTry ? <Caption style={styles.onStageMuted}>Try-on works with tops, bottoms and dresses — this look has none.</Caption> : null}
              </>
            ) : (
              <View style={styles.styling}>
                <Skeleton tone="stage" style={{ height: 330, borderRadius: radius.lg }} />
                <View style={styles.stylingRow}>
                  <PulseDot />
                  <AppText style={styles.stylingText}>{generate.isPending ? "Styling today's look from your closet…" : "Your look for today isn't styled yet."}</AppText>
                </View>
                {!generate.isPending ? <Button title="Style today's look" icon={Sparkles} variant="accent" onPress={() => style({ occasion: "casual", weather: true, askForLocation: true }).catch(() => {})} /> : null}
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
            <Punch style={styles.discoverEyebrow}>This week's challenge</Punch>
            <Title style={styles.discoverTitle}>Monochrome <Em>week</Em></Title>
            <AppText style={styles.discoverNote}>Style one colour head to toe — from what you already own.</AppText>
          </View>
          <View style={styles.discoverArrow}><ArrowRight size={20} color={colors.onInk} /></View>
        </PressableScale>
      </Reveal>
    </Screen>
  );
}

function EmptyCloset({ count }: { count: number }) {
  return (
    <View style={[styles.card, styles.emptyCard]}>
      <View style={styles.emptyArt}>
        <View style={[styles.emptyTile, { transform: [{ rotate: "-8deg" }] }]}><Shirt size={30} color={colors.onStage} strokeWidth={1.4} /></View>
        <View style={[styles.emptyTile, styles.emptyTileFront, { transform: [{ rotate: "6deg" }] }]}><ImagePlus size={30} color={colors.ink} strokeWidth={1.6} /></View>
      </View>
      <Title style={styles.emptyTitle}>{count ? "One more piece and we can style you" : "Start with three pieces"}</Title>
      <AppText style={styles.emptyNote}>Photograph clothes you already own. Flairwise styles outfits from them and shows them on you.</AppText>
      <Button title={count ? "Add another piece" : "Add your first piece"} icon={ImagePlus} variant="accent" onPress={() => router.push("/add-item")} />
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
          <View style={[styles.checkDot, step.done && styles.checkDotDone]}>{step.done ? <Check size={14} color={colors.ink} strokeWidth={3} /> : null}</View>
          <AppText style={[styles.checkLabel, step.done && styles.checkLabelDone]}>{step.label}</AppText>
          {!step.done ? <ArrowRight size={16} color={colors.muted} /> : null}
        </PressableScale>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  onStageMuted: { color: colors.onStageMuted },
  header: { flexDirection: "row", alignItems: "flex-start", justifyContent: "space-between", gap: spacing.md, paddingTop: spacing.md },
  headerCopy: { flex: 1, gap: spacing.sm },
  date: { color: colors.muted },
  hello: { fontSize: 46, lineHeight: 46 },
  card: { backgroundColor: colors.stage, borderRadius: radius.xl, padding: spacing.md, gap: spacing.lg, boxShadow: "0 24px 48px rgba(13,13,15,0.28)" },
  cardTop: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: spacing.xs, paddingTop: spacing.xs },
  badge: { flexDirection: "row", alignItems: "center", gap: 8, paddingHorizontal: spacing.md, height: 30, borderRadius: radius.pill, borderWidth: 1, borderColor: colors.stageLine },
  badgeText: { color: colors.onStage, fontSize: 10, lineHeight: 12 },
  weather: { flexDirection: "row", alignItems: "center", gap: 6, height: 30, paddingHorizontal: spacing.md, borderRadius: radius.pill, backgroundColor: colors.stageRaised },
  weatherText: { color: colors.onStage, fontSize: 13, fontFamily: fonts.medium, textTransform: "capitalize" },
  copy: { gap: spacing.sm, paddingHorizontal: spacing.xs },
  lookName: { fontSize: 34, lineHeight: 36, color: colors.onStage },
  explain: { color: colors.onStageMuted, fontSize: 15, lineHeight: 22 },
  actions: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  styling: { gap: spacing.lg },
  stylingRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm, paddingHorizontal: spacing.xs },
  stylingText: { flex: 1, color: colors.onStage, fontSize: 15, fontFamily: fonts.medium },
  error: { color: "#FF8A73", fontSize: 14, paddingHorizontal: spacing.xs },
  emptyCard: { padding: spacing.xl, alignItems: "center" },
  emptyArt: { height: 130, width: 180, alignItems: "center", justifyContent: "center", marginBottom: spacing.sm },
  emptyTile: { position: "absolute", width: 92, height: 116, borderRadius: radius.lg, backgroundColor: colors.stageRaised, alignItems: "center", justifyContent: "center", left: 22, borderWidth: 1, borderColor: colors.stageLine },
  emptyTileFront: { left: 70, top: 18, backgroundColor: colors.accent, borderColor: "transparent" },
  emptyTitle: { textAlign: "center", fontSize: 30, lineHeight: 34, color: colors.onStage },
  emptyNote: { textAlign: "center", color: colors.onStageMuted, fontSize: 15, lineHeight: 22, marginBottom: spacing.sm },
  checklist: { backgroundColor: colors.surface, borderRadius: radius.xl, padding: spacing.lg, gap: spacing.sm, borderWidth: 1, borderColor: colors.stroke },
  checkHead: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  checkCount: { color: colors.ink, fontSize: 14, fontFamily: fonts.semibold, fontVariant: ["tabular-nums"] },
  track: { height: 8, borderRadius: 4, backgroundColor: colors.canvasSoft, overflow: "hidden", marginBottom: spacing.xs },
  trackFill: { height: 8, borderRadius: 4, backgroundColor: colors.ink, borderRightWidth: 8, borderColor: colors.accent },
  checkRow: { minHeight: 48, flexDirection: "row", alignItems: "center", gap: spacing.md },
  checkDot: { width: 26, height: 26, borderRadius: 13, borderWidth: 1.5, borderColor: colors.strokeStrong, alignItems: "center", justifyContent: "center" },
  checkDotDone: { backgroundColor: colors.accent, borderColor: colors.ink },
  checkLabel: { flex: 1, fontSize: 15, fontFamily: fonts.medium },
  checkLabelDone: { color: colors.muted, textDecorationLine: "line-through" },
  section: { gap: spacing.md },
  continueRow: { flexDirection: "row", alignItems: "center", gap: spacing.md, backgroundColor: colors.surface, borderRadius: radius.lg, padding: spacing.sm, paddingRight: spacing.lg, borderWidth: 1, borderColor: colors.stroke },
  continueThumb: { width: 64, height: 80, borderRadius: radius.md, overflow: "hidden", backgroundColor: colors.canvasSoft },
  discover: { flexDirection: "row", alignItems: "center", gap: spacing.md, backgroundColor: colors.flare, borderRadius: radius.xl, padding: spacing.xl, overflow: "hidden" },
  discoverEyebrow: { color: colors.ink, fontSize: 10, opacity: 0.75 },
  discoverTitle: { color: colors.ink, fontSize: 34, lineHeight: 36, marginTop: 4 },
  discoverNote: { color: colors.ink, fontSize: 15, lineHeight: 21, marginTop: spacing.xs, opacity: 0.85 },
  discoverArrow: { width: 48, height: 48, borderRadius: 24, backgroundColor: colors.ink, alignItems: "center", justifyContent: "center" }
});
