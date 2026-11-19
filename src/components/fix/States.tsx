import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

export function PixelLoader({ label = "Loading", className }: { label?: string; className?: string }) {
  return (
    <div role="status" className={cn("flex flex-col items-center justify-center gap-3 py-12", className)}>
      <div className="grid grid-cols-3 gap-1" aria-hidden="true">
        {Array.from({ length: 9 }).map((_, i) => (
          <span
            key={i}
            className="h-2.5 w-2.5 bg-violet animate-pulse"
            style={{ animationDelay: `${(i % 3) * 120 + Math.floor(i / 3) * 120}ms` }}
          />
        ))}
      </div>
      <span className="eyebrow text-muted-foreground">{label}…</span>
    </div>
  );
}

export function SkeletonCard() {
  return (
    <div className="rounded-2xl border border-border bg-card p-5">
      <div className="h-3 w-24 animate-pulse rounded bg-muted" />
      <div className="mt-4 h-5 w-3/4 animate-pulse rounded bg-muted" />
      <div className="mt-2 h-4 w-full animate-pulse rounded bg-muted" />
      <div className="mt-2 h-4 w-2/3 animate-pulse rounded bg-muted" />
    </div>
  );
}

export function EmptyState({
  title,
  body,
  action,
  glyph = "?",
  className,
}: {
  title: string;
  body?: ReactNode;
  action?: ReactNode;
  glyph?: string;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "relative overflow-hidden rounded-3xl border-[1.5px] border-dashed border-ink/30 bg-card px-6 py-14 text-center",
        className,
      )}
    >
      <div className="pixel-dots pointer-events-none absolute inset-0 text-violet opacity-40" aria-hidden="true" />
      <div className="relative">
        <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-lime font-pixel text-4xl text-lime-foreground shadow-pop">
          {glyph}
        </div>
        <h3 className="font-pixel text-2xl text-ink">{title}</h3>
        {body && <p className="mx-auto mt-2 max-w-md text-muted-foreground">{body}</p>}
        {action && <div className="mt-6 flex flex-wrap justify-center gap-3">{action}</div>}
      </div>
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div role="alert" className="rounded-2xl border-[1.5px] border-destructive/50 bg-card p-6 text-center">
      <p className="font-semibold text-destructive">Couldn't load this</p>
      <p className="mt-1 text-sm text-muted-foreground">{message}</p>
      {onRetry && (
        <button onClick={onRetry} className="mt-3 text-sm font-semibold text-violet underline">
          Try again
        </button>
      )}
    </div>
  );
}
