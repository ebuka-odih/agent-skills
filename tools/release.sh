#!/usr/bin/env bash
# Versioning for this skills library: every plugin has its own version and tag, the marketplace has one too.
#
#   tools/release.sh status                       per plugin: version, last tag, changed since the tag, what to bump
#   tools/release.sh apply [plugin=level …] [repo=level]
#                                                 bump every changed plugin (plugin.json + marketplace entry), the
#                                                 marketplace version, and add a CHANGELOG section to fill in
#   tools/release.sh check                        versions agree, nothing changed without a bump, CHANGELOG filled in
#   tools/release.sh tag [--push]                 tag v<marketplace> and <plugin>-v<version> for new versions; push
#
# Levels: auto (from Conventional Commits since the plugin's tag; uncommitted work counts as patch) | major | minor | patch.
# Tags: v1.11.0 for the marketplace, product-v0.3.0 per plugin. Run from anywhere; --root <dir> for another checkout.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VS="$HERE/../plugins/product/scripts/version.sh"
ROOT="$(cd "$HERE/.." && pwd)"
cmd="${1:-status}"; shift || true
overrides=(); push=0
while [ $# -gt 0 ]; do
  case "$1" in --root) ROOT="$(cd "$2" && pwd)"; shift ;; --push) push=1 ;; *=*) overrides+=("$1") ;; *) echo "unknown argument: $1" >&2; exit 2 ;; esac
  shift
done
cd "$ROOT" || exit 2
MP=.claude-plugin/marketplace.json
[ -f "$MP" ] || { echo "no $MP in $ROOT" >&2; exit 2; }

plugins() { jq -r '.plugins[].name' "$MP"; }
pv() { jq -r .version "plugins/$1/.claude-plugin/plugin.json"; }
mv_() { jq -r --arg n "$1" '.plugins[] | select(.name==$n) | .version' "$MP"; }
repo_v() { jq -r .metadata.version "$MP"; }
tag_v() { local t; t="$(bash "$VS" last-tag --prefix "$1" 2>/dev/null)"; echo "${t#"$1"v}"; }   # prefix → version of last tag
gt() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$1" ] && [ "$1" != "$2" ]; }
committed_since() { # plugin → number of commits touching it since its tag (all commits if untagged)
  local t; t="$(bash "$VS" last-tag --prefix "$1-")"
  if [ -n "$t" ]; then git rev-list --count "$t..HEAD" -- "plugins/$1" 2>/dev/null; else git rev-list --count HEAD -- "plugins/$1" 2>/dev/null; fi
}
dirty() { [ -n "$(git status --porcelain -- "plugins/$1" 2>/dev/null)" ]; }
override() { local o; for o in "${overrides[@]+"${overrides[@]}"}"; do [ "${o%%=*}" = "$1" ] && { echo "${o#*=}"; return; }; done; }
level_for() { # plugin → major|minor|patch from its commits; uncommitted work alone → patch (override with plugin=level)
  local o cur nxt a b c x y z; o="$(override "$1")"; [ -n "$o" ] && { echo "$o"; return; }
  [ "$(committed_since "$1")" -gt 0 ] || { echo patch; return; }
  cur="$(pv "$1")"
  nxt="$(bash "$VS" next --path "plugins/$1" --prefix "$1-" --file "plugins/$1/.claude-plugin/plugin.json" 2>/dev/null)" || { echo patch; return; }
  IFS=. read -r a b c <<<"$cur"; IFS=. read -r x y z <<<"$nxt"
  if [ "$x" != "$a" ]; then echo major; elif [ "$y" != "$b" ]; then echo minor; else echo patch; fi
}
needs_bump() { # plugin → 0 when it changed since its tag but its version is not past the tag
  local t; t="$(tag_v "$1-")"
  [ -n "$t" ] || return 1                          # never released: its current version is the first release
  gt "$(pv "$1")" "$t" && return 1                  # already bumped
  [ "$(committed_since "$1")" -gt 0 ] || dirty "$1"
}

