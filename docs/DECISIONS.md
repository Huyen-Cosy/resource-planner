# DECISIONS — Vì sao Resource Planner được thiết kế như vậy

> File này ghi **lý do** đằng sau các quyết định, để session sau (Claude Chat hoặc Claude Code) không vô tình đi lùi. Mỗi mục: quyết định + vì sao + hệ quả.
> Khi chốt quyết định mới ở bất kỳ session nào, **cập nhật file này ngay**.

## D1. Đây là PLANNING tool, không phải execution/tracking tool
**Vì sao:** mục tiêu là lập kế hoạch nguồn lực & tài chính *dự kiến*, không theo dõi tiến độ thật. Tool tracking đòi cập nhật hằng ngày/tuần — không khả thi và không phải nhu cầu.
**Hệ quả:** cấm mọi chỉ số đòi dữ liệu thực tế (% hoàn thành, chi tiêu tới hôm nay, mốc "hôm nay", cờ quá hạn). Mọi thứ tính từ dữ liệu kế hoạch. Đây là ranh giới dễ trôi — đã từng phải kéo lại một lần khi trang CEO lỡ thêm yếu tố execution.

## D2. Granularity: tháng × role (không theo tuần, không theo ngày)
**Vì sao:** PM tư duy kế hoạch ở mức tháng/role; chi tiết theo tuần làm dữ liệu nhập phình gấp 4 và không thêm giá trị cho planning.
**Hệ quả:** schema, view, UI đều theo tháng. Đơn giản hơn nhiều.

## D3. Gán người là OPTIONAL, nằm trên lớp allocation mức role
**Vì sao:** lúc estimate chưa biết ai rảnh; nhiều dự án chỉ cần kế hoạch mức số lượng. Ép gán người sẽ cản trở.
**Hệ quả:** allocation (mức role) luôn có và đủ để chạy bức tranh công ty; assignments (mức cá nhân) là lớp phủ thêm. **Mọi tính năng phải chạy được khi chưa gán ai.** Chi phí dự án: dùng người gán nếu có, fallback rate trung bình role.

## D4. Rate theo CÁ NHÂN, không theo role
**Vì sao:** senior và intern cùng role chênh lương 3-4 lần; rate theo role làm mọi con số tài chính sai.
**Hệ quả:** mỗi employee có level + rate_type (monthly/hourly) + rate. Có level_rate gợi ý khi tạo nhanh. Hourly quy đổi 160h/tháng. Gán senior hay junior vào dự án thay đổi margin ngay — thành công cụ cân nhắc biên lợi nhuận.

## D5. Bỏ "effort đã bán (người-tháng)", chỉ dùng margin tiền làm thước đo lời/lỗ
**Vì sao:** "người-tháng" là đơn vị công sức, không phải tiền; khi rate mỗi người khác nhau, cùng số người-tháng có chi phí khác hẳn → con số nửa vời, gây lăn tăn. Hợp đồng bán kết quả với giá tiền, không bán người-tháng.
**Hệ quả:** thước đo lời/lỗ duy nhất = margin = doanh thu − tổng chi phí (rate cá nhân) − chi phí khác. (Nếu sau này cần che rate khỏi PM thì mới thêm lại "ngân sách người-tháng" — xem BACKLOG.)

## D6. Danh sách role tham gia dự án khai báo TƯỜNG MINH (project.roles)
**Vì sao:** suy ngầm "role nào có alloc>0" thì mong manh và gây bug (thêm role nhưng chưa nhập số → khối gán người không hiện). PM tư duy: chốt role tham gia trước, rồi điền số.
**Hệ quả:** bảng phân bổ và khối gán người đều render theo project.roles. Đồng bộ, không suy ngầm.

## D7. Cột "Đã gán" hiển thị theo FTE (người), không phải tổng %
**Vì sao:** tổng % nhiều người so với "cần N người" là sai đơn vị ("200% / cần 1" khó hiểu). Quy % về người rồi so với nhu cầu (chính là ô allocation) thì cùng đơn vị, đọc là hiểu đủ/thiếu/dư.
**Hệ quả:** "1.0/1 đủ" (xanh), "0.5/1 thiếu" (vàng), "2.0/1 dư" (cam). Quá tải cá nhân là việc của tab Nguồn lực cá nhân, không trộn vào cột này.

