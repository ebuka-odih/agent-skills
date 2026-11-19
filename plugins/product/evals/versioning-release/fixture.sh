#!/usr/bin/env bash
# A small CLI at v0.3.0 (tagged) with one feat and one fix merged since. No remote: nothing to push.
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@example.invalid -c tag.gpgSign=false "$@"; }
git init -q
mkdir -p bin test
cat > package.json <<'J'
{
  "name": "tallyho",
  "version": "0.3.0",
  "bin": { "tallyho": "bin/cli.js" },
  "scripts": { "test": "node --test" }
}
J
cat > bin/cli.js <<'J'
#!/usr/bin/env node
const { version } = require("../package.json");
const args = process.argv.slice(2);
if (args[0] === "--version") { console.log(`tallyho ${version}`); process.exit(0); }
const nums = args.map(Number).filter((n) => !Number.isNaN(n));
console.log(nums.reduce((a, b) => a + b, 0));
J
cat > test/cli.test.js <<'J'
const { test } = require("node:test");
const assert = require("node:assert");
const { execFileSync } = require("node:child_process");
test("sums numbers", () => assert.equal(execFileSync("node", ["bin/cli.js", "2", "3"]).toString().trim(), "5"));
J
cat > CHANGELOG.md <<'J'
# Changelog

## 0.3.0 — 2026-11-01
- Sum numbers from the command line.
J
g add -A && g commit -qm "feat: sum numbers" && g tag -a v0.3.0 -m v0.3.0
sed -i.bak 's/filter((n) => !Number.isNaN(n))/filter((n) => Number.isFinite(n))/' bin/cli.js && rm bin/cli.js.bak
g commit -qam "fix: ignore Infinity in the input"
cat >> bin/cli.js <<'J'
if (args.includes("--avg")) console.log(nums.length ? nums.reduce((a, b) => a + b, 0) / nums.length : 0);
J
g commit -qam "feat(cli): --avg prints the average"
