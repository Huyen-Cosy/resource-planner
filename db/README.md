# Phase 1 — Dựng database trên Supabase (hướng dẫn cho người non-tech)

3 file SQL, chạy **đúng thứ tự**:

| Thứ tự | File | Làm gì |
|---|---|---|
| 1 | `schema.sql` | Tạo bảng + phân quyền (RBAC: PM ẩn tiền) |
| 2 | `views.sql` | Tạo các "view" tính toán (bức tranh công ty, tài chính…) |
| 3 | `seed.sql` | Nạp dữ liệu thật ideaLAB (đội ngũ + 2 dự án) |

> ⚠️ Bước tạo project Supabase + chạy SQL là **việc tay của bạn** — công cụ không tự đăng nhập tài khoản Supabase của bạn được. Làm 1 lần, ~10 phút.

## Bước 1 — Tạo project Supabase
1. Vào https://supabase.com → **Sign in** (đăng nhập bằng GitHub cho nhanh).
2. **New project** → đặt tên (vd `resource-planner`) → chọn vùng **Singapore** (gần VN nhất) → đặt **Database Password** (lưu lại) → **Create**. Chờ ~2 phút.

## Bước 2 — Chạy 3 file SQL
1. Menu trái → **SQL Editor** → **New query**.
2. Mở `db/schema.sql`, copy toàn bộ, dán vào, bấm **Run** (▶). Thấy "Success" là xong.
3. Làm lại với `db/views.sql`.
4. Làm lại với `db/seed.sql`.
   → Vào **Table Editor** kiểm tra: bảng `employees` có 12 người, `projects` có 2 dự án.

## Bước 3 — Bật đăng nhập (Authentication)
1. Menu trái → **Authentication** → **Providers** → bật **Email** (bật sẵn). 
2. (Khuyến nghị lúc đầu) **Authentication → Providers → Email → tắt "Confirm email"** để đỡ phải xác nhận email khi test. Bật lại khi chạy thật.

## Bước 4 — Tạo tài khoản admin ĐẦU TIÊN (quan trọng)
Mọi người đăng ký đều mặc định là `pm` (không thấy tiền). Người đầu tiên cần tự nâng thành `finance`:

1. **Authentication → Users → Add user** → nhập email + mật khẩu của bạn (vd email Huyên) → tạo.
2. Quay lại **SQL Editor**, chạy lệnh sau (đổi email cho đúng):
   ```sql
   update app_users set role = 'finance'
   where email = 'email-cua-ban@gmail.com';
   ```
3. Từ giờ bạn là `finance` (thấy tất cả). Mọi người khác đăng ký sau sẽ là `pm`; bạn vào màn **"Quản lý người dùng"** (Phase 2) để nâng ai thành `finance`.

## Bước 5 — Lấy 2 thông tin cho web app (Phase 2)
**Settings → API**, copy:
- **Project URL** (vd `https://abcxyz.supabase.co`)
- **anon public key** (key dài) — key này **được phép** nhúng vào web app (an toàn nhờ RLS).

> ❌ TUYỆT ĐỐI KHÔNG copy **service_role key** vào web/repo — đó là chìa khóa quản trị.

---

## Kiểm tra nhanh phân quyền đã đúng chưa
Trong SQL Editor (đang chạy quyền admin nên thấy hết) thử:
```sql
select * from v_project_margin;   -- ra margin 2 dự án
select * from v_capacity_gap;     -- bức tranh thiếu/đủ người
```
Khi web app chạy (Phase 2): đăng nhập bằng tài khoản `pm` → các view tài chính (`v_project_margin`, `v_employee_cost`…) trả **0 dòng**; đăng nhập `finance` → thấy đầy đủ. Đó là RBAC hoạt động.
