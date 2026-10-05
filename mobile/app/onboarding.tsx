import { useState } from "react";
import { StyleSheet, TextInput, View } from "react-native";
import { Redirect, router } from "expo-router";
import Animated, { FadeInRight, FadeOutLeft, useAnimatedStyle, useDerivedValue, withSpring } from "react-native-reanimated";
import { ArrowRight, Check } from "@/icons";
import { AppText, Caption, Display, Em, Punch } from "@/components/AppText";
import { Button } from "@/components/Button";
import { LogoMark } from "@/components/Logo";
import { Chip } from "@/components/Chip";
import { PressableScale, SETTLE, SPRING } from "@/components/motion";
import { Screen } from "@/components/Screen";
import { useUpdateProfile } from "@/api/queries";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";

const styleAnchors = ["minimal", "streetwear", "classic", "athleisure", "soft glam", "workwear", "tailored", "weekend"];
const colorAnchors = [
  { name: "ink", value: "#242128" }, { name: "cream", value: "#E8D9C8" }, { name: "denim", value: "#496B83" }, { name: "berry", value: "#9B3F61" },
  { name: "olive", value: "#6E7552" }, { name: "cobalt", value: "#3C56B8" }, { name: "gold", value: "#C79043" }, { name: "lilac", value: "#9D85B6" }
];
const STEPS = 3;

export default function Onboarding() {
  const token = useAuthStore((state) => state.token);
  const onboardingComplete = useAuthStore((state) => state.onboardingComplete);
  const completeOnboarding = useAuthStore((state) => state.completeOnboarding);
  const update = useUpdateProfile();
  const [step, setStep] = useState(0);
  const [name, setName] = useState("");
  const [anchors, setAnchors] = useState<string[]>([]);
  const [palette, setPalette] = useState<string[]>([]);
  const progress = useDerivedValue(() => withSpring((step + 1) / STEPS, SPRING), [step]);
  const bar = useAnimatedStyle(() => ({ width: `${progress.value * 100}%` }));

  const toggle = (value: string, setter: React.Dispatch<React.SetStateAction<string[]>>) =>
    setter((current) => current.includes(value) ? current.filter((item) => item !== value) : [...current, value]);

  async function finish() {
    await completeOnboarding();
    update.mutate({ display_name: name.trim() || undefined, style_preferences: anchors, favorite_colors: palette, onboarding_complete: true });
    router.replace("/today");
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;
  if (onboardingComplete) return <Redirect href="/today" />;

  const canNext = step !== 0 || name.trim().length > 0;
  const footer = (
    <View style={styles.footer}>
      {step > 0 ? <Button title="Skip" variant="ghost" stretch={false} onPress={() => step < STEPS - 1 ? setStep(step + 1) : finish()} /> : <View />}
      <View style={styles.flex}>
        <Button title={step < STEPS - 1 ? "Continue" : "Start styling"} icon={step < STEPS - 1 ? ArrowRight : Check}
          disabled={!canNext} onPress={() => step < STEPS - 1 ? setStep(step + 1) : finish()} />
      </View>
    </View>
  );

  return (
    <Screen footer={footer}>
      <View style={styles.progressRow}>
        <LogoMark size={30} tone="light" />
        <Punch style={styles.stepNo}>{String(step + 1).padStart(2, "0")} / {String(STEPS).padStart(2, "0")}</Punch>
        <View style={styles.track}><Animated.View style={[styles.fill, bar]} /></View>
      </View>
      <Animated.View key={step} entering={FadeInRight.duration(420).easing(SETTLE)} exiting={FadeOutLeft.duration(200)} style={styles.step}>
        {step === 0 ? (
          <>
                        <Display>What should we <Em>call</Em> you?</Display>
            <TextInput accessibilityLabel="Your name" autoFocus value={name} onChangeText={setName} placeholder="First name" placeholderTextColor={colors.faint}
              returnKeyType="next" onSubmitEditing={() => canNext && setStep(1)} style={styles.input} />
          </>
        ) : step === 1 ? (
          <>
                        <Display>How do you like to <Em>dress?</Em></Display>
            <Caption>Pick any that feel like you. We use them to rank outfits.</Caption>
            <View style={styles.chips}>{styleAnchors.map((value) => <Chip key={value} active={anchors.includes(value)} onPress={() => toggle(value, setAnchors)}>{value}</Chip>)}</View>
          </>
        ) : (
          <>
                        <Display>Colours you <Em>reach for</Em></Display>
            <Caption>Tap the ones already in your closet.</Caption>
            <View style={styles.palette}>
              {colorAnchors.map((color) => {
                const active = palette.includes(color.name);
                return (
                  <PressableScale key={color.name} accessibilityRole="checkbox" accessibilityLabel={color.name} accessibilityState={{ checked: active }} scaleTo={0.9}
                    onPress={() => toggle(color.name, setPalette)} style={styles.colorCell}>
                    <View style={[styles.swatch, { backgroundColor: color.value }, active && styles.swatchOn]}>{active ? <Check size={20} color={color.name === "cream" ? colors.ink : colors.white} strokeWidth={3} /> : null}</View>
                    <AppText style={[styles.colorName, active && styles.colorNameOn]}>{color.name}</AppText>
                  </PressableScale>
                );
              })}
            </View>
          </>
        )}
      </Animated.View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  progressRow: { flexDirection: "row", alignItems: "center", gap: spacing.md, marginTop: spacing.md },
  stepNo: { fontSize: 12, fontVariant: ["tabular-nums"] },
  track: { flex: 1, height: 6, borderRadius: 3, backgroundColor: colors.canvasSoft, overflow: "hidden" },
  fill: { height: 6, borderRadius: 3, backgroundColor: colors.ink, borderRightWidth: 6, borderColor: colors.accent },
  step: { gap: spacing.lg },
  input: { height: 64, borderRadius: radius.md, backgroundColor: colors.surface, paddingHorizontal: spacing.lg, fontSize: 22, color: colors.ink, fontFamily: fonts.regular, borderWidth: 1, borderColor: colors.stroke },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.sm },
  palette: { flexDirection: "row", flexWrap: "wrap", marginHorizontal: -spacing.sm },
  colorCell: { width: "25%", alignItems: "center", gap: spacing.xs, paddingVertical: spacing.sm },
  swatch: { width: 60, height: 60, borderRadius: 30, alignItems: "center", justifyContent: "center", borderWidth: 3, borderColor: "transparent" },
  swatchOn: { borderColor: colors.canvas, boxShadow: "0 0 0 2.5px #0D0D0F", transform: [{ scale: 1.06 }] },
  colorName: { fontSize: 13, color: colors.muted, textTransform: "capitalize" },
  colorNameOn: { color: colors.ink, fontFamily: fonts.semibold },
  footer: { flexDirection: "row", alignItems: "center", gap: spacing.sm }
});
