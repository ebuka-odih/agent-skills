#!/usr/bin/env bash
# One version number per project, derived from commits, kept in every file that carries it, tagged on release.
#
#   version.sh status                 one line: version, last tag, unreleased commits, next version
#   version.sh current                the version in the primary version file
#   version.sh files                  the version files found (first = primary)
#   version.sh last-tag               the newest release tag (<prefix>vX.Y.Z), empty if none
#   version.sh next [level]           the next version; level = auto (default) | major | minor | patch
#   version.sh bump [level|X.Y.Z]     write the next version to every version file + a CHANGELOG section
#   version.sh tag                    annotated tag <prefix>v<current> (clean tree, newer than the last tag)
#   version.sh check                  version files agree, not behind the last tag, CHANGELOG has the section
#   version.sh verify --cmd "<cmd>" | --url <url> | --app <X.app>
#                                     the build the user actually runs reports the current version
# Options (any command):
#   --file <path>   a version file (repeatable; overrides detection). Env: VERSION_FILES="a b"
#   --path <dir>    only commits touching this path count (monorepos)
#   --prefix <p>    tag prefix, e.g. "api-" → api-v1.2.0
#   --changelog <f> changelog file (default CHANGELOG.md); bump --no-changelog leaves it alone
# Levels from Conventional Commits since the last tag: "type!:" or "BREAKING CHANGE" → major (minor while 0.x),
# feat → minor, anything else → patch. Exit codes: 0 ok · 1 check/verify failed · 2 usage · 3 nothing to release.
set -u

cmd="${1:-status}"; shift || true
files=(); path="."; prefix=""; changelog="CHANGELOG.md"; level=""; vcmd=""; vurl=""; vapp=""; nochangelog=0
while [ $# -gt 0 ]; do
  case "$1" in
    --file) files+=("$2"); shift ;;
    --path) path="$2"; shift ;;
    --prefix) prefix="$2"; shift ;;
    --changelog) changelog="$2"; shift ;;
    --no-changelog) nochangelog=1 ;;
    --cmd) vcmd="$2"; shift ;;
    --url) vurl="$2"; shift ;;
    --app) vapp="$2"; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) level="$1" ;;
  esac
  shift
done
if [ ${#files[@]} -eq 0 ] && [ -n "${VERSION_FILES:-}" ]; then
  for f in $VERSION_FILES; do files+=("$f"); done
fi

die() { echo "version.sh: $1" >&2; exit "${2:-2}"; }
in_git() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }

# ---- version files ---------------------------------------------------------------------------
detect_files() {
  local f
  for f in VERSION package.json pyproject.toml Cargo.toml composer.json .claude-plugin/plugin.json; do
    [ -f "$f" ] || continue
    [ -n "$(read_version "$f")" ] && echo "$f"
  done
  # Apple apps: the app's Info.plist (not build output, tests or dependencies)
  { in_git && git ls-files '*Info.plist' 2>/dev/null || find . -maxdepth 3 -name Info.plist 2>/dev/null; } \
    | sed 's|^\./||' | grep -vE '(^|/)(build|\.build|DerivedData|Pods|node_modules|Tests?|[^/]*Tests)/' \
    | awk -F/ 'NF<=3' | head -1 | while read -r f; do [ -n "$(read_version "$f")" ] && echo "$f"; done
}
version_files() { if [ ${#files[@]} -gt 0 ]; then printf '%s\n' "${files[@]}"; else detect_files; fi; }

read_version() { # file → version or empty
  local f="$1"; [ -f "$f" ] || return 0
  case "$f" in
    *VERSION) tr -d ' \t\r\n' < "$f" ;;
    *.json) awk 'match($0, /"version"[[:space:]]*:[[:space:]]*"[^"]*"/) { s = substr($0, RSTART, RLENGTH); sub(/.*:[[:space:]]*"/, "", s); sub(/"$/, "", s); print s; exit }' "$f" ;;
    *.toml) awk '/^\[/{sec=$0} (sec=="[project]" || sec=="[tool.poetry]" || sec=="[package]") && /^version[[:space:]]*=/ { s=$0; sub(/^[^"]*"/, "", s); sub(/".*/, "", s); print s; exit }' "$f" ;;
    *.plist) awk '/<key>CFBundleShortVersionString<\/key>/{k=1; next} k && /<string>/{ s=$0; sub(/.*<string>/, "", s); sub(/<\/string>.*/, "", s); print s; exit }' "$f" ;;
  esac
}

