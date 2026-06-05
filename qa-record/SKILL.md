---
name: qa-record
description: Recorded version of /qa-frontend. Runs the full frontend QA workflow in a Playwright session with screen recording, then uploads the video to Google Drive and replies with a shareable URL. Use this instead of /qa-frontend whenever the QA pass should produce a sharable recording (bug reports, async review, design feedback).
allowed-tools: Bash(playwright-cli:*) Bash(pwc:*) Bash(rclone:*) Bash(~/.claude/skills/qa-record/scripts/upload-to-drive.sh:*) Bash(mkdir:*) Bash(basename:*) Bash(dirname:*) Bash(pwd:*) Bash(which:*) Bash(command:*) Bash(date:*) Bash(ls:*) Bash(test:*) Bash(sed:*) Read Edit Write Glob Grep Skill
user_invocable: true
args: "<feature, page, or PRD context — same shape as /qa-frontend>"
---

# QA Frontend + Record & Share

This skill is the **broader version of `/qa-frontend`**: it runs the exact same QA workflow, but wraps it in a screen recording, uploads the recording to Google Drive, and replies with a shareable URL the user can paste into Slack, Jira, etc.

## What this skill owns vs. delegates

This SKILL.md is responsible for **recording + upload only**. The QA testing itself is delegated to the `qa-frontend` skill via the Skill tool.

This skill lives at **user level** (`~/.claude/skills/qa-record/`) and is available in every project on this Mac. The delegated `qa-frontend` skill, however, is currently project-scoped to **sku.io** (`.agents/skills/qa-frontend/SKILL.md`). When invoked outside sku.io, the `Skill(qa-frontend)` call will fail because that skill isn't loaded. In that case, perform a minimal browser QA pass inline (open the URL the user named, walk through the golden path, capture screenshots and console errors) — the recording + upload phases still work.

## Required tools

- `playwright-cli` — `npm i -g @playwright/cli`
- `rclone` — `brew install rclone`, then `rclone config` once with a Google Drive remote named **`qa-record`** (override with `RCLONE_REMOTE=<name>:Folder` if you prefer a different remote)

## Phase 0 — Pre-flight (must pass before any browser work)

```bash
command -v playwright-cli >/dev/null || { echo "MISSING: playwright-cli. Run: npm i -g @playwright/cli"; exit 1; }
command -v rclone >/dev/null         || { echo "MISSING: rclone. Run: brew install rclone"; exit 1; }
RCLONE_REMOTE_NAME="${RCLONE_REMOTE%%:*}"; RCLONE_REMOTE_NAME="${RCLONE_REMOTE_NAME:-qa-record}"
rclone listremotes | grep -q "^${RCLONE_REMOTE_NAME}:$" || { echo "MISSING: rclone '${RCLONE_REMOTE_NAME}:' remote. Run: rclone config (name the Google Drive remote '${RCLONE_REMOTE_NAME}', or set RCLONE_REMOTE=<name>:Folder)"; exit 1; }
```

If any check fails, stop and surface the exact remediation command to the user. Do not continue.

## Phase 1 — Open the browser session

Use the same convention as `qa-frontend`'s Phase 3.0 / the `browser` skill so the session composes cleanly.

```bash
PWC_SESSION="$(basename "$(pwd)" | sed 's/\.sku\.io//' | sed 's/[^a-zA-Z0-9_-]/-/g')"
if [ "$(basename "$(pwd)")" = "current" ]; then
  PWC_SESSION="$(basename "$(dirname "$(pwd)")" | sed 's/\.sku\.io//')"
fi
PWC_CMD="$(command -v pwc 2>/dev/null && echo pwc || echo playwright-cli)"

$PWC_CMD -s=$PWC_SESSION open
# If pwc isn't available, force 1080p so the recording matches the standard viewport:
# playwright-cli -s=$PWC_SESSION resize 1920 1080
```

## Phase 2 — Start video recording

```bash
RECORDING_DIR="$(pwd)/qa-reports/recordings"
mkdir -p "$RECORDING_DIR"
RECORDING_PATH="$RECORDING_DIR/qa-$(date +%Y%m%d-%H%M%S).webm"
playwright-cli -s=$PWC_SESSION video-start "$RECORDING_PATH" --size=1920x1080
```

