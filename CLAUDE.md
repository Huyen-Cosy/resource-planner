# CLAUDE.md — Hướng dẫn cho Claude Code trên repo `resource-planner`

> Đọc file này ĐẦU TIÊN mỗi phiên. Nó là bản đồ repo + luật chơi. Chi tiết sản phẩm nằm trong `docs/`.

## TL;DR — đọc theo thứ tự này
1. `docs/PROJECT-CONTEXT.md` — bắt nhịp 30 giây: đang làm gì, trạng thái.
2. `docs/DECISIONS.md` — **lý do** 12 quyết định kiến trúc. Đây là lớp chống đi-lùi. Không được vi phạm.
3. `docs/SPEC.md` — đặc tả đầy đủ: schema, view, 8 tab, kế hoạch phase, tiêu chí nghiệm thu. **Đây là nguồn chính khi build.**
4. `docs/BACKLOG.md` — việc CỐ Ý hoãn. **Không tự làm sớm** các mục này.
5. `docs/mockup.html` — đặc tả hành vi sống (bản v17). Mở bằng browser để xem tương tác thật.

## Bản đồ tài liệu — đọc đúng doc theo loại việc (Lớp 1: TẬN DỤNG)
| Khi cần | Đọc |
|---|---|
| Bắt nhịp trạng thái (đầu mỗi session) | `docs/PROJECT-CONTEXT.md` |
| Vì sao thiết kế thế (chống đi-lùi) | `docs/DECISIONS.md` |
| Yêu cầu nghiệp vụ / phạm vi / stakeholder | `docs/BRD.md` 📸 *baseline* |
| Chức năng chi tiết (FR/NFR) formal | `docs/SRS.md` 📸 *baseline — NFR đã chuyển sang user-stories* |
| **Yêu cầu sống** (epic/story/acceptance + NFR) | `docs/user-stories.md` 🟢 *LIVING* |
| Schema / view / RLS / công thức cost–margin | `docs/DATABASE.md` |
| Đặc tả gốc 8 tab + tiêu chí nghiệm thu | `docs/SPEC.md` |
| Việc CỐ Ý hoãn (đừng làm sớm) | `docs/BACKLOG.md` |
| Hành vi tương tác sống | `docs/mockup.html` (v17) |
| **Nhập effort thật / phân bổ** (Lark→%, 2 tầng, resync) | `docs/effort-data-entry.md` 🟢 *LIVING* |

## Sản phẩm là gì (1 câu)
Planning tool quản lý nguồn lực đa dự án cho công ty dịch vụ data: nhiều PM nhập kế hoạch (phase + nhu cầu role×tháng), tool tổng hợp thành bức tranh nguồn lực toàn công ty + tài chính kế hoạch, hỗ trợ CEO quyết định.

## 5 luật không được phá (vi phạm = đi lùi, xem DECISIONS.md)
1. **PLANNING, không phải TRACKING.** Cấm % hoàn thành, chi tiêu thực tới hôm nay, mốc "hôm nay", cờ quá hạn. Mọi thứ là kế hoạch dự kiến. (D1)
2. **Granularity tháng × role.** Không theo tuần/ngày. (D2)
3. **Gán người là OPTIONAL.** Mọi tính năng PHẢI chạy được khi chưa gán ai. Allocation mức role là lớp cơ bản; assignments mức cá nhân là lớp phủ thêm. (D3)
4. **Rate theo CÁ NHÂN** (level + monthly/hourly), không theo role. **Margin tiền là thước đo lời/lỗ duy nhất** — đã bỏ "effort đã bán". (D4, D5)
5. **Supabase = nguồn sự thật.** Mọi tính toán là SQL view (0 token vận hành). AI chỉ ở cửa estimation. Web app vanilla HTML/JS, không React/build pipeline. (D8, D9, D11)

## Cấu trúc repo
```
resource-planner/
├── CLAUDE.md              ← bạn đang đọc
├── README.md             ← tóm tắt + checklist setup cho người mới
├── .gitignore            ← chặn .env*/*.local/.vercel (token dev lưu .env gitignored OK, KHÔNG commit vào file track)
├── docs/                 ← tài liệu thiết kế (được sửa — khi đổi hướng nhớ cập nhật DECISIONS.md cùng đợt)
│   ├── PROJECT-CONTEXT.md
│   ├── DECISIONS.md
│   ├── SPEC.md
│   ├── BACKLOG.md
│   └── mockup.html       ← bản v17, đặc tả hành vi
├── db/                   ← Phase 1: schema.sql, seed.sql, views.sql
├── web/                  ← Phase 2+: index.html (app thật, nối Supabase)
└── supabase/functions/   ← Phase 5: Edge Function llm-proxy (SAU MVP)
```
Thư mục `db/`, `web/`, `supabase/functions/` hiện rỗng (chỉ có `.gitkeep`) — bạn dựng nội dung theo phase.

