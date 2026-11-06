// Unit tests for ui-check (no real browser: a fake Playwright drives the runner). Run: node --test
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadConfig, matrix, themeInitScript, findingsFor, summarize, toMarkdown, PAGE_PROBE } from '../scripts/ui-check/lib.mjs';
import { runChecks } from '../scripts/ui-check/ui-check.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const CLI = path.join(HERE, '../scripts/ui-check/ui-check.mjs');
const base = { baseUrl: 'https://x.test/', pages: [{ name: 'home', path: '/' }, { name: 'list', path: '/l' }] };

test('config: defaults and trailing slash', () => {
  const c = loadConfig(base);
  assert.equal(c.baseUrl, 'https://x.test');
  assert.deepEqual(c.widths, [375, 1280]); assert.deepEqual(c.themes, ['light']); assert.deepEqual(c.failOn, ['serious', 'critical']);
  assert.equal(c.checks.axe, true); assert.equal(c.themeStrategy.type, 'media');
});
test('config: overrides win, partial checks merge', () => {
  const c = loadConfig({ ...base, checks: { console: false } }, { baseUrl: 'http://staging.test' });
  assert.equal(c.baseUrl, 'http://staging.test'); assert.equal(c.checks.console, false); assert.equal(c.checks.axe, true);
  assert.equal(loadConfig(base, { baseUrl: undefined }).baseUrl, 'https://x.test');
});
test('config: every validation error is reported', () => {
  const bad = { baseUrl: 'ftp://x', pages: [{ name: 'a', path: 'no-slash' }, null], widths: [100, 375.5], themes: ['blue'], failOn: ['fatal'], themeStrategy: { type: 'nope' } };
  try { loadConfig(bad); assert.fail('should throw'); } catch (e) {
    assert.equal(e.configErrors.length, 7, e.message);
    for (const m of ['baseUrl', 'pages[0]', 'pages[1]', 'widths', 'themes', 'failOn', 'themeStrategy.type']) assert.ok(e.message.includes(m), m);
  }
  assert.throws(() => loadConfig({ baseUrl: 'https://x.test', pages: [] }), /at least one/);
  assert.throws(() => loadConfig({ ...base, themeStrategy: { type: 'attribute' } }), /needs a name/);
  assert.throws(() => loadConfig({ ...base, themeStrategy: { type: 'storage' } }), /needs a key/);
  assert.doesNotThrow(() => loadConfig({ ...base, widths: [240, 3840] }));
  assert.throws(() => loadConfig({ ...base, widths: [239] })); assert.throws(() => loadConfig({ ...base, widths: [3841] }));
});
test('matrix: pages × widths × themes, per-page overrides, mobile height', () => {
  const c = loadConfig({ ...base, themes: ['light', 'dark'], pages: [{ name: 'home', path: '/' }, { name: 'only-mobile', path: '/m', widths: [375], themes: ['dark'] }] });
  const m = matrix(c);
  assert.equal(m.length, 2 * 2 + 1);
  assert.deepEqual(m.at(-1), { page: 'only-mobile', url: 'https://x.test/m', width: 375, height: 812, theme: 'dark' });
  assert.equal(m.find((r) => r.width === 1280).height, 900);
  assert.equal(matrix(loadConfig({ ...base, widths: [767, 768] })).map((r) => r.height).join(), '812,900,812,900');
});
test('theme init scripts', () => {
  assert.equal(themeInitScript({ type: 'media' }, 'dark'), '');
  assert.match(themeInitScript({ type: 'class' }, 'dark'), /classList\.add\("dark"\)/);
  assert.match(themeInitScript({ type: 'class', name: 'theme-dark' }, 'light'), /classList\.remove\("theme-dark"\)/);
  assert.match(themeInitScript({ type: 'attribute', name: 'data-theme' }, 'dark'), /setAttribute\("data-theme", "dark"\)/);
  assert.match(themeInitScript({ type: 'attribute', name: 'data-mode', light: 'day' }, 'light'), /"data-mode", "day"/);
  assert.match(themeInitScript({ type: 'storage', key: 'theme', dark: 'night' }, 'dark'), /setItem\("theme", "night"\)/);
});

