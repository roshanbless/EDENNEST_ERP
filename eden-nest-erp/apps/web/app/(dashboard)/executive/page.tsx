import { createClient } from "@/lib/supabase/server";

/**
 * Phase 1 MVP dashboard: pulls core KPIs only (per docs/erd.md §8).
 * RLS scopes every query to the signed-in user's company_id automatically —
 * no company_id filter is added here on purpose.
 */
export default async function ExecutiveDashboardPage() {
  const supabase = createClient();

  const [{ count: customerCount }, { count: pendingOrders }, { data: lowStock }] =
    await Promise.all([
      supabase.from("customers").select("*", { count: "exact", head: true }),
      supabase
        .from("orders")
        .select("*", { count: "exact", head: true })
        .eq("status", "Order Created"),
      supabase.from("inventory").select("id, item_name, stock_qty, reorder_level"),
    ]);

  const lowStockItems = (lowStock ?? []).filter(
    (item) => item.stock_qty <= item.reorder_level
  );

  return (
    <main className="p-8">
      <h1 className="mb-6 font-semibold text-2xl">Executive Dashboard</h1>

      <div className="grid grid-cols-3 gap-4">
        <StatCard label="Total Customers" value={customerCount ?? 0} />
        <StatCard label="Orders Created" value={pendingOrders ?? 0} />
        <StatCard label="Low Stock Alerts" value={lowStockItems.length} />
      </div>
    </main>
  );
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-xl border border-neutral-200 bg-white p-4 shadow-sm">
      <div className="text-xs uppercase tracking-wide text-neutral-500">{label}</div>
      <div className="mt-2 font-semibold text-2xl">{value}</div>
    </div>
  );
}
