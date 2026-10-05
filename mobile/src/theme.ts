// FitSync "Daylight Atelier".
// Warm paper ground, ink type, garments shown in true colour. One accent —
// cobalt "sync" — reserved for AI and try-on moments, so it always means
// "FitSync is doing something for you". Editorial serif for headlines,
// Geist for everything functional.
const palette = {
  paper: "#F5F2EC",
  paperDeep: "#ECE7DE",
  card: "#FFFFFF",
  ink: "#17140F",
  ink2: "#4B463E",
  stone: "#8A8379",
  hairline: "rgba(23, 20, 15, 0.09)",
  hairlineStrong: "rgba(23, 20, 15, 0.18)",
  sync: "#2E44D6",
  syncSoft: "#E6E9FB",
  clay: "#B5502B",
  claySoft: "#F6E6DF",
  moss: "#3F6B4E",
  mossSoft: "#E3EDE5"
};

export const colors = {
  canvas: palette.paper,
  canvasSoft: palette.paperDeep,
  surface: palette.card,
  surfaceElevated: palette.card,
  surfaceMuted: palette.paperDeep,
  ink: palette.ink,
  inkSoft: palette.ink2,
  muted: palette.stone,
  faint: "rgba(23, 20, 15, 0.38)",
  stroke: palette.hairline,
  strokeStrong: palette.hairlineStrong,

  accent: palette.sync,
  accentWash: palette.syncSoft,
  onAccent: "#FFFFFF",
  onInk: "#FAF8F4",

  danger: palette.clay,
  dangerWash: palette.claySoft,
  success: palette.moss,
  successWash: palette.mossSoft,
  white: "#FFFFFF",
  black: "#000000",
  scrim: "rgba(23, 20, 15, 0.45)",

  // Legacy names still referenced by older screens, mapped onto the new system.
  rose: palette.sync,
  roseSoft: palette.sync,
  roseWash: palette.syncSoft,
  plum: palette.stone,
  plumWash: palette.paperDeep,
  gold: palette.clay,
  goldWash: palette.claySoft,
  sage: palette.moss,
  sageWash: palette.mossSoft,
  paper: palette.paper,
  cotton: palette.card,
  bone: palette.paperDeep,
  stitch: palette.hairline,
  moss: palette.moss,
  denim: palette.stone,
  tomato: palette.clay,
  brass: palette.clay
};

export const gradients = {
  hero: [palette.paper, palette.paperDeep] as const,
  rose: [palette.sync, "#4A5DE8"] as const,
  plum: [palette.paperDeep, palette.paperDeep] as const,
  gold: [palette.clay, palette.clay] as const,
  surface: [palette.card, palette.card] as const,
  photoFade: ["rgba(23,20,15,0)", "rgba(23,20,15,0.55)"] as const
};

export const spacing = {
  xxs: 2,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 28,
  xxxl: 40,
  display: 56
};

export const radius = {
  sm: 10,
  md: 14,
  lg: 20,
  xl: 28,
  pill: 999
};

export const fonts = {
  serif: "InstrumentSerif_400Regular",
  regular: "Geist_400Regular",
  medium: "Geist_500Medium",
  semibold: "Geist_600SemiBold",
  bold: "Geist_700Bold",
  black: "Geist_700Bold"
};

export const typography = {
  display: { fontFamily: fonts.serif, fontWeight: "400" as const, letterSpacing: -0.6 },
  body: { fontFamily: fonts.regular, fontWeight: "400" as const },
  label: { fontFamily: fonts.medium, fontWeight: "500" as const, letterSpacing: 0.2 }
};

export const motion = { quick: 160, standard: 240, reveal: 320 };

export const shadows = {
  card: "0 1px 2px rgba(23,20,15,0.04), 0 8px 24px rgba(23,20,15,0.06)",
  floating: "0 10px 30px rgba(23,20,15,0.18)"
};

export const layout = { gutter: 20, tabBarHeight: 64 };
