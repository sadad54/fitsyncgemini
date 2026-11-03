import { Linking, StyleSheet, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { useStore } from "@/api/discover-queries";
import { AppText, Caption, Display, Punch } from "@/components/AppText";
import { Button } from "@/components/Button";
import { PressableScale, Reveal } from "@/components/motion";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { splitHours } from "@/data/discover";
import { ArrowUpRight, CloudOff, MapPin, Star } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";

export default function StoreDetail() {
  const params = useLocalSearchParams<{ id: string; distance?: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const distance = typeof params.distance === "string" ? params.distance : "";
  const query = useStore(id);
  const store = query.data;
  const hours = splitHours(store?.opening_hours ?? []);
  const contact = [
    store?.phone ? { label: "Phone", value: store.phone, href: `tel:${store.phone.replace(/[^+\d]/g, "")}` } : null,
    store?.website ? { label: "Website", value: store.website.replace(/^https?:\/\/(www\.)?/, "").replace(/\/$/, ""), href: store.website } : null
  ].filter((row): row is { label: string; value: string; href: string } => row !== null);
  const today = new Date().toLocaleDateString("en-US", { weekday: "long" });
  const directions = store?.location
    ? `https://www.google.com/maps/dir/?api=1&destination=${store.location.lat},${store.location.lng}&destination_place_id=${encodeURIComponent(id ?? "")}`
    : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${store?.name ?? ""} ${store?.address ?? ""}`)}`;

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  if (!store) {
    return (
      <Screen>
        <PushHeader title="Store" onBack={() => router.back()} />
        {query.isError
          ? <StatePanel icon={CloudOff} title="Store details are unavailable" message={query.error instanceof Error ? query.error.message : "Try again in a moment."}
              action="Try again" onAction={() => query.refetch()} />
          : <StatePanel title="Loading…" message="Getting hours and contact details." />}
      </Screen>
    );
  }

  return (
    <Screen footer={<Button title="Get directions" icon={MapPin} onPress={() => Linking.openURL(directions).catch(() => {})} />}>
      <PushHeader title="Store" onBack={() => router.back()} />
      <Reveal>
        <View style={styles.hero}>
          {store.review_count ? <Punch style={styles.category}>{store.review_count.toLocaleString()} Google reviews</Punch> : null}
          <Display style={styles.name}>{store.name ?? "Store"}</Display>
          <View style={styles.metaRow}>
            {store.rating ? <View style={styles.rating}><Star size={13} color={colors.ink} fill={colors.ink} /><AppText style={styles.ratingText}>{store.rating.toFixed(1)}</AppText></View> : null}
            <AppText style={styles.metaText}>{[distance, store.address].filter(Boolean).join(" · ")}</AppText>
          </View>
        </View>
      </Reveal>
      <View style={styles.card}>
        <Punch style={styles.label}>Hours</Punch>
        {hours.length === 0 ? <Caption>Opening hours aren't listed for this store.</Caption> : null}
        {hours.map(([day, time]) => {
          const isToday = day === today;
          return (
            <View key={day} style={[styles.hourRow, isToday && styles.hourToday]}>
              <AppText style={[styles.day, isToday && styles.strong]}>{day}{isToday ? " · today" : ""}</AppText>
              <AppText style={[styles.time, time.toLowerCase() === "closed" && styles.closed]}>{time}</AppText>
            </View>
          );
        })}
      </View>

      {contact.length ? <View style={styles.card}>
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
      </View> : null}
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
