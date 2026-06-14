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
  ],
  v_employee_cost: [{ employee_id: "e1", rate_type: "monthly", rate: 70 }],
  v_projects_public: [],
  v_projects_finance: [],
  phases: [],
  allocations: [],
  assignments: [],
  app_llm_configs: [],
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

if (fails.length) {
  console.error("❌ SMOKE TEST FAIL\n" + fails.map((f) => "• " + f).join("\n"));
  process.exit(1);
}
console.log("✅ SMOKE TEST PASS — boot+load+render chạy sạch.");
console.log("   footCount: " + footEl().textContent.trim());
process.exit(0);
