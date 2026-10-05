import { useMemo, useState } from "react";
import { StyleSheet, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText, Caption, Display, Heading, Punch } from "@/components/AppText";
import { Button } from "@/components/Button";
import { PressableScale, Reveal } from "@/components/motion";
import { Photo } from "@/components/Photo";
import { PreviewNote } from "@/components/PreviewNote";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_AVATAR_ROW, SEED_CHALLENGES, SEED_POSTS } from "@/data/discover";
import { Check, Heart, Sparkles } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";

export default function ChallengeDetail() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const closet = useCloset();
  const challenge = SEED_CHALLENGES.find((entry) => entry.id === id) ?? SEED_CHALLENGES[0];
  const [joined, setJoined] = useState(false);
  const photos = useMemo(
    () => (closet.data?.items ?? []).map((item) => mediaUrl(item.image_url)).filter(Boolean) as string[],
    [closet.data]
  );

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  const footer = joined
    ? <Button title="Style an entry from my closet" icon={Sparkles} variant="accent" onPress={() => router.push("/style")} />
    : <Button title="Join this challenge" onPress={() => setJoined(true)} />;

  return (
    <Screen footer={footer}>
      <PushHeader title="Challenge" onBack={() => router.back()} />
      <Reveal>
        <View style={styles.hero}>
          <View style={styles.heroTop}>
            <Punch style={styles.heroTag}>{challenge.difficulty}</Punch>
            <Punch style={styles.heroTag}>{challenge.days} days left</Punch>
          </View>
          <Display style={styles.title}>{challenge.title}</Display>
          <AppText style={styles.description}>One tone, head to shoe, for seven days. Texture is your only contrast — post each day's version and tag it.</AppText>
          <View style={styles.reward}><AppText style={styles.rewardText}>Reward · {challenge.reward}</AppText></View>
        </View>
      </Reveal>
      <PreviewNote />

      <View style={styles.participants}>
        <View style={styles.avatars}>
          {SEED_AVATAR_ROW.map((initial, index) => (
            <View key={initial} style={[styles.avatar, { marginLeft: index ? -10 : 0, zIndex: 10 - index }, index === 0 && styles.avatarFirst]}>
              <AppText style={styles.avatarText}>{initial}</AppText>
            </View>
          ))}
        </View>
        <Heading style={styles.flex}>{(challenge.participants + (joined ? 1 : 0)).toLocaleString()} joined</Heading>
        {joined ? <View style={styles.joined}><Check size={14} color={colors.ink} strokeWidth={3} /><Punch style={styles.joinedText}>You're in</Punch></View> : null}
      </View>

      <View style={styles.entries}>
        <Punch style={styles.label}>Entries</Punch>
        <View style={styles.grid}>
          {SEED_POSTS.map((post, index) => (
            <Reveal key={post.id} index={index} style={styles.cell}>
              <PressableScale accessibilityRole="button" accessibilityLabel={`Open ${post.name}'s entry`} onPress={() => router.push(`/community/post/${post.id}`)} style={styles.entry}>
                <View style={[styles.entryMedia, { height: index % 3 === 0 ? 220 : 180 }]}>
                  {photos.length ? <Photo source={photos[index % photos.length]} /> : <View style={styles.placeholder} />}
                </View>
                <View style={styles.entryMeta}>
                  <AppText numberOfLines={1} style={styles.entryName}>{post.name}</AppText>
                  <View style={styles.entryLikes}><Heart size={12} color={colors.muted} /><Caption>{post.likes}</Caption></View>
                </View>
              </PressableScale>
            </Reveal>
          ))}
        </View>
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  hero: { backgroundColor: colors.accent, borderRadius: radius.xl, padding: spacing.xl, gap: spacing.md, borderWidth: 1.5, borderColor: colors.ink, boxShadow: "6px 6px 0 #0D0D0F" },
  heroTop: { flexDirection: "row", gap: spacing.xs },
  heroTag: { fontSize: 9, lineHeight: 11, borderWidth: 1.5, borderColor: colors.ink, borderRadius: radius.pill, paddingHorizontal: 10, paddingVertical: 5 },
  title: { fontSize: 44, lineHeight: 44 },
  description: { fontSize: 15, lineHeight: 22 },
  reward: { alignSelf: "flex-start", backgroundColor: colors.ink, borderRadius: radius.pill, paddingHorizontal: spacing.md, paddingVertical: 7 },
  rewardText: { color: colors.onInk, fontSize: 13, fontFamily: fonts.medium },
  participants: { flexDirection: "row", alignItems: "center", gap: spacing.md },
  avatars: { flexDirection: "row" },
  avatar: { width: 34, height: 34, borderRadius: 17, backgroundColor: colors.surface, borderWidth: 2, borderColor: colors.canvas, alignItems: "center", justifyContent: "center" },
  avatarFirst: { backgroundColor: colors.flare },
  avatarText: { fontFamily: fonts.serif, fontSize: 16 },
  joined: { flexDirection: "row", alignItems: "center", gap: 5, backgroundColor: colors.accent, borderRadius: radius.pill, paddingHorizontal: 10, height: 28, borderWidth: 1, borderColor: colors.ink },
  joinedText: { fontSize: 9, lineHeight: 11 },
  entries: { gap: spacing.sm },
  label: { color: colors.muted },
  grid: { flexDirection: "row", flexWrap: "wrap", marginHorizontal: -6 },
  cell: { width: "50%", padding: 6 },
  entry: { gap: spacing.xs },
  entryMedia: { borderRadius: radius.lg, overflow: "hidden", backgroundColor: colors.canvasSoft },
  placeholder: { flex: 1, backgroundColor: colors.canvasSoft },
  entryMeta: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 2 },
  entryName: { flex: 1, fontSize: 13, fontFamily: fonts.medium },
  entryLikes: { flexDirection: "row", alignItems: "center", gap: 3 }
});
