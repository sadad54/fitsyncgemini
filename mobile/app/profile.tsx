import { useEffect, useState } from "react";
import { Pressable, StyleSheet, TextInput, View } from "react-native";
import { router } from "expo-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/api/client";
import { keys, useClosetStats, useProfile, useSavedOutfits, useUpdateProfile } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { Reveal } from "@/components/motion";
import { Screen } from "@/components/Screen";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

const styleAnchors = ["minimal", "streetwear", "classic", "athleisure", "soft glam", "workwear", "tailored", "weekend"];
const colorAnchors = [
  { name: "ink", value: "#242128" }, { name: "cream", value: "#E8D9C8" }, { name: "denim", value: "#496B83" }, { name: "berry", value: "#9B3F61" },
  { name: "olive", value: "#6E7552" }, { name: "cobalt", value: "#3C56B8" }, { name: "gold", value: "#C79043" }, { name: "lilac", value: "#9D85B6" }
];

export default function Profile() {
  const profile = useProfile();
  const stats = useClosetStats();
  const saved = useSavedOutfits();
  const update = useUpdateProfile();
  const signOut = useAuthStore((state) => state.signOut);
  const queryClient = useQueryClient();
  const health = useQuery({ queryKey: keys.health, queryFn: api.health, refetchInterval: 30000 });
  const [name, setName] = useState("");
  const [stylesSelected, setStylesSelected] = useState<string[]>([]);
  const [colorsSelected, setColorsSelected] = useState<string[]>([]);
  const [signOutOpen, setSignOutOpen] = useState(false);

  useEffect(() => {
    if (!profile.data) return;
    setName(profile.data.display_name ?? "");
    setStylesSelected(profile.data.style_preferences);
    setColorsSelected(profile.data.favorite_colors);
  }, [profile.data]);

  function toggle(value: string, current: string[], setter: (next: string[]) => void) {
    setter(current.includes(value) ? current.filter((item) => item !== value) : [...current, value]);
  }

  function savePreferences() {
    update.mutate({ display_name: name.trim(), style_preferences: stylesSelected, favorite_colors: colorsSelected });
  }

  async function doSignOut() {
    setSignOutOpen(false);
    await signOut();
    queryClient.clear();
    router.replace("/(auth)/sign-in");
  }

  const firstLetter = (profile.data?.display_name || "F").slice(0, 1).toUpperCase();
  const online = ["ok", "healthy"].includes(health.data?.status ?? "");
  return (
    <Screen>
      <Reveal>
        <View style={styles.header}>
          <View style={styles.avatar}><AppText style={styles.avatarText}>{firstLetter}</AppText></View>
          <View style={styles.identity}>
            <Eyebrow>Your style profile</Eyebrow>
            <Title style={styles.title}>{profile.data?.display_name || "FitSync member"}</Title>
            <AppText selectable style={styles.memberId}>{profile.data?.user_id || "Syncing account…"}</AppText>
          </View>
        </View>
      </Reveal>

      <Reveal delay={60}>
        <View style={styles.metrics}>
          <ProfileMetric value={stats.data?.total_items ?? 0} label="pieces" />
          <ProfileMetric value={saved.data?.total ?? 0} label="looks" />
          <ProfileMetric value={profile.data?.style_preferences.length ?? 0} label="anchors" last />
        </View>
      </Reveal>

      <Reveal delay={110}>
        <View style={styles.card}>
          <View>
            <Eyebrow>Personalization</Eyebrow>
            <AppText style={styles.cardTitle}>Tune your stylist</AppText>
          </View>
          <AppText style={styles.label}>Display name</AppText>
          <TextInput accessibilityLabel="Display name" value={name} onChangeText={setName} style={styles.input} />
          <AppText style={styles.label}>Style anchors</AppText>
          <View style={styles.chips}>{styleAnchors.map((value) => <Chip key={value} active={stylesSelected.includes(value)} onPress={() => toggle(value, stylesSelected, setStylesSelected)}>{value}</Chip>)}</View>
          <AppText style={styles.label}>Go-to colors</AppText>
          <View style={styles.palette}>
            {colorAnchors.map((color) => {
              const active = colorsSelected.includes(color.name);
              return (
                <Pressable key={color.name} accessibilityRole="button" accessibilityLabel={color.name} accessibilityState={{ selected: active }} onPress={() => toggle(color.name, colorsSelected, setColorsSelected)} style={styles.colorWrap}>
                  <View style={[styles.colorSwatch, { backgroundColor: color.value }, active && styles.colorSwatchActive]} />
                </Pressable>
              );
            })}
          </View>
          <Button title={update.isPending ? "Saving preferences…" : update.isSuccess ? "Preferences saved" : "Save preferences"} icon="checkmark" disabled={!name.trim() || update.isPending} onPress={savePreferences} />
          {update.error ? <AppText selectable style={styles.error}>{update.error.message}</AppText> : null}
        </View>
      </Reveal>

      <Reveal delay={170}>
        <View style={styles.statusCard}>
          <View style={styles.statusHeader}>
            <View>
              <Eyebrow>Connection</Eyebrow>
              <AppText style={styles.cardTitle}>System status</AppText>
            </View>
            <View style={[styles.statusDot, online ? styles.online : styles.offline]} />
          </View>
          <StatusRow label="API service" value={health.data?.service ?? "FitSync API"} />
          <StatusRow label="Backend" value={health.isLoading ? "Checking…" : online ? "Online" : "Unavailable"} />
          <StatusRow label="Session" value="Secure device session" />
          {health.isError ? <Button title="Retry connection" icon="refresh" variant="secondary" compact onPress={() => health.refetch()} /> : null}
        </View>
      </Reveal>

      <Button title="Sign out" variant="secondary" onPress={() => setSignOutOpen(true)} />
      <AppText style={styles.version}>FitSync mobile 0.3 · Atelier system</AppText>

      <ConfirmDialog
        visible={signOutOpen}
        title="Sign out of this style space?"
        body="Your closet stays on the backend, and this device session will be removed."
        cancelLabel="Cancel"
        confirmLabel="Sign out"
        destructive
        onCancel={() => setSignOutOpen(false)}
        onConfirm={doSignOut}
      />
    </Screen>
  );
}