## D8. AI chỉ đứng ở cửa estimation; mọi tính toán là SQL
**Vì sao:** tiết kiệm token tối đa — bài toán tổng hợp nguồn lực là toán xác định, không cần LLM ở runtime.
**Hệ quả:** 0 token vận hành. LLM chỉ tốn token lúc PM tạo dự án mới (estimate). Vòng học = cập nhật norms/ví dụ, KHÔNG fine-tune.

## D9. Supabase là nguồn sự thật; Claude Code & web app là 2 client độc lập
**Vì sao:** nhiều PM, nhiều device, nhiều account Claude Code khác nhau. Cần một nơi chung. Supabase là cloud (khác server nội bộ ra ngoài LAN là tắc).
**Hệ quả:** không có kết nối trực tiếp Claude Code ↔ web app. Cả hai cùng đọc/ghi Supabase qua REST. Nhất quán logic giữa các Claude Code bằng: repo skill chung (pull) + ref tables (runtime) + DB constraints (chặn sai).

## D10. Cấu hình AI model động qua bảng (app_llm_configs), không hardcode env
**Vì sao:** model free hay hết quota; PM cần đổi model ngay mà không chờ admin redeploy.
**Hệ quả:** admin setup danh sách model, PM chọn active. API key vẫn ở Edge secret (nhạy cảm), chỉ lựa chọn model là động. model_version lưu vào dự án để vòng học so chất lượng từng model.

## D11. Tech stack tối giản: web tĩnh + Supabase, free tier
**Vì sao:** gọn, dễ build (ít token cho Claude Code), dễ dùng, 0 chi phí. Tránh React/build pipeline.
**Hệ quả:** vanilla HTML+JS + CDN. Mockup hiện tại đã là một file HTML chạy được — Claude Code chuyển nó thành app thật bằng cách nối Supabase, không phải viết lại từ đầu.

## D12. Mockup là đặc tả hành vi (sống qua 14 phiên)
**Vì sao:** mô tả UX bằng lời luôn thiếu sót; mockup định nghĩa chính xác từng tương tác.
**Hệ quả:** khi spec và mockup khác nhau → mockup đúng cho UI/tương tác. Giữ mockup trong repo, Claude Code đối chiếu khi build.

## D13. Claude Code được sửa thiết kế & mockup trực tiếp (bỏ ranh giới Chat/Code)
**Vì sao:** mockup là code sẽ tái dùng khi build (D11) — bug để lại trong mockup chảy thẳng vào app thật. Đợt test 3 vai (CEO/PM/Admin, 06/2026) cho thấy vá tại chỗ trong Claude Code nhanh và kiểm chứng được bằng test harness, không cần vòng qua Claude Chat.
**Hệ quả:** mọi thay đổi thiết kế/mockup làm được ngay tại Claude Code. Ràng buộc duy nhất: cập nhật DECISIONS.md (và SPEC nếu cần) cùng đợt sửa. CLAUDE.md đã bỏ mục "ranh giới với Claude Chat".

