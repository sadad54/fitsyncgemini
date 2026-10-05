// Flairwise "Volt Atelier".
// A hybrid system. Everyday screens sit on a crisp, cool bone ground so garments
// read in true colour. Hero moments (Today's look, the fitting room, boot,
// sign-in) move onto an ink "stage" — a lit dressing room. One signal colour,
// volt, means "Flairwise is doing something for you": AI, try-on, the centre
// action. Volt is a fill colour (ink text on top) and a glow on the stage; it is
// never used as text on light surfaces. Coral is the human colour: love, heat.
//
// Type: Instrument Serif for editorial headlines, Archivo ExtraBold for
// uppercase "label-maker" punches, Geist for everything functional.
const palette = {
  bone: "#F6F6F2",
  boneDeep: "#ECECE6",
  card: "#FFFFFF",
  ink: "#0D0D0F",
  ink2: "#3E3E44",
  stone: "#66666D",
  hairline: "rgba(13, 13, 15, 0.08)",
  hairlineStrong: "rgba(13, 13, 15, 0.16)",
  volt: "#D4FF3A",
  voltDeep: "#B8E600",
  voltSoft: "#F0FFC4",
  coral: "#FF5A3C",
  coralSoft: "#FFE7E1",
  ember: "#C2321A",
  emberSoft: "#FBE4DE",
  pine: "#16794A",
  pineSoft: "#DDF2E5",
  stage: "#0D0D0F",
  stageRaised: "#1A1A1F",
  stageLine: "rgba(246, 246, 242, 0.12)"
};

export const colors = {
  canvas: palette.bone,
  canvasSoft: palette.boneDeep,
  surface: palette.card,
  surfaceElevated: palette.card,
  surfaceMuted: palette.boneDeep,
  ink: palette.ink,
  inkSoft: palette.ink2,
  muted: palette.stone,
  faint: "rgba(13, 13, 15, 0.38)",
  stroke: palette.hairline,
  strokeStrong: palette.hairlineStrong,

  /** Volt: a fill. Put `onAccent` (ink) on top; never use as text on light. */
  accent: palette.volt,
  accentDeep: palette.voltDeep,
  accentWash: palette.voltSoft,
  onAccent: palette.ink,
  onInk: "#F6F6F2",

  /** Secondary accent — hearts, heat, "trending". */
  flare: palette.coral,
  flareWash: palette.coralSoft,

  /** The dark stage used for hero moments. */
  stage: palette.stage,
  stageRaised: palette.stageRaised,
  stageLine: palette.stageLine,
  onStage: "#F6F6F2",
  onStageMuted: "rgba(246, 246, 242, 0.64)",

  danger: palette.ember,
  dangerWash: palette.emberSoft,
  success: palette.pine,
  successWash: palette.pineSoft,
  white: "#FFFFFF",
  black: "#000000",
  scrim: "rgba(13, 13, 15, 0.55)",

  // Legacy names still referenced by older screens, mapped onto the new system.
  rose: palette.ink,
  roseSoft: palette.ink,
  roseWash: palette.voltSoft,
  plum: palette.stone,
  plumWash: palette.boneDeep,
  gold: palette.coral,
  goldWash: palette.coralSoft,
  sage: palette.pine,
  sageWash: palette.pineSoft,
  paper: palette.bone,
  cotton: palette.card,
  bone: palette.boneDeep,
  stitch: palette.hairline,
  moss: palette.pine,
  denim: palette.stone,
  tomato: palette.coral,
  brass: palette.coral
};

export const gradients = {
  hero: [palette.bone, palette.boneDeep] as const,
  rose: [palette.volt, palette.voltDeep] as const,
  plum: [palette.boneDeep, palette.boneDeep] as const,
  gold: [palette.coral, palette.coral] as const,
  surface: [palette.card, palette.card] as const,
  stage: ["#1C1C22", palette.stage] as const,
  photoFade: ["rgba(13,13,15,0)", "rgba(13,13,15,0.7)"] as const
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
  serifItalic: "InstrumentSerif_400Regular_Italic",
  punch: "Archivo_800ExtraBold",
  regular: "Geist_400Regular",
  medium: "Geist_500Medium",
  semibold: "Geist_600SemiBold",
  bold: "Geist_700Bold",
  black: "Archivo_800ExtraBold"
};

export const typography = {
  display: { fontFamily: fonts.serif, fontWeight: "400" as const, letterSpacing: -0.8 },
  body: { fontFamily: fonts.regular, fontWeight: "400" as const },
  label: { fontFamily: fonts.medium, fontWeight: "500" as const, letterSpacing: 0.2 },
  /** Uppercase label-maker tag: TODAY'S LOOK, ON YOU, 3 OF 4. */
  punch: { fontFamily: fonts.punch, fontWeight: "800" as const, letterSpacing: 1.4, textTransform: "uppercase" as const }
};

export const motion = { quick: 160, standard: 240, reveal: 320 };

export const shadows = {
  card: "0 1px 2px rgba(13,13,15,0.04), 0 10px 28px rgba(13,13,15,0.07)",
  floating: "0 14px 36px rgba(13,13,15,0.28)",
  volt: "0 8px 26px rgba(184,230,0,0.45)"
};

export const layout = { gutter: 20, tabBarHeight: 64 };
