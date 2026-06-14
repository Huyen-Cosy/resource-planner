# BRD — Business Requirements Document
## Resource Planner (ideaLAB)

> **⚠ BASELINE SNAPSHOT @14/06/2026 — đổi hiếm, chỉ cập nhật khi mục tiêu/scope nghiệp vụ thay đổi** (không sửa theo từng tính năng). Yêu cầu sống = `user-stories.md`; lý do thiết kế = `DECISIONS.md`.
>
> **Mục đích tài liệu:** ghi nhận *vì sao* xây sản phẩm và *cần đạt điều gì* ở mức nghiệp vụ. Bổ trợ cho `SPEC.md` (kỹ thuật) và `DECISIONS.md` (lý do kiến trúc). Cặp đôi với `SRS.md` (chức năng chi tiết) và `user-stories.md`.
>
> **Phiên bản:** 1.0 · **Ngày:** 14/06/2026 · **Tác giả:** Claude Code (vai PO/BA) · **Trạng thái sản phẩm:** MVP + Phase 2.5 (UX hardening) đã go-live.

---

## 1. Bối cảnh & Vấn đề (Problem Statement)

ideaLAB là công ty **dịch vụ data** chạy **nhiều dự án song song** (BI dashboard, data platform, pipeline, AI/ML) trên **cùng một đội nhân sự dùng chung**. Hiện trạng trước sản phẩm:

- Mỗi PM lập kế hoạch nhân sự riêng (Excel/trong đầu) → **không có bức tranh tổng hợp** toàn công ty.
- CEO/BOD **không nhìn ra**: tháng nào thiếu/dư người theo role, dự án nào **lỗ kế hoạch**, công ty **còn dư địa nhận thêm việc** hay không.
- Quyết định **nhận dự án mới / tuyển người** dựa trên cảm tính, dễ nhận quá tải hoặc bỏ lỡ năng lực nhàn rỗi.
- Số liệu tài chính dự án (rate, chi phí, margin) **nhạy cảm** — không phải ai cũng được xem.

## 2. Mục tiêu kinh doanh (Business Objectives)

| ID | Mục tiêu | Thước đo thành công |
|---|---|---|
| **BO1** | Tổng hợp kế hoạch đa dự án thành 1 **bức tranh nguồn lực** toàn công ty (role × tháng) | PM nhập xong → bức tranh tự cập nhật; thấy ngay tháng/role thiếu-đủ-dư |
| **BO2** | Cho lãnh đạo thấy **tài chính kế hoạch** (margin) từng dự án + toàn công ty | Mọi dự án có margin kế hoạch; dự án lỗ được làm nổi |
| **BO3** | Hỗ trợ quyết định **"có nhận thêm việc được không"** + **mô phỏng what-if** | CEO trả lời được "khoảng tháng X còn ~N người/role rảnh" trong < 1 phút |
| **BO4** | **Phân quyền** tài chính: PM nhập kế hoạch nhưng **không thấy tiền**; CEO/BOD/Admin thấy tất cả | PM đăng nhập không truy cập được bất kỳ số tiền nào (kể cả qua API) |
| **BO5** | **Vòng học**: dự án đóng lưu thực tế → ước lượng dự án sau sát hơn | Hệ số lệch est↔actual lưu lại theo loại dự án × role |
| **BO6** | Vận hành **chi phí ~0**, không cần đội kỹ thuật bảo trì nặng | Free tier (Supabase + Vercel); 0 chi phí token vận hành; không build pipeline |

## 3. Phạm vi (Scope)

### 3.1 Trong phạm vi (In-scope — đã làm)
- Quản lý **dự án** (CRUD), **phase/roadmap**, **phân bổ nhu cầu role × tháng** (lớp kế hoạch cơ bản).
- **Gán người cụ thể** (lớp phủ tùy chọn) với % người × role × tháng + **cảnh báo quá tải xuyên dự án**.
- **Bức tranh công ty**: ma trận demand/capacity, cảnh báo xung đột.
- **Tài chính kế hoạch**: rate theo cá nhân, chi phí (người gán / rate TB role), chi phí khác, **management% overhead**, **margin**.
- **Trang CEO/BOD**: KPI tổng quan, bảng margin, cảnh báo, **dư địa nhận việc** (khoảng tháng tự chọn), **what-if**, lọc theo dự án, xuất PDF/Word.
- **Nguồn lực cá nhân**: tải từng người × tháng, theo role, toàn đội.
- **Đóng dự án**: nhập thực tế → vòng học (est vs actual).
- **Cấu hình**: danh mục role, rate theo level, nhân sự + rate, năng lực khai báo, quản lý người dùng.
- **RBAC 2 tầng** (pm / finance) khóa ở **tầng database**.
- **Onboarding cơ bản**: tài khoản (admin tạo), domain chia sẻ.

