import { useMemo, useState } from "react";
import { StyleSheet, View } from "react-native";
import { router } from "expo-router";
import Animated, { FadeIn, LinearTransition } from "react-native-reanimated";
import { Heart, Images, Sparkles } from "@/icons";
import { useCloset, useSavedOutfits, useTryOns } from "@/api/queries";
import { mediaUrl } from "@/api/client";
import { AppText, Caption, Display, Em, Punch } from "@/components/AppText";
import { PressableScale, PulseDot, Reveal, Skeleton } from "@/components/motion";
import { OutfitCollage } from "@/components/outfit-rail";
import { Photo } from "@/components/Photo";
import { Screen } from "@/components/Screen";
import { Segmented } from "@/components/Segmented";
import { StatePanel } from "@/components/state-panel";
import type { ClothingItem, Outfit, TryOnResult } from "@/types/api";
import { colors, fonts, radius, spacing } from "@/theme";

type Filter = "all" | "onme" | "favorites";
type Entry = { kind: "look"; at: string; outfit: Outfit } | { kind: "tryon"; at: string; job: TryOnResult };

export default function Looks() {
  const [filter, setFilter] = useState<Filter>("all");
  const saved = useSavedOutfits();
  const tryons = useTryOns();
  const closet = useCloset();
  const items = closet.data?.items ?? [];

  const entries = useMemo(() => {
    const looks: Entry[] = (saved.data?.outfits ?? []).map((outfit) => ({ kind: "look", at: outfit.updated_at ?? outfit.created_at, outfit }));
    const jobs: Entry[] = (tryons.data?.results ?? []).map((job) => ({ kind: "tryon", at: job.created_at, job }));
    const pool = filter === "onme" ? jobs : filter === "favorites" ? looks.filter((e) => e.kind === "look" && e.outfit.favorited) : [...looks, ...jobs];
    return pool.sort((a, b) => b.at.localeCompare(a.at));
  }, [saved.data, tryons.data, filter]);

  const fitting = entries.filter((e) => e.kind === "tryon" && (e.job.status === "queued" || e.job.status === "processing"));
  const rest = entries.filter((e) => !fitting.includes(e));
  const columns = [rest.filter((_, i) => i % 2 === 0), rest.filter((_, i) => i % 2 === 1)];
  const loading = saved.isLoading || tryons.isLoading;

  return (
    <Screen tabbed refreshing={saved.isRefetching || tryons.isRefetching} onRefresh={() => { saved.refetch(); tryons.refetch(); closet.refetch(); }}>
      <Reveal>
        <View style={styles.header}>
          <Punch style={styles.count}>{(saved.data?.total ?? 0) + (tryons.data?.total ?? 0)} saved</Punch>
          <Display>Your <Em>looks</Em></Display>
        </View>
      </Reveal>
      <Reveal delay={60}>
        <Segmented<Filter> value={filter} onChange={setFilter} options={[
          { value: "all", label: "All" }, { value: "onme", label: "On me" }, { value: "favorites", label: "Favourites" }
        ]} />
      </Reveal>

      {fitting.map((entry) => entry.kind === "tryon" ? (
        <Animated.View key={entry.job.id} entering={FadeIn} layout={LinearTransition}>
          <PressableScale accessibilityRole="button" accessibilityLabel="Try-on in progress" onPress={() => router.push(`/tryon?job=${entry.job.id}`)} style={styles.fitting}>
            <PulseDot size={10} />
            <View style={styles.flex}>
              <AppText style={styles.fittingTitle}>Fitting a look on you…</AppText>
              <Caption style={styles.fittingNote}>Usually under a minute. Tap to watch.</Caption>
            </View>
          </PressableScale>
        </Animated.View>
      ) : null)}

      {saved.isError || tryons.isError ? (
        <StatePanel title="Looks didn't load" message={(saved.error ?? tryons.error)!.message} action="Try again" onAction={() => { saved.refetch(); tryons.refetch(); }} />
      ) : loading ? (
        <View style={styles.grid}>
          {[0, 1].map((c) => <View key={c} style={styles.column}>{[220, 280, 200].map((h, i) => <Skeleton key={i} style={{ height: c ? h + 40 : h, borderRadius: radius.lg }} />)}</View>)}
        </View>
      ) : !rest.length && !fitting.length ? (
        <StatePanel
          icon={filter === "favorites" ? Heart : Images}
          title={filter === "onme" ? "Nothing on you yet" : filter === "favorites" ? "No favourites yet" : "Your looks live here"}
          message={filter === "onme" ? "Try a look on and it lands here automatically." : filter === "favorites" ? "Heart a saved look to keep it at the top." : "Style a look and save it, or try one on."}
          action="Style me"
          onAction={() => router.push("/style")}
        />
      ) : (
        <View style={styles.grid}>
          {columns.map((column, c) => (
            <View key={c} style={styles.column}>
              {column.map((entry, i) => (
                <Reveal key={entry.kind === "look" ? entry.outfit.id : entry.job.id} index={i * 2 + c} delay={100}>
                  {entry.kind === "look" ? <LookCard outfit={entry.outfit} items={items} /> : <TryOnCard job={entry.job} />}
                </Reveal>
              ))}
            </View>
          ))}
        </View>
      )}
    </Screen>
  );
}

