# Effort Data Entry — Playbook nhập effort thật & phân bổ

> Đúc kết từ đợt nhập effort thật 06/2026. Đọc file này khi cần **nhập/sửa effort nhân sự** vào resource-planner (tầng người) và đồng bộ lên **bức tranh công ty** (tầng role). 🟢 LIVING.

## 0. TL;DR luồng chuẩn
1. Lấy số theo **rule nguồn** (§1) → 2. Quy đổi **giờ ÷ 160 = %** (§3) → 3. Ghi vào **assignments** (tầng người) → 4. **RESYNC allocations = ΣFTE** (§4) để bức tranh công ty phản ánh → 5. Thêm role vào `projects.roles` nếu role mới (D6) → 6. Verify.

## 1. Nguồn dữ liệu (SOURCE-OF-TRUTH RULES) — bám sát, không tự suy
| Nhóm | Nguồn |
|---|---|
| Người **hourly rate** (Huyên, Dõng, Hiếu) | **Giờ thật từ Lark base OmniKey** (§2) |
| Người khác (Hạnh, Lâm, Mai, Tài, Vân, Ly…) | **Note phân bổ tay** do PM cung cấp (% kế hoạch) |
| Hiếu | Lark nếu có log; tháng nào Lark trống → PM bổ sung tay sau |

> ⚠️ Note đôi khi là **KẾ HOẠCH** (vd "T2: Hạnh/Lâm/Mai 100% SVN" nhưng Lark cho thấy T2 chỉ Huyên log SVN). Khi trộn: người-Lark = **thực**, người-note = **kế hoạch**. Đây là hệ quả chấp nhận được; nếu cần phân biệt rạch ròi thực/kế-hoạch ở DB → đó là việc của lớp burn-actual (D22, chưa build).

## 2. Lark OmniKey base — truy cập & cấu trúc
- Base: **"Project Management - OmniKey team"** (dạng wiki, domain `*.sg.larksuite.com`).
- **Credentials:** App ID + App Secret do **user cấp trong session** (env/paste) — **KHÔNG commit** (secret). App hiện **thiếu scope `wiki:node:read`** → gọi `wiki/v2/spaces/get_node` bị từ chối.
- **Mẹo vượt thiếu scope:** dùng **wiki node token THẲNG làm bitable `app_token`** (fallback chạy được):
  - API base: `https://open.larksuite.com/open-apis`
  - token: `POST /auth/v3/tenant_access_token/internal` `{app_id, app_secret}` → `tenant_access_token`
  - `app_token` = wiki token `WTlSwKw4Kig3ghk4NNqlCpMVgvh`
  - đọc: `/bitable/v1/apps/{app_token}/tables/{table_id}/fields|records` (header `Authorization: Bearer <token>`)
- **Cấu trúc:** 1 bảng / người. Bảng đã dùng:
  | Người | table_id |
  |---|---|
  | Huyên | `tblmUcoOz7B88Ss5` |
  | Hiếu | `tblTyYAgUQxb9Px4` |
  | Dõng | `tblnFlX3OCKaqXGA` |
  | Hạnh | `tbliilWPgqbQe7Ug` · Tido `tbloFvRi9DfGoNKY` · Búp `tbl0kDa2RvpYZq7L` |
  | **Master "Project Management"** | `tblKhTBDWrmFxUNX` |
- **Mỗi dòng task:** `Man hours spent` (số giờ), `Month Year` (text "MM-YYYY"), `Project ID` (link → master, lấy `.fields["Project ID"][0].record_ids[0]`).
- **Master** có `Khách hàng`, `Tên dự án`, và cột `Effort YYYY-MM` (tổng **cả team** theo dự án — dùng cross-check).
- **Lọc theo dự án:** map `record_id` master → `Khách hàng`. SVN = 2 master id (`recv6ummxlHUSG` Menu Engineering + `recviG4dCjvNM0` Project Management). Thanh Yến = Khách hàng `"Thanh Yen"`.
- **Tổng hợp:** group `(record_id dự án, Month Year)` → `sum(Man hours spent)`.

