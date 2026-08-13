import { useMemo, useState } from "react";
import { Pressable, StyleSheet, TextInput, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { Redirect, router } from "expo-router";
import { AppText, Display, Eyebrow } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { Reveal } from "@/components/motion";
import { Screen } from "@/components/Screen";
import { useUpdateProfile } from "@/api/queries";
import { useAuthStore } from "@/store/auth";
import { colors, gradients, radius, spacing } from "@/theme";

const styleAnchors = ["minimal", "streetwear", "classic", "athleisure", "soft glam", "workwear", "tailored", "weekend"];
const colorAnchors = [
  { name: "ink", value: "#242128" },
  { name: "cream", value: "#E8D9C8" },
  { name: "denim", value: "#496B83" },
  { name: "berry", value: "#9B3F61" },
  { name: "olive", value: "#6E7552" },
  { name: "cobalt", value: "#3C56B8" },
  { name: "gold", value: "#C79043" },
  { name: "lilac", value: "#9D85B6" }
];

export default function Onboarding() {
  const storedName = "";
  const token = useAuthStore((state) => state.token);
  const onboardingComplete = useAuthStore((state) => state.onboardingComplete);
  const completeOnboarding = useAuthStore((state) => state.completeOnboarding);
  const [name, setName] = useState(storedName);
  const [styles, setStyles] = useState<string[]>([]);
  const [colorsSelected, setColorsSelected] = useState<string[]>([]);
  const update = useUpdateProfile();
  const ready = name.trim().length > 1 && styles.length > 0 && colorsSelected.length > 0;
  const progress = useMemo(() => [name.trim().length > 1, styles.length > 0, colorsSelected.length > 0].filter(Boolean).length / 3, [name, styles, colorsSelected]);

  function toggle(value: string, setter: React.Dispatch<React.SetStateAction<string[]>>) {
    setter((current) => current.includes(value) ? current.filter((item) => item !== value) : [...current, value]);
  }

  async function finish() {
    if (!ready || update.isPending) return;
    // Enter immediately, then sync when the API is available. This keeps the
    // first-run experience usable on web previews and intermittent networks.
    await completeOnboarding();
    router.replace("/(tabs)/home");
    update.mutate({ display_name: name.trim(), style_preferences: styles, favorite_colors: colorsSelected, onboarding_complete: true });
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;
  if (onboardingComplete) return <Redirect href="/(tabs)/home" />;

  return (
    <Screen bottomInset={false}>
      <View style={stylesSheet.progressTrack}><LinearGradient colors={gradients.rose} style={[stylesSheet.progress, { width: `${progress * 100}%` }]} /></View>
      <Reveal>
        <View style={stylesSheet.header}>
          <Eyebrow>Three details, better looks</Eyebrow>
          <Display>Make the stylist feel like yours.</Display>
          <AppText style={stylesSheet.note}>We use these anchors to rank outfit combinations—not to put your taste in a box.</AppText>
        </View>
      </Reveal>

      <Reveal delay={80}>
        <View style={stylesSheet.section}>
          <View style={stylesSheet.stepRow}><AppText style={stylesSheet.step}>01</AppText><AppText style={stylesSheet.sectionTitle}>Your name</AppText></View>
          <TextInput accessibilityLabel="Display name" value={name} onChangeText={setName} placeholder="What should we call you?" placeholderTextColor={colors.faint} style={stylesSheet.input} />
        </View>
      </Reveal>

      <Reveal delay={140}>
        <View style={stylesSheet.section}>
          <View style={stylesSheet.stepRow}><AppText style={stylesSheet.step}>02</AppText><AppText style={stylesSheet.sectionTitle}>Your style energy</AppText></View>
          <AppText style={stylesSheet.helper}>Pick at least one. Three or four gives the best range.</AppText>
          <View style={stylesSheet.chips}>{styleAnchors.map((style) => <Chip key={style} active={styles.includes(style)} onPress={() => toggle(style, setStyles)}>{style}</Chip>)}</View>
        </View>
      </Reveal>

      <Reveal delay={200}>
        <View style={stylesSheet.section}>
          <View style={stylesSheet.stepRow}><AppText style={stylesSheet.step}>03</AppText><AppText style={stylesSheet.sectionTitle}>Colors you reach for</AppText></View>
          <View style={stylesSheet.palette}>
            {colorAnchors.map((color) => {
              const active = colorsSelected.includes(color.name);
              return (
                <View key={color.name} style={stylesSheet.colorWrap}>
                  <Pressable accessibilityRole="button" accessibilityLabel={color.name} accessibilityState={{ selected: active }} style={({ pressed }) => [stylesSheet.colorRing, active && stylesSheet.colorRingActive, pressed && stylesSheet.colorPressed]} onPress={() => toggle(color.name, setColorsSelected)}>
                    <View style={[stylesSheet.colorDot, { backgroundColor: color.value }]} />
                  </Pressable>
                  <AppText style={[stylesSheet.colorName, active && stylesSheet.colorNameActive]}>{color.name}</AppText>
                </View>
              );
            })}
          </View>
        </View>
      </Reveal>

      <Button title={update.isPending ? "Building your profile…" : "Enter my closet"} disabled={!ready || update.isPending} onPress={finish} />
      {update.error ? <AppText selectable style={stylesSheet.error}>{update.error.message}</AppText> : null}
    </Screen>
  );
}

const stylesSheet = StyleSheet.create({
  progressTrack: { height: 4, borderRadius: radius.pill, backgroundColor: colors.surfaceMuted, overflow: "hidden" },
  progress: { height: "100%", borderRadius: radius.pill },
  header: { gap: spacing.md },
  note: { color: colors.muted, fontSize: 17, lineHeight: 26 },
  section: { gap: spacing.md, paddingVertical: spacing.sm },
  stepRow: { flexDirection: "row", alignItems: "center", gap: spacing.md },
  step: { color: colors.rose, fontSize: 12, fontWeight: "900", fontVariant: ["tabular-nums"] },
  sectionTitle: { fontSize: 22, lineHeight: 27, fontWeight: "800" },
  helper: { color: colors.muted, fontSize: 14, lineHeight: 20 },
  input: { minHeight: 56, borderRadius: radius.lg, borderCurve: "continuous", borderWidth: 1, borderColor: colors.strokeStrong, backgroundColor: colors.surface, color: colors.ink, paddingHorizontal: spacing.lg, fontSize: 17 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.sm },
  palette: { flexDirection: "row", flexWrap: "wrap", gap: spacing.lg },
  colorWrap: { alignItems: "center", gap: spacing.xs, width: 54 },
  colorRing: { width: 50, height: 50, borderRadius: 25, borderWidth: 2, borderColor: "transparent", alignItems: "center", justifyContent: "center" },
  colorRingActive: { borderColor: colors.roseSoft },
  colorPressed: { opacity: 0.7 },
  colorDot: { width: 38, height: 38, borderRadius: 19, borderWidth: 1, borderColor: colors.strokeStrong },
  colorName: { color: colors.faint, fontSize: 11, lineHeight: 14, textTransform: "capitalize" },
  colorNameActive: { color: colors.inkSoft },
  error: { color: colors.danger }
});