Hold onto `$RECORDING_PATH` — Phase 5 needs it.

You can mark logical chapters during Phase 3 to make the recording easier to scrub:

```bash
playwright-cli -s=$PWC_SESSION video-chapter "Login"
playwright-cli -s=$PWC_SESSION video-chapter "Open product mapping modal"
playwright-cli -s=$PWC_SESSION video-chapter "Bug: archived toggle resets filters"
```

Add a chapter at the start of each Phase from the qa-frontend workflow and at every bug moment. Future viewers (and `/qa-loom`) will thank you.

## Phase 3 — Run the full `/qa-frontend` workflow

Invoke the `qa-frontend` skill via the Skill tool, passing through whatever args the user gave to `/qa-record`. That skill handles:

- Context detection (git diff, PRD lookup, Vue 2 vs Vue 3)
- Test plan generation (happy path, edge cases, UI/UX heuristics, component-specific tests)
- Data readiness check (and invoking `/qa-seed` if needed)
- Browser QA execution against the already-open session
- Auto-fix of P0/P1 issues with build-wait + re-verification
- Final verification + handoff summary

**Important rules during Phase 3:**

- The browser session is already open and recording. When `qa-frontend` runs `$PWC_CMD open`, it will attach to the existing session — that's expected.
- Do **not** call `playwright-cli close` or `playwright-cli delete-data` at any point during the QA pass; that would terminate the recording.
- If `qa-frontend` instructs you to fix issues, follow its build/Pint/`/api-docs` rules exactly. Recording continues in the background while fixes are applied and re-tested.
- If the browser connection drops and must be restarted mid-run, stop the recording first (Phase 5), restart the browser, then start a fresh recording with a `-resumed` suffix. Upload both at the end.

## Phase 4 — Add a closing chapter

Before stopping, mark a final chapter so the viewer can jump to the wrap-up state:

```bash
playwright-cli -s=$PWC_SESSION video-chapter "Final verification screenshot"
```

## Phase 5 — Stop recording

```bash
playwright-cli -s=$PWC_SESSION video-stop
test -s "$RECORDING_PATH" || { echo "ERROR: recording file is missing or empty: $RECORDING_PATH"; exit 1; }
```

## Phase 6 — Upload to Drive and capture the URL

```bash
SHARE_URL="$(~/.claude/skills/qa-record/scripts/upload-to-drive.sh "$RECORDING_PATH")"
```

The script copies the file to `qa-record:QA-Recordings/<filename>.webm` (or whatever `RCLONE_REMOTE` is set to), creates a public link via `rclone link`, and prints only the URL on stdout (progress goes to stderr).

If `rclone link` fails on a brand-new upload (Drive sometimes lags a few seconds before allowing link creation), retry the script's link step once before reporting an error.

Override the destination folder with a second arg if needed:
```bash
~/.claude/skills/qa-record/scripts/upload-to-drive.sh "$RECORDING_PATH" "qa-record:Shared/QA"
```

## Phase 7 — Reply to the user

Print the qa-frontend handoff summary (from its Phase 5.2) with the recording link prepended:

```
## qa-record report

🎥 Recording: <SHARE_URL>
📁 Local copy: <RECORDING_PATH>

(then the full qa-frontend handoff: What Was Tested, Issues Found & Fixed, Manual QA Checklist, Things I Could Not Test, Confidence Level)
```

The URL is the most important line — surface it at the very top of the reply so the user can grab it without scrolling.

## Constraints

- Do **not** commit, push, or run destructive git commands.
- Do **not** close the browser session in Phase 7 — the user may want to keep poking. The `qa-frontend` skill also doesn't close it.
- Recording files live under `$(pwd)/qa-reports/recordings/`. In sku.io this is already inside the `qa-reports/` gitignore entry. In other projects, add `qa-reports/` to that project's `.gitignore` on first run so recordings don't get committed.
- The recording can be hundreds of MB. Do not Read it back into context. Only its path and the returned URL matter.
- If Phase 3 (the delegated `qa-frontend` workflow) errors out, still attempt Phase 5 + 6 so the user gets a recording of the partial run plus the error context.
