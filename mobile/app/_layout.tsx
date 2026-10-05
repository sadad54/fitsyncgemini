import { useEffect } from "react";
import { Stack } from "expo-router";
import { MutationCache, QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ActivityIndicator, StyleSheet, View } from "react-native";
import { StatusBar } from "expo-status-bar";
import { useFonts } from "expo-font";
import { Geist_400Regular, Geist_500Medium, Geist_600SemiBold, Geist_700Bold } from "@expo-google-fonts/geist";
import { InstrumentSerif_400Regular } from "@expo-google-fonts/instrument-serif";
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
    InstrumentSerif_400Regular
  });

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  if (!hydrated || !fontsLoaded) {
    return (
      <View style={styles.boot}>
        <StatusBar style="dark" />
        <ActivityIndicator color={colors.ink} />
      </View>
    );
  }

  return (
    <ErrorBoundary>
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
    </ErrorBoundary>
  );
}

const styles = StyleSheet.create({
  boot: { flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.canvas }
});
