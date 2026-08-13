// Editorial, system-first palette: warm paper, ink, and one restrained signal color.
export const colors = {
  canvas: "#F5F4F0",
  canvasSoft: "#FBFAF7",
  surface: "#FFFFFF",
  surfaceElevated: "#FFFFFF",
  surfaceMuted: "#ECE9E2",
  ink: "#191917",
  inkSoft: "#3F3D38",
  muted: "#6F6B64",
  faint: "#99948B",
  stroke: "rgba(25, 25, 23, 0.09)",
  strokeStrong: "rgba(25, 25, 23, 0.15)",
  rose: "#C94734",
  roseSoft: "#A43D2D",
  roseWash: "rgba(201, 71, 52, 0.09)",
  plum: "#373330",
  plumWash: "rgba(55, 51, 48, 0.07)",
  gold: "#9A6A24",
  goldWash: "rgba(154, 106, 36, 0.10)",
  sage: "#39745D",
  sageWash: "rgba(57, 116, 93, 0.10)",
  danger: "#B42318",
  dangerWash: "rgba(180, 35, 24, 0.10)",
  white: "#FFFFFF",
  black: "#000000",
  scrim: "rgba(18, 18, 16, 0.46)",

  // Compatibility aliases while legacy components migrate to semantic tokens.
  paper: "#F5F4F0",
  cotton: "#FFFFFF",
  bone: "#ECE9E2",
  stitch: "rgba(25, 25, 23, 0.09)",
  moss: "#39745D",
  denim: "#373330",
  tomato: "#C94734",
  brass: "#9A6A24",
  success: "#39745D"
};

export const gradients = {
  hero: ["#FBFAF7", "#F5F4F0", "#F5F4F0"] as const,
  rose: ["#191917", "#191917"] as const,
  plum: ["#373330", "#373330"] as const,
  gold: ["#B88439", "#98651B"] as const,
  surface: ["#FFFFFF", "#FFFFFF"] as const
};

export const spacing = {
  xxs: 2,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
  xxxl: 40,
  display: 56
};

export const radius = {
  sm: 12,
  md: 18,
  lg: 24,
  xl: 32,
  pill: 999
};

export const typography = {
  display: {
    fontFamily: process.env.EXPO_OS === "ios" ? "New York" : "Georgia",
    fontWeight: "700" as const,
    letterSpacing: -1.2
  },
  body: {
    fontWeight: "400" as const
  },
  label: {
    fontWeight: "700" as const,
    letterSpacing: 0.2
  }
};

export const motion = {
  quick: 160,
  standard: 260,
  reveal: 420
};

export const shadows = {
  card: "0 8px 28px rgba(25, 25, 23, 0.07)",
  floating: "0 16px 40px rgba(25, 25, 23, 0.13)"
};
