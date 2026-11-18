
-- ============ helpers ============
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin new.updated_at = now(); return new; end; $$;

-- ============ roles ============
create type public.app_role as enum ('admin', 'moderator', 'user');

-- ============ profiles ============
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  display_name text not null default '',
  avatar_url text,
  bio text not null default '',
  interests text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (username ~ '^[a-z0-9_]{3,20}$'),
  constraint profiles_display_name_len check (char_length(display_name) <= 50),
  constraint profiles_bio_len check (char_length(bio) <= 280),
  constraint profiles_interests_len check (coalesce(array_length(interests, 1), 0) <= 10)
);
create unique index profiles_username_key on public.profiles (username);
grant select on public.profiles to anon, authenticated;
grant update (username, display_name, avatar_url, bio, interests) on public.profiles to authenticated;
grant all on public.profiles to service_role;
alter table public.profiles enable row level security;
create policy "Profiles are publicly readable" on public.profiles for select using (true);
create policy "Users update own profile" on public.profiles for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);
create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

-- ============ user_roles ============
create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  role public.app_role not null,
  unique (user_id, role)
);
grant select on public.user_roles to authenticated;
grant all on public.user_roles to service_role;
alter table public.user_roles enable row level security;

create or replace function public.has_role(_user_id uuid, _role public.app_role)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles where user_id = _user_id and role = _role)
$$;

create policy "Users read own roles, admins read all" on public.user_roles for select to authenticated
  using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));

-- ============ suspensions ============
create table public.account_suspensions (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  reason text not null default '' check (char_length(reason) <= 300),
  suspended_by uuid,
  created_at timestamptz not null default now()
);
grant select, insert, delete on public.account_suspensions to authenticated;
grant all on public.account_suspensions to service_role;
alter table public.account_suspensions enable row level security;
create policy "Own or admin can view suspension" on public.account_suspensions for select to authenticated
  using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
create policy "Admins suspend" on public.account_suspensions for insert to authenticated
  with check (public.has_role(auth.uid(), 'admin') and user_id <> auth.uid());
create policy "Admins unsuspend" on public.account_suspensions for delete to authenticated
  using (public.has_role(auth.uid(), 'admin'));

create or replace function public.is_active_user(_user_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select _user_id is not null and not exists (select 1 from public.account_suspensions where user_id = _user_id)
$$;

-- ============ new user trigger ============
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  base text;
  candidate text;
  dname text;
  i int := 0;
begin
  base := lower(coalesce(new.raw_user_meta_data ->> 'username', ''));
  base := regexp_replace(base, '[^a-z0-9_]', '', 'g');
  if char_length(base) < 3 then
    base := regexp_replace(lower(split_part(coalesce(new.email, 'user'), '@', 1)), '[^a-z0-9_]', '', 'g');
  end if;
  if char_length(base) < 3 then base := 'looper'; end if;
  base := left(base, 20);
  candidate := base;
  while exists (select 1 from public.profiles where username = candidate) loop
    i := i + 1;
    candidate := left(base, 15) || '_' || (floor(random() * 9000) + 1000)::int::text;
    exit when i > 20;
  end loop;
  dname := left(coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), candidate), 50);
  insert into public.profiles (id, username, display_name) values (new.id, candidate, dname);
  insert into public.user_roles (user_id, role) values (new.id, 'user');
  return new;
end; $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.is_username_available(_username text)
returns boolean language sql stable security definer set search_path = public as $$
  select _username ~ '^[a-z0-9_]{3,20}$' and not exists (select 1 from public.profiles where username = _username)
$$;
grant execute on function public.is_username_available(text) to anon, authenticated;

-- ============ categories ============
create table public.categories (
  slug text primary key check (slug ~ '^[a-z0-9-]{2,30}$'),
  name text not null check (char_length(name) between 2 and 40),
  description text not null default '' check (char_length(description) <= 200),
  sort_order int not null default 100,
  created_at timestamptz not null default now()
);
grant select on public.categories to anon, authenticated;
grant insert, update, delete on public.categories to authenticated;
grant all on public.categories to service_role;
alter table public.categories enable row level security;
create policy "Categories are public" on public.categories for select using (true);
create policy "Admins insert categories" on public.categories for insert to authenticated
  with check (public.has_role(auth.uid(), 'admin'));
create policy "Admins update categories" on public.categories for update to authenticated
  using (public.has_role(auth.uid(), 'admin')) with check (public.has_role(auth.uid(), 'admin'));
