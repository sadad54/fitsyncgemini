import { useEffect, useState } from "react";
import { Pressable, StyleSheet, TextInput, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useClosetItem, useDeleteClosetItem, useUpdateClosetItem } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { Photo } from "@/components/Photo";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { colors, fonts, spacing } from "@/theme";
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
  const [deleteOpen, setDeleteOpen] = useState(false);

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

  function doDelete() {
    if (!id) return;
    setDeleteOpen(false);
    remove.mutate(id, { onSuccess: () => router.replace("/(tabs)/closet") });
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;
  if (item.isError) return <Screen><StatePanel title="This piece could not load" message={item.error.message} action="Try again" onAction={() => item.refetch()} /></Screen>;
  if (!item.data) return <Screen><StatePanel title="Finding that piece" message="Loading its image and style tags…" /></Screen>;

  const image = mediaUrl(item.data.image_url);
  return (
    <Screen bottomInset={false}>
      <View style={styles.topRow}>
        <Pressable accessibilityRole="button" accessibilityLabel="Back" onPress={() => router.back()} style={styles.iconButton}><AppText style={styles.iconGlyph}>←</AppText></Pressable>
        <Eyebrow>Closet details</Eyebrow>
        <Pressable accessibilityRole="button" accessibilityLabel="Delete item" onPress={() => setDeleteOpen(true)} style={[styles.iconButton, styles.deleteIcon]}><AppText style={styles.deleteGlyph}>✕</AppText></Pressable>
      </View>

      <View style={styles.imageShell}>
        {image ? <Photo source={image} transition={200} /> : <View style={styles.imagePlaceholder} />}
        <View style={styles.analysisBadge}><AppText style={styles.analysisText}>{String(item.data.analysis.provider ?? "local")} tags</AppText></View>
      </View>

      <View style={styles.header}>
        <Title style={styles.title}>{item.data.name}</Title>
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

      <Button title="Try it on" icon="arrow" onPress={() => router.push(`/tryon?from=item&items=${id}`)} />
      <Button title={update.isPending ? "Saving changes…" : "Save changes"} icon="checkmark" variant="secondary" disabled={!name.trim() || update.isPending} onPress={save} />
      <Button title={remove.isPending ? "Removing…" : "Remove from closet"} variant="danger" disabled={remove.isPending} onPress={() => setDeleteOpen(true)} />
      {update.error ? <AppText selectable style={styles.error}>{update.error.message}</AppText> : null}
      {remove.error ? <AppText selectable style={styles.error}>{remove.error.message}</AppText> : null}

      <ConfirmDialog
        visible={deleteOpen}
        title="Remove this piece?"
        body="It will disappear from your closet and future outfit recommendations."
        cancelLabel="Keep it"
        confirmLabel="Remove"
        destructive
        onCancel={() => setDeleteOpen(false)}
        onConfirm={doDelete}
      />
    </Screen>
  );
}

function Label({ children }: { children: string }) { return <AppText style={styles.label}>{children}</AppText>; }

const styles = StyleSheet.create({
  topRow: { minHeight: 40, flexDirection: "row", alignItems: "center", justifyContent: "space-between", borderBottomWidth: 2, borderColor: colors.strokeStrong, paddingBottom: spacing.md },
  iconButton: { width: 40, height: 40, alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: colors.stroke },
  iconGlyph: { color: colors.ink, fontSize: 16 },
  deleteIcon: { borderColor: colors.rose },
  deleteGlyph: { color: colors.roseSoft, fontSize: 14 },
  imageShell: { width: "100%", height: 396, backgroundColor: colors.surface, overflow: "hidden" },
  image: { width: "100%", height: "100%" },
  imagePlaceholder: { flex: 1, backgroundColor: colors.surface },
  analysisBadge: { position: "absolute", left: 0, bottom: 0, backgroundColor: colors.strokeStrong, paddingHorizontal: spacing.md, paddingVertical: spacing.sm },
  analysisText: { color: colors.canvas, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  header: { gap: spacing.md },
  title: { fontSize: 34 },
  tags: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  tag: { borderWidth: 1, borderColor: colors.stroke, paddingHorizontal: spacing.md, paddingVertical: spacing.xs },
  tagText: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  form: { gap: spacing.md },
  label: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase", marginBottom: -spacing.xs },
  input: { height: 48, borderWidth: 1, borderColor: colors.stroke, borderLeftWidth: 2, borderLeftColor: colors.strokeStrong, backgroundColor: colors.surface, color: colors.ink, paddingHorizontal: spacing.md, fontSize: 15, fontFamily: fonts.medium },
  notes: { minHeight: 96, paddingTop: spacing.md, textAlignVertical: "top" },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  error: { color: colors.roseSoft }
});
