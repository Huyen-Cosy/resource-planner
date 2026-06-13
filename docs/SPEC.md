# SPEC — Resource Planner (planning tool quản lý nguồn lực đa dự án)

> Tài liệu bàn giao cho Claude Code. Đọc kèm 3 file: `mockup-resource-planner.html` (đặc tả hành vi trực quan — nguồn sự thật về UX), `DECISIONS.md` (vì sao thiết kế như vậy), `BACKLOG.md` (việc cố ý hoãn).
> Ngôn ngữ giao diện: **tiếng Việt**. Code/tên bảng/tên cột: **tiếng Anh**.
> **Mockup là đặc tả hành vi.** Khi spec và mockup có vẻ khác nhau, mockup đúng cho phần UI/tương tác; spec đúng cho phần backend/database/đồng bộ mà mockup không thể hiện được.

---

## 0. Bản chất sản phẩm (đọc trước tiên — đừng làm sai)

Đây là **PLANNING tool**, KHÔNG phải execution/tracking tool. Nó trả lời "nếu bố trí nguồn lực thế này thì bức tranh nhân sự và tài chính **dự kiến** ra sao". Nó KHÔNG theo dõi tiến độ thực, KHÔNG có khái niệm "% hoàn thành", KHÔNG có "chi tiêu thực tế tới hôm nay", KHÔNG cần ai cập nhật hằng ngày/tuần.

Hệ quả thiết kế bắt buộc:
- Mọi chỉ số phải tính được từ **dữ liệu kế hoạch** (allocation, gán người, rate, doanh thu). Nếu một chỉ số đòi nhập tiến độ/chi tiêu thực → KHÔNG thuộc tool này.
- Vòng "thực tế" duy nhất là lúc **đóng dự án** (nhập số liệu thực tế một lần, để AI học cho lần estimate sau).
- Dữ liệu thay đổi vài lần/tháng (dự án mới, tái phân bổ), không phải cập nhật liên tục.

## 1. Granularity & các khái niệm cốt lõi

- Đơn vị thời gian: **THÁNG**. Đơn vị nhân lực: **người (FTE)**, ghi theo số (1 = một người full-time, 0.5 = nửa thời gian).
- **Role**: chức danh (DE, DS, DA, PM, PO, DATA_LEAD, ARCH...). Danh mục role **tùy biến được** (thêm Finance Support, QA...).
- **Allocation** (`alloc[role][tháng]`): nhu cầu **mức role** — "tháng 8 cần 1 DE". Đây là lớp kế hoạch cơ bản, luôn có.
- **Gán người** (`assign[role][tháng][employee_id] = %`): xếp **cá nhân cụ thể** vào nhu cầu role. **OPTIONAL** — mọi tính năng phải chạy được khi chưa gán ai. Một người gán nhiều dự án/tháng → cộng % để phát hiện quá tải.
- **project.roles**: danh sách role **tham gia** dự án, khai báo **tường minh** (không suy ngầm từ alloc>0). Bảng phân bổ và khối gán người đều render theo danh sách này.
- **Rate theo CÁ NHÂN** (không theo role): mỗi nhân sự có `level` (Intern/Junior/Middle/Senior/Lead) + `rateType` (monthly: triệu/tháng | hourly: nghìn/giờ, quy đổi 160h/tháng) + `rate`. Có bảng `level_rate` (rate gợi ý theo level) dùng khi chưa gán người.
- **Tài chính**: doanh thu (giá trị hợp đồng) − tổng chi phí = margin **kế hoạch**. Tổng chi phí = chi phí nhân sự + `otherCost` (license, hạ tầng, thầu phụ). **KHÔNG dùng khái niệm "effort đã bán (người-tháng)"** — đã loại bỏ; thước đo lời/lỗ duy nhất là margin tiền.

## 2. Công thức tính (đây là "trí tuệ" của tool — toàn bộ là SQL view / hàm thuần, 0 token vận hành)

