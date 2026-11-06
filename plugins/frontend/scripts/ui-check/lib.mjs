// Pure logic for ui-check: config, run matrix, page probes, summary, report. No browser imports here.

export const DEFAULTS = {
  widths: [375, 1280],
  themes: ['light'],
  themeStrategy: { type: 'media' }, // media | class | attribute | storage
  failOn: ['serious', 'critical'],
  checks: { axe: true, overflow: true, console: true, images: true, requests: true },
  axeTags: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'],
  ignore: { axeRules: [], console: [] },
  waitMs: 500,
  timeoutMs: 30000,
};

export function loadConfig(raw, overrides = {}) {
  const c = { ...DEFAULTS, ...raw, ...Object.fromEntries(Object.entries(overrides).filter(([, v]) => v != null)) };
  c.checks = { ...DEFAULTS.checks, ...(raw.checks || {}) };
  c.ignore = { ...DEFAULTS.ignore, ...(raw.ignore || {}) };
  c.themeStrategy = { ...DEFAULTS.themeStrategy, ...(raw.themeStrategy || {}) };
  const errors = [];
  if (!c.baseUrl || !/^https?:\/\//.test(c.baseUrl)) errors.push('baseUrl must be an http(s) URL');
  if (!Array.isArray(c.pages) || c.pages.length === 0) errors.push('pages must list at least one { name, path }');
  else c.pages.forEach((p, i) => { if (!p || !p.name || typeof p.path !== 'string' || !p.path.startsWith('/')) errors.push(`pages[${i}] needs a name and a path starting with /`); });
  if (!Array.isArray(c.widths) || !c.widths.every((w) => Number.isInteger(w) && w >= 240 && w <= 3840)) errors.push('widths must be integers between 240 and 3840');
  if (!Array.isArray(c.themes) || !c.themes.every((t) => t === 'light' || t === 'dark')) errors.push('themes may only contain "light" and "dark"');
  const levels = ['minor', 'moderate', 'serious', 'critical'];
  if (!Array.isArray(c.failOn) || !c.failOn.every((l) => levels.includes(l))) errors.push(`failOn must be a subset of ${levels.join(', ')}`);
  if (!['media', 'class', 'attribute', 'storage'].includes(c.themeStrategy.type)) errors.push('themeStrategy.type must be media, class, attribute or storage');
  if (c.themeStrategy.type === 'attribute' && !c.themeStrategy.name) errors.push('themeStrategy "attribute" needs a name (e.g. data-theme)');
  if (c.themeStrategy.type === 'storage' && !c.themeStrategy.key) errors.push('themeStrategy "storage" needs a key (localStorage key)');
  if (errors.length) { const e = new Error(errors.join('\n')); e.configErrors = errors; throw e; }
  c.baseUrl = c.baseUrl.replace(/\/+$/, '');
  return c;
}

export function matrix(c) {
  const runs = [];
  for (const page of c.pages) for (const width of page.widths || c.widths) for (const theme of page.themes || c.themes)
    runs.push({ page: page.name, url: c.baseUrl + page.path, width, height: width < 768 ? 812 : 900, theme });
  return runs;
}

// Script run in the page before its own scripts: applies the theme the way the app expects it.
export function themeInitScript(strategy, theme) {
  switch (strategy.type) {
    case 'class': {
      const cls = strategy.name || 'dark';
      return `document.documentElement.classList.${theme === 'dark' ? 'add' : 'remove'}(${JSON.stringify(cls)});`;
    }
    case 'attribute':
      return `document.documentElement.setAttribute(${JSON.stringify(strategy.name)}, ${JSON.stringify(theme === 'dark' ? (strategy.dark || 'dark') : (strategy.light || 'light'))});`;
    case 'storage':
      return `try { localStorage.setItem(${JSON.stringify(strategy.key)}, ${JSON.stringify(theme === 'dark' ? (strategy.dark || 'dark') : (strategy.light || 'light'))}); } catch {}`;
    default:
      return '';
  }
}

// Evaluated inside the page: layout and image problems axe doesn't report.
export const PAGE_PROBE = `(() => {
  const de = document.documentElement, w = window.innerWidth;
  const label = (el) => el.tagName.toLowerCase() + (el.id ? '#' + el.id : '') + (el.classList.length ? '.' + [...el.classList].slice(0, 2).join('.') : '');
  const clippedByAncestor = (el) => { for (let p = el.parentElement; p && p !== document.body; p = p.parentElement) { const o = getComputedStyle(p).overflowX; if (o === 'auto' || o === 'scroll' || o === 'hidden' || o === 'clip') return true; } return false; };
  let wide = [];
  if (de.scrollWidth > w + 1) {
    const all = [...document.body.querySelectorAll('*')].filter((el) => { const r = el.getBoundingClientRect(); return r.right > w + 1 && r.width > 0 && getComputedStyle(el).position !== 'fixed'; });
    const set = new Set(all);
    // culprits: wide elements with no wide child (the leaf that pushes the page out), unclipped first
    const leaves = all.filter((el) => ![...el.children].some((ch) => set.has(ch)));
    const pick = leaves.filter((el) => !clippedByAncestor(el)).concat(leaves.filter(clippedByAncestor));
    wide = pick.slice(0, 5).map((el) => label(el) + ' (' + Math.round(el.getBoundingClientRect().right) + 'px' + (clippedByAncestor(el) ? ', inside a clipped box' : '') + ')');
  }
  const broken = [...document.images].filter((i) => i.complete && i.naturalWidth === 0 && i.getAttribute('src')).map((i) => i.getAttribute('src')).slice(0, 10);
  return { scrollWidth: de.scrollWidth, innerWidth: w, wide, broken };
})()`;

const SEV = { minor: 1, moderate: 2, serious: 3, critical: 4 };

// raw: { run, axe: [{id, impact, help, nodes: [{target}]}], probe, console: [text], requests: [{url, status}], error? }
export function findingsFor(raw, c) {
  const f = [];
  const at = `${raw.run.page} · ${raw.run.width}px · ${raw.run.theme}`;
  if (raw.error) { f.push({ level: 'fail', kind: 'load', at, message: `page did not load: ${raw.error}` }); return f; }
  if (c.checks.axe) for (const v of raw.axe || []) {
    if (c.ignore.axeRules.includes(v.id)) continue;
    const fails = c.failOn.includes(v.impact);
    f.push({ level: fails ? 'fail' : 'warn', kind: 'axe', at, rule: v.id, impact: v.impact,
      message: `${v.impact} ${v.id}: ${v.help} — ${(v.nodes || []).slice(0, 3).map((n) => [].concat(n.target).join(' ')).join(', ')}${(v.nodes || []).length > 3 ? ` (+${v.nodes.length - 3} more)` : ''}` });
  }
  if (c.checks.overflow && raw.probe && raw.probe.scrollWidth > raw.probe.innerWidth + 1)
    f.push({ level: 'fail', kind: 'overflow', at, message: `page scrolls sideways: ${raw.probe.scrollWidth}px wide in a ${raw.probe.innerWidth}px viewport${raw.probe.wide.length ? ' — culprits: ' + raw.probe.wide.join(', ') : ''}` });
  if (c.checks.images) for (const src of (raw.probe && raw.probe.broken) || [])
    f.push({ level: 'fail', kind: 'image', at, message: `broken image: ${src}` });
  if (c.checks.console) for (const text of raw.console || []) {
    if (c.ignore.console.some((pat) => new RegExp(pat).test(text))) continue;
    f.push({ level: 'fail', kind: 'console', at, message: `console error: ${text.slice(0, 200)}` });
  }
  if (c.checks.requests) for (const r of raw.requests || [])
    if (r.status >= 400) f.push({ level: r.status >= 500 ? 'fail' : 'warn', kind: 'request', at, message: `${r.status} ${r.url}` });
  return f;
}

export function summarize(raws, c) {
  const findings = raws.flatMap((r) => findingsFor(r, c));
  const fails = findings.filter((x) => x.level === 'fail');
  const byKind = {};
  for (const x of fails) byKind[x.kind] = (byKind[x.kind] || 0) + 1;
  return { runs: raws.length, failed: fails.length, warnings: findings.length - fails.length, byKind, findings, ok: fails.length === 0 };
}

export function toMarkdown(s, c) {
  const lines = [`# UI check — ${c.baseUrl}`, '', `${s.runs} page runs (${c.pages.length} pages × widths × themes) · **${s.failed} failing** · ${s.warnings} warnings`, ''];
  if (s.failed) {
    lines.push('| Kind | Count |', '|---|---|', ...Object.entries(s.byKind).sort((a, b) => b[1] - a[1]).map(([k, n]) => `| ${k} | ${n} |`), '');
  }
  const group = (lvl) => s.findings.filter((x) => x.level === lvl).sort((a, b) => (SEV[b.impact] || 0) - (SEV[a.impact] || 0));
  for (const [title, lvl] of [['Failing', 'fail'], ['Warnings', 'warn']]) {
    const xs = group(lvl); if (!xs.length) continue;
    lines.push(`## ${title}`, '', ...xs.map((x) => `- **${x.at}** · ${x.message}`), '');
  }
  if (s.ok) lines.push('All checks passed.');
  return lines.join('\n') + '\n';
}