function ProfileMetric({ value, label, last }: { value: number; label: string; last?: boolean }) {
  return (
    <View style={[styles.metric, last && styles.metricLast]}>
      <AppText selectable style={styles.metricValue}>{value}</AppText>
      <AppText style={styles.metricLabel}>{label}</AppText>
    </View>
  );
}

function StatusRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.statusRow}>
      <AppText style={styles.statusLabel}>{label}</AppText>
      <AppText selectable style={styles.statusValue}>{value}</AppText>
    </View>
  );
}

const styles = StyleSheet.create({
  header: { flexDirection: "row", alignItems: "center", gap: spacing.lg, borderBottomWidth: 2, borderColor: colors.strokeStrong, paddingBottom: spacing.lg },
  avatar: { width: 66, height: 66, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center" },
  avatarText: { color: colors.white, fontSize: 26, fontFamily: fonts.black, fontWeight: "800" },
  identity: { flex: 1, gap: spacing.xs },
  title: { fontSize: 30, lineHeight: 28 },
  memberId: { color: colors.muted, fontSize: 10, lineHeight: 14 },
  metrics: { flexDirection: "row", borderBottomWidth: 1, borderColor: colors.stroke },
  metric: { flex: 1, paddingVertical: spacing.md, paddingHorizontal: spacing.sm, borderRightWidth: 1, borderColor: colors.stroke },
  metricLast: { borderRightWidth: 0 },
  metricValue: { fontSize: 32, lineHeight: 32, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.9, fontVariant: ["tabular-nums"] },
  metricLabel: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase", marginTop: spacing.xs },
  card: { backgroundColor: colors.surface, paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, gap: spacing.md, marginHorizontal: -spacing.xl },
  cardTitle: { fontSize: 24, lineHeight: 24, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.5, marginTop: spacing.sm, textTransform: "uppercase" },
  label: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase", marginBottom: -spacing.xs },
  input: { height: 48, borderWidth: 1, borderColor: colors.stroke, borderLeftWidth: 2, borderLeftColor: colors.strokeStrong, backgroundColor: colors.canvas, color: colors.ink, paddingHorizontal: spacing.md, fontSize: 15, fontFamily: fonts.medium },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  palette: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  colorWrap: { width: "11%" },
  colorSwatch: { width: "100%", aspectRatio: 1, borderWidth: 1, borderColor: colors.stroke },
  colorSwatchActive: { borderWidth: 2, borderColor: colors.rose },
  error: { color: colors.roseSoft },
  statusCard: { gap: spacing.md, borderTopWidth: 1, borderColor: colors.stroke, paddingTop: spacing.lg },
  statusHeader: { flexDirection: "row", alignItems: "flex-start", justifyContent: "space-between" },
  statusDot: { width: 10, height: 10, marginTop: spacing.xs },
  online: { backgroundColor: colors.rose },
  offline: { backgroundColor: colors.muted },
  statusRow: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: spacing.lg, borderTopWidth: 1, borderTopColor: colors.stroke, paddingTop: spacing.md },
  statusLabel: { color: colors.muted, fontSize: 12 },
  statusValue: { color: colors.ink, fontSize: 12, fontFamily: fonts.bold, fontWeight: "700", textAlign: "right" },
  version: { color: colors.muted, fontSize: 10, lineHeight: 14, textAlign: "center" }
});
