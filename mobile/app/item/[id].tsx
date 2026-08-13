import { useEffect, useState } from "react";
import { Alert, Pressable, StyleSheet, TextInput, View } from "react-native";
import { Image } from "expo-image";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { mediaUrl } from "@/api/client";
import { useClosetItem, useDeleteClosetItem, useUpdateClosetItem } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { colors, radius, shadows, spacing } from "@/theme";
import type { ClothingCategory } from "@/types/api";
import { useAuthStore } from "@/store/auth";

const categories: ClothingCategory[] = ["tops", "bottoms", "dresses", "outerwear", "footwear", "accessories", "activewear"];

export default function ItemDetail() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const item = useClosetItem(id ?? "", Boolean(token));
  const update = useUpdateClosetItem();
  const remove = useDeleteClosetItem();
  const [name, setName] = useState("");
  const [brand, setBrand] = useState("");
  const [notes, setNotes] = useState("");
  const [category, setCategory] = useState<ClothingCategory>("unknown");

  useEffect(() => {
    if (!item.data) return;
    setName(item.data.name);
    setBrand(item.data.brand ?? "");
    setNotes(item.data.notes ?? "");
    setCategory(item.data.category);
  }, [item.data]);

  function save() {
    if (!id || !name.trim()) return;
    update.mutate({ id, input: { name: name.trim(), brand: brand.trim() || undefined, notes: notes.trim() || undefined, category } }, { onSuccess: () => router.back() });
  }

  function confirmDelete() {
    if (!id) return;
    Alert.alert("Remove this piece?", "It will disappear from your closet and future outfit recommendations.", [
      { text: "Keep it", style: "cancel" },
      { text: "Remove", style: "destructive", onPress: () => remove.mutate(id, { onSuccess: () => router.replace("/(tabs)/closet") }) }
    ]);
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;
  if (item.isError) return <Screen><StatePanel title="This piece could not load" message={item.error.message} action="Try again" onAction={() => item.refetch()} /></Screen>;
  if (!item.data) return <Screen><StatePanel icon="hourglass-outline" title="Finding that piece" message="Loading its image and style tags…" /></Screen>;

  const image = mediaUrl(item.data.image_url);
  return (
    <Screen bottomInset={false}>
      <View style={styles.topRow}>
        <Pressable accessibilityRole="button" accessibilityLabel="Back" onPress={() => router.back()} style={styles.iconButton}><Ionicons name="chevron-back" size={23} color={colors.ink} /></Pressable>
        <Eyebrow>Closet details</Eyebrow>
        <Pressable accessibilityRole="button" accessibilityLabel="Delete item" onPress={confirmDelete} style={[styles.iconButton, styles.deleteIcon]}><Ionicons name="trash-outline" size={20} color={colors.danger} /></Pressable>
      </View>

      <View style={styles.imageShell}>
        {image ? <Image accessibilityLabel={`Photo of ${item.data.name}`} source={image} style={styles.image} contentFit="cover" transition={200} cachePolicy="memory-disk" /> : <Ionicons name="shirt-outline" size={42} color={colors.faint} />}
        <View style={styles.analysisBadge}><Ionicons name="sparkles" size={14} color={colors.gold} /><AppText style={styles.analysisText}>{String(item.data.analysis.provider ?? "local")} tags</AppText></View>
      </View>

      <View style={styles.header}>
        <Title>{item.data.name}</Title>
        <View style={styles.tags}>{item.data.colors.map((color) => <View key={color} style={styles.tag}><AppText style={styles.tagText}>{color}</AppText></View>)}{item.data.tags.slice(0, 3).map((tag) => <View key={tag} style={styles.tag}><AppText style={styles.tagText}>{tag}</AppText></View>)}</View>
      </View>

      <View style={styles.form}>
        <Label>Item name</Label>
        <TextInput accessibilityLabel="Item name" value={name} onChangeText={setName} style={styles.input} />
        <Label>Brand</Label>
        <TextInput accessibilityLabel="Brand" value={brand} onChangeText={setBrand} placeholder="Optional" placeholderTextColor={colors.faint} style={styles.input} />
        <Label>Category</Label>
        <View style={styles.chips}>{categories.map((value) => <Chip key={value} active={category === value} onPress={() => setCategory(value)}>{value}</Chip>)}</View>
        <Label>Notes</Label>
        <TextInput accessibilityLabel="Notes" value={notes} onChangeText={setNotes} placeholder="Fit, fabric, styling notes…" placeholderTextColor={colors.faint} multiline style={[styles.input, styles.notes]} />
      </View>

      <Button title={update.isPending ? "Saving changes…" : "Save changes"} icon="checkmark" disabled={!name.trim() || update.isPending} onPress={save} />
      <Button title={remove.isPending ? "Removing…" : "Remove from closet"} icon="trash-outline" variant="danger" disabled={remove.isPending} onPress={confirmDelete} />
      {update.error ? <AppText selectable style={styles.error}>{update.error.message}</AppText> : null}
      {remove.error ? <AppText selectable style={styles.error}>{remove.error.message}</AppText> : null}
    </Screen>
  );
}

function Label({ children }: { children: string }) { return <AppText style={styles.label}>{children}</AppText>; }

const styles = StyleSheet.create({
  topRow: { minHeight: 48, flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  iconButton: { width: 48, height: 48, borderRadius: 24, alignItems: "center", justifyContent: "center", backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke },
  deleteIcon: { backgroundColor: colors.dangerWash },
  imageShell: { width: "100%", aspectRatio: 0.88, borderRadius: radius.xl, borderCurve: "continuous", overflow: "hidden", backgroundColor: colors.surfaceElevated, borderWidth: 1, borderColor: colors.strokeStrong, alignItems: "center", justifyContent: "center", boxShadow: shadows.card },
  image: { width: "100%", height: "100%" },
  analysisBadge: { position: "absolute", left: spacing.md, bottom: spacing.md, flexDirection: "row", alignItems: "center", gap: spacing.xs, borderRadius: radius.pill, backgroundColor: colors.scrim, paddingHorizontal: spacing.md, paddingVertical: spacing.sm },
  analysisText: { color: colors.inkSoft, fontSize: 12, lineHeight: 16, fontWeight: "700" },
  header: { gap: spacing.md },
  tags: { flexDirection: "row", flexWrap: "wrap", gap: spacing.sm },
  tag: { borderRadius: radius.pill, backgroundColor: colors.surfaceElevated, paddingHorizontal: spacing.md, paddingVertical: spacing.xs },
  tagText: { color: colors.muted, fontSize: 12, lineHeight: 16, textTransform: "capitalize" },
  form: { gap: spacing.md },
  label: { color: colors.inkSoft, fontSize: 14, fontWeight: "800", marginBottom: -spacing.sm },
  input: { minHeight: 54, borderRadius: radius.lg, borderCurve: "continuous", borderWidth: 1, borderColor: colors.strokeStrong, backgroundColor: colors.surface, color: colors.ink, paddingHorizontal: spacing.lg, fontSize: 16 },
  notes: { minHeight: 112, paddingTop: spacing.lg, textAlignVertical: "top" },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.sm },
  error: { color: colors.danger }
});