## Kế hoạch build (tuần tự — chi tiết & tiêu chí nghiệm thu ở SPEC.md §8, §9)
**MVP:**
- **Phase 1** — `db/`: schema.sql + seed.sql + views + constraints. In hướng dẫn tạo Supabase project + chạy SQL.
- **Phase 2** — `web/`: tab t1/t2/t3/t4(Cách 1 nhập tay)/t6. CRUD, bức tranh công ty, tài chính cơ bản, quản lý role/nhân sự/rate. Test bằng seed. Hướng dẫn deploy (Cloudflare Pages/Vercel).
- **Phase 3** — gán người: t3 phần assign + t7 Nguồn lực cá nhân.
- **Phase 4** — CEO: t0 (dư địa + what-if) + t5 (đóng dự án).

**SAU MVP (Phase 5+ — KHÔNG làm khi build MVP):** Edge Function llm-proxy + nút AI Generate + cấu hình AI model động; repo skill `/estimate` `/close` + vòng học norms; đính kèm tài liệu (Storage + trích text). Đường AI là lớp trang trí thêm sau, MVP nhập tay hoàn toàn.

## ⚠ Design delta cần hòa giải khi vào Phase 1 & 2 (mockup v17 mới hơn SPEC)
Mockup v17 (bản gần nhất) đã thêm 3 ràng buộc ở luồng **t4 — Tạo dự án mới → Cách 1 (nhập tay)** mà SPEC.md (viết theo mockup v14) chưa phản ánh:
1. **Khung tháng kế hoạch tách khỏi deadline.** Có control "± tháng" nới/thu khung tự do; `pDeadline` chỉ là vạch mốc tham chiếu (cột viền vàng), không còn là biên khóa cứng.
2. **Allocation bị khóa ngoài phase.** Chỉ nhập được số ở tháng nằm trong một phase; ô ngoài phase bị disable (gạch chéo).
3. **Phase phải liền mạch** (không gap) mới cho lưu; overlap thì được phép. Allocation vượt deadline chỉ cảnh báo, vẫn lưu.

**Lưu ý quan trọng về schema:** ràng buộc (2)+(3) là **logic tầng UI lúc nhập liệu**, KHÔNG phải ràng buộc cứng ở DB. Schema SPEC (`phases` và `allocations` là 2 bảng độc lập, không FK ràng phase↔allocation) vẫn giữ nguyên — đừng thêm constraint DB ép allocation phải nằm trong phase. Lý do: BACKLOG B2/B3 cố ý hoãn việc đồng bộ phase↔allocation hai chiều ở tầng dữ liệu; v17 chỉ thêm *hỗ trợ nhập liệu* ở UI, không phải mô hình dữ liệu mới. Khi xây t4, bám mockup v17 cho hành vi UI; khi xây schema, bám SPEC. Nếu thấy mâu thuẫn khác giữa mockup và SPEC → **mockup đúng cho UI/tương tác** (D12), nhưng nêu rõ cho người dùng trước khi tự quyết những thứ động tới schema.

## Quy ước làm việc
- **Cuối mỗi phase:** commit + push, message mô tả phase (vd "Phase 1: schema + seed + views"). Tạo điểm khôi phục rõ ràng.
- **Secret:** TUYỆT ĐỐI không commit secret vào file **được git track** (sẽ lọt vào history + push lên GitHub). Cấm gồm: `service_role` key, LLM API key, GitHub PAT, Vercel token (`vcp_…`), Supabase access token (`sbp_…`), mật khẩu tài khoản.
  - **ĐƯỢC PHÉP lưu PAT/token phục vụ development** trong file **gitignored** (mặc định `.env` ở root — `.gitignore` đã chặn `.env`, `.env.*`, `*.local`, `.dev-secrets`). Dùng cho deploy/Management API trong phiên làm việc. Trước khi ghi token, LUÔN kiểm `git check-ignore -v <file>` để chắc nó không bị track.
  - **Lưu ý ephemeral:** container của Claude Code web là tạm thời — file `.env` KHÔNG tồn tại ở session mới. Muốn token sống qua nhiều session: thêm vào **Environment Variables của Claude Code web environment** (hoặc GitHub Secrets cho workflow), không phải file trong repo.
  - Anon key của Supabase được phép nhúng trong `web/index.html` (theo thiết kế Supabase + RLS — xem SPEC §7).
