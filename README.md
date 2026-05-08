# claude-bar

A minimal Claude Code status line that shows what you actually need: a
visual context-window bar and a token count.

```
ctx: [██████░░░░] 67% · 135k tok   NorthforgeCapital/strategy-backtester  main  Claude Opus 4.7
```

No dollar amounts (cost depends on model + tier; show the thing you can
act on instead). No spinner, no extra metadata. Bar fills as the context
window does, so you can spot a compaction coming three turns away.

## What it shows

- `[██████░░░░]` — 10-cell bar, one cell per 10% of the context window.
- `67%` — exact percentage from the harness.
- `135k tok` — current context size, with `k` / `M` suffixes.
- `parent/dir` — last two components of the cwd.
- `branch` — git branch when in a repo, otherwise omitted.
- Model display name.

## Requirements

- macOS or Linux (any bash, including macOS's bash 3.2)
- `jq` (`brew install jq` / `apt install jq`)
- Claude Code CLI

## Install

```bash
git clone https://github.com/ethanchiou/claude-bar.git ~/.claude-bar
chmod +x ~/.claude-bar/statusline.sh
```

Then add this block to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude-bar/statusline.sh"
  }
}
```

If `~/.claude/settings.json` already has other top-level keys, merge the
`statusLine` field into the existing object. Restart Claude Code (or
start a new session) and the bar appears.

## Updating across machines

```bash
cd ~/.claude-bar && git pull
```

No rebuild step. The script is read on every render.

## Customizing

Open `~/.claude-bar/statusline.sh` and edit. The interesting knobs:

- `bar_width=10` — bump to 20 for 5%-per-cell resolution.
- The `█` / `░` glyphs — swap for any monospace-friendly Unicode pair
  (e.g. `▓` / `▒` for softer shading).
- The right-hand fields (`short_cwd`, `branch`, `model`) — drop or
  reorder. The two load-bearing fields are the bar and the token count;
  everything to the right of `·` is informational.

## How the bar renders

Three pieces:

1. Compute how many cells to fill from the percentage:
   ```bash
   filled=$(awk -v p="$ctx_pct" -v w="$bar_width" \
       'BEGIN { printf "%d", (p/100)*w + 0.5 }')
   empty=$((bar_width - filled))
   ```
   `awk` does the math because POSIX `sh` has no float arithmetic.
   `+ 0.5` then `%d` truncation is manual round-to-nearest.

2. Build the string with a POSIX `while` loop (bash 3.2 safe — no
   `for ((i=0; i<n; i++))` since macOS ships bash 3.2):
   ```bash
   bar=""; i=0
   while [ "$i" -lt "$filled" ]; do bar="${bar}█"; i=$((i+1)); done
   i=0
   while [ "$i" -lt "$empty"  ]; do bar="${bar}░"; i=$((i+1)); done
   ```

3. Wrap in brackets and `printf`. No `tr` on multibyte chars (some BSD
   `tr` implementations mangle UTF-8); no brace expansion (bash 4+ only).

`█` is U+2588 Full Block, `░` is U+2591 Light Shade. Both 1 column wide
in any modern terminal, no visual gap when adjacent.

## License

MIT — see [LICENSE](./LICENSE).