## D14. Phán quyết PO sau đợt test mockup v17 (06/2026) — các hành vi chốt không sửa
**Vì sao:** đợt test 29 case tìm ra 8 fail; 6 nhóm blocker đã vá vào mockup (allocation "ma" khi đổi tháng bắt đầu, crash start trước mốc trục, clone tạo số trong ô khóa, CSS --warn thiếu, template literal lộ, dữ liệu `sold` chết). Các mục còn lại được cân nhắc và CHỐT như sau, để session sau không "sửa nhầm":
- **Nhân sự "Nghỉ" vẫn tính tải & chi phí** cho assignment đã gán — đúng bản chất planning (kế hoạch đã cam kết người đó). Phase 3 bổ sung CẢNH BÁO "X đã nghỉ nhưng còn được gán Tx–Ty", không tự xóa assignment.
- **Hai khái niệm "rảnh" cố ý khác nhau:** t0 "dư địa" tính theo allocation (mức role), t6 "còn trống" tính theo gán người (mức cá nhân) — đúng 2 lớp của D3. Khi build chỉ thêm 1 câu chú thích ở t6, không hợp nhất logic.
- **t5 đóng dự án build theo SPEC §5** (ghi allocations kind='actual', status='closed') — mockup chỉ demo phần delta %, không demo đổi status.
- **Vòng đời draft hoãn** → BACKLOG B9. MVP: dự án lưu là active ngay.
- **Thang severity cảnh báo CEO** (trộn triệu VND với người×100) giữ nguyên heuristic, tinh chỉnh sau khi CEO dùng thật.

## D15. Dư địa (slack) ở trang CEO phân biệt năng lực THẬT vs KHAI BÁO
**Vì sao:** đợt dogfood dự án Thanh Yến (06/2026) phát hiện trang CEO quảng cáo "DS còn ~18 người-tháng rảnh — thoải mái nhận thêm việc" trong khi công ty **không có Data Scientist nào** — con số đến từ `declaredCap` fallback. CEO dễ bị dẫn tới quyết định nhận việc dựa trên một "ghế trống ảo".
**Hệ quả:** trong khối *dư địa nhận thêm việc*, role có `realCap=0` (đếm từ employees active) nhưng `declaredCap>0` → KHÔNG hiển thị verdict "thoải mái nhận thêm", mà cảnh báo "năng lực N người là KHAI BÁO — chưa có ai thật, cần tuyển trước khi nhận việc cần role này". `roleCapacity()` vẫn fallback `declaredCap` cho **bức tranh công ty (t1)** theo D3 (tính năng phải chạy khi chưa có người) — chỉ phần **khuyến nghị nhận-việc của CEO** mới đòi người thật. Cùng đợt: bỏ hardcode `min="2026-06"` ở ô tháng what-if, set `min=ANCHOR` động để không lệch khi mốc kế hoạch khác.
**Tinh chỉnh CEO-4 (cùng đợt):** dư địa chỉ cộng "người-tháng rảnh" trong khung **còn dự án** (`planHorizon = min(horizon, tháng kết thúc muộn nhất của dự án active + 1)`). Các tháng sau khi MỌI dự án đã kết thúc là rảnh hiển nhiên (toàn đội 100% trống) → KHÔNG liệt từng role để khỏi thổi phồng con số, mà gộp 1 ghi chú "Từ tháng X trở đi chưa có dự án nào — toàn đội rảnh". Tránh hiểu nhầm "PM còn 4 người-tháng rảnh" khi 2 trong số đó chỉ là tháng trống cuối trục.

**Bổ sung (13/06/2026 — review PO):** thay bộ chọn cố định "3/6/12 tháng" bằng **2 ô Từ→Đến tháng tự chọn** (`slackFrom`/`slackTo`). Lý do PO: "X tháng tới" mâu thuẫn D1 (tool không có mốc "hôm nay") và bị neo cứng vào đầu khung; còn câu hỏi thật của CEO là *"nếu nhận dự án chạy 6→10/2026 thì còn người không"* → cần khoảng tháng tùy ý. Mặc định = toàn khung (đầu khung → tháng kết thúc dự án muộn nhất). Cho phép chọn vượt khung dự án (nhu cầu = 0 ngoài khung, dùng `labAbs` để gắn nhãn an toàn ngoài mảng `months`), kèm ghi chú "phần từ tháng X là sau khi mọi dự án kết thúc → năng lực trống gần như toàn bộ" để không thổi phồng. Ngưỡng "thoải mái/chừng mực" đổi từ `planHorizon` sang độ dài khoảng chọn (`rangeLen`).

