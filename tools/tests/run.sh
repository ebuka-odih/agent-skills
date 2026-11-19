#!/usr/bin/env bash
# Tests for the repo's own release tool (tools/release.sh) on a throwaway marketplace.
# Usage: bash tools/tests/run.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
R="$HERE/release.sh"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ✔ %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  ✘ %s\n    %s\n' "$1" "$2"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
g() { git -C "$T" -c user.name=t -c user.email=t@t.invalid -c tag.gpgSign=false "$@"; }
rel() { bash "$R" "$@" --root "$T"; }
mkplugin() { mkdir -p "$T/plugins/$1/.claude-plugin" "$T/plugins/$1/skills/x"; printf '{\n  "name": "%s",\n  "version": "%s"\n}\n' "$1" "$2" > "$T/plugins/$1/.claude-plugin/plugin.json"; echo "# $1" > "$T/plugins/$1/skills/x/SKILL.md"; }

git init -q "$T"; mkdir -p "$T/.claude-plugin"
mkplugin alpha 0.1.0; mkplugin beta 0.2.0
cat > "$T/.claude-plugin/marketplace.json" <<'EOF'
{
  "name": "m",
  "metadata": {
    "version": "1.0.0"
  },
  "plugins": [
    { "name": "alpha", "source": "./plugins/alpha", "version": "0.1.0" },
    { "name": "beta", "source": "./plugins/beta", "version": "0.2.0" }
  ]
}
EOF
printf '# Changelog\n\n## 1.0.0 — 2026-11-01\n- first\n' > "$T/CHANGELOG.md"
g add -A; g commit -qm "feat: first"; g tag -a v1.0.0 -m x; g tag -a alpha-v0.1.0 -m x; g tag -a beta-v0.2.0 -m x

echo "status / check on a clean release"
check "check passes"                       'rel check | grep -q "✔ versions consistent: marketplace 1.0.0 (last tag v1.0.0)"'
check "status: nothing to do"              'grep -q "^alpha .* -$" <<<"$(rel status)"'

echo "a change without a bump"
echo more >> "$T/plugins/alpha/skills/x/SKILL.md"; g commit -qam "feat(alpha): new step"
echo fix >> "$T/plugins/beta/skills/x/SKILL.md"
check "check fails: alpha changed, not bumped" 'grep -q "alpha changed since alpha-v0.1.0 but is still 0.1.0" <<<"$(rel check)"'
check "check exit 1"                       'rel check >/dev/null; [ $? = 1 ]'
check "uncommitted beta counts as changed" 'grep -q "beta changed since" <<<"$(rel check)"'
check "status suggests minor for feat, patch for uncommitted" 'st=$(rel status); grep -q "^alpha .*bump minor" <<<"$st" && grep -q "^beta .*bump patch" <<<"$st"'

echo "apply"
out=$(rel apply)
check "alpha → 0.2.0 (feat)"               'grep -q "bumped alpha → 0.2.0" <<<"$out" && [ "$(jq -r .version "$T/plugins/alpha/.claude-plugin/plugin.json")" = 0.2.0 ]'
check "beta → 0.2.1 (uncommitted = patch)" '[ "$(jq -r .version "$T/plugins/beta/.claude-plugin/plugin.json")" = 0.2.1 ]'
check "marketplace entries follow"         '[ "$(jq -r ".plugins[]|select(.name==\"alpha\")|.version" "$T/.claude-plugin/marketplace.json")" = 0.2.0 ] && [ "$(jq -r ".plugins[]|select(.name==\"beta\")|.version" "$T/.claude-plugin/marketplace.json")" = 0.2.1 ]'
check "marketplace minor bump (a plugin went minor)" '[ "$(jq -r .metadata.version "$T/.claude-plugin/marketplace.json")" = 1.1.0 ]'
check "CHANGELOG section on top with commit subjects" '[ "$(grep -m1 "^## " "$T/CHANGELOG.md")" = "## 1.1.0 — $(date +%Y-%m-%d)" ] && grep -q "^- \`alpha\` 0.2.0: new step$" "$T/CHANGELOG.md"'
check "uncommitted plugin gets a FILL IN line" 'grep -q "^- \`beta\` 0.2.1: FILL IN" "$T/CHANGELOG.md"'
check "apply says to fill in"              'grep -q "replace the FILL IN lines" <<<"$out"'
check "check fails while FILL IN remains"  'grep -q "1.1.0 still has FILL IN lines" <<<"$(rel check)"'
sed -i.bak 's/FILL IN: what changed and why/fixed a typo/' "$T/CHANGELOG.md"; rm -f "$T/CHANGELOG.md.bak"
check "check passes after filling in"      'rel check | grep -q "✔ versions consistent: marketplace 1.1.0"'
check "apply again changes nothing"        'grep -q "nothing changed since the last tags" <<<"$(rel apply)" && [ "$(jq -r .metadata.version "$T/.claude-plugin/marketplace.json")" = 1.1.0 ]'

