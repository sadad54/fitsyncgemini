import { Linking, StyleSheet, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { AppText, Caption, Display, Punch } from "@/components/AppText";
import { Button } from "@/components/Button";
import { PressableScale, Reveal } from "@/components/motion";
import { PreviewNote } from "@/components/PreviewNote";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_HOURS, SEED_STORES } from "@/data/discover";
import { ArrowUpRight, MapPin, Star } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";

export default function StoreDetail() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const store = SEED_STORES.find((entry) => entry.id === id) ?? SEED_STORES[0];
  const contact = [
    { label: "Phone", value: "+1 415 555 0148", href: "tel:+14155550148" },
    { label: "Website", value: "atelierseven.co", href: "https://atelierseven.co" }
  ];
  const today = new Date().toLocaleDateString("en-US", { weekday: "short" });

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen footer={<Button title="Get directions" icon={MapPin} onPress={() => Linking.openURL(`https://maps.google.com/?q=${encodeURIComponent(store.address)}`).catch(() => {})} />}>
      <PushHeader title="Store" onBack={() => router.back()} />
      <Reveal>
        <View style={styles.hero}>
          <Punch style={styles.category}>{store.category}</Punch>
          <Display style={styles.name}>{store.name}</Display>
          <View style={styles.metaRow}>
            <View style={styles.rating}><Star size={13} color={colors.ink} fill={colors.ink} /><AppText style={styles.ratingText}>{store.rating.toFixed(1)}</AppText></View>
            <AppText style={styles.metaText}>{store.distance} · {store.address}</AppText>
          </View>
        </View>
      </Reveal>
      <PreviewNote>Sample store details — hours and contact info aren't real yet.</PreviewNote>

      <View style={styles.card}>
        <Punch style={styles.label}>Hours</Punch>
        {SEED_HOURS.map(([day, time]) => {
          const isToday = day.startsWith(today);
          return (
            <View key={day} style={[styles.hourRow, isToday && styles.hourToday]}>
              <AppText style={[styles.day, isToday && styles.strong]}>{day}{isToday ? " · today" : ""}</AppText>
              <AppText style={[styles.time, time === "Closed" && styles.closed]}>{time}</AppText>
            </View>
          );
        })}
      </View>

      <View style={styles.card}>
        {contact.map((row, i) => (
          <PressableScale key={row.label} accessibilityRole="link" accessibilityLabel={`${row.label}: ${row.value}`}
            onPress={() => Linking.openURL(row.href).catch(() => {})} style={[styles.contact, i > 0 && styles.rule]}>
            <View style={styles.flex}>
              <Caption>{row.label}</Caption>
              <AppText style={styles.contactValue}>{row.value}</AppText>
            </View>
            <ArrowUpRight size={18} color={colors.inkSoft} />
          </PressableScale>
        ))}
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  hero: { gap: spacing.sm },
  category: { color: colors.muted },
  name: { fontSize: 46, lineHeight: 46 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm, flexWrap: "wrap" },
  rating: { flexDirection: "row", alignItems: "center", gap: 4, backgroundColor: colors.accent, borderRadius: radius.pill, paddingHorizontal: 10, height: 28, borderWidth: 1, borderColor: colors.ink },
  ratingText: { fontSize: 13, fontFamily: fonts.semibold },
  metaText: { color: colors.inkSoft, fontSize: 14 },
  card: { backgroundColor: colors.surface, borderRadius: radius.xl, padding: spacing.lg, gap: spacing.xs, borderWidth: 1, borderColor: colors.stroke },
  label: { color: colors.muted, marginBottom: spacing.xs },
  hourRow: { flexDirection: "row", justifyContent: "space-between", paddingVertical: 8, paddingHorizontal: spacing.sm, borderRadius: radius.sm },
  hourToday: { backgroundColor: colors.canvas },
  day: { color: colors.inkSoft, fontSize: 14 },
  strong: { color: colors.ink, fontFamily: fonts.semibold },
  time: { fontSize: 14, fontFamily: fonts.medium, fontVariant: ["tabular-nums"] },
  closed: { color: colors.muted },
  contact: { flexDirection: "row", alignItems: "center", gap: spacing.md, minHeight: 56, paddingVertical: spacing.sm },
  rule: { borderTopWidth: 1, borderColor: colors.stroke },
  contactValue: { fontSize: 16, fontFamily: fonts.semibold, fontWeight: "600" }
});
