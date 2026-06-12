import Link from "next/link";

export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-8">
      <h1 className="text-4xl font-bold tracking-tight">LeadLatch</h1>
      <p className="mt-2 text-lg text-gray-600">
        Speed-to-Lead Autopilot
      </p>
      <div className="mt-8 flex gap-4">
        <Link
          href="/auth/login"
          className="rounded-lg bg-blue-600 px-6 py-3 text-sm font-medium text-white hover:bg-blue-700"
        >
          Sign In
        </Link>
        <Link
          href="/auth/login?tab=signup"
          className="rounded-lg border border-gray-300 px-6 py-3 text-sm font-medium hover:bg-gray-100"
        >
          Get Started
        </Link>
      </div>
    </main>
  );
}
