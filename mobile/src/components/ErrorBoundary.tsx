import { Component, PropsWithChildren, ReactNode } from "react";
import { StyleSheet, View } from "react-native";
import { AppText, Eyebrow, Title } from "@/components/AppText";
import { Button } from "@/components/Button";
import { colors, spacing } from "@/theme";

type Props = PropsWithChildren<{ fallback?: ReactNode }>;
type State = { error: Error | null };

export class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: { componentStack: string }) {
    console.error("Unhandled render error", error, info.componentStack);
  }

  reset = () => this.setState({ error: null });

  render() {
    if (this.state.error) {
      if (this.props.fallback) return this.props.fallback;
      return (
        <View style={styles.container}>
          <Eyebrow>FitSync</Eyebrow>
          <Title style={styles.title}>Something went wrong</Title>
          <AppText style={styles.body}>
            {this.state.error.message || "The app hit an unexpected error."}
          </AppText>
          <Button title="Try again" onPress={this.reset} />
        </View>
      );
    }
    return this.props.children;
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.canvas,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: spacing.xl,
    gap: spacing.md
  },
  title: { fontSize: 28, lineHeight: 30, textAlign: "center" },
  body: { color: colors.muted, textAlign: "center", marginBottom: spacing.md }
});
