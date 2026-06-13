# PROJECT CONTEXT — Resource Planner (dán vào knowledge của Project)

> Đọc file này đầu mỗi session mới để bắt nhịp ngay. Chi tiết xem SPEC / DECISIONS / BACKLOG / mockup.

## Đang làm gì
Xây **Resource Planner** — planning tool quản lý nguồn lực đa dự án cho công ty làm dịch vụ data. Nhiều PM nhập kế hoạch dự án (phase, nhu cầu nhân sự theo role×tháng), tool tổng hợp thành bức tranh nguồn lực toàn công ty + tài chính kế hoạch, và hỗ trợ CEO quyết định (dư địa nhận việc, what-if).

## Trạng thái hiện tại
- **Đã xong:** mockup HTML (đặc tả hành vi đầy đủ, 8 tab), spec, DECISIONS.md, BACKLOG.md.
- **Quyết định mới (06/2026):** RBAC vào MVP — PM ẩn tài chính, khóa tầng RLS, user tự đăng ký + admin gán quyền (D19). Seed dùng dữ liệu thật ideaLAB.
- **✅ Phase 1 ĐÃ DỰNG**: `db/schema.sql` + `db/views.sql` + `db/seed.sql` + `db/README.md`. Đã test trên Postgres 16: 3 file chạy sạch; RBAC verify (pm = 0 dòng tài chính, finance = đủ).
- **✅ Phase 1 ĐÃ DEPLOY lên Supabase thật (13/06/2026)**: project `resource-planner` (ref `nnqpanuezemrqyznkffy`, ap-southeast-1). Đã áp schema→views→seed; verify trên DB live: 12 nhân sự · 2 dự án · margin 34.8%/34.7%; RBAC qua JWT đạt (pm thấy `[]` ở mọi view tiền + guard chặn PM ghi cột tiền). Admin finance đầu tiên: `lethuhuyen215@gmail.com`. Lấy Project URL + anon key ở Settings → API cho Phase 2.
- **🚧 Phase 2 (slice 1, 13/06/2026):** `web/index.html` — tái dùng UI mockup v17 + thay localStorage→Supabase. Đã nối: login/logout (Supabase Auth), đọc toàn bộ qua VIEW (RBAC D19), ghi Supabase cho t3 (lưu chi tiết dự án), t4 Cách 1 (tạo dự án thủ công), t6 (CRUD nhân sự/role/rate, finance-only), xóa dự án. Hướng dẫn chạy/deploy ở `web/README.md`.
- **✅ Phase 2 (slice 2, 13/06/2026):** (1) **Ẩn tài chính cho `pm`**: gắn `.fin-only` vào output render tiền — renderProjects (cột Margin), renderFinance (cả card Tài chính dự án), renderKPIs (Σ margin), renderCEO (3 KPI tiền + 3 cột tiền trong bảng), t6 (card Rate theo level + 3 cột rate ở bảng nhân sự). CSS `body.role-pm .fin-only{display:none}` ẩn theo role. (2) **Màn "Quản lý người dùng"** ở t6 (card `fin-only`): finance liệt kê `app_users`, nút *Nâng → finance* (RLS `au_fin_write`).
- **✅ ĐÃ DEPLOY (13/06/2026):** Vercel team `lethuhuyen215-1989s-projects`, project `web`. **URL production: https://web-pied-iota-32.vercel.app** (đã tắt Vercel Auth/`ssoProtection`). Đã đăng ký URL vào **Supabase → Auth → Site URL + Redirect URLs** (qua Management API). Login admin finance verify OK trên link live. *Deploy: `npx vercel@latest deploy web --prod --yes --scope lethuhuyen215-1989s-projects` (token ở `.env` gitignored). Lưu ý egress: deploy cần `api.vercel.com`/`vercel.com`; muốn curl/test `*.vercel.app` từ Claude Code thì thêm host đó vào allowlist.*
- **Bước tiếp theo:** Phase 3 — gán người nâng cao (t3 assign + t7 Nguồn lực cá nhân); Phase 4 — CEO (t0 dư địa/what-if + t5 đóng dự án ghi actual). t4 Cách 2 (AI) + import CSV vào DB để Phase 5.
- **Hạ tầng Supabase (Phase 1 live):** project ref `nnqpanuezemrqyznkffy` (ap-southeast-1). Admin finance: `lethuhuyen215@gmail.com` (mật khẩu tạm — đổi sau lần đăng nhập đầu, KHÔNG commit mật khẩu vào repo). Áp lại SQL: `db/schema.sql → views.sql → seed.sql` qua SQL Editor hoặc Management API.

## 5 điều cốt lõi không được quên (chi tiết ở DECISIONS.md)
1. **Planning tool, KHÔNG phải tracking** — không có tiến độ/chi tiêu thực, mọi thứ là kế hoạch dự kiến.
2. **Granularity tháng × role**; gán người cụ thể là OPTIONAL (mọi thứ chạy được khi chưa gán ai).
3. **Rate theo cá nhân** (level + monthly/hourly), không theo role. Margin tiền là thước đo lời/lỗ duy nhất (đã bỏ "effort đã bán").
4. **Supabase = nguồn sự thật**; web app (vanilla HTML+JS) và Claude Code là 2 client độc lập. AI chỉ ở cửa estimation, mọi tính toán là SQL → 0 token vận hành.
5. **Stack free, tối giản:** Supabase + web tĩnh + Cloudflare/Vercel.

## Tech stack chốt
Supabase (Postgres + REST + Edge Functions + Storage, free tier) · web app vanilla HTML/JS + Frappe Gantt qua CDN · host Cloudflare Pages/Vercel · LLM free (Groq/Gemini/NVIDIA) qua Edge Function cho nút AI · repo skill riêng cho Claude Code `/estimate`.

## Cách làm việc giữa 2 nơi
- **Claude Chat (đây):** bàn THIẾT KẾ — "nên xây cái gì, vì sao". Sửa mockup thử ý tưởng. Cập nhật spec/decisions.
- **Claude Code:** THI CÔNG — "xây như thế nào". Viết schema, web app, deploy, sửa lỗi.
- Ranh giới: gõ đoạn dài giải thích "sản phẩm hoạt động thế nào" → về Claude Chat. Gõ "sửa lỗi/thêm theo spec/deploy" → ở Claude Code.
- Đồng bộ: spec + DECISIONS.md là điểm chung; ai đổi hướng thì cập nhật file, nơi kia đọc lại.

## Mở session mới nên nói gì
"Đọc PROJECT-CONTEXT + DECISIONS trong project. Ta đang ở [bước X]. Tôi muốn bàn tiếp về [Y]."