create policy "Admins delete categories" on public.categories for delete to authenticated
  using (public.has_role(auth.uid(), 'admin'));

insert into public.categories (slug, name, description, sort_order) values
  ('study', 'Study', 'Homework, exams, focus and learning habits.', 1),
  ('mathematics', 'Mathematics', 'Equations, proofs, word problems and number sense.', 2),
  ('science', 'Science', 'Physics, chemistry, biology and how the world works.', 3),
  ('technology', 'Technology', 'Devices, apps, code and everything digital.', 4),
  ('life', 'Life', 'Everyday situations, habits and life admin.', 5),
  ('friends', 'Friends', 'Friendships, social situations and relationships.', 6),
  ('career', 'Career', 'Jobs, internships, interviews and future plans.', 7),
  ('creativity', 'Creativity', 'Art, writing, music, design and making things.', 8),
  ('general', 'General', 'Anything that does not fit elsewhere.', 9);

-- ============ questions ============
create table public.questions (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 10 and 160),
  body text not null check (char_length(body) between 20 and 5000),
  category_slug text not null references public.categories(slug) on update cascade,
  tags text[] not null default '{}' check (coalesce(array_length(tags, 1), 0) <= 5),
  like_count int not null default 0,
  answer_count int not null default 0,
  helpful_count int not null default 0,
  accepted_answer_id uuid,
  is_removed boolean not null default false,
  search tsvector,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index questions_created_idx on public.questions (created_at desc);
create index questions_category_idx on public.questions (category_slug, created_at desc);
create index questions_author_idx on public.questions (author_id);
create index questions_likes_idx on public.questions (like_count desc);
create index questions_helpful_idx on public.questions (helpful_count desc);
create index questions_search_idx on public.questions using gin (search);

create or replace function public.questions_search_update()
returns trigger language plpgsql set search_path = public as $$
begin
  new.search :=
    setweight(to_tsvector('english', coalesce(new.title, '')), 'A') ||
    setweight(to_tsvector('english', array_to_string(coalesce(new.tags, '{}'), ' ')), 'A') ||
    setweight(to_tsvector('english', coalesce(new.body, '')), 'B');
  return new;
end; $$;
create trigger questions_search before insert or update of title, body, tags on public.questions
  for each row execute function public.questions_search_update();
create trigger questions_updated_at before update of title, body, category_slug, tags on public.questions
  for each row execute function public.set_updated_at();

