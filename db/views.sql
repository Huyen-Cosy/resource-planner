-- =====================================================================
-- Resource Planner — VIEWS (Phase 1)
-- "Toàn bộ tính toán nằm ở view" (D8) — 0 token vận hành.
-- Hai nhóm:
--   PUBLIC  (mọi user đăng nhập)  — KHÔNG chứa cột tiền.
--   FINANCE (chặn is_finance())   — rate, cost, margin. PM gọi → 0 dòng.
-- View do postgres sở hữu ⇒ bypass RLS base table; bảo mật nằm ở:
--   (a) view public không select cột tiền,  (b) view finance lọc is_finance().
-- Chạy SAU schema.sql.
-- =====================================================================

-- ---- Helpers nội bộ ----------------------------------------------------
-- Chi phí 1 người/tháng (triệu) nếu làm 100%. hourly(nghìn/giờ)×160/1000 → triệu.
create or replace view v_emp_cost as
  select id as employee_id,
         case when rate_type='hourly' then rate*160/1000.0 else rate end as monthly_cost
  from employees;

-- Rate trung bình theo role (fallback level Middle khi role chưa có người) — dùng cho ước lượng chi phí
create or replace view v_role_avg_cost as
  select r.code as role_code,
    coalesce(
      (select avg(case when e.rate_type='hourly' then e.rate*160/1000.0 else e.rate end)
         from employees e where e.role_code=r.code and e.active),
      (select monthly_rate from ref_level_rates where level='Middle')
    ) as avg_cost
  from ref_roles r;

-- Năng lực theo role: ưu tiên số người THẬT (active), fallback khai báo (D3/D15)
create or replace view v_role_capacity as
  select r.code as role_code,
    case when (select count(*) from employees e where e.role_code=r.code and e.active) > 0
         then (select count(*) from employees e where e.role_code=r.code and e.active)::numeric
         else r.declared_capacity end as capacity
  from ref_roles r;

-- =====================================================================
-- PUBLIC VIEWS (không tiền)
-- =====================================================================

-- Dự án — KHÔNG cột revenue/other_cost/mgmt_pct
create or replace view v_projects_public as
  select id, name, description, project_type, pm_owner, priority, status,
         start_month, end_month, roles, created_by,
         playbook_version, model_version, created_at, closed_at, close_note
  from projects;

-- Nhân sự — KHÔNG cột rate/rate_type
create or replace view v_employees_public as
  select id, name, role_code, level, active, created_at
  from employees;

-- Σ nhu cầu role×tháng (dự án active, kind=estimate)
create or replace view v_monthly_demand as
  select a.role_code, a.month, sum(a.headcount) as demand
  from allocations a
  join projects p on p.id = a.project_id
  where a.kind='estimate' and p.status='active'
  group by a.role_code, a.month;

-- Năng lực − nhu cầu theo role×tháng
create or replace view v_capacity_gap as
  select dm.role_code, dm.month, rc.capacity, dm.demand,
         rc.capacity - dm.demand as gap
  from v_monthly_demand dm
  join v_role_capacity rc on rc.role_code = dm.role_code;

-- Xung đột: role×tháng thiếu người, kèm tên dự án gây thiếu
create or replace view v_conflict as
  select g.role_code, g.month, g.capacity, g.demand, g.gap,
    (select string_agg(p.name, ', ')
       from allocations a join projects p on p.id=a.project_id
      where a.role_code=g.role_code and a.month=g.month
        and a.kind='estimate' and p.status='active' and a.headcount>0
    ) as projects
  from v_capacity_gap g
  where g.gap < 0;

-- Tải cá nhân theo tháng (>100 = quá tải) — % effort, không phải tiền
create or replace view v_employee_load as
  select s.employee_id, e.name, s.month, sum(s.percent) as load_pct
  from assignments s
  join employees e on e.id = s.employee_id
  group by s.employee_id, e.name, s.month;

-- Dư địa (slack): role×tháng còn trống người
create or replace view v_slack as
  select role_code, month, gap as slack
  from v_capacity_gap
  where gap > 0;

