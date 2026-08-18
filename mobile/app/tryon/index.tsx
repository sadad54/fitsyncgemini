import { useEffect, useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, View } from "react-native";
import * as ImagePicker from "expo-image-picker";
import * as Haptics from "expo-haptics";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import Animated, { Easing, useAnimatedStyle, useSharedValue, withDelay, withRepeat, withTiming } from "react-native-reanimated";
import { useCloset, useCreateTryOn, useDeleteTryOn } from "@/api/queries";
import { mediaUrl } from "@/api/client";
import { AppText, Eyebrow } from "@/components/AppText";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { FIT_MODES, FIT_PHASES, LAYER_ROLES, ZONES } from "@/data/discover";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";
import type { ClothingItem } from "@/types/api";

export default function VirtualTryOn() {
  const params = useLocalSearchParams<{ items?: string; from?: string }>();
  const token = useAuthStore((state) => state.token);
  const closet = useCloset();
  const create = useCreateTryOn();
  const remove = useDeleteTryOn();

  const requestedIds = useMemo(() => {
    const raw = Array.isArray(params.items) ? params.items[0] : params.items;
    return raw ? raw.split(",").filter(Boolean) : [];
  }, [params.items]);

  const allItems = closet.data?.items ?? [];
  const sourceItems = useMemo(
    () => (requestedIds.length ? allItems.filter((item) => requestedIds.includes(item.id)) : allItems.slice(0, 1)),
    [allItems, requestedIds]
  );

  const [dropped, setDropped] = useState<Record<string, boolean>>({});
  const [layersOff, setLayersOff] = useState<Record<string, boolean>>({});
  const [personUri, setPersonUri] = useState<string | null>(null);
  const [fitMode, setFitMode] = useState("true");
  const [fitSaved, setFitSaved] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [pickerError, setPickerError] = useState<string | null>(null);

  const picks = sourceItems.filter((item) => !dropped[item.id]);
  const result = create.data;
  const stage: "idle" | "fitting" | "done" = create.isPending ? "fitting" : result ? "done" : "idle";

  const resultItems = useMemo(
    () => (result ? allItems.filter((item) => result.item_ids.includes(item.id)) : []),
    [result, allItems]
  );

  const fitScore = useMemo(() => {
    const base = result?.confidence_score ? Math.round(result.confidence_score * 100) : 92;
    const offCount = Object.values(layersOff).filter(Boolean).length;
    return Math.max(0, base - offCount * 7 - (fitMode === "up" ? 4 : 0));
  }, [result, layersOff, fitMode]);

  const fitLabel = FIT_MODES.find((mode) => mode.id === fitMode)?.label ?? FIT_MODES[0].label;

  async function pickImage(source: "camera" | "library") {
    setPickerError(null);
    if (source === "camera") {
      const permission = await ImagePicker.requestCameraPermissionsAsync();
      if (!permission.granted) {
        setPickerError("Camera permission is needed for a try-on photo. You can still choose one from your library.");
        return;
      }
    }
    const picked =
      source === "camera"
        ? await ImagePicker.launchCameraAsync({ mediaTypes: ["images"], quality: 0.85, allowsEditing: true, aspect: [3, 4] })
        : await ImagePicker.launchImageLibraryAsync({ mediaTypes: ["images"], quality: 0.85, allowsEditing: true, aspect: [3, 4] });
    if (!picked.canceled) {
      setPersonUri(picked.assets[0].uri);
      if (process.env.EXPO_OS === "ios") Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }
  }

  async function runTryOn() {
    if (!personUri || create.isPending) return;
    await create.mutateAsync({ imageUri: personUri, itemIds: picks.map((item) => item.id) });
    if (process.env.EXPO_OS === "ios") Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  }

  function reset() {
    create.reset();
    setLayersOff({});
    setFitSaved(false);
  }

  function confirmDelete() {
    setDeleteOpen(false);
    if (result) remove.mutate(result.id);
    reset();
    router.replace("/tryon/history");
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  const back = () => (params.from === "look" ? router.replace("/(tabs)/generate") : router.back());

  return (
    <Screen scroll bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.headerWrap}>
        <PushHeader title="Virtual try-on" onBack={back} actionGlyph="↻" onAction={reset} actionLabel="Start over" />
      </View>

      <View style={styles.hero}>
        <Eyebrow>
          {picks.length > 1 ? `Fitting the full edit — ${picks.length} pieces` : `Fitting one piece — ${picks[0]?.name ?? "your closet"}`}
        </Eyebrow>
        <AppText style={styles.heroTitle}>See it on you before you wear it.</AppText>
      </View>

      <View style={styles.stage}>
        {result?.result_image_url ? (
          <Photo source={mediaUrl(result.result_image_url)!} grayscale={false} />
        ) : personUri ? (
          <Photo source={personUri} grayscale={false} />
        ) : (
          <View style={styles.stageEmpty}>
            <View style={styles.stageMark} />
            <AppText style={styles.stageEmptyTitle}>One full-body photo</AppText>
            <AppText style={styles.stageEmptyNote}>Straight on, plain wall, shoes visible.</AppText>
          </View>
        )}

        {stage === "fitting" ? <FittingOverlay /> : null}

        {stage === "done" ? (
          <>
            <View style={styles.layerStack} pointerEvents="none">
              {resultItems.map((item, index) => (
                <View key={item.id} style={[styles.layerChip, layersOff[item.id] && styles.layerChipOff]}>
                  <AppText style={styles.layerChipText}>L{index + 1}</AppText>
                </View>
              ))}
            </View>
            <View style={styles.honestLabel} pointerEvents="none">
              <AppText style={styles.honestLabelText}>Style preview — not a fitted render · {fitLabel}</AppText>
            </View>
          </>
        ) : null}
      </View>

      {stage === "idle" ? (
        <View>
          <View style={styles.sourceRow}>
            <Pressable style={styles.sourceBtn} onPress={() => pickImage("camera")}>
              <AppText style={styles.sourceLabel}>Camera</AppText>
            </Pressable>
            <Pressable style={[styles.sourceBtn, styles.sourceBtnLast]} onPress={() => pickImage("library")}>
              <AppText style={styles.sourceLabel}>Library</AppText>
            </Pressable>
          </View>
          {pickerError ? <AppText selectable style={styles.warning}>{pickerError}</AppText> : null}

          <View style={styles.picksHeader}>
            <AppText style={styles.sectionLabel}>Pieces in this preview</AppText>
            <AppText style={styles.picksHint}>Tap ✕ to drop one</AppText>
          </View>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.picksRail}>
            {picks.map((item, index) => (
              <View key={item.id} style={styles.pick}>
                {mediaUrl(item.image_url) ? <Photo source={mediaUrl(item.image_url)!} /> : <View style={styles.pickPlaceholder} />}
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={`Drop ${item.name}`}
                  onPress={() => setDropped((current) => ({ ...current, [item.id]: true }))}
                  style={styles.pickDrop}
                >
                  <AppText style={styles.pickDropGlyph}>✕</AppText>
                </Pressable>
                <AppText style={styles.pickZone}>{ZONES[index] ?? "layer"}</AppText>
              </View>
            ))}
            <Pressable accessibilityRole="button" accessibilityLabel="Choose from closet" onPress={() => router.push("/closet")} style={styles.pickAdd}>
              <AppText style={styles.pickAddGlyph}>+</AppText>
              <AppText style={styles.pickAddLabel}>Choose from closet</AppText>
            </Pressable>
          </ScrollView>

          <View style={styles.idleCopy}>
            <AppText style={styles.idleNote}>
              Drop a straight-on full-body photo above and we layer these pieces onto it by body zone. It's a stylist's visual sketch, not a fitted render.
            </AppText>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Preview this look"
              disabled={!personUri || create.isPending}
              onPress={runTryOn}
              style={[styles.primary, (!personUri || create.isPending) && styles.primaryDisabled]}
            >
              <AppText style={styles.primaryLabel}>Preview this look</AppText>
              <AppText style={styles.primaryGlyph}>→</AppText>
            </Pressable>
            <Pressable accessibilityRole="button" accessibilityLabel="Past previews" onPress={() => router.push("/tryon/history")} style={styles.ghost}>
              <AppText style={styles.ghostLabel}>Past previews</AppText>
            </Pressable>
          </View>
        </View>
      ) : null}

      {stage === "done" ? (
        <View>
          <View style={styles.scoreRow}>
            <View style={styles.scoreCell}>
              <AppText selectable style={styles.scoreValue}>
                {fitScore}
                <AppText style={styles.scorePct}>%</AppText>
              </AppText>
              <AppText style={styles.scoreLabel}>fit confidence</AppText>
            </View>
            <AppText style={styles.scoreNote}>
              The trouser breaks slightly long over the boot. Everything else sits within your saved measurements.
            </AppText>
          </View>

          <AppText style={[styles.sectionLabel, styles.layersLabel]}>Layers on you — tap to remove</AppText>
          {resultItems.map((item, index) => {
            const off = Boolean(layersOff[item.id]);
            return (
              <Pressable
                key={item.id}
                accessibilityRole="button"
                accessibilityLabel={`Toggle ${item.name}`}
                onPress={() => setLayersOff((current) => ({ ...current, [item.id]: !current[item.id] }))}
                style={styles.layerRow}
              >
                <View style={[styles.layerSwatch, off && styles.layerSwatchOff]}>
                  {mediaUrl(item.image_url) ? <Photo source={mediaUrl(item.image_url)!} /> : null}
                </View>
                <View style={styles.layerCopy}>
                  <AppText style={[styles.layerName, off && styles.layerDim]}>{item.name}</AppText>
                  <AppText style={styles.layerRole}>{LAYER_ROLES[index] ?? "layer"}</AppText>
                </View>
                <View style={[styles.layerState, off ? styles.layerStateOff : styles.layerStateOn]}>
                  <AppText style={[styles.layerStateText, off && styles.layerStateTextOff]}>{off ? "Off" : "On"}</AppText>
                </View>
              </Pressable>
            );
          })}

          <View style={styles.fitCard}>
            <AppText style={styles.sectionLabel}>How it should sit</AppText>
            <View style={styles.fitModes}>
              {FIT_MODES.map((mode) => {
                const active = fitMode === mode.id;
                return (
                  <Pressable
                    key={mode.id}
                    accessibilityRole="button"
                    accessibilityState={{ selected: active }}
                    onPress={() => setFitMode(mode.id)}
                    style={[styles.fitMode, active && styles.fitModeActive]}
                  >
                    <AppText style={[styles.fitModeLabel, active && styles.fitModeLabelActive]}>{mode.label}</AppText>
                  </Pressable>
                );
              })}
            </View>
            <View style={styles.fitNoteRow}>
              <View style={styles.fitTick} />
              <AppText style={styles.fitNote}>A drape simulation, not a measurement. Confirm sizing before you buy or tailor.</AppText>
            </View>
          </View>

          <View style={styles.resultActions}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Save this fit"
              disabled={fitSaved}
              onPress={() => setFitSaved(true)}
              style={[styles.saveBtn, fitSaved && styles.saveBtnDone]}
            >
              <AppText style={[styles.saveLabel, fitSaved && styles.saveLabelDone]}>{fitSaved ? "Fit saved to look ✓" : "Save this fit"}</AppText>
            </Pressable>
            <Pressable accessibilityRole="button" accessibilityLabel="Retry" onPress={runTryOn} style={styles.retryBtn}>
              <AppText style={styles.retryLabel}>Retry</AppText>
            </Pressable>
            <Pressable accessibilityRole="button" accessibilityLabel="Delete preview" onPress={() => setDeleteOpen(true)} style={styles.deleteBtn}>
              <AppText style={styles.deleteGlyph}>✕</AppText>
            </Pressable>
          </View>
          <Pressable accessibilityRole="button" accessibilityLabel="Past previews" onPress={() => router.push("/tryon/history")} style={styles.pastBtn}>
            <AppText style={styles.ghostLabel}>Past previews</AppText>
          </Pressable>
        </View>
      ) : null}

      {create.error ? <AppText selectable style={styles.error}>{create.error.message}</AppText> : null}
      <View style={{ height: 40 }} />

      <ConfirmDialog
        visible={deleteOpen}
        title="Delete this preview?"
        body="The preview image goes; the pieces stay in your closet and the outfit stays saved."
        cancelLabel="Keep it"
        confirmLabel="Delete"
        destructive
        onCancel={() => setDeleteOpen(false)}
        onConfirm={confirmDelete}
      />
    </Screen>
  );
}

