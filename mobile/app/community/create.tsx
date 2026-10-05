import { useMemo, useState } from "react";
import { ScrollView, StyleSheet, TextInput, View } from "react-native";
import { Redirect, router } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset, useSavedOutfits } from "@/api/queries";
import { AppText, Caption, Display, Em, Punch } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { PressableScale, Reveal } from "@/components/motion";
import { Photo } from "@/components/Photo";
import { PreviewNote } from "@/components/PreviewNote";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_TAG_CHIPS } from "@/data/discover";
import { ArrowRight, Check } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, layout, radius, spacing } from "@/theme";

export default function CreatePost() {
  const token = useAuthStore((state) => state.token);
  const saved = useSavedOutfits();
  const closet = useCloset();
  const [pick, setPick] = useState<string | null>(null);
  const [caption, setCaption] = useState("");
  const [tag, setTag] = useState("");
  const [focused, setFocused] = useState(false);

  const photos = useMemo(
    () => (closet.data?.items ?? []).map((item) => mediaUrl(item.image_url)).filter(Boolean) as string[],
    [closet.data]
  );
  const outfits = saved.data?.outfits ?? [];
  const activePick = pick ?? outfits[0]?.id ?? null;

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen footer={<Button title="Post to community" icon={ArrowRight} disabled={!caption.trim()} onPress={() => router.replace("/community")} />}>
      <PushHeader title="Share a look" onBack={() => router.back()} backGlyph="✕" />
      <Reveal>
        <View style={styles.hero}>
          <Display style={styles.heroTitle}>Post something you <Em>actually</Em> wore.</Display>
          <AppText style={styles.note}>Pick a saved look. Captions do better when they name the pieces.</AppText>
        </View>
      </Reveal>
      <PreviewNote>Posting isn't live yet — nothing you write here is shared.</PreviewNote>

      <View style={styles.section}>
        <Punch style={styles.label}>Choose a saved look</Punch>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.bleed} contentContainerStyle={styles.rail}>
          {outfits.length ? outfits.map((outfit, index) => {
            const active = activePick === outfit.id;
            const image = photos.length ? photos[index % photos.length] : undefined;
            return (
              <PressableScale key={outfit.id} accessibilityRole="radio" accessibilityState={{ selected: active }} accessibilityLabel={outfit.name}
                onPress={() => setPick(outfit.id)} style={styles.pick}>
                <View style={[styles.pickMedia, active && styles.pickMediaActive]}>
                  {image ? <Photo source={image} /> : <View style={styles.placeholder} />}
                  {active ? <View style={styles.tick}><Check size={14} color={colors.ink} strokeWidth={3} /></View> : null}
                </View>
                <AppText numberOfLines={2} style={[styles.pickName, active && styles.pickNameActive]}>{outfit.name}</AppText>
              </PressableScale>
            );
          }) : <Caption style={styles.empty}>Save a look first and it shows up here.</Caption>}
        </ScrollView>
      </View>

      <View style={styles.section}>
        <Punch style={styles.label}>Caption</Punch>
        <TextInput accessibilityLabel="Caption" value={caption} onChangeText={setCaption} placeholder="Name the pieces and the plan…"
          placeholderTextColor={colors.faint} multiline onFocus={() => setFocused(true)} onBlur={() => setFocused(false)}
          style={[styles.input, focused && styles.inputFocus]} />
      </View>

      <View style={styles.section}>
        <Punch style={styles.label}>Tag a challenge · optional</Punch>
        <View style={styles.chips}>
          {SEED_TAG_CHIPS.map((label) => <Chip key={label} active={tag === label} onPress={() => setTag(tag === label ? "" : label)}>{label}</Chip>)}
        </View>
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  hero: { gap: spacing.sm },
  heroTitle: { fontSize: 40, lineHeight: 42 },
  note: { color: colors.inkSoft, fontSize: 15, lineHeight: 22 },
  section: { gap: spacing.sm },
  label: { color: colors.muted },
  bleed: { marginHorizontal: -layout.gutter },
  rail: { paddingHorizontal: layout.gutter, gap: spacing.md },
  pick: { width: 116, gap: spacing.sm },
  pickMedia: { height: 144, borderRadius: radius.lg, overflow: "hidden", backgroundColor: colors.surface, borderWidth: 2.5, borderColor: "transparent" },
  pickMediaActive: { borderColor: colors.ink },
  tick: { position: "absolute", top: 8, right: 8, width: 24, height: 24, borderRadius: 12, backgroundColor: colors.accent, borderWidth: 1.5, borderColor: colors.ink, alignItems: "center", justifyContent: "center" },
  placeholder: { flex: 1, backgroundColor: colors.canvasSoft },
  pickName: { color: colors.muted, fontSize: 13, lineHeight: 17, fontFamily: fonts.medium },
  pickNameActive: { color: colors.ink },
  empty: { paddingVertical: spacing.lg },
  input: {
    minHeight: 120, borderRadius: radius.md, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke,
    padding: spacing.lg, fontSize: 16, lineHeight: 22, color: colors.ink, fontFamily: fonts.regular, textAlignVertical: "top"
  },
  inputFocus: { borderColor: colors.ink },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs }
});
