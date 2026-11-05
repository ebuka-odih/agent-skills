#!/usr/bin/env bash
# High-confidence secret patterns (ERE). Sourced. Kept narrow to avoid false positives:
# each matches a real provider key format, not generic "password=" lines.
SECRET_PATTERNS=(
  'private-key|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
  'aws-access-key|AKIA[0-9A-Z]{16}'
  'github-token|gh[pousr]_[A-Za-z0-9]{36}'
  'github-pat|github_pat_[A-Za-z0-9_]{60,}'
  'stripe-live|(sk|rk)_live_[A-Za-z0-9]{20,}'
  'anthropic-key|sk-ant-[A-Za-z0-9_-]{30,}'
  'openai-key|sk-(proj-)?[A-Za-z0-9_-]{40,}'
  'slack-token|xox[baprs]-[A-Za-z0-9-]{20,}'
  'google-api-key|AIza[0-9A-Za-z_-]{35}'
)
# Values that are obviously placeholders (documentation examples, dummies)
PLACEHOLDER_RE='EXAMPLE|example|xxxx|XXXX|your[_-]?(key|token|secret)|changeme|dummy|<[^>]+>|\.\.\.'

# Print "kind" for each pattern matched in stdin text (one per line, deduped), ignoring placeholders.
secret_kinds() {
  local text; text="$(cat)"
  local entry kind re hit
  for entry in "${SECRET_PATTERNS[@]}"; do
    kind="${entry%%|*}"; re="${entry#*|}"
    hit=$(grep -oE -- "$re" <<<"$text" | grep -vE -- "$PLACEHOLDER_RE" | head -1)
    [ -n "$hit" ] && echo "$kind"
  done
}
