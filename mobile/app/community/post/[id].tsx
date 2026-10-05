import { useMemo, useState } from "react";
import { KeyboardAvoidingView, StyleSheet, TextInput, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText, Caption, Punch } from "@/components/AppText";
import { IconButton } from "@/components/IconButton";
import { PressableScale, Reveal } from "@/components/motion";
import { Photo } from "@/components/Photo";
import { PreviewNote } from "@/components/PreviewNote";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_COMMENTS, SEED_POSTS } from "@/data/discover";
import { Heart, Send } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";

export default function PostDetail() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const closet = useCloset();

  const post = SEED_POSTS.find((entry) => entry.id === id) ?? SEED_POSTS[0];
  const photos = useMemo(
    () => (closet.data?.items ?? []).map((item) => mediaUrl(item.image_url)).filter(Boolean) as string[],
    [closet.data]
  );
  const image = photos.length ? photos[SEED_POSTS.indexOf(post) % photos.length] : undefined;

  const [liked, setLiked] = useState(false);
  const [draft, setDraft] = useState("");
  const [extra, setExtra] = useState<typeof SEED_COMMENTS>([]);
  const [commentLikes, setCommentLikes] = useState<Record<string, boolean>>({});
  const comments = [...SEED_COMMENTS, ...extra];

  function addComment() {
    if (!draft.trim()) return;
    setExtra((current) => [...current, { id: `me-${current.length}`, name: "You", initial: "Y", ago: "now", text: draft.trim(), likes: 0 }]);
    setDraft("");
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  const composer = (
    <View style={styles.composer}>
      <TextInput accessibilityLabel="Add a comment" value={draft} onChangeText={setDraft} placeholder="Add a comment" placeholderTextColor={colors.faint}
        onSubmitEditing={addComment} returnKeyType="send" style={styles.input} />
      <IconButton icon={Send} label="Send comment" tone="ink" size={48} onPress={addComment} />
    </View>
  );

  return (
    <KeyboardAvoidingView behavior={process.env.EXPO_OS === "ios" ? "padding" : undefined} style={styles.flex}>
      <Screen footer={composer}>
        <PushHeader title="Post" onBack={() => router.back()} />
        <PreviewNote />
        <Reveal>
          <View style={styles.card}>
            <PressableScale accessibilityRole="button" accessibilityLabel={`${post.name}'s profile`} onPress={() => router.push(`/community/member/${post.id}`)} style={styles.author}>
              <View style={styles.avatar}><AppText style={styles.avatarText}>{post.initial}</AppText></View>
              <View style={styles.flex}>
                <AppText style={styles.name}>{post.name}</AppText>
                <Caption>{post.handle} · {post.ago} ago</Caption>
              </View>
              {post.tag ? <View style={styles.tagPill}><AppText style={styles.tagText}>{post.tag}</AppText></View> : null}
            </PressableScale>
            <View style={styles.media}>{image ? <Photo source={image} /> : <View style={styles.placeholder} />}</View>
            <AppText style={styles.caption}>{post.caption}</AppText>
            <View style={styles.metrics}>
              <PressableScale accessibilityRole="button" accessibilityLabel={liked ? "Unlike" : "Like"} accessibilityState={{ selected: liked }}
                onPress={() => setLiked((v) => !v)} style={[styles.like, liked && styles.likeOn]}>
                <Heart size={17} color={colors.ink} fill={liked ? colors.flare : "transparent"} />
                <AppText style={styles.likeText}>{post.likes + (liked ? 1 : 0)}</AppText>
              </PressableScale>
              <Punch style={styles.count}>{comments.length} comments</Punch>
            </View>
          </View>
        </Reveal>

        <View style={styles.comments}>
          {comments.map((comment) => {
            const on = Boolean(commentLikes[comment.id]);
            return (
              <View key={comment.id} style={styles.comment}>
                <View style={styles.commentAvatar}><AppText style={styles.commentInitial}>{comment.initial}</AppText></View>
                <View style={styles.flex}>
                  <AppText style={styles.commentName}>{comment.name} <AppText style={styles.commentAgo}>{comment.ago}</AppText></AppText>
                  <AppText style={styles.commentText}>{comment.text}</AppText>
                </View>
                <PressableScale accessibilityRole="button" accessibilityLabel="Like comment" accessibilityState={{ selected: on }}
                  onPress={() => setCommentLikes((c) => ({ ...c, [comment.id]: !c[comment.id] }))} style={styles.commentLike}>
                  <Heart size={14} color={on ? colors.flare : colors.muted} fill={on ? colors.flare : "transparent"} />
                  <Caption>{comment.likes + (on ? 1 : 0)}</Caption>
                </PressableScale>
              </View>
            );
          })}
        </View>
      </Screen>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.canvas },
  card: { backgroundColor: colors.surface, borderRadius: radius.xl, padding: spacing.sm, gap: spacing.sm, borderWidth: 1, borderColor: colors.stroke },
  author: { flexDirection: "row", alignItems: "center", gap: spacing.sm, padding: spacing.xs, minHeight: 48 },
  avatar: { width: 42, height: 42, borderRadius: 21, backgroundColor: colors.accent, alignItems: "center", justifyContent: "center", borderWidth: 1.5, borderColor: colors.ink },
  avatarText: { fontFamily: fonts.serif, fontSize: 22, lineHeight: 26 },
  name: { fontSize: 15, fontFamily: fonts.semibold, fontWeight: "600" },
  tagPill: { backgroundColor: colors.canvas, borderRadius: radius.pill, paddingHorizontal: spacing.md, height: 28, justifyContent: "center" },
  tagText: { fontSize: 12, color: colors.inkSoft, fontFamily: fonts.medium },
  media: { height: 360, borderRadius: radius.lg, overflow: "hidden", backgroundColor: colors.canvasSoft },
  placeholder: { flex: 1, backgroundColor: colors.canvasSoft },
  caption: { fontSize: 16, lineHeight: 23, paddingHorizontal: spacing.sm, paddingTop: spacing.xs },
  metrics: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", padding: spacing.xs },
  like: { flexDirection: "row", alignItems: "center", gap: 6, height: 44, paddingHorizontal: spacing.md, borderRadius: radius.pill, backgroundColor: colors.canvas },
  likeOn: { backgroundColor: colors.flareWash },
  likeText: { fontSize: 14, fontFamily: fonts.semibold, fontVariant: ["tabular-nums"] },
  count: { color: colors.muted, paddingRight: spacing.sm },
  comments: { gap: spacing.xs },
  comment: { flexDirection: "row", gap: spacing.md, paddingVertical: spacing.md, borderBottomWidth: 1, borderColor: colors.stroke },
  commentAvatar: { width: 34, height: 34, borderRadius: 17, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke, alignItems: "center", justifyContent: "center" },
  commentInitial: { fontFamily: fonts.serif, fontSize: 17 },
  commentName: { fontSize: 14, fontFamily: fonts.semibold, fontWeight: "600" },
  commentAgo: { fontSize: 13, color: colors.muted, fontFamily: fonts.regular, fontWeight: "400" },
  commentText: { fontSize: 15, lineHeight: 21, color: colors.inkSoft, marginTop: 2 },
  commentLike: { alignItems: "center", justifyContent: "center", gap: 2, minWidth: 44, minHeight: 44 },
  composer: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  input: { flex: 1, height: 48, borderRadius: radius.pill, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke, paddingHorizontal: spacing.lg, fontSize: 15, color: colors.ink, fontFamily: fonts.regular }
});
