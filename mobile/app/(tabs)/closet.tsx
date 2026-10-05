import { useState } from "react";
import { FlatList, ScrollView, StyleSheet, TextInput, View, useWindowDimensions } from "react-native";
import { router } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import Animated, { FadeInDown, FadeOutDown } from "react-native-reanimated";
import { Plus, Search, Shirt, Sparkles, X } from "@/icons";
import { useCloset } from "@/api/queries";
import { AppText, Caption, Display, Em, Punch } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { IconButton } from "@/components/IconButton";
import { ItemCard } from "@/components/ItemCard";
import { PressableScale, Reveal, SETTLE, Skeleton } from "@/components/motion";
import { StatePanel } from "@/components/state-panel";
import { isValidTryOnSelection } from "@/lib/tryon";
import type { ClothingCategory } from "@/types/api";
import { colors, fonts, layout, radius, spacing } from "@/theme";

const categories: Array<ClothingCategory | "all"> = ["all", "tops", "bottoms", "dresses", "outerwear", "footwear", "accessories", "activewear"];

export default function Closet() {
  const [category, setCategory] = useState<ClothingCategory | "all">("all");
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<string[]>([]);
  const closet = useCloset(category, search);
  const all = useCloset();
  const { width } = useWindowDimensions();
  const columns = width >= 760 ? 3 : 2;
  const selecting = selected.length > 0;
  const picks = (all.data?.items ?? []).filter((item) => selected.includes(item.id));
  const valid = isValidTryOnSelection(picks);

  const toggle = (id: string) => setSelected((current) => current.includes(id) ? current.filter((x) => x !== id) : [...current, id]);

  return (
    <View style={styles.root}>
      <StatusBar style="dark" />
      <SafeAreaView edges={["top"]} style={styles.flex}>
        <FlatList
          key={columns}
          data={closet.data?.items ?? []}
          numColumns={columns}
          keyExtractor={(item) => item.id}
          refreshing={closet.isRefetching}
          onRefresh={() => closet.refetch()}
          showsVerticalScrollIndicator={false}
          contentContainerStyle={styles.list}
          ListHeaderComponent={
            <View style={styles.header}>
              <Reveal>
                <View style={styles.titleRow}>
                  <View style={styles.flex}>
                    <Punch style={styles.count}>{all.data?.total ?? 0} pieces</Punch>
                    <Display>Your <Em>closet</Em></Display>
                  </View>
                  <IconButton icon={Plus} label="Add a piece" tone="accent" size={52} onPress={() => router.push("/add-item")} />
                </View>
              </Reveal>
              <Reveal delay={60}>
                <View style={styles.search}>
                  <Search size={18} color={colors.muted} />
                  <TextInput accessibilityLabel="Search your closet" value={search} onChangeText={setSearch} placeholder="Search by name or colour"
                    placeholderTextColor={colors.faint} returnKeyType="search" style={styles.input} />
                  {search ? <IconButton icon={X} label="Clear search" size={32} onPress={() => setSearch("")} /> : null}
                </View>
              </Reveal>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.chipScroll} contentContainerStyle={styles.chips}>
                {categories.map((item) => <Chip key={item} active={category === item} onPress={() => setCategory(item)}>{item === "all" ? "All" : item}</Chip>)}
              </ScrollView>
              {!selecting && (all.data?.total ?? 0) > 1 ? <Caption>Tip: press and hold pieces to try them on together.</Caption> : null}
            </View>
          }
          renderItem={({ item, index }) => (
            <Reveal index={index % 8} delay={80} style={{ width: `${100 / columns}%` }}>
              <ItemCard
                item={item}
                width="100%"
                selecting={selecting}
                selected={selected.includes(item.id)}
                onPress={selecting ? () => toggle(item.id) : undefined}
                onLongPress={() => toggle(item.id)}
              />
            </Reveal>
          )}
          ListEmptyComponent={
            closet.isLoading ? (
              <View style={styles.skeletons}>{[0, 1, 2, 3].map((i) => <Skeleton key={i} style={styles.skeleton} />)}</View>
            ) : closet.isError ? (
              <StatePanel title="Your closet didn't load" message={closet.error.message} action="Try again" onAction={() => closet.refetch()} />
            ) : (
              <StatePanel
                icon={Shirt}
                title={search || category !== "all" ? "Nothing matches" : "Your closet is empty"}
                message={search || category !== "all" ? "Try a broader search or another category." : "Photograph a piece you own. Flairwise tags it and starts styling."}
                action={!search && category === "all" ? "Add a piece" : undefined}
                onAction={() => router.push("/add-item")}
              />
            )
          }
        />
      </SafeAreaView>

      {selecting ? (
        <Animated.View entering={FadeInDown.duration(320).easing(SETTLE)} exiting={FadeOutDown.duration(200)} style={styles.selectBar}>
          <PressableScale accessibilityRole="button" accessibilityLabel="Cancel selection" onPress={() => setSelected([])} style={styles.selectCancel}>
            <X size={18} color={colors.onInk} />
          </PressableScale>
          <View style={styles.flex}>
            <AppText style={styles.selectTitle}>{selected.length} selected</AppText>
            <AppText style={styles.selectNote}>{valid ? "Ready to try on" : "Pick a dress, or a top + bottom"}</AppText>
          </View>
          <Button title="Try on" icon={Sparkles} variant="accent" compact stretch={false} disabled={!valid}
            onPress={() => { const ids = selected.join(","); setSelected([]); router.push(`/tryon?items=${ids}&auto=1`); }} />
        </Animated.View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.canvas },
  flex: { flex: 1 },
  list: { paddingHorizontal: layout.gutter - 6, paddingBottom: 140 },
  header: { paddingHorizontal: 6, paddingTop: spacing.md, gap: spacing.lg, marginBottom: spacing.sm },
  titleRow: { flexDirection: "row", alignItems: "flex-end", gap: spacing.md },
  count: { color: colors.muted, marginBottom: spacing.xs },
  search: { flexDirection: "row", alignItems: "center", gap: spacing.sm, height: 50, paddingLeft: spacing.lg, paddingRight: spacing.xs, borderRadius: radius.pill, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke },
  input: { flex: 1, color: colors.ink, fontSize: 16, fontFamily: fonts.regular, height: "100%" },
  chipScroll: { marginHorizontal: -layout.gutter },
  chips: { gap: spacing.xs, paddingHorizontal: layout.gutter },
  skeletons: { flexDirection: "row", flexWrap: "wrap" },
  skeleton: { width: "46%", margin: "2%", aspectRatio: 0.8, borderRadius: radius.lg },
  selectBar: {
    position: "absolute", left: 14, right: 14, bottom: 100, flexDirection: "row", alignItems: "center", gap: spacing.md,
    backgroundColor: colors.ink, borderRadius: radius.pill, padding: 6, paddingLeft: 6, boxShadow: "0 12px 30px rgba(23,20,15,0.3)"
  },
  selectCancel: { width: 44, height: 44, borderRadius: 22, backgroundColor: "rgba(255,255,255,0.12)", alignItems: "center", justifyContent: "center" },
  selectTitle: { color: colors.onInk, fontSize: 15, fontFamily: fonts.semibold, fontWeight: "600" },
  selectNote: { color: colors.onStageMuted, fontSize: 12 }
});
