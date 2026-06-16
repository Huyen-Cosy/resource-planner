// Smoke test — chạy NGUYÊN code web/index.html trong jsdom với Supabase stub.
// Mục tiêu: bắt lỗi RUNTIME khi boot+load+render (class lỗi như `const`→`let`
// reassignment, ReferenceError, hardcode role làm vỡ load) mà `node --check` bỏ sót.
// KHÔNG cần network/secret — toàn bộ Supabase được stub offline.
//
// Đậu khi: (A) không có lỗi script chưa bắt; (B) afterLogin chạy tới cuối
// (footCount được set) → loadFromSupabase + renderAll không ném; (C) app hiện ra.

import { JSDOM, VirtualConsole } from "jsdom";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(join(here, "..", "web", "index.html"), "utf8");

// ---- Mock data (đủ để chạy nhánh finance + kích [8] is_management/is_primary) ----
const MOCK = {
  app_users: [{ role: "finance" }],
  ref_roles: [
    { code: "DE",        name: "Data Engineer",     declared_capacity: 4, sort_order: 1,  is_management: false, is_primary: true  },
    { code: "DA",        name: "Data Analyst",      declared_capacity: 4, sort_order: 3,  is_management: false, is_primary: true  },
    { code: "PM",        name: "Project Manager",   declared_capacity: 3, sort_order: 4,  is_management: false, is_primary: true  },
    { code: "PO",        name: "Product Owner",     declared_capacity: 2, sort_order: 5,  is_management: true,  is_primary: false },
    { code: "DATA_LEAD", name: "Data Lead",         declared_capacity: 1, sort_order: 6,  is_management: true,  is_primary: false },
    { code: "DESIGN",    name: "Mockup Designer",   declared_capacity: 1, sort_order: 10, is_management: false, is_primary: true  },
  ],
  ref_project_types: [{ code: "BI_DASHBOARD" }, { code: "DATA_PLATFORM" }],
  v_level_rates: [{ level: "Senior", monthly_rate: 70 }, { level: "Middle", monthly_rate: 45 }],
  v_employees_public: [
    { id: "e1", name: "An",   role_code: "DE", active: true, level: "Senior" },
    { id: "e2", name: "Binh", role_code: "PM", active: true, level: "Middle" },
    { id: "e3", name: "Chi",  role_code: "DA", active: true, level: "Middle" },
  ],
  v_employee_cost: [
    { employee_id: "e1", rate_type: "monthly", rate: 70 },
    { employee_id: "e3", rate_type: "monthly", rate: 45 },
  ],
  // dự án bắt đầu trong QUÁ KHỨ (2025-10) → kích ANCHOR lùi lúc load (Phần 2)
  v_projects_public: [
    { id: "p1", name: "Past Proj", project_type: "BI_DASHBOARD", pm_owner: "Test",
      priority: 1, roles: ["DA"], start_month: "2025-10-01", end_month: "2026-04-01", status: "active" },
  ],
  v_projects_finance: [{ id: "p1", revenue: 800, other_cost: 0, mgmt_pct: 10, revenue_collected: 200 }],
  phases: [
    { project_id: "p1", name: "P1", start_month: "2025-10-01", end_month: "2025-12-01", sort_order: 1 },
    { project_id: "p1", name: "P2", start_month: "2026-01-01", end_month: "2026-03-01", sort_order: 2 },
  ],
  // allocation DA chỉ khai 2025-10 (1 người) — KHÔNG khai 2026-01
  allocations: [
    { project_id: "p1", role_code: "DA", month: "2025-10-01", headcount: 1, kind: "estimate" },
  ],
  // assignment: 2025-10 trong KH; 2026-01 NGOÀI KH (role chưa khai allocation tháng đó) → path (B)
  assignments: [
    { project_id: "p1", role_code: "DA", month: "2025-10-01", employee_id: "e3", percent: 100 },
    { project_id: "p1", role_code: "DA", month: "2026-01-01", employee_id: "e3", percent: 100 },
  ],
  app_llm_configs: [],
  // ghi chú dự án — mọi user CRUD; phải render ở card "Ghi chú dự án" của t3
  project_notes: [
    { id: "n1", project_id: "p1", body: "Ghi chú kiểm thử", author: "test@idealab.app",
      created_at: "2026-06-01T03:00:00Z", updated_at: "2026-06-01T03:00:00Z" },
  ],
};

// Query builder giả: mọi method chainable, await ra {data,error}. maybeSingle/single → 1 dòng.
function makeQuery(table) {
  let single = false;
  const rows = () => MOCK[table] ?? [];
  const settle = () => Promise.resolve({ data: single ? (rows()[0] ?? null) : rows(), error: null });
  const b = {
    select: () => b, order: () => b, eq: () => b, neq: () => b, in: () => b,
    is: () => b, gte: () => b, lte: () => b, limit: () => b,
    insert: () => b, update: () => b, delete: () => b, upsert: () => b,
    maybeSingle: () => { single = true; return b; },
    single: () => { single = true; return b; },
    then: (res, rej) => settle().then(res, rej),
  };
  return b;
}

const supabaseStub = {
  createClient: () => ({
    auth: {
      getSession: async () => ({ data: { session: { user: { id: "u1", email: "test@idealab.app" } } }, error: null }),
      onAuthStateChange: () => ({ data: { subscription: { unsubscribe() {} } } }),
      signInWithPassword: async () => ({ data: { user: { id: "u1", email: "test@idealab.app" } }, error: null }),
      signOut: async () => ({ error: null }),
    },
    from: (table) => makeQuery(table),
    rpc: async () => ({ data: [], error: null }),
  }),
};