### 3.2 Ngoài phạm vi hiện tại (Out-of-scope / Backlog)
- **AI Generate** estimation (Edge Function `llm-proxy` + LLM) — t4 "Cách 2" hiện là placeholder "Phase sau". *(Backlog — Phase 5)*
- **Import CSV vào DB** (hiện CSV chỉ ở lớp localStorage cũ). *(Backlog)*
- **Đồng bộ phase ↔ allocation 2 chiều ở tầng dữ liệu** (cố ý hoãn — B2/B3). *(Backlog)*
- **Đính kèm & trích text tài liệu hợp đồng** (Storage). *(Backlog — phục vụ AI)*
- **Tracking thực tế** (% hoàn thành, chi tiêu tới hôm nay, mốc "hôm nay", cờ quá hạn) — **cố ý KHÔNG làm** (luật D1, đây là tool planning).
- **Mobile cho luồng nhập liệu nặng** (t3/t4) — hiện chỉ tối ưu *đọc* trên mobile.

## 4. Stakeholders & Người dùng (Users)

| Nhóm | Vai | Quyền (RBAC) | Quan tâm chính |
|---|---|---|---|
| **PM** | Lập kế hoạch dự án | `pm` — nhập kế hoạch, **ẩn tiền** | Phase, phân bổ role×tháng, gán người, tải đội |
| **CEO** | Ra quyết định | `finance` — thấy tất cả | Margin, dư địa, what-if, dự án lỗ |
| **BOD** | Hội đồng / chủ sở hữu | `finance` — thấy tất cả | Bức tranh tài chính tổng, margin toàn công ty |
| **Quản trị viên (Admin)** | Vận hành hệ thống | `finance` — thấy tất cả + quản lý người dùng | Cấu hình role/rate/nhân sự, gán quyền |

> Hiện hệ chỉ có **2 tầng quyền** (`pm`, `finance`). CEO/BOD/Admin đều là `finance` (ngang quyền). Tách quyền chi tiết hơn (vd BOD read-only) → backlog (đụng schema RLS).

## 5. Business Requirements (BR)

> Ưu tiên: **P1** = bắt buộc MVP · **P2** = quan trọng · **P3** = nên có. Trạng thái: ✅ Done · 🔵 Backlog.

| ID | Yêu cầu nghiệp vụ | Ưu tiên | Trạng thái |
|---|---|---|---|
| **BR-01** | PM nhập được kế hoạch dự án: phase + nhu cầu role × tháng | P1 | ✅ |
| **BR-02** | Hệ thống tổng hợp nhu cầu mọi dự án thành ma trận role × tháng toàn công ty, đối chiếu năng lực | P1 | ✅ |
| **BR-03** | Cảnh báo tháng/role **thiếu người**; làm nổi mức độ thiệt hại | P1 | ✅ |
| **BR-04** | Tính **chi phí & margin kế hoạch** từng dự án theo **rate cá nhân** (+ chi phí khác + management%) | P1 | ✅ |
| **BR-05** | Gán người cụ thể vào role-tháng (tùy chọn); cảnh báo **quá tải** khi 1 người > 100% (gồm cả dự án khác) | P2 | ✅ |
| **BR-06** | Trang lãnh đạo: KPI tổng, bảng margin (lỗ-nhất lên đầu), cảnh báo xếp theo thiệt hại | P1 | ✅ |
| **BR-07** | **Dư địa nhận việc**: theo khoảng tháng tự chọn, trình bày dễ hiểu cho lãnh đạo | P2 | ✅ |
| **BR-08** | **What-if**: mô phỏng nhận 1 dự án giả định → margin dự kiến + có gây thiếu hụt không (không lưu) | P2 | ✅ |
| **BR-09** | Xem **tải từng người** × tháng; đỏ khi quá tải | P2 | ✅ |
| **BR-10** | **Đóng dự án**: nhập thực tế theo role → lưu để **học** cho ước lượng sau | P2 | ✅ |
| **BR-11** | **Phân quyền**: PM không thấy bất kỳ số tiền nào (rate/chi phí/margin/doanh thu); khóa ở **DB** | P1 | ✅ |
| **BR-12** | Quản lý danh mục: role, rate theo level, nhân sự + rate cá nhân, năng lực khai báo | P1 | ✅ |
| **BR-13** | Lãnh đạo **xuất báo cáo** (PDF/Word) để đọc/ký ngoài hệ thống | P3 | ✅ |
| **BR-14** | **Lọc** trang lãnh đạo theo từng dự án (chọn 1/nhiều/tất cả) | P3 | ✅ |
| **BR-15** | Tạo dự án nhanh với **cấu hình mặc định** (1 phase + 4 role chính × 1 người/tháng theo khung) | P3 | ✅ |
| **BR-16** | Dùng được trên **mobile** (ưu tiên màn đọc cho CEO/BOD) | P3 | ◻️ Một phần (đọc-trước; cần test phone) |
| **BR-17** | **AI tự sinh estimation** từ tiêu chí + tài liệu hợp đồng (human duyệt rồi lưu) | P3 | 🔵 Backlog (Phase 5) |
| **BR-18** | **Onboard member**: cấp tài khoản + domain chia sẻ | P2 | ✅ Cơ bản (admin tạo account) |

