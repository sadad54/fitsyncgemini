import { PropsWithChildren } from "react";
import { StyleSheet, Text, TextProps } from "react-native";
import { colors, typography } from "@/theme";

export function AppText({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return (
    <Text allowFontScaling {...props} style={[styles.text, style]}>
      {children}
    </Text>
  );
}

export function Display({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText {...props} style={[styles.display, style]}>{children}</AppText>;
}

export function Title({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText {...props} style={[styles.title, style]}>{children}</AppText>;
}

export function Eyebrow({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText {...props} style={[styles.eyebrow, style]}>{children}</AppText>;
}

const styles = StyleSheet.create({
  text: { color: colors.ink, fontSize: 16, lineHeight: 24, ...typography.body },
  display: { color: colors.ink, fontSize: 44, lineHeight: 48, ...typography.display },
  title: { color: colors.ink, fontSize: 30, lineHeight: 35, ...typography.display },
  eyebrow: { color: colors.roseSoft, fontSize: 12, lineHeight: 16, ...typography.label, letterSpacing: 1.2, textTransform: "uppercase" }
});
