import { useMemo, useState } from "react";
import { Pressable, StyleSheet, TextInput, View } from "react-native";
import { Redirect, router } from "expo-router";
import { AppText, Display, Eyebrow } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { Reveal } from "@/components/motion";
import { Screen } from "@/components/Screen";
import { useUpdateProfile } from "@/api/queries";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

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
    await completeOnboarding();
    router.replace("/(tabs)/home");
    update.mutate({ display_name: name.trim(), style_preferences: styles, favorite_colors: colorsSelected, onboarding_complete: true });
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;
  if (onboardingComplete) return <Redirect href="/(tabs)/home" />;

  return (
    <Screen bottomInset={false}>
      <View style={stylesSheet.progressTrack}><View style={[stylesSheet.progress, { width: `${progress * 100}%` }]} /></View>
      <Reveal>
        <View style={stylesSheet.header}>
          <Eyebrow>Three details, better looks</Eyebrow>
          <Display>Tune the{"\n"}stylist.</Display>
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
                <Pressable key={color.name} accessibilityRole="button" accessibilityLabel={color.name} accessibilityState={{ selected: active }} style={stylesSheet.colorWrap} onPress={() => toggle(color.name, setColorsSelected)}>
                  <View style={[stylesSheet.colorSwatch, { backgroundColor: color.value }, active && stylesSheet.colorSwatchActive]} />
                  <AppText style={[stylesSheet.colorName, active && stylesSheet.colorNameActive]}>{color.name}</AppText>
                </Pressable>
              );
            })}
          </View>
        </View>
      </Reveal>

      <Button title={update.isPending ? "Building your profile…" : "Enter my closet"} icon="arrow" disabled={!ready || update.isPending} onPress={finish} />
      {update.error ? <AppText selectable style={stylesSheet.error}>{update.error.message}</AppText> : null}
    </Screen>
  );
}

const stylesSheet = StyleSheet.create({
  progressTrack: { height: 3, backgroundColor: colors.surfaceElevated },
  progress: { height: "100%", backgroundColor: colors.rose },
  header: { gap: spacing.md, borderBottomWidth: 2, borderColor: colors.strokeStrong, paddingBottom: spacing.lg },
  note: { color: colors.muted, fontSize: 13, lineHeight: 20 },
  section: { gap: spacing.md, paddingVertical: spacing.md, borderBottomWidth: 1, borderColor: colors.stroke },
  stepRow: { flexDirection: "row", alignItems: "baseline", gap: spacing.md },
  step: { color: colors.roseSoft, fontSize: 11, fontFamily: fonts.black, fontWeight: "800" },
  sectionTitle: { fontSize: 17, lineHeight: 21, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.2 },
  helper: { color: colors.muted, fontSize: 12, lineHeight: 17 },
  input: { height: 50, borderWidth: 1, borderColor: colors.stroke, borderLeftWidth: 2, borderLeftColor: colors.strokeStrong, backgroundColor: colors.surface, color: colors.ink, paddingHorizontal: spacing.md, fontSize: 15, fontFamily: fonts.medium },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  palette: { flexDirection: "row", flexWrap: "wrap", gap: spacing.md },
  colorWrap: { alignItems: "flex-start", gap: spacing.xs, width: 66 },
  colorSwatch: { width: "100%", height: 44, borderWidth: 1, borderColor: colors.stroke },
  colorSwatchActive: { borderWidth: 2, borderColor: colors.rose },
  colorName: { color: colors.muted, fontSize: 9, lineHeight: 12, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  colorNameActive: { color: colors.ink },
  error: { color: colors.roseSoft }
});
