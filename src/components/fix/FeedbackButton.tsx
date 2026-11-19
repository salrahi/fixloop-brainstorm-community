import { useState } from "react";
import { useLocation } from "@tanstack/react-router";
import { MessageSquareHeart } from "lucide-react";
import { toast } from "sonner";

import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { errorMessage } from "@/lib/format";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

export const FEEDBACK_PROMPT = "What's one thing that confused you or that you'd change?";

export function FeedbackForm({ onDone }: { onDone?: () => void }) {
  const { user } = useAuth();
  const location = useLocation();
  const [message, setMessage] = useState("");
  const [anonymous, setAnonymous] = useState(true);
  const [busy, setBusy] = useState(false);
  const [sent, setSent] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    const text = message.trim();
    if (text.length < 3) {
      toast.error("Please write a few words first.");
      return;
    }
    setBusy(true);
    const { error } = await supabase.from("feedback").insert({
      message: text.slice(0, 1000),
      page: location.pathname.slice(0, 200),
      user_id: user && !anonymous ? user.id : null,
    });
    setBusy(false);
    if (error) {
      toast.error(errorMessage(error));
      return;
    }
    setSent(true);
    setMessage("");
    toast.success("Thank you — feedback received.");
    onDone?.();
  };

  if (sent && !onDone) {
    return (
      <div className="rounded-2xl bg-lime p-6 text-lime-foreground">
        <p className="font-pixel text-2xl">Thanks for looping back!</p>
        <p className="mt-1">Every note helps us make FixLoop better.</p>
        <button className="mt-3 text-sm font-semibold underline" onClick={() => setSent(false)}>
          Send another
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={submit} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="feedback-message">{FEEDBACK_PROMPT}</Label>
        <Textarea
          id="feedback-message"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          maxLength={1000}
          rows={5}
          placeholder="Be honest — nothing is too small."
          required
        />
        <p className="text-right text-xs text-muted-foreground">{message.length}/1000</p>
      </div>
      {user ? (
        <div className="flex items-center gap-2">
          <Checkbox id="feedback-anon" checked={anonymous} onCheckedChange={(v) => setAnonymous(v === true)} />
          <Label htmlFor="feedback-anon" className="font-normal">
            Send anonymously
          </Label>
        </div>
      ) : (
        <p className="text-xs text-muted-foreground">No name or email needed — feedback is anonymous.</p>
      )}
      <Button type="submit" variant="lime" disabled={busy} className="w-full sm:w-auto">
        {busy ? "Sending…" : "Send feedback"}
      </Button>
    </form>
  );
}

export function FeedbackButton() {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button
        onClick={() => setOpen(true)}
        className="fixed bottom-4 right-4 z-40 inline-flex items-center gap-2 rounded-full border-[1.5px] border-ink bg-lime px-4 py-2.5 text-sm font-semibold text-lime-foreground shadow-pop transition-transform hover:-translate-y-0.5 sm:bottom-6 sm:right-6"
        aria-label="Send feedback"
      >
        <MessageSquareHeart className="h-4 w-4" />
        <span className="hidden sm:inline">Feedback</span>
      </button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle className="font-pixel text-3xl">Feedback</DialogTitle>
            <DialogDescription>Help shape FixLoop. Takes 20 seconds.</DialogDescription>
          </DialogHeader>
          <FeedbackForm onDone={() => setOpen(false)} />
        </DialogContent>
      </Dialog>
    </>
  );
}
