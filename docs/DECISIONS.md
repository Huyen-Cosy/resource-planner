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
