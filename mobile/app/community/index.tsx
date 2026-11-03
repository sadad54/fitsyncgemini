import { useState } from "react";
import { StyleSheet, View } from "react-native";
import { Redirect, router } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useChallenges, usePosts, useToggleJoin, useToggleLike } from "@/api/discover-queries";
import { AppText, Caption, Display, Em, Punch } from "@/components/AppText";
import { Button } from "@/components/Button";
import { IconButton } from "@/components/IconButton";
import { POP, PressableScale, Reveal } from "@/components/motion";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { Segmented } from "@/components/Segmented";
import { StatePanel } from "@/components/state-panel";
import { daysLeftLabel, toChallenge, toPost, type FeedTab, type Post } from "@/data/discover";
import { CloudOff, Heart, MessageCircle, Plus, Users } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";
import Animated, { useAnimatedStyle, useSharedValue, withSequence, withSpring } from "react-native-reanimated";

const TABS: FeedTab[] = ["Following", "Discover", "Challenges"];

export default function CommunityFeed() {
  const token = useAuthStore((state) => state.token);
  const [tab, setTab] = useState<FeedTab>("Following");
  const feed = tab === "Following" ? "following" : "discover";
  const postsQuery = usePosts(feed, tab !== "Challenges");
  const challengesQuery = useChallenges();
  const toggleLike = useToggleLike();
  const toggleJoin = useToggleJoin();

  const posts = (postsQuery.data ?? []).map((post) => toPost(post));
  const challenges = (challengesQuery.data ?? []).map(toChallenge);
  const active = tab === "Challenges" ? challengesQuery : postsQuery;

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen>
      <PushHeader title="Community" onBack={() => router.back()} />
      <Reveal>
        <View style={styles.hero}>
          <View style={styles.flex}>
            <Punch style={styles.kicker}>Real closets, real outfits</Punch>
            <Display style={styles.heroTitle}>What people <Em>actually</Em> wear</Display>
          </View>
          <IconButton icon={Plus} label="Share a look" tone="accent" size={52} onPress={() => router.push("/community/create")} />
        </View>
      </Reveal>
      <Segmented<FeedTab> value={tab} onChange={setTab} options={TABS.map((t) => ({ value: t, label: t }))} />

      {active.isError ? (
        <StatePanel icon={CloudOff} title="Couldn't load the community" message={active.error instanceof Error ? active.error.message : "Try again in a moment."}
          action="Try again" onAction={() => active.refetch()} />
      ) : active.isLoading ? (
        <StatePanel title="Loading…" message="Fetching the latest from the community." />
      ) : tab === "Challenges" ? (
        challenges.length === 0 ? (
          <StatePanel icon={Users} title="No open challenges" message="New challenges appear here when they start." />
        ) : (
        <View style={styles.list}>
          {challenges.map((challenge, index) => {
            const isJoined = challenge.joined;
            return (
              <Reveal key={challenge.id} index={index}>
                <View style={styles.challenge}>
                  <PressableScale accessibilityRole="button" accessibilityLabel={challenge.title}
                    onPress={() => router.push(`/community/challenge/${challenge.id}`)} style={styles.challengeRow}>
                    <View style={styles.challengeMedia}>
                      {challenge.imageUrl ? <Photo source={mediaUrl(challenge.imageUrl)!} /> : <View style={styles.placeholder} />}
                    </View>
                    <View style={styles.challengeCopy}>
                      <Punch style={styles.difficulty}>{challenge.difficulty} · {daysLeftLabel(challenge.days)}</Punch>
                      <AppText style={styles.challengeTitle}>{challenge.title}</AppText>
                      <Caption>{challenge.reward}</Caption>
                      <View style={styles.metaRow}>
                        <Users size={14} color={colors.muted} />
                        <Caption>{challenge.participants.toLocaleString()} joined</Caption>
                      </View>
                    </View>
                  </PressableScale>
                  <Button title={isJoined ? "Joined · tap to leave" : "Join challenge"} compact variant={isJoined ? "secondary" : "primary"}
                    onPress={() => toggleJoin.mutate({ challengeId: challenge.id, joined: !isJoined })} />
                </View>
              </Reveal>
            );
          })}
        </View>
        )
      ) : posts.length === 0 && tab === "Following" ? (
        <StatePanel icon={Users} title="You follow nobody yet" message="Discover has the whole community. Follow a few people and this becomes your own feed."
          action="Open Discover" onAction={() => setTab("Discover")} />
      ) : posts.length === 0 ? (
        <StatePanel icon={Users} title="No posts yet" message="Be the first to share a look from your closet." action="Share a look" onAction={() => router.push("/community/create")} />
      ) : (
        <View style={styles.list}>
          {posts.map((post, index) => (
            <Reveal key={post.id} index={index}>
              <PostCard post={post} onLike={() => toggleLike.mutate({ postId: post.id, liked: !post.liked })} />
            </Reveal>
          ))}
        </View>
      )}
    </Screen>
  );
}

