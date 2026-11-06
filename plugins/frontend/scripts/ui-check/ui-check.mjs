#!/usr/bin/env node
// Browser checks for a running site: axe accessibility, sideways scrolling, broken images, console errors and failed
// requests — per page × width × theme. Exit 1 when anything fails (CI gate).
//
//   node ui-check.mjs [--config ui-check.config.json] [--base-url https://staging.example.com] [--out ui-check-report]
//
// Needs, in the project (dev only):  npm i -D playwright @axe-core/playwright && npx playwright install --with-deps chromium
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { loadConfig, matrix, themeInitScript, PAGE_PROBE, summarize, toMarkdown } from './lib.mjs';

export async function runChecks(c, { chromium, AxeBuilder, log = () => {} }) {
  const browser = await chromium.launch(c.browserChannel ? { channel: c.browserChannel } : {});   // "chrome" uses the installed Chrome (no download)
  const raws = [];
  try {
    for (const run of matrix(c)) {
      const ctx = await browser.newContext({ viewport: { width: run.width, height: run.height }, colorScheme: run.theme });
      const init = themeInitScript(c.themeStrategy, run.theme);
      if (init) await ctx.addInitScript(init);
      const page = await ctx.newPage();
      const consoleErrors = [], requests = [];
      const origin = new URL(run.url).origin;
      page.on('console', (m) => { if (m.type() === 'error') consoleErrors.push(m.text()); });
      page.on('pageerror', (e) => consoleErrors.push(String(e && e.message || e)));
      page.on('response', (r) => { try { if (r.status() >= 400 && new URL(r.url()).origin === origin) requests.push({ url: r.url(), status: r.status() }); } catch {} });
      const raw = { run, axe: [], probe: null, console: consoleErrors, requests };
      try {
        const resp = await page.goto(run.url, { waitUntil: 'load', timeout: c.timeoutMs });
        if (resp && resp.status() >= 400) throw new Error(`HTTP ${resp.status()}`);
        await page.waitForTimeout(c.waitMs);
        raw.probe = await page.evaluate(PAGE_PROBE);
        if (c.checks.axe) raw.axe = (await new AxeBuilder({ page }).withTags(c.axeTags).analyze()).violations;
        if (c.screenshots) await page.screenshot({ path: path.join(c.screenshots, `${run.page}-${run.width}-${run.theme}.png`), fullPage: true });
      } catch (e) { raw.error = String(e && e.message || e).split('\n')[0]; }
      raws.push(raw);
      log(`${raw.error ? '✘' : '·'} ${run.page} ${run.width}px ${run.theme}`);
      await ctx.close();
    }
  } finally { await browser.close(); }
  return raws;
}

function args(argv) {
  const a = { config: 'ui-check.config.json', out: 'ui-check-report' };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--config') a.config = argv[++i];
    else if (argv[i] === '--base-url') a.baseUrl = argv[++i];
    else if (argv[i] === '--out') a.out = argv[++i];
    else if (argv[i] === '--help' || argv[i] === '-h') a.help = true;
  }
  return a;
}

async function main() {
  const a = args(process.argv.slice(2));
  if (a.help) { console.log(readFileSync(new URL(import.meta.url)).toString().split('\n').slice(1, 8).join('\n')); return 0; }
  let c;
  try { c = loadConfig(JSON.parse(readFileSync(a.config, 'utf8')), { baseUrl: a.baseUrl }); }
  catch (e) { console.error(`ui-check: ${e.code === 'ENOENT' ? `no config at ${a.config} (copy templates/ui-check.config.json)` : e.message}`); return 2; }
  const req = createRequire(path.join(process.cwd(), 'noop.js'));   // the project's node_modules, not ours
  let chromium, AxeBuilder;
  try {
    const pw = await import(pathToFileURL(req.resolve('playwright')).href);            // CommonJS: names may sit on default
    chromium = pw.chromium || (pw.default && pw.default.chromium);
    const ax = await import(pathToFileURL(req.resolve('@axe-core/playwright')).href);
    AxeBuilder = (ax.default && ax.default.default) || ax.AxeBuilder || ax.default;
    if (!chromium || typeof AxeBuilder !== 'function') throw new Error('unexpected module shape');
  }
  catch { console.error('ui-check: install the dev tools first: npm i -D playwright @axe-core/playwright && npx playwright install --with-deps chromium'); return 2; }
  mkdirSync(a.out, { recursive: true });
  if (c.screenshots === true) c.screenshots = path.join(a.out, 'screenshots');
  if (c.screenshots) mkdirSync(c.screenshots, { recursive: true });
  let raws;
  try { raws = await runChecks(c, { chromium, AxeBuilder, log: (m) => console.log(m) }); }
  catch (e) { console.error(`ui-check: browser failed: ${String(e && e.message || e).split('\n')[0]}${c.browserChannel ? '' : ' (no browser? run: npx playwright install --with-deps chromium, or set "browserChannel": "chrome")'}`); return 2; }
  const s = summarize(raws, c);
  writeFileSync(path.join(a.out, 'report.json'), JSON.stringify(s, null, 2));
  writeFileSync(path.join(a.out, 'report.md'), toMarkdown(s, c));
  console.log('\n' + toMarkdown(s, c));
  return s.ok ? 0 : 1;
}

if (import.meta.url === pathToFileURL(process.argv[1] || '').href) main().then((code) => process.exit(code));
