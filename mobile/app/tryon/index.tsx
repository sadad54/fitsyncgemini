import { useEffect, useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, View } from "react-native";
import * as ImagePicker from "expo-image-picker";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import Animated, { Easing, useAnimatedStyle, useSharedValue, withDelay, withRepeat, withTiming } from "react-native-reanimated";
import { useCloset, useCreateTryOn, useDeleteTryOn, useTryOn } from "@/api/queries";
import { mediaUrl } from "@/api/client";
import { AppText, Eyebrow } from "@/components/AppText";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

export default function VirtualTryOn() {
  const params = useLocalSearchParams<{ items?: string; from?: string; job?: string }>();
  const token = useAuthStore((state) => state.token);
  const closet = useCloset();
  const create = useCreateTryOn();
  const remove = useDeleteTryOn();
  const [jobId, setJobId] = useState<string | undefined>(params.job);
  const job = useTryOn(jobId);
  const [personUri, setPersonUri] = useState<string | null>(null);
  const [dropped, setDropped] = useState<Record<string, boolean>>({});
  const [showOriginal, setShowOriginal] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [pickerError, setPickerError] = useState<string | null>(null);
  const allItems = closet.data?.items ?? [];
  const requestedIds = useMemo(() => params.items?.split(",").filter(Boolean) ?? [], [params.items]);
  const picks = (requestedIds.length ? allItems.filter((item) => requestedIds.includes(item.id)) : allItems.slice(0, 1))
    .filter((item) => !dropped[item.id]);
  const validPicks = picks.length >= 1 && picks.length <= 2 &&
    picks.every((item) => ["tops", "outerwear", "bottoms", "dresses"].includes(item.category)) &&
    (picks.length === 1 || (picks.filter((item) => item.category === "bottoms").length === 1 &&
      picks.filter((item) => ["tops", "outerwear"].includes(item.category)).length === 1));
  const result = job.data ?? (create.data?.id === jobId ? create.data : undefined);
  const working = create.isPending || Boolean(jobId && !result && !job.error) ||
    result?.status === "queued" || result?.status === "processing";
  const image = showOriginal ? result?.person_image_url : result?.result_image_url;
  const displayedImage = mediaUrl(image) ?? personUri ?? mediaUrl(result?.person_image_url);
  useEffect(() => { setJobId(params.job); }, [params.job]);

  async function pickImage(source: "camera" | "library") {
    setPickerError(null);
    try {
      if (source === "camera" && !(await ImagePicker.requestCameraPermissionsAsync()).granted) {
        setPickerError("Camera access is needed. You can also choose a photo from your library.");
        return;
      }
      const options: ImagePicker.ImagePickerOptions = { mediaTypes: ["images"], quality: 0.85, allowsEditing: false };
      const picked = source === "camera" ? await ImagePicker.launchCameraAsync(options) : await ImagePicker.launchImageLibraryAsync(options);
      if (!picked.canceled) setPersonUri(picked.assets[0].uri);
    } catch { setPickerError("Could not open the photo picker. Please try again."); }
  }

  async function runTryOn() {
    if (!personUri || !validPicks || working) return;
    try {
      const accepted = await create.mutateAsync({ imageUri: personUri, itemIds: picks.map((item) => item.id) });
      setJobId(accepted.id);
      setShowOriginal(false);
    } catch { /* Mutation errors are rendered below. */ }
  }

  function reset() {
    if (create.isPending) return;
    create.reset();
    setJobId(undefined);
    setShowOriginal(false);
    router.setParams({ job: undefined });
  }

  async function confirmDelete() {
    setDeleteOpen(false);
    if (!result) return;
    try {
      await remove.mutateAsync(result.id);
      reset();
      router.replace("/tryon/history");
    } catch { /* Retain the result until deletion succeeds. */ }
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;
  return (
    <Screen scroll bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.headerWrap}>
        <PushHeader title="Virtual try-on" onBack={() => router.back()} actionGlyph="↻" onAction={reset} actionLabel="Start over" />
      </View>
      <View style={styles.hero}>
        <Eyebrow>Prototype · your clothes, on you</Eyebrow>
        <AppText style={styles.heroTitle}>See it on you before you wear it.</AppText>
      </View>
      <View style={styles.stage}>
        {displayedImage ? <Photo source={displayedImage} grayscale={false} /> : (
          <View style={styles.stageEmpty}>
            <View style={styles.stageMark} />
            <AppText style={styles.stageEmptyTitle}>One full-body photo</AppText>
            <AppText style={styles.stageEmptyNote}>Straight on, plain wall, feet and garment hem visible.</AppText>
          </View>
        )}
        {working ? <FittingOverlay status={result?.status} /> : null}
        {result?.status === "completed" ? <View style={styles.honestLabel}>
          <AppText style={styles.honestLabelText}>{showOriginal ? "Original photo" : result.render_kind === "diffusion" ? "AI try-on · sizing may differ" : "Legacy style preview"}</AppText>
        </View> : null}
      </View>
      {!jobId && !working ? <>
        <View style={styles.sourceRow}>
          <Pressable accessibilityRole="button" style={styles.sourceBtn} onPress={() => pickImage("camera")}><AppText>Camera</AppText></Pressable>
          <Pressable accessibilityRole="button" style={styles.sourceBtn} onPress={() => pickImage("library")}><AppText>Library</AppText></Pressable>
        </View>
        <View style={styles.picksHeader}><AppText style={styles.sectionLabel}>Garments to try</AppText></View>
        <ScrollView horizontal style={styles.picksRail}>
          {picks.map((item) => <View key={item.id} style={styles.pick}>
            {mediaUrl(item.image_url) ? <Photo source={mediaUrl(item.image_url)!} /> : null}
            <Pressable accessibilityRole="button" accessibilityLabel={`Remove ${item.name}`} style={styles.pickDrop}
              onPress={() => setDropped((current) => ({ ...current, [item.id]: true }))}><AppText>✕</AppText></Pressable>
            <AppText style={styles.pickZone}>{item.category}</AppText>
          </View>)}
          <Pressable accessibilityRole="button" onPress={() => router.push("/closet")} style={styles.pickAdd}><AppText>+ Choose from closet</AppText></Pressable>
        </ScrollView>
        <View style={styles.idleCopy}>
          <AppText style={styles.idleNote}>Choose one dress, one top or bottom, or a top and bottom together. Shoes and accessories are not supported yet.</AppText>
          {!validPicks ? <AppText style={styles.warning}>Adjust the selection above before generating.</AppText> : null}
          <AppText style={styles.idleNote}>Your photo goes to our prototype GPU service and is kept for up to seven days. Only use photos you have permission to upload. AI may alter details and does not measure fit.</AppText>
          <Pressable accessibilityRole="button" disabled={!personUri || !validPicks || working} onPress={runTryOn}
            style={[styles.primary, (!personUri || !validPicks || working) && styles.primaryDisabled]}>
            <AppText style={styles.primaryLabel}>Generate try-on →</AppText>
          </Pressable>
        </View>
      </> : null}
      {working ? <View style={styles.idleCopy}>
        <AppText accessibilityLiveRegion="polite" style={styles.idleNote}>The GPU can take a few minutes to wake up. You can leave this screen and reopen the job from history.</AppText>
      </View> : null}
      {result?.status === "completed" ? <View style={styles.idleCopy}>
        <AppText style={styles.idleNote}>Saved automatically to history. New prototype photos expire after seven days. This image is a visual approximation, not a sizing recommendation.</AppText>
        <Pressable accessibilityRole="button" onPress={() => setShowOriginal((value) => !value)} style={styles.primary}>
          <AppText style={styles.primaryLabel}>{showOriginal ? "Show try-on" : "Compare original"}</AppText>
        </Pressable>
      </View> : null}
      {result?.status === "failed" ? <AppText style={styles.error}>{result.error_message ?? "Generation failed. Please try again."}</AppText> : null}
      {result && !working ? <View style={styles.idleCopy}>
        <Pressable accessibilityRole="button" onPress={reset} style={styles.ghost}><AppText>Start another try-on</AppText></Pressable>
        <Pressable accessibilityRole="button" onPress={() => setDeleteOpen(true)} style={styles.ghost}><AppText>Delete this job and photos</AppText></Pressable>
      </View> : null}
      {job.error ? <View style={styles.idleCopy}>
        <AppText style={styles.error}>{job.error.message}</AppText>
        <Pressable accessibilityRole="button" onPress={() => job.refetch()} style={styles.ghost}><AppText>Reconnect to job</AppText></Pressable>
      </View> : null}
      {[pickerError, closet.error?.message, create.error?.message, remove.error?.message].filter(Boolean).map((message, i) =>
        <AppText key={i} style={styles.error}>{message}</AppText>)}
      <Pressable accessibilityRole="button" onPress={() => router.push("/tryon/history")} style={styles.pastBtn}><AppText>Try-on history →</AppText></Pressable>
      <View style={{ height: 40 }} />
      <ConfirmDialog visible={deleteOpen} title="Delete this try-on?" body={result?.render_kind === "legacy_preview" ? "The legacy preview is removed from history. Your wardrobe stays in your closet." : "Your prototype photos will be removed. Your wardrobe items stay in your closet."}
        cancelLabel="Keep it" confirmLabel="Delete" destructive onCancel={() => setDeleteOpen(false)} onConfirm={confirmDelete} />
    </Screen>
  );
}

