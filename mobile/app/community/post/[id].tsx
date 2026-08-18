import { useMemo, useState } from "react";
import { KeyboardAvoidingView, Pressable, StyleSheet, TextInput, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText } from "@/components/AppText";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_COMMENTS, SEED_POSTS } from "@/data/discover";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

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
  const image = photos[SEED_POSTS.indexOf(post) % Math.max(photos.length, 1)];

  const [liked, setLiked] = useState(false);
  const [draft, setDraft] = useState("");
  const [extra, setExtra] = useState<typeof SEED_COMMENTS>([]);
  const [commentLikes, setCommentLikes] = useState<Record<string, boolean>>({});

  const comments = [...SEED_COMMENTS, ...extra];

  function addComment() {
    if (!draft.trim()) return;
    setExtra((current) => [
      ...current,
      { id: `me-${current.length}`, name: "You", initial: "Y", ago: "now", text: draft.trim(), likes: 0 }
    ]);
    setDraft("");
  }

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <KeyboardAvoidingView behavior={process.env.EXPO_OS === "ios" ? "padding" : undefined} style={styles.flex}>
      <Screen scroll bottomInset={false} contentStyle={styles.screen}>
        <View style={styles.headerWrap}>
          <PushHeader title="Post" onBack={() => router.back()} />
        </View>

        <View style={styles.postHeader}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={post.name}
            onPress={() => router.push(`/community/member/${post.id}`)}
            style={styles.avatar}
          >
            <AppText style={styles.avatarText}>{post.initial}</AppText>
          </Pressable>
          <View style={styles.author}>
            <AppText style={styles.name}>{post.name}</AppText>
            <AppText style={styles.handle}>{post.handle} · {post.ago} ago</AppText>
          </View>
          {post.tag ? (
            <View style={styles.tagPill}>
              <AppText style={styles.tagPillText}>{post.tag}</AppText>
            </View>
          ) : null}
        </View>

        <View style={styles.media}>{image ? <Photo source={image} /> : <View style={styles.mediaPlaceholder} />}</View>

        <AppText style={styles.caption}>{post.caption}</AppText>

        <View style={styles.metrics}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={liked ? "Unlike" : "Like"}
            onPress={() => setLiked((v) => !v)}
            style={[styles.likeBtn, liked && styles.likeBtnActive]}
          >
            <AppText style={[styles.likeLabel, liked && styles.likeLabelActive]}>♥ {post.likes + (liked ? 1 : 0)}</AppText>
          </Pressable>
          <View style={styles.countCell}>
            <AppText style={styles.countLabel}>{comments.length} comments</AppText>
          </View>
        </View>

        {comments.map((comment) => {
          const commentLiked = Boolean(commentLikes[comment.id]);
          return (
            <View key={comment.id} style={styles.comment}>
              <View style={styles.commentAvatar}>
                <AppText style={styles.commentAvatarText}>{comment.initial}</AppText>
              </View>
              <View style={styles.commentBody}>
                <AppText style={styles.commentName}>
                  {comment.name}
                  <AppText style={styles.commentAgo}>  {comment.ago}</AppText>
                </AppText>
                <AppText style={styles.commentText}>{comment.text}</AppText>
              </View>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel="Like comment"
                onPress={() => setCommentLikes((current) => ({ ...current, [comment.id]: !current[comment.id] }))}
              >
                <AppText style={[styles.commentLike, commentLiked && styles.commentLikeActive]}>
                  ♥ {comment.likes + (commentLiked ? 1 : 0)}
                </AppText>
              </Pressable>
            </View>
          );
        })}

        <View style={styles.composer}>
          <TextInput
            accessibilityLabel="Add a comment"
            value={draft}
            onChangeText={setDraft}
            placeholder="Add a comment"
            placeholderTextColor={colors.faint}
            onSubmitEditing={addComment}
            returnKeyType="send"
            style={styles.input}
          />
          <Pressable accessibilityRole="button" accessibilityLabel="Send comment" onPress={addComment} style={styles.send}>
            <AppText style={styles.sendGlyph}>→</AppText>
          </Pressable>
        </View>
      </Screen>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.canvas },
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  headerWrap: { paddingHorizontal: spacing.xl, paddingTop: spacing.sm },
  postHeader: { flexDirection: "row", alignItems: "center", gap: 11, paddingHorizontal: spacing.xl, paddingVertical: 13 },
  avatar: { width: 38, height: 38, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center" },
  avatarText: { color: colors.white, fontFamily: fonts.black, fontWeight: "800", fontSize: 15 },
  author: { flex: 1 },
  name: { fontFamily: fonts.black, fontWeight: "800", fontSize: 14, letterSpacing: -0.2 },
  handle: { color: colors.muted, fontSize: 10, letterSpacing: 0.8, textTransform: "uppercase", marginTop: 5 },
  tagPill: { borderWidth: 1, borderColor: colors.rose, paddingHorizontal: 9, paddingVertical: 8 },
  tagPillText: { color: colors.roseSoft, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  media: { height: 326, backgroundColor: colors.surface, overflow: "hidden" },
  mediaPlaceholder: { flex: 1, backgroundColor: colors.surface },
  caption: { color: colors.ink, fontSize: 14, lineHeight: 22, paddingHorizontal: spacing.xl, paddingVertical: spacing.lg },
  metrics: { flexDirection: "row", borderTopWidth: 1, borderColor: colors.stroke, borderBottomWidth: 2, borderBottomColor: colors.strokeStrong },
  likeBtn: { height: 52, paddingHorizontal: spacing.lg, borderRightWidth: 1, borderColor: colors.stroke, justifyContent: "center" },
  likeBtnActive: { backgroundColor: colors.rose },
  likeLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  likeLabelActive: { color: colors.white },
  countCell: { flex: 1, height: 52, justifyContent: "center", paddingHorizontal: spacing.lg },
  countLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.2, textTransform: "uppercase" },
  comment: { flexDirection: "row", gap: spacing.md, paddingHorizontal: spacing.xl, paddingVertical: spacing.md, borderBottomWidth: 1, borderColor: colors.stroke },
  commentAvatar: { width: 30, height: 30, backgroundColor: colors.surfaceElevated, alignItems: "center", justifyContent: "center" },
  commentAvatarText: { color: colors.ink, fontFamily: fonts.black, fontWeight: "800", fontSize: 12 },
  commentBody: { flex: 1 },
  commentName: { fontFamily: fonts.black, fontWeight: "800", fontSize: 12, letterSpacing: -0.2 },
  commentAgo: { color: colors.muted, fontSize: 10, letterSpacing: 0.8, textTransform: "uppercase", fontFamily: fonts.regular, fontWeight: "400" },
  commentText: { color: colors.ink, fontSize: 13, lineHeight: 19, marginTop: 6 },
  commentLike: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1 },
  commentLikeActive: { color: colors.roseSoft },
  composer: { flexDirection: "row", borderTopWidth: 2, borderColor: colors.strokeStrong, paddingHorizontal: spacing.xl, paddingTop: spacing.md, paddingBottom: spacing.xxl, marginTop: "auto" },
  input: { flex: 1, height: 48, borderWidth: 1, borderColor: colors.stroke, borderLeftWidth: 2, borderLeftColor: colors.strokeStrong, backgroundColor: colors.surface, color: colors.ink, paddingHorizontal: spacing.md, fontSize: 14, fontFamily: fonts.medium },
  send: { width: 56, height: 48, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center" },
  sendGlyph: { color: colors.white, fontSize: 17 }
});
