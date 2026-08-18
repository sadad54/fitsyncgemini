// Modernist — flat, architectural, one family (Archivo), one signal color.
// Atelier-at-night: ink ground, bone type, signal red. Zero radius, no shadows,
// full-bleed bands divided by rules instead of floating cards.
export const colors = {
  canvas: "#131211",
  canvasSoft: "#131211",
  surface: "#1c1a19",
  surfaceElevated: "#232120",
  surfaceMuted: "#232120",
  ink: "#f3f2f2",
  inkSoft: "#f3f2f2",
  muted: "#9b9797",
  faint: "rgba(243, 242, 242, 0.42)",
  stroke: "rgba(243, 242, 242, 0.18)",
  strokeStrong: "#f3f2f2",
  rose: "#ec3013",
  roseSoft: "#ff563c",
  roseWash: "transparent",
  plum: "#9b9797",
  plumWash: "transparent",
  gold: "#ec3013",
  goldWash: "transparent",
  sage: "#5fae8c",
  sageWash: "transparent",
  danger: "#ec3013",
  dangerWash: "transparent",
  white: "#ffffff",
  black: "#000000",
  scrim: "rgba(13, 12, 11, 0.72)",

  // Compatibility aliases while legacy components migrate to semantic tokens.
  paper: "#131211",
  cotton: "#1c1a19",
  bone: "#232120",
  stitch: "rgba(243, 242, 242, 0.18)",
  moss: "#5fae8c",
  denim: "#9b9797",
  tomato: "#ec3013",
  brass: "#ec3013",
  success: "#5fae8c"
};

// Flat fills — same-stop arrays so LinearGradient renders as a solid color.
// Kept as gradients only so call sites don't need touching.
export const gradients = {
  hero: ["#131211", "#131211"] as const,
  rose: ["#ec3013", "#ec3013"] as const,
  plum: ["#232120", "#232120"] as const,
  gold: ["#ec3013", "#ec3013"] as const,
  surface: ["#1c1a19", "#1c1a19"] as const
};

export const spacing = {
  xxs: 2,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 22,
  xxl: 32,
  xxxl: 40,
  display: 56
};

// Every radius is 0 on purpose — nothing rounds in this system.
export const radius = {
  sm: 0,
  md: 0,
  lg: 0,
  xl: 0,
  pill: 0
};

export const fonts = {
  regular: "Archivo_400Regular",
  medium: "Archivo_500Medium",
  semibold: "Archivo_600SemiBold",
  bold: "Archivo_700Bold",
  black: "Archivo_800ExtraBold"
};

export const typography = {
  display: {
    fontFamily: fonts.black,
    fontWeight: "800" as const,
    letterSpacing: -1.6
  },
  body: {
    fontFamily: fonts.regular,
    fontWeight: "400" as const
  },
  label: {
    fontFamily: fonts.bold,
    fontWeight: "700" as const,
    letterSpacing: 1.6
  }
};

export const motion = {
  quick: 160,
  standard: 260,
  reveal: 300
};

// No elevation in this system — bands are separated by rules, not shadow.
export const shadows = {
  card: "none",
  floating: "none"
};