grant select on public.questions to anon, authenticated;
grant insert (author_id, title, body, category_slug, tags) on public.questions to authenticated;
grant update (title, body, category_slug, tags, accepted_answer_id) on public.questions to authenticated;
grant delete on public.questions to authenticated;
grant all on public.questions to service_role;
alter table public.questions enable row level security;
create policy "Questions visible unless removed" on public.questions for select
  using (not is_removed or author_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
create policy "Active users ask questions" on public.questions for insert to authenticated
  with check (author_id = auth.uid() and public.is_active_user(auth.uid()));
create policy "Authors edit questions" on public.questions for update to authenticated
  using (author_id = auth.uid()) with check (author_id = auth.uid() and public.is_active_user(auth.uid()));
create policy "Authors or admins delete questions" on public.questions for delete to authenticated
  using (author_id = auth.uid() or public.has_role(auth.uid(), 'admin'));

-- ============ answers ============
create table public.answers (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 2 and 5000),
  like_count int not null default 0,
  comment_count int not null default 0,
  helpful_count int not null default 0,
  is_removed boolean not null default false,
  search tsvector generated always as (to_tsvector('english', coalesce(body, ''))) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index answers_question_idx on public.answers (question_id, created_at);
create index answers_author_idx on public.answers (author_id);
create index answers_search_idx on public.answers using gin (search);
create trigger answers_updated_at before update of body on public.answers
  for each row execute function public.set_updated_at();

alter table public.questions add constraint questions_accepted_answer_fk
  foreign key (accepted_answer_id) references public.answers(id) on delete set null;

grant select on public.answers to anon, authenticated;
grant insert (question_id, author_id, body) on public.answers to authenticated;
grant update (body) on public.answers to authenticated;
grant delete on public.answers to authenticated;
grant all on public.answers to service_role;
alter table public.answers enable row level security;
create policy "Answers visible unless removed" on public.answers for select
  using (not is_removed or author_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
create policy "Active users answer" on public.answers for insert to authenticated
  with check (author_id = auth.uid() and public.is_active_user(auth.uid())
    and exists (select 1 from public.questions q where q.id = question_id and not q.is_removed));
create policy "Authors edit answers" on public.answers for update to authenticated
  using (author_id = auth.uid()) with check (author_id = auth.uid() and public.is_active_user(auth.uid()));
create policy "Authors or admins delete answers" on public.answers for delete to authenticated
  using (author_id = auth.uid() or public.has_role(auth.uid(), 'admin'));

-- ============ comments ============
create table public.comments (
  id uuid primary key default gen_random_uuid(),
  answer_id uuid not null references public.answers(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  is_removed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index comments_answer_idx on public.comments (answer_id, created_at);
create index comments_author_idx on public.comments (author_id);
create trigger comments_updated_at before update of body on public.comments
  for each row execute function public.set_updated_at();
grant select on public.comments to anon, authenticated;
grant insert (answer_id, author_id, body) on public.comments to authenticated;
grant update (body) on public.comments to authenticated;
grant delete on public.comments to authenticated;
grant all on public.comments to service_role;
alter table public.comments enable row level security;
create policy "Comments visible unless removed" on public.comments for select
  using (not is_removed or author_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
create policy "Active users comment" on public.comments for insert to authenticated
  with check (author_id = auth.uid() and public.is_active_user(auth.uid()));
create policy "Authors edit comments" on public.comments for update to authenticated
  using (author_id = auth.uid()) with check (author_id = auth.uid());
create policy "Authors or admins delete comments" on public.comments for delete to authenticated
  using (author_id = auth.uid() or public.has_role(auth.uid(), 'admin'));

-- ============ likes / helpful / saved / blocks ============
create table public.question_likes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, question_id)
);
create index question_likes_q_idx on public.question_likes (question_id);
create table public.answer_likes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  answer_id uuid not null references public.answers(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, answer_id)
);
create index answer_likes_a_idx on public.answer_likes (answer_id);
create table public.helpful_votes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  answer_id uuid not null references public.answers(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, answer_id)
);
create index helpful_votes_a_idx on public.helpful_votes (answer_id);
create table public.saved_questions (
  user_id uuid not null references public.profiles(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, question_id)
);
create table public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

grant select, insert, delete on public.question_likes, public.answer_likes, public.helpful_votes,
  public.saved_questions, public.blocks to authenticated;
grant all on public.question_likes, public.answer_likes, public.helpful_votes,
  public.saved_questions, public.blocks to service_role;
alter table public.question_likes enable row level security;
alter table public.answer_likes enable row level security;
alter table public.helpful_votes enable row level security;
alter table public.saved_questions enable row level security;
alter table public.blocks enable row level security;

create policy "Own question likes" on public.question_likes for select to authenticated using (user_id = auth.uid());
create policy "Like questions" on public.question_likes for insert to authenticated
  with check (user_id = auth.uid() and public.is_active_user(auth.uid()));
create policy "Unlike questions" on public.question_likes for delete to authenticated using (user_id = auth.uid());

create policy "Own answer likes" on public.answer_likes for select to authenticated using (user_id = auth.uid());
create policy "Like answers" on public.answer_likes for insert to authenticated
  with check (user_id = auth.uid() and public.is_active_user(auth.uid()));
create policy "Unlike answers" on public.answer_likes for delete to authenticated using (user_id = auth.uid());

create policy "Own helpful votes" on public.helpful_votes for select to authenticated using (user_id = auth.uid());
create policy "Vote helpful" on public.helpful_votes for insert to authenticated
  with check (user_id = auth.uid() and public.is_active_user(auth.uid())
    and not exists (select 1 from public.answers a where a.id = answer_id and a.author_id = auth.uid()));
create policy "Remove helpful vote" on public.helpful_votes for delete to authenticated using (user_id = auth.uid());

create policy "Own saved" on public.saved_questions for select to authenticated using (user_id = auth.uid());
create policy "Save question" on public.saved_questions for insert to authenticated with check (user_id = auth.uid());
create policy "Unsave question" on public.saved_questions for delete to authenticated using (user_id = auth.uid());

create policy "Own blocks" on public.blocks for select to authenticated using (blocker_id = auth.uid());
create policy "Block users" on public.blocks for insert to authenticated with check (blocker_id = auth.uid());
create policy "Unblock users" on public.blocks for delete to authenticated using (blocker_id = auth.uid());

-- ============ notifications ============
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete cascade,
  type text not null check (type in ('answer', 'comment', 'like_question', 'like_answer', 'helpful', 'accepted')),
  question_id uuid references public.questions(id) on delete cascade,
  answer_id uuid references public.answers(id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
grant select, delete on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;
grant all on public.notifications to service_role;
alter table public.notifications enable row level security;
create policy "Own notifications" on public.notifications for select to authenticated using (user_id = auth.uid());
create policy "Mark own notifications" on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Clear own notifications" on public.notifications for delete to authenticated using (user_id = auth.uid());

create or replace function public.create_notification(_recipient uuid, _actor uuid, _type text, _question uuid, _answer uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if _recipient is null or _recipient = _actor then return; end if;
  if exists (select 1 from public.blocks where blocker_id = _recipient and blocked_id = _actor) then return; end if;
  if exists (
    select 1 from public.notifications
    where user_id = _recipient and actor_id is not distinct from _actor and type = _type
      and question_id is not distinct from _question and answer_id is not distinct from _answer
  ) then return; end if;
  insert into public.notifications (user_id, actor_id, type, question_id, answer_id)
  values (_recipient, _actor, _type, _question, _answer);
end; $$;
revoke execute on function public.create_notification(uuid, uuid, text, uuid, uuid) from public, anon, authenticated;

-- ============ counter + notification triggers ============
create or replace function public.on_question_like()
returns trigger language plpgsql security definer set search_path = public as $$
declare _author uuid;
begin
  if tg_op = 'INSERT' then
    update public.questions set like_count = like_count + 1 where id = new.question_id returning author_id into _author;
    perform public.create_notification(_author, new.user_id, 'like_question', new.question_id, null);
    return new;
  else
    update public.questions set like_count = greatest(like_count - 1, 0) where id = old.question_id;
    return old;
  end if;
end; $$;
create trigger question_likes_counter after insert or delete on public.question_likes
  for each row execute function public.on_question_like();

create or replace function public.on_answer_like()
returns trigger language plpgsql security definer set search_path = public as $$
declare _author uuid; _q uuid;
begin
  if tg_op = 'INSERT' then
    update public.answers set like_count = like_count + 1 where id = new.answer_id returning author_id, question_id into _author, _q;
    perform public.create_notification(_author, new.user_id, 'like_answer', _q, new.answer_id);
    return new;
  else
    update public.answers set like_count = greatest(like_count - 1, 0) where id = old.answer_id;
    return old;
  end if;
end; $$;
create trigger answer_likes_counter after insert or delete on public.answer_likes
  for each row execute function public.on_answer_like();

create or replace function public.on_helpful_vote()
returns trigger language plpgsql security definer set search_path = public as $$
declare _author uuid; _q uuid;
begin
  if tg_op = 'INSERT' then
    update public.answers set helpful_count = helpful_count + 1 where id = new.answer_id returning author_id, question_id into _author, _q;
    update public.questions set helpful_count = helpful_count + 1 where id = _q;
    perform public.create_notification(_author, new.user_id, 'helpful', _q, new.answer_id);
    return new;
  else
    update public.answers set helpful_count = greatest(helpful_count - 1, 0) where id = old.answer_id returning question_id into _q;
    update public.questions set helpful_count = greatest(helpful_count - 1, 0) where id = _q;
    return old;
  end if;
end; $$;
create trigger helpful_votes_counter after insert or delete on public.helpful_votes
  for each row execute function public.on_helpful_vote();

create or replace function public.on_answer_change()
returns trigger language plpgsql security definer set search_path = public as $$
declare _author uuid;
begin
  if tg_op = 'INSERT' then
    update public.questions set answer_count = answer_count + 1 where id = new.question_id returning author_id into _author;
    perform public.create_notification(_author, new.author_id, 'answer', new.question_id, new.id);
    return new;
  else
    update public.questions set answer_count = greatest(answer_count - 1, 0),
      helpful_count = greatest(helpful_count - old.helpful_count, 0)
      where id = old.question_id;
    return old;
  end if;
end; $$;
create trigger answers_counter after insert or delete on public.answers
  for each row execute function public.on_answer_change();

create or replace function public.on_comment_change()
returns trigger language plpgsql security definer set search_path = public as $$
declare _author uuid; _q uuid;
begin
  if tg_op = 'INSERT' then
    update public.answers set comment_count = comment_count + 1 where id = new.answer_id returning author_id, question_id into _author, _q;
    perform public.create_notification(_author, new.author_id, 'comment', _q, new.answer_id);
    return new;
  else
    update public.answers set comment_count = greatest(comment_count - 1, 0) where id = old.answer_id;
    return old;
  end if;
end; $$;
create trigger comments_counter after insert or delete on public.comments
  for each row execute function public.on_comment_change();

create or replace function public.on_question_accept()
returns trigger language plpgsql security definer set search_path = public as $$
declare _answer_author uuid;
begin
  if new.accepted_answer_id is not null and new.accepted_answer_id is distinct from old.accepted_answer_id then
    select author_id into _answer_author from public.answers
      where id = new.accepted_answer_id and question_id = new.id;
    if not found then
      raise exception 'That answer does not belong to this question';
    end if;
    perform public.create_notification(_answer_author, new.author_id, 'accepted', new.id, new.accepted_answer_id);
  end if;
  return new;
end; $$;
create trigger questions_accept before update of accepted_answer_id on public.questions
  for each row execute function public.on_question_accept();

-- ============ reports ============
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('question', 'answer', 'comment', 'user')),
  question_id uuid references public.questions(id) on delete cascade,
  answer_id uuid references public.answers(id) on delete cascade,
  comment_id uuid references public.comments(id) on delete cascade,
  reported_user_id uuid references public.profiles(id) on delete cascade,
  reason text not null check (reason in ('spam', 'harassment', 'hate', 'misinformation', 'unsafe', 'off_topic', 'other')),
  details text not null default '' check (char_length(details) <= 500),
  status text not null default 'open' check (status in ('open', 'resolved', 'dismissed')),
  resolved_by uuid,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  check (
    (target_type = 'question' and question_id is not null) or
    (target_type = 'answer' and answer_id is not null) or
    (target_type = 'comment' and comment_id is not null) or
    (target_type = 'user' and reported_user_id is not null)
  )
);
create unique index reports_unique_per_reporter on public.reports
  (reporter_id, target_type, coalesce(question_id, answer_id, comment_id, reported_user_id));
create index reports_status_idx on public.reports (status, created_at desc);
grant select on public.reports to authenticated;
grant insert (reporter_id, target_type, question_id, answer_id, comment_id, reported_user_id, reason, details) on public.reports to authenticated;
grant update (status, resolved_by, resolved_at) on public.reports to authenticated;
grant all on public.reports to service_role;
alter table public.reports enable row level security;
create policy "Reporters and admins view reports" on public.reports for select to authenticated
  using (reporter_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
create policy "Users file reports" on public.reports for insert to authenticated
  with check (reporter_id = auth.uid());
create policy "Admins resolve reports" on public.reports for update to authenticated
  using (public.has_role(auth.uid(), 'admin')) with check (public.has_role(auth.uid(), 'admin'));

-- ============ feedback ============
create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  message text not null check (char_length(message) between 3 and 1000),
  page text not null default '' check (char_length(page) <= 200),
  created_at timestamptz not null default now()
);
create index feedback_created_idx on public.feedback (created_at desc);
grant insert (user_id, message, page) on public.feedback to anon, authenticated;
grant select, delete on public.feedback to authenticated;
grant all on public.feedback to service_role;
alter table public.feedback enable row level security;
create policy "Anyone can send feedback" on public.feedback for insert to anon, authenticated
  with check (user_id is null or user_id = auth.uid());
create policy "Admins read feedback" on public.feedback for select to authenticated
  using (public.has_role(auth.uid(), 'admin'));
create policy "Admins delete feedback" on public.feedback for delete to authenticated
  using (public.has_role(auth.uid(), 'admin'));

-- ============ AI ============
create table public.ai_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);
create index ai_requests_user_idx on public.ai_requests (user_id, created_at desc);
grant select, insert on public.ai_requests to authenticated;
grant all on public.ai_requests to service_role;
alter table public.ai_requests enable row level security;
create policy "Own ai requests" on public.ai_requests for select to authenticated using (user_id = auth.uid());
create policy "Log own ai requests" on public.ai_requests for insert to authenticated
  with check (user_id = auth.uid() and public.is_active_user(auth.uid()));