```
roleCapacity(r)       = số nhân sự active thuộc role r (đếm từ employees);
                        nếu role chưa có ai → dùng declared_capacity[r]
empMonthlyCost(e)     = rateType='monthly' ? rate
                        : rate * 160 / 1000   (hourly: nghìn/giờ → triệu/tháng)
avgRoleCost(r)        = trung bình empMonthlyCost của người active thuộc role r
                        (fallback level Middle nếu role chưa có ai)
projCostMonth(p,i)    = Σ theo role:
                          nếu tháng-role đã gán người: Σ (%/100 × empMonthlyCost(người))
                                                       + (need − assignedFTE) × avgRoleCost(r)
                          nếu chưa gán: need × avgRoleCost(r)
projCost(p)           = Σ projCostMonth(p, mọi tháng)
projMgmtCost(p)       = (projCost(p) + otherCost) × mgmt_pct/100   -- overhead vai quản lý (D16)
projTotalCost(p)      = projCost(p) + otherCost + projMgmtCost(p)
projMargin(p)         = revenue − projTotalCost(p)
demand[r][i]          = Σ alloc[r][i] của mọi dự án active   (mức role)
gap[r][i]             = roleCapacity(r) − demand[r][i]   (<0 thiếu, >0 dư)
empLoad(e,i)          = Σ % của e trong tháng i, cộng mọi dự án active  (>100% = quá tải)
```

## 3. Kiến trúc kỹ thuật (giữ nguyên từ thiết kế gốc)

```
Repo skill (Git) ──pull──► Claude Code của từng PM (lệnh /estimate, /close)
                                   │ GET ref+examples / POST kết quả (REST)
                                   ▼
Web app tĩnh ──CRUD/form──► SUPABASE (Postgres + REST + Edge Functions) ◄── Power BI (tùy chọn)
     │ nút "AI Generate"          │  toàn bộ tính toán = SQL view
     ▼                            │
Edge Function llm-proxy ──► LLM provider (free: Groq/Gemini/NVIDIA | Anthropic) — cấu hình động qua app_llm_configs
```

- **Web app**: vanilla HTML+JS, `@supabase/supabase-js` + Frappe Gantt qua CDN. Không build step. Host Cloudflare Pages/Vercel (free).
- **Supabase free tier**: Postgres + REST tự sinh + Edge Functions + Storage (cho tài liệu đính kèm).
- **Nhiều PM, nhiều device**: Supabase là nguồn sự thật chung; web app và Claude Code là 2 client độc lập cùng đọc/ghi vào đó. KHÔNG có kết nối trực tiếp giữa Claude Code và web app.

## 4. Database schema (Supabase Postgres)

