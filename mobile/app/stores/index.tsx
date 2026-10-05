import { useMemo, useState } from "react";
import { StyleSheet, TextInput, View } from "react-native";
import { Redirect, router } from "expo-router";
import { AppText, Caption, Display, Em, Punch } from "@/components/AppText";
import { IconButton } from "@/components/IconButton";
import { PressableScale, Reveal } from "@/components/motion";
import { PreviewNote } from "@/components/PreviewNote";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_STORES } from "@/data/discover";
import { ArrowUpRight, MapPin, Search, Star, X } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";

export default function NearbyStores() {
  const token = useAuthStore((state) => state.token);
  const [query, setQuery] = useState("");
  const stores = useMemo(
    () => SEED_STORES.filter((store) => !query || `${store.name} ${store.address}`.toLowerCase().includes(query.toLowerCase())),
    [query]
  );

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen>
      <PushHeader title="Nearby" onBack={() => router.back()} />
      <Reveal>
        <View style={styles.hero}>
          <Punch style={styles.kicker}>Within walking distance</Punch>
          <Display style={styles.heroTitle}>Shops <Em>near you</Em></Display>
        </View>
      </Reveal>
      <PreviewNote>Sample stores — location search isn't connected yet.</PreviewNote>
      <View style={styles.search}>
        <Search size={18} color={colors.muted} />
        <TextInput accessibilityLabel="Search stores" value={query} onChangeText={setQuery} placeholder="Search stores or neighbourhoods"
          placeholderTextColor={colors.faint} returnKeyType="search" style={styles.input} />
        {query ? <IconButton icon={X} label="Clear search" size={32} onPress={() => setQuery("")} /> : null}
      </View>

      <View style={styles.list}>
        {stores.map((store, i) => (
          <Reveal key={store.id} index={i}>
            <PressableScale accessibilityRole="button" accessibilityLabel={`${store.name}, ${store.distance}`} onPress={() => router.push(`/stores/${store.id}`)} style={styles.store}>
              <View style={styles.pin}><MapPin size={18} color={colors.accent} /></View>
              <View style={styles.flex}>
                <View style={styles.top}>
                  <AppText numberOfLines={1} style={styles.name}>{store.name}</AppText>
                  <Punch style={styles.distance}>{store.distance}</Punch>
                </View>
                <Caption>{store.category}</Caption>
                <View style={styles.metaRow}>
                  <Star size={13} color={colors.ink} fill={colors.ink} />
                  <AppText style={styles.meta}>{store.rating.toFixed(1)}</AppText>
                  <AppText style={styles.price}>{"$".repeat(store.price)}<AppText style={styles.priceOff}>{"$".repeat(4 - store.price)}</AppText></AppText>
                </View>
                <Caption numberOfLines={1}>{store.address}</Caption>
              </View>
              <ArrowUpRight size={18} color={colors.inkSoft} />
            </PressableScale>
          </Reveal>
        ))}
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  hero: { gap: spacing.xs },
  kicker: { color: colors.muted },
  heroTitle: { fontSize: 48, lineHeight: 48 },
  search: { flexDirection: "row", alignItems: "center", gap: spacing.sm, height: 52, paddingLeft: spacing.lg, paddingRight: spacing.xs, borderRadius: radius.pill, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke },
  input: { flex: 1, height: "100%", color: colors.ink, fontSize: 16, fontFamily: fonts.regular },
  list: { gap: spacing.md },
  store: { flexDirection: "row", alignItems: "center", gap: spacing.md, backgroundColor: colors.surface, borderRadius: radius.xl, padding: spacing.lg, borderWidth: 1, borderColor: colors.stroke },
  pin: { width: 44, height: 44, borderRadius: 22, backgroundColor: colors.ink, alignItems: "center", justifyContent: "center", alignSelf: "flex-start" },
  top: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  name: { flex: 1, fontSize: 17, fontFamily: fonts.semibold, fontWeight: "600" },
  distance: { fontSize: 10, color: colors.muted },
  metaRow: { flexDirection: "row", alignItems: "center", gap: 5, marginVertical: 2 },
  meta: { fontSize: 13, fontFamily: fonts.semibold },
  price: { fontSize: 13, fontFamily: fonts.semibold, marginLeft: spacing.sm, letterSpacing: 1 },
  priceOff: { color: colors.faint }
});
