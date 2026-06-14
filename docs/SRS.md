# SRS — Software Requirements Specification
## Resource Planner (ideaLAB)

> **⚠ BASELINE SNAPSHOT @14/06/2026 — KHÔNG sửa từng commit.** Doc yêu cầu **sống** là `user-stories.md` (NFR đã chuyển vào Phụ lục A của nó). File này là bản formal chụp tại thời điểm, dùng khi cần FR formal (khách/đấu thầu/sign-off) — **regenerate từ `user-stories.md` + code khi cần**, đừng maintain song song.
>
> **Mục đích:** đặc tả **chức năng (FR)** và **phi chức năng (NFR)** chi tiết, có **truy vết** ngược về BR (xem `BRD.md`). Schema/view kỹ thuật đầy đủ ở `SPEC.md`. Lý do thiết kế ở `DECISIONS.md`.
>
> **Phiên bản:** 1.0 · **Ngày:** 14/06/2026 · **Vai:** PO/BA · Trạng thái: ✅ Done · 🔵 Backlog · ◻️ Một phần.

---

## 1. Tổng quan hệ thống

Web app **vanilla HTML/JS một trang** (8 tab), client trực tiếp gọi **Supabase** (Postgres + REST + Auth + RLS). **Mọi tính toán nằm ở SQL view**; client chỉ render + ghi. Host tĩnh trên **Vercel**. Đăng nhập bắt buộc; phân quyền 2 tầng (`pm` / `finance`) khóa ở DB.

**Actor:** PM (`pm`), CEO/BOD/Admin (`finance`).

## 2. Yêu cầu chức năng (Functional Requirements)

> Quy ước ID: `FR-<tab>.<n>`. Cột BR = truy vết về Business Requirement.

### 2.1 Xác thực & Phân quyền (Auth & RBAC)
| ID | Chức năng | BR | TT |
|---|---|---|---|
| FR-AUTH.1 | Đăng nhập bằng email/mật khẩu (Supabase Auth); chưa đăng nhập → màn login | BR-11 | ✅ |
| FR-AUTH.2 | Sau đăng nhập, đọc role từ `app_users` (mặc định `pm` qua trigger `handle_new_user`) | BR-11 | ✅ |
| FR-AUTH.3 | Role `pm`: **ẩn toàn bộ số tiền** (rate, chi phí, margin, doanh thu, management) ở UI (`.fin-only`) **và** ở DB (view bọc `is_finance()` trả `[]`; guard trigger ép cột tiền = 0) | BR-11 | ✅ |
| FR-AUTH.4 | Role `finance`: thấy tất cả + màn "Quản lý người dùng" (nâng `pm`→`finance`) | BR-11, BR-12 | ✅ |
| FR-AUTH.5 | Đăng xuất | — | ✅ |

### 2.2 t0 — Tổng quan CEO/BOD
| ID | Chức năng | BR | TT |
|---|---|---|---|
| FR-T0.1 | 5 KPI: số dự án, tổng doanh thu, tổng margin %, số dự án lỗ, lượt role-tháng thiếu (KPI tiền là `.fin-only`) | BR-06 | ✅ |
| FR-T0.2 | Bảng margin từng dự án, sắp **lỗ-nhất lên đầu**; cột Doanh thu/Chi phí/Margin (fin-only) + "Đã xếp người %" | BR-06 | ✅ |
| FR-T0.3 | Cảnh báo kế hoạch xếp theo **mức thiệt hại** + gợi ý hành động | BR-03, BR-06 | ✅ |
| FR-T0.4 | **Dư địa nhận việc** theo **khoảng tháng Từ→Đến tự chọn** (mọi năm, thứ tự không quan trọng); badge số tháng; trình bày **"trung bình ~X người rảnh/tháng"** + chi tiết người-tháng; role có-assign trên, quản lý/không-PIC dưới | BR-07 | ✅ |
| FR-T0.5 | **What-if**: nhập tháng bắt đầu/số tháng/doanh thu + nhu cầu role (4 role chính default 1) → margin dự kiến + có tạo thiếu hụt không; **không lưu** | BR-08 | ✅ |
| FR-T0.6 | **Lọc dự án** (checkbox Tất cả + từng dự án) → KPI/margin/cảnh báo/dư địa/what-if tính lại theo lựa chọn | BR-14 | ✅ |
| FR-T0.7 | Panel "Cách tính các con số" + tooltip ⓘ minh bạch công thức | BR-06 | ✅ |
| FR-T0.8 | Xuất báo cáo **PDF** (print) + **Word** (.doc) | BR-13 | ✅ |
| FR-T0.9 | Chọn phạm vi: dự án active / gồm cả nháp | BR-06 | ✅ |

### 2.3 t1 — Bức tranh công ty
| ID | Chức năng | BR | TT |
|---|---|---|---|
| FR-T1.1 | Ma trận **role × tháng**: demand / capacity, màu thiếu/đủ/nhàn rỗi; trục tháng tự mở rộng theo dự án xa nhất | BR-02 | ✅ |
| FR-T1.2 | Sắp role: có-assign lên trên, quản lý + không-PIC xuống dưới | BR-02 | ✅ |
| FR-T1.3 | Danh sách cảnh báo xung đột (tháng/role thiếu) + link mở dự án gây thiếu | BR-03 | ✅ |

