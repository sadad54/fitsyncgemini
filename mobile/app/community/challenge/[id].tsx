import { useMemo, useState } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText } from "@/components/AppText";
import { Glyph } from "@/components/Glyph";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_AVATAR_ROW, SEED_CHALLENGES, SEED_POSTS } from "@/data/discover";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

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

  return (
    <Screen scroll bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.headerWrap}>
        <PushHeader title="Challenge" onBack={() => router.back()} />
      </View>

      <View style={styles.hero}>{photos[0] ? <Photo source={photos[0]} /> : <View style={styles.mediaPlaceholder} />}</View>

      <View style={styles.body}>
        <View style={styles.difficultyRow}>
          <Glyph shape={challenge.shape} size={11} strokeWidth={2} color={colors.roseSoft} />
          <AppText style={styles.difficulty}>{challenge.difficulty} · {challenge.days} days left</AppText>
        </View>
        <AppText style={styles.title}>{challenge.title}</AppText>
        <AppText style={styles.description}>
          One tone, head to shoe, for seven days. Texture is your only contrast — post each day's version and tag it.
        </AppText>
        <AppText style={styles.reward}>Reward: {challenge.reward}</AppText>
      </View>

      <View style={styles.participants}>
        <AppText style={styles.participantsCount}>{challenge.participants + (joined ? 1 : 0)} joined</AppText>
        <View style={styles.avatarRow}>
          {SEED_AVATAR_ROW.map((initial, index) => (
            <View key={initial} style={[styles.avatar, index === 0 && styles.avatarFirst]}>
              <AppText style={[styles.avatarText, index === 0 && styles.avatarTextFirst]}>{initial}</AppText>
            </View>
          ))}
        </View>
      </View>

      <Pressable
        accessibilityRole="button"
        accessibilityLabel={joined ? "Leave challenge" : "Join this challenge"}
        onPress={() => setJoined((v) => !v)}
        style={[styles.joinBtn, !joined && styles.joinBtnActive]}
      >
        <AppText style={[styles.joinLabel, !joined && styles.joinLabelActive]}>
          {joined ? "Joined — leave challenge" : "Join this challenge"}
        </AppText>
      </Pressable>

      <AppText style={styles.entriesLabel}>Entries</AppText>
      {SEED_POSTS.map((post, index) => {
        const image = photos[index % Math.max(photos.length, 1)];
        return (
          <View key={post.id} style={styles.entry}>
            <View style={styles.entryHeader}>
              <View style={styles.entryAvatar}>
                <AppText style={styles.entryAvatarText}>{post.initial}</AppText>
              </View>
              <AppText style={styles.entryName}>{post.name}</AppText>
              <AppText style={styles.entryLikes}>♥ {post.likes}</AppText>
            </View>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={`Open ${post.name}'s entry`}
              onPress={() => router.push(`/community/post/${post.id}`)}
              style={styles.entryMedia}
            >
              {image ? <Photo source={image} /> : <View style={styles.mediaPlaceholder} />}
            </Pressable>
            <AppText style={styles.entryCaption}>{post.caption}</AppText>
          </View>
        );
      })}
      <View style={{ height: 40 }} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  headerWrap: { paddingHorizontal: spacing.xl, paddingTop: spacing.sm },
  hero: { height: 240, backgroundColor: colors.surface, overflow: "hidden" },
  mediaPlaceholder: { flex: 1, backgroundColor: colors.surface },
  body: { paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.lg, borderBottomWidth: 1, borderColor: colors.stroke },
  difficultyRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  difficulty: { color: colors.roseSoft, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  title: { fontSize: 34, lineHeight: 32, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -1.2, textTransform: "uppercase", marginTop: spacing.md },
  description: { color: colors.muted, fontSize: 13, lineHeight: 21, marginTop: 11 },
  reward: { color: colors.ink, fontSize: 13, lineHeight: 21, marginTop: spacing.md },
  participants: { flexDirection: "row", alignItems: "center", gap: spacing.md, paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, borderBottomWidth: 1, borderColor: colors.stroke },
  participantsCount: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  avatarRow: { flexDirection: "row", gap: 4 },
  avatar: { width: 26, height: 26, backgroundColor: colors.surface, alignItems: "center", justifyContent: "center" },
  avatarFirst: { backgroundColor: colors.rose },
  avatarText: { color: colors.ink, fontFamily: fonts.black, fontWeight: "800", fontSize: 10 },
  avatarTextFirst: { color: colors.white },
  joinBtn: { height: 56, borderBottomWidth: 2, borderColor: colors.strokeStrong, justifyContent: "center", paddingHorizontal: spacing.xl },
  joinBtnActive: { backgroundColor: colors.rose },
  joinLabel: { color: colors.muted, fontFamily: fonts.black, fontWeight: "800", fontSize: 13, letterSpacing: 1.3, textTransform: "uppercase" },
  joinLabelActive: { color: colors.white },
  entriesLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6, textTransform: "uppercase", paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.sm },
  entry: { borderTopWidth: 1, borderColor: colors.stroke },
  entryHeader: { flexDirection: "row", alignItems: "center", gap: 11, paddingHorizontal: spacing.xl, paddingVertical: spacing.md },
  entryAvatar: { width: 30, height: 30, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center" },
  entryAvatarText: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 12 },
  entryName: { flex: 1, fontFamily: fonts.black, fontWeight: "800", fontSize: 13, letterSpacing: -0.2 },
  entryLikes: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  entryMedia: { height: 220, backgroundColor: colors.surface, overflow: "hidden" },
  entryCaption: { color: colors.muted, fontSize: 12, lineHeight: 18, paddingHorizontal: spacing.xl, paddingTop: spacing.md, paddingBottom: spacing.lg }
});
