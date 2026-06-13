# Phase 2 — Web app (`web/index.html`)

App thật: vanilla HTML/JS, nối thẳng Supabase (đã deploy ở Phase 1). Không build step.
Tái dùng UI mockup v17 (`docs/mockup-idealab.html`) + thay tầng dữ liệu localStorage → Supabase.

## Chạy thử local
File tĩnh — KHÔNG mở bằng `file://` (CORS chặn fetch). Phải qua HTTP server:
```bash
cd web && python3 -m http.server 8080
# mở http://localhost:8080
```
Đăng nhập bằng tài khoản đã tạo ở Phase 1 (admin finance: `lethuhuyen215@gmail.com`).

## Đã nối Supabase (Phase 2 slice 1)
| Việc | Trạng thái |
|---|---|
| Đăng nhập / đăng xuất (Supabase Auth, email+password) | ✅ |
| Đọc toàn bộ dữ liệu từ Supabase (role/nhân sự/dự án/phase/alloc/assign) | ✅ |
| RBAC: đọc qua VIEW; view tài chính lọc `is_finance()` (D19) | ✅ |
| t3 — Lưu chi tiết dự án (thời gian + phase + phân bổ + gán người + tài chính) | ✅ ghi Supabase |
| t4 — Tạo dự án thủ công (Cách 1) | ✅ ghi Supabase (uuid do DB sinh) |
| t6 — CRUD nhân sự / role / năng lực khai báo / rate theo level | ✅ ghi Supabase (chỉ finance) |
| Xóa dự án | ✅ ghi Supabase (cascade) |

## Chưa nối DB ở slice này (việc tiếp theo)
- **Ẩn tài chính cho role `pm`**: dữ liệu tiền đã KHÔNG lộ (view trả 0 dòng cho pm), nhưng UI còn hiển thị ô tiền = 0. Cần gắn class `.fin-only` vào output các hàm render tài chính (CSS `body.role-pm .fin-only{display:none}` đã sẵn). → polish kế tiếp.
- **t4 Cách 2 — AI Generate** và **t5 — Đóng dự án (ghi actual)**: thuộc Phase 5 / Phase 4, chưa ghi DB.
- **Import CSV nhiều file**: hiện chỉ nạp vào bộ nhớ, chưa đẩy Supabase.

## Cấu hình
`SUPABASE_URL` + `SUPABASE_ANON_KEY` nhúng ngay đầu khối `<script>` tích hợp (cuối file).
Anon key **được phép** công khai — an toàn nhờ RLS (SPEC §7). Không bao giờ nhúng service_role.

## Deploy (free)
**Cloudflare Pages:** New project → Connect repo → build command để trống, output dir `web` → Deploy.
**Vercel:** Import repo → Framework Preset "Other" → Root Directory `web` → Deploy.
Sau deploy, vào Supabase **Authentication → URL Configuration** thêm domain vào **Site URL / Redirect URLs** (cần cho luồng email; password login không bắt buộc).