write_version() { # file version
  local f="$1" v="$2" tmp; tmp="$(mktemp "${f}.XXXX")" || die "cannot write $f"
  case "$f" in
    *VERSION) printf '%s\n' "$v" > "$tmp" ;;
    *.json) awk -v v="$v" '!done && /"version"[[:space:]]*:[[:space:]]*"[^"]*"/ { sub(/"version"[[:space:]]*:[[:space:]]*"[^"]*"/, "\"version\": \"" v "\""); done=1 } {print}' "$f" > "$tmp" ;;
    *.toml) awk -v v="$v" '/^\[/{sec=$0} !done && (sec=="[project]" || sec=="[tool.poetry]" || sec=="[package]") && /^version[[:space:]]*=/ { sub(/"[^"]*"/, "\"" v "\""); done=1 } {print}' "$f" > "$tmp" ;;
    *.plist) # CFBundleShortVersionString = version; CFBundleVersion: integer → +1, otherwise = version
      awk -v v="$v" '
        /<key>CFBundleShortVersionString<\/key>/ { print; k="short"; next }
        /<key>CFBundleVersion<\/key>/ { print; k="build"; next }
        k != "" && /<string>/ {
          s=$0; old=s; sub(/.*<string>/, "", old); sub(/<\/string>.*/, "", old)
          nv = (k=="build" && old ~ /^[0-9]+$/) ? old+1 : v
          sub(/<string>[^<]*<\/string>/, "<string>" nv "</string>", s); print s; k=""; next }
        { print }' "$f" > "$tmp" ;;
    *) rm -f "$tmp"; die "don't know how to write a version into $f" ;;
  esac
  cat "$tmp" > "$f"; rm -f "$tmp"   # keep the file's mode and inode
}

# ---- semver ----------------------------------------------------------------------------------
core() { echo "${1%%[-+]*}"; }
valid() { [[ "$(core "$1")" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; }
cmp() { # a b → prints -1 / 0 / 1 (prerelease ignored)
  awk -v a="$(core "$1")" -v b="$(core "$2")" 'BEGIN { split(a, x, "."); split(b, y, ".");
    for (i = 1; i <= 3; i++) { if (x[i]+0 > y[i]+0) { print 1; exit } if (x[i]+0 < y[i]+0) { print -1; exit } } print 0 }'
}
inc() { # version level
  local IFS=.; set -- $(core "$1") "$2"
  case "$4" in major) echo "$(($1+1)).0.0" ;; minor) echo "$1.$(($2+1)).0" ;; *) echo "$1.$2.$(($3+1))" ;; esac
}

# ---- tags and commits ------------------------------------------------------------------------
last_tag() {
  in_git || return 0
  git tag -l "${prefix}v[0-9]*" 2>/dev/null | while read -r t; do
    v="${t#"${prefix}"v}"; valid "$v" && printf '%s\t%s\n' "$(core "$v")" "$t"
  done | sort -t. -k1,1n -k2,2n -k3,3n | tail -1 | cut -f2
}
commits() { # subject<US>body<RS> for commits since the last tag that touch $path (release commits skipped)
  in_git || return 0
  local t range; t="$(last_tag)"; range="HEAD"; [ -n "$t" ] && range="$t..HEAD"
  git log --no-merges --format='%s%x1f%b%x1e' "$range" -- "$path" 2>/dev/null
}
summary() { # → "n feat breaking other"
  commits | awk -v RS=$'\x1e' -v FS=$'\x1f' '{
      sub(/^\n+/, "", $1); if ($1 == "") next
      if ($1 ~ /^chore\(release\)/) next
      n++
      if ($1 ~ /^[a-z]+(\([^)]*\))?!:/ || $2 ~ /BREAKING[ -]CHANGE/) b++
      else if ($1 ~ /^feat(\([^)]*\))?:/) f++
      else o++ }
    END { printf "%d %d %d %d\n", n, f, b, o }'
}
auto_level() { # → major|minor|patch|none
  local n f b o cur; read -r n f b o <<<"$(summary)"
  [ "$n" -eq 0 ] && { echo none; return; }
  cur="$(current)"
  if [ "$b" -gt 0 ]; then [ "${cur%%.*}" = 0 ] && echo minor || echo major
  elif [ "$f" -gt 0 ]; then echo minor
  else echo patch; fi
}

