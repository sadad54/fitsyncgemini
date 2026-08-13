import { useMemo, useState } from "react";
import { FlatList, Pressable, StyleSheet, View } from "react-native";
import { router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useCloset, useFavoriteOutfit, useOutfitFeedback, useSavedOutfits } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Chip } from "@/components/Chip";
import { OutfitRail } from "@/components/outfit-rail";
import { RatingRow } from "@/components/rating-row";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { colors, radius, shadows, spacing } from "@/theme";
import type { Outfit } from "@/types/api";

export default function Saved() {
  const [filter, setFilter] = useState<"all" | "favorites">("all");
  const [ratings, setRatings] = useState<Record<string, number>>({});
  const saved = useSavedOutfits();
  const closet = useCloset();
  const favorite = useFavoriteOutfit();
  const feedback = useOutfitFeedback();
  const outfits = useMemo(() => (saved.data?.outfits ?? []).filter((item) => filter === "all" || item.favorited), [saved.data, filter]);

  function rate(outfit: Outfit, value: number) {
    setRatings((current) => ({ ...current, [outfit.id]: value }));
    feedback.mutate({ id: outfit.id, rating: value });
  }

  return (
    <Screen scroll={false} contentStyle={styles.screen}>
      <View style={styles.header}>
        <Eyebrow>Your lookbook</Eyebrow>
        <Title>Outfits worth repeating.</Title>
        <AppText style={styles.subtitle}>A personal rail of combinations that already earned a yes.</AppText>
      </View>
      <View style={styles.filters}>
        <Chip active={filter === "all"} onPress={() => setFilter("all")}>All saved</Chip>
        <Chip active={filter === "favorites"} onPress={() => setFilter("favorites")}>Favorites</Chip>
      </View>

      {saved.isError ? (
        <StatePanel icon="cloud-offline-outline" title="Your lookbook could not sync" message={saved.error.message} action="Try again" onAction={() => saved.refetch()} />
      ) : (
        <FlatList
          data={outfits}
          keyExtractor={(item) => item.id}
          contentInsetAdjustmentBehavior="automatic"
          contentContainerStyle={styles.list}
          showsVerticalScrollIndicator={false}
          refreshing={saved.isRefetching}
          onRefresh={() => Promise.all([saved.refetch(), closet.refetch()])}
          renderItem={({ item }) => {
            const pieces = (closet.data?.items ?? []).filter((piece) => item.item_ids.includes(piece.id));
            return (
              <View style={styles.card}>
                <View style={styles.cardTop}>
                  <View style={styles.cardCopy}>
                    <Eyebrow>{item.occasion} · {Math.round(item.score * 100)}% match</Eyebrow>
                    <AppText style={styles.name}>{item.name}</AppText>
                  </View>
                  <Pressable accessibilityRole="button" accessibilityLabel={item.favorited ? "Favorite look" : "Mark as favorite"} accessibilityState={{ selected: item.favorited }} disabled={item.favorited || favorite.isPending} onPress={() => favorite.mutate(item.id)} style={styles.heart}>
                    <Ionicons name={item.favorited ? "heart" : "heart-outline"} size={21} color={item.favorited ? colors.rose : colors.muted} />
                  </Pressable>
                </View>
                <OutfitRail items={pieces} />
                <AppText style={styles.note}>{item.explanation}</AppText>
                <RatingRow value={ratings[item.id] ?? 0} onChange={(value) => rate(item, value)} disabled={feedback.isPending} />
              </View>
            );
          }}
          ListEmptyComponent={
            <StatePanel
              icon={saved.isLoading ? "hourglass-outline" : filter === "favorites" ? "heart-outline" : "bookmark-outline"}
              title={saved.isLoading ? "Opening your lookbook" : filter === "favorites" ? "No favorites yet" : "No saved looks yet"}
              message={saved.isLoading ? "Syncing your saved edits…" : filter === "favorites" ? "Tap the heart on a saved outfit to keep the best at the top of your mind." : "Generate one strong look, save it, and it will live here."}
              action={!saved.isLoading ? "Create a look" : undefined}
              onAction={() => router.push("/generate")}
            />
          }
        />
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { gap: spacing.lg },
  header: { gap: spacing.sm },
  subtitle: { color: colors.muted },
  filters: { flexDirection: "row", gap: spacing.sm },
  list: { flexGrow: 1, gap: spacing.lg, paddingTop: spacing.xs, paddingBottom: 112 },
  card: { backgroundColor: colors.surface, borderRadius: radius.xl, borderCurve: "continuous", borderWidth: 1, borderColor: colors.stroke, padding: spacing.xl, gap: spacing.lg, boxShadow: shadows.card },
  cardTop: { flexDirection: "row", alignItems: "flex-start", gap: spacing.md },
  cardCopy: { flex: 1, gap: spacing.xs },
  name: { fontSize: 22, lineHeight: 27, fontWeight: "900" },
  heart: { width: 48, height: 48, borderRadius: 24, backgroundColor: colors.roseWash, alignItems: "center", justifyContent: "center" },
  note: { color: colors.muted, fontSize: 14, lineHeight: 21 }
});
