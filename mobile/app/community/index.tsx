import { useMemo, useState } from "react";
import { StyleSheet, View } from "react-native";
import { Redirect, router } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText, Caption, Display, Em, Punch } from "@/components/AppText";
import { Button } from "@/components/Button";
import { IconButton } from "@/components/IconButton";
import { POP, PressableScale, Reveal } from "@/components/motion";
import { Photo } from "@/components/Photo";
import { PreviewNote } from "@/components/PreviewNote";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { Segmented } from "@/components/Segmented";
import { StatePanel } from "@/components/state-panel";
import { SEED_CHALLENGES, SEED_POSTS, type FeedTab, type Post } from "@/data/discover";
import { Heart, MessageCircle, Plus, Users } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";
import Animated, { useAnimatedStyle, useSharedValue, withSequence, withSpring } from "react-native-reanimated";

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
  const posts = useMemo(() => SEED_POSTS.filter((post) => tab === "Discover" || post.following), [tab]);

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
      <PreviewNote>Sample members and posts. Photos are from your own closet as stand-ins.</PreviewNote>
      <Segmented<FeedTab> value={tab} onChange={setTab} options={TABS.map((t) => ({ value: t, label: t }))} />

      {tab === "Challenges" ? (
        <View style={styles.list}>
          {SEED_CHALLENGES.map((challenge, index) => {
            const isJoined = Boolean(joined[challenge.id]);
            return (
              <Reveal key={challenge.id} index={index}>
                <View style={styles.challenge}>
                  <PressableScale accessibilityRole="button" accessibilityLabel={challenge.title}
                    onPress={() => router.push(`/community/challenge/${challenge.id}`)} style={styles.challengeRow}>
                    <View style={styles.challengeMedia}>
                      {photos.length ? <Photo source={photos[index % photos.length]} /> : <View style={styles.placeholder} />}
                    </View>
                    <View style={styles.challengeCopy}>
                      <Punch style={styles.difficulty}>{challenge.difficulty} · {challenge.days} days left</Punch>
                      <AppText style={styles.challengeTitle}>{challenge.title}</AppText>
                      <Caption>{challenge.reward}</Caption>
                      <View style={styles.metaRow}>
                        <Users size={14} color={colors.muted} />
                        <Caption>{(challenge.participants + (isJoined ? 1 : 0)).toLocaleString()} joined</Caption>
                      </View>
                    </View>
                  </PressableScale>
                  <Button title={isJoined ? "Joined · tap to leave" : "Join challenge"} compact variant={isJoined ? "secondary" : "primary"}
                    onPress={() => setJoined((current) => ({ ...current, [challenge.id]: !current[challenge.id] }))} />
                </View>
              </Reveal>
            );
          })}
        </View>
      ) : posts.length === 0 ? (
        <StatePanel icon={Users} title="You follow nobody yet" message="Discover has the whole community. Follow a few people and this becomes your own feed."
          action="Open Discover" onAction={() => setTab("Discover")} />
      ) : (
        <View style={styles.list}>
          {posts.map((post, index) => (
            <Reveal key={post.id} index={index}>
              <PostCard post={post} image={photos.length ? photos[index % photos.length] : undefined}
                liked={Boolean(likes[post.id])} onLike={() => setLikes((current) => ({ ...current, [post.id]: !current[post.id] }))} />
            </Reveal>
          ))}
        </View>
      )}
    </Screen>
  );
}

function PostCard({ post, image, liked, onLike }: { post: Post; image?: string; liked: boolean; onLike: () => void }) {
  const pop = useSharedValue(1);
  const heart = useAnimatedStyle(() => ({ transform: [{ scale: pop.value }] }));
  return (
    <View style={styles.post}>
      <View style={styles.postHeader}>
        <PressableScale accessibilityRole="button" accessibilityLabel={`${post.name}'s profile`} onPress={() => router.push(`/community/member/${post.id}`)} style={styles.author}>
          <View style={styles.avatar}><AppText style={styles.avatarText}>{post.initial}</AppText></View>
          <View style={styles.flex}>
            <AppText style={styles.postName}>{post.name}</AppText>
            <Caption>{post.handle} · {post.ago} ago</Caption>
          </View>
        </PressableScale>
        {post.tag ? <View style={styles.tagPill}><AppText style={styles.tagText}>{post.tag}</AppText></View> : null}
      </View>
      <PressableScale accessibilityRole="button" accessibilityLabel="Open post" scaleTo={0.985} onPress={() => router.push(`/community/post/${post.id}`)} style={styles.postMedia}>
        {image ? <Photo source={image} /> : <View style={styles.placeholder} />}
      </PressableScale>
      <AppText style={styles.caption}>{post.caption}</AppText>
      <View style={styles.actions}>
        <PressableScale accessibilityRole="button" accessibilityLabel={liked ? "Unlike" : "Like"} accessibilityState={{ selected: liked }}
          onPress={() => { pop.value = withSequence(withSpring(1.35, POP), withSpring(1, POP)); onLike(); }} style={[styles.action, liked && styles.actionLiked]}>
          <Animated.View style={heart}><Heart size={17} color={liked ? colors.ink : colors.inkSoft} fill={liked ? colors.flare : "transparent"} /></Animated.View>
          <AppText style={styles.actionText}>{post.likes + (liked ? 1 : 0)}</AppText>
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
