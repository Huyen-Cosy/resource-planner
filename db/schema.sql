-- =====================================================================
-- Resource Planner — SCHEMA (Phase 1)
-- Postgres / Supabase. Bám SPEC §4. Bổ sung RBAC theo D19:
--   - app_users (role 'pm' | 'finance'), trigger tạo dòng mặc định 'pm'
--   - RLS theo role: số tiền (rate, revenue, cost, margin) chỉ 'finance' đọc
--   - cơ chế đọc = qua VIEW (xem views.sql); base table không mở SELECT cho client
--
-- THỨ TỰ CHẠY:  schema.sql  →  views.sql  →  seed.sql
-- (seed chạy bằng SQL Editor = quyền postgres, bypass RLS — nạp data trực tiếp)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. RBAC core — app_users + helper is_finance()
-- ---------------------------------------------------------------------
create table if not exists app_users (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  email      text,
  role       text not null default 'pm' check (role in ('pm','finance')),
  created_at timestamptz default now()
);
comment on table app_users is 'Phân quyền theo user (D19). pm=chỉ effort, ẩn tiền | finance=CEO/Admin, thấy tất cả.';

-- user mới đăng ký (Supabase Auth) → tự tạo dòng role mặc định 'pm' (an toàn: chưa thấy tiền)
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into app_users (user_id, email, role)
  values (new.id, new.email, 'pm')
  on conflict (user_id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- "user hiện tại có phải finance không?" — dùng trong RLS & view tài chính.
-- auth.uid() IS NULL ⇒ ngữ cảnh service_role / postgres / SQL Editor (seed) → coi như full quyền.
-- An toàn vì: anon (chưa login) không có GRANT trên bảng/view nào; service_role là server-side, không phát cho PM.
create or replace function is_finance()
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is null
      or exists (
        select 1 from app_users
        where user_id = auth.uid() and role = 'finance'
      );
$$;

-- ---------------------------------------------------------------------
-- 1. Bảng tham chiếu (catalog)
-- ---------------------------------------------------------------------
create table if not exists ref_roles (
  code              text primary key,            -- 'DE','DS','DA','PM','PO','DATA_LEAD','ARCH','LARK','FIN','DESIGN'...
  name              text not null,
  declared_capacity numeric default 0,           -- năng lực KHAI BÁO (fallback khi chưa có người thật)
  sort_order        int default 0,
  is_management     boolean not null default false, -- chi phí tính qua management% (overhead), KHÔNG allocate trực tiếp (D5)
  is_primary        boolean not null default false  -- role chính của dự án data — ưu tiên hiển thị + default what-if/lưu nhanh
);

-- Rate gợi ý theo level — DỮ LIỆU NHẠY CẢM (chỉ finance đọc, qua v_level_rates)
create table if not exists ref_level_rates (
  level        text primary key,                 -- 'Intern','Junior','Middle','Senior','Lead'
  monthly_rate numeric not null                  -- triệu/tháng
);

create table if not exists ref_norms (
  key text primary key, value numeric, description text, updated_at timestamptz default now()
);
create table if not exists ref_project_types (code text primary key, name text);

-- ---------------------------------------------------------------------
-- 2. Nhân sự — rate theo CÁ NHÂN (D4). Cột rate/rate_type NHẠY CẢM.
-- ---------------------------------------------------------------------
create table if not exists employees (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  role_code  text not null references ref_roles(code),
  level      text references ref_level_rates(level),
  rate_type  text not null default 'monthly' check (rate_type in ('monthly','hourly')),
  rate       numeric not null default 0,         -- monthly: triệu/tháng | hourly: nghìn/giờ
  active     boolean not null default true,
  created_at timestamptz default now()
);

-- ---------------------------------------------------------------------
-- 3. Dự án. Cột revenue/other_cost/mgmt_pct NHẠY CẢM (tài chính).
-- ---------------------------------------------------------------------
create table if not exists projects (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  description      text,
  project_type     text references ref_project_types(code),
  pm_owner         text not null,
  priority         int default 3 check (priority between 1 and 5),
  status           text not null default 'active' check (status in ('draft','active','closed','cancelled')),
  start_month      date not null,                -- luôn ngày 01
  end_month        date not null,
  revenue          numeric default 0,            -- 💰 giá trị hợp đồng (triệu)
  other_cost       numeric default 0,            -- 💰 chi phí khác ngoài lương (triệu)
  mgmt_pct         numeric default 0,            -- 💰 % management overhead (D16)
  roles            text[] default '{}',          -- danh sách role tham gia (tường minh, D6)
  created_by       text not null,
  playbook_version text,
  model_version    text,
  created_at       timestamptz default now(),
  closed_at        timestamptz,
  close_note       text,
  check (end_month >= start_month),
  check (extract(day from start_month)=1 and extract(day from end_month)=1)
);

create table if not exists phases (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  name       text not null,
  start_month date not null,
  end_month   date not null,
  sort_order  int default 1,
  check (end_month >= start_month)
);

-- Nhu cầu mức role theo tháng (lớp kế hoạch cơ bản — luôn có, D3). KHÔNG nhạy cảm.
create table if not exists allocations (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  role_code  text not null references ref_roles(code),
  month      date not null,
  headcount  numeric not null check (headcount >= 0 and headcount <= 50),
  kind       text not null default 'estimate' check (kind in ('estimate','actual')),
  unique (project_id, role_code, month, kind),
  check (extract(day from month)=1)
);

-- Gán người cụ thể (OPTIONAL, D3). KHÔNG nhạy cảm (chỉ % tải, không phải tiền).
create table if not exists assignments (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects(id) on delete cascade,
  role_code   text not null references ref_roles(code),
  month       date not null,
  employee_id uuid not null references employees(id) on delete cascade,
  percent     numeric not null check (percent > 0 and percent <= 100),
  unique (project_id, role_code, month, employee_id),
  check (extract(day from month)=1)
);

-- Ghi chú dự án (free-text). Mọi user (pm & finance) đều tạo/sửa/xóa được — KHÔNG nhạy cảm tài chính.
-- KHÔNG phải tracking tiến độ (D1): đây chỉ là sổ ghi chú kế hoạch/thông tin của dự án, không có % hoàn thành/mốc hôm nay.
create table if not exists project_notes (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  body       text not null default '',
  author     text,                                  -- email người tạo (chỉ để hiển thị)
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- updated_at tự cập nhật mỗi lần sửa
create or replace function touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_project_notes_touch on project_notes;
create trigger trg_project_notes_touch
  before update on project_notes
  for each row execute function touch_updated_at();

-- Cấu hình AI model (Phase 5) — đưa bảng vào sớm để schema ổn định
create table if not exists app_llm_configs (
  id uuid primary key default gen_random_uuid(),
  label text not null, provider text not null,
  base_url text, model text,
  is_active boolean default false, sort_order int default 0
);

create table if not exists audit_log (
  id bigint generated always as identity primary key,
  actor text, action text, entity text, entity_id text, detail jsonb, at timestamptz default now()
);

-- ---------------------------------------------------------------------
-- 4. Trigger chặn ghi: PM không được gài số tiền vào projects (D19)
--    INSERT của non-finance → ép 0 ; UPDATE → giữ nguyên giá trị cũ.
-- ---------------------------------------------------------------------
create or replace function guard_project_financials()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not is_finance() then
    if tg_op = 'INSERT' then
      new.revenue := 0; new.other_cost := 0; new.mgmt_pct := 0;
    elsif tg_op = 'UPDATE' then
      new.revenue := old.revenue; new.other_cost := old.other_cost; new.mgmt_pct := old.mgmt_pct;
    end if;
  end if;
  return new;
end; $$;

drop trigger if exists trg_guard_project_fin on projects;
create trigger trg_guard_project_fin
  before insert or update on projects
  for each row execute function guard_project_financials();

-- =====================================================================
-- 5. RLS + GRANTS
-- Mô hình: client (anon/authenticated) KHÔNG đọc base table trực tiếp.
--   - Đọc: chỉ qua VIEW (views.sql). View tài chính tự chặn is_finance().
--   - Ghi: cấp DML cho 'authenticated' trên base table + policy + guard trigger.
-- anon (chưa đăng nhập) = không có gì → buộc phải login.
-- =====================================================================

-- bật RLS toàn bộ
alter table app_users        enable row level security;
alter table ref_roles        enable row level security;
alter table ref_level_rates  enable row level security;
alter table ref_norms        enable row level security;
alter table ref_project_types enable row level security;
alter table employees        enable row level security;
alter table projects         enable row level security;
alter table phases           enable row level security;
alter table allocations      enable row level security;
alter table assignments      enable row level security;
alter table project_notes    enable row level security;
alter table app_llm_configs  enable row level security;
alter table audit_log        enable row level security;

-- thu hồi mọi quyền mặc định của client trên base table
revoke all on all tables in schema public from anon, authenticated;

-- catalog KHÔNG nhạy cảm (ref_roles, ref_project_types, ref_norms): cho đọc trực tiếp
grant select on ref_roles, ref_project_types, ref_norms to authenticated;
-- ghi catalog: chỉ finance/admin — RLS gate qua is_finance(); GRANT phải có để policy có hiệu lực
grant insert, update, delete on ref_roles, ref_project_types, ref_norms to authenticated;
create policy ref_roles_write   on ref_roles        for all to authenticated using (is_finance()) with check (is_finance());
create policy ref_types_write   on ref_project_types for all to authenticated using (is_finance()) with check (is_finance());
create policy ref_norms_write   on ref_norms        for all to authenticated using (is_finance()) with check (is_finance());
-- (đọc catalog đã cấp qua GRANT ở trên; thêm policy select để RLS không chặn)
create policy ref_roles_read    on ref_roles        for select to authenticated using (true);
create policy ref_types_read    on ref_project_types for select to authenticated using (true);
create policy ref_norms_read    on ref_norms        for select to authenticated using (true);

-- ref_level_rates (rate gợi ý) = NHẠY CẢM: chỉ finance ghi; đọc đi qua v_level_rates
grant select, insert, update, delete on ref_level_rates to authenticated;
create policy lvl_rate_fin on ref_level_rates for all to authenticated using (is_finance()) with check (is_finance());

-- employees: đọc qua view (v_employees_public / v_employee_cost). Ghi (CRUD roster + rate) = finance.
grant select, insert, update, delete on employees to authenticated;
create policy emp_fin on employees for all to authenticated using (is_finance()) with check (is_finance());

-- projects: PM + finance đều tạo/sửa dự án (guard trigger chặn cột tiền của PM). Đọc qua view.
grant select, insert, update, delete on projects to authenticated;
create policy proj_write on projects for all to authenticated using (true) with check (true);

-- phases / allocations / assignments: lớp kế hoạch — authenticated (pm & finance) toàn quyền
grant select, insert, update, delete on phases, allocations, assignments to authenticated;
create policy phase_rw  on phases      for all to authenticated using (true) with check (true);
create policy alloc_rw  on allocations for all to authenticated using (true) with check (true);
create policy assign_rw on assignments for all to authenticated using (true) with check (true);

-- project_notes: ghi chú dự án — mọi user (pm & finance) toàn quyền CRUD (không nhạy cảm tài chính)
grant select, insert, update, delete on project_notes to authenticated;
create policy note_rw on project_notes for all to authenticated using (true) with check (true);

-- app_llm_configs: đọc authenticated, ghi finance
grant select, insert, update, delete on app_llm_configs to authenticated;
create policy llm_read  on app_llm_configs for select to authenticated using (true);
create policy llm_write on app_llm_configs for all to authenticated using (is_finance()) with check (is_finance());

-- app_users: mỗi người đọc dòng của mình; finance đọc & gán quyền tất cả (màn "Quản lý người dùng")
grant select, insert, update, delete on app_users to authenticated;
create policy au_self_read on app_users for select to authenticated using (user_id = auth.uid() or is_finance());
create policy au_fin_write on app_users for all   to authenticated using (is_finance()) with check (is_finance());

-- audit_log: authenticated ghi (log hành động), finance đọc
grant insert on audit_log to authenticated;
grant select on audit_log to authenticated;
create policy audit_insert on audit_log for insert to authenticated with check (true);
create policy audit_read   on audit_log for select to authenticated using (is_finance());

-- Lưu ý: base table projects/employees đã cấp SELECT cho 'authenticated' để PostgREST
-- trả về bản ghi sau ghi (return=representation). NHƯNG RLS + thực tế dùng:
--   * employees: policy emp_fin → chỉ finance select được dòng → PM không đọc rate qua base.
--   * projects: PM select được dòng (policy proj_write using true) KÈM cột tiền →
--     ⇒ App PM PHẢI đọc qua v_projects_public (không có cột tiền) và ghi với Prefer:return=minimal.
--     Đây là quy ước tầng app (Phase 2). Bảo đảm cứng cho "ẩn tiền khỏi PM" nằm ở:
--     report/bức tranh đọc qua view tài chính (is_finance) + form PM không hiển thị cột tiền.
-- (Nếu cần khóa cứng tuyệt đối cột tiền của projects khỏi PM ở tầng DB, tách bảng
--  project_financials RLS is_finance() — cân nhắc ở Phase 2, xem ghi chú D19.)
