import { useMemo, useState } from "react";
import { StyleSheet, View } from "react-native";
import { router, useLocalSearchParams } from "expo-router";
import Animated, { FadeInRight, FadeOutLeft, useAnimatedStyle, useDerivedValue, withSpring } from "react-native-reanimated";
import { Briefcase, CloudSun, Dumbbell, Heart, Plane, Shuffle, Sparkles, Sun, UtensilsCrossed, Wine, X, type LucideIcon } from "lucide-react-native";
import { useCloset, useFavoriteOutfit, useOutfitFeedback, useSaveOutfit } from "@/api/queries";
import { AppText, Caption, Display, Eyebrow, Heading, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { IconButton } from "@/components/IconButton";
import { Breathe, PressableScale, Reveal, SETTLE, SPRING, Skeleton } from "@/components/motion";
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
            <Eyebrow>From your closet, not a catalogue</Eyebrow>
            <Display style={styles.headline}>Where are you headed?</Display>
          </Reveal>
          <View style={styles.grid}>
            {OCCASIONS.map((item, index) => {
              const Icon = OCCASION_ICONS[item.id] ?? Sun;
              const active = occasion === item.id;
              return (
                <Reveal key={item.id} index={index} delay={60} style={styles.cell}>
                  <PressableScale accessibilityRole="radio" accessibilityState={{ selected: active }} accessibilityLabel={item.label}
                    onPress={() => setOccasion(item.id)} style={[styles.occasion, active && styles.occasionActive]}>
                    <Icon size={22} color={active ? colors.onInk : colors.ink} strokeWidth={1.8} />
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
            <Breathe><Sparkles size={22} color={colors.accent} strokeWidth={2} /></Breathe>
            <Title style={styles.thinkingTitle}>Reading your closet…</Title>
          </View>
          <View style={styles.skeletonBoard}>
            <Skeleton style={{ flex: 1.25, height: 380, borderRadius: radius.lg }} />
            <View style={{ flex: 1, gap: spacing.sm }}>
              <Skeleton style={{ flex: 1, borderRadius: radius.lg }} />
              <Skeleton style={{ flex: 1, borderRadius: radius.lg }} />
            </View>
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
                <View style={styles.tag}><AppText style={styles.tagText}>{Math.round(outfit.score * 100)}% match</AppText></View>
              </View>
              <View style={styles.titleRow}>
                <Title style={[styles.flex, styles.lookName]}>{outfit.name}</Title>
                <IconButton icon={Heart} label={isSaved ? "Saved" : "Save look"} tone="solid" color={isSaved ? colors.danger : colors.ink} filled={isSaved}
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
      <AppText style={styles.stepLabel}>{STEPS[step]}</AppText>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  content: { gap: spacing.xl },
  top: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingTop: spacing.xs },
  stepper: { flex: 1, maxWidth: 180, alignItems: "center", gap: 6 },
  stepTrack: { width: "100%", height: 4, borderRadius: 2, backgroundColor: colors.canvasSoft, overflow: "hidden" },
  stepFill: { height: 4, borderRadius: 2, backgroundColor: colors.accent },
  stepLabel: { fontSize: 12, color: colors.muted, fontFamily: fonts.medium },
  stepBody: { gap: spacing.xl },
  headline: { marginTop: spacing.xs },
  grid: { flexDirection: "row", flexWrap: "wrap", marginHorizontal: -6 },
  cell: { width: "50%", padding: 6 },
  occasion: { height: 104, borderRadius: radius.lg, backgroundColor: colors.surface, padding: spacing.lg, justifyContent: "space-between", borderWidth: 1, borderColor: colors.stroke },
  occasionActive: { backgroundColor: colors.ink, borderColor: colors.ink },
  occasionLabel: { fontSize: 16, fontFamily: fonts.semibold, fontWeight: "600" },
  occasionLabelActive: { color: colors.onInk },
  weatherRow: { flexDirection: "row", alignItems: "center", gap: spacing.md, backgroundColor: colors.surface, borderRadius: radius.lg, padding: spacing.lg },
  weatherIcon: { width: 40, height: 40, borderRadius: 20, backgroundColor: colors.canvas, alignItems: "center", justifyContent: "center" },
  notice: { gap: spacing.sm, alignItems: "flex-start" },
  noticeText: { color: colors.inkSoft },
  thinking: { flexDirection: "row", alignItems: "center", gap: spacing.md },
  thinkingTitle: { fontSize: 26 },
  skeletonBoard: { flexDirection: "row", gap: spacing.sm, height: 380 },
  meta: { gap: spacing.md },
  tags: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  tag: { flexDirection: "row", alignItems: "center", gap: 5, height: 28, paddingHorizontal: spacing.md, borderRadius: radius.pill, backgroundColor: colors.surface },
  tagText: { fontSize: 13, color: colors.inkSoft, fontFamily: fonts.medium, textTransform: "capitalize" },
  titleRow: { flexDirection: "row", alignItems: "center", gap: spacing.md },
  lookName: { fontSize: 32, lineHeight: 36 },
  explain: { color: colors.inkSoft, fontSize: 16, lineHeight: 24 },
  divider: { height: 1, backgroundColor: colors.stroke, marginVertical: spacing.xs },
  footerRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  error: { color: colors.danger, fontSize: 14 }
});
