import { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, View } from "react-native";
import { Redirect, router } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Glyph } from "@/components/Glyph";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { SEED_CHALLENGES, SEED_POSTS, type FeedTab } from "@/data/discover";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

const TABS: FeedTab[] = ["Following", "Discover", "Challenges"];

export default function CommunityFeed() {
  const token = useAuthStore((state) => state.token);
  const closet = useCloset();
  const [tab, setTab] = useState<FeedTab>("Following");
  const [likes, setLikes] = useState<Record<string, boolean>>({ p2: true });
  const [joined, setJoined] = useState<Record<string, boolean>>({ ch2: true });

  // Community imagery stands in with the member's own closet photos until the
  // posts service is rebuilt — see src/data/discover.ts.
  const photos = useMemo(
    () => (closet.data?.items ?? []).map((item) => mediaUrl(item.image_url)).filter(Boolean) as string[],
    [closet.data]
  );

  const posts = useMemo(
    () => SEED_POSTS.filter((post) => tab === "Discover" || post.following),
    [tab]
  );

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen scroll bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.headerWrap}>
        <PushHeader title="Community" onBack={() => router.back()} rule="none" />
      </View>

      <View style={styles.hero}>
        <View style={styles.heroCopy}>
          <Eyebrow>Community</Eyebrow>
          <Title style={styles.heroTitle}>What people are actually wearing</Title>
        </View>
        <Pressable accessibilityRole="button" accessibilityLabel="Share a look" onPress={() => router.push("/community/create")} style={styles.addButton}>
          <AppText style={styles.addGlyph}>+</AppText>
        </Pressable>
      </View>

      <View style={styles.tabs}>
        {TABS.map((item) => {
          const active = tab === item;
          return (
            <Pressable
              key={item}
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
              onPress={() => setTab(item)}
              style={[styles.tab, active && styles.tabActive]}
            >
              <AppText style={[styles.tabLabel, active && styles.tabLabelActive]}>{item}</AppText>
            </Pressable>
          );
        })}
      </View>

      {tab === "Challenges" ? (
        SEED_CHALLENGES.map((challenge, index) => {
          const isJoined = Boolean(joined[challenge.id]);
          return (
            <View key={challenge.id} style={styles.challenge}>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={challenge.title}
                onPress={() => router.push(`/community/challenge/${challenge.id}`)}
                style={styles.challengeRow}
              >
                <View style={styles.challengeMedia}>
                  {photos[index % Math.max(photos.length, 1)] ? (
                    <Photo source={photos[index % photos.length]} />
                  ) : (
                    <View style={styles.mediaPlaceholder} />
                  )}
                </View>
                <View style={styles.challengeCopy}>
                  <View style={styles.difficultyRow}>
                    <Glyph shape={challenge.shape} size={11} strokeWidth={2} color={colors.roseSoft} />
                    <AppText style={styles.difficulty}>{challenge.difficulty}</AppText>
                  </View>
                  <AppText style={styles.challengeTitle}>{challenge.title}</AppText>
                  <AppText style={styles.challengeReward}>{challenge.reward}</AppText>
                  <AppText style={styles.challengeMeta}>
                    {challenge.participants + (isJoined ? 1 : 0)} joined · {challenge.days} days left
                  </AppText>
                </View>
              </Pressable>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={isJoined ? "Leave challenge" : "Join challenge"}
                onPress={() => setJoined((current) => ({ ...current, [challenge.id]: !current[challenge.id] }))}
                style={[styles.joinBtn, !isJoined && styles.joinBtnActive]}
              >
                <AppText style={[styles.joinLabel, !isJoined && styles.joinLabelActive]}>
                  {isJoined ? "Joined — leave challenge" : "Join challenge"}
                </AppText>
              </Pressable>
            </View>
          );
        })
      ) : posts.length === 0 ? (
        <View style={styles.padded}>
          <StatePanel
            title="You follow nobody yet"
            message="Discover has the whole community. Follow a few people and this becomes your own feed."
            action="Open discover"
            onAction={() => setTab("Discover")}
          />
        </View>
      ) : (
        posts.map((post, index) => {
          const liked = Boolean(likes[post.id]);
          const image = photos[index % Math.max(photos.length, 1)];
          return (
            <View key={post.id} style={styles.post}>
              <View style={styles.postHeader}>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={post.name}
                  onPress={() => router.push(`/community/member/${post.id}`)}
                  style={styles.avatar}
                >
                  <AppText style={styles.avatarText}>{post.initial}</AppText>
                </Pressable>
                <Pressable style={styles.postAuthor} onPress={() => router.push(`/community/member/${post.id}`)}>
                  <AppText style={styles.postName}>{post.name}</AppText>
                  <AppText style={styles.postHandle}>{post.handle} · {post.ago} ago</AppText>
                </Pressable>
                {post.tag ? (
                  <View style={styles.tagPill}>
                    <AppText style={styles.tagPillText}>{post.tag}</AppText>
                  </View>
                ) : null}
              </View>

              <Pressable
                accessibilityRole="button"
                accessibilityLabel="Open post"
                onPress={() => router.push(`/community/post/${post.id}`)}
                style={styles.postMedia}
              >
                {image ? <Photo source={image} /> : <View style={styles.mediaPlaceholder} />}
              </Pressable>

              <AppText style={styles.caption}>{post.caption}</AppText>

              <View style={styles.postActions}>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={liked ? "Unlike" : "Like"}
                  onPress={() => setLikes((current) => ({ ...current, [post.id]: !current[post.id] }))}
                  style={[styles.likeBtn, liked && styles.likeBtnActive]}
                >
                  <AppText style={[styles.likeLabel, liked && styles.likeLabelActive]}>♥ {post.likes + (liked ? 1 : 0)}</AppText>
                </Pressable>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel="Open comments"
                  onPress={() => router.push(`/community/post/${post.id}`)}
                  style={styles.commentBtn}
                >
                  <Glyph shape="moonDown" size={11} strokeWidth={2} color={colors.muted} />
                  <AppText style={styles.commentLabel}>{post.comments} comments</AppText>
                </Pressable>
              </View>
            </View>
          );
        })
      )}
      <View style={{ height: 40 }} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  headerWrap: { paddingHorizontal: spacing.xl, paddingTop: spacing.sm },
  hero: { flexDirection: "row", alignItems: "flex-end", justifyContent: "space-between", gap: spacing.lg, paddingHorizontal: spacing.xl, paddingBottom: spacing.lg, borderBottomWidth: 2, borderColor: colors.strokeStrong },
  heroCopy: { flex: 1, gap: spacing.xs },
  heroTitle: { fontSize: 40, lineHeight: 37 },
  addButton: { width: 48, height: 48, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center" },
  addGlyph: { color: colors.white, fontSize: 26, lineHeight: 26 },
  tabs: { flexDirection: "row", borderBottomWidth: 1, borderColor: colors.stroke },
  tab: { flex: 1, paddingVertical: spacing.md, paddingHorizontal: spacing.md, borderRightWidth: 1, borderColor: colors.stroke, alignItems: "flex-start" },
  tabActive: { backgroundColor: colors.rose, borderColor: colors.rose },
  tabLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  tabLabelActive: { color: colors.white },
  padded: { paddingHorizontal: spacing.xl },
  challenge: { borderBottomWidth: 1, borderColor: colors.stroke },
  challengeRow: { flexDirection: "row" },
  challengeMedia: { width: 112, backgroundColor: colors.surface, overflow: "hidden" },
  mediaPlaceholder: { flex: 1, backgroundColor: colors.surface },
  challengeCopy: { flex: 1, paddingHorizontal: spacing.lg, paddingVertical: spacing.lg },
  difficultyRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  difficulty: { color: colors.roseSoft, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase" },
  challengeTitle: { fontSize: 21, lineHeight: 21, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.6, textTransform: "uppercase", marginTop: 9 },
  challengeReward: { color: colors.muted, fontSize: 12, lineHeight: 18, marginTop: spacing.sm },
  challengeMeta: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase", marginTop: 9 },
  joinBtn: { height: 50, borderTopWidth: 1, borderColor: colors.stroke, justifyContent: "center", paddingHorizontal: spacing.lg },
  joinBtnActive: { backgroundColor: colors.rose },
  joinLabel: { color: colors.muted, fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: 1, textTransform: "uppercase" },
  joinLabelActive: { color: colors.white },
  post: { borderBottomWidth: 1, borderColor: colors.stroke },
  postHeader: { flexDirection: "row", alignItems: "center", gap: 11, paddingHorizontal: spacing.xl, paddingVertical: 13 },
  avatar: { width: 34, height: 34, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center" },
  avatarText: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 14 },
  postAuthor: { flex: 1 },
  postName: { fontFamily: fonts.black, fontWeight: "800", fontSize: 13, letterSpacing: -0.2 },
  postHandle: { color: colors.muted, fontSize: 10, letterSpacing: 0.8, textTransform: "uppercase", marginTop: 5 },
  tagPill: { borderWidth: 1, borderColor: colors.rose, paddingHorizontal: 9, paddingVertical: 8 },
  tagPillText: { color: colors.roseSoft, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  postMedia: { height: 300, backgroundColor: colors.surface, overflow: "hidden" },
  caption: { color: colors.ink, fontSize: 13, lineHeight: 20, paddingHorizontal: spacing.xl, paddingVertical: spacing.md },
  postActions: { flexDirection: "row", borderTopWidth: 1, borderColor: colors.stroke },
  likeBtn: { height: 50, paddingHorizontal: spacing.lg, borderRightWidth: 1, borderColor: colors.stroke, justifyContent: "center" },
  likeBtnActive: { backgroundColor: colors.rose },
  likeLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  likeLabelActive: { color: colors.white },
  commentBtn: { flex: 1, flexDirection: "row", alignItems: "center", gap: 9, height: 50, paddingHorizontal: spacing.lg },
  commentLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" }
});
