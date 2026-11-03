import { StyleSheet, View } from "react-native";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import { mediaUrl } from "@/api/client";
import { useChallenge, useToggleJoin } from "@/api/discover-queries";
import { AppText, Caption, Display, Heading, Punch } from "@/components/AppText";
import { Button } from "@/components/Button";
import { PressableScale, Reveal } from "@/components/motion";
import { Photo } from "@/components/Photo";
import { PushHeader } from "@/components/PushHeader";
import { Screen } from "@/components/Screen";
import { StatePanel } from "@/components/state-panel";
import { daysLeftLabel, initialOf, toChallenge, toPost } from "@/data/discover";
import { Check, CloudOff, Heart, PenLine, Sparkles } from "@/icons";
import { useAuthStore } from "@/store/auth";
import { colors, fonts, radius, spacing } from "@/theme";

export default function ChallengeDetail() {
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;
  const token = useAuthStore((state) => state.token);
  const query = useChallenge(id);
  const toggleJoin = useToggleJoin();
  const challenge = query.data ? toChallenge(query.data) : null;
  const entries = (query.data?.entries ?? []).map((post) => toPost(post));
  const avatars = query.data?.recent_participants ?? [];

  if (!token) return <Redirect href="/(auth)/sign-in" />;

  if (!challenge) {
    return (
      <Screen>
        <PushHeader title="Challenge" onBack={() => router.back()} />
        {query.isError
          ? <StatePanel icon={CloudOff} title="Couldn't open this challenge" message={query.error instanceof Error ? query.error.message : "Try again in a moment."}
              action="Try again" onAction={() => query.refetch()} />
          : <StatePanel title="Loading…" message="Opening the challenge." />}
      </Screen>
    );
  }

  const joined = challenge.joined;
  const footer = joined ? (
    <View style={styles.footer}>
      <Button title="Post an entry" icon={PenLine} variant="accent" onPress={() => router.push({ pathname: "/community/create", params: { challenge: challenge.id } })} />
      <Button title="Style a look first" icon={Sparkles} variant="secondary" onPress={() => router.push("/style")} />
    </View>
  ) : <Button title="Join this challenge" onPress={() => toggleJoin.mutate({ challengeId: challenge.id, joined: true })} />;

  return (
    <Screen footer={footer}>
      <PushHeader title="Challenge" onBack={() => router.back()} />
      <Reveal>
        <View style={styles.hero}>
          <View style={styles.heroTop}>
            <Punch style={styles.heroTag}>{challenge.difficulty}</Punch>
            <Punch style={styles.heroTag}>{daysLeftLabel(challenge.days)}</Punch>
          </View>
          <Display style={styles.title}>{challenge.title}</Display>
          {challenge.description ? <AppText style={styles.description}>{challenge.description}</AppText> : null}
          {challenge.reward ? <View style={styles.reward}><AppText style={styles.rewardText}>Reward · {challenge.reward}</AppText></View> : null}
        </View>
      </Reveal>

      <View style={styles.participants}>
        <View style={styles.avatars}>
          {avatars.map((name, index) => (
            <View key={`${name}-${index}`} style={[styles.avatar, { marginLeft: index ? -10 : 0, zIndex: 10 - index }, index === 0 && styles.avatarFirst]}>
              <AppText style={styles.avatarText}>{initialOf(name)}</AppText>
            </View>
          ))}
        </View>
        <Heading style={styles.flex}>{challenge.participants.toLocaleString()} joined</Heading>
        {joined ? <View style={styles.joined}><Check size={14} color={colors.ink} strokeWidth={3} /><Punch style={styles.joinedText}>You're in</Punch></View> : null}
      </View>

      <View style={styles.entries}>
        <Punch style={styles.label}>Entries</Punch>
        {entries.length === 0 ? <AppText style={styles.empty}>No entries yet. Join and post the first one.</AppText> : null}
        <View style={styles.grid}>
          {entries.map((post, index) => (
            <Reveal key={post.id} index={index} style={styles.cell}>
              <PressableScale accessibilityRole="button" accessibilityLabel={`Open ${post.name}'s entry`} onPress={() => router.push(`/community/post/${post.id}`)} style={styles.entry}>
                <View style={[styles.entryMedia, { height: index % 3 === 0 ? 220 : 180 }]}>
                  {post.imageUrl ? <Photo source={mediaUrl(post.imageUrl)!} /> : <View style={styles.textTile}><AppText numberOfLines={7} style={styles.textTileCopy}>{post.caption}</AppText></View>}
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
  textTile: { flex: 1, padding: spacing.md, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.stroke, borderRadius: radius.lg },
  textTileCopy: { fontSize: 14, lineHeight: 19, color: colors.inkSoft },
  empty: { color: colors.muted },
  footer: { gap: spacing.sm },
  entryMeta: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 2 },
  entryName: { flex: 1, fontSize: 13, fontFamily: fonts.medium },
  entryLikes: { flexDirection: "row", alignItems: "center", gap: 3 }
});