create table public.saved_ai_responses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  prompt text not null check (char_length(prompt) between 1 and 2000),
  category_slug text references public.categories(slug) on update cascade on delete set null,
  response text not null check (char_length(response) between 1 and 20000),
  created_at timestamptz not null default now()
);
create index saved_ai_user_idx on public.saved_ai_responses (user_id, created_at desc);
grant select, insert, delete on public.saved_ai_responses to authenticated;
grant all on public.saved_ai_responses to service_role;
alter table public.saved_ai_responses enable row level security;
create policy "Own saved ai" on public.saved_ai_responses for select to authenticated using (user_id = auth.uid());
create policy "Save ai" on public.saved_ai_responses for insert to authenticated with check (user_id = auth.uid());
create policy "Delete saved ai" on public.saved_ai_responses for delete to authenticated using (user_id = auth.uid());

-- ============ Brain Arena ============
create table public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('math', 'logic', 'quiz')),
  topic text not null,
  difficulty text not null check (difficulty in ('easy', 'medium', 'hard')),
  prompt text not null,
  options text[] not null check (array_length(options, 1) between 2 and 6),
  correct_index smallint not null,
  explanation text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  check (correct_index >= 0 and correct_index < array_length(options, 1))
);
create index quiz_questions_kind_idx on public.quiz_questions (kind, difficulty, topic);
-- Answers and explanations are never readable directly; grading happens in functions below.
grant select (id, kind, topic, difficulty, prompt, options) on public.quiz_questions to anon, authenticated;
grant all on public.quiz_questions to service_role;
alter table public.quiz_questions enable row level security;
create policy "Active quiz questions are public" on public.quiz_questions for select using (is_active);