### 2.4 t2 — Danh sách dự án
| ID | Chức năng | BR | TT |
|---|---|---|---|
| FR-T2.1 | Bảng dự án (Loại, PM, Ưu tiên, Thời gian, Margin KH fin-only, Trạng thái); bấm dòng mở chi tiết | BR-01 | ✅ |
| FR-T2.2 | Xóa dự án (cascade DB) | BR-01 | ✅ |
| FR-T2.3 | Import nhiều dự án qua CSV | — | ◻️ Lớp localStorage cũ (chưa ghi DB) |

### 2.5 t3 — Chi tiết dự án
| ID | Chức năng | BR | TT |
|---|---|---|---|
| FR-T3.1 | Chọn dự án; sửa thời gian dự án (start/end, +3 tháng/+1 năm) | BR-01 | ✅ |
| FR-T3.2 | **Roadmap/phase**: Gantt + **thêm / đổi tên / xóa phase**, sửa tháng bắt đầu/kết thúc | BR-01 | ✅ |
| FR-T3.3 | **Phân bổ role × tháng**: sửa inline, điền nhanh theo khoảng, thêm/xóa role | BR-01 | ✅ |
| FR-T3.4 | **Gán người**: bulk-assign (người × khoảng tháng × %), sửa %/xóa từng người, cột "Đã gán/Cần" (FTE 3 màu) | BR-05 | ✅ |
| FR-T3.5 | **Cảnh báo quá tải xuyên dự án**: banner + chip đỏ ⚠ khi 1 người > 100% (cộng cả dự án khác), refresh live | BR-05 | ✅ |
| FR-T3.6 | **Card Tài chính** (fin-only): nhập doanh thu / chi phí khác / management%; KPI margin; burn theo tháng | BR-04 | ✅ |
| FR-T3.7 | **Bảng "Chi tiết cấu thành chi phí"**: rate từng người đã gán + phần chưa gán (rate TB role) → Σ NS → +khác → +mgmt → tổng → margin; diễn giải cột "Người-tháng" | BR-04 | ✅ |
| FR-T3.8 | Nút **Lưu** (ở card Roadmap, Phân bổ, Tài chính) — 1 nút lưu hết qua `persistProject`; cờ "chưa lưu" | BR-01 | ✅ |

### 2.6 t4 — Tạo dự án mới
| ID | Chức năng | BR | TT |
|---|---|---|---|
| FR-T4.1 | Bước 1 — Thông tin dự án (nhập tay, sẽ lưu): Tên, Loại (nạp từ `ref_project_types`), PM, Tháng bắt đầu, Ưu tiên, Doanh thu (fin-only), Deadline (mốc tham chiếu) | BR-01 | ✅ |
| FR-T4.2 | **Lưu nhanh với mặc định**: tự sinh 1 phase phủ khung (Tháng bắt đầu→Deadline) + phân bổ **4 role chính** (DE/DA/PM/DESIGN) mỗi tháng 1 người → lưu + mở Chi tiết | BR-15 | ✅ |
| FR-T4.3 | Cách 1 — Tự nhập: khung tháng ± , phase, phân bổ, điền nhanh, nhân bản từ dự án, kiểm tra fit | BR-01 | ✅ |
| FR-T4.4 | Ràng buộc nhập (UI): allocation khóa ngoài phase; phase phải liền mạch mới lưu; allocation vượt deadline chỉ cảnh báo | BR-01 | ✅ |
| FR-T4.5 | Tiêu chí AI + đính kèm tài liệu (gập, "Phase sau") | BR-17 | 🔵 Placeholder |
| FR-T4.6 | Cách 2 — AI Generate | BR-17 | 🔵 Backlog (banner "Phase sau") |

### 2.7 t5 — Đóng dự án
| ID | Chức năng | BR | TT |
|---|---|---|---|
| FR-T5.1 | Nhập **thực tế theo role** (prefill = estimate), delta % tự tính; close_note | BR-10 | ✅ |
| FR-T5.2 | Lưu → ghi `allocations kind='actual'` (rải theo hình dạng tháng của estimate) + `status='closed'` + `closed_at` + `close_note` | BR-10 | ✅ |
| FR-T5.3 | Đóng dự án → giải phóng demand/load (renderer lọc `status='active'`); vòng học `v_estimate_vs_actual` + `v_norm_suggestions` cập nhật | BR-10, BR-05 | ✅ |

