// checklist.mjs — the composition-checklist lint (core/contracts/composition.md).
//
// A plan's `합성 설계 체크리스트` table answers, with evidence, how its pure steps are
// composed. Three pure steps, composed by the caller:
//
//   checklist_rows      mdast tree → rows [{ num, answer, evidence }] | null (no table)
//   checklist_problems  rows | null → problems [{ kind, nums }]
//   render_warnings     problems, t → lint entries [{ level, message }]
//
// Warn — never block, never fill in. A table is "missing" only when the plan carries no
// checklist heading or no table under it; old plans are warned once, nothing more.

const HEAD_KEYS = ["체크리스트", "checklist", "チェックリスト"];
const ANSWER_KEYS = ["답", "answer", "答"];
const EVIDENCE_KEYS = ["근거", "evidence", "根拠"];

const text = (n) =>
  !n ? "" : typeof n.value === "string" ? n.value : Array.isArray(n.children) ? n.children.map(text).join("") : "";

// A cell that was never filled: empty, a dash, or the template's `<TODO …>` placeholder.
const blank = (s) => {
  const v = String(s || "").trim();
  return v === "" || /^[-–—]+$/.test(v) || /^<?\s*todo\b/i.test(v);
};

const col = (header, keys) =>
  header.findIndex((h) => keys.some((k) => h.toLowerCase().includes(k)));

// The table under ONE checklist heading — null when that heading carries none.
const table_under = (nodes, at) => {
  for (let i = at + 1; i < nodes.length; i++) {
    if (nodes[i].type === "heading") return null;
    if (nodes[i].type === "table") return nodes[i];
  }
  return null;
};

const rows_of = (table) => {
  const [head, ...body] = table.children.map((r) => r.children.map((c) => text(c).trim()));
  const a = col(head || [], ANSWER_KEYS);
  const e = col(head || [], EVIDENCE_KEYS);
  if (a < 0 || e < 0) return null;
  return body.map((cells) => ({ num: cells[0] || "", answer: cells[a] || "", evidence: cells[e] || "" }));
};

// Every part of the plan folder is scanned, so another heading may carry the word
// (a tests checklist, say) — the first heading whose table has answer + evidence wins.
export function checklist_rows(tree) {
  const nodes = Array.isArray(tree && tree.children) ? tree.children : [];
  for (let i = 0; i < nodes.length; i++) {
    const n = nodes[i];
    if (n.type !== "heading" || n.depth < 2) continue;
    if (!HEAD_KEYS.some((k) => text(n).toLowerCase().includes(k))) continue;
    const table = table_under(nodes, i);
    const rows = table ? rows_of(table) : null;
    if (rows) return rows;
  }
  return null;
}

// One pass over the rows — a row with no answer is not also asked for its evidence.
export function checklist_problems(rows) {
  if (rows == null) return [{ kind: "missing", nums: [] }];
  const noAnswer = [];
  const noEvidence = [];
  for (const r of rows) {
    if (blank(r.answer)) noAnswer.push(r.num);
    else if (blank(r.evidence)) noEvidence.push(r.num);
  }
  return [
    ...(noAnswer.length ? [{ kind: "noAnswer", nums: noAnswer }] : []),
    ...(noEvidence.length ? [{ kind: "noEvidence", nums: noEvidence }] : []),
  ];
}

const KEY = { missing: "lintNoChecklist", noAnswer: "lintChecklistNoAnswer", noEvidence: "lintChecklistNoEvidence" };

export function render_warnings(problems, t) {
  return problems.map((p) => ({ level: "warn", message: t(KEY[p.kind], p.nums.join(", ")) }));
}
