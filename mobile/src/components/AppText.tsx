import { PropsWithChildren } from "react";
import { StyleSheet, Text, TextProps } from "react-native";
import { colors, fonts, typography } from "@/theme";

export function AppText({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return (
    <Text allowFontScaling maxFontSizeMultiplier={1.6} {...props} style={[styles.text, style]}>
      {children}
    </Text>
  );
}

/** Editorial serif headline — one per screen. */
export function Display({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText accessibilityRole="header" {...props} style={[styles.display, style]}>{children}</AppText>;
}

/** Serif section/secondary headline. */
export function Title({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText accessibilityRole="header" {...props} style={[styles.title, style]}>{children}</AppText>;
}

/** Functional heading for cards, rows and sheets. */
export function Heading({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText {...props} style={[styles.heading, style]}>{children}</AppText>;
}

/** Small label above a headline or section. */
export function Eyebrow({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText {...props} style={[styles.eyebrow, style]}>{children}</AppText>;
}

export function Caption({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText {...props} style={[styles.caption, style]}>{children}</AppText>;
}

const styles = StyleSheet.create({
  text: { color: colors.ink, fontSize: 16, lineHeight: 23, ...typography.body },
  display: { color: colors.ink, fontSize: 40, lineHeight: 44, ...typography.display },
  title: { color: colors.ink, fontSize: 28, lineHeight: 32, ...typography.display, letterSpacing: -0.3 },
  heading: { color: colors.ink, fontSize: 17, lineHeight: 22, fontFamily: fonts.semibold, fontWeight: "600", letterSpacing: -0.2 },
  eyebrow: { color: colors.muted, fontSize: 13, lineHeight: 18, fontFamily: fonts.medium, fontWeight: "500", letterSpacing: 0.1 },
  caption: { color: colors.muted, fontSize: 13, lineHeight: 18, fontFamily: fonts.regular }
});
