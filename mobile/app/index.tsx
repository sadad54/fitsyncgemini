import { Redirect } from "expo-router";
import { AppText, Display, Eyebrow } from "@/components/AppText";
import { Screen } from "@/components/Screen";
import { useAuthStore } from "@/store/auth";
import { colors } from "@/theme";

export default function Index() {
  const token = useAuthStore((state) => state.token);
  const hydrated = useAuthStore((state) => state.hydrated);
  const onboardingComplete = useAuthStore((state) => state.onboardingComplete);

  if (!hydrated) {
    return (
      <Screen contentStyle={{ justifyContent: "center" }} bottomInset={false}>
        <Eyebrow>FitSync</Eyebrow>
        <Display>Curating your closet.</Display>
        <AppText style={{ color: colors.muted }}>Restoring your private session…</AppText>
      </Screen>
    );
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  // First-run access is local-first. A missing development backend should never
  // strand a person behind a network timeout before they can enter the app.
  if (!onboardingComplete) return <Redirect href="/onboarding" />;
  return <Redirect href="/(tabs)/home" />;
}
