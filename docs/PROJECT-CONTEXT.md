# PROJECT CONTEXT — Resource Planner (dán vào knowledge của Project)

> Đọc file này đầu mỗi session mới để bắt nhịp ngay. Chi tiết xem SPEC / DECISIONS / BACKLOG / mockup.

## Đang làm gì
Xây **Resource Planner** — planning tool quản lý nguồn lực đa dự án cho công ty làm dịch vụ data. Nhiều PM nhập kế hoạch dự án (phase, nhu cầu nhân sự theo role×tháng), tool tổng hợp thành bức tranh nguồn lực toàn công ty + tài chính kế hoạch, và hỗ trợ CEO quyết định (dư địa nhận việc, what-if).

## Trạng thái hiện tại
- **Đã xong:** mockup HTML qua 14 phiên (đặc tả hành vi đầy đủ, 8 tab), spec hoàn chỉnh, DECISIONS.md, BACKLOG.md.
- **Bước tiếp theo:** đưa 4 tài liệu (spec, decisions, backlog, mockup) + vào repo → mở Claude Code → build theo kế hoạch phase trong spec (MVP: Phase 1-4).
- **Chưa bắt đầu code thật.**

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
