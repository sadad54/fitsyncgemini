import { useEffect, useMemo, useRef, useState } from "react";
import { ScrollView, Share, StyleSheet, View } from "react-native";
import * as ImagePicker from "expo-image-picker";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import Animated, { FadeIn, FadeInDown, LinearTransition } from "react-native-reanimated";
import { Camera, Check, ImagePlus, Images, Plus, Share2, Trash2, UserRound, X } from "@/icons";
import { useCloset, useCreateTryOn, useDeleteTryOn, useTryOn } from "@/api/queries";
import { mediaUrl } from "@/api/client";
import { AppText, Caption, Em, Heading, Punch, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { FittingRoom } from "@/components/FittingRoom";
import { IconButton } from "@/components/IconButton";
import { Photo } from "@/components/Photo";
import { PressableScale, Reveal } from "@/components/motion";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { isValidTryOnSelection } from "@/lib/tryon";
import { useAuthStore } from "@/store/auth";
import { useFitPhoto } from "@/store/fitPhoto";
import { colors, fonts, radius, spacing } from "@/theme";

export default function TryOn() {
  const params = useLocalSearchParams<{ items?: string; job?: string; auto?: string }>();
  const token = useAuthStore((state) => state.token);
  const fitPhoto = useFitPhoto();
  const closet = useCloset();
  const create = useCreateTryOn();
  const remove = useDeleteTryOn();
  const [jobId, setJobId] = useState<string | undefined>(params.job);
  const job = useTryOn(jobId);
  const [personUri, setPersonUri] = useState<string | null>(null);
  const [dropped, setDropped] = useState<Record<string, boolean>>({});
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [pickerError, setPickerError] = useState<string | null>(null);
  const autoStarted = useRef(false);

  useEffect(() => { fitPhoto.load(); }, []);
  useEffect(() => { setJobId(params.job); }, [params.job]);
  const photo = personUri ?? fitPhoto.uri;

  const allItems = closet.data?.items ?? [];
  const requestedIds = useMemo(() => params.items?.split(",").filter(Boolean) ?? [], [params.items]);
  const picks = allItems.filter((item) => requestedIds.includes(item.id) && !dropped[item.id]);
  const validPicks = isValidTryOnSelection(picks);
  const result = job.data ?? (create.data?.id === jobId ? create.data : undefined);
  const working = create.isPending || Boolean(jobId && !result && !job.error) || result?.status === "queued" || result?.status === "processing";
  const completed = result?.status === "completed";
  const resultUri = completed ? mediaUrl(result?.result_image_url) : null;
  const shownPerson = jobId ? mediaUrl(result?.person_image_url) ?? photo : photo;

  async function start(uri = photo) {
    if (!uri || !validPicks || working) return;
    try {
      const accepted = await create.mutateAsync({ imageUri: uri, itemIds: picks.map((item) => item.id) });
      setJobId(accepted.id);
      router.setParams({ job: accepted.id });
    } catch { /* rendered below */ }
  }

  // One-tap path from Today / Style me: start as soon as everything is ready.
  useEffect(() => {
    if (params.auto !== "1" || autoStarted.current || jobId || !fitPhoto.loaded || !fitPhoto.uri || !closet.isSuccess || !validPicks) return;
    autoStarted.current = true;
    start(fitPhoto.uri);
  }, [params.auto, jobId, fitPhoto.loaded, fitPhoto.uri, closet.isSuccess, validPicks]);

  async function pick(source: "camera" | "library") {
    setPickerError(null);
    try {
      if (source === "camera" && !(await ImagePicker.requestCameraPermissionsAsync()).granted) {
        setPickerError("Camera access is off. You can choose a photo from your library instead.");
        return;
      }
      const options: ImagePicker.ImagePickerOptions = { mediaTypes: ["images"], quality: 0.85 };
      const picked = source === "camera" ? await ImagePicker.launchCameraAsync(options) : await ImagePicker.launchImageLibraryAsync(options);
      if (picked.canceled) return;
      const uri = picked.assets[0].uri;
      // The first photo becomes the default fit photo, so next time is one tap.
      if (!fitPhoto.uri) setPersonUri(await fitPhoto.save(uri)); else setPersonUri(uri);
    } catch { setPickerError("Couldn't open the photo picker. Please try again."); }
  }

  function again() {
    create.reset();
    setJobId(undefined);
    autoStarted.current = true;
    router.setParams({ job: undefined, auto: undefined });
  }

  async function confirmDelete() {
    setDeleteOpen(false);
    if (!result) return;
    try {
      await remove.mutateAsync(result.id);
      router.replace("/looks");
    } catch { /* rendered below */ }
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  const footer = completed ? (
    <View style={styles.footerRow}>
      <IconButton icon={Share2} label="Share" tone="stage" size={56} onPress={() => resultUri && Share.share({ url: resultUri, message: "Styled with Flairwise" })} />
      <View style={styles.flex}><Button title="Done" icon={Check} variant="stage" onPress={() => router.navigate("/looks")} /></View>
    </View>
  ) : working ? (
    <Button title="Keep browsing — we'll keep fitting" variant="stage" onPress={() => router.navigate("/today")} />
  ) : (
    <Button title="Try it on" icon={ImagePlus} variant="accent" disabled={!photo || !validPicks} onPress={() => start()} />
  );

  return (
    <Screen tone="stage" footer={footer} contentStyle={styles.content}>
      <PushHeader tone="stage" title={completed ? "On you" : working ? "Fitting room" : "Try on"} onBack={() => router.back()}
        actionIcon={result && !working ? Trash2 : undefined} actionLabel="Delete this try-on" onAction={() => setDeleteOpen(true)} />

      <Reveal>
        <FittingRoom
          personUri={shownPerson}
          resultUri={resultUri}
          working={working}
          status={result?.status}
          placeholder={<PhotoPrompt onCamera={() => pick("camera")} onLibrary={() => pick("library")} />}
        />
      </Reveal>

      {result?.status === "failed" ? (
        <Animated.View entering={FadeInDown} style={styles.failed}>
          <Heading>{result.error_message?.includes("usage limit") ? "Try-on is busy" : "That one didn't fit"}</Heading>
          <AppText style={styles.failedNote}>
            {result.error_message ?? "The try-on couldn't finish."}
            {result.error_message?.includes("usage limit") ? "" : " A straight-on, full-body photo in good light works best."}
          </AppText>
          <Button title="Try again" compact stretch={false} onPress={again} />
        </Animated.View>
      ) : null}

      {!jobId ? (
        <Animated.View entering={FadeIn} style={styles.section}>
          {photo ? (
            <View style={styles.photoRow}>
              <View style={styles.flex}>
                <Heading style={styles.onStage}>{personUri && personUri !== fitPhoto.uri ? "Using this photo" : "Your fit photo"}</Heading>
                <Caption style={styles.onStageMuted}>Full body, facing the camera, plain background.</Caption>
              </View>
              <IconButton icon={Camera} label="Take a new photo" tone="stage" onPress={() => pick("camera")} />
              <IconButton icon={Images} label="Choose from library" tone="stage" onPress={() => pick("library")} />
            </View>
          ) : null}

          <View style={styles.garmentsHead}>
            <Punch style={styles.onStage}>Trying on</Punch>
            <Caption style={styles.onStageMuted}>{validPicks ? `${picks.length} ${picks.length === 1 ? "piece" : "pieces"}` : "Pick a dress, or a top and bottom"}</Caption>
          </View>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.garments}>
            {picks.map((item) => (
              <Animated.View key={item.id} layout={LinearTransition} entering={FadeIn} style={styles.garment}>
                {mediaUrl(item.image_url) ? <Photo source={mediaUrl(item.image_url)!} /> : null}
                <View style={styles.garmentDrop}>
                  <IconButton icon={X} label={`Remove ${item.name}`} tone="glass" size={30} onPress={() => setDropped((d) => ({ ...d, [item.id]: true }))} />
                </View>
              </Animated.View>
            ))}
            <PressableScale accessibilityRole="button" accessibilityLabel="Choose pieces from your closet" onPress={() => router.navigate("/closet")} style={[styles.garment, styles.garmentAdd]}>
              <Plus size={22} color={colors.accent} />
              <AppText style={styles.garmentAddText}>Closet</AppText>
            </PressableScale>
          </ScrollView>
          <Caption style={styles.onStageMuted}>Your photo is sent securely to generate the image and kept for up to 7 days. Results are a visual preview, not a size guide.</Caption>
        </Animated.View>
      ) : null}

      {completed ? (
        <Reveal delay={900}>
          <View style={styles.doneRow}>
            <View style={styles.flex}>
              <Punch style={styles.doneKicker}>Saved to Looks</Punch>
              <Title style={styles.doneTitle}>Looking <Em style={styles.doneEm}>good.</Em></Title>
            </View>
            <Button title="Try another" variant="stage" compact stretch={false} onPress={again} />
          </View>
        </Reveal>
      ) : null}

      {job.error ? (
        <View style={styles.failed}>
          <AppText style={styles.failedNote}>{job.error.message}</AppText>
          <Button title="Reconnect" compact stretch={false} variant="primary" onPress={() => job.refetch()} />
        </View>
      ) : null}
      {[pickerError, closet.error?.message, create.error?.message, remove.error?.message].filter(Boolean).map((message, i) =>
        <AppText key={i} selectable style={styles.error}>{message}</AppText>)}

      <ConfirmDialog visible={deleteOpen} title="Delete this try-on?" body="The photos for this try-on are removed. Your clothes stay in your closet."
        cancelLabel="Keep it" confirmLabel="Delete" destructive onCancel={() => setDeleteOpen(false)} onConfirm={confirmDelete} />
    </Screen>
  );
}

function PhotoPrompt({ onCamera, onLibrary }: { onCamera: () => void; onLibrary: () => void }) {
  return (
    <View style={styles.prompt}>
      <View style={styles.promptIcon}><UserRound size={30} color={colors.ink} strokeWidth={1.6} /></View>
      <Title style={styles.promptTitle}>Add your fit photo</Title>
      <AppText style={styles.promptNote}>One full-body photo, saved on this phone and reused for every try-on.</AppText>
      <View style={styles.promptActions}>
        <Button title="Camera" icon={Camera} compact stretch={false} variant="accent" onPress={onCamera} />
        <Button title="Library" icon={Images} compact stretch={false} variant="stage" onPress={onLibrary} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  content: { gap: spacing.xl },
  section: { gap: spacing.md },
  photoRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  garmentsHead: { flexDirection: "row", alignItems: "baseline", justifyContent: "space-between", marginTop: spacing.sm },
  garments: { gap: spacing.sm },
  garment: { width: 96, height: 120, borderRadius: radius.md, overflow: "hidden", backgroundColor: colors.surface },
  onStage: { color: colors.onStage },
  onStageMuted: { color: colors.onStageMuted },
  doneKicker: { color: colors.accent, fontSize: 10 },
  doneTitle: { color: colors.onStage, fontSize: 36, lineHeight: 38, marginTop: 4 },
  doneEm: { color: colors.accent },
  garmentDrop: { position: "absolute", top: 4, right: 4 },
  garmentAdd: { alignItems: "center", justifyContent: "center", gap: 4, borderWidth: 1, borderStyle: "dashed", borderColor: "rgba(212,255,58,0.5)", backgroundColor: "transparent" },
  garmentAddText: { fontSize: 13, color: colors.onStage, fontFamily: fonts.medium },
  failed: { gap: spacing.sm, backgroundColor: colors.dangerWash, borderRadius: radius.lg, padding: spacing.lg, alignItems: "flex-start" },
  failedNote: { color: colors.inkSoft, fontSize: 15, lineHeight: 22 },
  doneRow: { flexDirection: "row", alignItems: "center", gap: spacing.md },
  footerRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  error: { color: "#FF8A73", fontSize: 14 },
  prompt: { flex: 1, alignItems: "center", justifyContent: "center", padding: spacing.xl, gap: spacing.md },
  promptIcon: { width: 68, height: 68, borderRadius: 34, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center" },
  promptTitle: { textAlign: "center", color: colors.onStage, fontSize: 32, lineHeight: 36 },
  promptNote: { textAlign: "center", color: colors.onStageMuted, fontSize: 15, lineHeight: 22, maxWidth: 260 },
  promptActions: { flexDirection: "row", gap: spacing.sm, marginTop: spacing.sm }
});
