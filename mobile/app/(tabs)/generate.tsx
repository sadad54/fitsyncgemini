import { useEffect, useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, View } from "react-native";
import { router } from "expo-router";
import * as Location from "expo-location";
import * as Haptics from "expo-haptics";
import Svg, { Circle, Text as SvgText } from "react-native-svg";
import Animated, { Easing, useAnimatedProps, useAnimatedStyle, useSharedValue, withDelay, withRepeat, withTiming } from "react-native-reanimated";
import { useCloset, useFavoriteOutfit, useGenerateOutfit, useOutfitFeedback, useSaveOutfit } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Glyph } from "@/components/Glyph";
import { ThermometerIcon } from "@/components/Icon";
import { Reveal } from "@/components/motion";
import { OutfitRail } from "@/components/outfit-rail";
import { RatingRow } from "@/components/rating-row";
import { Screen } from "@/components/Screen";
import { Toggle } from "@/components/Toggle";
import { colors, fonts, spacing } from "@/theme";

const AnimatedCircle = Animated.createAnimatedComponent(Circle);

// expo-location's web implementation can hang indefinitely instead of
// resolving or rejecting (observed with both permission requests and
// position reads). Weather-aware styling is a nice-to-have, not a blocker —
// never let it freeze the primary "generate" action.
function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("timeout")), ms);
    promise.then(
      (value) => { clearTimeout(timer); resolve(value); },
      (error) => { clearTimeout(timer); reject(error); }
    );
  });
}

const occasions = [
  { id: "casual", label: "Everyday", shape: "square" },
  { id: "work", label: "Work", shape: "square" },
  { id: "date", label: "Date", shape: "circle" },
  { id: "workout", label: "Move", shape: "square" },
  { id: "travel", label: "Travel", shape: "diamond" },
  { id: "dinner", label: "Dinner", shape: "moonDown" }
] as const;

