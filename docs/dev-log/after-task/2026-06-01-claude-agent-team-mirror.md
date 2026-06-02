# After-Task Report: Mirror the Codex team into `.claude/agents/`

## Task goal

Give Claude Code execution parity with the Codex team. Before this task,
`.codex/agents/` defined 10 launchable agents but Claude had no equivalent, so a
Claude session could read `AGENTS.md` but could not launch the named team as
subagents.

## Files created or changed

- New: `.claude/agents/{tmb-engineer,simulation-tester,documentation-writer,
  pkgdown-editor,reviewer,systems-auditor,reproducibility-engineer,
  landscape-scout,literature-curator,user-tester}.md` — 10 Claude subagent
  definitions, one per `.codex/agents/*.toml`.
- Edited: `CLAUDE.md` (new "Launchable Team Agents" section), `AGENTS.md`
  (sync note in Multi-Agent Collaboration).
- Appended: `docs/dev-log/team-improvements.md` (Curie naming follow-up),
  `docs/dev-log/check-log.md`.

## Mapping decisions

- Instruction bodies were copied **verbatim** from the Codex TOMLs.
- `model_reasoning_effort` mapped to a model: `high` → `opus`, `medium` →
  `sonnet`.
- Tools were scoped by posture: implementers (`tmb_engineer`,
  `simulation_tester`) and prose editors (`documentation_writer`,
  `pkgdown_editor`) get edit tools; reviewers/scouts are read-only, with
  `WebSearch`/`WebFetch` added for `landscape_scout` and `literature_curator`,
  and `Bash` for the agents that need to run checks (`reviewer`,
  `systems_auditor`, `reproducibility_engineer`).
- Standing-only names (Ada, Boole, Noether, Darwin, Florence, Emmy, Fisher) were
  deliberately left without agent files, matching the Codex side.

## Checks run and exact outcomes

- `ls .claude/agents/` → 10 `.md` files, matching the 10 `.codex/agents/*.toml`.
- `rg -n '^(name|description|model|tools):' .claude/agents/` → every file has
  valid frontmatter keys.
- Verbatim-body check: each `.md` body diffed against the corresponding TOML
  `developer_instructions`; no wording changes.
- `git status` → only the intended new/edited files; no changes under `R/`,
  `src/`, `tests/`, or likelihood design docs.
- The R toolchain is not installed in this web container, so `devtools::document`,
  `devtools::test`, and `devtools::check` were **not** run. This change is
  docs/config only and touches no R or C++ code, so package checks are not
  required for it.

## Consistency audit

- `rg -n "rho12|sigma|tau|meta_known_V" .claude/agents/` → canonical names
  preserved; `tau` does not appear; `rho12` used where the source TOMLs used it.
- No `meta_gaussian` or `tau ~` syntax introduced.

## Tests of the tests

Not applicable — no automated tests were added. Verification was structural
(frontmatter validity, file count parity, verbatim-body diff against the Codex
TOMLs).

## What did not go smoothly

Found a pre-existing role-name collision (see below). Resolved by preserving
existing wording and logging a follow-up rather than renaming mid-task.

## Team learning and process improvements

Logged in `team-improvements.md`: the **Curie** role is defined two ways —
`AGENTS.md` lists Curie as the simulation/testing specialist, but
`.codex/agents/literature-curator.toml` (now mirrored to
`.claude/agents/literature-curator.md`) calls Curie the literature/methods
curator. The simulation/testing function is actually carried by
`simulation_tester`. This is terminology drift in the role layer; it needs an
owner decision, not a silent rename.

## Design-doc updates

`docs/design/38-portable-agent-operating-kit.md` describes the agent-kit but not
the `.codex`/`.claude` mirror convention; the new convention is documented in
`AGENTS.md` and `CLAUDE.md` instead, which are the source of truth agents read
first. No design-doc grammar/likelihood change occurred.

## pkgdown / documentation updates

None required — `.claude/agents/` is developer tooling, not user-facing package
documentation.

## GitHub issue maintenance

No open issue matched this tooling task; the issue tracker was left unchanged
deliberately. A draft PR will carry the change.

## Known limitations and next actions

- No SessionStart hook or `.claude/settings.json` permissions were added (the
  owner scoped this task to the team mirror only). Both remain available as a
  follow-up to let `devtools::*` run in web sessions.
- The seven standing-only roles are not launchable agents; add files later if
  the owner wants them as subagents.
- Resolve the Curie naming collision in a dedicated decision.
