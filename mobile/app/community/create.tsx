import { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, TextInput, View } from "react-native";
import { Redirect, router } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset, useSavedOutfits } from "@/api/queries";
import { AppText, Title } from "@/components/AppText";
import { Chip } from "@/components/Chip";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_TAG_CHIPS } from "@/data/discover";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

export default function CreatePost() {
  const token = useAuthStore((state) => state.token);
  const saved = useSavedOutfits();
  const closet = useCloset();
  const [pick, setPick] = useState<string | null>(null);
  const [caption, setCaption] = useState("");
  const [tag, setTag] = useState("");

  const photos = useMemo(
    () => (closet.data?.items ?? []).map((item) => mediaUrl(item.image_url)).filter(Boolean) as string[],
    [closet.data]
  );
  const outfits = saved.data?.outfits ?? [];
  const activePick = pick ?? outfits[0]?.id ?? null;

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen scroll bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.headerWrap}>
        <PushHeader title="Share a look" onBack={() => router.back()} backGlyph="✕" />
      </View>

      <View style={styles.hero}>
        <Title style={styles.heroTitle}>Post something you actually wore.</Title>
        <AppText style={styles.heroNote}>Pick a saved outfit or a closet photo. Captions do better when they name the pieces.</AppText>
      </View>

      <AppText style={[styles.sectionLabel, styles.pickLabel]}>Choose a saved outfit</AppText>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.pickRail}>
        {outfits.length ? (
          outfits.map((outfit, index) => {
            const active = activePick === outfit.id;
            const image = photos[index % Math.max(photos.length, 1)];
            return (
              <Pressable
                key={outfit.id}
                accessibilityRole="button"
                accessibilityState={{ selected: active }}
                onPress={() => setPick(outfit.id)}
                style={styles.pick}
              >
                <View style={styles.pickMedia}>
                  {image ? <Photo source={image} /> : <View style={styles.mediaPlaceholder} />}
                  {active ? <View style={styles.pickRing} pointerEvents="none" /> : null}
                </View>
                <AppText numberOfLines={2} style={[styles.pickName, active && styles.pickNameActive]}>{outfit.name}</AppText>
              </Pressable>
            );
          })
        ) : (
          <View style={styles.pickEmpty}>
            <AppText style={styles.pickEmptyText}>Save a look first and it shows up here.</AppText>
          </View>
        )}
      </ScrollView>

      <View style={styles.form}>
        <AppText style={styles.fieldLabel}>Caption</AppText>
        <TextInput
          accessibilityLabel="Caption"
          value={caption}
          onChangeText={setCaption}
          placeholder="Name the pieces and the plan…"
          placeholderTextColor={colors.faint}
          multiline
          style={[styles.input, styles.textarea]}
        />

        <AppText style={styles.fieldLabel}>Tag a challenge — optional</AppText>
        <View style={styles.chips}>
          {SEED_TAG_CHIPS.map((label) => (
            <Chip key={label} active={tag === label} onPress={() => setTag(tag === label ? "" : label)}>
              {label}
            </Chip>
          ))}
        </View>

        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Post to community"
          disabled={!caption.trim()}
          onPress={() => router.replace("/community")}
          style={[styles.primary, !caption.trim() && styles.primaryDisabled]}
        >
          <AppText style={styles.primaryLabel}>Post to community</AppText>
          <AppText style={styles.primaryGlyph}>→</AppText>
        </Pressable>
      </View>
      <View style={{ height: 40 }} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  headerWrap: { paddingHorizontal: spacing.xl, paddingTop: spacing.sm },
  hero: { paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.lg, gap: spacing.md },
  heroTitle: { fontSize: 34, lineHeight: 32 },
  heroNote: { color: colors.muted, fontSize: 13, lineHeight: 20 },
  sectionLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6, textTransform: "uppercase" },
  pickLabel: { paddingHorizontal: spacing.xl, paddingBottom: spacing.sm },
  pickRail: { flexGrow: 0, borderTopWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke },
  pick: { width: 112, borderRightWidth: 1, borderColor: colors.stroke },
  pickMedia: { height: 132, backgroundColor: colors.surface, overflow: "hidden" },
  mediaPlaceholder: { flex: 1, backgroundColor: colors.surface },
  pickRing: { ...StyleSheet.absoluteFillObject, borderWidth: 3, borderColor: colors.rose },
  pickName: { color: colors.muted, fontSize: 9, lineHeight: 12, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase", paddingHorizontal: 11, paddingTop: 10, paddingBottom: spacing.md },
  pickNameActive: { color: colors.ink },
  pickEmpty: { paddingHorizontal: spacing.xl, paddingVertical: spacing.xl },
  pickEmptyText: { color: colors.muted, fontSize: 13 },
  form: { paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, gap: spacing.md },
  fieldLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  input: { borderWidth: 1, borderColor: colors.stroke, borderLeftWidth: 2, borderLeftColor: colors.strokeStrong, backgroundColor: colors.surface, color: colors.ink, paddingHorizontal: spacing.md, fontSize: 14, fontFamily: fonts.regular },
  textarea: { minHeight: 104, paddingTop: spacing.md, textAlignVertical: "top", lineHeight: 21 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  primary: { height: 54, marginTop: spacing.sm, backgroundColor: colors.rose, flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: spacing.lg },
  primaryDisabled: { opacity: 0.45 },
  primaryLabel: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 13, letterSpacing: 1.3, textTransform: "uppercase" },
  primaryGlyph: { color: colors.white, fontSize: 17 }
});