## 6. Nguyên tắc & Ràng buộc nghiệp vụ (Business Rules / Constraints)

> Chi tiết & lý do ở `DECISIONS.md`. Đây là các **luật không được phá** — vi phạm = đi lùi.

- **BRULE-1 (D1):** Đây là **PLANNING, không phải TRACKING**. Cấm % hoàn thành, chi tiêu thực tới hôm nay, mốc "hôm nay", cờ quá hạn. Mọi số là **kế hoạch dự kiến**.
- **BRULE-2 (D2):** Độ phân giải **tháng × role** (không theo tuần/ngày).
- **BRULE-3 (D3):** **Gán người là OPTIONAL** — mọi tính năng chạy được khi chưa gán ai (allocation mức role là lớp cơ bản).
- **BRULE-4 (D4/D5):** **Rate theo cá nhân** (level + monthly/hourly), không theo role. **Margin tiền là thước đo lời/lỗ duy nhất**.
- **BRULE-5 (D16):** Vai quản lý (PO/Tech Lead/Data Lead) tính chi phí qua **management% overhead**, không log giờ trực tiếp.
- **BRULE-6 (D19):** Số tiền chặn ở **tầng database** (RLS + security-definer view), không chỉ ẩn UI — vì anon key nhúng ở client.
- **BRULE-7 (D8/D9/D11):** **Supabase = nguồn sự thật**; mọi tính toán là **SQL view** (0 token vận hành); web app **vanilla HTML/JS**, không build pipeline.

## 7. Giả định & Phụ thuộc (Assumptions & Dependencies)

- Người dùng có tài khoản (đăng ký Supabase Auth); email-confirm đang bật.
- Đội nhân sự + rate cá nhân được Admin nhập đúng (đầu vào tính chi phí).
- Stack phụ thuộc: **Supabase** (Postgres/REST/Auth/RLS) + **Vercel** (host) — free tier.
- Số liệu là **kế hoạch**, độ chính xác phụ thuộc chất lượng đầu vào của PM.

## 8. Rủi ro (Risks)

| Rủi ro | Ảnh hưởng | Giảm thiểu |
|---|---|---|
| Anon key nhúng ở client → lộ dữ liệu nếu RLS sai | Cao (lộ tiền) | RBAC ở DB (RLS + view); đã test PM thấy `[]` mọi view tiền |
| Free tier giới hạn (Supabase/Vercel) | Trung bình | Tính toán = SQL view (nhẹ); 2 dự án mẫu nhỏ; nâng cấp khi cần |
| PM nhập sai/thiếu → số liệu lệch | Trung bình | Cảnh báo fit/conflict; constraint DB chặn dữ liệu vô lý |
| Mobile chưa tối ưu cho nhập liệu | Thấp | Định vị mobile = đọc-trước; nhập liệu khuyến nghị desktop |
| Phụ thuộc 1 người vận hành (bus factor) | Trung bình | Docs đầy đủ (BRD/SRS/SPEC/DECISIONS); web vanilla dễ tiếp quản |

## 9. Tiêu chí thành công tổng thể (Definition of Success)

Sản phẩm thành công khi: **một PM nhập 1 dự án trong vài phút**, **CEO mở trang tổng quan thấy ngay margin + tháng thiếu/dư người + dư địa nhận việc**, và **PM không truy cập được bất kỳ số tiền nào** — tất cả trên hạ tầng **chi phí ~0**.

> **Trạng thái 14/06/2026:** Toàn bộ BR P1/P2 (trừ BR-17 AI) đã **Done + go-live + verified** (harness jsdom + REST live). Còn lại: mobile vòng 2, onboard hoàn chỉnh, Phase 5 AI.
