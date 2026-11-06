#!/usr/bin/env bash
# Shared patterns for UI token checks. Sourced by ui-hook.sh and ui-scan.sh.
# Reads "lineno<TAB>text" on stdin for one file path; prints "path:line: kind: text".

PALETTE='slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose'
UTIL='bg|text|border|ring|fill|stroke|from|to|via|outline|divide|decoration|placeholder|caret|accent|shadow|border-[trblxy]'
export UI_RAW_RE="(^|[^A-Za-z0-9_-])(${UTIL})-((${PALETTE})-(50|[1-9]00|950)|white|black)(/[0-9]+)?([^A-Za-z0-9_-]|$)"
export UI_ARB_RE='(^|[^A-Za-z0-9_-])[a-z][a-z0-9-]*-\[[^]]+\]'
export UI_LIT_RE="#[0-9a-fA-F]{3,8}([^0-9A-Za-z]|$)|(rgb|rgba|hsl|hsla|oklch|oklab)\("
export UI_STYLE_RE='style=\{\{'

# ui_skip <path> — true when the file is exempt (primitives, stories, tests, generated)
ui_skip() {
  case "$1" in
    */components/ui/*|components/ui/*) return 0 ;;
    *.stories.*|*.test.*|*.spec.*|*/__tests__/*|*/node_modules/*|*/dist/*|*/build/*|*.d.ts) return 0 ;;
  esac
  return 1
}

# ui_scan_text <path>  (stdin: lineno<TAB>text)
ui_scan_text() {
  local fpath="$1" ext="${1##*.}"
  case "$ext" in tsx|jsx|ts|js|vue|svelte|css|scss|html) ;; *) return 0 ;; esac
  ui_skip "$fpath" && return 0
  UI_PATH="$fpath" UI_EXT="$ext" awk -F'\t' '
    BEGIN { path=ENVIRON["UI_PATH"]; ext=ENVIRON["UI_EXT"]; raw=ENVIRON["UI_RAW_RE"]; arb=ENVIRON["UI_ARB_RE"];
            lit=ENVIRON["UI_LIT_RE"]; sty=ENVIRON["UI_STYLE_RE"] }
    {
      n=$1; t=substr($0, index($0, "\t")+1)
      if (t ~ /^[[:space:]]*(\/\/|\/\*|\*)/) next                       # comments
      if (ext ~ /^(css|scss)$/) {
        # token definitions (--name: value) and @theme blocks are where literals belong
        if (t ~ /^[[:space:]]*--[A-Za-z0-9-]+[[:space:]]*:/) next
        if (t ~ lit) print path ":" n ": colour-literal: " t
        next
      }
      if (t ~ raw) print path ":" n ": raw-colour: " t
      tmp=t; gsub(/(data|aria|group|peer|has|supports|not|in|nth)[a-z0-9-]*-\[[^]]*\]/, "", tmp)
      if (tmp ~ arb && tmp !~ /-\[(var|calc\(var)\(/) print path ":" n ": arbitrary-value: " t
      if (t ~ lit) print path ":" n ": colour-literal: " t
      if (t ~ sty) print path ":" n ": inline-style: " t
    }'
}
