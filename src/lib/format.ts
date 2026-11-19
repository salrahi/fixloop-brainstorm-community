import { formatDistanceToNowStrict, format } from "date-fns";

export function timeAgo(date: string | Date) {
  try {
    return formatDistanceToNowStrict(new Date(date), { addSuffix: true });
  } catch {
    return "";
  }
}

export function fullDate(date: string | Date) {
  try {
    return format(new Date(date), "d MMM yyyy");
  } catch {
    return "";
  }
}

export function plural(n: number, one: string, many = `${one}s`) {
  return `${n} ${n === 1 ? one : many}`;
}

export function initials(name: string) {
  return (
    name
      .split(/\s+|_/)
      .filter(Boolean)
      .slice(0, 2)
      .map((s) => s[0]?.toUpperCase())
      .join("") || "?"
  );
}

export function errorMessage(err: unknown, fallback = "Something went wrong. Please try again.") {
  if (!err) return fallback;
  const msg =
    typeof err === "string"
      ? err
      : typeof err === "object" && err && "message" in err
        ? String((err as { message: unknown }).message)
        : "";
  if (!msg) return fallback;
  if (/duplicate key|already exists/i.test(msg)) return "That already exists.";
  if (/row-level security|permission denied/i.test(msg))
    return "You don't have permission to do that. If your account is suspended, contact the moderators.";
  if (/check constraint/i.test(msg)) return "Some fields are too short or too long. Please check and try again.";
  if (/Failed to fetch|NetworkError/i.test(msg)) return "Network problem — check your connection and try again.";
  return msg;
}
