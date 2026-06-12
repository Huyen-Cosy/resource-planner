# Resource Planner

Planning tool quản lý nguồn lực đa dự án cho công ty dịch vụ data. Nhiều PM nhập kế hoạch dự án (phase + nhu cầu nhân sự theo role×tháng); tool tổng hợp thành bức tranh nguồn lực toàn công ty + tài chính kế hoạch, hỗ trợ CEO ra quyết định (dư địa nhận việc, what-if).

> **Đây là PLANNING tool, không phải tracking tool.** Mọi số liệu là kế hoạch dự kiến — không có tiến độ/chi tiêu thực tế.

## Tech stack
Supabase (Postgres + REST + Edge Functions + Storage, free tier) · web app vanilla HTML/JS + Frappe Gantt qua CDN · host Cloudflare Pages/Vercel · LLM free qua Edge Function (chỉ ở cửa estimation, sau MVP).

## Cấu trúc
- `CLAUDE.md` — hướng dẫn cho Claude Code (đọc đầu tiên).
- `docs/` — tài liệu thiết kế: PROJECT-CONTEXT, DECISIONS, SPEC, BACKLOG, mockup.html (v17).
- `db/` — schema, seed, views (Phase 1).
- `web/` — web app (Phase 2+).
- `supabase/functions/` — Edge Function (Phase 5, sau MVP).

## Bắt đầu (build với Claude Code)
1. Mở Claude Code trong thư mục repo này.
2. Bảo Claude Code đọc `CLAUDE.md` → nó sẽ tự đọc tiếp `docs/` theo thứ tự và bắt đầu Phase 1.
3. Việc tay duy nhất: tạo Supabase project (free, ~2 phút) và chạy file SQL mà Claude Code sinh ra ở Phase 1.
4. Cuối mỗi phase: commit + push.

## Trạng thái
Chưa bắt đầu code thật. Đã có: spec đầy đủ, DECISIONS, BACKLOG, mockup v17 (đặc tả hành vi qua 17 phiên). Bước tiếp theo: Phase 1 — database schema.

## Lưu ý bảo mật
Không commit secret (`service_role` key, LLM API key, GitHub PAT). `.gitignore` đã chặn `.env*`. Supabase anon key được phép nhúng trong web app (giới hạn bởi RLS).
