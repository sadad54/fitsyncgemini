import { useState } from "react";
import { Platform, Pressable, StyleSheet, View, ViewStyle } from "react-native";
import { Image, ImageContentFit, ImageStyle } from "expo-image";

// The design prints every garment photo in pure black and white until it's
// touched ("Photography prints in pure black and white... duotone until you
// touch it"). RN has no native grayscale filter — on web we can pass real
// CSS through; on iOS/Android we fake it with a desaturating scrim that
// lifts on press, since there's no filter API without a native module.
export function Photo({
  source,
  style,
  contentFit = "cover",
  grayscale = true,
  transition = 180
}: {
  source: string;
  style?: ViewStyle;
  contentFit?: ImageContentFit;
  grayscale?: boolean;
  transition?: number;
}) {
  const [touched, setTouched] = useState(false);
  const showColor = touched || !grayscale;

  const webFilter =
    Platform.OS === "web"
      ? ({ filter: showColor ? "none" : "grayscale(1) contrast(1.15)", transition: "filter 300ms" } as unknown as ImageStyle)
      : undefined;

  return (
    <Pressable
      onPressIn={() => grayscale && setTouched(true)}
      onPressOut={() => grayscale && setTouched(false)}
      style={[styles.fill, style]}
    >
      <Image accessible={false} source={source} style={[styles.fill, webFilter]} contentFit={contentFit} transition={transition} cachePolicy="memory-disk" />
      {Platform.OS !== "web" && grayscale ? (
        <View pointerEvents="none" style={[styles.fill, styles.scrim, showColor && styles.scrimHidden]} />
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  fill: { width: "100%", height: "100%" },
  scrim: { backgroundColor: "rgba(19, 18, 17, 0.42)" },
  scrimHidden: { opacity: 0 }
});
