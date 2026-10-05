import { useEffect, useState } from "react";
import { KeyboardAvoidingView, StyleSheet, TextInput, View } from "react-native";
import { router } from "expo-router";
import { LinearGradient } from "expo-linear-gradient";
import Animated, {
  Easing,
  FadeInDown,
  interpolate,
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withDelay,
  withRepeat,
  withSequence,
  withSpring,
  withTiming
} from "react-native-reanimated";
import { AppText, Caption, Display, Em, Punch } from "@/components/AppText";
import { Button } from "@/components/Button";
import { LogoMark } from "@/components/Logo";
import { Reveal } from "@/components/motion";
import { Screen } from "@/components/Screen";
import { Segmented } from "@/components/Segmented";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";

type Mode = "sign-in" | "sign-up";

export default function SignIn() {
  const [mode, setMode] = useState<Mode>("sign-up");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [focus, setFocus] = useState<"email" | "password" | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const signIn = useAuthStore((state) => state.signIn);
  const signUp = useAuthStore((state) => state.signUp);
  const ready = email.trim().length > 3 && password.length >= 6;

  async function submit() {
    if (!ready || busy) return;
    setBusy(true); setError(null); setNotice(null);
    try {
      if (mode === "sign-up") {
        await signUp(email, password);
        if (!useAuthStore.getState().token) { setNotice("Check your email to confirm your account, then sign in."); return; }
      } else {
        await signIn(email, password);
      }
      router.replace("/onboarding");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong. Try again.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <KeyboardAvoidingView behavior={process.env.EXPO_OS === "ios" ? "padding" : undefined} style={styles.flex}>
      <Screen tone="stage" contentStyle={styles.content}>
        <Reveal>
          <View style={styles.brand}>
            <View style={styles.lockupRow} accessible accessibilityLabel="Flairwise">
              <LogoMark size={34} tone="dark" />
              <AppText allowFontScaling={false} style={styles.wordmark}>FLAIR<AppText style={styles.wordmarkVolt}>WISE</AppText></AppText>
            </View>
            <Punch style={styles.brandTag}>AI stylist</Punch>
          </View>
        </Reveal>

        <FittingVisual />

        <View style={styles.hero}>
          <Reveal delay={350}>
            <Display style={styles.headline}>Your closet,{"\n"}<Em style={styles.headlineEm}>on you.</Em></Display>
          </Reveal>
          <Reveal delay={450}>
            <AppText style={styles.sub}>Outfits styled from clothes you already own — and a preview of them on you before you get dressed.</AppText>
          </Reveal>
        </View>

        <Reveal delay={550}>
          <View style={styles.form}>
            <Segmented<Mode> tone="stage" value={mode} onChange={(m) => { setMode(m); setError(null); setNotice(null); }}
              options={[{ value: "sign-up", label: "Create account" }, { value: "sign-in", label: "Sign in" }]} />
            <TextInput accessibilityLabel="Email" autoCapitalize="none" autoComplete="email" keyboardType="email-address" textContentType="emailAddress"
              returnKeyType="next" value={email} onChangeText={setEmail} placeholder="Email" placeholderTextColor="rgba(246,246,242,0.4)"
              onFocus={() => setFocus("email")} onBlur={() => setFocus(null)} selectionColor={colors.accent}
              style={[styles.input, focus === "email" && styles.inputFocus]} />
            <TextInput accessibilityLabel="Password" autoCapitalize="none" autoComplete={mode === "sign-up" ? "new-password" : "current-password"}
              textContentType={mode === "sign-up" ? "newPassword" : "password"} secureTextEntry returnKeyType="go" value={password} onChangeText={setPassword}
              onFocus={() => setFocus("password")} onBlur={() => setFocus(null)} selectionColor={colors.accent}
              onSubmitEditing={submit} placeholder="Password (6+ characters)" placeholderTextColor="rgba(246,246,242,0.4)"
              style={[styles.input, focus === "password" && styles.inputFocus]} />
            <Button title={mode === "sign-up" ? "Get started" : "Sign in"} variant="accent" loading={busy} disabled={!ready} onPress={submit} />
            {error ? <Animated.View entering={FadeInDown}><AppText selectable style={styles.error}>{error}</AppText></Animated.View> : null}
            {notice ? <Animated.View entering={FadeInDown}><AppText selectable style={styles.notice}>{notice}</AppText></Animated.View> : null}
            <Caption style={styles.legal}>Your session is stored securely on this device.</Caption>
          </View>
        </Reveal>
      </Screen>
    </KeyboardAvoidingView>
  );
}

/**
 * A miniature fitting room: three garment cards fan out inside a volt
 * viewfinder while the scan beam sweeps — the product's promise in one image.
 */
function FittingVisual() {
  const reduced = useReducedMotion();
  const scan = useSharedValue(0);
  useEffect(() => {
    if (reduced) return;
    scan.value = withDelay(900, withRepeat(withSequence(
      withTiming(1, { duration: 2200, easing: Easing.inOut(Easing.cubic) }),
      withTiming(0, { duration: 2200, easing: Easing.inOut(Easing.cubic) })
    ), -1));
  }, [reduced, scan]);
  const beam = useAnimatedStyle(() => ({ opacity: reduced ? 0 : 1, transform: [{ translateY: interpolate(scan.value, [0, 1], [8, 196]) }] }));
  const cards = [
    { color: "#EDE6D8", rotate: -13, x: -78, delay: 0, label: "Linen", no: "01", fg: colors.ink },
    { color: colors.flare, rotate: 0, x: 0, delay: 90, label: "Coral", no: "02", fg: colors.ink },
    { color: colors.accent, rotate: 12, x: 78, delay: 180, label: "Volt", no: "03", fg: colors.ink }
  ];
  return (
    <View style={styles.visual} aria-hidden>
      <View style={styles.finder}>
        <View style={[styles.corner, styles.tl]} /><View style={[styles.corner, styles.tr]} />
        <View style={[styles.corner, styles.bl]} /><View style={[styles.corner, styles.br]} />
      </View>
      {cards.map((card) => <FanCard key={card.label} {...card} />)}
      <Animated.View pointerEvents="none" style={[styles.beam, beam]}>
        <LinearGradient colors={["rgba(212,255,58,0)", "rgba(212,255,58,0.28)", "rgba(212,255,58,0)"]} style={StyleSheet.absoluteFill} />
        <View style={styles.beamLine} />
      </Animated.View>
    </View>
  );
}

function FanCard({ color, rotate, x, delay, label, no, fg }: { color: string; rotate: number; x: number; delay: number; label: string; no: string; fg: string }) {
  const reduced = useReducedMotion();
  const t = useSharedValue(reduced ? 1 : 0);
  useEffect(() => { if (!reduced) t.value = withDelay(delay + 150, withSpring(1, { damping: 13, stiffness: 120 })); }, [reduced, delay, t]);
  const style = useAnimatedStyle(() => ({
    opacity: Math.min(1, t.value * 1.4),
    transform: [{ translateX: x * t.value }, { translateY: (1 - t.value) * 50 + Math.abs(rotate) * 0.6 * t.value }, { rotate: `${rotate * t.value}deg` }]
  }));
  return (
    <Animated.View style={[styles.card, { backgroundColor: color }, style]}>
      <View style={[styles.cardHanger, { borderColor: fg }]} />
      <View>
        <Punch style={[styles.cardNo, { color: fg }]}>No. {no}</Punch>
        <AppText style={[styles.cardLabel, { color: fg }]}>{label}</AppText>
      </View>
    </Animated.View>
  );
}

const C = 22;
const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.stage },
  content: { gap: spacing.xl },
  brand: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingTop: spacing.sm },
  lockupRow: { flexDirection: "row", alignItems: "center", gap: 4 },
  wordmark: { fontFamily: fonts.punch, fontSize: 20, lineHeight: 24, letterSpacing: 2.5, color: colors.onStage },
  wordmarkVolt: { fontFamily: fonts.punch, color: colors.accent },
  brandTag: { color: colors.onStageMuted, borderWidth: 1, borderColor: colors.stageLine, borderRadius: radius.pill, paddingHorizontal: 10, paddingVertical: 5, fontSize: 10 },
  visual: { height: 230, alignItems: "center", justifyContent: "center" },
  finder: { position: "absolute", top: 0, bottom: 0, width: 300 },
  corner: { position: "absolute", width: C, height: C, borderColor: colors.accent },
  tl: { top: 0, left: 0, borderTopWidth: 2.5, borderLeftWidth: 2.5, borderTopLeftRadius: 8 },
  tr: { top: 0, right: 0, borderTopWidth: 2.5, borderRightWidth: 2.5, borderTopRightRadius: 8 },
  bl: { bottom: 0, left: 0, borderBottomWidth: 2.5, borderLeftWidth: 2.5, borderBottomLeftRadius: 8 },
  br: { bottom: 0, right: 0, borderBottomWidth: 2.5, borderRightWidth: 2.5, borderBottomRightRadius: 8 },
  card: { position: "absolute", width: 116, height: 156, borderRadius: radius.lg, padding: spacing.md, justifyContent: "space-between", boxShadow: "0 18px 36px rgba(0,0,0,0.45)" },
  cardHanger: { width: 24, height: 24, borderRadius: 12, borderWidth: 1.5, alignSelf: "center", opacity: 0.5 },
  cardNo: { fontSize: 9, lineHeight: 11, opacity: 0.7 },
  cardLabel: { fontFamily: fonts.serif, fontSize: 22, lineHeight: 26 },
  beam: { position: "absolute", top: 0, width: 300, height: 26, marginTop: -13 },
  beamLine: { position: "absolute", left: 0, right: 0, top: 12, height: 2, backgroundColor: colors.accent, boxShadow: "0 0 14px rgba(212,255,58,0.9)" },
  hero: { gap: spacing.md },
  headline: { fontSize: 54, lineHeight: 54, color: colors.onStage },
  headlineEm: { color: colors.accent },
  sub: { color: colors.onStageMuted, fontSize: 16, lineHeight: 24 },
  form: { gap: spacing.md },
  input: {
    height: 56, borderRadius: radius.md, backgroundColor: colors.stageRaised, paddingHorizontal: spacing.lg, fontSize: 16,
    color: colors.onStage, fontFamily: fonts.regular, borderWidth: 1, borderColor: colors.stageLine
  },
  inputFocus: { borderColor: colors.accent },
  error: { color: "#FF8A73", fontSize: 14 },
  notice: { color: colors.accent, fontSize: 14 },
  legal: { textAlign: "center", color: colors.onStageMuted }
});
