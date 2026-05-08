#!/usr/bin/env bash
# claude-bar — Claude Code status line.
# Renders: ctx: [██████░░░░] 62% · 158k tok   parent/dir  branch  Model
#
# The bar is 10 characters wide (█ filled, ░ empty). Token count is
# formatted with k / M suffixes. Branch and model trail on the right.
#
# Source / install: https://github.com/ethanchiou/claude-bar

input=$(cat)

bar_width=10

# --- context window percentage + bar ---
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$ctx_pct" ]; then
    filled=$(awk -v p="$ctx_pct" -v w="$bar_width" 'BEGIN { printf "%d", (p/100)*w + 0.5 }')
    [ "$filled" -gt "$bar_width" ] && filled="$bar_width"
    [ "$filled" -lt 0 ] && filled=0
    empty=$((bar_width - filled))
    pct_label=$(awk -v p="$ctx_pct" 'BEGIN { printf "%.0f%%", p }')
else
    filled=0
    empty="$bar_width"
    pct_label="--%"
fi

# Build the bar — POSIX-safe loop so this works on bash 3.2 (macOS default).
bar=""
i=0
while [ "$i" -lt "$filled" ]; do
    bar="${bar}█"
    i=$((i + 1))
done
i=0
while [ "$i" -lt "$empty" ]; do
    bar="${bar}░"
    i=$((i + 1))
done

# --- token count (prefer current context size; fall back to session totals) ---
ctx_tokens=$(echo "$input" | jq -r '
    .context_window.total_tokens //
    .context_window.used_tokens //
    ((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0)) //
    empty
')

if [ -n "$ctx_tokens" ] && [ "$ctx_tokens" != "0" ] && [ "$ctx_tokens" != "null" ]; then
    tok_label=$(awk -v t="$ctx_tokens" 'BEGIN {
        if (t >= 1000000) printf "%.1fM tok", t/1000000
        else if (t >= 1000)  printf "%dk tok",  t/1000
        else                 printf "%d tok",   t
    }')
else
    tok_label="-- tok"
fi

# --- model short name ---
model=$(echo "$input" | jq -r '.model.display_name // "claude"')

# --- cwd (last 2 path components for brevity) ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
short_cwd=$(echo "$cwd" | awk -F/ '{
    n=NF; if(n>=2) print $(n-1)"/"$n; else print $n
}')

# --- git branch (skip optional locks) ---
branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
fi

# --- assemble ---
left=$(printf "ctx: [%s] %s · %s" "$bar" "$pct_label" "$tok_label")
right=""
[ -n "$short_cwd" ] && right="$short_cwd"
[ -n "$branch"    ] && right="$right  $branch"
[ -n "$model"     ] && right="$right  $model"

if [ -n "$right" ]; then
    printf "%s   %s" "$left" "$right"
else
    printf "%s" "$left"
fi