export default function Generate() {
  const [occasion, setOccasion] = useState("casual");
  const [weatherAware, setWeatherAware] = useState(true);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [rating, setRating] = useState(0);
  const generate = useGenerateOutfit();
  const save = useSaveOutfit();
  const favorite = useFavoriteOutfit();
  const feedback = useOutfitFeedback();
  const closet = useCloset();
  const outfit = generate.data;
  const outfitItems = useMemo(() => outfit ? (closet.data?.items ?? []).filter((item) => outfit.item_ids.includes(item.id)) : [], [outfit, closet.data]);
  const isSaved = Boolean(outfit?.saved || (save.data && save.data.id === outfit?.id));
  const isFavorite = Boolean(outfit?.favorited || (favorite.data && favorite.data.id === outfit?.id));

  async function styleLook() {
    setLocationError(null);
    setRating(0);
    let locationInput: { use_weather?: boolean; latitude?: number; longitude?: number } = { use_weather: false };
    if (weatherAware) {
      try {
        const permission = await withTimeout(Location.requestForegroundPermissionsAsync(), 6000);
        if (!permission.granted) {
          setLocationError("Location permission is off. Enable it for weather-aware styling, or switch weather off below.");
          return;
        }
        const location = await withTimeout(Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced }), 6000);
        locationInput = { use_weather: true, latitude: location.coords.latitude, longitude: location.coords.longitude };
      } catch {
        setLocationError("Couldn't get your location in time, so this look skips weather. Try again, or switch weather off below.");
      }
    }
    await generate.mutateAsync({ occasion, ...locationInput });
    if (process.env.EXPO_OS === "ios") Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  }

  function submitRating(value: number) {
    if (!outfit || feedback.isPending) return;
    setRating(value);
    feedback.mutate({ id: outfit.id, rating: value });
  }

  return (
    <Screen>
      <Reveal>
        <View style={styles.header}>
          <Eyebrow>AI styling studio</Eyebrow>
          <Title style={styles.headline}>Set the scene. We pull the look.</Title>
          <AppText style={styles.subtitle}>FitSync only recommends pieces already in your closet, so every result is wearable now.</AppText>
        </View>
      </Reveal>

      <Reveal delay={60}>
        <View style={styles.section}>
          <AppText style={styles.sectionLabel}>Where are you headed?</AppText>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.occasionRail}>
            {occasions.map((item) => {
              const active = occasion === item.id;
              return (
                <Pressable key={item.id} accessibilityRole="button" accessibilityState={{ selected: active }} onPress={() => setOccasion(item.id)} style={[styles.occasion, active && styles.occasionActive]}>
                  <Glyph shape={item.shape} size={20} strokeWidth={2} color={active ? colors.white : colors.ink} />
                  <AppText style={[styles.occasionText, active && styles.occasionTextActive]}>{item.label}</AppText>
                </Pressable>
              );
            })}
          </ScrollView>
        </View>
      </Reveal>

      <Reveal delay={110}>
        <View style={styles.weatherCard}>
          <View style={styles.weatherCopy}>
            <AppText style={styles.weatherTitle}>Dress for current weather</AppText>
            <AppText style={styles.weatherNote}>Uses your location once to account for temperature.</AppText>
          </View>
          <Toggle accessibilityLabel="Weather-aware styling" value={weatherAware} onValueChange={setWeatherAware} />
        </View>
      </Reveal>
      {locationError ? <AppText selectable style={styles.warning}>{locationError}</AppText> : null}

      <Button title={generate.isPending ? "Reading your closet…" : outfit ? "Create another look" : "Create this look"} icon="sparkles" disabled={generate.isPending} onPress={styleLook} />

      {generate.isPending ? <LoadingCard /> : null}

      {outfit && !generate.isPending ? (
        <Reveal>
          <View style={styles.result}>
            <View style={styles.resultTop}>
              <ScoreRing score={Math.round(outfit.score * 100)} />
              <View style={styles.resultCopy}>
                <Eyebrow>{outfit.occasion} edit</Eyebrow>
                <AppText style={styles.resultName}>{outfit.name}</AppText>
              </View>
            </View>
            <OutfitRail items={outfitItems} />
            <AppText style={styles.explanation}>{outfit.explanation}</AppText>
            {outfit.weather_context && typeof outfit.weather_context.temperature === "number" ? (
              <View style={styles.weatherResult}>
                <ThermometerIcon size={13} color={colors.white} />
                <AppText style={styles.weatherResultText}>Built for {Math.round(outfit.weather_context.temperature)}°C right now</AppText>
              </View>
            ) : null}
            {outfit.item_ids.length ? (
              <>
                <View style={styles.actions}>
                  <Pressable disabled={isSaved || save.isPending} onPress={() => save.mutate(outfit.id)} style={[styles.saveBtn, isSaved && styles.saveBtnDone]}>
                    <AppText style={[styles.saveLabel, isSaved && styles.saveLabelDone]}>{isSaved ? "Saved to looks ✓" : save.isPending ? "Saving…" : "Save look"}</AppText>
                  </Pressable>
                  <Pressable disabled={isFavorite || favorite.isPending} onPress={() => favorite.mutate(outfit.id)} style={[styles.favBtn, isFavorite && styles.favBtnDone]}>
                    <AppText style={[styles.favLabel, isFavorite && styles.favLabelDone]}>{isFavorite ? "Favorite ♥" : "Favorite"}</AppText>
                  </Pressable>
                </View>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel="Try this look on"
                  onPress={() => router.push(`/tryon?from=look&items=${outfit.item_ids.join(",")}`)}
                  style={styles.tryOnRow}
                >
                  <AppText style={styles.tryOnLabel}>Try this look on</AppText>
                  <AppText style={styles.tryOnGlyph}>→</AppText>
                </Pressable>
                <RatingRow value={rating} onChange={submitRating} disabled={feedback.isPending} />
              </>
            ) : (
              <Button title="Add pieces first" onPress={() => router.push("/add-item")} />
            )}
          </View>
        </Reveal>
      ) : !generate.isPending ? (
        <View style={styles.emptyResult}>
          <View style={styles.emptyMarks}>
            <View style={styles.emptyBar} />
            <View style={styles.emptyBar} />
            <View style={[styles.emptyBar, styles.emptyBarAccent]} />
          </View>
          <AppText style={styles.emptyTitle}>Your next look starts here.</AppText>
          <AppText style={styles.emptyNote}>Choose the plan above, then let the wardrobe—not a shopping feed—do the work.</AppText>
        </View>
      ) : null}

      {generate.error ? <AppText selectable style={styles.error}>{generate.error.message}</AppText> : null}
      {save.error ? <AppText selectable style={styles.error}>{save.error.message}</AppText> : null}
      {favorite.error ? <AppText selectable style={styles.error}>{favorite.error.message}</AppText> : null}
      {feedback.error ? <AppText selectable style={styles.error}>{feedback.error.message}</AppText> : null}
    </Screen>
  );
}

