import { useEffect } from "react";
import { Stack } from "expo-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ActivityIndicator, StyleSheet, View } from "react-native";
import { StatusBar } from "expo-status-bar";
import {
  Archivo_400Regular,
  Archivo_500Medium,
  Archivo_600SemiBold,
  Archivo_700Bold,
  Archivo_800ExtraBold,
  useFonts
} from "@expo-google-fonts/archivo";
import { AppText, Eyebrow } from "@/components/AppText";
import { ErrorBoundary } from "@/components/ErrorBoundary";
import { useAuthStore } from "@/store/auth";
import { colors, spacing } from "@/theme";

const queryClient = new QueryClient({
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
    Archivo_400Regular,
    Archivo_500Medium,
    Archivo_600SemiBold,
    Archivo_700Bold,
    Archivo_800ExtraBold
  });

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  if (!hydrated || !fontsLoaded) {
    return (
      <View style={styles.boot}>
        <StatusBar style="light" />
        <ActivityIndicator color={colors.rose} />
        <Eyebrow>FitSync</Eyebrow>
        <AppText style={styles.bootText}>Restoring your style space…</AppText>
      </View>
    );
  }

  return (
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <StatusBar style="light" />
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
          <Stack.Screen name="tryon/history" options={{ animation: "slide_from_right" }} />
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
  boot: { flex: 1, alignItems: "center", justifyContent: "center", gap: spacing.md, backgroundColor: colors.canvas },
  bootText: { color: colors.muted, fontSize: 14 }
});
