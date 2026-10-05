import { useCallback, useEffect, useState } from "react";
import { Stack } from "expo-router";
import { MutationCache, QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StyleSheet, View } from "react-native";
import { StatusBar } from "expo-status-bar";
import { useFonts } from "expo-font";
// Per-weight imports: the package roots pull every weight's .ttf into the bundle.
import { Geist_400Regular } from "@expo-google-fonts/geist/400Regular";
import { Geist_500Medium } from "@expo-google-fonts/geist/500Medium";
import { Geist_600SemiBold } from "@expo-google-fonts/geist/600SemiBold";
import { Geist_700Bold } from "@expo-google-fonts/geist/700Bold";
import { InstrumentSerif_400Regular } from "@expo-google-fonts/instrument-serif/400Regular";
import { InstrumentSerif_400Regular_Italic } from "@expo-google-fonts/instrument-serif/400Regular_Italic";
import { Archivo_800ExtraBold } from "@expo-google-fonts/archivo/800ExtraBold";
import { BootBlank, BootSplash } from "@/components/BootSplash";
import { ErrorBoundary } from "@/components/ErrorBoundary";
import { useAuthStore } from "@/store/auth";
import { colors } from "@/theme";

const queryClient = new QueryClient({
  // A mutation that fails (timeout, network drop, 5xx) and has no local
  // onError would otherwise become an unhandled promise rejection — which
  // Hermes/Expo Go surfaces as a fatal-looking red screen. This always
  // fires alongside any per-call onError, so every mutation is guaranteed
  // to have its rejection observed somewhere.
  mutationCache: new MutationCache({
    onError: (error) => {
      if (__DEV__) console.warn("Mutation failed:", error instanceof Error ? error.message : error);
    }
  }),
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 2,
      retry: (failureCount, error) => {
        const status = typeof error === "object" && error && "status" in error ? Number(error.status) : 0;
        return status >= 400 && status < 500 ? false : failureCount < 2;
      },
      refetchOnWindowFocus: false
    },
    mutations: { retry: false }
  }
});

export default function RootLayout() {
  const hydrate = useAuthStore((state) => state.hydrate);
  const hydrated = useAuthStore((state) => state.hydrated);
  const [fontsLoaded] = useFonts({
    Geist_400Regular,
    Geist_500Medium,
    Geist_600SemiBold,
    Geist_700Bold,
    InstrumentSerif_400Regular,
    InstrumentSerif_400Regular_Italic,
    Archivo_800ExtraBold
  });
  const [splashDone, setSplashDone] = useState(false);
  const finishSplash = useCallback(() => setSplashDone(true), []);

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  if (!fontsLoaded) return <BootBlank />;

  return (
    <View style={styles.boot}>
    {hydrated ? <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <StatusBar style="dark" />
        <Stack
          screenOptions={{
            headerShown: false,
            contentStyle: { backgroundColor: colors.canvas },
            animation: "slide_from_right",
            gestureEnabled: true
          }}
        >
          <Stack.Screen name="index" options={{ animation: "fade" }} />
          <Stack.Screen name="(auth)/sign-in" options={{ animation: "fade" }} />
          <Stack.Screen name="onboarding" options={{ gestureEnabled: false, animation: "fade" }} />
          <Stack.Screen name="(tabs)" options={{ animation: "fade" }} />
          <Stack.Screen name="add-item" options={{ presentation: "modal", animation: "slide_from_bottom" }} />
          <Stack.Screen name="item/[id]" options={{ animation: "slide_from_right" }} />
          <Stack.Screen name="tryon/index" options={{ animation: "slide_from_right" }} />
          <Stack.Screen name="style/index" options={{ presentation: "fullScreenModal", animation: "slide_from_bottom", gestureEnabled: true }} />
          <Stack.Screen name="look/[id]" options={{ animation: "slide_from_right" }} />
          <Stack.Screen name="profile" options={{ animation: "slide_from_right" }} />
          <Stack.Screen name="community/index" options={{ animation: "slide_from_right" }} />
          <Stack.Screen name="community/post/[id]" options={{ animation: "slide_from_right" }} />
          <Stack.Screen name="community/create" options={{ presentation: "modal", animation: "slide_from_bottom" }} />
          <Stack.Screen name="community/challenge/[id]" options={{ animation: "slide_from_right" }} />
          <Stack.Screen name="community/member/[id]" options={{ animation: "slide_from_right" }} />
          <Stack.Screen name="trends/index" options={{ animation: "slide_from_right" }} />
          <Stack.Screen name="trends/[id]" options={{ animation: "slide_from_right" }} />
          <Stack.Screen name="stores/index" options={{ animation: "slide_from_right" }} />
          <Stack.Screen name="stores/[id]" options={{ animation: "slide_from_right" }} />
        </Stack>
      </QueryClientProvider>
    </ErrorBoundary> : null}
    {splashDone ? null : <BootSplash ready={hydrated} onDone={finishSplash} />}
    </View>
  );
}

const styles = StyleSheet.create({
  boot: { flex: 1, backgroundColor: colors.canvas }
});
