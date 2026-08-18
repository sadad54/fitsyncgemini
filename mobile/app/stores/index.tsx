import { useMemo, useState } from "react";
import { Pressable, StyleSheet, TextInput, View } from "react-native";
import { Redirect, router } from "expo-router";
import { AppText, Title } from "@/components/AppText";
import { SearchIcon } from "@/components/Icon";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_STORES } from "@/data/discover";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

export default function NearbyStores() {
  const token = useAuthStore((state) => state.token);
  const [query, setQuery] = useState("");

  const stores = useMemo(
    () =>
      SEED_STORES.filter(
        (store) => !query || `${store.name} ${store.address}`.toLowerCase().includes(query.toLowerCase())
      ),
    [query]
  );

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen scroll bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.headerWrap}>
        <PushHeader title="Nearby" onBack={() => router.back()} rule="none" />
      </View>

      <View style={styles.hero}>
        <Title style={styles.heroTitle}>Stores within walking distance</Title>
        <AppText style={styles.heroNote}>Ranked by distance from where you are now.</AppText>
      </View>

      <View style={styles.searchShell}>
        <SearchIcon size={16} color={colors.muted} />
        <TextInput
          accessibilityLabel="Search stores"
          value={query}
          onChangeText={setQuery}
          placeholder="Search stores or neighborhoods"
          placeholderTextColor={colors.faint}
          returnKeyType="search"
          style={styles.input}
        />
      </View>

      {stores.map((store) => (
        <Pressable
          key={store.id}
          accessibilityRole="button"
          accessibilityLabel={store.name}
          onPress={() => router.push(`/stores/${store.id}`)}
          style={styles.store}
        >
          <View style={styles.storeTop}>
            <AppText style={styles.storeName}>{store.name}</AppText>
            <AppText style={styles.storeDistance}>{store.distance}</AppText>
          </View>
          <AppText style={styles.storeCategory}>{store.category}</AppText>
          <View style={styles.ratingRow}>
            <View style={styles.diamonds}>
              {[1, 2, 3, 4, 5].map((n) => (
                <View key={n} style={[styles.diamond, n <= Math.round(store.rating) ? styles.diamondFilled : styles.diamondEmpty]} />
              ))}
            </View>
            <AppText style={styles.ratingValue}>{store.rating.toFixed(1)}</AppText>
            <View style={styles.priceRow}>
              {[1, 2, 3, 4].map((n) => (
                <View key={n} style={[styles.priceSquare, n <= store.price ? styles.priceFilled : styles.priceEmpty]} />
              ))}
            </View>
          </View>
          <AppText style={styles.storeAddress}>{store.address}</AppText>
        </Pressable>
      ))}
      <View style={{ height: 40 }} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  headerWrap: { paddingHorizontal: spacing.xl, paddingTop: spacing.sm },
  hero: { paddingHorizontal: spacing.xl, paddingBottom: spacing.lg, borderBottomWidth: 2, borderColor: colors.strokeStrong },
  heroTitle: { fontSize: 40, lineHeight: 37 },
  heroNote: { color: colors.muted, fontSize: 12, lineHeight: 18, marginTop: 11 },
  searchShell: { height: 52, flexDirection: "row", alignItems: "center", gap: spacing.sm, paddingHorizontal: spacing.xl, borderBottomWidth: 1, borderColor: colors.stroke },
  input: { flex: 1, color: colors.ink, fontSize: 14, fontFamily: fonts.medium },
  store: { paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, borderBottomWidth: 1, borderColor: colors.stroke },
  storeTop: { flexDirection: "row", alignItems: "baseline", justifyContent: "space-between", gap: spacing.md },
  storeName: { flex: 1, fontSize: 19, lineHeight: 20, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.4, textTransform: "uppercase" },
  storeDistance: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  storeCategory: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase", marginTop: spacing.sm },
  ratingRow: { flexDirection: "row", alignItems: "center", gap: spacing.md, marginTop: 11 },
  diamonds: { flexDirection: "row", gap: 5 },
  diamond: { width: 11, height: 11, borderWidth: 1, transform: [{ rotate: "45deg" }] },
  diamondFilled: { backgroundColor: colors.rose, borderColor: colors.rose },
  diamondEmpty: { backgroundColor: "transparent", borderColor: colors.stroke },
  ratingValue: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1 },
  priceRow: { flexDirection: "row", gap: 3, marginLeft: spacing.xs },
  priceSquare: { width: 9, height: 9, borderWidth: 1 },
  priceFilled: { backgroundColor: colors.ink, borderColor: colors.ink },
  priceEmpty: { backgroundColor: "transparent", borderColor: colors.stroke },
  storeAddress: { color: colors.muted, fontSize: 12, lineHeight: 18, marginTop: spacing.sm }
});
