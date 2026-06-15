# User Stories — Resource Planner (ideaLAB)

> **🟢 DOC YÊU CẦU SỐNG (LIVING)** — nguồn sự thật yêu cầu duy nhất được cập nhật theo từng commit. Diễn đạt theo góc **người dùng** (As a… I want… so that…) + **tiêu chí chấp nhận** (Given/When/Then) = Definition of Done để test. **NFR ở Phụ lục A**; dữ liệu/RBAC trỏ `DATABASE.md` (Phụ lục B). `SRS.md`/`BRD.md` là baseline snapshot, regenerate từ doc này + code khi cần. Trạng thái: ✅ Done · 🔵 Backlog · ◻️ Một phần.
>
> **Phiên bản:** 1.0 · **Ngày:** 14/06/2026 · **Vai:** PO/BA.

Personas: **PM** (lập kế hoạch), **CEO/BOD** (`finance` — quyết định), **Admin** (`finance` — vận hành).

---

## EPIC 1 — Lập kế hoạch dự án (PM)

### US-1.1 — Tạo dự án nhanh ✅ `FR-T4.1, FR-T4.2`
**As a** PM, **I want** điền thông tin cơ bản rồi bấm "Lưu nhanh", **so that** có ngay 1 dự án với khung mặc định để tinh chỉnh sau.
- **Given** tôi nhập Tên, Loại, Tháng bắt đầu, Deadline ở Bước 1
- **When** tôi bấm **💾 Lưu nhanh với mặc định**
- **Then** hệ thống tạo dự án với **1 phase** phủ khung (Tháng bắt đầu→Deadline) + phân bổ **DE, DA, PM, DESIGN** mỗi tháng 1 người, rồi **mở thẳng Chi tiết** (không popup).

### US-1.2 — Tạo dự án chi tiết (nhập tay) ✅ `FR-T4.3, FR-T4.4`
**As a** PM, **I want** tự nhập phase + phân bổ role×tháng, **so that** kế hoạch khớp thực tế dự án.
- **Given** đang ở t4 Cách 1
- **When** tôi đặt khung tháng, thêm phase liền mạch, điền số người vào ô trong phase
- **Then** chỉ lưu được khi phase liền mạch; ô ngoài phase bị khóa; allocation vượt deadline chỉ cảnh báo.

### US-1.3 — Sửa roadmap/phase (gồm đổi thứ tự) ✅ `FR-T3.2`
**As a** PM, **I want** thêm/đổi tên/xóa/đổi thứ tự phase và chỉnh tháng, **so that** roadmap phản ánh đúng giai đoạn.
- **Given** đang ở Chi tiết dự án
- **When** tôi sửa tên phase / đổi tháng / bấm + Thêm phase / ✕ xóa / **▲▼ đổi thứ tự**
- **Then** Gantt vẽ lại ngay; phase mới nối tiếp liền mạch; bấm Lưu là ghi xuống DB.
- **And** (chèn phase vào giữa) bấm "+ Thêm phase" (xuất hiện ở cuối) → ▲ đưa lên vị trí mong muốn → sửa tháng. Thứ tự mảng `p.phases` → `sort_order` khi lưu; load lại đúng thứ tự. KHÔNG đổi schema.

### US-1.4 — Phân bổ nhu cầu role×tháng ✅ `FR-T3.3`
**As a** PM, **I want** nhập/điền nhanh số người mỗi role mỗi tháng, **so that** thể hiện nhu cầu nhân sự.
- **When** tôi sửa ô inline hoặc điền nhanh theo khoảng tháng
- **Then** bức tranh công ty (t1) cập nhật ngay theo số mới.

### US-1.5 — Lưu toàn bộ chi tiết ✅ `FR-T3.8`
**As a** PM, **I want** 1 nút Lưu lưu hết, **so that** không sợ mất thay đổi ở roadmap/phân bổ/gán người/tài chính.
- **Given** có thay đổi chưa lưu (cờ "● chưa lưu" hiện ở các card)
- **When** tôi bấm **💾 Lưu thay đổi dự án** (ở bất kỳ card nào)
- **Then** roadmap + phân bổ + gán người + (tài chính nếu finance) đều ghi xuống Supabase.

---

## EPIC 2 — Gán người & tránh quá tải (PM)

### US-2.1 — Gán người vào role-tháng ✅ `FR-T3.4`
**As a** PM, **I want** gán người cụ thể với % vào role-tháng, **so that** biết ai làm gì khi nào.
- **When** tôi bulk-assign (người × khoảng tháng × %) hoặc sửa % từng ô
- **Then** cột "Đã gán / Cần" hiển thị FTE 3 màu (thiếu/đủ/dư).
- **And** (D3) mọi tính năng vẫn chạy nếu tôi **không** gán ai.