-- Vòng học: estimate vs actual (dự án closed)
create or replace view v_estimate_vs_actual as
  select est.project_id, est.role_code, est.month,
         est.headcount as estimate, act.headcount as actual,
         round(act.headcount / nullif(est.headcount,0), 2) as ratio
  from allocations est
  join allocations act
    on act.project_id=est.project_id and act.role_code=est.role_code
   and act.month=est.month and act.kind='actual'
  join projects p on p.id = est.project_id
  where est.kind='estimate' and p.status='closed';

-- Gợi ý norms: hệ số lệch TB theo project_type×role
create or replace view v_norm_suggestions as
  select p.project_type, est.role_code,
         avg(act.headcount / nullif(est.headcount,0)) as avg_ratio,
         count(*) as n
  from allocations est
  join allocations act
    on act.project_id=est.project_id and act.role_code=est.role_code
   and act.month=est.month and act.kind='actual'
  join projects p on p.id = est.project_id
  where est.kind='estimate' and p.status='closed'
  group by p.project_type, est.role_code;

-- =====================================================================
-- FINANCE VIEWS — chặn is_finance() (PM gọi → 0 dòng)
-- =====================================================================

-- Rate gợi ý theo level
create or replace view v_level_rates as
  select level, monthly_rate from ref_level_rates where is_finance();

-- Chi phí từng nhân sự (kèm rate)
create or replace view v_employee_cost as
  select e.id as employee_id, e.name, e.role_code, e.level,
         e.rate_type, e.rate,
         case when e.rate_type='hourly' then e.rate*160/1000.0 else e.rate end as monthly_cost
  from employees e
  where is_finance();

-- Dự án kèm cột tài chính
create or replace view v_projects_finance as
  select id, name, status, start_month, end_month,
         revenue, other_cost, mgmt_pct, revenue_collected
  from projects
  where is_finance();

-- Chi phí nhân sự theo dự án (công thức §2: ưu tiên người gán, fallback avgRoleCost)
create or replace view v_project_cost as
  with cell as (
    select a.project_id, a.role_code, a.month, a.headcount as need
    from allocations a
    where a.kind='estimate' and is_finance()
  ),
  asg as (
    select s.project_id, s.role_code, s.month,
           sum(s.percent/100.0) as fte,
           sum(s.percent/100.0 * ec.monthly_cost) as cost
    from assignments s
    join v_emp_cost ec on ec.employee_id = s.employee_id
    group by s.project_id, s.role_code, s.month
  )
  select c.project_id,
         sum( coalesce(asg.cost,0)
              + greatest(c.need - coalesce(asg.fte,0), 0) * rac.avg_cost ) as project_cost
  from cell c
  join v_role_avg_cost rac on rac.role_code = c.role_code
  left join asg on asg.project_id=c.project_id and asg.role_code=c.role_code and asg.month=c.month
  group by c.project_id;

-- Margin = revenue − (chi phí NS + chi phí khác + management) (D5/D16)
create or replace view v_project_margin as
  select p.id as project_id, p.name,
         p.revenue,
         coalesce(pc.project_cost,0) as project_cost,
         p.other_cost,
         (coalesce(pc.project_cost,0) + p.other_cost) * (p.mgmt_pct/100.0) as mgmt_cost,
         coalesce(pc.project_cost,0) + p.other_cost
           + (coalesce(pc.project_cost,0) + p.other_cost) * (p.mgmt_pct/100.0) as total_cost,
         p.revenue - ( coalesce(pc.project_cost,0) + p.other_cost
           + (coalesce(pc.project_cost,0) + p.other_cost) * (p.mgmt_pct/100.0) ) as margin
  from projects p
  left join v_project_cost pc on pc.project_id = p.id
  where is_finance();

-- ---- GRANTS: client đọc qua view (không đọc base table) -----------------
grant select on
  v_projects_public, v_employees_public, v_monthly_demand, v_capacity_gap,
  v_conflict, v_employee_load, v_slack, v_estimate_vs_actual, v_norm_suggestions,
  v_role_capacity
to authenticated;

-- view finance: vẫn cấp cho authenticated, nhưng tự lọc is_finance() bên trong
grant select on
  v_level_rates, v_employee_cost, v_projects_finance, v_project_cost, v_project_margin
to authenticated;