### 2.8 t6 — Cấu hình
| ID | Chức năng | BR | TT |
|---|---|---|---|
| FR-T6.1 | Danh mục **role** (thêm/xóa) | BR-12 | ✅ |
| FR-T6.2 | **Rate theo level** (gợi ý) | BR-12 | ✅ |
| FR-T6.3 | **Nhân sự** CRUD: tên, role, level, rate_type (monthly/hourly), rate; cột chi phí quy đổi | BR-12 | ✅ |
| FR-T6.4 | **Năng lực khai báo** theo role (3 cột: khai báo / thực có / còn trống theo tháng) | BR-12 | ✅ |
| FR-T6.5 | **Quản lý người dùng** (finance): liệt kê `app_users`, nâng `pm`→`finance` | BR-11 | ✅ |
| FR-T6.6 | Cấu hình AI model | BR-17 | 🔵 Placeholder |

### 2.9 t7 — Nguồn lực cá nhân
| ID | Chức năng | BR | TT |
|---|---|---|---|
| FR-T7.1 | Theo **cá nhân**: timeline %tải × tháng, KPI quá tải, dự án tham gia; **đỏ khi >100%** | BR-09 | ✅ |
| FR-T7.2 | Theo **role**: tất cả người của role × %tải + hàng nhu cầu role | BR-09 | ✅ |
| FR-T7.3 | **Bảng toàn đội** (người × tháng, đỏ khi quá tải) | BR-09 | ✅ |

## 3. Yêu cầu phi chức năng (Non-Functional Requirements)

| ID | Loại | Yêu cầu | TT |
|---|---|---|---|
| NFR-01 | **Bảo mật** | Số tiền chặn ở **tầng DB** (RLS + security-definer view `is_finance()`); anon key nhúng client an toàn nhờ RLS; guard trigger chặn PM ghi cột tiền | ✅ |
| NFR-02 | **Bảo mật** | Không commit secret (service_role/LLM key/PAT/mật khẩu) vào file git-track | ✅ |
| NFR-03 | **Toàn vẹn dữ liệu** | Constraint DB = lưới an toàn: FK role/type, percent 0–100, headcount ≤ 50, month = ngày 01, end ≥ start, UNIQUE | ✅ |
| NFR-04 | **Hiệu năng / chi phí** | Mọi tính toán = SQL view → 0 token vận hành; free tier | ✅ |
| NFR-05 | **Khả dụng** | Web tĩnh, không build pipeline; deploy = copy file | ✅ |
| NFR-06 | **Tương thích** | Vanilla HTML/JS, chạy mọi browser hiện đại; Supabase JS qua CDN | ✅ |
| NFR-07 | **Responsive** | Đọc-trước trên mobile (ghim cột đầu, KPI/card gọn, bảng cuộn ngang) | ◻️ Vòng 1 (cần test phone) |
| NFR-08 | **Chính xác** | Client tính khớp DB view (margin client = `v_project_margin`) | ✅ |
| NFR-09 | **Bền vững khi đổi catalog** | Không hardcode mã role/type trong logic (đã sửa `renderConflicts`, dropdown loại dự án nạp động) | ✅ |
| NFR-10 | **Khả kiểm thử** | Test bằng **harness jsdom chạy code app thật + REST live** (bắt được bug runtime) | ✅ |

## 4. Yêu cầu dữ liệu (Data Requirements)

Bảng chính (chi tiết schema ở `SPEC.md §4`): `projects`, `phases`, `allocations` (kind estimate/actual), `assignments`, `employees`, `ref_roles`, `ref_level_rates`, `ref_project_types`, `app_users`, `app_llm_configs`, `audit_log`.

View tính toán: `v_monthly_demand`, `v_capacity_gap`, `v_conflict`, `v_employee_load`, `v_project_cost`, `v_project_margin`, `v_slack`, `v_estimate_vs_actual`, `v_norm_suggestions`; + view RBAC (`v_projects_public` / `v_projects_finance`, `v_employees_public` / `v_employee_cost`, `v_level_rates`).

## 5. Ma trận phân quyền (RBAC Matrix)

| Đối tượng dữ liệu | pm | finance |
|---|---|---|
| Dự án (tên, loại, thời gian, role, trạng thái) | Đọc/Ghi | Đọc/Ghi |
| Doanh thu / chi phí khác / management% | ❌ (DB ép 0) | Đọc/Ghi |
| Rate cá nhân / rate level / chi phí / margin | ❌ (view `[]`) | Đọc/Ghi |
| Phase / allocation / assignment (lớp effort) | Đọc/Ghi | Đọc/Ghi |
| Nhân sự, role, năng lực | Đọc/Ghi* | Đọc/Ghi |
| `app_users` (gán quyền) | Đọc dòng của mình | Đọc/Ghi tất cả |

*Ghi catalog (role/type) yêu cầu `is_finance()` ở policy — pm đọc, finance ghi.

## 6. Truy vết (Traceability) — tóm tắt

Mọi **FR** ở §2 có cột **BR** trỏ về `BRD.md §5`. Mọi **BRULE** nghiệp vụ trỏ về **D-decision** trong `DECISIONS.md`. User story (`user-stories.md`) trỏ về FR.

> **Tổng kết:** FR P1/P2 = ✅ Done. Còn 🔵: FR-T4.5/4.6, FR-T6.6 (AI — Phase 5), FR-T2.3 (CSV→DB). ◻️: NFR-07 (mobile vòng 2).
