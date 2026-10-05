import { useMemo, useState } from "react";
import { FlatList, Pressable, StyleSheet, View } from "react-native";
import { router } from "expo-router";
import { useCloset, useFavoriteOutfit, useOutfitFeedback, useSavedOutfits } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Chip } from "@/components/Chip";
import { OutfitRail } from "@/components/outfit-rail";
import { RatingRow } from "@/components/rating-row";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { colors, fonts, spacing } from "@/theme";
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
    <Screen scroll={false} bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.header}>
        <Eyebrow>Your lookbook</Eyebrow>
        <Title style={styles.title}>Outfits worth repeating</Title>
        <AppText style={styles.subtitle}>A personal rail of combinations that already earned a yes.</AppText>
      </View>
      <View style={styles.filters}>
        <Pressable style={[styles.filter, filter === "all" && styles.filterActive]} onPress={() => setFilter("all")}>
          <AppText style={[styles.filterLabel, filter === "all" && styles.filterLabelActive]}>All saved</AppText>
        </Pressable>
        <Pressable style={[styles.filter, filter === "favorites" && styles.filterActive]} onPress={() => setFilter("favorites")}>
          <AppText style={[styles.filterLabel, filter === "favorites" && styles.filterLabelActive]}>Favorites</AppText>
        </Pressable>
      </View>

      {saved.isError ? (
        <View style={styles.padded}>
          <StatePanel title="Your lookbook could not sync" message={saved.error.message} action="Try again" onAction={() => saved.refetch()} />
        </View>
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
                  <Pressable
                    accessibilityRole="button"
                    accessibilityLabel={item.favorited ? "Favorite look" : "Mark as favorite"}
                    accessibilityState={{ selected: item.favorited }}
                    disabled={item.favorited || favorite.isPending}
                    onPress={() => favorite.mutate(item.id)}
                    style={[styles.heart, item.favorited && styles.heartActive]}
                  >
                    <AppText style={[styles.heartGlyph, item.favorited && styles.heartGlyphActive]}>♥</AppText>
                  </Pressable>
                </View>
                <View style={styles.railWrap}><OutfitRail items={pieces} /></View>
                <AppText style={styles.note}>{item.explanation}</AppText>
                <View style={styles.ratingRow}><RatingRow value={ratings[item.id] ?? 0} onChange={(value) => rate(item, value)} disabled={feedback.isPending} /></View>
              </View>
            );
          }}
          ListEmptyComponent={
            <View style={styles.padded}>
              <StatePanel
                title={saved.isLoading ? "Opening your lookbook" : filter === "favorites" ? "No favorites yet" : "No saved looks yet"}
                message={saved.isLoading ? "Syncing your saved edits…" : filter === "favorites" ? "Tap the heart on a saved outfit to keep the best at the top of your mind." : "Generate one strong look, save it, and it will live here."}
                action={!saved.isLoading ? "Create a look" : undefined}
                onAction={() => router.push("/generate")}
              />
            </View>
          }
        />
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  header: { paddingHorizontal: spacing.xl, paddingBottom: spacing.lg, borderBottomWidth: 2, borderColor: colors.strokeStrong, gap: spacing.xs },
  title: { fontSize: 40 },
  subtitle: { color: colors.muted, fontSize: 12, marginTop: spacing.xs },
  filters: { flexDirection: "row", borderBottomWidth: 1, borderColor: colors.stroke },
  filter: { flex: 1, paddingVertical: spacing.md, alignItems: "flex-start", paddingHorizontal: spacing.xl, borderRightWidth: 1, borderColor: colors.stroke },
  filterActive: { backgroundColor: colors.rose, borderColor: colors.rose },
  filterLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  filterLabelActive: { color: colors.white },
  padded: { paddingHorizontal: spacing.xl },
  list: { flexGrow: 1, paddingBottom: 40 },
  card: { borderBottomWidth: 1, borderColor: colors.stroke },
  cardTop: { flexDirection: "row", alignItems: "flex-start", gap: spacing.md, paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.md },
  cardCopy: { flex: 1, gap: spacing.xs },
  name: { fontSize: 25, lineHeight: 25, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.6, textTransform: "uppercase" },
  heart: { width: 40, height: 40, borderWidth: 1, borderColor: colors.stroke, alignItems: "center", justifyContent: "center" },
  heartActive: { backgroundColor: colors.rose, borderColor: colors.rose },
  heartGlyph: { color: colors.muted, fontSize: 15 },
  heartGlyphActive: { color: colors.white },
  railWrap: { borderTopWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke },
  note: { color: colors.muted, fontSize: 13, lineHeight: 20, paddingHorizontal: spacing.xl, paddingTop: spacing.md },
  ratingRow: { paddingHorizontal: spacing.xl, paddingVertical: spacing.lg }
});
