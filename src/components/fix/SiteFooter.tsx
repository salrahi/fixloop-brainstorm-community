import { Link } from "@tanstack/react-router";
import { Logo } from "./Logo";

const LINKS = [
  { to: "/about", label: "About" },
  { to: "/guidelines", label: "Community Guidelines" },
  { to: "/privacy", label: "Privacy Policy" },
  { to: "/terms", label: "Terms" },
  { to: "/contact", label: "Contact" },
  { to: "/contact", label: "Feedback", hash: "feedback" },
] as const;

export function SiteFooter() {
  return (
    <footer className="grain bg-ink-deep text-ink-foreground">
      <div className="mx-auto max-w-7xl px-4 py-14 sm:px-6">
        <div className="flex flex-col gap-10 md:flex-row md:items-end md:justify-between">
          <div className="max-w-sm">
            <Logo />
            <p className="mt-4 text-ink-muted">Find Solutions. Share Experiences.</p>
            <p className="mt-1 font-pixel text-xl text-lime">Every problem deserves a possibility.</p>
          </div>
          <nav aria-label="Footer" className="grid grid-cols-2 gap-x-10 gap-y-3 text-sm sm:grid-cols-3">
            {LINKS.map((l) => (
              <Link key={l.label} to={l.to} hash={"hash" in l ? l.hash : undefined} className="text-ink-muted hover:text-lime">
                {l.label}
              </Link>
            ))}
          </nav>
        </div>
        <div className="mt-12 flex flex-col gap-2 border-t border-ink-foreground/10 pt-6 text-xs text-ink-muted sm:flex-row sm:justify-between">
          <span>© {new Date().getFullYear()} FixLoop. Built by the community, for the community.</span>
          <span className="eyebrow">Problems in · Solutions out</span>
        </div>
      </div>
    </footer>
  );
}
