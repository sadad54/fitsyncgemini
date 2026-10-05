import { useEffect, useState } from "react";
import { KeyboardAvoidingView, StyleSheet, TextInput, View } from "react-native";
import { router } from "expo-router";
import Animated, { FadeInDown, useAnimatedStyle, useReducedMotion, useSharedValue, withDelay, withSpring } from "react-native-reanimated";
import { Sparkles } from "lucide-react-native";
import { AppText, Caption, Display } from "@/components/AppText";
import { Button } from "@/components/Button";
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
      <Screen contentStyle={styles.content}>
        <View style={styles.brand}>
          <Sparkles size={18} color={colors.accent} strokeWidth={2.2} />
          <AppText style={styles.wordmark}>FitSync</AppText>
        </View>

        <Fan />

        <View style={styles.hero}>
          <Reveal delay={350}><Display style={styles.headline}>Your closet,{"\n"}<AppText style={styles.italic}>on you.</AppText></Display></Reveal>
          <Reveal delay={450}><AppText style={styles.sub}>Outfits styled from clothes you already own — and a preview of them on you before you get dressed.</AppText></Reveal>
        </View>

        <Reveal delay={550}>
          <View style={styles.form}>
            <Segmented<Mode> value={mode} onChange={(m) => { setMode(m); setError(null); setNotice(null); }}
              options={[{ value: "sign-up", label: "Create account" }, { value: "sign-in", label: "Sign in" }]} />
            <TextInput accessibilityLabel="Email" autoCapitalize="none" autoComplete="email" keyboardType="email-address" textContentType="emailAddress"
              returnKeyType="next" value={email} onChangeText={setEmail} placeholder="Email" placeholderTextColor={colors.faint} style={styles.input} />
            <TextInput accessibilityLabel="Password" autoCapitalize="none" autoComplete={mode === "sign-up" ? "new-password" : "current-password"}
              textContentType={mode === "sign-up" ? "newPassword" : "password"} secureTextEntry returnKeyType="go" value={password} onChangeText={setPassword}
              onSubmitEditing={submit} placeholder="Password (6+ characters)" placeholderTextColor={colors.faint} style={styles.input} />
            <Button title={mode === "sign-up" ? "Get started" : "Sign in"} loading={busy} disabled={!ready} onPress={submit} />
            {error ? <Animated.View entering={FadeInDown}><AppText selectable style={styles.error}>{error}</AppText></Animated.View> : null}
            {notice ? <Animated.View entering={FadeInDown}><AppText selectable style={styles.notice}>{notice}</AppText></Animated.View> : null}
            <Caption style={styles.legal}>Your session is stored securely on this device.</Caption>
          </View>
        </Reveal>
      </Screen>
    </KeyboardAvoidingView>
  );
}

/** Three garment swatches fan out like a stylist laying out options. */
function Fan() {
  const cards = [
    { color: "#E9DFD0", rotate: -14, x: -70, delay: 0, label: "Linen" },
    { color: colors.ink, rotate: 0, x: 0, delay: 90, label: "Wool" },
    { color: colors.accent, rotate: 13, x: 70, delay: 180, label: "Cobalt" }
  ];
  return (
    <View style={styles.fan} accessible={false}>
      {cards.map((card) => <FanCard key={card.label} {...card} />)}
    </View>
  );
}

function FanCard({ color, rotate, x, delay, label }: { color: string; rotate: number; x: number; delay: number; label: string }) {
  const reduced = useReducedMotion();
  const t = useSharedValue(reduced ? 1 : 0);
  useEffect(() => { if (!reduced) t.value = withDelay(delay + 120, withSpring(1, { damping: 14, stiffness: 120 })); }, [reduced, delay, t]);
  const style = useAnimatedStyle(() => ({
    opacity: Math.min(1, t.value * 1.4),
    transform: [{ translateX: x * t.value }, { translateY: (1 - t.value) * 40 + Math.abs(rotate) * 0.6 * t.value }, { rotate: `${rotate * t.value}deg` }]
  }));
  const light = color === "#E9DFD0";
  return (
    <Animated.View style={[styles.card, { backgroundColor: color }, style]}>
      <View style={[styles.cardHanger, { borderColor: light ? colors.ink : colors.onInk }]} />
      <AppText style={[styles.cardLabel, { color: light ? colors.ink : colors.onInk }]}>{label}</AppText>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.canvas },
  content: { gap: spacing.xl },
  brand: { flexDirection: "row", alignItems: "center", gap: 6, paddingTop: spacing.sm },
  wordmark: { fontFamily: fonts.serif, fontSize: 24, lineHeight: 28 },
  fan: { height: 210, alignItems: "center", justifyContent: "center" },
  card: { position: "absolute", width: 120, height: 160, borderRadius: radius.lg, padding: spacing.md, justifyContent: "space-between", boxShadow: "0 14px 30px rgba(23,20,15,0.16)" },
  cardHanger: { width: 26, height: 26, borderRadius: 13, borderWidth: 1.5, alignSelf: "center", opacity: 0.6 },
  cardLabel: { fontFamily: fonts.serif, fontSize: 20 },
  hero: { gap: spacing.md },
  headline: { fontSize: 48, lineHeight: 50 },
  italic: { fontFamily: fonts.serif, color: colors.accent, fontSize: 48, lineHeight: 50 },
  sub: { color: colors.inkSoft, fontSize: 16, lineHeight: 24 },
  form: { gap: spacing.md },
  input: { height: 54, borderRadius: radius.md, backgroundColor: colors.surface, paddingHorizontal: spacing.lg, fontSize: 16, color: colors.ink, fontFamily: fonts.regular, borderWidth: 1, borderColor: colors.stroke },
  error: { color: colors.danger, fontSize: 14 },
  notice: { color: colors.success, fontSize: 14 },
  legal: { textAlign: "center" }
});

