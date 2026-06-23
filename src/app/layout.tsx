import type { Metadata } from "next";
import { Providers } from "@/components/providers";
import "./globals.css";

export const metadata: Metadata = {
  title: "Adventure",
  description: "Plan outdoor trips, log explorations, and revisit your adventures.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-adventure-sand text-gray-900 antialiased">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