const PHASES = ["Reading your pieces…", "Matching palette to your anchors…", "Weighting for the weather…", "Balancing occasion and fit…"];

function LoadingCard() {
  const [phase, setPhase] = useState(0);
  const [caretOn, setCaretOn] = useState(true);
  useEffect(() => {
    const id = setInterval(() => setPhase((p) => (p + 1) % PHASES.length), 700);
    const caret = setInterval(() => setCaretOn((v) => !v), 500);
    return () => { clearInterval(id); clearInterval(caret); };
  }, []);
  return (
    <View style={styles.loadingCard}>
      <Wipe />
      <View style={styles.loadingRail}>
        <SwayBlock delay={0} height={64} />
        <SwayBlock delay={180} height={84} accent />
        <SwayBlock delay={360} height={56} />
        <SwayBlock delay={540} height={74} />
      </View>
      <Eyebrow>Building the edit</Eyebrow>
      <AppText style={styles.loadingTitle}>{PHASES[phase]}<AppText style={{ opacity: caretOn ? 1 : 0 }}>_</AppText></AppText>
    </View>
  );
}

function SwayBlock({ delay, height, accent }: { delay: number; height: number; accent?: boolean }) {
  const t = useSharedValue(0);
  useEffect(() => {
    t.value = withDelay(delay, withRepeat(withTiming(1, { duration: 1500, easing: Easing.inOut(Easing.ease) }), -1, true));
  }, []);
  const style = useAnimatedStyle(() => ({
    transform: [
      { translateY: -14 * t.value },
      { rotate: `${-2 + 4 * t.value}deg` }
    ]
  }));
  return <Animated.View style={[styles.loadingBlock, { height }, accent && styles.loadingBlockAccent, style]} />;
}

function Wipe() {
  const x = useSharedValue(-1);
  useEffect(() => {
    x.value = withRepeat(withTiming(2, { duration: 1400, easing: Easing.linear }), -1, false);
  }, []);
  const style = useAnimatedStyle(() => ({ transform: [{ translateX: x.value * 260 }] }));
  return (
    <View style={styles.wipeMask} pointerEvents="none">
      <Animated.View style={[styles.wipeBar, style]} />
    </View>
  );
}

function ScoreRing({ score }: { score: number }) {
  const progress = useSharedValue(0);
  useEffect(() => {
    progress.value = withTiming(score, { duration: 1100, easing: Easing.out(Easing.cubic) });
  }, [score]);
  const circumference = 2 * Math.PI * 44;
  const animatedProps = useAnimatedProps(() => ({
    strokeDashoffset: circumference - (circumference * progress.value) / 100
  }));

  return (
    <View style={styles.scoreRing}>
      <Svg width={96} height={96} viewBox="0 0 100 100">
        <Circle cx={50} cy={50} r={44} stroke={colors.stroke} strokeWidth={6} fill="none" />
        <AnimatedCircle
          cx={50}
          cy={50}
          r={44}
          stroke={colors.rose}
          strokeWidth={6}
          fill="none"
          strokeDasharray={`${circumference} ${circumference}`}
          animatedProps={animatedProps}
          strokeLinecap="butt"
          transform="rotate(-90 50 50)"
        />
        <SvgText x={50} y={54} textAnchor="middle" fill={colors.ink} fontSize={24} fontFamily={fonts.black}>{score}</SvgText>
        <SvgText x={50} y={70} textAnchor="middle" fill={colors.muted} fontSize={7} fontFamily={fonts.bold} letterSpacing={2}>MATCH</SvgText>
      </Svg>
    </View>
  );
}

