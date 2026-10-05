import { useMemo, useState } from "react";
import { StyleSheet, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useCloset } from "@/api/queries";
import { AppText, Punch, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { PressableScale, Reveal } from "@/components/motion";
import { Photo } from "@/components/Photo";
import { PreviewNote } from "@/components/PreviewNote";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { SEED_MEMBER, SEED_POSTS } from "@/data/discover";
import { Check, Plus } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";

const GRID_HEIGHTS = [232, 196, 198, 236];

export default function MemberProfile() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const closet = useCloset();
  const [following, setFollowing] = useState(false);

  const post = SEED_POSTS.find((entry) => entry.id === id);
  const member = post ? { ...SEED_MEMBER, initial: post.initial, handle: post.handle, name: post.name } : SEED_MEMBER;
  const photos = useMemo(
    () => (closet.data?.items ?? []).map((item) => mediaUrl(item.image_url)).filter(Boolean) as string[],
    [closet.data]
  );

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Screen>
      <PushHeader title="Member" onBack={() => router.back()} />
      <Reveal>
        <View style={styles.card}>
          <View style={styles.avatar}><AppText style={styles.avatarText}>{member.initial}</AppText></View>
          <Punch style={styles.handle}>{member.handle}</Punch>
          <Title style={styles.name}>{member.name}</Title>
          <AppText style={styles.bio}>{member.bio}</AppText>
          <View style={styles.metrics}>
            <Metric value={String(member.posts)} label="Posts" />
            <View style={styles.rule} />
            <Metric value={member.followers} label="Followers" />
            <View style={styles.rule} />
            <Metric value={String(member.challenges)} label="Challenges" />
          </View>
          <Button title={following ? "Following" : `Follow ${member.name.split(" ")[0]}`} icon={following ? Check : Plus}
            variant={following ? "stage" : "accent"} onPress={() => setFollowing((v) => !v)} />
        </View>
      </Reveal>
      <PreviewNote />

      <View style={styles.posts}>
        <Punch style={styles.label}>Their posts</Punch>
        <View style={styles.grid}>
          {[0, 1].map((col) => (
            <View key={col} style={styles.column}>
              {GRID_HEIGHTS.filter((_, i) => i % 2 === col).map((height, i) => {
                const index = i * 2 + col;
                return (
                  <PressableScale key={index} accessibilityRole="button" accessibilityLabel="Open post"
                    onPress={() => router.push(`/community/post/${SEED_POSTS[index % SEED_POSTS.length].id}`)} style={[styles.tile, { height }]}>
                    {photos.length ? <Photo source={photos[index % photos.length]} /> : <View style={styles.placeholder} />}
                  </PressableScale>
                );
              })}
            </View>
          ))}
        </View>
      </View>
    </Screen>
  );
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
  placeholder: { flex: 1, backgroundColor: colors.canvasSoft }
});