// ---- Bắt lỗi script chưa xử lý ----
const scriptErrors = [];
const vc = new VirtualConsole();
vc.on("jsdomError", (e) => scriptErrors.push(e));

const dom = new JSDOM(html, {
  runScripts: "dangerously",
  virtualConsole: vc,
  url: "https://idealab-planner.vercel.app/",
  beforeParse(window) {
    window.supabase = supabaseStub;          // thay CDN script (jsdom không nạp external)
    window.scrollTo = () => {};
    window.alert = () => {};
    window.print = () => {};
  },
});

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

// chờ boot async settle (poll footCount tối đa ~6s)
const footEl = () => dom.window.document.getElementById("footCount");
let ok = false;
for (let i = 0; i < 60; i++) {
  await wait(100);
  if (footEl() && footEl().textContent.trim()) { ok = true; break; }
}

// ---- Mở chi tiết dự án để chạy renderDetail/renderAlloc/renderAssign (path (B) + ANCHOR quá khứ) ----
let detailHtml = "";
let phaseHtml = "";
let noteHtml = "";
let infoHtml = "";
let finHtml = "";
let reportHtml = "";
try {
  if (typeof dom.window.openProject === "function") {
    dom.window.openProject("p1");
    await wait(200);
    const box = dom.window.document.getElementById("assignBox");
    detailHtml = box ? box.innerHTML : "";
    const pe = dom.window.document.getElementById("phaseEdit");
    phaseHtml = pe ? pe.innerHTML : "";
    const nl = dom.window.document.getElementById("noteList");
    noteHtml = nl ? nl.innerHTML : "";
    const pi = dom.window.document.getElementById("projInfoCard");
    infoHtml = pi ? pi.innerHTML : "";
    const fk = dom.window.document.getElementById("finKpis");
    finHtml = fk ? fk.innerHTML : "";
    if (typeof dom.window.buildCeoReport === "function") reportHtml = dom.window.buildCeoReport();
  }
} catch (e) {
  scriptErrors.push({ detail: "openProject ném: " + e.message });
}

// ---- Assertions ----
const fails = [];
if (scriptErrors.length) {
  fails.push("Lỗi script chưa bắt:\n  " + scriptErrors.map((e) => (e.detail || e).toString().split("\n")[0]).join("\n  "));
}
if (!ok) {
  fails.push("footCount RỖNG sau 6s → boot/afterLogin/loadFromSupabase/renderAll đã ném (xem dbErr).");
}
const doc = dom.window.document;
const appRoot = doc.getElementById("appRoot");
if (ok && appRoot && appRoot.style.display === "none") {
  fails.push("appRoot vẫn ẩn → afterLogin chưa hiện app.");
}
// (B) chi tiết dự án phải render + nhận diện gán ngoài kế hoạch (2026-01 không có allocation)
if (ok && !detailHtml) {
  fails.push("Mở chi tiết dự án nhưng assignBox rỗng.");
} else if (ok && !detailHtml.includes("syncAllocFromAssign")) {
  fails.push("renderAssign KHÔNG phát hiện gán ngoài kế hoạch (path B có thể vỡ). assignBox len=" + detailHtml.length);
}
// đổi thứ tự phase: bảng phase phải render nút ▲▼ (movePhase)
if (ok && phaseHtml && !phaseHtml.includes("movePhase")) {
  fails.push("Bảng phase KHÔNG có nút đổi thứ tự (movePhase) — tính năng reorder có thể vỡ.");
}
// ghi chú dự án: card phải render ghi chú đã load + nút sửa/xóa
if (ok && !noteHtml.includes("Ghi chú kiểm thử")) {
  fails.push("Card Ghi chú dự án KHÔNG render note đã load. noteList=" + noteHtml.slice(0, 120));
} else if (ok && !(noteHtml.includes("deleteNote") && noteHtml.includes("startEditNote"))) {
  fails.push("Ghi chú thiếu nút sửa/xóa (startEditNote/deleteNote).");
}
// thông tin dự án editable: card phải có ô sửa (setProjField) + đổi trạng thái cả 3 (setProjStatus)
if (ok && !(infoHtml.includes("setProjField") && infoHtml.includes("setProjStatus"))) {
  fails.push("Card Thông tin dự án thiếu ô sửa/đổi trạng thái. projInfoCard=" + infoHtml.slice(0, 120));
} else if (ok && !["draft", "active", "closed"].every((s) => infoHtml.includes(`value="${s}"`))) {
  fails.push("Dropdown trạng thái thiếu 1 trong draft/active/closed.");
}
// thực thu / dự thu (D27): finKpis phải có KPI thực thu + đã thu 25% (200/800), margin KHÔNG đổi
if (ok && !(finHtml.includes("thực thu") && finHtml.includes("25%"))) {
  fails.push("Card Tài chính thiếu thực thu/% đã thu (D27). finKpis=" + finHtml.slice(0, 160));
}
// report export phải phản ánh D27 (thu hồi) + chạy không lỗi
if (ok && !(reportHtml.includes("Tình hình thu hồi") && reportHtml.includes("Thực thu"))) {
  fails.push("Report export thiếu phần Thu hồi (D27). reportHtml len=" + reportHtml.length);
}

if (fails.length) {
  console.error("❌ SMOKE TEST FAIL\n" + fails.map((f) => "• " + f).join("\n"));
  process.exit(1);
}
console.log("✅ SMOKE TEST PASS — boot+load+render chạy sạch.");
console.log("   footCount: " + footEl().textContent.trim());
process.exit(0);