create table public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  mode text not null check (mode in ('math', 'logic', 'quiz', 'daily')),
  difficulty text,
  topic text,
  question_ids uuid[] not null,
  total int not null,
  score int not null default 0,
  answered int not null default 0,
  challenge_date date,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index quiz_attempts_user_idx on public.quiz_attempts (user_id, created_at desc);
create index quiz_attempts_completed_idx on public.quiz_attempts (completed_at) where completed_at is not null;
create unique index quiz_attempts_daily_unique on public.quiz_attempts (user_id, challenge_date) where mode = 'daily';
grant select on public.quiz_attempts to authenticated;
grant all on public.quiz_attempts to service_role;
alter table public.quiz_attempts enable row level security;
create policy "Own attempts" on public.quiz_attempts for select to authenticated using (user_id = auth.uid());

create table public.quiz_attempt_answers (
  attempt_id uuid not null references public.quiz_attempts(id) on delete cascade,
  question_id uuid not null references public.quiz_questions(id) on delete cascade,
  choice smallint not null,
  is_correct boolean not null,
  answered_at timestamptz not null default now(),
  primary key (attempt_id, question_id)
);
grant select on public.quiz_attempt_answers to authenticated;
grant all on public.quiz_attempt_answers to service_role;
alter table public.quiz_attempt_answers enable row level security;
create policy "Own attempt answers" on public.quiz_attempt_answers for select to authenticated
  using (exists (select 1 from public.quiz_attempts a where a.id = attempt_id and a.user_id = auth.uid()));

