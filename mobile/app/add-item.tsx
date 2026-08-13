import { useState } from "react";
import { Pressable, StyleSheet, TextInput, View } from "react-native";
import { Image } from "expo-image";
import * as ImagePicker from "expo-image-picker";
import * as Haptics from "expo-haptics";
import { Redirect, router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useAddClosetItem } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { Screen } from "@/components/Screen";
import { colors, radius, shadows, spacing } from "@/theme";
import type { ClothingCategory } from "@/types/api";
import { useAuthStore } from "@/store/auth";

const categories: ClothingCategory[] = ["tops", "bottoms", "dresses", "outerwear", "footwear", "accessories", "activewear"];

export default function AddItem() {
  const [name, setName] = useState("");
  const [brand, setBrand] = useState("");
  const [category, setCategory] = useState<ClothingCategory | undefined>();
  const [imageUri, setImageUri] = useState<string | null>(null);
  const [pickerError, setPickerError] = useState<string | null>(null);
  const addItem = useAddClosetItem();
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
      setImageUri(result.assets[0].uri);
      if (process.env.EXPO_OS === "ios") Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }
  }

  async function submit() {
    if (!name.trim() || !imageUri) return;
    await addItem.mutateAsync({ name, brand, category, imageUri });
    if (process.env.EXPO_OS === "ios") await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    router.replace("/(tabs)/closet");
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen bottomInset={false}>
      <View style={styles.topRow}>
        <Pressable accessibilityRole="button" accessibilityLabel="Close" onPress={() => router.back()} style={styles.iconButton}><Ionicons name="close" size={23} color={colors.ink} /></Pressable>
        <Eyebrow>New wardrobe piece</Eyebrow>
        <View style={styles.iconSpacer} />
      </View>

      <View style={styles.header}>
        <Title>Photograph it like a product.</Title>
        <AppText style={styles.note}>Use an uncluttered background and natural light. Better input gives the tagger—and your outfit results—a cleaner signal.</AppText>
      </View>

      <View style={styles.photoShell}>
        {imageUri ? (
          <Image accessibilityLabel="Selected garment photo" source={imageUri} style={styles.preview} contentFit="cover" transition={180} />
        ) : (
          <View style={styles.emptyPhoto}>
            <View style={styles.cameraIcon}><Ionicons name="camera-outline" size={30} color={colors.roseSoft} /></View>
            <AppText style={styles.emptyTitle}>One garment, front-facing</AppText>
            <AppText style={styles.emptyNote}>FitSync supports JPEG, PNG, and WebP images.</AppText>
          </View>
        )}
        {imageUri ? <Pressable accessibilityRole="button" accessibilityLabel="Remove selected photo" onPress={() => setImageUri(null)} style={styles.remove}><Ionicons name="close" size={18} color={colors.white} /></Pressable> : null}
      </View>

      <View style={styles.sourceRow}>
        <Button title="Camera" icon="camera-outline" variant="secondary" compact onPress={() => pickImage("camera")} />
        <Button title="Library" icon="images-outline" variant="secondary" compact onPress={() => pickImage("library")} />
      </View>
      {pickerError ? <AppText selectable style={styles.warning}>{pickerError}</AppText> : null}

      <View style={styles.form}>
        <FieldLabel label="Item name" required />
        <TextInput accessibilityLabel="Item name" value={name} onChangeText={setName} placeholder="Blue linen overshirt" placeholderTextColor={colors.faint} style={styles.input} />
        <FieldLabel label="Brand" />
        <TextInput accessibilityLabel="Brand, optional" value={brand} onChangeText={setBrand} placeholder="Optional" placeholderTextColor={colors.faint} style={styles.input} />
        <FieldLabel label="Category" note="Optional—the backend can infer it" />
        <View style={styles.chips}>{categories.map((item) => <Chip key={item} active={category === item} onPress={() => setCategory(category === item ? undefined : item)}>{item}</Chip>)}</View>
      </View>

      <Button title={addItem.isPending ? "Analyzing and adding…" : "Add to my closet"} icon="sparkles" disabled={!name.trim() || !imageUri || addItem.isPending} onPress={submit} />
      {addItem.error ? <AppText selectable style={styles.error}>{addItem.error.message}</AppText> : null}
    </Screen>
  );
}

function FieldLabel({ label, required, note }: { label: string; required?: boolean; note?: string }) {
  return <View style={styles.labelRow}><AppText style={styles.label}>{label}{required ? " *" : ""}</AppText>{note ? <AppText style={styles.labelNote}>{note}</AppText> : null}</View>;
}

const styles = StyleSheet.create({
  topRow: { minHeight: 48, flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  iconButton: { width: 48, height: 48, borderRadius: 24, alignItems: "center", justifyContent: "center", backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke },
  iconSpacer: { width: 48 },
  header: { gap: spacing.md },
  note: { color: colors.muted },
  photoShell: { width: "100%", aspectRatio: 0.96, borderRadius: radius.xl, borderCurve: "continuous", overflow: "hidden", backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.strokeStrong, boxShadow: shadows.card },
  preview: { width: "100%", height: "100%" },
  emptyPhoto: { flex: 1, alignItems: "center", justifyContent: "center", padding: spacing.xxl, gap: spacing.sm },
  cameraIcon: { width: 64, height: 64, borderRadius: radius.lg, backgroundColor: colors.roseWash, alignItems: "center", justifyContent: "center", marginBottom: spacing.sm },
  emptyTitle: { fontSize: 18, lineHeight: 23, fontWeight: "800", textAlign: "center" },
  emptyNote: { color: colors.muted, fontSize: 13, lineHeight: 19, textAlign: "center" },
  remove: { position: "absolute", top: spacing.md, right: spacing.md, width: 44, height: 44, borderRadius: 22, backgroundColor: colors.scrim, alignItems: "center", justifyContent: "center" },
  sourceRow: { flexDirection: "row", gap: spacing.sm },
  warning: { color: colors.gold, fontSize: 13, lineHeight: 19 },
  form: { gap: spacing.md },
  labelRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", gap: spacing.md, marginBottom: -spacing.sm },
  label: { color: colors.inkSoft, fontSize: 14, fontWeight: "800" },
  labelNote: { flex: 1, color: colors.faint, fontSize: 11, lineHeight: 15, textAlign: "right" },
  input: { minHeight: 54, borderRadius: radius.lg, borderCurve: "continuous", borderColor: colors.strokeStrong, borderWidth: 1, backgroundColor: colors.surface, color: colors.ink, paddingHorizontal: spacing.lg, fontSize: 16 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.sm },
  error: { color: colors.danger }
});