echo "tag"
check "tag refuses a dirty tree"           'rel tag >/dev/null 2>&1; [ $? = 1 ]'
g add -A; g commit -qm "chore(release): v1.1.0"
check "tag creates repo + bumped plugin tags only" 'grep -q "tagged: v1.1.0 alpha-v0.2.0 beta-v0.2.1" <<<"$(rel tag)"'
check "tag again → nothing to tag"         'grep -q "nothing to tag" <<<"$(rel tag)"'
check "status clean after tagging"         '! rel status | grep -q "bump"'
check "apply on a fully tagged repo changes nothing" 'rel apply >/dev/null && [ "$(jq -r .metadata.version "$T/.claude-plugin/marketplace.json")" = 1.1.0 ] && [ -z "$(git -C "$T" status --porcelain)" ]'

echo "drift the check catches"
jq '(.plugins[]|select(.name=="beta")|.version) = "0.9.9"' "$T/.claude-plugin/marketplace.json" > "$T/m.json" && mv "$T/m.json" "$T/.claude-plugin/marketplace.json"
check "plugin.json ≠ marketplace"          'grep -q "beta: plugin.json 0.2.1 ≠ marketplace 0.9.9" <<<"$(rel check)"'
g checkout -q .claude-plugin/marketplace.json
mkplugin gamma 0.1.0
check "plugin folder not in the marketplace" 'grep -q "plugins/gamma is not in" <<<"$(rel check)"'
rm -rf "$T/plugins/gamma"
jq '(.plugins[]|select(.name=="alpha")|.version) = "0.3.0"' "$T/.claude-plugin/marketplace.json" > "$T/m.json" && mv "$T/m.json" "$T/.claude-plugin/marketplace.json"
jq '.version = "0.3.0"' "$T/plugins/alpha/.claude-plugin/plugin.json" > "$T/p.json" && mv "$T/p.json" "$T/plugins/alpha/.claude-plugin/plugin.json"
check "plugin bumped, marketplace not"     'grep -q "alpha has a new version but the marketplace is still 1.1.0" <<<"$(rel check)"'
check "override levels: alpha=major repo=major" 'g checkout -q . && echo z >> "$T/plugins/alpha/skills/x/SKILL.md" && rel apply alpha=major repo=major >/dev/null && [ "$(jq -r .version "$T/plugins/alpha/.claude-plugin/plugin.json")" = 1.0.0 ] && [ "$(jq -r .metadata.version "$T/.claude-plugin/marketplace.json")" = 2.0.0 ]'
echo "push and patch-only"
B="$(mktemp -d)"; git init -q --bare "$B"; g checkout -q . ; g remote add origin "$B"
check "back at marketplace 1.1.0, beta 0.2.1" '[ "$(jq -r .metadata.version "$T/.claude-plugin/marketplace.json")" = 1.1.0 ] && [ "$(jq -r .version "$T/plugins/beta/.claude-plugin/plugin.json")" = 0.2.1 ]'
echo f >> "$T/plugins/beta/skills/x/SKILL.md"; g commit -qam "fix(beta): typo"
check "fix-only commits → patch"           'grep -q "^beta .*bump patch" <<<"$(rel status)"'
rel apply >/dev/null; sed -i.bak "s/FILL IN: what changed and why/x/" "$T/CHANGELOG.md"; rm -f "$T/CHANGELOG.md.bak"
check "beta 0.2.1 → 0.2.2, marketplace patch" '[ "$(jq -r .version "$T/plugins/beta/.claude-plugin/plugin.json")" = 0.2.2 ] && [ "$(jq -r .metadata.version "$T/.claude-plugin/marketplace.json")" = 1.1.1 ]'
echo g >> "$T/plugins/beta/skills/x/SKILL.md"
rel apply beta=patch >/dev/null
check "already-bumped marketplace is not bumped twice" '[ "$(jq -r .metadata.version "$T/.claude-plugin/marketplace.json")" = 1.1.1 ]'
check "no second CHANGELOG section"        '[ "$(grep -c "^## 1.1.1 " "$T/CHANGELOG.md")" = 1 ]'
g add -A; g commit -qm "chore(release): v1.1.1"
check "tag without --push leaves the remote alone" 'rel tag >/dev/null && [ -z "$(git -C "$B" tag -l)" ]'
g tag -d v1.1.1 beta-v0.2.2 >/dev/null
check "tag --push pushes branch and new tags" 'rel tag --push >/dev/null 2>&1 && git -C "$B" tag -l | grep -qx v1.1.1 && git -C "$B" tag -l | grep -qx beta-v0.2.2 && [ -n "$(git -C "$B" branch --list)" ]'
rm -rf "$B"
check "unknown argument → 2"               'rel nope-arg >/dev/null 2>&1; [ $? = 2 ]'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