**Bổ sung 2 (13/06/2026 — review CEO):** (1) **Không giới hạn năm** ở ô chọn tháng (bỏ `min/max`), chỉ chặn runaway ~100 năm. (2) **Badge số tháng** (`slackLenBadge`) đếm INCLUSIVE — T6→T10 = 5 tháng (tính cả 2 đầu); note ghi rõ "tính cả tháng đầu & cuối". (3) **Trình bày trung bình** thay cộng dồn: số chính = `~X người rảnh/tháng` (= người-tháng ÷ số tháng) vì cộng dồn "12 người-tháng" khó hiểu cho CEO (tưởng 12 người); chi tiết người-tháng để trong ngoặc. (4) **Sắp xếp role**: role đang dùng trong dự án lên trước, role thường chưa dùng ở giữa, `MGMT_ROLES` xuống cuối.

## D16. Chi phí Management theo % (overhead) — thành phần chi phí thứ 3, cấu hình theo từng dự án
**Vì sao:** đợt dogfood Thanh Yến (06/2026) cho thấy nhiều dự án có các vai quản lý (PO, Tech Lead, Data Lead) đóng góp nhưng KHÔNG tính giờ trực tiếp — quy ước doanh nghiệp là cộng một khoản "management cost = X% tổng chi phí dự án". Ép họ thành assignment theo giờ vừa sai bản chất (họ không log giờ) vừa làm phình tab Nguồn lực cá nhân.
**Hệ quả:** thêm field `projects.mgmt_pct` (mặc định 0). `projMgmtCost = (chi phí NS + chi phí khác) × mgmt_pct/100`; `projTotalCost = NS + khác + management`; margin trừ luôn khoản này. UI: một ô cấu hình riêng trong card Tài chính (t3), **per-project**, hiển thị cả % lẫn số tiền quy ra; mặc định 0 ở sản phẩm generic, người dùng đặt mức tùy dự án. Burn theo tháng phân bổ management theo tỷ lệ chi phí NS lũy kế để ô cuối khớp tổng. **KHÔNG vi phạm D5** — margin tiền vẫn là thước đo lời/lỗ duy nhất, đây chỉ là thêm một dòng chi phí, không quay lại "effort đã bán".
**Phạm vi promote (đợt này):** đưa feature (management cost + ô Doanh thu chỉnh được ngay ở t3) từ bản test `mockup-test-thanhyen.html` sang `mockup.html` gốc. **Dữ liệu demo generic giữ nguyên** — toàn bộ data Thanh Yến (ANCHOR 2026-03, đội ideaLAB, role Lark Admin/Finance/Designer, dự án Thanh Yến) **chỉ nằm ở file test**, không nhét vào sản phẩm. Role domain không thêm vào catalog mặc định — vẫn dùng cơ chế role tùy biến ở t6 (đúng tinh thần SPEC §9.5 "thêm Finance Support").

**Bổ sung (13/06/2026 — review PO):** ở bảng **"Dư địa nhận thêm việc"** (t0), các role quản lý (`MGMT_ROLES=['PO','ARCH','DATA_LEAD']`) được **gắn nhãn** "vai trò quản lý — chi phí tính qua management%, không giao việc dự án trực tiếp" thay vì khuyên "thoải mái nhận thêm việc". Lý do: họ là overhead (D16), không phải năng lực giao việc — hiện họ là "dư địa" gây CEO hiểu nhầm còn người làm dự án. Chỉ là **nhãn UI** (constant ở `web/index.html`), không đổi công thức chi phí/margin. Nếu doanh nghiệp khác định nghĩa role quản lý khác → sửa `MGMT_ROLES`.

