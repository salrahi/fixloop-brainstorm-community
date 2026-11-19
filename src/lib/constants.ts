export const CATEGORY_EMOJI: Record<string, string> = {
  study: "◩",
  mathematics: "∑",
  science: "⚛",
  technology: "⌘",
  life: "☼",
  friends: "♥",
  career: "↗",
  creativity: "✦",
  general: "◎",
};

export const SORTS = [
  { value: "latest", label: "Latest" },
  { value: "popular", label: "Popular" },
  { value: "helpful", label: "Most helpful" },
  { value: "unanswered", label: "Unanswered" },
] as const;
export type SortValue = (typeof SORTS)[number]["value"];

export const REPORT_REASONS = [
  { value: "spam", label: "Spam or advertising" },
  { value: "harassment", label: "Harassment or bullying" },
  { value: "hate", label: "Hate speech" },
  { value: "misinformation", label: "Harmful misinformation" },
  { value: "unsafe", label: "Unsafe or dangerous advice" },
  { value: "off_topic", label: "Off-topic" },
  { value: "other", label: "Something else" },
] as const;

export const USERNAME_RE = /^[a-z0-9_]{3,20}$/;

export const AI_DISCLAIMER =
  "AI-generated suggestions. Not verified by people or professionals — double-check anything important.";