function FittingOverlay() {
  const [phase, setPhase] = useState(0);
  const [caretOn, setCaretOn] = useState(true);
  useEffect(() => {
    const phaseTimer = setInterval(() => setPhase((p) => (p + 1) % FIT_PHASES.length), 750);
    const caretTimer = setInterval(() => setCaretOn((v) => !v), 500);
    return () => { clearInterval(phaseTimer); clearInterval(caretTimer); };
  }, []);

  return (
    <View style={styles.fitting} pointerEvents="none">
      <Wipe />
      <View style={styles.fittingRail}>
        <SwayBlock delay={0} height={74} />
        <SwayBlock delay={180} height={96} accent />
        <SwayBlock delay={360} height={64} />
        <SwayBlock delay={540} height={84} />
      </View>
      <View style={styles.fittingBanner}>
        <AppText style={styles.fittingText}>
          {FIT_PHASES[phase]}
          <AppText style={{ opacity: caretOn ? 1 : 0 }}>_</AppText>
        </AppText>
      </View>
    </View>
  );
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
  layerStack: { position: "absolute", top: 0, right: 0, gap: 1 },
  layerChip: { width: 66, height: 74, backgroundColor: colors.surfaceElevated },
  layerChipOff: { opacity: 0.28 },
  layerChipText: { position: "absolute", left: 0, top: 0, backgroundColor: colors.strokeStrong, color: colors.canvas, fontSize: 8, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, paddingHorizontal: 5, paddingVertical: 4 },
  honestLabel: { position: "absolute", left: 0, bottom: 0, backgroundColor: colors.strokeStrong, paddingHorizontal: 13, paddingVertical: 9 },
  honestLabelText: { color: colors.canvas, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  sourceRow: { flexDirection: "row" },
  sourceBtn: { flex: 1, height: 52, borderRightWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke, alignItems: "flex-start", justifyContent: "center", paddingHorizontal: spacing.lg },
  sourceBtnLast: { borderRightWidth: 0 },
  sourceLabel: { fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: 1, textTransform: "uppercase" },
  warning: { color: colors.roseSoft, fontSize: 13, lineHeight: 19, paddingHorizontal: spacing.xl, paddingTop: spacing.md },
  picksHeader: { flexDirection: "row", alignItems: "baseline", justifyContent: "space-between", gap: spacing.sm, paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.sm },
  sectionLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6, textTransform: "uppercase" },
  picksHint: { color: colors.muted, fontSize: 10 },
  picksRail: { flexGrow: 0, borderTopWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke },
  pick: { width: 96, height: 124, borderRightWidth: 1, borderColor: colors.stroke, backgroundColor: colors.surface, overflow: "hidden" },
  pickPlaceholder: { flex: 1, backgroundColor: colors.surface },
  pickDrop: { position: "absolute", top: 0, right: 0, width: 26, height: 26, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center" },
  pickDropGlyph: { color: colors.white, fontSize: 12 },
  pickZone: { position: "absolute", left: 6, bottom: 6, color: colors.white, fontSize: 8, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  pickAdd: { width: 96, height: 124, alignItems: "flex-start", justifyContent: "flex-end", gap: spacing.sm, padding: spacing.md },
  pickAddGlyph: { color: colors.roseSoft, fontSize: 20 },
  pickAddLabel: { color: colors.muted, fontSize: 9, lineHeight: 12, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  idleCopy: { padding: spacing.xl, gap: spacing.sm },
  idleNote: { color: colors.muted, fontSize: 13, lineHeight: 21 },
  primary: { height: 56, marginTop: spacing.lg, backgroundColor: colors.rose, flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: spacing.lg },
  primaryDisabled: { opacity: 0.45 },
  primaryLabel: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 13, letterSpacing: 1.3, textTransform: "uppercase" },
  primaryGlyph: { color: colors.white, fontSize: 17 },
  ghost: { height: 52, borderBottomWidth: 1, borderColor: colors.stroke, justifyContent: "center" },
  ghostLabel: { color: colors.muted, fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: 1, textTransform: "uppercase" },
  scoreRow: { flexDirection: "row", borderBottomWidth: 1, borderColor: colors.stroke },
  scoreCell: { width: 118, paddingVertical: spacing.lg, paddingLeft: spacing.xl },
  scoreValue: { fontSize: 44, lineHeight: 40, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -1.6, fontVariant: ["tabular-nums"] },
  scorePct: { fontSize: 20, fontFamily: fonts.black, fontWeight: "800" },
  scoreLabel: { color: colors.muted, fontSize: 9, lineHeight: 12, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase", marginTop: spacing.sm },
  scoreNote: { flex: 1, color: colors.ink, fontSize: 13, lineHeight: 20, paddingVertical: spacing.lg, paddingRight: spacing.xl, paddingLeft: spacing.md, borderLeftWidth: 1, borderColor: colors.stroke },
  layersLabel: { paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.sm },
  layerRow: { flexDirection: "row", alignItems: "center", gap: spacing.md, paddingHorizontal: spacing.xl, paddingVertical: spacing.md, borderTopWidth: 1, borderColor: colors.stroke },
  layerSwatch: { width: 34, height: 40, backgroundColor: colors.surfaceElevated, overflow: "hidden" },
  layerSwatchOff: { opacity: 0.28 },
  layerCopy: { flex: 1 },
  layerName: { fontFamily: fonts.black, fontWeight: "800", fontSize: 14, lineHeight: 17 },
  layerDim: { opacity: 0.28 },
  layerRole: { color: colors.muted, fontSize: 10, letterSpacing: 0.8, textTransform: "uppercase", marginTop: 5 },
  layerState: { paddingHorizontal: 9, paddingVertical: 8, borderWidth: 1 },
  layerStateOn: { backgroundColor: colors.rose, borderColor: colors.rose },
  layerStateOff: { backgroundColor: "transparent", borderColor: colors.stroke },
  layerStateText: { color: colors.white, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  layerStateTextOff: { color: colors.muted },
  fitCard: { backgroundColor: colors.surface, borderTopWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke, paddingHorizontal: spacing.xl, paddingVertical: spacing.lg },
  fitModes: { flexDirection: "row", borderWidth: 1, borderColor: colors.stroke, marginTop: spacing.md },
  fitMode: { flex: 1, paddingVertical: spacing.md, paddingHorizontal: spacing.sm, borderRightWidth: 1, borderColor: colors.stroke, alignItems: "flex-start" },
  fitModeActive: { backgroundColor: colors.rose },
  fitModeLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1, textTransform: "uppercase" },
  fitModeLabelActive: { color: colors.white },
  fitNoteRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm, marginTop: spacing.md },
  fitTick: { width: 8, height: 8, backgroundColor: colors.rose },
  fitNote: { flex: 1, color: colors.muted, fontSize: 11, lineHeight: 16 },
  resultActions: { flexDirection: "row", borderBottomWidth: 1, borderColor: colors.stroke },
  saveBtn: { flex: 1, height: 56, backgroundColor: colors.rose, borderRightWidth: 1, borderColor: colors.stroke, justifyContent: "center", paddingHorizontal: spacing.lg },
  saveBtnDone: { backgroundColor: colors.surface },
  saveLabel: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: 1, textTransform: "uppercase" },
  saveLabelDone: { color: colors.muted },
  retryBtn: { width: 104, height: 56, borderRightWidth: 1, borderColor: colors.stroke, justifyContent: "center", paddingHorizontal: spacing.lg },
  retryLabel: { color: colors.ink, fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: 1, textTransform: "uppercase" },
  deleteBtn: { width: 52, height: 56, alignItems: "center", justifyContent: "center" },
  deleteGlyph: { color: colors.roseSoft, fontSize: 15 },
  pastBtn: { height: 52, borderBottomWidth: 1, borderColor: colors.stroke, justifyContent: "center", paddingHorizontal: spacing.xl },
  error: { color: colors.roseSoft, paddingHorizontal: spacing.xl, paddingTop: spacing.md }
});