case "$cmd" in
  status)
    printf '%-16s %-9s %-10s %-22s %s\n' plugin version "last tag" changed action
    for p in $(plugins); do
      v="$(pv "$p")"; t="$(tag_v "$p-")"; n="$(committed_since "$p")"; ch="${n:-0} commit(s)"; dirty "$p" && ch="$ch + uncommitted"
      if needs_bump "$p"; then a="bump $(level_for "$p")"; elif [ -n "$t" ] && gt "$v" "$t"; then a="tag $p-v$v"; elif [ -z "$t" ]; then a="tag $p-v$v (first)"; else a="-"; fi
      printf '%-16s %-9s %-10s %-22s %s\n' "$p" "$v" "${t:-none}" "$ch" "$a"
    done
    rv="$(repo_v)"; rt="$(tag_v "")"; echo; echo "marketplace $rv · last tag ${rt:+v}${rt:-none}" ;;

  apply)
    bumped=(); top=patch
    for p in $(plugins); do
      needs_bump "$p" || continue
      lvl="$(level_for "$p")"
      nv="$(bash "$VS" bump "$lvl" --file "plugins/$p/.claude-plugin/plugin.json" --prefix "$p-" --no-changelog)" || exit 1
      bumped+=("$p $nv")
      case "$lvl" in major|minor) top=minor ;; esac
    done
    # marketplace entries follow plugin.json
    for p in $(plugins); do
      v="$(pv "$p")"; [ "$(mv_ "$p")" = "$v" ] && continue
      jq --indent 2 --arg n "$p" --arg v "$v" '(.plugins[] | select(.name==$n) | .version) = $v' "$MP" > "$MP.tmp" && mv "$MP.tmp" "$MP"
    done
    rv="$(repo_v)"; rt="$(tag_v "")"
    if [ ${#bumped[@]} -gt 0 ] && { [ -z "$rt" ] || ! gt "$rv" "$rt"; }; then
      lvl="$(override repo)"; lvl="${lvl:-$top}"
      IFS=. read -r a b c <<<"$rv"
      case "$lvl" in major) rv="$((a+1)).0.0" ;; minor) rv="$a.$((b+1)).0" ;; *) rv="$a.$b.$((c+1))" ;; esac
      jq --indent 2 --arg v "$rv" '.metadata.version = $v' "$MP" > "$MP.tmp" && mv "$MP.tmp" "$MP"
    fi
    if [ ${#bumped[@]} -gt 0 ] && ! grep -q "^## $rv " CHANGELOG.md 2>/dev/null; then
      {
        printf '## %s — %s\n' "$rv" "$(date +%Y-%m-%d)"
        for b in "${bumped[@]}"; do
          p="${b% *}"; v="${b#* }"; t="$(bash "$VS" last-tag --prefix "$p-")"
          subj="$(git log --no-merges --format='%s' ${t:+"$t..HEAD"} -- "plugins/$p" 2>/dev/null | grep -v '^chore(release)' | sed 's/^[a-z]*([^)]*)!*: //; s/^[a-z]*!*: //' | paste -sd ';' - | sed 's/;/; /g')"
          printf -- '- `%s` %s: %s\n' "$p" "$v" "${subj:-FILL IN: what changed and why}"
        done
      } > CHANGELOG.section
      at="$(grep -n '^## ' CHANGELOG.md | head -1 | cut -d: -f1)"
      { head -n $((at - 1)) CHANGELOG.md; cat CHANGELOG.section; echo; tail -n +"$at" CHANGELOG.md; } > CHANGELOG.tmp && mv CHANGELOG.tmp CHANGELOG.md
      rm -f CHANGELOG.section
    fi
    for b in "${bumped[@]+"${bumped[@]}"}"; do echo "bumped ${b% *} → ${b#* }"; done
    [ ${#bumped[@]} -eq 0 ] && echo "nothing changed since the last tags"
    echo "marketplace $(repo_v)"
    grep -q "FILL IN:" CHANGELOG.md 2>/dev/null && echo "CHANGELOG.md: replace the FILL IN lines with what changed and why"
    exit 0 ;;

  check)
    bad=0
    for p in $(plugins); do
      [ -f "plugins/$p/.claude-plugin/plugin.json" ] || { echo "✘ $p: listed in $MP but plugins/$p has no plugin.json"; bad=1; continue; }
      v="$(pv "$p")"; m="$(mv_ "$p")"
      [ "$v" = "$m" ] || { echo "✘ $p: plugin.json $v ≠ marketplace $m"; bad=1; }
      needs_bump "$p" && { echo "✘ $p changed since $p-v$(tag_v "$p-") but is still $v — run: tools/release.sh apply"; bad=1; }
    done
    for d in plugins/*/; do d="$(basename "$d")"; plugins | grep -qx "$d" || { echo "✘ plugins/$d is not in $MP"; bad=1; }; done
    rv="$(repo_v)"; rt="$(tag_v "")"
    if [ -n "$rt" ]; then
      for p in $(plugins); do t="$(tag_v "$p-")"; if [ -n "$t" ] && gt "$(pv "$p")" "$t" && ! gt "$rv" "$rt"; then echo "✘ $p has a new version but the marketplace is still $rv (tag v$rt)"; bad=1; break; fi; done
    fi
    if ! grep -q "^## $rv " CHANGELOG.md 2>/dev/null; then echo "✘ CHANGELOG.md has no section for $rv"; bad=1
    elif awk -v h="## $rv " 'index($0, h) == 1 {on=1; next} /^## /{on=0} on && /FILL IN:/ {f=1} END {exit !f}' CHANGELOG.md; then echo "✘ CHANGELOG.md $rv still has FILL IN lines"; bad=1; fi
    [ "$bad" = 0 ] && echo "✔ versions consistent: marketplace $rv${rt:+ (last tag v$rt)}"
    exit "$bad" ;;

  tag)
    [ -z "$(git status --porcelain)" ] || { echo "commit first: tags must match a commit" >&2; exit 1; }
    "$0" check --root "$ROOT" >/dev/null || { "$0" check --root "$ROOT"; exit 1; }
    made=()
    rv="$(repo_v)"; git rev-parse -q --verify "refs/tags/v$rv" >/dev/null || { git tag -a "v$rv" -m "ebuka-skills $rv" && made+=("v$rv"); }
    for p in $(plugins); do
      v="$(pv "$p")"; git rev-parse -q --verify "refs/tags/$p-v$v" >/dev/null || { git tag -a "$p-v$v" -m "$p $v" && made+=("$p-v$v"); }
    done
    if [ ${#made[@]} -eq 0 ]; then echo "nothing to tag"; else echo "tagged: ${made[*]}"; fi
    if [ "$push" = 1 ]; then
      git push origin HEAD && { [ ${#made[@]} -eq 0 ] || git push origin "${made[@]}"; }
    fi ;;
  *) sed -n '2,12p' "$0"; exit 2 ;;
esac
