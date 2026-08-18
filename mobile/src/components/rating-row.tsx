import { Pressable, StyleSheet, View } from "react-native";
import * as Haptics from "expo-haptics";
import { AppText } from "@/components/AppText";
import { colors, fonts, spacing } from "@/theme";

export function RatingRow({ value, onChange, disabled }: { value: number; onChange: (value: number) => void; disabled?: boolean }) {
  return (
    <View style={styles.row}>
      <AppText style={styles.label}>{value ? "Thanks—feedback saved" : "Rate this look"}</AppText>
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
            <View style={[styles.diamond, rating <= value ? styles.diamondFilled : styles.diamondEmpty]} />
          </Pressable>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "center", gap: spacing.md },
  label: { color: colors.muted, fontSize: 9, lineHeight: 12, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  stars: { flexDirection: "row", gap: spacing.xs },
  star: { width: 22, height: 22, alignItems: "center", justifyContent: "center" },
  diamond: { width: 13, height: 13, transform: [{ rotate: "45deg" }] },
  diamondFilled: { backgroundColor: colors.rose },
  diamondEmpty: { backgroundColor: colors.stroke }
});
