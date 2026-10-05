import { useRef, useState } from "react";
import { StyleSheet, TextInput, View } from "react-native";
import * as ImagePicker from "expo-image-picker";
import * as Haptics from "expo-haptics";
import { Redirect, router } from "expo-router";
import Animated, { FadeIn, FadeInDown, ZoomIn } from "react-native-reanimated";
import { Camera, Check, Images, Shirt, Sparkles } from "@/icons";
import { useAddClosetItem, useDetectClosetItemCategory } from "@/api/queries";
import { AppText, Caption, Display, Em, Heading } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Chip } from "@/components/Chip";
import { PulseDot, Reveal, SETTLE } from "@/components/motion";
import { ScanBeam } from "@/components/ScanBeam";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { useAuthStore } from "@/store/auth";
import type { ClothingCategory } from "@/types/api";
import { colors, fonts, radius, spacing } from "@/theme";

const categories: ClothingCategory[] = ["tops", "bottoms", "dresses", "outerwear", "footwear", "accessories", "activewear"];

export default function AddItem() {
  const [name, setName] = useState("");
  const [brand, setBrand] = useState("");
  const [category, setCategory] = useState<ClothingCategory | undefined>();
  const [imageUri, setImageUri] = useState<string | null>(null);
  const [pickerError, setPickerError] = useState<string | null>(null);
  const [detectedVision, setDetectedVision] = useState<unknown>(null);
  const [added, setAdded] = useState(0);
  const [showMore, setShowMore] = useState(false);
  const categoryTouched = useRef(false);
  const nameTouched = useRef(false);
  const addItem = useAddClosetItem();
  const detect = useDetectClosetItemCategory();
  const token = useAuthStore((state) => state.token);

  async function pick(source: "camera" | "library") {
    setPickerError(null);
    if (source === "camera" && !(await ImagePicker.requestCameraPermissionsAsync()).granted) {
      setPickerError("Camera access is off. You can choose a photo from your library instead.");
      return;
    }
    const options: ImagePicker.ImagePickerOptions = { mediaTypes: ["images"], quality: 0.82, allowsEditing: true, aspect: [4, 5] };
    const result = source === "camera" ? await ImagePicker.launchCameraAsync(options) : await ImagePicker.launchImageLibraryAsync(options);
    if (result.canceled) return;
    const uri = result.assets[0].uri;
    setImageUri(uri);
    categoryTouched.current = false;
    nameTouched.current = false;
    setDetectedVision(null);
    detect.mutate(uri, {
      onSuccess: (vision) => {
        setDetectedVision(vision);
        if (!categoryTouched.current && vision.category && vision.category !== "unknown") setCategory(vision.category);
        if (!nameTouched.current && vision.suggested_name) setName(vision.suggested_name);
      },
      onError: () => {}
    });
  }

  async function submit(addAnother: boolean) {
    if (!name.trim() || !imageUri) return;
    try {
      await addItem.mutateAsync({ name, brand, category, imageUri, detectedVision });
    } catch { return; }
    if (process.env.EXPO_OS !== "web") Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    if (!addAnother) { router.back(); return; }
    setAdded((n) => n + 1);
    setImageUri(null); setName(""); setBrand(""); setCategory(undefined); setDetectedVision(null); addItem.reset();
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  const ready = Boolean(name.trim() && imageUri);
  const footer = imageUri ? (
    <View style={styles.footerRow}>
      <View style={styles.flex}><Button title="Save & add another" variant="secondary" disabled={!ready || addItem.isPending} onPress={() => submit(true)} /></View>
      <View style={styles.flex}><Button title="Save" icon={Check} loading={addItem.isPending} disabled={!ready} onPress={() => submit(false)} /></View>
    </View>
  ) : undefined;

  return (
    <Screen footer={footer}>
      <PushHeader title={added ? `${added} added` : "New piece"} backGlyph="✕" onBack={() => router.back()} />

      {!imageUri ? (
        <Reveal>
          <View style={styles.intro}>
            <Display>Snap a piece <Em>you own.</Em></Display>
            <AppText style={styles.note}>Lay it flat or hang it up, in good light. Flairwise tags the type and colour for you.</AppText>
          </View>
        </Reveal>
      ) : null}

      <Reveal delay={60}>
        <View style={styles.photo}>
          {imageUri ? (
            <Animated.View entering={ZoomIn.duration(420).easing(SETTLE)} style={StyleSheet.absoluteFill}><Photo source={imageUri} />{detect.isPending ? <ScanBeam duration={1200} /> : null}</Animated.View>
          ) : (
            <View style={styles.empty}>
              <View style={styles.emptyIcon}><Shirt size={30} color={colors.accent} strokeWidth={1.6} /></View>
              <View style={styles.sourceRow}>
                <Button title="Camera" icon={Camera} compact stretch={false} variant="accent" onPress={() => pick("camera")} />
                <Button title="Library" icon={Images} compact stretch={false} variant="secondary" onPress={() => pick("library")} />
              </View>
            </View>
          )}
          {detect.isPending ? (
            <Animated.View entering={FadeIn} style={styles.detecting}>
              <PulseDot size={7} />
              <AppText style={styles.detectingText}>Recognising…</AppText>
            </Animated.View>
          ) : detectedVision && category ? (
            <Animated.View entering={FadeInDown.easing(SETTLE)} style={styles.detecting}>
              <Sparkles size={14} color={colors.accent} />
              <AppText style={styles.detectingText}>Looks like {category}</AppText>
            </Animated.View>
          ) : null}
        </View>
      </Reveal>

      {imageUri ? (
        <Animated.View entering={FadeInDown.duration(400).easing(SETTLE)} style={styles.form}>
          <View style={styles.sourceRowInline}>
            <Button title="Retake" icon={Camera} compact stretch={false} variant="secondary" onPress={() => pick("camera")} />
            <Button title="Library" icon={Images} compact stretch={false} variant="ghost" onPress={() => pick("library")} />
          </View>
          <View style={styles.field}>
            <Caption>Name</Caption>
            <TextInput accessibilityLabel="Item name" value={name} onChangeText={(text) => { nameTouched.current = true; setName(text); }}
              placeholder={detect.isPending ? "Detecting…" : "Blue linen overshirt"} placeholderTextColor={colors.faint} style={styles.input} />
          </View>
          <View style={styles.field}>
            <Caption>Type</Caption>
            <View style={styles.chips}>{categories.map((item) => (
              <Chip key={item} active={category === item} onPress={() => { categoryTouched.current = true; setCategory(category === item ? undefined : item); }}>{item}</Chip>
            ))}</View>
          </View>
          {showMore ? (
            <View style={styles.field}>
              <Caption>Brand</Caption>
              <TextInput accessibilityLabel="Brand, optional" value={brand} onChangeText={setBrand} placeholder="Optional" placeholderTextColor={colors.faint} style={styles.input} />
            </View>
          ) : <Button title="Add brand" variant="ghost" compact stretch={false} onPress={() => setShowMore(true)} />}
        </Animated.View>
      ) : (
        <Reveal delay={120}>
          <View style={styles.tips}>
            <Heading>For the best results</Heading>
            {["One garment per photo", "Plain background, natural light", "Whole piece in frame, front facing"].map((tip) => (
              <View key={tip} style={styles.tip}><Check size={16} color={colors.success} strokeWidth={2.4} /><AppText style={styles.tipText}>{tip}</AppText></View>
            ))}
          </View>
        </Reveal>
      )}

      {[pickerError, addItem.error?.message].filter(Boolean).map((m, i) => <AppText key={i} selectable style={styles.error}>{m}</AppText>)}
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  intro: { gap: spacing.sm },
  note: { color: colors.inkSoft, fontSize: 16, lineHeight: 23 },
  photo: { width: "100%", aspectRatio: 4 / 5, borderRadius: radius.xl, overflow: "hidden", backgroundColor: colors.surface },
  empty: { flex: 1, alignItems: "center", justifyContent: "center", gap: spacing.xl, borderRadius: radius.xl, borderWidth: 1.5, borderStyle: "dashed", borderColor: colors.strokeStrong },
  emptyIcon: { width: 76, height: 76, borderRadius: 38, backgroundColor: colors.ink, alignItems: "center", justifyContent: "center" },
  sourceRow: { flexDirection: "row", gap: spacing.sm },
  sourceRowInline: { flexDirection: "row", gap: spacing.xs },
  detecting: { position: "absolute", left: spacing.md, bottom: spacing.md, flexDirection: "row", alignItems: "center", gap: 6, height: 34, paddingHorizontal: spacing.md, borderRadius: radius.pill, backgroundColor: "rgba(13,13,15,0.86)" },
  detectingText: { fontSize: 13, fontFamily: fonts.medium, textTransform: "capitalize", color: colors.onStage },
  form: { gap: spacing.lg },
  field: { gap: spacing.sm },
  input: { height: 50, borderRadius: radius.md, backgroundColor: colors.surface, paddingHorizontal: spacing.lg, fontSize: 16, color: colors.ink, fontFamily: fonts.regular, borderWidth: 1, borderColor: colors.stroke },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: spacing.xs },
  tips: { gap: spacing.md, backgroundColor: colors.surface, borderRadius: radius.xl, padding: spacing.lg, borderWidth: 1, borderColor: colors.stroke },
  tip: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  tipText: { fontSize: 15, color: colors.inkSoft },
  footerRow: { flexDirection: "row", gap: spacing.sm },
  error: { color: colors.danger, fontSize: 14 }
});
