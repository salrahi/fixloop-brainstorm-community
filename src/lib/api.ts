import { supabase } from "@/integrations/supabase/client";
import type { Tables } from "@/integrations/supabase/types";
import type { SortValue } from "./constants";

export type Category = Tables<"categories">;
export type AuthorLite = Pick<Tables<"profiles">, "id" | "username" | "display_name" | "avatar_url">;
export type QuestionRow = Tables<"questions"> & {
  author: AuthorLite | null;
  category: Pick<Category, "slug" | "name"> | null;
};
export type AnswerRow = Tables<"answers"> & { author: AuthorLite | null };
export type CommentRow = Tables<"comments"> & { author: AuthorLite | null };

const AUTHOR = "id, username, display_name, avatar_url";
export const Q_SELECT = `id, author_id, title, body, category_slug, tags, like_count, answer_count, helpful_count, accepted_answer_id, is_removed, search, created_at, updated_at, author:profiles!questions_author_id_fkey(${AUTHOR}), category:categories(slug, name)`;
export const A_SELECT = `*, author:profiles!answers_author_id_fkey(${AUTHOR})`;
export const C_SELECT = `*, author:profiles!comments_author_id_fkey(${AUTHOR})`;

export const PAGE_SIZE = 12;

export async function fetchCategories(): Promise<Category[]> {
  const { data, error } = await supabase.from("categories").select("*").order("sort_order");
  if (error) throw error;
  return data;
}

export async function fetchFeed(opts: { category?: string; sort: SortValue; page: number }) {
  let q = supabase.from("questions").select(Q_SELECT).eq("is_removed", false);
  if (opts.category) q = q.eq("category_slug", opts.category);
  if (opts.sort === "popular") q = q.order("like_count", { ascending: false }).order("answer_count", { ascending: false });
  if (opts.sort === "helpful") q = q.order("helpful_count", { ascending: false }).order("accepted_answer_id", { ascending: true, nullsFirst: false });
  if (opts.sort === "unanswered") q = q.eq("answer_count", 0);
  q = q.order("created_at", { ascending: false });
  const from = opts.page * PAGE_SIZE;
  const { data, error } = await q.range(from, from + PAGE_SIZE - 1);
  if (error) throw error;
  return data as unknown as QuestionRow[];
}

export async function searchQuestions(term: string, category?: string) {
  const { data, error } = await supabase
    .rpc("search_questions", category ? { _q: term, _category: category } : { _q: term })
    .select(Q_SELECT);
  if (error) throw error;
  return (data ?? []) as unknown as QuestionRow[];
}

export async function searchAnswers(term: string) {
  const { data, error } = await supabase
    .rpc("search_answers", { _q: term })
    .select(`${A_SELECT}, question:questions(id, title, is_removed)`);
  if (error) throw error;
  return (data ?? []) as unknown as (AnswerRow & { question: { id: string; title: string; is_removed: boolean } | null })[];
}

export async function fetchQuestion(id: string) {
  const { data, error } = await supabase.from("questions").select(Q_SELECT).eq("id", id).maybeSingle();
  if (error) throw error;
  return data as unknown as QuestionRow | null;
}

export async function fetchAnswers(questionId: string) {
  const { data, error } = await supabase
    .from("answers")
    .select(A_SELECT)
    .eq("question_id", questionId)
    .order("helpful_count", { ascending: false })
    .order("created_at", { ascending: true });
  if (error) throw error;
  return data as unknown as AnswerRow[];
}

export async function fetchComments(answerIds: string[]) {
  if (!answerIds.length) return [] as CommentRow[];
  const { data, error } = await supabase
    .from("comments")
    .select(C_SELECT)
    .in("answer_id", answerIds)
    .order("created_at", { ascending: true });
  if (error) throw error;
  return data as unknown as CommentRow[];
}

export interface PlatformStats {
  members: number;
  questions: number;
  answers: number;
  solved: number;
  helpful_votes: number;
  arena_rounds: number;
}

export async function fetchStats(): Promise<PlatformStats> {
  const { data, error } = await supabase.rpc("get_platform_stats");
  if (error) throw error;
  return data as unknown as PlatformStats;
}

export async function fetchBlockedIds(userId: string): Promise<string[]> {
  const { data, error } = await supabase.from("blocks").select("blocked_id").eq("blocker_id", userId);
  if (error) throw error;
  return data.map((b) => b.blocked_id);
}

export function publicDisplay(author: AuthorLite | null | undefined) {
  return author?.display_name || author?.username || "Deleted user";
}