create or replace function public.attempt_payload(_attempt_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'attempt_id', a.id,
    'mode', a.mode,
    'total', a.total,
    'score', a.score,
    'answered', a.answered,
    'completed', a.completed_at is not null,
    'challenge_date', a.challenge_date,
    'questions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', q.id, 'prompt', q.prompt, 'options', to_jsonb(q.options),
        'topic', q.topic, 'difficulty', q.difficulty, 'kind', q.kind,
        'answer', case when aa.question_id is null then null else jsonb_build_object(
          'choice', aa.choice, 'is_correct', aa.is_correct,
          'correct_index', q.correct_index, 'explanation', q.explanation) end
      ) order by ord.n)
      from unnest(a.question_ids) with ordinality as ord(qid, n)
      join public.quiz_questions q on q.id = ord.qid
      left join public.quiz_attempt_answers aa on aa.attempt_id = a.id and aa.question_id = q.id
    ), '[]'::jsonb)
  ) from public.quiz_attempts a where a.id = _attempt_id
$$;
revoke execute on function public.attempt_payload(uuid) from public, anon, authenticated;

create or replace function public.start_attempt(_mode text, _difficulty text default null, _topic text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  _uid uuid := auth.uid();
  _ids uuid[];
  _today date := (now() at time zone 'utc')::date;
  _existing uuid;
  _new uuid;
begin
  if _uid is null then raise exception 'Sign in to play'; end if;
  if not public.is_active_user(_uid) then raise exception 'Your account is suspended'; end if;
  if _mode not in ('math', 'logic', 'quiz', 'daily') then raise exception 'Unknown mode'; end if;
  if _difficulty is not null and _difficulty not in ('easy', 'medium', 'hard') then raise exception 'Unknown difficulty'; end if;

  if _mode = 'daily' then
    select id into _existing from public.quiz_attempts where user_id = _uid and mode = 'daily' and challenge_date = _today;
    if _existing is not null then return public.attempt_payload(_existing); end if;
    select array_agg(id) into _ids from (
      (select id from public.quiz_questions where is_active and kind = 'math' order by md5(id::text || _today::text) limit 2)
      union all
      (select id from public.quiz_questions where is_active and kind = 'logic' order by md5(id::text || _today::text) limit 2)
      union all
      (select id from public.quiz_questions where is_active and kind = 'quiz' order by md5(id::text || _today::text) limit 1)
    ) s;
  else
    select array_agg(id) into _ids from (
      select id from public.quiz_questions
      where is_active and kind = _mode
        and (_difficulty is null or difficulty = _difficulty)
        and (_topic is null or topic = _topic)
      order by random() limit 5
    ) s;
  end if;

  if _ids is null or array_length(_ids, 1) = 0 then raise exception 'No questions available for that selection'; end if;

  insert into public.quiz_attempts (user_id, mode, difficulty, topic, question_ids, total, challenge_date)
  values (_uid, _mode, _difficulty, _topic, _ids, array_length(_ids, 1), case when _mode = 'daily' then _today end)
  returning id into _new;
  return public.attempt_payload(_new);
end; $$;
grant execute on function public.start_attempt(text, text, text) to authenticated;

create or replace function public.answer_attempt(_attempt_id uuid, _question_id uuid, _choice int)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  _uid uuid := auth.uid();
  _a public.quiz_attempts%rowtype;
  _q public.quiz_questions%rowtype;
  _correct boolean;
begin
  if _uid is null then raise exception 'Sign in to play'; end if;
  select * into _a from public.quiz_attempts where id = _attempt_id and user_id = _uid for update;
  if not found then raise exception 'Attempt not found'; end if;
  if not (_question_id = any(_a.question_ids)) then raise exception 'Question is not part of this attempt'; end if;
  select * into _q from public.quiz_questions where id = _question_id;
  if _choice < 0 or _choice >= array_length(_q.options, 1) then raise exception 'Invalid choice'; end if;

  if not exists (select 1 from public.quiz_attempt_answers where attempt_id = _attempt_id and question_id = _question_id) then
    _correct := (_choice = _q.correct_index);
    insert into public.quiz_attempt_answers (attempt_id, question_id, choice, is_correct)
      values (_attempt_id, _question_id, _choice, _correct);
    update public.quiz_attempts
      set answered = answered + 1,
          score = score + case when _correct then 1 else 0 end,
          completed_at = case when answered + 1 >= total then now() else completed_at end
      where id = _attempt_id;
  end if;
  return public.attempt_payload(_attempt_id);
end; $$;
grant execute on function public.answer_attempt(uuid, uuid, int) to authenticated;

create or replace function public.get_leaderboard(_period text default 'all')
returns table (username text, display_name text, avatar_url text, points bigint, rounds bigint)
language sql stable security definer set search_path = public as $$
  select p.username, p.display_name, p.avatar_url, sum(a.score)::bigint as points, count(*)::bigint as rounds
  from public.quiz_attempts a
  join public.profiles p on p.id = a.user_id
  where a.completed_at is not null
    and (_period <> 'week' or a.completed_at > now() - interval '7 days')
    and not exists (select 1 from public.account_suspensions s where s.user_id = a.user_id)
  group by p.id
  having sum(a.score) > 0
  order by points desc, rounds asc, min(a.completed_at) asc
  limit 25
$$;
grant execute on function public.get_leaderboard(text) to anon, authenticated;

create or replace function public.get_my_arena_stats()
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'rounds', count(*) filter (where completed_at is not null),
    'points', coalesce(sum(score) filter (where completed_at is not null), 0),
    'answered', coalesce(sum(answered), 0),
    'correct', coalesce(sum(score), 0),
    'daily_completed', count(*) filter (where mode = 'daily' and completed_at is not null),
    'daily_dates', coalesce((select jsonb_agg(d order by d desc) from (
        select challenge_date d from public.quiz_attempts
        where user_id = auth.uid() and mode = 'daily' and completed_at is not null
        order by challenge_date desc limit 30) x), '[]'::jsonb),
    'by_mode', coalesce((select jsonb_object_agg(mode, jsonb_build_object('answered', ans, 'correct', cor)) from (
        select mode, sum(answered) ans, sum(score) cor from public.quiz_attempts
        where user_id = auth.uid() group by mode) m), '{}'::jsonb)
  ) from public.quiz_attempts where user_id = auth.uid()
