import { Link } from "@tanstack/react-router";
import { cn } from "@/lib/utils";

export function LogoMark({ className }: { className?: string }) {
  // Pixel loop: an 8x8 grid ring with a lime "spark" — the problem going in, the fix coming out.
  const cells = [
    [2, 0], [3, 0], [4, 0], [5, 0],
    [1, 1], [6, 1],
    [0, 2], [7, 2], [0, 3], [7, 3], [0, 4], [7, 4], [0, 5], [7, 5],
    [1, 6], [6, 6],
    [2, 7], [3, 7], [4, 7],
  ];
  return (
    <svg viewBox="0 0 8 8" className={cn("h-7 w-7", className)} aria-hidden="true" shapeRendering="crispEdges">
      {cells.map(([x, y]) => (
        <rect key={`${x}-${y}`} x={x} y={y} width="1" height="1" fill="currentColor" />
      ))}
      <rect x="5" y="7" width="1" height="1" className="fill-lime" />
      <rect x="6" y="7" width="2" height="1" className="fill-lime" />
      <rect x="3" y="3" width="2" height="2" className="fill-lime" />
    </svg>
  );
}

export function Logo({ className, tone = "light" }: { className?: string; tone?: "light" | "dark" }) {
  return (
    <Link
      to="/"
      className={cn(
        "inline-flex items-center gap-2 font-pixel text-2xl leading-none",
        tone === "light" ? "text-ink-foreground" : "text-ink",
        className,
      )}
      aria-label="FixLoop home"
    >
      <LogoMark />
      <span>FixLoop</span>
    </Link>
  );
}
