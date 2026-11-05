#!/usr/bin/env bash
# Parsers for SPEC.md and PLAN.md. Sourced, not executed. Output is TSV on stdout.

# Requirements: id <TAB> priority <TAB> status
spec_requirements() {
  awk '
    function flush() { if (id != "") print id "\t" pri "\t" st; id="" }
    /^[[:space:]]*- \*\*(NFR|R)[0-9]+\*\*/ {
      flush()
      match($0, /(NFR|R)[0-9]+/); id = substr($0, RSTART, RLENGTH)
      pri = "must"; if (match($0, /\((must|should|could)\)/)) pri = substr($0, RSTART+1, RLENGTH-2)
      st = "open"; next
    }
    id != "" && /status:/ { s=$0; sub(/.*status:[[:space:]]*/, "", s); sub(/[[:space:]].*/, "", s); st = s }
    /^## / { flush() }
    END { flush() }
  ' "$1"
}

# Milestones: id <TAB> name <TAB> status
plan_milestones() {
  awk '
    /^## M[0-9]+/ {
      line=$0; sub(/^## /, "", line)
      match(line, /^M[0-9]+/); id = substr(line, RSTART, RLENGTH)
      st = "planned"; if (match(line, /status:[[:space:]]*[a-z]+/)) { st = substr(line, RSTART, RLENGTH); sub(/status:[[:space:]]*/, "", st) }
      name = line; sub(/^M[0-9]+[[:space:]]*[—-]+[[:space:]]*/, "", name); sub(/[[:space:]]*·[[:space:]]*status:.*/, "", name)
      print id "\t" name "\t" st
    }
  ' "$1"
}

# Tasks: milestone <TAB> mark <TAB> id <TAB> title <TAB> covers <TAB> depends <TAB> note
plan_tasks() {
  awk '
    /^## M[0-9]+/ { match($0, /M[0-9]+/); ms = substr($0, RSTART, RLENGTH); next }
    /^## / { ms = "" ; next }
    ms != "" && /^[[:space:]]*- \[.\] T[0-9]+/ {
      line = $0; sub(/^[[:space:]]*- \[/, "", line)
      mark = substr(line, 1, 1); line = substr(line, 4)
      sep = " — "; note = ""; p = index(line, sep); if (p) { note = substr(line, p + length(sep)); line = substr(line, 1, p - 1) }
      n = split(line, f, / · /)
      id = f[1]; title = f[2]; covers = "-"; deps = "-"
      for (i = 3; i <= n; i++) {
        if (f[i] ~ /^covers:/)  { covers = f[i]; sub(/^covers:[[:space:]]*/, "", covers) }
        if (f[i] ~ /^depends:/) { deps = f[i];   sub(/^depends:[[:space:]]*/, "", deps) }
      }
      gsub(/[[:space:]]/, "", covers); gsub(/[[:space:]]/, "", deps)
      print ms "\t" mark "\t" id "\t" title "\t" covers "\t" deps "\t" note
    }
  ' "$1"
}

# Requirement IDs listed under "## Deferred"
plan_deferred() {
  awk '/^## Deferred/ { on=1; next } /^## / { on=0 } on && /^[[:space:]]*- (NFR|R)[0-9]+/ { match($0, /(NFR|R)[0-9]+/); print substr($0, RSTART, RLENGTH) }' "$1"
}

# Ready tasks: todo, in the active milestone, all depends done.
plan_ready() {
  local plan="$1" active done_ids
  active=$(plan_milestones "$plan" | awk -F'\t' '$3=="active"{print $1; exit}')
  done_ids=" $(plan_tasks "$plan" | awk -F'\t' '$2=="x"{printf "%s ", $3}') "
  plan_tasks "$plan" | while IFS=$'\t' read -r ms mark id title covers deps note; do
    [ "$ms" = "$active" ] && [ "$mark" = " " ] || continue
    ok=1
    if [ "$deps" != "-" ] && [ -n "$deps" ]; then
      IFS=',' read -ra ds <<<"$deps"
      for d in "${ds[@]}"; do case "$done_ids" in *" $d "*) ;; *) ok=0 ;; esac; done
    fi
    if [ "$ok" = 1 ]; then printf '%s\t%s\t%s\n' "$id" "$title" "$covers"; fi
  done
}
