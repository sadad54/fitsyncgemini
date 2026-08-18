import { useRef, useState } from "react";
import { Pressable, StyleSheet, TextInput, View } from "react-native";
import * as ImagePicker from "expo-image-picker";
import * as Haptics from "expo-haptics";
import { Redirect, router } from "expo-router";
import { useAddClosetItem, useDetectClosetItemCategory } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { Photo } from "@/components/Photo";
import { Screen } from "@/components/Screen";
import { colors, fonts, spacing } from "@/theme";
import type { ClothingCategory } from "@/types/api";
import { useAuthStore } from "@/store/auth";

const categories: ClothingCategory[] = ["tops", "bottoms", "dresses", "outerwear", "footwear", "accessories", "activewear"];

export default function AddItem() {
  const [name, setName] = useState("");
  const [brand, setBrand] = useState("");
  const [category, setCategory] = useState<ClothingCategory | undefined>();
  const categoryTouched = useRef(false);
  const [imageUri, setImageUri] = useState<string | null>(null);
  const [pickerError, setPickerError] = useState<string | null>(null);
  const [detectedVision, setDetectedVision] = useState<unknown>(null);
  const addItem = useAddClosetItem();
  const detectCategory = useDetectClosetItemCategory();
  const token = useAuthStore((state) => state.token);

  async function pickImage(source: "camera" | "library") {
    setPickerError(null);
    if (source === "camera") {
      const permission = await ImagePicker.requestCameraPermissionsAsync();
      if (!permission.granted) {
        setPickerError("Camera permission is needed to photograph a garment. You can still choose one from your library.");
        return;
      }
    }
    const result = source === "camera"
      ? await ImagePicker.launchCameraAsync({ mediaTypes: ["images"], quality: 0.82, allowsEditing: true, aspect: [4, 5] })
      : await ImagePicker.launchImageLibraryAsync({ mediaTypes: ["images"], quality: 0.82, allowsEditing: true, aspect: [4, 5] });
    if (!result.canceled) {
      const uri = result.assets[0].uri;
      setImageUri(uri);
      categoryTouched.current = false;
      setDetectedVision(null);
      if (process.env.EXPO_OS === "ios") Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      detectCategory.mutate(uri, {
        onSuccess: (result) => {
          setDetectedVision(result);
          if (!categoryTouched.current && result.category && result.category !== "unknown") setCategory(result.category);
        }
      });
    }
  }

  async function submit() {
    if (!name.trim() || !imageUri) return;
    await addItem.mutateAsync({ name, brand, category, imageUri, detectedVision });
    if (process.env.EXPO_OS === "ios") await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    router.replace("/(tabs)/closet");
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen bottomInset={false}>
      <View style={styles.topRow}>
        <Pressable accessibilityRole="button" accessibilityLabel="Close" onPress={() => router.back()} style={styles.iconButton}><AppText style={styles.iconGlyph}>✕</AppText></Pressable>
        <Eyebrow>New wardrobe piece</Eyebrow>
        <View style={styles.iconSpacer} />
      </View>

      <View style={styles.header}>
        <Title style={styles.title}>Shoot it like a product.</Title>
        <AppText style={styles.note}>Use an uncluttered background and natural light. Better input gives the tagger—and your outfit results—a cleaner signal.</AppText>
      </View>

      <View style={styles.photoShell}>
        {imageUri ? (
          <Photo source={imageUri} />
        ) : (
          <View style={styles.emptyPhoto}>
            <View style={styles.emptyMark} />
            <AppText style={styles.emptyTitle}>One garment, front-facing</AppText>
            <AppText style={styles.emptyNote}>FitSync supports JPEG, PNG, and WebP images.</AppText>
          </View>
        )}
        {imageUri ? <Pressable accessibilityRole="button" accessibilityLabel="Remove selected photo" onPress={() => setImageUri(null)} style={styles.remove}><AppText style={styles.removeGlyph}>✕</AppText></Pressable> : null}
        {detectCategory.isPending ? (
          <View style={styles.detecting}><AppText style={styles.detectingText}>AI is detecting the category…</AppText></View>
        ) : null}
      </View>

      <View style={styles.sourceRow}>
        <Pressable style={styles.sourceBtn} onPress={() => pickImage("camera")}><AppText style={styles.sourceLabel}>Camera</AppText></Pressable>
        <Pressable style={styles.sourceBtn} onPress={() => pickImage("library")}><AppText style={styles.sourceLabel}>Library</AppText></Pressable>
      </View>
      {pickerError ? <AppText selectable style={styles.warning}>{pickerError}</AppText> : null}

      <View style={styles.form}>
        <FieldLabel label="Item name" required />
        <TextInput accessibilityLabel="Item name" value={name} onChangeText={setName} placeholder="Blue linen overshirt" placeholderTextColor={colors.faint} style={styles.input} />
        <FieldLabel label="Brand" />
        <TextInput accessibilityLabel="Brand, optional" value={brand} onChangeText={setBrand} placeholder="Optional" placeholderTextColor={colors.faint} style={styles.input} />
        <FieldLabel label="Category" note={detectCategory.isPending ? "Detecting from photo…" : "Auto-filled — editable"} />
        <View style={styles.chips}>{categories.map((item) => <Chip key={item} active={category === item} onPress={() => { categoryTouched.current = true; setCategory(category === item ? undefined : item); }}>{item}</Chip>)}</View>
      </View>

      <Button title={addItem.isPending ? "Analyzing and adding…" : "Add to my closet"} icon="arrow" disabled={!name.trim() || !imageUri || addItem.isPending} onPress={submit} />
      {addItem.error ? <AppText selectable style={styles.error}>{addItem.error.message}</AppText> : null}
    </Screen>
  );
}

