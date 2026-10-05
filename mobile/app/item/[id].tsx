import { useEffect, useMemo, useState } from "react";
import { ScrollView, StyleSheet, TextInput, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { ChevronLeft, Sparkles, Trash2 } from "lucide-react-native";
import { useClosetItem, useDeleteClosetItem, useOutfits, useUpdateClosetItem, useCloset } from "@/api/queries";
import { mediaUrl } from "@/api/client";
import { AppText, Caption, Heading, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { IconButton } from "@/components/IconButton";
import { colorFromName } from "@/components/ItemCard";
import { PressableScale, Reveal } from "@/components/motion";
import { OutfitRail } from "@/components/outfit-rail";
import { Photo } from "@/components/Photo";
import { StatePanel } from "@/components/state-panel";
import { Screen } from "@/components/Screen";
import { isTryOnable } from "@/lib/tryon";
import { useAuthStore } from "@/store/auth";
import type { ClothingCategory } from "@/types/api";
import { colors, fonts, layout, radius, spacing } from "@/theme";

const categories: ClothingCategory[] = ["tops", "bottoms", "dresses", "outerwear", "footwear", "accessories", "activewear"];

export default function ItemDetail() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const item = useClosetItem(id ?? "", Boolean(token));
  const outfits = useOutfits(true);
  const closet = useCloset();
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

  const appearsIn = useMemo(() => (outfits.data?.outfits ?? []).filter((o) => id && o.item_ids.includes(id)), [outfits.data, id]);
  const dirty = item.data && (name.trim() !== item.data.name || brand.trim() !== (item.data.brand ?? "") || notes.trim() !== (item.data.notes ?? "") || category !== item.data.category);

  if (!token) return <Redirect href="/(auth)/sign-in" />;
  if (item.isError) return <Screen><StatePanel title="This piece didn't load" message={item.error.message} action="Try again" onAction={() => item.refetch()} /></Screen>;
  if (!item.data) return <Screen><StatePanel title="Opening piece" message="One moment…" /></Screen>;

  const image = mediaUrl(item.data.image_url);
  const tryable = isTryOnable(item.data);

  return (
    <View style={styles.root}>
      <StatusBar style="dark" />
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
        <View style={styles.hero}>
          {image ? <Photo source={image} /> : null}
          <SafeAreaView edges={["top"]} style={styles.heroBar}>
            <IconButton icon={ChevronLeft} label="Back" tone="glass" onPress={() => router.back()} />
            <IconButton icon={Trash2} label="Remove from closet" tone="glass" onPress={() => setDeleteOpen(true)} />
          </SafeAreaView>
        </View>

        <View style={styles.body}>
          <Reveal>
            <View style={styles.head}>
              <Title style={styles.title}>{item.data.name}</Title>
              <View style={styles.tags}>
                {item.data.colors.map((color) => (
                  <View key={color} style={styles.tag}><View style={[styles.dot, { backgroundColor: colorFromName(color) }]} /><AppText style={styles.tagText}>{color}</AppText></View>
                ))}
                {item.data.tags.slice(0, 3).map((tag) => <View key={tag} style={styles.tag}><AppText style={styles.tagText}>{tag}</AppText></View>)}
              </View>
            </View>
          </Reveal>

          <Reveal delay={60}>
            {tryable
              ? <Button title="Try it on" icon={Sparkles} variant="accent" onPress={() => router.push(`/tryon?items=${id}&auto=1`)} />
              : <Caption>Try-on supports tops, bottoms, outerwear and dresses.</Caption>}
          </Reveal>

          {appearsIn.length ? (
            <Reveal delay={100}>
              <View style={styles.section}>
                <Heading>In your looks</Heading>
                {appearsIn.slice(0, 3).map((outfit) => (
                  <PressableScale key={outfit.id} accessibilityRole="button" accessibilityLabel={outfit.name} onPress={() => router.push(`/look/${outfit.id}`)} style={styles.lookRow}>
                    <OutfitRail compact items={(closet.data?.items ?? []).filter((piece) => outfit.item_ids.includes(piece.id))} />
                    <AppText numberOfLines={1} style={styles.lookName}>{outfit.name}</AppText>
                  </PressableScale>
                ))}
              </View>
            </Reveal>
          ) : null}

          <Reveal delay={140}>
            <View style={styles.card}>
              <Heading>Details</Heading>
              <Field label="Name"><TextInput accessibilityLabel="Item name" value={name} onChangeText={setName} style={styles.input} /></Field>
              <Field label="Brand"><TextInput accessibilityLabel="Brand" value={brand} onChangeText={setBrand} placeholder="Optional" placeholderTextColor={colors.faint} style={styles.input} /></Field>
              <Field label="Category">
                <View style={styles.chips}>{categories.map((value) => <Chip key={value} active={category === value} onPress={() => setCategory(value)}>{value}</Chip>)}</View>
              </Field>
              <Field label="Notes">
                <TextInput accessibilityLabel="Notes" value={notes} onChangeText={setNotes} placeholder="Fit, fabric, how you like to wear it" placeholderTextColor={colors.faint} multiline style={[styles.input, styles.notes]} />
              </Field>
              {dirty ? (
                <Button title="Save changes" loading={update.isPending} disabled={!name.trim()}
                  onPress={() => id && update.mutate({ id, input: { name: name.trim(), brand: brand.trim() || undefined, notes: notes.trim() || undefined, category } })} />
              ) : null}
              {update.error ? <AppText selectable style={styles.error}>{update.error.message}</AppText> : null}
              {remove.error ? <AppText selectable style={styles.error}>{remove.error.message}</AppText> : null}
            </View>
          </Reveal>
        </View>
      </ScrollView>

      <ConfirmDialog visible={deleteOpen} title="Remove this piece?" body="It leaves your closet and future outfits."
        cancelLabel="Keep it" confirmLabel="Remove" destructive onCancel={() => setDeleteOpen(false)}
        onConfirm={() => { setDeleteOpen(false); if (id) remove.mutate(id, { onSuccess: () => router.back() }); }} />
    </View>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return <View style={styles.field}><Caption>{label}</Caption>{children}</View>;
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.canvas },
  scroll: { paddingBottom: 60 },
  hero: { width: "100%", aspectRatio: 4 / 5, backgroundColor: colors.surface, borderBottomLeftRadius: radius.xl, borderBottomRightRadius: radius.xl, overflow: "hidden" },
  heroBar: { position: "absolute", top: 0, left: 0, right: 0, flexDirection: "row", justifyContent: "space-between", paddingHorizontal: layout.gutter, paddingTop: spacing.sm },
  body: { paddingHorizontal: layout.gutter, paddingTop: spacing.xl, gap: spacing.xl },
  head: { gap: spacing.md },
  title: { fontSize: 34, lineHeight: 38 },
  tags: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  tag: { flexDirection: "row", alignItems: "center", gap: 6, height: 30, paddingHorizontal: spacing.md, borderRadius: radius.pill, backgroundColor: colors.surface },
  dot: { width: 10, height: 10, borderRadius: 5, borderWidth: StyleSheet.hairlineWidth, borderColor: colors.strokeStrong },
  tagText: { fontSize: 13, color: colors.inkSoft, fontFamily: fonts.medium, textTransform: "capitalize" },
  section: { gap: spacing.sm },
  lookRow: { flexDirection: "row", alignItems: "center", gap: spacing.md, backgroundColor: colors.surface, borderRadius: radius.lg, padding: spacing.sm },
  lookName: { flex: 1, fontSize: 15, fontFamily: fonts.medium },
  card: { backgroundColor: colors.surface, borderRadius: radius.xl, padding: spacing.lg, gap: spacing.lg },
  field: { gap: spacing.sm },
  input: { minHeight: 50, borderRadius: radius.md, backgroundColor: colors.canvas, paddingHorizontal: spacing.lg, fontSize: 16, color: colors.ink, fontFamily: fonts.regular },
  notes: { minHeight: 96, paddingTop: spacing.md, textAlignVertical: "top" },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  error: { color: colors.danger, fontSize: 14 }
});
