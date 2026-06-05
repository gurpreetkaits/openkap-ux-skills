# openkap-ux-skills

Personal collection of [Claude Code](https://claude.com/claude-code) skills focused on UX and design system workflows for OpenKap projects.

## Skills

| Skill | Purpose |
| --- | --- |
| [`ui-design-system`](./ui-design-system) | Senior UI designer toolkit — design tokens, component documentation, responsive design calculations, and developer handoff helpers. |

## Install

Clone the repo somewhere outside `~/.claude/skills/`, then symlink each skill in:

```bash
git clone git@github.com:gurpreetkaits/openkap-ux-skills.git ~/code/openkap-ux-skills

cd ~/.claude/skills
ln -s ~/code/openkap-ux-skills/ui-design-system ui-design-system
```

Claude Code picks up symlinked skills the same as local directories. Edit files in the repo, commit, and the changes are live immediately.

## Adding a new skill

1. Create a new directory at the repo root with a `SKILL.md` (see [Anthropic's skill docs](https://docs.claude.com/en/docs/claude-code/skills)).
2. Symlink it into `~/.claude/skills/` to use it locally.
3. Commit and push.