## D17. Xuất báo cáo CEO (PDF + Word) ngay từ mockup, không thư viện ngoài
**Vì sao:** mục tiêu trước mắt là **dùng mockup làm sản phẩm luôn** (chưa dựng web app). PM nhập/sửa dữ liệu xong cần đưa CEO một bản báo cáo tĩnh để đọc/ký, không thể bắt CEO mở file HTML mockup.
**Hệ quả:** thêm 2 nút ở tab CEO (t0): **Xuất PDF** (mở cửa sổ mới chứa báo cáo sạch → `window.print()` → người dùng "Save as PDF") và **Xuất Word** (Blob `application/msword` từ HTML có namespace Office → tải `.doc`). Hàm `buildCeoReport()` gom dữ liệu kế hoạch hiện tại (KPI tổng, bảng tài chính từng dự án gồm management, ma trận role×tháng nhu cầu/năng lực, cảnh báo lỗ + thiếu người) thành 1 HTML in được. **Không CDN, không thư viện** — chạy offline, đúng D11 (vanilla, không build). Báo cáo ghi rõ "KẾ HOẠCH DỰ KIẾN, không phải số thực" (giữ D1). Khi build web app thật (Phase 2+) tái dùng nguyên `buildCeoReport()`; nếu cần PDF server-side đẹp hơn thì để BACKLOG, bản print-to-PDF đủ dùng cho MVP.

## D18. Mockup dùng như sản phẩm tạm: báo cáo toàn cảnh + import CSV + localStorage (CẦU TẠM trước Supabase)
**Vì sao:** PM muốn dùng mockup làm sản phẩm ngay (chưa dựng web app), nhiều PM nhập nhanh nhiều dự án, dữ liệu sống qua reload, xuất 1 báo cáo đầy đủ cho CEO.
**Quyết định (kèm phản biện PO):**
- **Báo cáo mở rộng 5 phần** (1 CEO · 2 bức tranh công ty · 3 chi tiết TỪNG dự án · 4 nguồn lực cá nhân · 5 cấu hình). Gồm cả **bảng rate cá nhân + AI config** theo yêu cầu user — PO đã cảnh báo rủi ro lộ lương khi phát tán file (BACKLOG B1), user chốt "gồm tất cả". Vẫn giữ nhãn "KẾ HOẠCH DỰ KIẾN" (D1). Đây là phần **product-worthy** → nên promote sang `mockup.html`/web app.
- **Import = CSV, KHÔNG .xlsx.** Đọc .xlsx bắt buộc thư viện (SheetJS) → phá "vanilla, offline" (D11). CSV: Excel Save As được, parse vanilla 0 lib. Template tải sẵn (1 dòng/role, cột T1..T12 tính từ tháng bắt đầu). Validation: YYYY-MM, end≥start, start≥ANCHOR, role hợp lệ → chỉ nhận dự án valid. Import nhiều file một lúc.
- **localStorage** giữ dữ liệu qua reload (hook vào `markEdited` + import/xóa) + nút Reset về mẫu.
- **Loại/xóa dự án:** cờ `inReport` (loại khỏi báo cáo tổng, vẫn ở tool) + nút xóa hẳn. Báo cáo + bức tranh công ty đều tính theo `reportProjects()` = active ∧ inReport.
**⚠ RANH GIỚI CHỐNG ĐI LÙI:** `import CSV` + `localStorage` là **CẦU TẠM chỉ ở bản instance `mockup-idealab.html`** để xài mockup như sản phẩm trước khi có Supabase. **KHÔNG promote 2 thứ này vào `mockup.html`/web app thật** — bài toán multi-PM + nguồn sự thật chung là việc của **Supabase** (D9), không phải localStorage. Web app thật: PM ghi Supabase, báo cáo đọc từ đó. Khi build, chỉ **báo cáo 5 phần** mới mang sang product; phần import/persist build lại bằng Supabase.

## D19. Phân quyền RBAC (PM ẩn tài chính) ĐƯA VÀO MVP, khóa ở tầng RLS — promote B1 lên sớm
**Vì sao:** quyết định của PO (06/2026) sau khi xác nhận tool sẽ có ≥2 người cùng nhìn kết quả và nhiều PM không nên thấy lương nhau. B1 (BACKLOG) vốn hoãn vì giả định "tool nội bộ tin cậy, dùng chung anon key + RLS mở"; giả định đó không còn đúng → kéo B1 vào MVP. Lương là dữ liệu nhạy cảm, "giấu nút ở UI" KHÔNG đủ (anon key nhúng ở web app → người rành kỹ thuật moi data trực tiếp), nên phải khóa ở **tầng database (RLS theo user) + Supabase Auth**, không chỉ ẩn hiển thị.
**Quyết định:**
- **2 nhóm quyền** (CEO & Quản trị viên ngang nhau, gộp thành 1 tier "thấy tiền"):
  - **`finance` (CEO + Admin):** thấy tất cả — rate, chi phí, margin, what-if, dư địa tiền.
  - **`pm`:** chỉ nhập dự án + gán người; thấy lớp *số người / effort*; **KHÔNG thấy** rate, chi phí dự án, margin, KPI Σ margin, ô doanh thu, management cost.
