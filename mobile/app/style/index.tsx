import { useMemo, useState } from "react";
import { StyleSheet, View } from "react-native";
import { router, useLocalSearchParams } from "expo-router";
import Animated, { FadeInRight, FadeOutLeft, useAnimatedStyle, useDerivedValue, withSpring } from "react-native-reanimated";
import { Briefcase, CloudSun, Dumbbell, Heart, Plane, Shuffle, Sparkles, Sun, UtensilsCrossed, Wine, X, type LucideIcon } from "@/icons";
import { useCloset, useFavoriteOutfit, useOutfitFeedback, useSaveOutfit } from "@/api/queries";
import { AppText, Caption, Display, Em, Heading, Punch, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { IconButton } from "@/components/IconButton";
import { PressableScale, PulseDot, Reveal, SETTLE, SPRING, Skeleton } from "@/components/motion";
import { ScanBeam } from "@/components/ScanBeam";
import { OutfitCollage } from "@/components/outfit-rail";
import { RatingRow } from "@/components/rating-row";
import { Screen } from "@/components/Screen";
import { Toggle } from "@/components/Toggle";
import { tryOnHref, tryOnSubset } from "@/lib/tryon";
import { OCCASIONS, useStyleOutfit, weatherLabel } from "@/lib/useStyleOutfit";
import { colors, fonts, radius, spacing } from "@/theme";

const OCCASION_ICONS: Record<string, LucideIcon> = {
  casual: Sun, work: Briefcase, date: Wine, dinner: UtensilsCrossed, travel: Plane, workout: Dumbbell
};
const STEPS = ["Plan", "Outfit", "On you"];

export default function StyleMe() {
  const params = useLocalSearchParams<{ occasion?: string }>();
  const [occasion, setOccasion] = useState<string>(params.occasion ?? "casual");
  const [weather, setWeather] = useState(true);
  const [rating, setRating] = useState(0);
  const { style, generate, locationNote } = useStyleOutfit();
  const save = useSaveOutfit();
  const favorite = useFavoriteOutfit();
  const feedback = useOutfitFeedback();
  const closet = useCloset();
  const outfit = generate.data;
  const step = outfit || generate.isPending ? 1 : 0;

  const items = useMemo(() => outfit ? (closet.data?.items ?? []).filter((item) => outfit.item_ids.includes(item.id)) : [], [outfit, closet.data]);
  const canTry = tryOnSubset(items).length > 0;
  const isSaved = Boolean(outfit?.saved || save.data?.id === outfit?.id);
  const isFavorite = Boolean(outfit?.favorited || favorite.data?.id === outfit?.id);

  function run() {
    setRating(0);
    style({ occasion, weather, askForLocation: true }).catch(() => {});
  }

  const footer = step === 0 ? (
    <Button title="Style me" icon={Sparkles} variant="accent" disabled={!closet.data?.items.length} onPress={run} />
  ) : outfit && !generate.isPending ? (
    <View style={styles.footerRow}>
      <IconButton icon={Shuffle} label="Style a different look" tone="solid" size={54} onPress={run} />
      <View style={styles.flex}>
        <Button title="See it on me" icon={Sparkles} variant="accent" disabled={!canTry}
          onPress={() => router.replace(tryOnHref(items, "&auto=1"))} />
      </View>
    </View>
  ) : null;

  return (
    <Screen footer={footer} contentStyle={styles.content}>
      <View style={styles.top}>
        <IconButton icon={X} label="Close" tone="solid" onPress={() => router.back()} />
        <Stepper step={step} />
        <View style={{ width: 44 }} />
      </View>

      {step === 0 ? (
        <Animated.View key="plan" entering={FadeInRight.duration(380).easing(SETTLE)} exiting={FadeOutLeft.duration(220)} style={styles.stepBody}>
          <Reveal>
            <Punch style={styles.kicker}>From your closet, not a catalogue</Punch>
            <Display style={styles.headline}>Where are you <Em>headed?</Em></Display>
          </Reveal>
          <View style={styles.grid}>
            {OCCASIONS.map((item, index) => {
              const Icon = OCCASION_ICONS[item.id] ?? Sun;
              const active = occasion === item.id;
              return (
                <Reveal key={item.id} index={index} delay={60} style={styles.cell}>
                  <PressableScale accessibilityRole="radio" accessibilityState={{ selected: active }} accessibilityLabel={item.label}
                    onPress={() => setOccasion(item.id)} style={[styles.occasion, active && styles.occasionActive]}>
                    <View style={styles.occasionTop}>
                      <Icon size={22} color={colors.ink} strokeWidth={active ? 2.2 : 1.8} />
                      <Punch style={styles.occasionNo}>{String(index + 1).padStart(2, "0")}</Punch>
                    </View>
                    <AppText style={[styles.occasionLabel, active && styles.occasionLabelActive]}>{item.label}</AppText>
                  </PressableScale>
                </Reveal>
              );
            })}
          </View>
          <Reveal delay={420}>
            <View style={styles.weatherRow}>
              <View style={styles.weatherIcon}><CloudSun size={20} color={colors.ink} strokeWidth={1.8} /></View>
              <View style={styles.flex}>
                <Heading>Dress for the weather</Heading>
                <Caption>Uses your location once for today's temperature.</Caption>
              </View>
              <Toggle accessibilityLabel="Dress for the weather" value={weather} onValueChange={setWeather} />
            </View>
          </Reveal>
          {!closet.data?.items.length && closet.isSuccess ? (
            <View style={styles.notice}>
              <AppText style={styles.noticeText}>Add a few pieces to your closet first.</AppText>
              <Button title="Add a piece" compact stretch={false} onPress={() => router.replace("/add-item")} />
            </View>
          ) : null}
        </Animated.View>
      ) : generate.isPending ? (
        <Animated.View key="loading" entering={FadeInRight.duration(380).easing(SETTLE)} style={styles.stepBody}>
          <View style={styles.thinking}>
            <PulseDot size={10} color={colors.ink} />
            <Title style={styles.thinkingTitle}>Reading your <Em>closet…</Em></Title>
          </View>
          <View style={styles.stageBoard}>
            <View style={styles.skeletonBoard}>
              <Skeleton tone="stage" style={{ flex: 1.25, height: 364, borderRadius: radius.lg }} />
              <View style={{ flex: 1, gap: spacing.sm }}>
                <Skeleton tone="stage" style={{ flex: 1, borderRadius: radius.lg }} />
                <Skeleton tone="stage" style={{ flex: 1, borderRadius: radius.lg }} />
              </View>
            </View>
            <ScanBeam />
            <Punch style={styles.stageNote}>Matching colour · weather · occasion</Punch>
          </View>
        </Animated.View>
      ) : outfit ? (
        <Animated.View key={outfit.id} entering={FadeInRight.duration(380).easing(SETTLE)} style={styles.stepBody}>
          <OutfitCollage items={items} animateKey={outfit.id} height={380} />
          <Reveal delay={260}>
            <View style={styles.meta}>
              <View style={styles.tags}>
                <View style={styles.tag}><AppText style={styles.tagText}>{OCCASIONS.find((o) => o.id === outfit.occasion)?.label ?? outfit.occasion}</AppText></View>
                {weatherLabel(outfit.weather_context) ? <View style={styles.tag}><CloudSun size={13} color={colors.inkSoft} /><AppText style={styles.tagText}>{weatherLabel(outfit.weather_context)}</AppText></View> : null}
                <View style={[styles.tag, styles.matchTag]}><Punch style={styles.matchText}>{Math.round(outfit.score * 100)}% match</Punch></View>
              </View>
              <View style={styles.titleRow}>
                <Title style={[styles.flex, styles.lookName]}>{outfit.name}</Title>
                <IconButton icon={Heart} label={isSaved ? "Saved" : "Save look"} tone="solid" color={isSaved ? colors.flare : colors.ink} filled={isSaved}
                  onPress={() => { if (!isSaved) save.mutate(outfit.id); else if (!isFavorite) favorite.mutate(outfit.id); }} />
              </View>
              <AppText style={styles.explain}>{outfit.explanation}</AppText>
              {isSaved ? <Caption>{isFavorite ? "Saved and marked favourite." : "Saved to Looks. Tap the heart again to favourite."}</Caption> : null}
              {!canTry ? <Caption>Try-on works with tops, bottoms and dresses — shuffle for a look that includes them.</Caption> : null}
              <View style={styles.divider} />
              <RatingRow value={rating} disabled={feedback.isPending} onChange={(value) => { setRating(value); feedback.mutate({ id: outfit.id, rating: value }); }} />
            </View>
          </Reveal>
        </Animated.View>
      ) : null}

      {locationNote ? <Caption>{locationNote}</Caption> : null}
      {[generate.error, save.error, favorite.error].filter(Boolean).map((error, i) => <AppText key={i} selectable style={styles.error}>{error!.message}</AppText>)}
    </Screen>
  );
}

function Stepper({ step }: { step: number }) {
  const progress = useDerivedValue(() => withSpring(step, SPRING), [step]);
  const fill = useAnimatedStyle(() => ({ width: `${((progress.value + 1) / STEPS.length) * 100}%` }));
  return (
    <View style={styles.stepper} accessibilityLabel={`Step ${step + 1} of ${STEPS.length}: ${STEPS[step]}`}>
      <View style={styles.stepTrack}><Animated.View style={[styles.stepFill, fill]} /></View>
      <Punch style={styles.stepLabel}>{String(step + 1).padStart(2, "0")} · {STEPS[step]}</Punch>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  content: { gap: spacing.xl },
  top: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingTop: spacing.xs },
  stepper: { flex: 1, maxWidth: 180, alignItems: "center", gap: 6 },
  stepTrack: { width: "100%", height: 6, borderRadius: 3, backgroundColor: colors.canvasSoft, overflow: "hidden" },
  stepFill: { height: 6, borderRadius: 3, backgroundColor: colors.ink, borderRightWidth: 6, borderColor: colors.accent },
  stepLabel: { fontSize: 10, lineHeight: 12, color: colors.ink },
  stepBody: { gap: spacing.xl },
  headline: { marginTop: spacing.sm, fontSize: 48, lineHeight: 48 },
  kicker: { color: colors.muted },
  grid: { flexDirection: "row", flexWrap: "wrap", marginHorizontal: -6 },
  cell: { width: "50%", padding: 6 },
  occasion: { height: 112, borderRadius: radius.lg, backgroundColor: colors.surface, padding: spacing.lg, justifyContent: "space-between", borderWidth: 1.5, borderColor: colors.stroke },
  occasionTop: { flexDirection: "row", justifyContent: "space-between", alignItems: "flex-start" },
  occasionNo: { fontSize: 10, color: colors.muted },
  occasionActive: { backgroundColor: colors.accent, borderColor: colors.ink, boxShadow: "4px 4px 0 #0D0D0F" },
  occasionLabel: { fontSize: 20, lineHeight: 24, fontFamily: fonts.serif },
  occasionLabelActive: { color: colors.ink },
  weatherRow: { flexDirection: "row", alignItems: "center", gap: spacing.md, backgroundColor: colors.surface, borderRadius: radius.lg, padding: spacing.lg },
  weatherIcon: { width: 40, height: 40, borderRadius: 20, backgroundColor: colors.canvas, alignItems: "center", justifyContent: "center" },
  notice: { gap: spacing.sm, alignItems: "flex-start" },
  noticeText: { color: colors.inkSoft },
  thinking: { flexDirection: "row", alignItems: "center", gap: spacing.md },
  thinkingTitle: { fontSize: 30, lineHeight: 34 },
  stageBoard: { backgroundColor: colors.stage, borderRadius: radius.xl, padding: spacing.sm, gap: spacing.md, overflow: "hidden" },
  stageNote: { color: colors.onStageMuted, fontSize: 10, textAlign: "center", paddingBottom: spacing.sm },
  matchTag: { backgroundColor: colors.accent, borderWidth: 1, borderColor: colors.ink },
  matchText: { fontSize: 10, lineHeight: 12 },
  skeletonBoard: { flexDirection: "row", gap: spacing.sm, height: 364 },
  meta: { gap: spacing.md },
  tags: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  tag: { flexDirection: "row", alignItems: "center", gap: 5, height: 30, paddingHorizontal: spacing.md, borderRadius: radius.pill, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke },
  tagText: { fontSize: 13, color: colors.inkSoft, fontFamily: fonts.medium, textTransform: "capitalize" },
  titleRow: { flexDirection: "row", alignItems: "center", gap: spacing.md },
  lookName: { fontSize: 36, lineHeight: 38 },
  explain: { color: colors.inkSoft, fontSize: 16, lineHeight: 24 },
  divider: { height: 1, backgroundColor: colors.stroke, marginVertical: spacing.xs },
  footerRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  error: { color: colors.danger, fontSize: 14 }
});
