-- Minimal seed data for local development / demos
insert into roles (id, name, permissions) values
  (uuid_generate_v4(), 'Owner', '{"all": true}'),
  (uuid_generate_v4(), 'Manager', '{"manage_operations": true}'),
  (uuid_generate_v4(), 'Staff', '{"read_only": false, "log_production": true}');

insert into companies (id, name, plan) values
  ('00000000-0000-0000-0000-000000000001', 'Eden Nest Farm', 'free');

-- Add your first user via Supabase Auth, then link their auth.uid()
-- into the `users` table with company_id = the row above.