const styles = StyleSheet.create({
  header: { gap: spacing.md },
  headline: { fontSize: 38, lineHeight: 36 },
  subtitle: { color: colors.muted, fontSize: 13, lineHeight: 20 },
  section: { gap: spacing.md },
  sectionLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6, textTransform: "uppercase" },
  occasionRail: { gap: spacing.xs, paddingRight: spacing.xl },
  occasion: { width: 88, minHeight: 88, borderWidth: 1, borderColor: colors.stroke, alignItems: "flex-start", justifyContent: "flex-end", gap: spacing.sm, padding: spacing.md },
  occasionActive: { backgroundColor: colors.rose, borderColor: colors.rose },
  occasionText: { color: colors.ink, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  occasionTextActive: { color: colors.white },
  weatherCard: { minHeight: 64, flexDirection: "row", alignItems: "center", gap: spacing.md, borderTopWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke, paddingVertical: spacing.md },
  weatherCopy: { flex: 1, gap: spacing.xxs },
  weatherTitle: { fontFamily: fonts.black, fontWeight: "800", fontSize: 14 },
  weatherNote: { color: colors.muted, fontSize: 11, lineHeight: 16, marginTop: 2 },
  warning: { color: colors.roseSoft, fontSize: 13, lineHeight: 19 },
  loadingCard: { borderWidth: 2, borderColor: colors.strokeStrong, padding: spacing.xl, gap: spacing.md, overflow: "hidden" },
  wipeMask: { ...StyleSheet.absoluteFillObject, overflow: "hidden" },
  wipeBar: { position: "absolute", top: 0, bottom: 0, width: 130, backgroundColor: "rgba(236, 48, 19, 0.14)" },
  loadingRail: { flexDirection: "row", gap: spacing.sm, alignItems: "flex-end", height: 90 },
  loadingBlock: { width: 40, backgroundColor: colors.surfaceElevated, borderWidth: 1, borderColor: colors.stroke },
  loadingBlockAccent: { backgroundColor: colors.rose, borderColor: colors.rose },
  loadingTitle: { fontFamily: fonts.black, fontWeight: "800", fontSize: 18, letterSpacing: -0.3 },
  result: { borderTopWidth: 2, borderColor: colors.strokeStrong, paddingTop: spacing.lg, gap: spacing.lg },
  resultTop: { flexDirection: "row", alignItems: "center", gap: spacing.lg },
  scoreRing: { width: 96, height: 96 },
  resultCopy: { flex: 1, gap: spacing.xs },
  resultName: { fontSize: 25, lineHeight: 25, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.6, textTransform: "uppercase" },
  explanation: { color: colors.ink, fontSize: 14, lineHeight: 22 },
  weatherResult: { flexDirection: "row", alignItems: "center", gap: spacing.xs, alignSelf: "stretch", backgroundColor: colors.rose, paddingHorizontal: spacing.md, paddingVertical: spacing.sm },
  weatherResultText: { color: colors.white, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  actions: { flexDirection: "row", gap: spacing.xs },
  saveBtn: { flex: 1, height: 54, backgroundColor: colors.rose, alignItems: "flex-start", justifyContent: "center", paddingHorizontal: spacing.md },
  saveBtnDone: { backgroundColor: colors.surface },
  saveLabel: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: 1, textTransform: "uppercase" },
  saveLabelDone: { color: colors.muted },
  favBtn: { width: 112, height: 54, borderWidth: 2, borderColor: colors.strokeStrong, alignItems: "flex-start", justifyContent: "center", paddingHorizontal: spacing.md },
  favBtnDone: { backgroundColor: colors.rose, borderColor: colors.rose },
  favLabel: { color: colors.ink, fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: 1, textTransform: "uppercase" },
  favLabelDone: { color: colors.white },
  tryOnRow: { height: 56, borderTopWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke, flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: spacing.lg },
  tryOnLabel: { color: colors.ink, fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: 1, textTransform: "uppercase" },
  tryOnGlyph: { color: colors.roseSoft, fontSize: 16 },
  emptyResult: { borderWidth: 2, borderStyle: "dashed", borderColor: colors.strokeStrong, padding: spacing.xxl, gap: spacing.sm },
  emptyMarks: { flexDirection: "row", gap: spacing.xs },
  emptyBar: { width: 34, height: 46, backgroundColor: colors.surfaceElevated },
  emptyBarAccent: { backgroundColor: colors.rose },
  emptyTitle: { fontSize: 20, lineHeight: 24, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.4, marginTop: spacing.sm },
  emptyNote: { color: colors.muted, fontSize: 13, lineHeight: 20 },
  error: { color: colors.roseSoft }
});