```sql
-- Danh mục role (tùy biến)
create table ref_roles (
  code text primary key,                 -- 'DE','DS','DA','PM','PO','DATA_LEAD','ARCH','FIN'...
  name text not null,
  declared_capacity numeric default 0,   -- số người khai báo/kế hoạch (fallback khi chưa có người thật)
  sort_order int default 0
);

-- Rate gợi ý theo level
create table ref_level_rates (
  level text primary key,                -- 'Intern','Junior','Middle','Senior','Lead'
  monthly_rate numeric not null          -- triệu/tháng
);

-- Norms cho AI estimate (tự hiệu chỉnh qua vòng /close)
create table ref_norms (key text primary key, value numeric, description text, updated_at timestamptz default now());
create table ref_project_types (code text primary key, name text);

-- Nhân sự — rate theo CÁ NHÂN
create table employees (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  role_code text not null references ref_roles(code),
  level text references ref_level_rates(level),
  rate_type text not null default 'monthly' check (rate_type in ('monthly','hourly')),
  rate numeric not null default 0,       -- monthly: triệu/tháng | hourly: nghìn/giờ
  active boolean not null default true,
  created_at timestamptz default now()
);

create table projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  project_type text references ref_project_types(code),
  pm_owner text not null,
  priority int default 3 check (priority between 1 and 5),
  status text not null default 'active' check (status in ('draft','active','closed','cancelled')),
  start_month date not null,             -- luôn ngày 01
  end_month date not null,
  revenue numeric default 0,             -- giá trị hợp đồng (triệu) — thước đo lời/lỗ
  other_cost numeric default 0,          -- chi phí khác ngoài lương (triệu)
  mgmt_pct numeric default 0,            -- % chi phí management (overhead vai quản lý không tính giờ) — xem D16
  roles text[] default '{}',             -- danh sách role tham gia (tường minh)
  created_by text not null,
  playbook_version text,
  model_version text,                    -- model AI sinh estimation (cho vòng học so sánh)
  created_at timestamptz default now(),
  closed_at timestamptz,
  close_note text,
  check (end_month >= start_month),
  check (extract(day from start_month)=1 and extract(day from end_month)=1)
);

create table phases (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  name text not null,
  start_month date not null,
  end_month date not null,
  sort_order int default 1,
  check (end_month >= start_month)
);

-- Nhu cầu mức role theo tháng (lớp kế hoạch cơ bản)
create table allocations (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  role_code text not null references ref_roles(code),
  month date not null,                   -- ngày 01
  headcount numeric not null check (headcount >= 0 and headcount <= 50),
  kind text not null default 'estimate' check (kind in ('estimate','actual')),
  unique (project_id, role_code, month, kind),
  check (extract(day from month)=1)
);

-- Gán người cụ thể (OPTIONAL) — % của 1 cá nhân vào 1 role-tháng của 1 dự án
create table assignments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  role_code text not null references ref_roles(code),
  month date not null,
  employee_id uuid not null references employees(id) on delete cascade,
  percent numeric not null check (percent > 0 and percent <= 100),
  unique (project_id, role_code, month, employee_id),
  check (extract(day from month)=1)
);

-- Cấu hình AI model (admin quản lý, PM chọn) — đổi model không cần redeploy
create table app_llm_configs (
  id uuid primary key default gen_random_uuid(),
  label text not null,                   -- 'Gemini 2.0 Flash'
  provider text not null,                -- 'openai_compatible' | 'anthropic'
  base_url text, model text,
  is_active boolean default false,       -- model đang dùng
  sort_order int default 0
);

create table audit_log (
  id bigint generated always as identity primary key,
  actor text, action text, entity text, entity_id text, detail jsonb, at timestamptz default now()
);
```

### Views (toàn bộ tính toán nằm đây)
- `v_monthly_demand` — Σ headcount theo role×tháng (dự án active, kind=estimate).
- `v_capacity_gap` — roleCapacity − demand theo role×tháng (capacity đếm từ employees active, fallback declared_capacity).
- `v_conflict` — role×tháng có gap<0, kèm danh sách dự án gây thiếu.
- `v_employee_load` — Σ percent theo employee×tháng từ assignments (>100 = quá tải).
- `v_project_cost` — chi phí nhân sự theo dự án (theo công thức §2; ưu tiên người gán, fallback avgRoleCost).
- `v_project_margin` — revenue − (project_cost + other_cost).
- `v_slack` — dư địa: gap>0 theo role, dùng cho trang CEO (gộp theo khoảng thời gian ở tầng app).
- `v_estimate_vs_actual` — so allocations kind='estimate' vs 'actual' của dự án closed (vòng học).
- `v_norm_suggestions` — hệ số lệch trung bình theo project_type×role.

### Constraints = lưới an toàn cho AI (Lớp 3)
FK `role_code`→ref_roles (AI không bịa role), CHECK percent 0–100, headcount≤50, month phải ngày 01, end≥start. Estimation sai cấu trúc bị DB từ chối → Claude Code tự sửa & gửi lại.

## 5. Các màn hình (8 tab — khớp mockup, đọc mockup để biết chi tiết tương tác)

