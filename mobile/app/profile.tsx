import { useEffect, useState } from "react";
import { Pressable, StyleSheet, TextInput, View } from "react-native";
import { router } from "expo-router";
import * as ImagePicker from "expo-image-picker";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Camera, Check, Images, LogOut, Trash2, UserRound } from "@/icons";
import { api } from "@/api/client";
import { keys, useClosetStats, useProfile, useSavedOutfits, useTryOns, useUpdateProfile } from "@/api/queries";
import { AppText, Caption, Heading, Punch, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { IconButton } from "@/components/IconButton";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { PressableScale, Reveal } from "@/components/motion";
import { Screen } from "@/components/Screen";
import { useAuthStore } from "@/store/auth";
import { useFitPhoto } from "@/store/fitPhoto";
import { colors, fonts, radius, spacing } from "@/theme";

const styleAnchors = ["minimal", "streetwear", "classic", "athleisure", "soft glam", "workwear", "tailored", "weekend"];
const colorAnchors = [
  { name: "ink", value: "#242128" }, { name: "cream", value: "#E8D9C8" }, { name: "denim", value: "#496B83" }, { name: "berry", value: "#9B3F61" },
  { name: "olive", value: "#6E7552" }, { name: "cobalt", value: "#3C56B8" }, { name: "gold", value: "#C79043" }, { name: "lilac", value: "#9D85B6" }
];

export default function Profile() {
  const profile = useProfile();
  const stats = useClosetStats();
  const saved = useSavedOutfits();
  const tryons = useTryOns();
  const update = useUpdateProfile();
  const signOut = useAuthStore((state) => state.signOut);
  const fitPhoto = useFitPhoto();
  const queryClient = useQueryClient();
  const health = useQuery({ queryKey: keys.health, queryFn: api.health, refetchInterval: 30000, enabled: __DEV__ });
  const [name, setName] = useState("");
  const [stylesSelected, setStylesSelected] = useState<string[]>([]);
  const [colorsSelected, setColorsSelected] = useState<string[]>([]);
  const [signOutOpen, setSignOutOpen] = useState(false);
  const [removePhotoOpen, setRemovePhotoOpen] = useState(false);

  useEffect(() => { fitPhoto.load(); }, []);
  useEffect(() => {
    if (!profile.data) return;
    setName(profile.data.display_name ?? "");
    setStylesSelected(profile.data.style_preferences);
    setColorsSelected(profile.data.favorite_colors);
  }, [profile.data]);

  const toggle = (value: string, current: string[], setter: (next: string[]) => void) =>
    setter(current.includes(value) ? current.filter((item) => item !== value) : [...current, value]);
  const dirty = profile.data && (name.trim() !== (profile.data.display_name ?? "") ||
    stylesSelected.join() !== profile.data.style_preferences.join() || colorsSelected.join() !== profile.data.favorite_colors.join());

  async function pickFitPhoto(source: "camera" | "library") {
    if (source === "camera" && !(await ImagePicker.requestCameraPermissionsAsync()).granted) return;
    const options: ImagePicker.ImagePickerOptions = { mediaTypes: ["images"], quality: 0.85 };
    const picked = source === "camera" ? await ImagePicker.launchCameraAsync(options) : await ImagePicker.launchImageLibraryAsync(options);
    if (!picked.canceled) await fitPhoto.save(picked.assets[0].uri);
  }

  async function doSignOut() {
    setSignOutOpen(false);
    await fitPhoto.clear();
    await signOut();
    queryClient.clear();
    router.replace("/(auth)/sign-in");
  }

  const displayName = profile.data?.display_name || "Flairwise member";
  const online = ["ok", "healthy"].includes(health.data?.status ?? "");

  return (
    <Screen>
      <PushHeader title="Profile" onBack={() => router.back()} />
      <Reveal>
        <View style={styles.identity}>
          <View style={styles.avatar}><AppText style={styles.avatarText}>{displayName.slice(0, 1).toUpperCase()}</AppText></View>
          <Title style={styles.name}>{displayName}</Title>
          <Punch style={styles.member}>Flairwise member</Punch>
          <View style={styles.stats}>
            <Stat value={stats.data?.total_items ?? 0} label="Pieces" />
            <View style={styles.statRule} />
            <Stat value={saved.data?.total ?? 0} label="Looks" />
            <View style={styles.statRule} />
            <Stat value={tryons.data?.total ?? 0} label="Try-ons" />
          </View>
        </View>
      </Reveal>

      <Reveal delay={70}>
        <View style={styles.card}>
          <View style={styles.cardHead}>
            <View style={styles.flex}>
              <Heading>Fit photo</Heading>
              <Caption>Stored only on this phone. Used for one-tap try-ons.</Caption>
            </View>
          </View>
          <View style={styles.fitRow}>
            <View style={styles.fitThumb}>
              {fitPhoto.uri ? <Photo source={fitPhoto.uri} /> : <UserRound size={28} color={colors.muted} strokeWidth={1.5} />}
            </View>
            <View style={styles.fitActions}>
              <Button title={fitPhoto.uri ? "Retake" : "Take photo"} icon={Camera} compact onPress={() => pickFitPhoto("camera")} />
              <Button title="From library" icon={Images} compact variant="secondary" onPress={() => pickFitPhoto("library")} />
              {fitPhoto.uri ? <Button title="Remove" icon={Trash2} compact variant="ghost" onPress={() => setRemovePhotoOpen(true)} /> : null}
            </View>
          </View>
        </View>
      </Reveal>

      <Reveal delay={130}>
        <View style={styles.card}>
          <Heading>Your style</Heading>
          <View style={styles.field}>
            <Caption>Name</Caption>
            <TextInput accessibilityLabel="Display name" value={name} onChangeText={setName} style={styles.input} placeholder="Your name" placeholderTextColor={colors.faint} />
          </View>
          <View style={styles.field}>
            <Caption>Style anchors</Caption>
            <View style={styles.chips}>{styleAnchors.map((value) => <Chip key={value} active={stylesSelected.includes(value)} onPress={() => toggle(value, stylesSelected, setStylesSelected)}>{value}</Chip>)}</View>
          </View>
          <View style={styles.field}>
            <Caption>Colours you reach for</Caption>
            <View style={styles.palette}>
              {colorAnchors.map((color) => {
                const active = colorsSelected.includes(color.name);
                return (
                  <PressableScale key={color.name} accessibilityRole="checkbox" accessibilityLabel={color.name} accessibilityState={{ checked: active }} scaleTo={0.88}
                    onPress={() => toggle(color.name, colorsSelected, setColorsSelected)} style={[styles.swatchRing, active && styles.swatchRingOn]}>
                    <View style={[styles.swatch, { backgroundColor: color.value }]}>{active ? <Check size={16} color={color.name === "cream" ? colors.ink : colors.white} strokeWidth={3} /> : null}</View>
                  </PressableScale>
                );
              })}
            </View>
          </View>
          <Button title={update.isSuccess && !dirty ? "Saved" : "Save changes"} icon={update.isSuccess && !dirty ? Check : undefined}
            loading={update.isPending} disabled={!name.trim() || !dirty}
            onPress={() => update.mutate({ display_name: name.trim(), style_preferences: stylesSelected, favorite_colors: colorsSelected })} />
          {update.error ? <AppText selectable style={styles.error}>{update.error.message}</AppText> : null}
        </View>
      </Reveal>

      {__DEV__ ? (
        <View style={styles.card}>
          <View style={styles.cardHead}>
            <Heading style={styles.flex}>Developer · backend</Heading>
            <View style={[styles.dot, { backgroundColor: online ? colors.success : colors.danger }]} />
          </View>
          <Caption>{health.isLoading ? "Checking…" : online ? `${health.data?.service ?? "API"} online` : "Unavailable"}</Caption>
          {health.isError ? <Button title="Retry" compact variant="secondary" onPress={() => health.refetch()} /> : null}
        </View>
      ) : null}

      <Pressable accessibilityRole="button" onPress={() => setSignOutOpen(true)} style={styles.signOut}>
        <LogOut size={18} color={colors.danger} />
        <AppText style={styles.signOutText}>Sign out</AppText>
      </Pressable>

      <ConfirmDialog visible={signOutOpen} title="Sign out?" body="Your closet and looks stay in your account. Your fit photo is removed from this phone."
        confirmLabel="Sign out" destructive onCancel={() => setSignOutOpen(false)} onConfirm={doSignOut} />
      <ConfirmDialog visible={removePhotoOpen} title="Remove your fit photo?" body="It's deleted from this phone. You'll be asked for a photo on your next try-on."
        confirmLabel="Remove" destructive onCancel={() => setRemovePhotoOpen(false)} onConfirm={() => { setRemovePhotoOpen(false); fitPhoto.clear(); }} />
    </Screen>
  );
}

function Stat({ value, label }: { value: number; label: string }) {
  return (
    <View style={styles.stat}>
      <AppText style={styles.statValue}>{value}</AppText>
      <Punch style={styles.statLabel}>{label}</Punch>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  identity: { alignItems: "center", gap: spacing.sm, backgroundColor: colors.stage, borderRadius: radius.xl, padding: spacing.xl, paddingBottom: spacing.md },
  avatar: { width: 88, height: 88, borderRadius: 44, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center", borderWidth: 3, borderColor: colors.stageRaised, boxShadow: "0 0 0 1.5px #D4FF3A" },
  avatarText: { color: colors.ink, fontFamily: fonts.serif, fontSize: 44, lineHeight: 50 },
  name: { textAlign: "center", color: colors.onStage, fontSize: 32, lineHeight: 36 },
  member: { color: colors.onStageMuted, fontSize: 10 },
  stats: { flexDirection: "row", alignItems: "center", borderTopWidth: 1, borderColor: colors.stageLine, paddingTop: spacing.md, marginTop: spacing.md, alignSelf: "stretch" },
  stat: { flex: 1, alignItems: "center", gap: 2 },
  statValue: { fontFamily: fonts.serif, fontSize: 34, lineHeight: 38, color: colors.onStage },
  statLabel: { fontSize: 9, color: colors.onStageMuted },
  statRule: { width: 1, height: 32, backgroundColor: colors.stageLine },
  card: { backgroundColor: colors.surface, borderRadius: radius.xl, padding: spacing.lg, gap: spacing.lg, borderWidth: 1, borderColor: colors.stroke },
  cardHead: { flexDirection: "row", alignItems: "center", gap: spacing.md },
  fitRow: { flexDirection: "row", gap: spacing.lg },
  fitThumb: { width: 110, aspectRatio: 3 / 4, borderRadius: radius.lg, overflow: "hidden", backgroundColor: colors.canvas, alignItems: "center", justifyContent: "center" },
  fitActions: { flex: 1, gap: spacing.sm, justifyContent: "center" },
  field: { gap: spacing.sm },
  input: { height: 50, borderRadius: radius.md, backgroundColor: colors.canvas, paddingHorizontal: spacing.lg, fontSize: 16, color: colors.ink, fontFamily: fonts.regular },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  palette: { flexDirection: "row", flexWrap: "wrap", gap: spacing.sm },
  swatchRing: { width: 48, height: 48, borderRadius: 24, padding: 3, borderWidth: 2, borderColor: "transparent" },
  swatchRingOn: { borderColor: colors.ink },
  swatch: { flex: 1, borderRadius: 20, alignItems: "center", justifyContent: "center" },
  dot: { width: 10, height: 10, borderRadius: 5 },
  error: { color: colors.danger, fontSize: 14 },
  signOut: { flexDirection: "row", alignItems: "center", justifyContent: "center", gap: spacing.sm, minHeight: 52 },
  signOutText: { color: colors.danger, fontSize: 16, fontFamily: fonts.semibold, fontWeight: "600" }
});
