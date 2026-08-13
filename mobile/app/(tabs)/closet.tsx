import { useState } from "react";
import { FlatList, Pressable, ScrollView, StyleSheet, TextInput, useWindowDimensions, View } from "react-native";
import { router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useCloset } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Chip } from "@/components/Chip";
import { ItemCard } from "@/components/ItemCard";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { colors, radius, shadows, spacing } from "@/theme";
import type { ClothingCategory } from "@/types/api";

const categories: Array<ClothingCategory | "all"> = ["all", "tops", "bottoms", "outerwear", "footwear", "dresses", "accessories", "activewear"];

export default function Closet() {
  const [category, setCategory] = useState<ClothingCategory | "all">("all");
  const [search, setSearch] = useState("");
  const closet = useCloset(category, search);
  const { width } = useWindowDimensions();
  const columns = width >= 760 ? 3 : 2;

  return (
    <Screen scroll={false} contentStyle={styles.screen}>
      <View style={styles.header}>
        <View style={styles.headerCopy}>
          <Eyebrow>Your wardrobe</Eyebrow>
          <Title>The closet edit.</Title>
          <AppText style={styles.subtitle}>{closet.data?.total ?? 0} pieces, ready to remix.</AppText>
        </View>
        <Pressable accessibilityRole="button" accessibilityLabel="Add a closet item" onPress={() => router.push("/add-item")} style={({ pressed }) => [styles.addButton, pressed && styles.pressed]}>
          <Ionicons name="add" size={25} color={colors.white} />
        </Pressable>
      </View>

      <View style={styles.searchShell}>
        <Ionicons name="search" size={20} color={colors.muted} />
        <TextInput
          accessibilityLabel="Search your closet"
          value={search}
          onChangeText={setSearch}
          placeholder="Search by name or color"
          placeholderTextColor={colors.faint}
          returnKeyType="search"
          style={styles.input}
        />
        {search ? <Pressable accessibilityRole="button" accessibilityLabel="Clear search" onPress={() => setSearch("")} style={styles.clear}><Ionicons name="close-circle" size={20} color={colors.faint} /></Pressable> : null}
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.chips}>
        {categories.map((item) => <Chip key={item} active={category === item} onPress={() => setCategory(item)}>{item}</Chip>)}
      </ScrollView>

      {closet.isError ? (
        <StatePanel icon="cloud-offline-outline" title="Your closet could not sync" message={closet.error.message} action="Try again" onAction={() => closet.refetch()} />
      ) : (
        <FlatList
          key={columns}
          data={closet.data?.items ?? []}
          numColumns={columns}
          contentInsetAdjustmentBehavior="automatic"
          columnWrapperStyle={styles.gridRow}
          contentContainerStyle={styles.list}
          keyExtractor={(item) => item.id}
          refreshing={closet.isRefetching}
          onRefresh={() => closet.refetch()}
          showsVerticalScrollIndicator={false}
          renderItem={({ item }) => <ItemCard item={item} width={`${100 / columns - 2}%`} />}
          ListEmptyComponent={
            <StatePanel
              icon={closet.isLoading ? "hourglass-outline" : "shirt-outline"}
              title={closet.isLoading ? "Opening your closet" : search || category !== "all" ? "No pieces match" : "Your rail is waiting"}
              message={closet.isLoading ? "Fetching your pieces and their AI tags…" : search || category !== "all" ? "Try a broader search or another category." : "Add a clear garment photo and FitSync will tag it for styling."}
              action={!closet.isLoading && !search && category === "all" ? "Add first piece" : undefined}
              onAction={() => router.push("/add-item")}
            />
          }
        />
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { gap: spacing.lg },
  header: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", gap: spacing.lg },
  headerCopy: { flex: 1, gap: spacing.xs },
  subtitle: { color: colors.muted, fontSize: 14, lineHeight: 20 },
  addButton: { width: 52, height: 52, borderRadius: 26, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center", boxShadow: shadows.card },
  pressed: { opacity: 0.72, transform: [{ scale: 0.96 }] },
  searchShell: { minHeight: 54, borderRadius: radius.lg, borderCurve: "continuous", borderColor: colors.strokeStrong, borderWidth: 1, backgroundColor: colors.surface, paddingHorizontal: spacing.lg, flexDirection: "row", alignItems: "center", gap: spacing.sm },
  input: { flex: 1, color: colors.ink, fontSize: 16, paddingVertical: spacing.md },
  clear: { width: 44, height: 44, alignItems: "center", justifyContent: "center", marginRight: -spacing.md },
  chips: { gap: spacing.sm, paddingRight: spacing.xl },
  list: { flexGrow: 1, gap: spacing.md, paddingTop: spacing.xs, paddingBottom: 112 },
  gridRow: { gap: spacing.md, marginBottom: spacing.md }
});
