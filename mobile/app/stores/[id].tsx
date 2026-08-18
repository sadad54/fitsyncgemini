import { Linking, Pressable, StyleSheet, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { AppText, Eyebrow } from "@/components/AppText";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_HOURS, SEED_STORES } from "@/data/discover";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

export default function StoreDetail() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);

  const store = SEED_STORES.find((entry) => entry.id === id) ?? SEED_STORES[0];
  const contact = [
    { label: "Phone", value: "+1 415 555 0148", href: "tel:+14155550148" },
    { label: "Website", value: "atelierseven.co", href: "https://atelierseven.co" }
  ];

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen scroll bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.headerWrap}>
        <PushHeader title="Store" onBack={() => router.back()} />
      </View>

      <View style={styles.body}>
        <Eyebrow style={styles.category}>{store.category}</Eyebrow>
        <AppText style={styles.name}>{store.name}</AppText>
        <View style={styles.ratingRow}>
          <View style={styles.diamonds}>
            {[1, 2, 3, 4, 5].map((n) => (
              <View key={n} style={[styles.diamond, n <= Math.round(store.rating) ? styles.diamondFilled : styles.diamondEmpty]} />
            ))}
          </View>
          <AppText style={styles.ratingValue}>{store.rating.toFixed(1)} · 128 ratings</AppText>
        </View>
        <AppText style={styles.address}>{store.distance} · {store.address}</AppText>
      </View>

      <View style={styles.hoursSection}>
        <AppText style={styles.sectionLabel}>Hours</AppText>
        {SEED_HOURS.map(([day, time]) => (
          <View key={day} style={styles.hourRow}>
            <AppText style={styles.day}>{day}</AppText>
            <AppText style={[styles.time, time === "Closed" && styles.timeClosed]}>{time}</AppText>
          </View>
        ))}
      </View>

      {contact.map((row) => (
        <Pressable
          key={row.label}
          accessibilityRole="button"
          accessibilityLabel={`${row.label}: ${row.value}`}
          onPress={() => Linking.openURL(row.href).catch(() => {})}
          style={styles.contactRow}
        >
          <View style={styles.contactCopy}>
            <AppText style={styles.contactLabel}>{row.label}</AppText>
            <AppText style={styles.contactValue}>{row.value}</AppText>
          </View>
          <AppText style={styles.contactGlyph}>→</AppText>
        </Pressable>
      ))}

      <View style={styles.ctaWrap}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Get directions"
          onPress={() =>
            Linking.openURL(`https://maps.google.com/?q=${encodeURIComponent(store.address)}`).catch(() => {})
          }
          style={styles.primary}
        >
          <AppText style={styles.primaryLabel}>Get directions</AppText>
          <AppText style={styles.primaryGlyph}>→</AppText>
        </Pressable>
      </View>
      <View style={{ height: 40 }} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  headerWrap: { paddingHorizontal: spacing.xl, paddingTop: spacing.sm },
  body: { paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.lg, borderBottomWidth: 1, borderColor: colors.stroke },
  category: { color: colors.muted },
  name: { fontSize: 38, lineHeight: 35, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -1.5, textTransform: "uppercase", marginTop: spacing.md },
  ratingRow: { flexDirection: "row", alignItems: "center", gap: spacing.md, marginTop: spacing.md },
  diamonds: { flexDirection: "row", gap: 5 },
  diamond: { width: 12, height: 12, borderWidth: 1, transform: [{ rotate: "45deg" }] },
  diamondFilled: { backgroundColor: colors.rose, borderColor: colors.rose },
  diamondEmpty: { backgroundColor: "transparent", borderColor: colors.rose },
  ratingValue: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1 },
  address: { color: colors.muted, fontSize: 13, lineHeight: 20, marginTop: 13 },
  hoursSection: { paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, borderBottomWidth: 1, borderColor: colors.stroke },
  sectionLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6, textTransform: "uppercase" },
  hourRow: { flexDirection: "row", justifyContent: "space-between", gap: spacing.md, borderTopWidth: 1, borderColor: colors.stroke, paddingTop: 11, marginTop: 11 },
  day: { color: colors.muted, fontSize: 12 },
  time: { color: colors.ink, fontSize: 12, fontFamily: fonts.bold, fontWeight: "700" },
  timeClosed: { color: colors.muted },
  contactRow: { flexDirection: "row", alignItems: "center", gap: spacing.md, paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, borderBottomWidth: 1, borderColor: colors.stroke },
  contactCopy: { flex: 1 },
  contactLabel: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  contactValue: { fontSize: 15, lineHeight: 18, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.2, marginTop: 6 },
  contactGlyph: { color: colors.muted, fontSize: 15 },
  ctaWrap: { paddingHorizontal: spacing.xl, paddingVertical: spacing.lg },
  primary: { height: 56, backgroundColor: colors.rose, flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: spacing.lg },
  primaryLabel: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 13, letterSpacing: 1.3, textTransform: "uppercase" },
  primaryGlyph: { color: colors.white, fontSize: 17 }
});
