-- =====================================================================
-- Resource Planner — STAGING schema `stg` (môi trường test, D-staging 06/2026)
-- Mục đích: sandbox để DIỄN TẬP migration (D22–D24…) + test logic cost/view
--           mà KHÔNG đụng dữ liệu production ở schema `public`.
-- Đánh đổi (PO chốt): free-tier đủ 2 project active → staging = SCHEMA riêng
--           trong cùng project, KHÔNG phải project riêng. Cô lập yếu hơn
--           (chung auth/anon key/project) nhưng $0 và đủ cho rehearsal + logic test.
--
-- CÁCH DỰNG / LÀM MỚI (idempotent — drop & rebuild):
--   1) chạy file này  → schema stg + bảng (clone cấu trúc) + COPY data từ public
--   2) chạy:  set search_path = stg, public;  rồi  \i db/views.sql
--      → 17 view tạo trong stg, tham chiếu bảng stg + stg.is_finance() (mở).
--   (Tự động hoá qua Management API: 2 lời gọi — file này, rồi search_path+views.sql.)
--
-- LƯU Ý: stg.is_finance() luôn TRUE → view finance (cost/margin) MỞ trong sandbox
--        để verify công thức tiền. KHÔNG dùng stg cho kiểm thử RLS/phân quyền
--        (đó là đặc thù cần project riêng — ngoài phạm vi staging-schema).
-- =====================================================================

drop schema if exists stg cascade;
create schema stg;

-- Sandbox: luôn là "finance" để view tiền tính được khi test (không phụ thuộc JWT)
create or replace function stg.is_finance() returns boolean
  language sql stable as $$ select true $$;

-- ---- Clone cấu trúc + COPY dữ liệu hiện tại từ public ------------------
-- (LIKE INCLUDING ALL: cột, default, CHECK, PK/UNIQUE, index. KHÔNG copy FK —
--  sandbox không cần ràng buộc liên bảng; dữ liệu nguồn vốn đã hợp lệ.)
create table stg.ref_roles          (like public.ref_roles          including all);
create table stg.ref_level_rates    (like public.ref_level_rates    including all);
create table stg.ref_project_types  (like public.ref_project_types  including all);
create table stg.ref_norms          (like public.ref_norms          including all);
create table stg.employees          (like public.employees          including all);
create table stg.projects           (like public.projects           including all);
create table stg.phases             (like public.phases             including all);
create table stg.allocations        (like public.allocations        including all);
create table stg.assignments        (like public.assignments        including all);
create table stg.app_users          (like public.app_users          including all);
create table stg.app_llm_configs    (like public.app_llm_configs    including all);
create table stg.audit_log          (like public.audit_log          including all);

insert into stg.ref_roles          select * from public.ref_roles;
insert into stg.ref_level_rates    select * from public.ref_level_rates;
insert into stg.ref_project_types  select * from public.ref_project_types;
insert into stg.ref_norms          select * from public.ref_norms;
insert into stg.employees          select * from public.employees;
insert into stg.projects           select * from public.projects;
insert into stg.phases             select * from public.phases;
insert into stg.allocations        select * from public.allocations;
insert into stg.assignments        select * from public.assignments;
insert into stg.app_users          select * from public.app_users;
insert into stg.app_llm_configs    select * from public.app_llm_configs;
insert into stg.audit_log          overriding system value select * from public.audit_log;  -- id = GENERATED ALWAYS identity