current() { local f; f="$(version_files | head -1)"; [ -n "$f" ] && read_version "$f"; }
next_version() {
  local cur lvl; cur="$(current)"; [ -n "$cur" ] || die "no version file found (pass --file)"
  lvl="${level:-auto}"
  if valid "$lvl"; then echo "$lvl"; return; fi
  [ "$lvl" = auto ] && lvl="$(auto_level)"
  case "$lvl" in none) return 3 ;; major|minor|patch) ;; *) die "unknown level: $lvl" ;; esac
  # Already bumped since the last tag (release prepared, not yet tagged) → keep it.
  local t; t="$(last_tag)"
  if [ -n "$t" ] && [ "$(cmp "$cur" "${t#"${prefix}"v}")" = 1 ] && [ "${level:-auto}" = auto ]; then echo "$cur"; return; fi
  inc "$cur" "$lvl"
}

changelog_section() { # version → markdown section from commits
  local v="$1"
  printf '## %s — %s\n' "$v" "$(date +%Y-%m-%d)"
  commits | awk -v RS=$'\x1e' -v FS=$'\x1f' '{
      sub(/^\n+/, "", $1); s=$1; if (s == "" || s ~ /^chore\(release\)/) next
      k="Other"
      if (s ~ /^[a-z]+(\([^)]*\))?!:/ || $2 ~ /BREAKING[ -]CHANGE/) k="Breaking"
      else if (s ~ /^feat(\([^)]*\))?:/) k="Features"
      else if (s ~ /^fix(\([^)]*\))?:/) k="Fixes"
      scope=""; if (match(s, /^[a-z]+\([^)]*\)/)) { scope=substr(s, RSTART, RLENGTH); sub(/^[a-z]+\(/, "", scope); sub(/\)$/, "", scope) }
      sub(/^[a-z]+(\([^)]*\))?!?:[[:space:]]*/, "", s)
      line = "- " s (scope != "" ? " (" scope ")" : "")
      out[k] = out[k] line "\n" }
    END { split("Breaking Features Fixes Other", order, " ")
      for (i = 1; i <= 4; i++) if (out[order[i]] != "") printf "\n### %s\n%s", order[i], out[order[i]] }'
  echo
}
has_section() { [ -f "$changelog" ] && grep -qE "^## \[?v?$(core "$1" | sed 's/\./\\./g')\]?([^0-9.]|$)" "$changelog"; }

