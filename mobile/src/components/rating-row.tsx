import { Pressable, StyleSheet, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { AppText } from "@/components/AppText";
import { colors, spacing } from "@/theme";

export function RatingRow({ value, onChange, disabled }: { value: number; onChange: (value: number) => void; disabled?: boolean }) {
  return (
    <View style={styles.row}>
      <AppText style={styles.label}>{value ? "Thanks—feedback saved" : "How wearable is this?"}</AppText>
      <View style={styles.stars}>
        {[1, 2, 3, 4, 5].map((rating) => (
          <Pressable
            key={rating}
            accessibilityRole="button"
            accessibilityLabel={`${rating} star${rating === 1 ? "" : "s"}`}
            accessibilityState={{ selected: value === rating, disabled }}
            disabled={disabled}
            onPress={() => {
              if (process.env.EXPO_OS === "ios") Haptics.selectionAsync();
              onChange(rating);
            }}
            style={styles.star}
          >
            <Ionicons name={rating <= value ? "star" : "star-outline"} size={20} color={rating <= value ? colors.gold : colors.faint} />
          </Pressable>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { gap: spacing.sm },
  label: { color: colors.muted, fontSize: 13, lineHeight: 18, fontWeight: "700" },
  stars: { flexDirection: "row" },
  star: { width: 44, height: 44, alignItems: "center", justifyContent: "center" }
});