const c0 = loadConfig({ ...base, ignore: { axeRules: ['region'], console: ['DevTools'] } });
const run = { page: 'home', width: 375, theme: 'dark' };
const v = (id, impact, n = 1) => ({ id, impact, help: `${id} help`, nodes: Array.from({ length: n }, (_, i) => ({ target: [`#n${i}`] })) });
test('findings: axe levels follow failOn, ignored rules dropped, node list capped', () => {
  const f = findingsFor({ run, axe: [v('color-contrast', 'serious', 5), v('landmark', 'moderate'), v('region', 'critical'), v('aria', 'critical')] }, c0);
  assert.deepEqual(f.map((x) => `${x.rule}:${x.level}`), ['color-contrast:fail', 'landmark:warn', 'aria:fail']);
  assert.match(f[0].message, /#n0, #n1, #n2 \(\+2 more\)/);
  assert.equal(f[0].at, 'home · 375px · dark');
  const strict = loadConfig({ ...base, failOn: ['moderate', 'serious', 'critical'] });
  assert.equal(findingsFor({ run, axe: [v('landmark', 'moderate')] }, strict)[0].level, 'fail');
});
test('findings: overflow only beyond 1px, lists widest elements', () => {
  assert.equal(findingsFor({ run, probe: { scrollWidth: 376, innerWidth: 375, wide: [], broken: [] } }, c0).length, 0);
  const f = findingsFor({ run, probe: { scrollWidth: 980, innerWidth: 375, wide: ['div.hero (980px)'], broken: [] } }, c0);
  assert.equal(f.length, 1); assert.equal(f[0].kind, 'overflow'); assert.match(f[0].message, /980px wide in a 375px viewport — culprits: div\.hero/);
});
test('findings: images, console (with ignore), requests 4xx warn / 5xx fail', () => {
  const f = findingsFor({ run, probe: { scrollWidth: 375, innerWidth: 375, wide: [], broken: ['/a.png'] }, console: ['Download the React DevTools', 'TypeError: x is undefined'], requests: [{ url: 'https://x.test/api', status: 404 }, { url: 'https://x.test/b', status: 502 }, { url: 'https://x.test/c', status: 200 }] }, c0);
  assert.deepEqual(f.map((x) => `${x.kind}:${x.level}`), ['image:fail', 'console:fail', 'request:warn', 'request:fail']);
});
test('findings: switched-off checks are skipped; load error short-circuits', () => {
  const off = loadConfig({ ...base, checks: { axe: false, overflow: false, images: false, console: false, requests: false } });
  assert.equal(findingsFor({ run, axe: [v('x', 'critical')], probe: { scrollWidth: 999, innerWidth: 375, wide: [], broken: ['/a'] }, console: ['e'], requests: [{ url: 'u', status: 500 }] }, off).length, 0);
  const f = findingsFor({ run, error: 'net::ERR', axe: [v('x', 'critical')] }, c0);
  assert.deepEqual(f.map((x) => x.kind), ['load']);
});
test('summary and markdown', () => {
  const s = summarize([{ run, axe: [v('color-contrast', 'serious'), v('landmark', 'minor')] }, { run: { ...run, width: 1280 }, probe: { scrollWidth: 2000, innerWidth: 1280, wide: [], broken: [] } }], c0);
  assert.equal(s.runs, 2); assert.equal(s.failed, 2); assert.equal(s.warnings, 1); assert.equal(s.ok, false);
  assert.deepEqual(s.byKind, { axe: 1, overflow: 1 });
  const md = toMarkdown(s, c0);
  assert.match(md, /\*\*2 failing\*\* · 1 warnings/); assert.match(md, /## Failing/); assert.match(md, /## Warnings/); assert.match(md, /\| axe \| 1 \|/);
  const okmd = toMarkdown(summarize([{ run, axe: [] }], c0), c0);
  assert.match(okmd, /All checks passed/); assert.doesNotMatch(okmd, /## Failing/);
});
test('page probe is a self-contained expression', () => {
  assert.match(PAGE_PROBE, /^\(\(\) => \{/); assert.match(PAGE_PROBE, /\}\)\(\)$/);
  assert.doesNotThrow(() => new Function(`return ${PAGE_PROBE.replace(/\)\(\)$/, ')')}`));
});

// ---- runner with a fake Playwright
function fakePlaywright(behaviour) {
  const rec = { contexts: [], closed: { ctx: 0, browser: 0 }, axeTags: null };
  const chromium = { launch: async () => ({
    newContext: async (opts) => { const ctx = { opts, init: [], closed: false };
      rec.contexts.push(ctx);
      return { addInitScript: async (s) => ctx.init.push(s), close: async () => { rec.closed.ctx++; },
        newPage: async () => { const handlers = {}; ctx.handlers = handlers;
          return { on: (ev, fn) => { handlers[ev] = fn; },
            goto: async (url) => { ctx.url = url; return behaviour.goto(url, handlers); },
            waitForTimeout: async () => {}, evaluate: async () => behaviour.probe(ctx), screenshot: async () => {} }; } }; },
    close: async () => { rec.closed.browser++; } }) };
  class AxeBuilder { constructor({ page }) { this.page = page; } withTags(t) { rec.axeTags = t; return this; } async analyze() { return { violations: behaviour.axe() }; } }
  return { chromium, AxeBuilder, rec };
}
const msg = (type, text) => ({ type: () => type, text: () => text });
const res = (url, status) => ({ url: () => url, status: () => status });
test('runner: theme per context, events collected, same-origin requests only', async () => {
  const c = loadConfig({ ...base, pages: [{ name: 'home', path: '/' }], widths: [375], themes: ['light', 'dark'], themeStrategy: { type: 'class' } });
  const fp = fakePlaywright({
    goto: (url, h) => { h.console(msg('error', 'boom')); h.console(msg('warning', 'meh')); h.pageerror(new Error('uncaught')); h.response(res('https://x.test/api', 500)); h.response(res('https://cdn.other/x', 404)); return res(url, 200); },
    probe: () => ({ scrollWidth: 375, innerWidth: 375, wide: [], broken: [] }), axe: () => [v('color-contrast', 'serious')] });
  const raws = await runChecks(c, fp);
  assert.equal(raws.length, 2);
  assert.deepEqual(fp.rec.contexts.map((x) => x.opts.colorScheme), ['light', 'dark']);
  assert.match(fp.rec.contexts[1].init[0], /classList\.add/); assert.match(fp.rec.contexts[0].init[0], /classList\.remove/);
  assert.deepEqual(raws[0].console, ['boom', 'uncaught']);
  assert.deepEqual(raws[0].requests, [{ url: 'https://x.test/api', status: 500 }]);
  assert.equal(raws[0].axe[0].id, 'color-contrast'); assert.deepEqual(fp.rec.axeTags, c.axeTags);
  assert.deepEqual(fp.rec.closed, { ctx: 2, browser: 1 });
});
test('runner: media strategy adds no init script; HTTP error and thrown goto become load errors', async () => {
  const c = loadConfig({ ...base, widths: [1280] });
  let n = 0;
  const fp = fakePlaywright({ goto: (url) => { n++; if (n === 1) return res(url, 503); throw new Error('net::ERR_CONNECTION_REFUSED\nstack'); },
    probe: () => { throw new Error('not reached'); }, axe: () => [] });
  const raws = await runChecks(c, fp);
  assert.equal(fp.rec.contexts[0].init.length, 0);
  assert.deepEqual(raws.map((r) => r.error), ['HTTP 503', 'net::ERR_CONNECTION_REFUSED']);
  assert.equal(summarize(raws, c).byKind.load, 2);
});
test('runner: axe can be switched off', async () => {
  const c = loadConfig({ ...base, pages: [{ name: 'h', path: '/' }], widths: [375], checks: { axe: false } });
  const fp = fakePlaywright({ goto: (u) => res(u, 200), probe: () => ({ scrollWidth: 375, innerWidth: 375, wide: [], broken: [] }), axe: () => { throw new Error('axe should not run'); } });
  const raws = await runChecks(c, fp); assert.equal(raws[0].error, undefined); assert.deepEqual(raws[0].axe, []);
});
test('runner: browser closes even when a context fails', async () => {
  const c = loadConfig(base);
  const fp = fakePlaywright({ goto: (u) => res(u, 200), probe: () => ({ scrollWidth: 1, innerWidth: 1, wide: [], broken: [] }), axe: () => [] });
  const launch = fp.chromium.launch;
  fp.chromium.launch = async () => { const b = await launch(); b.newContext = async () => { throw new Error('ctx fail'); }; return b; };
  await assert.rejects(runChecks(c, fp), /ctx fail/); assert.equal(fp.rec.closed.browser, 1);
});
test('cli: missing config and missing playwright exit 2 with guidance', () => {
  const dir = mkdtempSync(path.join(tmpdir(), 'uic-'));
  const run = () => { try { execFileSync('node', [CLI, '--config', 'ui-check.config.json'], { cwd: dir, stdio: 'pipe' }); return { code: 0 }; } catch (e) { return { code: e.status, err: String(e.stderr) }; } };
  let r = run(); assert.equal(r.code, 2); assert.match(r.err, /no config at ui-check.config.json/);
  writeFileSync(path.join(dir, 'ui-check.config.json'), JSON.stringify({ baseUrl: 'nope', pages: [] }));
  r = run(); assert.equal(r.code, 2); assert.match(r.err, /baseUrl must be/);
  writeFileSync(path.join(dir, 'ui-check.config.json'), JSON.stringify(base));
  r = run(); assert.equal(r.code, 2); assert.match(r.err, /npm i -D playwright @axe-core\/playwright/);
});