### US-2.2 — Cảnh báo quá tải xuyên dự án ✅ `FR-T3.5, FR-T7.1`
**As a** PM, **I want** được cảnh báo khi 1 người vượt 100% (gồm cả dự án khác), **so that** không xếp lịch bất khả thi.
- **Given** tôi gán 1 người tổng > 100% trong 1 tháng
- **When** màn hình refresh
- **Then** banner liệt kê lượt quá tải + chip đỏ ⚠ tại ô gán; ở t7 ô tải hiện **đỏ**.

### US-2.3 — Gán người NGOÀI kế hoạch + đồng bộ thủ công ✅ `D21`
**As a** PM, **I want** gán người ở tháng mà role **chưa khai allocation**, **so that** ghi nhận effort cá nhân phát sinh ngoài roadmap/phân bổ.
- **Given** role chưa có số ở Phân bổ nguồn lực cho tháng X
- **When** tôi bulk-assign người vào tháng X
- **Then** ô hiện nhãn **"ngoài KH"** (tím) + banner "⚠ N lượt gán ngoài kế hoạch"; chi phí người đó **vẫn vào margin**, nhưng bức tranh công ty chỉ đếm theo Phân bổ.
- **And** nút **"⤓ Đồng bộ phân bổ theo người đã gán"** bơm `alloc=max(hiện tại, Σngười)` — ghi đè kế hoạch là **thủ công, có chủ đích** (không tự động; KHÔNG phải B2/B3).
- **Not:** KHÔNG thêm "cột thực tế" *trong allocation* (đụng `kind='actual'` của t5). *(Cập nhật 15/06 — D22: burn-actual giờ thực được phép, nhưng ở **lớp riêng tầng người**, không phải cột trong allocation; effort-thực ≠ progress-thực.)*

### US-1.6 — Khung thời gian linh hoạt (quá khứ + tương lai) ✅ `D20`
**As a** PM, **I want** chọn tháng bắt đầu/kết thúc **tùy ý** trong quá khứ (≥2020-01) và tương lai (≤2035-12), **so that** nhập được dự án đã chạy từ trước và lập kế hoạch xa.
- **Given** dự án bắt đầu trước mốc mặc định 2026-03
- **When** tôi đặt tháng bắt đầu sớm hơn
- **Then** trục tháng tự lùi (ANCHOR động + reindex), KHÔNG còn chặn "không thể trước mốc kế hoạch".
- **And** dữ liệu đã lưu không đổi (DB lưu ngày tuyệt đối).

---

## EPIC 3 — Bức tranh & quyết định (CEO/BOD)

### US-3.1 — Xem bức tranh nguồn lực ✅ `FR-T1.1, FR-T1.3`
**As a** CEO, **I want** ma trận role×tháng demand/capacity + cảnh báo thiếu, **so that** biết tháng/role nào thiếu người.

### US-3.2 — Xem margin & dự án lỗ ✅ `FR-T0.1, FR-T0.2`
**As a** CEO, **I want** KPI margin tổng + bảng margin từng dự án (lỗ-nhất lên đầu), **so that** biết ngay dự án nào đang lỗ kế hoạch.

### US-3.3 — Đo dư địa nhận việc ✅ `FR-T0.4`
**As a** CEO, **I want** chọn khoảng tháng và xem **trung bình bao nhiêu người/role rảnh/tháng**, **so that** quyết định có nhận thêm việc trong khoảng đó không.
- **Given** tôi định nhận 1 dự án chạy 6→10/2026
- **When** tôi đặt Từ 2026-06, Đến 2026-10
- **Then** mỗi role hiện "trung bình ~X người rảnh/tháng (≈ Y người-tháng / 5 tháng)"; role quản lý gắn nhãn riêng.

### US-3.4 — Mô phỏng what-if ✅ `FR-T0.5`
**As a** CEO, **I want** thử "nếu nhận thêm 1 dự án giả định", **so that** thấy margin dự kiến + có gây thiếu hụt không, mà không lưu gì.
- **When** tôi nhập tháng/số tháng/doanh thu + nhu cầu role (4 role chính sẵn 1)
- **Then** hiện margin dự kiến (fin-only) + "kham được" hoặc danh sách thiếu hụt mới.