function FittingOverlay({ status }: { status?: string }) {
  return <View style={styles.fitting} pointerEvents="none">
    <Wipe />
    <View style={styles.fittingRail}><SwayBlock delay={0} height={74} /><SwayBlock delay={180} height={96} accent /><SwayBlock delay={360} height={64} /></View>
    <View style={styles.fittingBanner}><AppText style={styles.fittingText}>
      {status === "queued" ? "Queued for the prototype GPU" : status === "processing" ? "Generating — first run can take longer" : "Connecting to your try-on"}
    </AppText></View>
  </View>;
}

function SwayBlock({ delay, height, accent }: { delay: number; height: number; accent?: boolean }) {
  const t = useSharedValue(0);
  useEffect(() => {
    t.value = withDelay(delay, withRepeat(withTiming(1, { duration: 1500, easing: Easing.inOut(Easing.ease) }), -1, true));
  }, []);
  const style = useAnimatedStyle(() => ({
    transform: [{ translateY: -14 * t.value }, { rotate: `${-2 + 4 * t.value}deg` }]
  }));
  return <Animated.View style={[styles.swayBlock, { height }, accent && styles.swayBlockAccent, style]} />;
}

function Wipe() {
  const x = useSharedValue(-1);
  useEffect(() => {
    x.value = withRepeat(withTiming(2, { duration: 1400, easing: Easing.linear }), -1, false);
  }, []);
  const style = useAnimatedStyle(() => ({ transform: [{ translateX: x.value * 260 }] }));
  return (
    <View style={styles.wipeMask} pointerEvents="none">
      <Animated.View style={[styles.wipeBar, style]} />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  headerWrap: { paddingHorizontal: spacing.xl, paddingTop: spacing.sm },
  hero: { paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.lg, gap: spacing.md },
  heroTitle: { fontSize: 36, lineHeight: 34, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -1.4, textTransform: "uppercase" },
  stage: { height: 430, backgroundColor: colors.surface, borderTopWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke, overflow: "hidden" },
  stageEmpty: { flex: 1, justifyContent: "flex-end", padding: spacing.xl, gap: spacing.sm },
  stageMark: { width: 44, height: 44, borderWidth: 2, borderColor: colors.strokeStrong, marginBottom: spacing.sm },
  stageEmptyTitle: { fontSize: 20, lineHeight: 21, fontFamily: fonts.black, fontWeight: "800", textTransform: "uppercase" },
  stageEmptyNote: { color: colors.muted, fontSize: 12, lineHeight: 18 },
  fitting: { ...StyleSheet.absoluteFillObject, backgroundColor: colors.surface, overflow: "hidden" },
  wipeMask: { ...StyleSheet.absoluteFillObject, overflow: "hidden" },
  wipeBar: { position: "absolute", top: 0, bottom: 0, width: 130, backgroundColor: "rgba(236, 48, 19, 0.14)" },
  fittingRail: { position: "absolute", left: spacing.xl, right: spacing.xl, bottom: 74, flexDirection: "row", gap: spacing.sm, alignItems: "flex-end", height: 120 },
  swayBlock: { width: 48, backgroundColor: colors.surfaceElevated, borderWidth: 1, borderColor: colors.stroke },
  swayBlockAccent: { backgroundColor: colors.rose, borderColor: colors.rose },
  fittingBanner: { position: "absolute", left: 0, right: 0, bottom: 0, backgroundColor: colors.rose, paddingHorizontal: spacing.lg, paddingVertical: spacing.md },
  fittingText: { color: colors.white, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  honestLabel: { position: "absolute", left: 0, bottom: 0, backgroundColor: colors.strokeStrong, paddingHorizontal: 13, paddingVertical: 9 },
  honestLabelText: { color: colors.canvas, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  sourceRow: { flexDirection: "row" },
  sourceBtn: { flex: 1, height: 52, borderRightWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke, alignItems: "flex-start", justifyContent: "center", paddingHorizontal: spacing.lg },
  warning: { color: colors.roseSoft, fontSize: 13, lineHeight: 19, paddingHorizontal: spacing.xl, paddingTop: spacing.md },
  picksHeader: { flexDirection: "row", alignItems: "baseline", justifyContent: "space-between", gap: spacing.sm, paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.sm },
  sectionLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6, textTransform: "uppercase" },
  picksRail: { flexGrow: 0, borderTopWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke },
  pick: { width: 96, height: 124, borderRightWidth: 1, borderColor: colors.stroke, backgroundColor: colors.surface, overflow: "hidden" },
  pickDrop: { position: "absolute", top: 0, right: 0, width: 26, height: 26, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center" },
  pickZone: { position: "absolute", left: 6, bottom: 6, color: colors.white, fontSize: 8, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  pickAdd: { width: 96, height: 124, alignItems: "flex-start", justifyContent: "flex-end", gap: spacing.sm, padding: spacing.md },
  idleCopy: { padding: spacing.xl, gap: spacing.sm },
  idleNote: { color: colors.muted, fontSize: 13, lineHeight: 21 },
  primary: { height: 56, marginTop: spacing.lg, backgroundColor: colors.rose, flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: spacing.lg },
  primaryDisabled: { opacity: 0.45 },
  primaryLabel: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 13, letterSpacing: 1.3, textTransform: "uppercase" },
  ghost: { height: 52, borderBottomWidth: 1, borderColor: colors.stroke, justifyContent: "center" },
  pastBtn: { height: 52, borderBottomWidth: 1, borderColor: colors.stroke, justifyContent: "center", paddingHorizontal: spacing.xl },
  error: { color: colors.roseSoft, paddingHorizontal: spacing.xl, paddingTop: spacing.md }
});

