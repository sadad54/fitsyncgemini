import { StyleSheet } from "react-native";
import { Image, ImageContentFit, ImageStyle } from "expo-image";

/** Garments always render in true colour — colour is the information. */
export function Photo({
  source,
  style,
  contentFit = "cover",
  transition = 220
}: {
  source: string;
  style?: ImageStyle;
  contentFit?: ImageContentFit;
  /** Legacy prop from the monochrome system; ignored. */
  grayscale?: boolean;
  transition?: number;
}) {
  return (
    <Image
      aria-hidden
      source={source}
      style={[styles.fill, style]}
      contentFit={contentFit}
      transition={transition}
      cachePolicy="memory-disk"
    />
  );
}

const styles = StyleSheet.create({ fill: { width: "100%", height: "100%" } });
