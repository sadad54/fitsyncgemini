import { useEffect, useState } from "react";
import { Alert, Pressable, StyleSheet, TextInput, View } from "react-native";
import { router } from "expo-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Ionicons } from "@expo/vector-icons";
import { api } from "@/api/client";
import { keys, useClosetStats, useProfile, useSavedOutfits, useUpdateProfile } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { Reveal } from "@/components/motion";
import { Screen } from "@/components/Screen";
import { useAuthStore } from "@/store/auth";
import { colors, radius, shadows, spacing } from "@/theme";

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

  function confirmSignOut() {
    Alert.alert("Sign out of this style space?", "Your closet stays on the backend, and this device session will be removed.", [
      { text: "Cancel", style: "cancel" },
      { text: "Sign out", style: "destructive", onPress: async () => { await signOut(); queryClient.clear(); router.replace("/(auth)/sign-in"); } }
    ]);
  }

  const firstLetter = (profile.data?.display_name || "F").slice(0, 1).toUpperCase();
  return (
    <Screen>
      <Reveal>
        <View style={styles.header}>
          <View style={styles.avatar}><AppText style={styles.avatarText}>{firstLetter}</AppText></View>
          <View style={styles.identity}>
            <Eyebrow>Your style profile</Eyebrow>
            <Title>{profile.data?.display_name || "FitSync member"}</Title>
            <AppText selectable style={styles.memberId}>{profile.data?.user_id || "Syncing account…"}</AppText>
          </View>
        </View>
      </Reveal>

      <Reveal delay={60}>
        <View style={styles.metrics}>
          <ProfileMetric icon="shirt-outline" value={stats.data?.total_items ?? 0} label="pieces" />
          <ProfileMetric icon="bookmark-outline" value={saved.data?.total ?? 0} label="looks" />
          <ProfileMetric icon="sparkles-outline" value={profile.data?.style_preferences.length ?? 0} label="anchors" />
        </View>
      </Reveal>

      <Reveal delay={110}>
        <View style={styles.card}>
          <View style={styles.sectionTitleRow}><View><Eyebrow>Personalization</Eyebrow><AppText style={styles.cardTitle}>Tune your stylist</AppText></View><Ionicons name="options-outline" size={22} color={colors.roseSoft} /></View>
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
                  <View style={[styles.colorRing, active && styles.colorRingActive]}><View style={[styles.colorDot, { backgroundColor: color.value }]} /></View>
                  <AppText style={[styles.colorName, active && styles.colorNameActive]}>{color.name}</AppText>
                </Pressable>
              );
            })}
          </View>
          <Button title={update.isPending ? "Saving preferences…" : update.isSuccess ? "Preferences saved" : "Save preferences"} icon={update.isSuccess ? "checkmark-circle" : "checkmark"} disabled={!name.trim() || update.isPending} onPress={savePreferences} />
          {update.error ? <AppText selectable style={styles.error}>{update.error.message}</AppText> : null}
        </View>
      </Reveal>

      <Reveal delay={170}>
        <View style={styles.card}>
          <View style={styles.sectionTitleRow}><View><Eyebrow>Connection</Eyebrow><AppText style={styles.cardTitle}>System status</AppText></View><View style={[styles.statusDot, health.data ? styles.online : styles.offline]} /></View>
          <StatusRow label="API service" value={health.data?.service ?? "FitSync API"} />
          <StatusRow label="Backend" value={health.isLoading ? "Checking…" : ["ok", "healthy"].includes(health.data?.status ?? "") ? "Online" : "Unavailable"} />
          <StatusRow label="Session" value="Secure device session" />
          {health.isError ? <Button title="Retry connection" icon="refresh" variant="secondary" compact onPress={() => health.refetch()} /> : null}
        </View>
      </Reveal>

      <Button title="Sign out" icon="log-out-outline" variant="ghost" onPress={confirmSignOut} />
      <AppText style={styles.version}>FitSync mobile 0.2 · Editorial motion system</AppText>
    </Screen>
  );
}

