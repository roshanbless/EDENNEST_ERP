import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Eden Nest ERP",
  description: "The Operating System for Farm-to-Consumer Agriculture Businesses",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
