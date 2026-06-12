import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AI Bridge Sync",
  description: "Iron Forge Studios — MCP-only AI context synchronization",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-gray-950 text-gray-100">{children}</body>
    </html>
  );
}