### US-3.5 — Lọc theo dự án ✅ `FR-T0.6`
**As a** CEO, **I want** lọc trang tổng quan theo 1/nhiều dự án, **so that** phân tích đúng tập dự án quan tâm.
- **Then** KPI, bảng margin, cảnh báo, dư địa, what-if đều tính lại theo dự án đang chọn.

### US-3.6 — Hiểu cách tính ✅ `FR-T0.7`
**As a** CEO, **I want** giải thích công thức ngay trên trang, **so that** tin được con số.
- **Then** panel "Cách tính các con số" + tooltip ⓘ ở mỗi cột/khái niệm (người-tháng, nhu cầu, năng lực, dư địa, chi phí, margin).

### US-3.7 — Xuất báo cáo ✅ `FR-T0.8`
**As a** CEO/BOD, **I want** xuất PDF/Word, **so that** đọc/ký ngoài hệ thống.

---

## EPIC 4 — Tài chính kế hoạch (CEO/Admin)

### US-4.1 — Cấu hình rate cá nhân ✅ `FR-T6.3`
**As an** Admin, **I want** nhập rate từng nhân sự (level + monthly/hourly), **so that** chi phí tính đúng người đúng giá.

### US-4.2 — Xem cấu thành chi phí ✅ `FR-T3.7`
**As a** CEO, **I want** bảng liệt kê rate từng người đã gán + phần chưa gán, **so that** hiểu margin từ đâu ra.
- **Then** Σ chi phí NS (khớp DB) → + khác → + management% → tổng → margin; cột "Người-tháng" có diễn giải.

### US-4.3 — Management cost như overhead ✅ `FR-T3.6` (BRULE-5)
**As a** CEO, **I want** cộng chi phí PO/Tech Lead/Data Lead dưới dạng % overhead, **so that** không phải log giờ cho vai quản lý.

---

## EPIC 5 — Vòng học (đóng dự án)

### US-5.1 — Đóng dự án & nhập thực tế ✅ `FR-T5.1, FR-T5.2`
**As a** PM/Admin, **I want** nhập số thực tế khi đóng dự án, **so that** lưu bài học cho ước lượng sau.
- **When** tôi sửa ô lệch (prefill = estimate) + ghi close_note → Đóng
- **Then** ghi `allocations kind='actual'` + `status='closed'`; demand/load được giải phóng; `v_estimate_vs_actual`/`v_norm_suggestions` cập nhật.

### US-5.2 — Khai báo effort thực & đo burn 🔵 `D22, D23, D24` *(CHỐT THIẾT KẾ, CHƯA BUILD — 15/06/2026)*
**As a** PM/Finance, **I want** khai báo **giờ effort thật** từng người theo tháng ngay ở t3 (Chi tiết dự án), **so that** đo được **hiệu quả burn** chi phí (thực vs kế hoạch) mà không biến tool thành tracking tiến độ.
- **Given** dự án đang chạy, người đã gán (lớp kế hoạch `percent`)
- **When** tôi nhập giờ thực/người/tháng (lớp burn-actual riêng, nullable)
- **Then** cost_actual tính song song cost_plan (KHÔNG ghi đè); burn = cost_actual ÷ cost_plan; người **lương cố định** có cost trần = lương thật (D23), người hourly = giờ×rate; rate lấy theo **tháng hiệu lực** (D24, freeze lúc log).
- **And** load (Σgiờ÷160) vẫn báo quá tải >100% mà KHÔNG bịa chi phí; vênh idle/overload của người fixed hiện ở **mức công ty**.
- **And t5 đổi vai:** từ "trang nhập số" → **nghi thức đóng** (xem lại actual đã nhập ở t3 + bài học + snapshot role `kind='actual'` + flip `closed`). KHÔNG bỏ t5.
- **Not:** KHÔNG % hoàn thành / mốc "hôm nay" / cờ quá hạn / đồng hồ chi-tiêu-realtime (giữ D1).

---

## EPIC 6 — Phân quyền & Vận hành (Admin)

### US-6.1 — PM không thấy tiền ✅ `FR-AUTH.3` (BRULE-6)
**As an** Admin, **I want** PM bị chặn xem mọi số tiền **ở tầng DB**, **so that** an toàn dù anon key nhúng ở client.
- **Given** đăng nhập role `pm`
- **Then** mọi view tiền trả `[]`; gửi revenue lên bị guard ép 0; PM không tự nâng quyền được.

### US-6.2 — Nâng quyền người dùng ✅ `FR-T6.5`
**As an** Admin (finance), **I want** nâng `pm`→`finance`, **so that** mở khóa tài chính cho người cần.

