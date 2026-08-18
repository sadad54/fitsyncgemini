import { PropsWithChildren } from "react";
import { StyleSheet, Text, TextProps } from "react-native";
import { colors, fonts, typography } from "@/theme";

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
  display: { color: colors.ink, fontSize: 44, lineHeight: 41, ...typography.display, textTransform: "uppercase" },
  title: { color: colors.ink, fontSize: 40, lineHeight: 37, ...typography.display, textTransform: "uppercase" },
  eyebrow: {
    color: colors.roseSoft,
    fontSize: 10,
    lineHeight: 13,
    fontFamily: fonts.bold,
    fontWeight: "700",
    letterSpacing: 1.6,
    textTransform: "uppercase"
  }
});
