import { useState } from "react";
import { KeyboardAvoidingView, Pressable, StyleSheet, TextInput, View } from "react-native";
import { router } from "expo-router";
import { AppText, Display, Eyebrow } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Reveal } from "@/components/motion";
import { Screen } from "@/components/Screen";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

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
            <View style={styles.mark} />
            <AppText style={styles.wordmark}>FITSYNC</AppText>
            <View style={styles.badge}><AppText style={styles.badgeText}>PRIVATE BETA</AppText></View>
          </View>
        </Reveal>

        <Reveal delay={70}>
          <View style={styles.hero}>
            <Eyebrow>Your wardrobe, remixed</Eyebrow>
            <Display style={styles.headline}>
              The closet you{"\n"}already{"\n"}<AppText style={styles.headlineAccent}>own.</AppText>
            </Display>
            <AppText style={styles.subtitle}>Catalog real pieces, build weather-aware looks, and save the combinations that feel like you.</AppText>
          </View>
        </Reveal>

        <Reveal delay={140}>
          <View style={styles.preview}>
            <View style={[styles.previewCard, styles.previewBack]} />
            <View style={[styles.previewCard, styles.previewMiddle]} />
            <View style={[styles.previewCard, styles.previewFront]}>
              <Eyebrow style={styles.previewEyebrow}>Today's edit</Eyebrow>
              <AppText style={styles.previewTitle}>Dinner,{"\n"}effortless</AppText>
              <View style={styles.previewRail}>
                <View style={[styles.swatch, { backgroundColor: "#E6D1BD" }]} />
                <View style={[styles.swatch, { backgroundColor: "#25242B" }]} />
                <View style={[styles.swatch, { backgroundColor: colors.white }]} />
              </View>
            </View>
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
              icon="arrow"
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
    <Pressable accessibilityRole="button" accessibilityState={{ selected: active }} onPress={onPress} style={[modeTabStyles.tab, active && modeTabStyles.tabActive]}>
      <AppText style={[modeTabStyles.label, active && modeTabStyles.labelActive]}>{label}</AppText>
    </Pressable>
  );
}

const modeTabStyles = StyleSheet.create({
  tab: { flex: 1, minHeight: 46, alignItems: "flex-start", justifyContent: "center", paddingHorizontal: spacing.md },
  tabActive: { backgroundColor: colors.rose },
  label: { fontFamily: fonts.bold, fontWeight: "700", color: colors.muted, fontSize: 11, letterSpacing: 1.2, textTransform: "uppercase" },
  labelActive: { color: colors.white }
});

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.canvas },
  content: { justifyContent: "flex-start", gap: spacing.xxl, paddingBottom: spacing.xxl },
  brandRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm, borderBottomWidth: 2, borderColor: colors.strokeStrong, paddingBottom: spacing.lg },
  mark: { width: 22, height: 22, backgroundColor: colors.rose },
  wordmark: { fontSize: 18, fontFamily: fonts.black, fontWeight: "800", flex: 1, letterSpacing: -0.3 },
  badge: { borderWidth: 1, borderColor: colors.stroke, paddingHorizontal: spacing.sm, paddingVertical: 6 },
  badgeText: { color: colors.muted, fontSize: 9, lineHeight: 12, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6 },
  hero: { gap: spacing.md },
  headline: { fontSize: 46, lineHeight: 44 },
  headlineAccent: { color: colors.roseSoft, fontSize: 46, lineHeight: 44, fontFamily: fonts.black, fontWeight: "800", textTransform: "uppercase" },
  subtitle: { color: colors.muted, fontSize: 14, lineHeight: 21, maxWidth: 300 },
  preview: { height: 190, justifyContent: "center", alignItems: "center" },
  previewCard: { position: "absolute", width: "80%", height: 150, borderWidth: 1, borderColor: colors.stroke },
  previewBack: { backgroundColor: colors.surfaceElevated, transform: [{ rotate: "-4deg" }] },
  previewMiddle: { backgroundColor: colors.surface, opacity: 0.9, transform: [{ rotate: "4deg" }, { translateX: 10 }] },
  previewFront: { backgroundColor: colors.rose, borderColor: colors.rose, padding: spacing.lg, justifyContent: "flex-end", gap: spacing.sm, transform: [{ translateX: -8 }] },
  previewEyebrow: { color: "rgba(255,255,255,0.8)" },
  previewTitle: { color: colors.white, fontSize: 22, lineHeight: 23, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.6, textTransform: "uppercase" },
  previewRail: { flexDirection: "row", gap: spacing.sm, marginTop: spacing.sm },
  swatch: { width: 26, height: 6 },
  form: { gap: spacing.md, borderTopWidth: 2, borderColor: colors.strokeStrong, paddingTop: spacing.xl },
  modeRow: { flexDirection: "row", borderWidth: 1, borderColor: colors.stroke, marginBottom: spacing.xs },
  label: { fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", color: colors.muted, letterSpacing: 1.4, textTransform: "uppercase", marginBottom: -spacing.xs },
  input: { height: 48, borderWidth: 1, borderColor: colors.stroke, borderLeftWidth: 2, borderLeftColor: colors.strokeStrong, backgroundColor: colors.surface, color: colors.ink, paddingHorizontal: spacing.md, fontSize: 15, fontFamily: fonts.medium },
  error: { color: colors.roseSoft, fontSize: 13, lineHeight: 19 },
  privacy: { color: colors.muted, fontSize: 11, lineHeight: 17 }
});
