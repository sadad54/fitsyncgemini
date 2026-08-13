import { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Switch, View } from "react-native";
import { router } from "expo-router";
import { LinearGradient } from "expo-linear-gradient";
import * as Location from "expo-location";
import * as Haptics from "expo-haptics";
import { Ionicons } from "@expo/vector-icons";
import { useCloset, useFavoriteOutfit, useGenerateOutfit, useOutfitFeedback, useSaveOutfit } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { Reveal } from "@/components/motion";
import { OutfitRail } from "@/components/outfit-rail";
import { RatingRow } from "@/components/rating-row";
import { Screen } from "@/components/Screen";
import { colors, gradients, radius, shadows, spacing } from "@/theme";

const occasions = [
  { id: "casual", label: "Everyday", icon: "cafe-outline" },
  { id: "work", label: "Work", icon: "briefcase-outline" },
  { id: "date", label: "Date", icon: "heart-outline" },
  { id: "workout", label: "Move", icon: "barbell-outline" },
  { id: "travel", label: "Travel", icon: "airplane-outline" },
  { id: "dinner", label: "Dinner", icon: "wine-outline" }
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
      const permission = await Location.requestForegroundPermissionsAsync();
      if (!permission.granted) {
        setLocationError("Location permission is off. Enable it for weather-aware styling, or switch weather off below.");
        return;
      }
      const location = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced });
      locationInput = { use_weather: true, latitude: location.coords.latitude, longitude: location.coords.longitude };
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
          <Title>Set the scene. We’ll pull the look.</Title>
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
                <Pressable key={item.id} accessibilityRole="button" accessibilityState={{ selected: active }} onPress={() => setOccasion(item.id)} style={({ pressed }) => [styles.occasion, active && styles.occasionActive, pressed && styles.pressed]}>
                  <Ionicons name={item.icon} size={21} color={active ? colors.roseSoft : colors.muted} />
                  <AppText style={[styles.occasionText, active && styles.occasionTextActive]}>{item.label}</AppText>
                </Pressable>
              );
            })}
          </ScrollView>
        </View>
      </Reveal>

      <Reveal delay={110}>
        <View style={styles.weatherCard}>
          <View style={styles.weatherIcon}><Ionicons name="partly-sunny-outline" size={22} color={colors.gold} /></View>
          <View style={styles.weatherCopy}>
            <AppText style={styles.weatherTitle}>Dress for current weather</AppText>
            <AppText style={styles.weatherNote}>Uses your location once to account for temperature.</AppText>
          </View>
          <Switch accessibilityLabel="Weather-aware styling" value={weatherAware} onValueChange={setWeatherAware} trackColor={{ false: colors.surfaceMuted, true: colors.rose }} thumbColor={colors.white} />
        </View>
      </Reveal>
      {locationError ? <AppText selectable style={styles.warning}>{locationError}</AppText> : null}

      <Button title={generate.isPending ? "Reading your closet…" : "Create this look"} icon="sparkles" disabled={generate.isPending} onPress={styleLook} />

      {generate.isPending ? (
        <View style={styles.loadingCard}>
          <View style={styles.loadingRail}><View style={[styles.loadingBlock, { transform: [{ rotate: "-5deg" }] }]} /><View style={[styles.loadingBlock, { marginLeft: -18, transform: [{ rotate: "4deg" }] }]} /><View style={[styles.loadingBlock, { marginLeft: -18, transform: [{ rotate: "-2deg" }] }]} /></View>
          <Eyebrow>Building the edit</Eyebrow>
          <AppText style={styles.loadingTitle}>Balancing palette, occasion, and weather…</AppText>
        </View>
      ) : null}

      {outfit && !generate.isPending ? (
        <Reveal>
          <LinearGradient colors={gradients.surface} style={styles.result}>
            <View style={styles.resultTop}>
              <View style={styles.scoreRing}>
                <AppText selectable style={styles.scoreValue}>{Math.round(outfit.score * 100)}</AppText>
                <AppText style={styles.scoreUnit}>match</AppText>
              </View>
              <View style={styles.resultCopy}>
                <Eyebrow>{outfit.occasion} edit</Eyebrow>
                <AppText style={styles.resultName}>{outfit.name}</AppText>
              </View>
            </View>
            <OutfitRail items={outfitItems} />
            <AppText style={styles.explanation}>{outfit.explanation}</AppText>
            {outfit.weather_context && typeof outfit.weather_context.temperature === "number" ? (
              <View style={styles.weatherResult}><Ionicons name="thermometer-outline" size={17} color={colors.gold} /><AppText style={styles.weatherResultText}>Built for {Math.round(outfit.weather_context.temperature)}°C right now</AppText></View>
            ) : null}
            {outfit.item_ids.length ? (
              <View style={styles.actions}>
                <Button title={isSaved ? "Saved to looks" : save.isPending ? "Saving…" : "Save look"} icon={isSaved ? "checkmark-circle" : "bookmark-outline"} disabled={isSaved || save.isPending} onPress={() => save.mutate(outfit.id)} />
                <Button title={isFavorite ? "Favorite" : favorite.isPending ? "Favoriting…" : "Mark favorite"} icon={isFavorite ? "heart" : "heart-outline"} variant="secondary" disabled={isFavorite || favorite.isPending} onPress={() => favorite.mutate(outfit.id)} />
              </View>
            ) : (
              <Button title="Add pieces first" icon="camera-outline" onPress={() => router.push("/add-item")} />
            )}
            <RatingRow value={rating} onChange={submitRating} disabled={!outfit.item_ids.length || feedback.isPending} />
          </LinearGradient>
        </Reveal>
      ) : !generate.isPending ? (
        <View style={styles.emptyResult}>
          <Ionicons name="sparkles-outline" size={28} color={colors.plum} />
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

const styles = StyleSheet.create({
  header: { gap: spacing.md },
  subtitle: { color: colors.muted, fontSize: 16, lineHeight: 24 },
  section: { gap: spacing.md },
  sectionLabel: { color: colors.inkSoft, fontWeight: "800" },
  occasionRail: { gap: spacing.sm, paddingRight: spacing.xl },
  occasion: { width: 88, minHeight: 82, borderRadius: radius.lg, borderCurve: "continuous", backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke, alignItems: "center", justifyContent: "center", gap: spacing.sm },
  occasionActive: { backgroundColor: colors.roseWash, borderColor: colors.rose },
  occasionText: { color: colors.muted, fontSize: 13, lineHeight: 17, fontWeight: "700" },
  occasionTextActive: { color: colors.roseSoft },
  pressed: { opacity: 0.68 },
  weatherCard: { minHeight: 80, flexDirection: "row", alignItems: "center", gap: spacing.md, backgroundColor: colors.surface, borderRadius: radius.lg, borderCurve: "continuous", borderWidth: 1, borderColor: colors.stroke, padding: spacing.md },
  weatherIcon: { width: 46, height: 46, borderRadius: radius.md, backgroundColor: colors.goldWash, alignItems: "center", justifyContent: "center" },
  weatherCopy: { flex: 1, gap: spacing.xxs },
  weatherTitle: { fontWeight: "800", fontSize: 15, lineHeight: 20 },
  weatherNote: { color: colors.muted, fontSize: 12, lineHeight: 17 },
  warning: { color: colors.gold, fontSize: 13, lineHeight: 19 },
  loadingCard: { minHeight: 260, borderRadius: radius.xl, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke, padding: spacing.xl, justifyContent: "center", alignItems: "center", gap: spacing.md },
  loadingRail: { flexDirection: "row", marginBottom: spacing.md },
  loadingBlock: { width: 72, height: 92, borderRadius: radius.lg, backgroundColor: colors.surfaceMuted, borderWidth: 1, borderColor: colors.strokeStrong },
  loadingTitle: { textAlign: "center", fontWeight: "800" },
  result: { borderRadius: radius.xl, borderCurve: "continuous", borderWidth: 1, borderColor: colors.strokeStrong, padding: spacing.xl, gap: spacing.lg, overflow: "hidden", boxShadow: shadows.card },
  resultTop: { flexDirection: "row", alignItems: "center", gap: spacing.lg },
  scoreRing: { width: 74, height: 74, borderRadius: 37, borderWidth: 5, borderColor: colors.sage, alignItems: "center", justifyContent: "center" },
  scoreValue: { fontSize: 21, lineHeight: 24, fontWeight: "900", fontVariant: ["tabular-nums"] },
  scoreUnit: { color: colors.muted, fontSize: 9, lineHeight: 12, fontWeight: "800", textTransform: "uppercase" },
  resultCopy: { flex: 1, gap: spacing.xs },
  resultName: { fontSize: 24, lineHeight: 29, fontWeight: "900" },
  explanation: { color: colors.inkSoft },
  weatherResult: { alignSelf: "flex-start", flexDirection: "row", alignItems: "center", gap: spacing.xs, borderRadius: radius.pill, backgroundColor: colors.goldWash, paddingHorizontal: spacing.md, paddingVertical: spacing.sm },
  weatherResultText: { color: colors.gold, fontSize: 12, lineHeight: 16, fontWeight: "700" },
  actions: { gap: spacing.sm },
  emptyResult: { borderRadius: radius.xl, borderWidth: 1, borderStyle: "dashed", borderColor: colors.strokeStrong, padding: spacing.xxl, alignItems: "center", gap: spacing.sm },
  emptyTitle: { fontSize: 18, lineHeight: 23, fontWeight: "800", textAlign: "center" },
  emptyNote: { color: colors.muted, textAlign: "center" },
  error: { color: colors.danger }
});
