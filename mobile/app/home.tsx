import { Redirect } from "expo-router";

// Kept for one release so old deep links keep working.
export default function Moved() {
  return <Redirect href="/today" />;
}
