import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "LeadLatch — Speed-to-Lead Autopilot",
  description: "Capture, engage, and convert leads automatically.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-gray-50 text-gray-900 antialiased">{children}</body>
    </html>
  );
}