function LookCard({ outfit, items }: { outfit: Outfit; items: ClothingItem[] }) {
  const pieces = items.filter((item) => outfit.item_ids.includes(item.id));
  return (
    <PressableScale accessibilityRole="button" accessibilityLabel={outfit.name} onPress={() => router.push(`/look/${outfit.id}`)} style={styles.card}>
      <View style={styles.collage}><OutfitCollage items={pieces} height={200} /></View>
      <View style={styles.cardBody}>
        <AppText numberOfLines={2} style={styles.cardTitle}>{outfit.name}</AppText>
        <View style={styles.cardMeta}>
          <Caption style={styles.capitalize}>{outfit.occasion}</Caption>
          {outfit.favorited ? <Heart size={13} color={colors.flare} fill={colors.flare} /> : null}
        </View>
      </View>
    </PressableScale>
  );
}

function TryOnCard({ job }: { job: TryOnResult }) {
  const image = mediaUrl(job.result_image_url) ?? mediaUrl(job.person_image_url);
  const failed = job.status === "failed";
  return (
    <PressableScale accessibilityRole="button" accessibilityLabel="Open try-on" onPress={() => router.push(`/tryon?job=${job.id}`)} style={styles.card}>
      <View style={styles.tryon}>
        {image ? <Photo source={image} /> : null}
        <View style={[styles.onYou, failed && styles.onYouFailed]}>
          {failed ? null : <Sparkles size={11} color={colors.onAccent} strokeWidth={2.4} />}
          <Punch style={[styles.onYouText, failed && styles.onYouTextFailed]}>{failed ? "Didn't finish" : "On you"}</Punch>
        </View>
      </View>
      <View style={styles.cardBody}>
        <Caption>{new Date(job.created_at).toLocaleDateString(undefined, { day: "numeric", month: "short" })} · {job.item_ids.length} {job.item_ids.length === 1 ? "piece" : "pieces"}</Caption>
      </View>
    </PressableScale>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  header: { paddingTop: spacing.md, gap: spacing.xs },
  count: { color: colors.muted },
  fitting: { flexDirection: "row", alignItems: "center", gap: spacing.md, padding: spacing.lg, borderRadius: radius.lg, backgroundColor: colors.stage },
  fittingTitle: { fontSize: 15, fontFamily: fonts.semibold, fontWeight: "600", color: colors.onStage },
  fittingNote: { color: colors.onStageMuted },
  grid: { flexDirection: "row", gap: spacing.md, marginTop: -spacing.sm },
  column: { flex: 1, gap: spacing.md },
  card: { backgroundColor: colors.surface, borderRadius: radius.lg, overflow: "hidden", borderWidth: 1, borderColor: colors.stroke },
  collage: { padding: 6 },
  tryon: { width: "100%", aspectRatio: 3 / 4, backgroundColor: colors.canvasSoft },
  onYou: { position: "absolute", left: 8, top: 8, flexDirection: "row", alignItems: "center", gap: 4, height: 24, paddingHorizontal: 8, borderRadius: 6, backgroundColor: colors.accent, borderWidth: 1.5, borderColor: colors.ink },
  onYouFailed: { backgroundColor: colors.danger },
  onYouText: { color: colors.onAccent, fontSize: 9, lineHeight: 11 },
  onYouTextFailed: { color: colors.white },
  cardBody: { paddingHorizontal: spacing.md, paddingTop: spacing.xs, paddingBottom: spacing.md, gap: 2 },
  cardTitle: { fontSize: 15, lineHeight: 20, fontFamily: fonts.semibold, fontWeight: "600" },
  cardMeta: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  capitalize: { textTransform: "capitalize" }
});
