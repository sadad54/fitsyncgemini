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
  return <AppText accessibilityRole="header" maxFontSizeMultiplier={1.3} {...props} style={[styles.display, style]}>{children}</AppText>;
}

/** Serif section/secondary headline. */
export function Title({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText accessibilityRole="header" maxFontSizeMultiplier={1.4} {...props} style={[styles.title, style]}>{children}</AppText>;
}

/** Serif italic, for the one emphasised word inside a headline. Nest it in Display/Title. */
export function Em({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <Text {...props} style={[styles.em, style]}>{children}</Text>;
}

/** Functional heading for cards, rows and sheets. */
export function Heading({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText {...props} style={[styles.heading, style]}>{children}</AppText>;
}

/** Small label above a headline or section. */
export function Eyebrow({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText {...props} style={[styles.eyebrow, style]}>{children}</AppText>;
}

/** Uppercase label-maker tag — the brand's "punch" voice. Keep it to 1–3 words. */
export function Punch({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText maxFontSizeMultiplier={1.3} {...props} style={[styles.punch, style]}>{children}</AppText>;
}

export function Caption({ children, style, ...props }: PropsWithChildren<TextProps>) {
  return <AppText {...props} style={[styles.caption, style]}>{children}</AppText>;
}

const styles = StyleSheet.create({
  text: { color: colors.ink, fontSize: 16, lineHeight: 23, ...typography.body },
  display: { color: colors.ink, fontSize: 44, lineHeight: 46, ...typography.display },
  title: { color: colors.ink, fontSize: 28, lineHeight: 32, ...typography.display, letterSpacing: -0.4 },
  em: { fontFamily: fonts.serifItalic, fontStyle: "normal" },
  heading: { color: colors.ink, fontSize: 17, lineHeight: 22, fontFamily: fonts.semibold, fontWeight: "600", letterSpacing: -0.2 },
  eyebrow: { color: colors.muted, fontSize: 13, lineHeight: 18, fontFamily: fonts.medium, fontWeight: "500", letterSpacing: 0.1 },
  punch: { color: colors.ink, fontSize: 11, lineHeight: 14, ...typography.punch },
  caption: { color: colors.muted, fontSize: 13, lineHeight: 18, fontFamily: fonts.regular }
});
