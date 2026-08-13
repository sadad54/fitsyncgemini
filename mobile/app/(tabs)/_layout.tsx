import { Redirect, Slot } from "expo-router";
import { StyleSheet, View } from "react-native";
import { BottomNav } from "@/components/BottomNav";
import { colors } from "@/theme";
import { useAuthStore } from "@/store/auth";

export default function TabsLayout() {
  const token = useAuthStore((state) => state.token);
  if (!token) return <Redirect href="/(auth)/sign-in" />;
  return (
    <View style={styles.shell}>
      <View style={styles.stage}><Slot /></View>
      <BottomNav />
    </View>
  );
}

const styles = StyleSheet.create({
  shell: { flex: 1, backgroundColor: colors.canvas },
  stage: { flex: 1 }
});