### US-6.3 — Onboard member ✅◻️ `BR-18`
**As an** Admin, **I want** cấp tài khoản + link chia sẻ, **so that** member khác dùng được.
- **Done:** tạo sẵn account (admin-create pre-confirmed) + domain `idealab-planner.vercel.app`.
- **Pending:** member tự đăng ký cần xác nhận email (cân nhắc bật auto-confirm).

### US-6.4 — Hướng dẫn sử dụng ngay trên trang ✅
**As a** member mới (PM hoặc CEO), **I want** một trang hướng dẫn ngay trong app, **so that** dùng được mà không cần training/đọc tài liệu riêng.
- **Given** tôi đăng nhập
- **When** bấm tab **❓ Hướng dẫn** ở thanh điều hướng
- **Then** thấy: (1) tool để làm gì + nguyên tắc PLANNING-không-TRACKING; (2) quickstart 4 bước; (3) 8 màn hình dùng để làm gì; (4) thuật ngữ chủ chốt (gập); (5) ghi chú quyền-theo-role.
- **And** với role `pm`, mọi mục liên quan tiền (rate/chi phí/margin/doanh thu) **tự ẩn** qua `.fin-only` — hướng dẫn khớp đúng thứ họ thấy.
- **Note:** trang tĩnh, không thêm JS — dùng lại handler `go()` sẵn có.

---

## EPIC 7 — Trải nghiệm đa thiết bị

### US-7.1 — Đọc trên mobile ◻️ `NFR-07`
**As a** CEO/BOD, **I want** liếc KPI/margin/dư địa trên điện thoại, **so that** xem nhanh khi di chuyển.
- **Done vòng 1:** ghim cột đầu khi cuộn ngang, KPI/card gọn, bảng cuộn trong card.
- **Pending vòng 2:** cần test phone thật + vá CSS theo ảnh.

---

## EPIC 8 — AI Estimation 🔵 BACKLOG (Phase 5)

### US-8.1 — AI gợi ý phân bổ 🔵 `FR-T4.5, FR-T4.6` (BR-17)
**As a** PM, **I want** AI sinh phân bổ từ tiêu chí + tài liệu hợp đồng, **so that** đỡ nhập tay — **nhưng tôi duyệt trước khi lưu** (human-in-the-loop, AI không tự ghi DB).
- **Quyết định (review PO):** chọn cơ chế **AI gợi ý → người duyệt** (không PAT, không bot tự ghi). Triển khai: Edge Function `llm-proxy` + nút AI Generate (hiện placeholder "Phase sau").

---

## Bảng tổng trạng thái

| Epic | Stories | Trạng thái |
|---|---|---|
| 1 — Lập kế hoạch | US-1.1…1.6 | ✅ Done |
| 2 — Gán người & quá tải | US-2.1…2.3 | ✅ Done |
| 3 — Bức tranh & quyết định | US-3.1…3.7 | ✅ Done |
| 4 — Tài chính kế hoạch | US-4.1…4.3 | ✅ Done |
| 5 — Vòng học | US-5.1 | ✅ Done |
| 6 — Phân quyền & vận hành | US-6.1…6.4 | ✅ / ◻️ onboard |
| 7 — Mobile | US-7.1 | ◻️ Vòng 1 (cần vòng 2) |
| 8 — AI | US-8.1 | 🔵 Backlog (Phase 5) |

---

## Phụ lục A — Yêu cầu phi chức năng (NFR)

> Gộp về đây từ `SRS.md` để **một doc yêu cầu sống duy nhất**. Khi đụng các điểm này lúc build, cập nhật ngay tại đây.

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
| NFR-09 | **Bền vững khi đổi catalog** | Không hardcode mã role/type trong logic: `renderConflicts` lọc động, dropdown loại dự án nạp động, **`MGMT_ROLES`/`PRIMARY_ROLES` nạp từ `ref_roles.is_management`/`is_primary`** (không còn mảng cứng) | ✅ |
| NFR-10 | **Khả kiểm thử** | Harness jsdom chạy code app thật, **đã commit `test/smoke.mjs` + `npm test`** và **CI GitHub Action** chạy mỗi push/PR (bắt lỗi runtime như `const`→`let`); regression REST-live vẫn dùng on-demand | ✅ |

## Phụ lục B — Dữ liệu & Phân quyền (con trỏ)

- **Yêu cầu dữ liệu** (bảng + view tính toán): nguồn sống ở `DATABASE.md`; đặc tả schema gốc ở `SPEC.md §4`.
- **Ma trận RBAC** (`pm` / `finance` × hành động): nguồn sống ở `DATABASE.md` (RLS + view RBAC). Đừng nhân bản bảng RBAC ở đây.
