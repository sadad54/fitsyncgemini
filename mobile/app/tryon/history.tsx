import { FlatList, Pressable, StyleSheet, View } from "react-native";
import { Redirect, router } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useTryOns } from "@/api/queries";
import { AppText, Title } from "@/components/AppText";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

// Staggered tile heights keep the grid editorial rather than uniform.
const HEIGHTS = [214, 242, 196, 226];

function formatDate(iso: string) {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "";
  return date.toLocaleDateString(undefined, { day: "2-digit", month: "short" });
}

export default function TryOnHistory() {
  const token = useAuthStore((state) => state.token);
  const tryons = useTryOns();
  const results = tryons.data?.results ?? [];

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen scroll={false} bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.headerWrap}>
        <PushHeader title="Try-on history" onBack={() => router.back()} />
      </View>

      <View style={styles.hero}>
        <Title style={styles.heroTitle}>Every preview you kept</Title>
        <AppText style={styles.heroNote}>Saved previews stay on your account so you can compare two versions of the same evening.</AppText>
      </View>

      {tryons.isError ? (
        <View style={styles.padded}>
          <StatePanel title="History could not load" message={tryons.error.message} action="Try again" onAction={() => tryons.refetch()} />
        </View>
      ) : (
        <FlatList
          data={results}
          keyExtractor={(item) => item.id}
          numColumns={2}
          contentContainerStyle={styles.list}
          showsVerticalScrollIndicator={false}
          refreshing={tryons.isRefetching}
          onRefresh={() => tryons.refetch()}
          renderItem={({ item, index }) => {
            const image = mediaUrl(item.result_image_url) ?? mediaUrl(item.person_image_url);
            return (
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={`Preview from ${formatDate(item.created_at)}`}
                onPress={() => router.push(`/tryon?items=${item.item_ids.join(",")}`)}
                style={styles.tile}
              >
                <View style={[styles.tileMedia, { height: HEIGHTS[index % HEIGHTS.length] }]}>
                  {image ? <Photo source={image} grayscale={false} /> : <View style={styles.tilePlaceholder} />}
                  <View style={styles.tileBadge}>
                    <AppText style={styles.tileBadgeText}>{item.status === "completed" ? "Preview" : item.status}</AppText>
                  </View>
                </View>
                <View style={styles.tileBody}>
                  <AppText numberOfLines={2} style={styles.tileName}>
                    {item.item_ids.length ? `${item.item_ids.length} piece preview` : "Photo only"}
                  </AppText>
                  <AppText style={styles.tileMeta}>
                    {formatDate(item.created_at)} · {item.item_ids.length} pieces
                  </AppText>
                </View>
              </Pressable>
            );
          }}
          ListEmptyComponent={
            <View style={styles.padded}>
              <StatePanel
                title={tryons.isLoading ? "Opening your previews" : "Nothing previewed yet"}
                message={
                  tryons.isLoading
                    ? "Syncing your saved try-ons…"
                    : "Preview a look on your own photo and save it to start the history."
                }
                action={!tryons.isLoading ? "Preview a look" : undefined}
                onAction={() => router.replace("/tryon")}
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
  headerWrap: { paddingHorizontal: spacing.xl, paddingTop: spacing.sm },
  hero: { paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.lg, borderBottomWidth: 1, borderColor: colors.stroke, gap: spacing.md },
  heroTitle: { fontSize: 38, lineHeight: 36 },
  heroNote: { color: colors.muted, fontSize: 13, lineHeight: 20 },
  padded: { paddingHorizontal: spacing.xl },
  list: { flexGrow: 1, paddingBottom: 40 },
  tile: { width: "50%", borderRightWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke, backgroundColor: colors.canvas },
  tileMedia: { backgroundColor: colors.surface, overflow: "hidden" },
  tilePlaceholder: { flex: 1, backgroundColor: colors.surface },
  tileBadge: { position: "absolute", left: 0, top: 0, backgroundColor: colors.strokeStrong, paddingHorizontal: 7, paddingVertical: 5 },
  tileBadgeText: { color: colors.canvas, fontSize: 8, lineHeight: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  tileBody: { paddingHorizontal: spacing.md, paddingTop: 11, paddingBottom: spacing.lg },
  tileName: { fontFamily: fonts.black, fontWeight: "800", fontSize: 13, lineHeight: 16, letterSpacing: -0.2 },
  tileMeta: { color: colors.muted, fontSize: 10, letterSpacing: 0.8, textTransform: "uppercase", marginTop: 6 }
});
