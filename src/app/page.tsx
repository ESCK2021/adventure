"use client";

import { Button } from "@heroui/react";

export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-lg flex-col items-center justify-center gap-6 px-6 text-center">
      <p className="text-sm font-medium uppercase tracking-widest text-adventure-green">
        Adventure
      </p>
      <h1 className="text-4xl font-bold text-adventure-earth">
        Your trips, journals, and trails — together.
      </h1>
      <p className="text-lg text-gray-600">
        Bootstrap complete. Next: Figma design system, then implementation per{" "}
        <code className="rounded bg-white/80 px-1">docs/brief.md</code>.
      </p>
      <Button color="primary" className="bg-adventure-green">
        Coming soon
      </Button>
    </main>
  );
}