function ProfileMetric({ icon, value, label }: { icon: keyof typeof Ionicons.glyphMap; value: number; label: string }) {
  return <View style={styles.metric}><Ionicons name={icon} size={18} color={colors.roseSoft} /><AppText selectable style={styles.metricValue}>{value}</AppText><AppText style={styles.metricLabel}>{label}</AppText></View>;
}

function StatusRow({ label, value }: { label: string; value: string }) {
  return <View style={styles.statusRow}><AppText style={styles.statusLabel}>{label}</AppText><AppText selectable style={styles.statusValue}>{value}</AppText></View>;
}

const styles = StyleSheet.create({
  header: { flexDirection: "row", alignItems: "center", gap: spacing.lg },
  avatar: { width: 76, height: 76, borderRadius: 38, backgroundColor: colors.roseWash, borderWidth: 1, borderColor: colors.rose, alignItems: "center", justifyContent: "center", boxShadow: shadows.card },
  avatarText: { color: colors.roseSoft, fontSize: 28, lineHeight: 32, fontWeight: "900" },
  identity: { flex: 1, gap: spacing.xs },
  memberId: { color: colors.faint, fontSize: 12, lineHeight: 16 },
  metrics: { flexDirection: "row", gap: spacing.sm },
  metric: { flex: 1, minHeight: 104, borderRadius: radius.lg, borderCurve: "continuous", backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke, padding: spacing.md, alignItems: "center", justifyContent: "center", gap: spacing.xxs },
  metricValue: { fontSize: 22, lineHeight: 26, fontWeight: "900", fontVariant: ["tabular-nums"] },
  metricLabel: { color: colors.muted, fontSize: 11, lineHeight: 15 },
  card: { backgroundColor: colors.surface, borderRadius: radius.xl, borderCurve: "continuous", borderWidth: 1, borderColor: colors.stroke, padding: spacing.xl, gap: spacing.lg, boxShadow: shadows.card },
  sectionTitleRow: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: spacing.lg },
  cardTitle: { fontSize: 21, lineHeight: 26, fontWeight: "900", marginTop: spacing.xs },
  label: { color: colors.inkSoft, fontSize: 14, fontWeight: "800", marginBottom: -spacing.sm },
  input: { minHeight: 54, borderRadius: radius.lg, borderCurve: "continuous", borderWidth: 1, borderColor: colors.strokeStrong, backgroundColor: colors.surfaceElevated, color: colors.ink, paddingHorizontal: spacing.lg, fontSize: 16 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.sm },
  palette: { flexDirection: "row", flexWrap: "wrap", gap: spacing.md },
  colorWrap: { alignItems: "center", gap: spacing.xs, width: 50 },
  colorRing: { width: 46, height: 46, borderRadius: 23, borderWidth: 2, borderColor: "transparent", alignItems: "center", justifyContent: "center" },
  colorRingActive: { borderColor: colors.roseSoft },
  colorDot: { width: 34, height: 34, borderRadius: 17, borderWidth: 1, borderColor: colors.strokeStrong },
  colorName: { color: colors.faint, fontSize: 10, lineHeight: 13, textTransform: "capitalize" },
  colorNameActive: { color: colors.inkSoft },
  statusDot: { width: 12, height: 12, borderRadius: 6 },
  online: { backgroundColor: colors.sage },
  offline: { backgroundColor: colors.danger },
  statusRow: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: spacing.lg, borderTopWidth: 1, borderTopColor: colors.stroke, paddingTop: spacing.md },
  statusLabel: { color: colors.muted, fontSize: 14 },
  statusValue: { color: colors.inkSoft, fontSize: 14, fontWeight: "700", textAlign: "right" },
  error: { color: colors.danger },
  version: { color: colors.faint, fontSize: 11, lineHeight: 16, textAlign: "center" }
});
