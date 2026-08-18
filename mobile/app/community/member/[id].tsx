import { useMemo, useState } from "react";
import { Pressable, StyleSheet, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_MEMBER, SEED_POSTS } from "@/data/discover";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, spacing } from "@/theme";

const GRID_HEIGHTS = [232, 206, 198, 228];

export default function MemberProfile() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const closet = useCloset();
  const [following, setFollowing] = useState(false);

  const post = SEED_POSTS.find((entry) => entry.id === id);
  const member = post
    ? { ...SEED_MEMBER, initial: post.initial, handle: post.handle, name: post.name }
    : SEED_MEMBER;

  const photos = useMemo(
    () => (closet.data?.items ?? []).map((item) => mediaUrl(item.image_url)).filter(Boolean) as string[],
    [closet.data]
  );

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen scroll bottomInset={false} contentStyle={styles.screen}>
      <View style={styles.headerWrap}>
        <PushHeader title="Member" onBack={() => router.back()} />
      </View>

      <View style={styles.identity}>
        <View style={styles.avatar}>
          <AppText style={styles.avatarText}>{member.initial}</AppText>
        </View>
        <View style={styles.identityCopy}>
          <Eyebrow style={styles.handle}>{member.handle}</Eyebrow>
          <Title style={styles.name}>{member.name}</Title>
          <AppText style={styles.bio}>{member.bio}</AppText>
        </View>
      </View>

      <View style={styles.metrics}>
        <Metric value={String(member.posts)} label="posts" />
        <Metric value={member.followers} label="followers" />
        <Metric value={String(member.challenges)} label="challenges" last />
      </View>

      <Pressable
        accessibilityRole="button"
        accessibilityLabel={following ? "Unfollow" : "Follow"}
        onPress={() => setFollowing((v) => !v)}
        style={[styles.followBtn, following ? styles.followBtnOn : styles.followBtnOff]}
      >
        <AppText style={[styles.followLabel, !following && styles.followLabelActive]}>
          {following ? `Following — tap to unfollow` : `Follow ${member.name.split(" ")[0]}`}
        </AppText>
      </Pressable>

      <AppText style={styles.postsLabel}>Their posts</AppText>
      <View style={styles.grid}>
        {GRID_HEIGHTS.map((height, index) => {
          const image = photos[index % Math.max(photos.length, 1)];
          return (
            <Pressable
              key={index}
              accessibilityRole="button"
              accessibilityLabel="Open post"
              onPress={() => router.push(`/community/post/${SEED_POSTS[index % SEED_POSTS.length].id}`)}
              style={[styles.gridTile, { height }]}
            >
              {image ? <Photo source={image} /> : <View style={styles.mediaPlaceholder} />}
            </Pressable>
          );
        })}
      </View>
      <View style={{ height: 40 }} />
    </Screen>
  );
}

function Metric({ value, label, last }: { value: string; label: string; last?: boolean }) {
  return (
    <View style={[styles.metric, last && styles.metricLast]}>
      <AppText selectable style={styles.metricValue}>{value}</AppText>
      <AppText style={styles.metricLabel}>{label}</AppText>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { paddingHorizontal: 0, paddingTop: 0, gap: 0 },
  headerWrap: { paddingHorizontal: spacing.xl, paddingTop: spacing.sm },
  identity: { flexDirection: "row", alignItems: "center", gap: spacing.lg, paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.lg, borderBottomWidth: 1, borderColor: colors.stroke },
  avatar: { width: 66, height: 66, backgroundColor: colors.rose, alignItems: "center", justifyContent: "center" },
  avatarText: { color: colors.white, fontSize: 26, fontFamily: fonts.black, fontWeight: "800" },
  identityCopy: { flex: 1, gap: spacing.xs },
  handle: { color: colors.muted },
  name: { fontSize: 30, lineHeight: 28 },
  bio: { color: colors.muted, fontSize: 12, lineHeight: 17, marginTop: spacing.xs },
  metrics: { flexDirection: "row", borderBottomWidth: 1, borderColor: colors.stroke },
  metric: { flex: 1, paddingVertical: spacing.lg, paddingHorizontal: spacing.lg, borderRightWidth: 1, borderColor: colors.stroke },
  metricLast: { borderRightWidth: 0 },
  metricValue: { fontSize: 32, lineHeight: 32, fontFamily: fonts.black, fontWeight: "800", letterSpacing: -0.9, fontVariant: ["tabular-nums"] },
  metricLabel: { color: colors.muted, fontSize: 9, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.4, textTransform: "uppercase", marginTop: 7 },
  followBtn: { height: 56, justifyContent: "center", paddingHorizontal: spacing.xl },
  followBtnOff: { backgroundColor: colors.rose },
  followBtnOn: { backgroundColor: "transparent", borderTopWidth: 2, borderBottomWidth: 2, borderColor: colors.strokeStrong },
  followLabel: { color: colors.ink, fontFamily: fonts.black, fontWeight: "800", fontSize: 13, letterSpacing: 1.3, textTransform: "uppercase" },
  followLabelActive: { color: colors.white },
  postsLabel: { color: colors.muted, fontSize: 10, fontFamily: fonts.bold, fontWeight: "700", letterSpacing: 1.6, textTransform: "uppercase", paddingHorizontal: spacing.xl, paddingTop: spacing.lg, paddingBottom: spacing.sm },
  grid: { flexDirection: "row", flexWrap: "wrap" },
  gridTile: { width: "50%", backgroundColor: colors.surface, borderRightWidth: 1, borderBottomWidth: 1, borderColor: colors.stroke, overflow: "hidden" },
  mediaPlaceholder: { flex: 1, backgroundColor: colors.surface }
});