- **t0 — Tổng quan CEO** (planning): KPI (số dự án, tổng doanh thu, tổng margin %, số dự án lỗ kế hoạch, lượt role-tháng thiếu); bảng margin từng dự án (sắp lỗ-nhất lên đầu, KHÔNG có tiến độ/burn thực); cảnh báo xếp theo mức thiệt hại + gợi ý hành động; **dư địa nhận thêm việc** (gộp 1 dòng/role + chọn khoảng 3/6/12 tháng/toàn bộ); **what-if** (mô phỏng nhận thêm dự án giả định → margin dự kiến + có gây thiếu hụt không, KHÔNG lưu).
- **t1 — Bức tranh công ty**: ma trận role×tháng (demand/capacity, màu thiếu/đủ/nhàn rỗi), cảnh báo xung đột, KPI Σ margin. Trục tháng động (mở rộng theo dự án xa nhất).
- **t2 — Danh sách dự án**: bảng + cột Margin KH, bấm dòng mở chi tiết.
- **t3 — Chi tiết dự án**: chọn dự án (dropdown); sửa thời gian dự án + phase (Gantt vẽ lại); bảng phân bổ role×tháng (sửa inline, điền nhanh theo khoảng tháng, thêm/xóa role); **gán người** (bulk-assign 1 người×khoảng tháng×%, cột "Đã gán/Cần" theo **FTE** với 3 màu thiếu/đủ/dư, sửa %/xóa từng người, tên kèm role+level); **card Tài chính** (KPI doanh thu/chi phí/margin + burn kế hoạch theo tháng + ô nhập otherCost); nút Lưu + cờ "chưa lưu".
- **t4 — Tạo dự án mới**: Bước 1 (thông tin + tiêu chí estimation + đính kèm tài liệu + doanh thu). Cách 1 — tự nhập toàn bộ (phase + phân bổ + điền nhanh + nhân bản từ dự án có sẵn + kiểm tra fit). Cách 2 — AI Generate (qua llm-proxy, chọn model, kết quả duyệt/sửa trước khi lưu, kiểm tra fit). Cả hai → popup xác nhận → mở chi tiết.
- **t5 — Đóng dự án**: nhập actual theo role (prefill = estimate, chỉ sửa ô lệch), chênh lệch % tự tính, close_note. → ghi allocations kind='actual', status='closed'.
- **t6 — Cấu hình**: danh mục role (thêm/xóa); rate gợi ý theo level; quản lý nhân sự (CRUD + level + rate_type + rate, cột chi phí quy đổi); năng lực theo role (3 cột: khai báo / thực có đếm tự động / còn trống theo tháng chọn); cấu hình AI model (danh sách, chọn active, test, model hết quota bị khóa); gợi ý cập nhật norms.
- **t7 — Nguồn lực cá nhân**: 2 chế độ — **theo cá nhân** (timeline %tải, KPI quá tải, dự án tham gia) và **theo role** (toàn bộ người của role × %tải + hàng nhu cầu role); bảng toàn đội (người×tháng, đỏ khi quá tải). Tên luôn kèm role+level.

## 6. Đường AI estimation (2 cửa chung 1 playbook)

- **Cửa A — Claude Code** (`/estimate`, `/close`): repo skill riêng, mỗi PM clone. Quy trình: GET ref+norms+ví dụ dự án đã đóng → hỏi thông tin thiếu → generate JSON theo schema → POST (constraint validate) → báo conflict.
- **Cửa B — nút AI trên web**: gọi Edge Function `llm-proxy`. Input gồm `criteria` (khách mới/cũ, hiện trạng data, số nguồn, số module, độ phức tạp, IT đối ứng), `documents_text` (trích từ file đính kèm phía client), model chọn từ `app_llm_configs`. Proxy build prompt = playbook + ref + ví dụ → gọi LLM → trả JSON cho web duyệt (human-in-the-loop, KHÔNG tự ghi DB).
- **Vòng học**: dự án đóng lưu cả estimate & actual → `v_norm_suggestions` cập nhật `ref_norms` → mọi estimate sau tự sát hơn. `model_version` cho phép so model nào estimate chính xác nhất. KHÔNG fine-tune.

