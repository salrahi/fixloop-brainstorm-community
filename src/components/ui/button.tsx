import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-full text-sm font-semibold cursor-pointer transition-all duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:pointer-events-none disabled:opacity-50 disabled:cursor-not-allowed [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-ink-soft",
        lime: "bg-lime text-lime-foreground border-[1.5px] border-ink hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-pop active:translate-x-0 active:translate-y-0 active:shadow-none",
        limeGlow:
          "bg-lime text-lime-foreground hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-[4px_4px_0_0_var(--violet)]",
        violet: "bg-violet text-violet-foreground hover:bg-violet/90",
        ink: "bg-ink text-ink-foreground border-[1.5px] border-ink hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-pop-lime",
        outlineInk:
          "border-[1.5px] border-ink-foreground/40 text-ink-foreground bg-transparent hover:border-lime hover:text-lime",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline: "border-[1.5px] border-ink/80 bg-card text-foreground hover:bg-lavender-strong",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/70",
        ghost: "hover:bg-secondary text-foreground",
        link: "text-violet underline-offset-4 hover:underline rounded-md",
      },
      size: {
        default: "h-10 px-5",
        sm: "h-8 px-3 text-xs",
        lg: "h-12 px-7 text-base",
        xl: "h-14 px-8 text-base",
        icon: "h-10 w-10",
        iconSm: "h-8 w-8",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  },
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>, VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button";
    return (
      <Comp className={cn(buttonVariants({ variant, size, className }))} ref={ref} {...props} />
    );
  },
);
Button.displayName = "Button";

export { Button, buttonVariants };
