#!/usr/bin/env bash
# Shared helpers for agent-ops hooks. Sourced, not executed.

# Project root: Claude sets CLAUDE_PROJECT_DIR for hooks; fall back to the event's cwd.
ao_project_dir() {
  local cwd="$1"
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then printf '%s' "$CLAUDE_PROJECT_DIR"; else printf '%s' "${cwd:-$PWD}"; fi
}

ao_log_dir() {
  local dir; dir="$(ao_project_dir "$1")/.agent-log"
  mkdir -p "$dir/sessions" "$dir/goals"
  # Session logs are local by default; goals are committable. Edit .agent-log/.gitignore to change.
  [ -f "$dir/.gitignore" ] || printf 'sessions/\n' > "$dir/.gitignore"
  printf '%s' "$dir"
}

ao_session_file() {
  local logdir="$1" sid="$2"
  local short="${sid:0:8}"; [ -n "$short" ] || short="nosession"
  # Reuse the file this session already started (handles sessions that cross midnight).
  local existing; existing=$(ls "$logdir/sessions/"*"_${short}.jsonl" 2>/dev/null | head -1)
  if [ -n "$existing" ]; then printf '%s' "$existing"; else printf '%s/sessions/%s_%s.jsonl' "$logdir" "$(date +%F)" "$short"; fi
}

ao_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Redact common secret shapes and cap length. Reads stdin, writes stdout.
ao_redact() {
  local max="${1:-2000}"
  sed -E \
    -e 's/(Bearer )[A-Za-z0-9._-]+/\1REDACTED/g' \
    -e 's/(sk-[A-Za-z0-9_-]{8})[A-Za-z0-9_-]+/\1…REDACTED/g' \
    -e 's/(gh[pousr]_)[A-Za-z0-9]{10,}/\1REDACTED/g' \
    -e 's/(AKIA)[A-Z0-9]{12,}/\1REDACTED/g' \
    -e 's/(xox[abpr]-)[A-Za-z0-9-]+/\1REDACTED/g' \
    -e 's/((password|passwd|secret|token|api[_-]?key|authorization)["'"'"' ]*[:=]["'"'"' ]*)[^"'"'"' ,}]+/\1REDACTED/Ig' \
  | head -c "$max"
}

# Goal status from .agent-log/GOAL.md: none | active | done | partial | …
ao_goal_status() {
  local goal="$1/GOAL.md"
  [ -f "$goal" ] || { printf 'none'; return; }
  local s; s=$(sed -n 's/^status:[[:space:]]*//p' "$goal" | head -1 | tr -d '[:space:]')
  printf '%s' "${s:-active}"
}

# Count unticked criteria "- [ ] C…" in GOAL.md, ignoring ones marked BLOCKED.
ao_goal_open() {
  local goal="$1/GOAL.md"
  [ -f "$goal" ] || { printf '0'; return; }
  grep -E '^\s*- \[ \] C[0-9]+' "$goal" | grep -vc 'BLOCKED' || true
}

ao_goal_open_ids() {
  local goal="$1/GOAL.md"
  [ -f "$goal" ] || return 0
  grep -E '^\s*- \[ \] C[0-9]+' "$goal" | grep -v 'BLOCKED' | sed -E 's/^\s*- \[ \] (C[0-9]+).*/\1/' | paste -sd, -
}
