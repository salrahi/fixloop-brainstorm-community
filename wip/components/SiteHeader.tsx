import { useState } from "react";
import { Link, useNavigate } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { Bell, Menu, Search, X, Plus, LogOut, User, Settings, Shield } from "lucide-react";

import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Logo } from "./Logo";
import { UserAvatar } from "./UserAvatar";
import { cn } from "@/lib/utils";

const NAV = [
  { to: "/", label: "Home" },
  { to: "/explore", label: "Explore" },
  { to: "/community", label: "Community" },
  { to: "/ai", label: "FixLoop AI" },
  { to: "/arena", label: "Brain Arena" },
  { to: "/about", label: "About" },
] as const;

export function useUnreadCount() {
  const { user } = useAuth();
  return useQuery({
    queryKey: ["notifications", "unread", user?.id],
    enabled: !!user,
    refetchInterval: 60_000,
    queryFn: async () => {
      const { count, error } = await supabase
        .from("notifications")
        .select("id", { count: "exact", head: true })
        .eq("user_id", user!.id)
        .is("read_at", null);
      if (error) throw error;
      return count ?? 0;
    },
  });
}

export function SiteHeader() {
  const { user, profile, isAdmin, signOut, ready } = useAuth();
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  const navigate = useNavigate();
  const unread = useUnreadCount();
  const name = profile?.display_name || profile?.username || "You";

  const submitSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const term = q.trim();
    if (!term) return;
    setOpen(false);
    navigate({ to: "/search", search: { q: term, category: undefined } });
  };

  return (
    <header className="sticky top-0 z-40 border-b border-ink-foreground/10 bg-ink-deep/95 text-ink-foreground backdrop-blur supports-[backdrop-filter]:bg-ink-deep/85">
      <div className="mx-auto flex h-16 max-w-7xl items-center gap-3 px-4 sm:px-6">
        <Logo />
        <nav aria-label="Main" className="ml-4 hidden items-center gap-1 lg:flex">
          {NAV.map((item) => (
            <Link
              key={item.to}
              to={item.to}
              activeOptions={{ exact: item.to === "/" }}
              className="rounded-full px-3 py-1.5 text-sm text-ink-muted transition-colors hover:text-ink-foreground data-[status=active]:bg-ink-soft data-[status=active]:text-lime"
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <form onSubmit={submitSearch} className="ml-auto hidden md:block" role="search">
          <label className="relative block">
            <span className="sr-only">Search FixLoop</span>
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-muted" />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Search problems…"
              className="h-9 w-44 rounded-full border border-ink-foreground/15 bg-ink-soft/60 pl-9 pr-3 text-sm text-ink-foreground placeholder:text-ink-muted focus:w-60 focus:border-lime focus:outline-none transition-all xl:w-52"
            />
          </label>
        </form>

        <div className="ml-auto flex items-center gap-2 md:ml-0">
          {ready && user ? (
            <>
              <Button asChild variant="limeGlow" size="sm" className="hidden sm:inline-flex">
                <Link to="/ask">
                  <Plus /> Ask
                </Link>
              </Button>
              <Link
                to="/notifications"
                className="relative inline-flex h-9 w-9 items-center justify-center rounded-full text-ink-foreground hover:bg-ink-soft"
                aria-label={`Notifications${unread.data ? `, ${unread.data} unread` : ""}`}
              >
                <Bell className="h-5 w-5" />
                {!!unread.data && (
                  <span className="absolute -right-0.5 -top-0.5 min-w-5 rounded-full bg-lime px-1 text-center font-mono text-[10px] font-bold leading-5 text-lime-foreground">
                    {unread.data > 99 ? "99+" : unread.data}
                  </span>
                )}
              </Link>
              <DropdownMenu>
                <DropdownMenuTrigger className="rounded-full focus-visible:outline-2 focus-visible:outline-lime" aria-label="Account menu">
                  <UserAvatar name={name} src={profile?.avatar_url} size="sm" className="border-lime" />
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-56">
                  <DropdownMenuLabel className="truncate">
                    {name}
                    {profile && <span className="block text-xs font-normal text-muted-foreground">@{profile.username}</span>}
                  </DropdownMenuLabel>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem asChild>
                    <Link to="/me">
                      <User className="mr-2 h-4 w-4" /> My profile
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuItem asChild>
                    <Link to="/settings">
                      <Settings className="mr-2 h-4 w-4" /> Settings
                    </Link>
                  </DropdownMenuItem>
                  {isAdmin && (
                    <DropdownMenuItem asChild>
                      <Link to="/admin">
                        <Shield className="mr-2 h-4 w-4" /> Admin
                      </Link>
                    </DropdownMenuItem>
                  )}
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onSelect={() => signOut()}>
                    <LogOut className="mr-2 h-4 w-4" /> Log out
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </>
          ) : (
            <>
              <Link to="/auth" search={{ mode: "login", redirect: undefined }} className="hidden px-2 text-sm font-semibold text-ink-foreground hover:text-lime sm:inline">
                Login
              </Link>
              <Button asChild variant="limeGlow" size="sm">
                <Link to="/auth" search={{ mode: "signup", redirect: undefined }}>Get started</Link>
              </Button>
            </>
          )}
          <button
            className="inline-flex h-9 w-9 items-center justify-center rounded-full hover:bg-ink-soft lg:hidden"
            onClick={() => setOpen((v) => !v)}
            aria-expanded={open}
            aria-controls="mobile-nav"
            aria-label={open ? "Close menu" : "Open menu"}
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
      </div>

      <div
        id="mobile-nav"
        className={cn(
          "overflow-hidden border-t border-ink-foreground/10 transition-[max-height] duration-300 lg:hidden",
          open ? "max-h-[560px]" : "max-h-0 border-t-0",
        )}
      >
        <div className="space-y-1 px-4 py-4">
          <form onSubmit={submitSearch} role="search" className="mb-3">
            <label className="relative block">
              <span className="sr-only">Search FixLoop</span>
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-muted" />
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder="Search problems…"
                className="h-11 w-full rounded-full border border-ink-foreground/15 bg-ink-soft/60 pl-9 pr-3 text-base text-ink-foreground placeholder:text-ink-muted focus:border-lime focus:outline-none"
              />
            </label>
          </form>
          {NAV.map((item) => (
            <Link
              key={item.to}
              to={item.to}
              onClick={() => setOpen(false)}
              activeOptions={{ exact: item.to === "/" }}
              className="block rounded-xl px-3 py-3 font-pixel text-2xl text-ink-foreground data-[status=active]:bg-ink-soft data-[status=active]:text-lime"
            >
              {item.label}
            </Link>
          ))}
          {user ? (
            <Link to="/ask" onClick={() => setOpen(false)} className="mt-2 block rounded-xl bg-lime px-3 py-3 text-center font-semibold text-lime-foreground">
              Ask a question
            </Link>
          ) : (
            <Link
              to="/auth"
              search={{ mode: "login", redirect: undefined }}
              onClick={() => setOpen(false)}
              className="mt-2 block rounded-xl border border-ink-foreground/20 px-3 py-3 text-center font-semibold"
            >
              Login
            </Link>
          )}
        </div>
      </div>
    </header>
  );
}
