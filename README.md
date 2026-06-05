# claude-ux-skills

Personal collection of [Claude Code](https://claude.com/claude-code) skills focused on UX, QA, and design system workflows.

## Skills

| Skill | Purpose |
| --- | --- |
| [`qa-record`](./qa-record) | Runs `/qa-frontend` in a Playwright session with screen recording, uploads the video to Google Drive, and returns a shareable URL. Use for bug reports, async review, or design feedback. |
| [`ui-design-system`](./ui-design-system) | Senior UI designer toolkit — design tokens, component documentation, responsive design calculations, and developer handoff helpers. |
| [`sku-setup`](./sku-setup) | Switches local `.env` to Temu production secrets. |

## Install

Clone the repo somewhere outside `~/.claude/skills/`, then symlink each skill in:

```bash
git clone git@github.com:gurpreetkaits/claude-ux-skills.git ~/code/claude-ux-skills

cd ~/.claude/skills
ln -s ~/code/claude-ux-skills/qa-record qa-record
ln -s ~/code/claude-ux-skills/ui-design-system ui-design-system
ln -s ~/code/claude-ux-skills/sku-setup sku-setup
```

Claude Code picks up symlinked skills the same as local directories. Edit files in the repo, commit, and the changes are live immediately.

## Adding a new skill

1. Create a new directory at the repo root with a `SKILL.md` (see [Anthropic's skill docs](https://docs.claude.com/en/docs/claude-code/skills)).
2. Symlink it into `~/.claude/skills/` to use it locally.
3. Commit and push.