function FieldLabel({ label, required, note }: { label: string; required?: boolean; note?: string }) {
  return <View style={styles.labelRow}><AppText style={styles.label}>{label}{required ? " *" : ""}</AppText>{note ? <AppText style={styles.labelNote}>{note}</AppText> : null}</View>;
}

const styles = StyleSheet.create({
  topRow: { minHeight: 40, flexDirection: "row", alignItems: "center", justifyContent: "space-between", borderBottomWidth: 2, borderColor: colors.strokeStrong, paddingBottom: spacing.md },
  iconButton: { width: 40, height: 40, alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.stroke },
  iconGlyph: { color: colors.ink, fontSize: 15 },
  iconSpacer: { width: 40 },
  header: { gap: spacing.sm },
  title: { fontSize: 34 },
  note: { color: colors.muted, fontSize: 13, lineHeight: 20 },
  photoShell: { width: "100%", height: 330, backgroundColor: colors.surface, borderTopWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke, overflow: "hidden" },
  preview: { width: "100%", height: "100%" },
  emptyPhoto: { flex: 1, justifyContent: "flex-end", padding: spacing.xl, gap: spacing.sm },
  emptyMark: { width: 44, height: 44, borderWidth: 2, borderColor: colors.strokeStrong, marginBottom: spacing.sm },
  emptyTitle: { fontSize: 20, lineHeight: 21, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.3, textTransform: "uppercase" },
  emptyNote: { color: colors.muted, fontSize: 12, lineHeight: 18 },
  remove: { position: "absolute", top: spacing.md, right: spacing.md, width: 38, height: 38, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center" },
  removeGlyph: { color: colors.white, fontSize: 15 },
  detecting: { position: "absolute", left: 0, right: 0, bottom: 0, backgroundColor: colors.rose, paddingHorizontal: spacing.lg, paddingVertical: spacing.sm },
  detectingText: { color: colors.white, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  sourceRow: { flexDirection: "row" },
  sourceBtn: { flex: 1, height: 52, borderRightWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke, alignItems: "flex-start", justifyContent: "center", paddingHorizontal: spacing.lg },
  sourceLabel: { fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: 1, textTransform: "uppercase" },
  warning: { color: colors.roseSoft, fontSize: 13, lineHeight: 19 },
  form: { gap: spacing.md },
  labelRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", gap: spacing.md, marginBottom: -spacing.xs },
  label: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  labelNote: { flex: 1, color: colors.muted, fontSize: 10, textAlign: "right" },
  input: { height: 48, borderWidth: 1, borderColor: colors.stroke, borderLeftWidth: 2, borderLeftColor: colors.strokeStrong, backgroundColor: colors.surface, color: colors.ink, paddingHorizontal: spacing.md, fontSize: 15, fontFamily: fonts.medium },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  error: { color: colors.roseSoft }
});
