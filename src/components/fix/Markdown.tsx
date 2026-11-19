import ReactMarkdown from "react-markdown";
import { cn } from "@/lib/utils";

export function Markdown({ children, className }: { children: string; className?: string }) {
  return (
    <div className={cn("prose-fix", className)}>
      <ReactMarkdown
        components={{
          a: ({ href, children: c }) => (
            <a href={href} target="_blank" rel="noopener noreferrer nofollow">
              {c}
            </a>
          ),
          img: () => null,
        }}
      >
        {children}
      </ReactMarkdown>
    </div>
  );
}

/** Plain text with preserved line breaks — used for user posts (no HTML). */
export function PlainText({ children, className }: { children: string; className?: string }) {
  return <div className={cn("whitespace-pre-wrap break-words leading-relaxed", className)}>{children}</div>;
}