## 3. Quy đổi giờ → % (cách tính hiện tại — D4)
- **Chuẩn tháng = 160h** (D4: hourly rate × 160 = lương tháng; config hiển thị 200k/h × 160 = 32tr).
- `percent = round(giờ ÷ 160 × 100)` → lưu `assignments.percent` (= FTE fraction × 100).
- Người lương tháng (note): % là phân bổ kế hoạch trực tiếp (không qua giờ).

## 4. Hai tầng — viết đúng tầng (D3 / D21)
- **assignments** (người × role × tháng, `percent`): nơi nhập effort cá nhân.
- **allocations** (role × tháng, `headcount` FTE, `kind='estimate'`): nhu cầu mức role → **nguồn của BỨC TRANH CÔNG TY** (`v_monthly_demand`).
- Bức tranh công ty đọc **allocation, KHÔNG đọc assignment**. Nhập assignment xong **phải RESYNC** mới hiện:
  ```sql
  delete from allocations where kind='estimate' and project_id='<proj_id>';
  insert into allocations (project_id, role_code, month, headcount, kind)
    select project_id, role_code, month, round(sum(percent)/100.0, 2), 'estimate'
    from assignments where project_id='<proj_id>'
    group by project_id, role_code, month;
  ```
  (Đây là sync allocation←assignment **một chiều, thủ công, có chủ đích** — đúng tinh thần D21. KHÔNG phải B2/B3.)
- Role mới cho dự án → thêm vào `projects.roles` (D6) để hiện ở project detail/overview:
  ```sql
  update projects set roles = (select array(select distinct unnest(roles||array['LARK']) order by 1)) where id='<proj_id>';
  ```

## 5. Ghi vào Supabase production
- **Management API SQL endpoint** (env: `SUPABASE_ACCESS_TOKEN` + `SUPABASE_PROJECT_REF`):
  `POST https://api.supabase.com/v1/projects/{ref}/database/query` body `{"query":"..."}` (build JSON bằng `jq -Rs '{query:.}'` để khỏi lỗi escape).
- Tháng lưu **ngày tuyệt đối** `YYYY-MM-01` (không phải index — D20). Ràng buộc: `percent` 0<x≤100; `headcount` 0≤x≤50; UNIQUE(project,role,month,employee) & (project,role,month,kind).
- **Đổi schema/view → diễn tập trên `stg` trước** (`db/staging.sql`, xem `db/README.md`).

## 6. Map dự án resource-planner ↔ Lark client
| resource-planner | id | Lark "Khách hàng" |
|---|---|---|
| SVN × ideaLAB | c2 | SVN |
| Thanh Yến Treasury | c1 | Thanh Yen |
| NutriNest 2 — BI | c4 | NutriNest |
| Rabity — BI | c3 | Rabity *(lưu ý: OmniKey base có nhiều dự án Rabity SCM/quy-trình — KHÁC dự án BI dashboard; cẩn thận khi map)* |

## 7. Snapshot đã nhập (06/2026)
- **Huyên/Dõng/Hiếu = Lark** (giờ÷160); **còn lại = note**. Quy ước người: Huyên chỉ **SVN+TY** (bỏ Rabity dù Lark có); Hiếu **SVN T1/T2 chờ bổ sung**.
- SVN: DA (Hạnh/Mai/Vân) + DE (Lâm 100/Tài 50) copy đều T1→T6 phần đầu; PM Huyên 12/10/22/16/17/6; DESIGN Hiếu T3/T4.
- Thanh Yến: Huyên 13/38/38/20 · Hiếu 12/35 · **Dõng (LARK) 17/34/14** · Tài · Vân.
- Allocation đã **resync** từ assignment cho cả 4 dự án → bức tranh công ty phản ánh số thật.

> Khi nhập đợt mới: lặp lại §0. Nếu chỉ sửa vài người → vẫn phải resync allocation của dự án đó (§4) thì overview mới đúng.