- **Khi đổi hướng thiết kế:** cập nhật `docs/DECISIONS.md` (và SPEC nếu cần) để Claude Chat và Claude Code không lệch. Đây là điểm đồng bộ chung giữa hai nơi.
- **Definition of Done — luật chống lệch tài liệu (Lớp 2):** mỗi thay đổi PHẢI cập nhật doc liên quan **trong CÙNG commit**. Ánh xạ:

  | Đổi gì trong code/DB | Phải cập nhật doc (LIVING) |
  |---|---|
  | `db/schema.sql` / `db/views.sql` | `DATABASE.md` (+ `SPEC.md` nếu đụng đặc tả) |
  | Tính năng / hành vi UI (mới hoặc sửa) | `user-stories.md` (story + acceptance; NFR ở Phụ lục A) + `PROJECT-CONTEXT.md` (status) |
  | Đổi hướng thiết kế | `DECISIONS.md` |
  | Hoãn / bỏ việc | `BACKLOG.md` |

  **Phân loại doc — chỉ LIVING mới cập nhật theo commit:**
  - 🟢 **LIVING** (sửa mỗi commit liên quan): `PROJECT-CONTEXT.md`, `DECISIONS.md`, `DATABASE.md`, **`user-stories.md`** (doc yêu cầu sống duy nhất — đã gộp NFR).
  - 📸 **BASELINE SNAPSHOT** (KHÔNG sửa từng commit): `BRD.md`, `SRS.md`. Chỉ **regenerate on-demand** từ `user-stories.md` + code khi cần bản formal (milestone / gửi stakeholder / handoff / đấu thầu), hoặc khi **scope nghiệp vụ** đổi (riêng BRD). Lý do: 3 doc yêu cầu chồng lấp → maintain song song = churn + lệch; Claude tái sinh được từ nguồn sống nên không cần giữ liên tục.

  **Cuối mỗi session (Lớp 3):** rà `PROJECT-CONTEXT.md` (status) + doc LIVING bị ảnh hưởng → commit chung. Nguyên tắc: *code và doc-sống đi cùng nhau, không để lệch quá 1 commit.*
- **Sửa thiết kế & mockup:** Claude Code ĐƯỢC PHÉP đổi thiết kế, sửa mockup, thử UX trực tiếp tại đây — không cần chuyển qua Claude Chat. Điều kiện duy nhất: khi đổi hướng thiết kế, cập nhật `docs/DECISIONS.md` (và SPEC nếu cần) ngay trong cùng đợt sửa để mọi session sau không lệch.
- **Gate chất lượng — `/sa-review`:** repo có subagent **`tech-reviewer`** (`.claude/agents/`) + slash command **`/sa-review [full|web|db|deploy|docs|<change>]`** (`.claude/commands/`). Chạy 8 checkpoint (5 luật bất biến · bảo mật tiền DB · schema · secret · doc-sync · test & **verify-live** · ops/deploy · performance) → báo cáo PASS/WARN/FAIL + verdict go-live. **Nên chạy trước khi go-live / sau thay đổi lớn / khi review PR.** Review chỉ-đọc, không tự sửa.
- **Deploy = git auto-deploy:** project Vercel `web` đã nối GitHub (`rootDirectory=web`, `prodBranch=main`). **Push `main` là tự lên production** — KHÔNG còn CLI tay. Thay đổi `web/` chưa coi là "done" cho tới khi **verify live** (deployment `src=git state=READY` cho commit mới nhất). Đừng báo done khi mới chỉ push.

## Bắt đầu từ đâu
Nếu repo chưa có gì trong `db/`: bắt đầu **Phase 1**. Đọc SPEC.md §4 (schema) + §9 (nghiệm thu), dựng `db/schema.sql`, `db/seed.sql`, `db/views.sql`, rồi in hướng dẫn tạo Supabase project và chạy SQL (Claude Code không tự đăng nhập Supabase của người dùng được — bước tạo project + chạy SQL là việc tay của họ).
