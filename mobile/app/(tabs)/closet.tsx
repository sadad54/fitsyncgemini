import { useState } from "react";
import { FlatList, Pressable, ScrollView, StyleSheet, TextInput, useWindowDimensions, View } from "react-native";
import { router } from "expo-router";
import { useCloset } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Chip } from "@/components/Chip";
import { SearchIcon } from "@/components/Icon";
import { ItemCard } from "@/components/ItemCard";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { colors, fonts, spacing } from "@/theme";
import type { ClothingCategory } from "@/types/api";

const categories: Array<ClothingCategory | "all"> = ["all", "tops", "bottoms", "outerwear", "footwear", "dresses", "accessories", "activewear"];

export default function Closet() {
  const [category, setCategory] = useState<ClothingCategory | "all">("all");
  const [search, setSearch] = useState("");
  const closet = useCloset(category, search);
  const { width } = useWindowDimensions();
  const columns = width >= 760 ? 3 : 2;

  return (
    <Screen scroll={false} bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.header}>
        <View style={styles.headerCopy}>
          <Eyebrow>Your wardrobe</Eyebrow>
          <Title style={styles.title}>The rail</Title>
          <AppText style={styles.subtitle}>{closet.data?.total ?? 0} pieces, ready to remix.</AppText>
        </View>
        <Pressable accessibilityRole="button" accessibilityLabel="Add a closet item" onPress={() => router.push("/add-item")} style={styles.addButton}>
          <AppText style={styles.addGlyph}>+</AppText>
        </Pressable>
      </View>

      <View style={styles.searchShell}>
        <SearchIcon size={16} color={colors.muted} />
        <TextInput
          accessibilityLabel="Search your closet"
          value={search}
          onChangeText={setSearch}
          placeholder="Search by name or color"
          placeholderTextColor={colors.faint}
          returnKeyType="search"
          style={styles.input}
        />
        {search ? <Pressable accessibilityRole="button" accessibilityLabel="Clear search" onPress={() => setSearch("")} style={styles.clear}><AppText style={styles.clearGlyph}>✕</AppText></Pressable> : null}
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.chipsRow} contentContainerStyle={styles.chipsContent}>
        {categories.map((item) => <Chip key={item} active={category === item} onPress={() => setCategory(item)}>{item}</Chip>)}
      </ScrollView>

      {closet.isError ? (
        <View style={styles.padded}>
          <StatePanel title="Your closet could not sync" message={closet.error.message} action="Try again" onAction={() => closet.refetch()} />
        </View>
      ) : (
        <FlatList
          key={columns}
          data={closet.data?.items ?? []}
          numColumns={columns}
          contentInsetAdjustmentBehavior="automatic"
          contentContainerStyle={styles.list}
          keyExtractor={(item) => item.id}
          refreshing={closet.isRefetching}
          onRefresh={() => closet.refetch()}
          showsVerticalScrollIndicator={false}
          renderItem={({ item }) => <ItemCard item={item} width={`${100 / columns}%`} />}
          ListEmptyComponent={
            <View style={styles.padded}>
              <StatePanel
                title={closet.isLoading ? "Opening your closet" : search || category !== "all" ? "No pieces match" : "Your rail is waiting"}
                message={closet.isLoading ? "Fetching your pieces and their AI tags…" : search || category !== "all" ? "Try a broader search or another category." : "Add a clear garment photo and FitSync will tag it for styling."}
                action={!closet.isLoading && !search && category === "all" ? "Add first piece" : undefined}
                onAction={() => router.push("/add-item")}
              />
            </View>
          }
        />
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  header: { flexDirection: "row", alignItems: "flex-end", justifyContent: "space-between", gap: spacing.lg, paddingHorizontal: spacing.xl, paddingBottom: spacing.lg, borderBottomWidth: 2, borderColor: colors.strokeStrong },
  headerCopy: { flex: 1, gap: spacing.xs },
  title: { fontSize: 40 },
  subtitle: { color: colors.muted, fontSize: 12, marginTop: spacing.xs, fontFamily: fonts.regular },
  addButton: { width: 48, height: 48, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center" },
  addGlyph: { color: colors.white, fontSize: 26, lineHeight: 26, fontFamily: fonts.regular },
  searchShell: { height: 52, borderBottomWidth: 1, borderColor: colors.stroke, paddingHorizontal: spacing.xl, flexDirection: "row", alignItems: "center", gap: spacing.sm },
  input: { flex: 1, color: colors.ink, fontSize: 14, fontFamily: fonts.medium },
  clear: { width: 32, height: 32, alignItems: "center", justifyContent: "center" },
  clearGlyph: { color: colors.muted, fontSize: 15 },
  chipsRow: { flexGrow: 0, borderBottomWidth: 1, borderColor: colors.stroke },
  chipsContent: { gap: spacing.xs, paddingHorizontal: spacing.xl, paddingVertical: spacing.sm },
  padded: { paddingHorizontal: spacing.xl },
  list: { flexGrow: 1, paddingBottom: 40 }
});