$$;
grant execute on function public.get_my_arena_stats() to authenticated;

-- ============ stats ============
create or replace function public.get_platform_stats()
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'members', (select count(*) from public.profiles),
    'questions', (select count(*) from public.questions where not is_removed),
    'answers', (select count(*) from public.answers where not is_removed),
    'solved', (select count(*) from public.questions where not is_removed and accepted_answer_id is not null),
    'helpful_votes', (select count(*) from public.helpful_votes),
    'arena_rounds', (select count(*) from public.quiz_attempts where completed_at is not null)
  )
$$;
grant execute on function public.get_platform_stats() to anon, authenticated;

-- ============ search ============
create or replace function public.search_questions(_q text, _category text default null)
returns setof public.questions language sql stable set search_path = public as $$
  with term as (
    select websearch_to_tsquery('english', coalesce(_q, '')) as tsq,
           '%' || replace(replace(replace(coalesce(_q, ''), '\', '\\'), '%', '\%'), '_', '\_') || '%' as pat
  )
  select q.* from public.questions q, term t
  where (_category is null or q.category_slug = _category)
    and char_length(trim(coalesce(_q, ''))) > 0
    and (
      q.search @@ t.tsq
      or q.title ilike t.pat
      or array_to_string(q.tags, ' ') ilike t.pat
      or q.category_slug ilike t.pat
      or exists (select 1 from public.answers a where a.question_id = q.id and not a.is_removed
                 and (a.search @@ t.tsq or a.body ilike t.pat))
    )
  order by ts_rank(q.search, t.tsq) desc, q.created_at desc
  limit 50
$$;
grant execute on function public.search_questions(text, text) to anon, authenticated;

create or replace function public.search_answers(_q text)
returns setof public.answers language sql stable set search_path = public as $$
  select a.* from public.answers a
  where char_length(trim(coalesce(_q, ''))) > 0
    and (a.search @@ websearch_to_tsquery('english', _q)
      or a.body ilike '%' || replace(replace(replace(_q, '\', '\\'), '%', '\%'), '_', '\_') || '%')
  order by ts_rank(a.search, websearch_to_tsquery('english', _q)) desc, a.created_at desc
  limit 30
$$;
grant execute on function public.search_answers(text) to anon, authenticated;

-- ============ admin ============
create or replace function public.admin_set_removed(_type text, _id uuid, _removed boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.has_role(auth.uid(), 'admin') then raise exception 'Forbidden'; end if;
  if _type = 'question' then update public.questions set is_removed = _removed where id = _id;
  elsif _type = 'answer' then update public.answers set is_removed = _removed where id = _id;
  elsif _type = 'comment' then update public.comments set is_removed = _removed where id = _id;
  else raise exception 'Unknown content type'; end if;
end; $$;
grant execute on function public.admin_set_removed(text, uuid, boolean) to authenticated;

create or replace function public.admin_list_users(_search text default null)
returns table (id uuid, username text, display_name text, avatar_url text, created_at timestamptz,
  question_count bigint, answer_count bigint, is_suspended boolean, is_admin boolean)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.has_role(auth.uid(), 'admin') then raise exception 'Forbidden'; end if;
  return query
    select p.id, p.username, p.display_name, p.avatar_url, p.created_at,
      (select count(*) from public.questions q where q.author_id = p.id),
      (select count(*) from public.answers a where a.author_id = p.id),
      exists (select 1 from public.account_suspensions s where s.user_id = p.id),
      exists (select 1 from public.user_roles r where r.user_id = p.id and r.role = 'admin')
    from public.profiles p
    where _search is null or p.username ilike '%' || _search || '%' or p.display_name ilike '%' || _search || '%'
    order by p.created_at desc
    limit 200;
end; $$;
grant execute on function public.admin_list_users(text) to authenticated;

-- ============ storage: avatars ============
create policy "Avatar images are publicly readable" on storage.objects for select
  using (bucket_id = 'avatars');
create policy "Users upload own avatar" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users update own avatar" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users delete own avatar" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
