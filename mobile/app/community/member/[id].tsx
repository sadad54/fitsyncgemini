import { StyleSheet, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useMember, useToggleFollow } from "@/api/discover-queries";
import { AppText, Punch, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { PressableScale, Reveal } from "@/components/motion";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { handleOf, initialOf } from "@/data/discover";
import { Check, CloudOff, Plus } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";

const GRID_HEIGHTS = [232, 196, 198, 236];

export default function MemberProfile() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const memberQuery = useMember(id);
  const toggleFollow = useToggleFollow();
  const member = memberQuery.data;
  const posts = member?.posts ?? [];

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  if (!member) {
    return (
      <Screen>
        <PushHeader title="Member" onBack={() => router.back()} />
        {memberQuery.isError
          ? <StatePanel icon={CloudOff} title="Couldn't open this profile" message={memberQuery.error instanceof Error ? memberQuery.error.message : "Try again in a moment."}
              action="Try again" onAction={() => memberQuery.refetch()} />
          : <StatePanel title="Loading…" message="Opening the profile." />}
      </Screen>
    );
  }

  const firstName = member.name.split(" ")[0];
  return (
    <Screen>
      <PushHeader title="Member" onBack={() => router.back()} />
      <Reveal>
        <View style={styles.card}>
          <View style={styles.avatar}><AppText style={styles.avatarText}>{initialOf(member.name)}</AppText></View>
          <Punch style={styles.handle}>{handleOf(member.name)}</Punch>
          <Title style={styles.name}>{member.name}</Title>
          {member.style_tags.length ? <AppText style={styles.bio}>{member.style_tags.join(" · ")}</AppText> : null}
          <View style={styles.metrics}>
            <Metric value={compact(member.posts_count)} label="Posts" />
            <View style={styles.rule} />
            <Metric value={compact(member.followers_count)} label="Followers" />
            <View style={styles.rule} />
            <Metric value={compact(member.challenges_count)} label="Challenges" />
          </View>
          {member.is_self ? null : (
            <Button title={member.following ? "Following" : `Follow ${firstName}`} icon={member.following ? Check : Plus}
              variant={member.following ? "stage" : "accent"} onPress={() => toggleFollow.mutate({ userId: member.user_id, following: !member.following })} />
          )}
        </View>
      </Reveal>

      <View style={styles.posts}>
        <Punch style={styles.label}>Their posts</Punch>
        {posts.length === 0 ? <AppText style={styles.empty}>{member.is_self ? "You haven't posted yet." : `${firstName} hasn't posted yet.`}</AppText> : (
          <View style={styles.grid}>
            {[0, 1].map((col) => (
              <View key={col} style={styles.column}>
                {posts.filter((_, i) => i % 2 === col).map((post, i) => {
                  const image = mediaUrl(post.image_url);
                  return (
                    <PressableScale key={post.id} accessibilityRole="button" accessibilityLabel="Open post"
                      onPress={() => router.push(`/community/post/${post.id}`)} style={[styles.tile, { height: GRID_HEIGHTS[(i * 2 + col) % GRID_HEIGHTS.length] }]}>
                      {image ? <Photo source={image} /> : <View style={styles.textTile}><AppText numberOfLines={6} style={styles.textTileCopy}>{post.content}</AppText></View>}
                    </PressableScale>
                  );
                })}
              </View>
            ))}
          </View>
        )}
      </View>
    </Screen>
  );
}

function compact(n: number) {
  return n >= 1000 ? `${(n / 1000).toFixed(n >= 10_000 ? 0 : 1)}k` : String(n);
}

function Metric({ value, label }: { value: string; label: string }) {
  return (
    <View style={styles.metric}>
      <AppText style={styles.metricValue}>{value}</AppText>
      <Punch style={styles.metricLabel}>{label}</Punch>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: colors.stage, borderRadius: radius.xl, padding: spacing.xl, gap: spacing.sm, alignItems: "center" },
  avatar: { width: 84, height: 84, borderRadius: 42, backgroundColor: colors.flare, alignItems: "center", justifyContent: "center", borderWidth: 3, borderColor: colors.stageRaised },
  avatarText: { fontFamily: fonts.serif, fontSize: 42, lineHeight: 48 },
  handle: { color: colors.onStageMuted, fontSize: 10, marginTop: spacing.xs },
  name: { color: colors.onStage, fontSize: 34, lineHeight: 36, textAlign: "center" },
  bio: { color: colors.onStageMuted, fontSize: 14, lineHeight: 20, textAlign: "center" },
  metrics: { flexDirection: "row", alignItems: "center", alignSelf: "stretch", borderTopWidth: 1, borderColor: colors.stageLine, paddingTop: spacing.md, marginTop: spacing.sm, marginBottom: spacing.sm },
  metric: { flex: 1, alignItems: "center", gap: 2 },
  metricValue: { color: colors.onStage, fontFamily: fonts.serif, fontSize: 30, lineHeight: 34 },
  metricLabel: { color: colors.onStageMuted, fontSize: 9 },
  rule: { width: 1, height: 30, backgroundColor: colors.stageLine },
  posts: { gap: spacing.sm },
  label: { color: colors.muted },
  grid: { flexDirection: "row", gap: spacing.md },
  column: { flex: 1, gap: spacing.md },
  tile: { borderRadius: radius.lg, overflow: "hidden", backgroundColor: colors.canvasSoft },
  textTile: { flex: 1, padding: spacing.md, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke, borderRadius: radius.lg },
  textTileCopy: { fontSize: 14, lineHeight: 19, color: colors.inkSoft },
  empty: { color: colors.muted, paddingVertical: spacing.md }
});
