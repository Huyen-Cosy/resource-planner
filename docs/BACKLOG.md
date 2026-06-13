# BACKLOG — Việc CỐ Ý hoãn (không phải thiếu sót)

> Những mục dưới đây đã được cân nhắc và **chủ động hoãn** để giữ MVP gọn. Claude Code KHÔNG tự làm sớm các mục này khi build MVP — chúng làm phình phạm vi. Khi nào làm sẽ quyết riêng.

## B1. Phân quyền theo vai trò (RBAC) — ✅ ĐÃ PROMOTE VÀO MVP (06/2026, xem DECISIONS D19)
**Là gì:** CEO/admin thấy rate + tiền; PM thường chỉ thấy người + effort, ẩn rate/margin.
**Trạng thái:** KHÔNG còn hoãn. PO chốt (06/2026) kéo vào MVP vì tool có ≥2 người cùng xem và nhiều PM không nên thấy lương nhau. Làm ở mức **khóa tầng gốc (Supabase Auth + RLS theo user)**, không chỉ ẩn UI. Chi tiết quyết định: DECISIONS **D19**. Phase 1 thêm `app_users` + RLS theo role; Phase 2 thêm login + ẩn cụm tài chính khi role=`pm`.
**Lưu ý:** rate là dữ liệu nhạy cảm — phải chặn ở RLS, vì anon key nhúng web app khiến "giấu nút UI" không đủ an toàn.

## B2. Đồng bộ allocation theo phase
**Là gì:** khi dịch một phase (vd "modelling lùi 1 tháng"), allocation các role thuộc phase đó tự trượt theo.
**Vì sao hoãn:** logic mapping phase↔allocation hai chiều phức tạp. Hiện sửa phase và sửa allocation độc lập.
**Khi làm:** sau khi MVP ổn, nếu PM thấy thao tác dịch phase thủ công tốn công.

## B3. Gán effort theo phase rồi rải xuống tháng
**Là gì:** PM gõ "phase Build: DE×2" → hệ thống tự điền mọi tháng của phase. (Chiều bulk-input thứ 3.)
**Vì sao hoãn:** cần liên kết phase↔allocation (như B2). Hiện đã có 2 chiều bulk: điền theo khoảng tháng + nhân bản từ dự án.
**Khi làm:** cùng đợt với B2.

## B4. Import nhân sự từ hệ thống HR
**Là gì:** đồng bộ danh sách employees + rate từ HR thay vì nhập tay.
**Vì sao hoãn:** MVP nhập tay đủ cho quy mô vài chục người. Import cần tích hợp riêng từng HR system.
**Khi làm:** khi công ty đủ lớn / có HR system API.

## B5. What-if nâng cao
**Là gì:** hiện what-if mô phỏng 1 dự án giả định (margin + thiếu hụt). Nâng cao: lưu nhiều kịch bản, so sánh, mô phỏng "nếu dự án X trượt sang Q1".
**Vì sao hoãn:** bản cơ bản đã trả lời câu hỏi chính ("có nên nhận thêm việc"). Nâng cao là tối ưu.

## B6. Realtime subscription
**Là gì:** web app tự cập nhật khi PM khác ghi (Supabase realtime).
**Vì sao hoãn:** refresh thủ công đủ dùng; dữ liệu đổi vài lần/tháng. Realtime thêm phức tạp.

## B7. Test phủ rộng
**Vì sao hoãn ở MVP:** chỉ cần 1 script seed + kiểm tra query capacity/margin ra số đúng. Test đầy đủ sau khi cấu trúc ổn định.

## B8. Tự động đồng bộ playbook giữa repo skill và Edge Function
**Là gì:** hiện playbook nằm 2 nơi (repo skill cho Claude Code, hằng số trong Edge Function cho nút web), phải sửa cả 2 tay.
**Vì sao hoãn:** MVP chưa có cả 2 cửa cùng lúc. Khi có, cân nhắc để Edge Function fetch playbook từ DB/repo.

## B9. Vòng đời dự án draft (soạn nháp → kích hoạt)
**Là gì:** tạo dự án ở trạng thái `draft` (kế hoạch chưa cam kết, không ăn capacity), mở/sửa được từ t2, nút kích hoạt → `active`. Hiện schema + bộ lọc CEO đã có khái niệm draft nhưng không có UI nào tạo/mở/kích hoạt draft.
**Vì sao hoãn:** MVP lưu dự án là active ngay — đủ cho luồng chính. Thêm vòng đời draft kéo theo quyết định draft có/không tính vào fit-check, what-if, dư địa. (Phán quyết PO 06/2026, xem DECISIONS D14.)
**Khi làm:** khi PM cần soạn kế hoạch chào giá/chưa ký mà không làm nhiễu bức tranh công ty.

## B10. What-if ước lượng chi phí tuyển khi role thiếu người
**Là gì:** hiện what-if tính chi phí dự án giả định bằng rate trung bình role (`avgRoleCost`). Khi role bị thiếu (phải tuyển/thuê ngoài), chi phí tuyển/thuê thật KHÔNG nằm trong margin → margin lạc quan hơn thực tế. Cảnh báo "tạo thiếu hụt" hiện đã bù lại về mặt định tính (nhắc CEO sẽ phải tuyển/lùi lịch/từ chối).
**Vì sao hoãn:** bản what-if cơ bản đã trả lời câu hỏi chính ("có nên nhận thêm việc"). Ước lượng chi phí tuyển cần thêm giả định (rate thuê ngoài, lead time tuyển) — là tinh chỉnh, không phải lõi.
**Khi làm:** cùng đợt B5 (what-if nâng cao). (Phát hiện CEO-5, dogfood Thanh Yến 06/2026.)

---
## Tính năng đã CÓ trong mockup nhưng thuộc Phase sau MVP (nhắc để không build nhầm thứ tự)
- Nút AI Generate + Edge Function llm-proxy + cấu hình AI model động → Phase 5.
- Repo skill `/estimate` `/close` + vòng học norms → Phase 5.
- Đính kèm tài liệu (Storage + trích text) → Phase 5.
(MVP dùng nhập tay hoàn toàn — đường AI là lớp thêm sau, đúng tinh thần "AI là trang trí, không phải lõi".)
