import { useMemo, useState } from "react";
import { StyleSheet, View } from "react-native";
import { router, useLocalSearchParams } from "expo-router";
import { ChevronRight, CloudSun, Heart, Sparkles } from "@/icons";
import { useCloset, useFavoriteOutfit, useOutfitFeedback, useOutfits } from "@/api/queries";
import { mediaUrl } from "@/api/client";
import { AppText, Caption, Heading, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { PressableScale, Reveal } from "@/components/motion";
import { OutfitCollage } from "@/components/outfit-rail";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { RatingRow } from "@/components/rating-row";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { tryOnHref, tryOnSubset } from "@/lib/tryon";
import { weatherLabel } from "@/lib/useStyleOutfit";
import { colors, fonts, radius, spacing } from "@/theme";

export default function LookDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const outfits = useOutfits(false);
  const closet = useCloset();
  const favorite = useFavoriteOutfit();
  const feedback = useOutfitFeedback();
  const [rating, setRating] = useState(0);
  const outfit = outfits.data?.outfits.find((o) => o.id === id);
  const items = useMemo(() => outfit ? (closet.data?.items ?? []).filter((item) => outfit.item_ids.includes(item.id)) : [], [outfit, closet.data]);
  const canTry = tryOnSubset(items).length > 0;
  const isFavorite = Boolean(outfit?.favorited || favorite.data?.id === outfit?.id);

  if (!outfit) {
    return (
      <Screen>
        <PushHeader title="Look" onBack={() => router.back()} />
        <StatePanel title={outfits.isLoading ? "Opening look" : "Look not found"} message={outfits.isLoading ? "One moment…" : "It may have been removed."} />
      </Screen>
    );
  }

  return (
    <Screen footer={<Button title="Try it on" icon={Sparkles} variant="accent" disabled={!canTry} onPress={() => router.push(tryOnHref(items, "&auto=1"))} />}>
      <PushHeader title="Look" onBack={() => router.back()} actionIcon={Heart} actionLabel={isFavorite ? "Favourite" : "Mark favourite"}
        onAction={() => !isFavorite && favorite.mutate(outfit.id)} />
      <Reveal><OutfitCollage items={items} height={400} animateKey={outfit.id} /></Reveal>
      <Reveal delay={200}>
        <View style={styles.meta}>
          <View style={styles.tags}>
            <View style={styles.tag}><AppText style={styles.tagText}>{outfit.occasion}</AppText></View>
            {weatherLabel(outfit.weather_context) ? <View style={styles.tag}><CloudSun size={13} color={colors.inkSoft} /><AppText style={styles.tagText}>{weatherLabel(outfit.weather_context)}</AppText></View> : null}
            {isFavorite ? <View style={styles.tag}><Heart size={12} color={colors.flare} fill={colors.flare} /><AppText style={styles.tagText}>Favourite</AppText></View> : null}
          </View>
          <Title style={styles.name}>{outfit.name}</Title>
          <AppText style={styles.explain}>{outfit.explanation}</AppText>
          <RatingRow value={rating} disabled={feedback.isPending} onChange={(value) => { setRating(value); feedback.mutate({ id: outfit.id, rating: value }); }} />
        </View>
      </Reveal>
      <Reveal delay={280}>
        <View style={styles.pieces}>
          <Heading>In this look</Heading>
          {items.map((item) => (
            <PressableScale key={item.id} accessibilityRole="button" accessibilityLabel={item.name} onPress={() => router.push(`/item/${item.id}`)} style={styles.piece}>
              <View style={styles.thumb}>{mediaUrl(item.image_url) ? <Photo source={mediaUrl(item.image_url)!} /> : null}</View>
              <View style={styles.flex}>
                <AppText style={styles.pieceName}>{item.name}</AppText>
                <Caption style={styles.capitalize}>{item.category}{item.brand ? ` · ${item.brand}` : ""}</Caption>
              </View>
              <ChevronRight size={18} color={colors.muted} />
            </PressableScale>
          ))}
        </View>
      </Reveal>
      {!canTry ? <Caption>Try-on works with tops, bottoms and dresses.</Caption> : null}
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  meta: { gap: spacing.md },
  tags: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  tag: { flexDirection: "row", alignItems: "center", gap: 5, height: 30, paddingHorizontal: spacing.md, borderRadius: radius.pill, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke },
  tagText: { fontSize: 13, color: colors.inkSoft, fontFamily: fonts.medium, textTransform: "capitalize" },
  name: { fontSize: 40, lineHeight: 42 },
  explain: { color: colors.inkSoft, fontSize: 16, lineHeight: 24 },
  pieces: { gap: spacing.sm },
  piece: { flexDirection: "row", alignItems: "center", gap: spacing.md, padding: spacing.sm, paddingRight: spacing.md, backgroundColor: colors.surface, borderRadius: radius.lg, borderWidth: 1, borderColor: colors.stroke },
  thumb: { width: 56, height: 70, borderRadius: radius.sm, overflow: "hidden", backgroundColor: colors.canvasSoft },
  pieceName: { fontSize: 15, fontFamily: fonts.medium },
  capitalize: { textTransform: "capitalize" }
});
