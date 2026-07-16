-- ============================================================
-- Eden Nest ERP — Initial schema migration
-- Implements docs/erd.md — multi-company, multi-farm, multi-user
-- ============================================================

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ---------- Tenancy root ----------
create table companies (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  plan text not null default 'free',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table roles (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  permissions jsonb not null default '{}'::jsonb
);

create table users (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  role_id uuid not null references roles(id),
  name text not null,
  email text unique,
  phone text,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- ---------- Locations ----------
create table franchises (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  name text not null,
  city text not null,
  status text not null default 'concept', -- concept | planned | operating
  manager_user_id uuid references users(id),
  created_at timestamptz not null default now()
);

create table farms (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  franchise_id uuid references franchises(id),
  name text not null,
  location text not null,
  capacity int not null default 0,
  owner_user_id uuid references users(id),
  manager_user_id uuid references users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table farm_units (
  id uuid primary key default uuid_generate_v4(),
  farm_id uuid not null references farms(id),
  unit_type text not null, -- cage | coop | hatchery | packing_line
  name text not null,
  breed text,
  headcount int not null default 0,
  health_status text not null default 'Healthy',
  created_at timestamptz not null default now()
);

-- ---------- Operations ----------
create table production (
  id uuid primary key default uuid_generate_v4(),
  farm_unit_id uuid not null references farm_units(id),
  log_date date not null,
  birds_count int not null,
  feed_consumption_kg numeric(10,2) not null default 0,
  mortality int not null default 0,
  eggs_produced int not null default 0,
  broken_eggs int not null default 0,
  production_percentage numeric(5,2) generated always as (
    case when birds_count > 0 then round((eggs_produced::numeric / birds_count) * 100, 2) else 0 end
  ) stored,
  quality_grade text not null default 'A',
  created_by uuid references users(id),
  created_at timestamptz not null default now()
);

create table quality_checks (
  id uuid primary key default uuid_generate_v4(),
  farm_unit_id uuid not null references farm_units(id),
  batch_no text not null,
  check_date date not null,
  grade_a int not null default 0,
  grade_b int not null default 0,
  grade_c int not null default 0,
  rejected int not null default 0,
  notes text,
  created_at timestamptz not null default now()
);

create table complaints (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  customer_id uuid,
  batch_no text,
  issue text not null,
  status text not null default 'Open',
  created_at timestamptz not null default now()
);

-- ---------- Inventory ----------
create table inventory (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  farm_id uuid references farms(id),
  category text not null, -- Raw Materials | Finished Products | Packaging | Feed | Equipment
  item_name text not null,
  stock_qty numeric(12,2) not null default 0,
  unit text not null,
  reorder_level numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table inventory_batches (
  id uuid primary key default uuid_generate_v4(),
  item_id uuid not null references inventory(id),
  batch_no text not null,
  quantity numeric(12,2) not null,
  received_date date not null,
  expiry_date date,
  created_at timestamptz not null default now()
);

create table stock_movements (
  id uuid primary key default uuid_generate_v4(),
  item_id uuid not null references inventory(id),
  type text not null, -- 'Stock In' | 'Stock Out'
  quantity numeric(12,2) not null,
  batch_no text,
  notes text,
  created_by uuid references users(id),
  created_at timestamptz not null default now()
);

-- ---------- Products / Customers ----------
create table products (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  name text not null,
  category text not null,
  price numeric(12,2) not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table customers (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  cust_code text not null,
  name text not null,
  phone text not null,
  address text,
  location text,
  customer_type text not null default 'Retail', -- Premium | Subscription | Retail | B2B | Franchise
  created_at timestamptz not null default now(),
  unique (company_id, cust_code)
);

create table leads (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  name text not null,
  phone text,
  source text,
  stage text not null default 'New', -- New | Contacted | Converted | Lost
  last_contact date,
  notes text,
  created_at timestamptz not null default now()
);

-- ---------- Orders ----------
create table orders (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  customer_id uuid not null references customers(id),
  channel text not null, -- Website | WhatsApp | Mobile App | Sales Team
  status text not null default 'Order Created',
  -- Order Created -> Confirmed -> Packed -> Out for Delivery -> Delivered -> Payment Completed
  order_date date not null default current_date,
  total_amount numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);

create table order_items (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid not null references orders(id) on delete cascade,
  product_id uuid not null references products(id),
  quantity int not null,
  unit_price numeric(12,2) not null
);

create table subscriptions (
  id uuid primary key default uuid_generate_v4(),
  customer_id uuid not null references customers(id),
  plan text not null, -- Weekly | Biweekly | Monthly
  quantity int not null default 1,
  next_delivery date,
  status text not null default 'Active', -- Active | Paused | Cancelled
  created_at timestamptz not null default now()
);

create table payments (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid references orders(id),
  customer_id uuid not null references customers(id),
  amount numeric(12,2) not null,
  method text, -- UPI | Cash | Bank Transfer
  status text not null default 'Pending', -- Paid | Pending | Overdue
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

create table deliveries (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid references orders(id),
  zone text not null, -- Zone A | Zone B | Zone C
  driver_id uuid references users(id),
  status text not null default 'Scheduled', -- Scheduled | Out for delivery | Delivered | Failed
  scheduled_date date not null,
  cost numeric(10,2) not null default 0,
  cod_amount numeric(12,2) not null default 0,
  cod_collected boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------- Suppliers / Employees ----------
create table suppliers (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  category text not null, -- Feed Supplier | Packaging | Logistics | Veterinary | Other
  name text not null,
  contact text,
  terms text,
  outstanding numeric(12,2) not null default 0,
  last_order date,
  created_at timestamptz not null default now()
);

create table purchase_orders (
  id uuid primary key default uuid_generate_v4(),
  supplier_id uuid not null references suppliers(id),
  po_number text not null,
  items text not null,
  amount numeric(12,2) not null,
  status text not null default 'Ordered', -- Ordered | Received | Cancelled
  order_date date not null default current_date
);

create table supplier_payments (
  id uuid primary key default uuid_generate_v4(),
  supplier_id uuid not null references suppliers(id),
  amount numeric(12,2) not null,
  method text,
  status text not null default 'Pending',
  paid_date date
);

create table employees (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  farm_id uuid references farms(id),
  user_id uuid references users(id),
  role text not null,
  phone text,
  status text not null default 'Active', -- Active | On Leave
  joined_date date not null default current_date
);

-- ---------- Analytics (rollup) ----------
create table analytics (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references companies(id),
  metric_key text not null,
  metric_value numeric(14,2) not null,
  period text not null, -- e.g. '2026-07' or '2026-07-15'
  computed_at timestamptz not null default now()
);

-- ---------- Audit log ----------
create table audit_logs (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid,
  user_id uuid,
  table_name text not null,
  row_id uuid,
  action text not null, -- INSERT | UPDATE | DELETE
  old_values jsonb,
  new_values jsonb,
  ip_address text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- Row Level Security — enabled on every tenant-scoped table
-- ============================================================
do $$
declare
  t text;
begin
  for t in
    select unnest(array[
      'companies','users','franchises','farms','products','customers',
      'leads','orders','suppliers','employees','analytics','inventory',
      'complaints'
    ])
  loop
    execute format('alter table %I enable row level security;', t);
    execute format($f$
      create policy "tenant_isolation_select_%1$s" on %1$I for select
      using (
        case when %1$I = 'companies' then id = (auth.jwt() ->> 'company_id')::uuid
        else company_id = (auth.jwt() ->> 'company_id')::uuid end
      );
    $f$, t);
  end loop;
end $$;

-- Indexes for the columns every module filters/sorts by
create index idx_production_farm_unit_date on production(farm_unit_id, log_date desc);
create index idx_orders_company_status on orders(company_id, status);
create index idx_inventory_company_category on inventory(company_id, category);
create index idx_customers_company_type on customers(company_id, customer_type);
create index idx_deliveries_zone_date on deliveries(zone, scheduled_date);