## 7. Credentials (cung cấp 1 lần, không hỏi lại)
- Supabase **anon key** trong `config.json` repo skill (private) + đầu web app → PM clone là chạy, không nhập key. Quyền giới hạn bởi RLS.
- **Đăng nhập bắt buộc (Supabase Auth) + RLS theo user — RBAC vào MVP (D19).** 2 nhóm: `finance` (CEO + Quản trị viên, ngang quyền — thấy rate/chi phí/margin/what-if) và `pm` (chỉ nhập dự án + gán người + lớp số người; **KHÔNG** thấy rate/chi phí/margin/doanh thu/management). Số tiền bị chặn ở **tầng database (RLS/security-definer view theo role)**, không chỉ ẩn UI — vì anon key nhúng ở client nên giấu nút không đủ an toàn. Role lưu ở `app_users` (hoặc JWT claim). Anon key chung vẫn nhúng được, nhưng dữ liệu nhạy cảm chỉ trả về sau khi đăng nhập đúng role.
- **service_role key** + **LLM API key**: chỉ trong Edge Function secrets, KHÔNG commit, KHÔNG phát cho PM.
- GitHub: `gh auth login` 1 lần/máy (hoặc fine-grained PAT). Claude Code web: gắn repo qua nút +.
- Cấm tuyệt đối: ghi service_role/LLM key/PAT vào bất kỳ file nào trong repo. Tạo `.gitignore` (`.env*`) từ Phase 1.

## 8. Kế hoạch thực thi (làm tuần tự, đánh dấu rõ MVP)

**MVP (build trước — đây là phần lõi tạo giá trị ngay):**
- Phase 1: schema.sql + seed.sql + views + constraints. Thêm `app_users` (role `finance`/`pm`) + **RLS theo role** che dữ liệu tiền khỏi `pm` (D19). In hướng dẫn tạo Supabase + chạy SQL.
- Phase 2: web app t1/t2/t3/t4(Cách 1 tự nhập)/t6 — CRUD đầy đủ, nhập tay, bức tranh công ty, tài chính cơ bản, quản lý role/nhân sự/rate. **Thêm màn đăng nhập (Supabase Auth) + ẩn cụm tài chính (KPI Σ margin t1, tài chính dự án t2/t3, rate ở t6) khi role=`pm`** (D19). Test bằng seed. Hướng dẫn deploy.
- Phase 3: gán người (t3 phần assign + t7 Nguồn lực cá nhân).
- Phase 4: trang CEO (t0) gồm dư địa + what-if; đóng dự án (t5).

**Sau MVP (Phase 5+ — xem BACKLOG.md):**
- Edge Function llm-proxy + nút AI Generate + cấu hình AI model động.
- Repo skill estimation + `/estimate` `/close` + vòng học norms.
- Đính kèm tài liệu (Storage + trích text).

**KHÔNG làm (xem BACKLOG.md để biết lý do hoãn):** đồng bộ allocation theo phase, gán effort theo phase rồi rải tháng, import HR, realtime subscription, test phủ rộng ở MVP. *(Phân quyền theo vai trò ĐÃ chuyển vào MVP — xem D19, không còn ở danh sách hoãn.)*

## 9. Tiêu chí nghiệm thu (MVP)
1. Seed → t1 hiển thị ma trận đúng; thêm dự án trùng tháng 7 dùng nhiều DE → cảnh báo đỏ thiếu DE kèm tên dự án.
2. POST allocation role_code không tồn tại → DB từ chối (FK).
3. t3: sửa rate 1 nhân sự ở t6 → margin dự án đổi ngay; gán senior vs junior vào cùng slot → chi phí khác nhau.
4. t3: cột "Đã gán/Cần" hiện FTE (vd "1.0/1 đủ", "2.0/1 dư"), không hiện % tổng vô nghĩa.
5. Thêm role "Finance Support" ở t6 → xuất hiện ở phân bổ, gán người, năng lực.
6. t0: what-if nhận thêm dự án → báo margin dự kiến + có gây thiếu hụt không; dư địa gộp 1 dòng/role theo khoảng chọn.
7. Đóng dự án với actual lệch → v_estimate_vs_actual ra ratio; v_norm_suggestions có dòng tương ứng.