function PostCard({ post, onLike }: { post: Post; onLike: () => void }) {
  const liked = post.liked;
  const image = mediaUrl(post.imageUrl) ?? undefined;
  const pop = useSharedValue(1);
  const heart = useAnimatedStyle(() => ({ transform: [{ scale: pop.value }] }));
  return (
    <View style={styles.post}>
      <View style={styles.postHeader}>
        <PressableScale accessibilityRole="button" accessibilityLabel={`${post.name}'s profile`} onPress={() => router.push(`/community/member/${post.authorId}`)} style={styles.author}>
          <View style={styles.avatar}><AppText style={styles.avatarText}>{post.initial}</AppText></View>
          <View style={styles.flex}>
            <AppText style={styles.postName}>{post.name}</AppText>
            <Caption>{post.handle} · {post.ago} ago</Caption>
          </View>
        </PressableScale>
        {post.tag ? <View style={styles.tagPill}><AppText style={styles.tagText}>{post.tag}</AppText></View> : null}
      </View>
      {image ? (
        <PressableScale accessibilityRole="button" accessibilityLabel="Open post" scaleTo={0.985} onPress={() => router.push(`/community/post/${post.id}`)} style={styles.postMedia}>
          <Photo source={image} />
        </PressableScale>
      ) : null}
      <PressableScale accessibilityRole="button" accessibilityLabel="Open post" scaleTo={0.99} onPress={() => router.push(`/community/post/${post.id}`)}>
        <AppText style={styles.caption}>{post.caption}</AppText>
      </PressableScale>
      <View style={styles.actions}>
        <PressableScale accessibilityRole="button" accessibilityLabel={liked ? "Unlike" : "Like"} accessibilityState={{ selected: liked }}
          onPress={() => { pop.value = withSequence(withSpring(1.35, POP), withSpring(1, POP)); onLike(); }} style={[styles.action, liked && styles.actionLiked]}>
          <Animated.View style={heart}><Heart size={17} color={liked ? colors.ink : colors.inkSoft} fill={liked ? colors.flare : "transparent"} /></Animated.View>
          <AppText style={styles.actionText}>{post.likes}</AppText>
        </PressableScale>
        <PressableScale accessibilityRole="button" accessibilityLabel={`${post.comments} comments`} onPress={() => router.push(`/community/post/${post.id}`)} style={styles.action}>
          <MessageCircle size={17} color={colors.inkSoft} />
          <AppText style={styles.actionText}>{post.comments}</AppText>
        </PressableScale>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  hero: { flexDirection: "row", alignItems: "flex-end", gap: spacing.md },
  kicker: { color: colors.muted, marginBottom: spacing.xs },
  heroTitle: { fontSize: 42, lineHeight: 42 },
  list: { gap: spacing.lg },
  challenge: { backgroundColor: colors.surface, borderRadius: radius.xl, padding: spacing.sm, gap: spacing.sm, borderWidth: 1, borderColor: colors.stroke },
  challengeRow: { flexDirection: "row", gap: spacing.md },
  challengeMedia: { width: 104, height: 128, borderRadius: radius.lg, overflow: "hidden", backgroundColor: colors.canvasSoft },
  placeholder: { flex: 1, backgroundColor: colors.canvasSoft },
  challengeCopy: { flex: 1, gap: 6, paddingVertical: spacing.xs },
  difficulty: { color: colors.muted, fontSize: 9, lineHeight: 11 },
  challengeTitle: { fontFamily: fonts.serif, fontSize: 24, lineHeight: 26 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: 6 },
  post: { backgroundColor: colors.surface, borderRadius: radius.xl, overflow: "hidden", borderWidth: 1, borderColor: colors.stroke },
  postHeader: { flexDirection: "row", alignItems: "center", gap: spacing.sm, padding: spacing.md },
  author: { flexDirection: "row", alignItems: "center", gap: spacing.sm, minHeight: 44 },
  avatar: { width: 40, height: 40, borderRadius: 20, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center", borderWidth: 1.5, borderColor: colors.ink },
  avatarText: { fontFamily: fonts.serif, fontSize: 20, lineHeight: 24 },
  postName: { fontSize: 15, fontFamily: fonts.semibold, fontWeight: "600" },
  tagPill: { marginLeft: "auto", backgroundColor: colors.canvas, borderRadius: radius.pill, paddingHorizontal: spacing.md, height: 28, justifyContent: "center" },
  tagText: { fontSize: 12, color: colors.inkSoft, fontFamily: fonts.medium },
  postMedia: { height: 320, backgroundColor: colors.canvasSoft, marginHorizontal: spacing.sm, borderRadius: radius.lg, overflow: "hidden" },
  caption: { fontSize: 15, lineHeight: 22, paddingHorizontal: spacing.lg, paddingTop: spacing.md },
  actions: { flexDirection: "row", gap: spacing.sm, padding: spacing.md },
  action: { flexDirection: "row", alignItems: "center", gap: 6, height: 44, paddingHorizontal: spacing.md, borderRadius: radius.pill, backgroundColor: colors.canvas },
  actionLiked: { backgroundColor: colors.flareWash },
  actionText: { fontSize: 14, fontFamily: fonts.semibold, fontVariant: ["tabular-nums"] }
});
