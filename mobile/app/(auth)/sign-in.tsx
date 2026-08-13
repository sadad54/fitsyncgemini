import { useState } from "react";
import { KeyboardAvoidingView, Pressable, StyleSheet, TextInput, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { router } from "expo-router";
import { AppText, Display, Eyebrow } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Reveal } from "@/components/motion";
import { Screen } from "@/components/Screen";
import { useAuthStore } from "@/store/auth";
import { colors, gradients, radius, shadows, spacing } from "@/theme";

export default function SignIn() {
  const [mode, setMode] = useState<"sign-in" | "sign-up">("sign-in");
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
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      if (mode === "sign-up") {
        await signUp(email, password);
        if (!useAuthStore.getState().token) {
          setNotice("Check your email to confirm your account, then sign in.");
          return;
        }
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
      <Screen bottomInset={false} contentStyle={styles.content}>
        <Reveal>
          <View style={styles.brandRow}>
            <View style={styles.mark}><View style={styles.markInset} /></View>
            <AppText style={styles.wordmark}>FitSync</AppText>
            <View style={styles.badge}><AppText style={styles.badgeText}>PRIVATE BETA</AppText></View>
          </View>
        </Reveal>

        <Reveal delay={70}>
          <View style={styles.hero}>
            <Eyebrow>Your wardrobe, remixed</Eyebrow>
            <Display>A smarter closet starts with what you own.</Display>
            <AppText style={styles.subtitle}>Catalog real pieces, build weather-aware looks, and save the combinations that feel like you.</AppText>
          </View>
        </Reveal>

        <Reveal delay={140}>
          <View style={styles.preview}>
            <View style={[styles.previewCard, styles.previewBack]} />
            <LinearGradient colors={gradients.plum} style={[styles.previewCard, styles.previewMiddle]} />
            <LinearGradient colors={gradients.rose} style={[styles.previewCard, styles.previewFront]}>
              <Eyebrow style={styles.previewEyebrow}>Today’s edit</Eyebrow>
              <AppText style={styles.previewTitle}>Dinner, but effortless.</AppText>
              <View style={styles.previewRail}>
                <View style={[styles.swatch, { backgroundColor: "#E6D1BD" }]} />
                <View style={[styles.swatch, { backgroundColor: "#25242B" }]} />
                <View style={[styles.swatch, { backgroundColor: "#9A425D" }]} />
              </View>
            </LinearGradient>
          </View>
        </Reveal>

        <Reveal delay={210}>
          <View style={styles.form}>
            <View style={styles.modeRow}>
              <ModeTab label="Sign in" active={mode === "sign-in"} onPress={() => setMode("sign-in")} />
              <ModeTab label="Create account" active={mode === "sign-up"} onPress={() => setMode("sign-up")} />
            </View>
            <AppText style={styles.label}>Email</AppText>
            <TextInput
              accessibilityLabel="Email"
              autoCapitalize="none"
              autoComplete="email"
              keyboardType="email-address"
              returnKeyType="next"
              value={email}
              onChangeText={setEmail}
              placeholder="you@example.com"
              placeholderTextColor={colors.faint}
              style={styles.input}
            />
            <AppText style={styles.label}>Password</AppText>
            <TextInput
              accessibilityLabel="Password"
              autoCapitalize="none"
              autoComplete={mode === "sign-up" ? "new-password" : "current-password"}
              secureTextEntry
              returnKeyType="done"
              value={password}
              onChangeText={setPassword}
              onSubmitEditing={submit}
              placeholder="At least 6 characters"
              placeholderTextColor={colors.faint}
              style={styles.input}
            />
            <Button
              title={busy ? "Opening your closet…" : mode === "sign-up" ? "Create my style space" : "Sign in"}
              disabled={!ready || busy}
              onPress={submit}
            />
            {error ? <AppText selectable style={styles.error}>{error}</AppText> : null}
            {notice ? <AppText selectable style={styles.error}>{notice}</AppText> : null}
            <AppText style={styles.privacy}>Your session is secured with Supabase auth and stored only on this device.</AppText>
          </View>
        </Reveal>
      </Screen>
    </KeyboardAvoidingView>
  );
}

function ModeTab({ label, active, onPress }: { label: string; active: boolean; onPress: () => void }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected: active }}
      onPress={onPress}
      style={[modeTabStyles.tab, active && modeTabStyles.tabActive]}
    >
      <AppText style={[modeTabStyles.label, active && modeTabStyles.labelActive]}>{label}</AppText>
    </Pressable>
  );
}

const modeTabStyles = StyleSheet.create({
  tab: { flex: 1, alignItems: "center", justifyContent: "center", paddingVertical: spacing.sm, borderRadius: radius.pill },
  tabActive: { backgroundColor: colors.ink },
  label: { fontWeight: "700", color: colors.faint, fontSize: 14 },
  labelActive: { color: colors.white }
});

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.canvas },
  content: { justifyContent: "space-between", paddingBottom: spacing.xxl },
  brandRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  mark: { width: 42, height: 42, borderRadius: 14, backgroundColor: colors.ink, alignItems: "center", justifyContent: "center" },
  markInset: { width: 12, height: 12, borderRadius: 6, backgroundColor: colors.canvas },
  wordmark: { fontSize: 20, fontWeight: "900", flex: 1 },
  badge: { borderRadius: radius.pill, borderWidth: 1, borderColor: colors.strokeStrong, paddingHorizontal: spacing.md, paddingVertical: 6 },
  badgeText: { color: colors.muted, fontSize: 10, lineHeight: 13, fontWeight: "800", letterSpacing: 0.8 },
  hero: { gap: spacing.md },
  subtitle: { color: colors.muted, fontSize: 17, lineHeight: 26 },
  preview: { height: 190, justifyContent: "center", alignItems: "center" },
  previewCard: { position: "absolute", width: "82%", height: 148, borderRadius: radius.xl, borderCurve: "continuous", boxShadow: shadows.card },
  previewBack: { backgroundColor: colors.surfaceMuted, transform: [{ rotate: "-7deg" }, { translateX: -12 }] },
  previewMiddle: { opacity: 0.64, transform: [{ rotate: "7deg" }, { translateX: 14 }] },
  previewFront: { padding: spacing.xl, justifyContent: "flex-end", gap: spacing.sm },
  previewEyebrow: { color: "rgba(255,255,255,0.72)" },
  previewTitle: { color: colors.white, fontSize: 24, lineHeight: 28, fontWeight: "900" },
  previewRail: { flexDirection: "row", gap: spacing.sm },
  swatch: { width: 30, height: 8, borderRadius: radius.pill },
  form: { gap: spacing.md },
  modeRow: { flexDirection: "row", gap: spacing.xs, backgroundColor: colors.surfaceMuted, borderRadius: radius.pill, padding: 4 },
  label: { fontSize: 14, fontWeight: "700", color: colors.inkSoft },
  input: { minHeight: 56, borderRadius: radius.lg, borderCurve: "continuous", borderWidth: 1, borderColor: colors.strokeStrong, backgroundColor: colors.surface, color: colors.ink, paddingHorizontal: spacing.lg, fontSize: 17 },
  error: { color: colors.danger },
  privacy: { color: colors.faint, fontSize: 12, lineHeight: 18, textAlign: "center" }
});