# ---- commands --------------------------------------------------------------------------------
case "$cmd" in
  files) version_files ;;
  current) v="$(current)"; [ -n "$v" ] || die "no version file found (pass --file)" 1; echo "$v" ;;
  last-tag) last_tag ;;
  next) next_version ;;
  status)
    f="$(version_files | head -1)"
    [ -n "$f" ] || { echo "version: no version file (VERSION, package.json, pyproject.toml, Cargo.toml, composer.json, Info.plist)"; exit 0; }
    cur="$(read_version "$f")"; t="$(last_tag)"; read -r n fe b o <<<"$(summary)"
    line="version $cur ($f) · last tag ${t:-none}"
    if [ "$n" -gt 0 ]; then
      nx="$(next_version)"
      line="$line · $n unreleased commit(s) ($fe feat, $b breaking, $o other) → next $nx"
    else line="$line · nothing unreleased"; fi
    [ -n "$t" ] && [ "$(cmp "$cur" "${t#"${prefix}"v}")" = 1 ] && line="$line · $cur is bumped but not tagged yet"
    echo "$line" ;;
  bump)
    list="$(version_files)"; [ -n "$list" ] || die "no version file found (pass --file)"
    nv="$(next_version)"; rc=$?
    [ $rc -eq 3 ] && { echo "nothing to release: no commits since $(last_tag)"; exit 3; }
    [ $rc -eq 0 ] || exit $rc
    while read -r f; do write_version "$f" "$nv"; done <<<"$list"
    if [ "$nochangelog" = 0 ] && ! has_section "$nv"; then
      sec="$(changelog_section "$nv")"
      if [ -f "$changelog" ]; then   # new section goes above the newest one (or at the end)
        at="$(grep -n '^## ' "$changelog" | head -1 | cut -d: -f1)"
        { if [ -n "$at" ]; then head -n $((at - 1)) "$changelog"; printf '%s\n\n' "$sec"; tail -n +"$at" "$changelog"
          else cat "$changelog"; printf '\n%s\n' "$sec"; fi; } > "$changelog.tmp" && cat "$changelog.tmp" > "$changelog"
        rm -f "$changelog.tmp"
      else printf '# Changelog\n\n%s\n' "$sec" > "$changelog"; fi
    fi
    echo "$nv" ;;
  tag)
    in_git || die "not a git repository" 1
    [ -z "$(git status --porcelain 2>/dev/null)" ] || die "commit first: the tag must match a commit (working tree has changes)" 1
    cur="$(current)"; [ -n "$cur" ] || die "no version file found" 1
    t="$(last_tag)"; nt="${prefix}v$cur"
    git rev-parse -q --verify "refs/tags/$nt" >/dev/null && die "$nt already exists — run: version.sh bump" 1
    [ -n "$t" ] && [ "$(cmp "$cur" "${t#"${prefix}"v}")" != 1 ] && die "$cur is not newer than $t — run: version.sh bump" 1
    [ -f "$changelog" ] && ! has_section "$cur" && die "$changelog has no section for $cur" 1
    git tag -a "$nt" -m "${prefix}$cur" && echo "$nt" ;;
  check)
    list="$(version_files)"; [ -n "$list" ] || die "no version file found" 1
    bad=0; cur=""
    while read -r f; do
      v="$(read_version "$f")"
      valid "$v" || { echo "✘ $f: '$v' is not X.Y.Z"; bad=1; continue; }
      if [ -z "$cur" ]; then cur="$v"; elif [ "$v" != "$cur" ]; then echo "✘ $f says $v, primary says $cur"; bad=1; fi
    done <<<"$list"
    t="$(last_tag)"
    if [ -n "$t" ] && [ -n "$cur" ] && [ "$(cmp "$cur" "${t#"${prefix}"v}")" = -1 ]; then echo "✘ version $cur is behind the last tag $t"; bad=1; fi
    if [ -f "$changelog" ] && [ -n "$cur" ] && ! has_section "$cur"; then echo "✘ $changelog has no section for $cur"; bad=1; fi
    [ "$bad" = 0 ] && echo "✔ version $cur consistent (${t:-no tag yet})"
    exit "$bad" ;;
  verify)
    cur="$(current)"; [ -n "$cur" ] || die "no version file found" 1
    if [ -n "$vapp" ]; then got="$(read_version "$vapp/Contents/Info.plist")"; where="$vapp"
    elif [ -n "$vurl" ]; then got="$(curl -fsSL --max-time 15 "$vurl" 2>/dev/null | head -c 20000)"; where="$vurl"
    elif [ -n "$vcmd" ]; then got="$(bash -c "$vcmd" 2>&1 | head -c 20000)"; where="$vcmd"
    else die "verify needs --cmd, --url or --app"; fi
    if printf '%s' "$got" | grep -qF "$cur"; then echo "✔ $where reports $cur"; exit 0; fi
    seen="$(printf '%s' "$got" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    echo "✘ $where reports ${seen:-no version}, expected $cur — the user is not running this release yet (install / deploy it, then verify again)"
    exit 1 ;;
  *) sed -n '2,20p' "$0"; exit 2 ;;
esac