- **Bắt buộc đăng nhập** (Supabase Auth — email/password hoặc magic link). Bỏ mô hình "anon key dùng chung, không login" của MVP cũ.
- **Khóa ở tầng gốc (RLS), không chỉ ẩn UI:** các cột/bảng tiền (rate cá nhân, `level_rate`, chi phí, revenue, margin) chỉ trả về cho role `finance`. View tài chính (`v_project_cost`, margin…) chặn ở RLS/`security definer` theo `auth` role. PM gọi API trực tiếp cũng KHÔNG lấy được số tiền.
- **Lưu role ở đâu:** bảng `app_users` (user_id ↔ role `finance`/`pm`) hoặc custom claim trong JWT; RLS policy đọc role từ đó. Quyết định chi tiết cơ chế khi vào Phase 1.
- **Lớp effort vẫn đầy đủ cho PM:** allocation (role×tháng), gán người, bức tranh số lượng, cảnh báo thiếu/dư người — đều KHÔNG đụng tiền nên PM thấy trọn vẹn (đúng tầng D3/D5: effort tách khỏi money).
**Cách tạo tài khoản & gán quyền (PO chốt 06/2026 — Cách A: self-signup + admin gán quyền):**
- **Người dùng TỰ đăng ký** (Supabase Auth signUp bằng anon key — không cần service_role ở client). Mặc định mọi user mới = **`pm`** → an toàn: chưa thấy tiền cho tới khi admin nâng quyền. Loại trừ rủi ro lộ lương khi chưa kịp phân quyền.
- **Admin chỉ gán/đổi quyền**, KHÔNG tạo account hộ. Lý do từ chối "admin tạo account trong app": tạo user cần service_role — **cấm nhúng vào web app** (lộ mã nguồn). Muốn admin-tạo-account tận tay thì phải dựng Edge Function (service_role server-side) → đó là việc Phase 5, cố ý KHÔNG kéo lên (xem Cách B đã loại).
- **Màn "Quản lý người dùng" (admin-only):** liệt kê user đã đăng ký (đọc từ `app_users`), gạt role `pm`↔`finance`. RLS chỉ cho role `finance`/admin GHI vào `app_users`; PM chỉ đọc được dòng của chính mình. Đặt trong t6 (Cấu hình) hoặc tab riêng — quyết khi build Phase 2.
- Trigger Supabase: khi có user mới ở `auth.users` → tự tạo dòng `app_users` role mặc định `pm` (insert qua trigger `on auth user created`).

**Hệ quả với MVP:** Phase 1 schema thêm `app_users` + trigger default `pm` + bật RLS theo role (không còn "RLS mở"); Phase 2 thêm màn đăng nhập + **màn admin "Quản lý người dùng" (gán quyền)** + ẩn cụm tài chính (t1 KPI margin, t2/t3 tài chính dự án) khi role=`pm`; Phase 4 (t0 CEO) vốn chỉ dành cho `finance`. **KHÔNG vi phạm D4/D5** — rate vẫn theo cá nhân, margin vẫn là thước đo lời/lỗ duy nhất; chỉ thêm lớp *ai được xem*. Mô hình này là chuẩn ngành (Float/Runn/Forecast: planner thấy khối lượng, chỉ sếp/admin thấy tiền). Thay thế ghi chú cũ ở D5 ("nếu sau này cần che rate khỏi PM…") — giờ làm ngay, không cần "ngân sách người-tháng" thay thế vì RLS che thẳng số tiền.
