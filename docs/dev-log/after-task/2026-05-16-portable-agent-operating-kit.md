# After Task: Portable Agent Operating Kit

## Goal

Package the collaboration habits, named review team, after-task routines,
memory rules, and reusable local skills from the `drmTMB` workflow into a
portable bundle that can be copied into sibling R, statistical,
machine-learning, agent-based modelling, or data-wrangling projects.

## Implemented

Added `docs/agent-kit/` as a process-only bundle. The kit includes a README,
bootstrap checklist, standing-role guide, project-memory policy, and copyable
templates for `AGENTS.md`, `CLAUDE.md`, a memory seed, design docs, dev-log
files, and local skills.

Added `docs/design/38-portable-agent-operating-kit.md` to state the boundary:
the kit copies process, not `drmTMB` statistical claims.

Added `docs/dev-log/team-improvements.md` and a `Team Improvement Loop` rule in
`AGENTS.md`, because packaging the team exposed a gap in our own process: there
was no single durable place for team-level process improvements.

## Files Changed

- `AGENTS.md`
- `.gitignore`
- `docs/agent-kit/README.md`
- `docs/agent-kit/bootstrap-checklist.md`
- `docs/agent-kit/team-roles.md`
- `docs/agent-kit/project-memory-policy.md`
- `docs/agent-kit/templates/AGENTS.md`
- `docs/agent-kit/templates/CLAUDE.md`
- `docs/agent-kit/templates/MEMORY.seed.md`
- `docs/agent-kit/templates/docs/design/00-vision.md`
- `docs/agent-kit/templates/docs/design/10-after-task-protocol.md`
- `docs/agent-kit/templates/docs/dev-log/check-log.md`
- `docs/agent-kit/templates/docs/dev-log/decisions.md`
- `docs/agent-kit/templates/.agents/skills/after-task-audit/SKILL.md`
- `docs/agent-kit/templates/.agents/skills/prose-style-review/SKILL.md`
- `docs/agent-kit/templates/.agents/skills/simulation-test-plan/SKILL.md`
- `docs/agent-kit/templates/.agents/skills/model-implementation-review/SKILL.md`
- `docs/agent-kit/templates/.agents/skills/release-readiness-review/SKILL.md`
- `docs/design/38-portable-agent-operating-kit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`
- `docs/dev-log/after-task/2026-05-16-portable-agent-operating-kit.md`

## Checks Run

- `PATH=/opt/homebrew/bin:$PATH air format .gitignore AGENTS.md docs/agent-kit/README.md docs/agent-kit/bootstrap-checklist.md docs/agent-kit/team-roles.md docs/agent-kit/project-memory-policy.md docs/agent-kit/templates/AGENTS.md docs/agent-kit/templates/CLAUDE.md docs/agent-kit/templates/MEMORY.seed.md docs/agent-kit/templates/docs/design/00-vision.md docs/agent-kit/templates/docs/design/10-after-task-protocol.md docs/agent-kit/templates/docs/dev-log/check-log.md docs/agent-kit/templates/docs/dev-log/decisions.md docs/agent-kit/templates/.agents/skills/after-task-audit/SKILL.md docs/agent-kit/templates/.agents/skills/prose-style-review/SKILL.md docs/agent-kit/templates/.agents/skills/simulation-test-plan/SKILL.md docs/agent-kit/templates/.agents/skills/model-implementation-review/SKILL.md docs/agent-kit/templates/.agents/skills/release-readiness-review/SKILL.md docs/design/38-portable-agent-operating-kit.md docs/dev-log/team-improvements.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-portable-agent-operating-kit.md`:
  passed.
- `git diff --check`: passed.
- `PATH=/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `git diff --unified=0 -- . ':!docs/dev-log/check-log.md' | LC_ALL=C rg -n '[^\x00-\x7F]' || true`:
  returned no added non-ASCII outside the existing historical check log.
- `git diff --unified=0 -- docs/dev-log/check-log.md | LC_ALL=C rg -n '^\+.*[^\x00-\x7F]' || true`:
  returned no added non-ASCII in the new check-log entry.

## Tests Of The Tests

No package tests were added because this task created documentation and process
templates only.

## Consistency Audit

- `rg -n "<PROJECT>|<one-sentence|<plain-language|<statistical modelling|<applied users|<workflow|<non-goal|<future idea|<function|<parameter|<object field|<file>|<test or check>|<branch>|<record output>|<short task|<decision" docs/agent-kit docs/design/38-portable-agent-operating-kit.md docs/dev-log/team-improvements.md docs/dev-log/after-task/2026-05-16-portable-agent-operating-kit.md AGENTS.md docs/dev-log/check-log.md`:
  confirmed placeholders are confined to the copyable templates and explanatory
  instructions.
- `rg -n "<PROJECT>|<one-sentence|<plain-language|<statistical modelling|<applied users|<workflow|<non-goal|<future idea|<function|<parameter|<object field|<file>|<test or check>|<branch>|<record output>|<short task|<decision" docs/agent-kit docs/design/38-portable-agent-operating-kit.md docs/dev-log/team-improvements.md docs/dev-log/after-task/2026-05-16-portable-agent-operating-kit.md AGENTS.md docs/dev-log/check-log.md | rg -v "docs/agent-kit/templates|bootstrap-checklist.md|portable-agent-operating-kit.md" || true`:
  returned no unexpected placeholders outside templates and explanatory text.
- `rg -n "rho12|meta_known_V|phylo\(|spatial\(|Template Model Builder|TMB|drmTMB" docs/agent-kit/templates || true`:
  returned no `drmTMB` statistical claims inside the copyable templates.

## What Did Not Go Smoothly

The main design risk was overfitting the bundle to `drmTMB`. The templates now
use `<PROJECT>` placeholders and explicitly tell adopters to rewrite statistical
claims, parameter names, examples, and validation rules for each target
project.

The main repository mechanics risk was `.gitignore`: `docs/*` is ignored by
default, so `docs/agent-kit/` needed an explicit exception before the portable
bundle could be tracked.

The staged diff check also caught extra blank lines at the end of the new
template files. A mechanical cleanup removed them before commit.

## Team Learning

Ada kept the bundle focused on copyable files. Boole made the public interface
of the kit explicit: copy `templates/`, then adapt placeholders. Pat and Darwin
kept the project-type advice readable for non-`drmTMB` users. Grace kept the
release and check-log pieces concrete. Rose required a memory policy and a team
improvement log so hidden agent memory does not become the only record of
project decisions or process lessons.

## Known Limitations

The kit has not yet been installed into `gllvmTMB` or another sibling
repository. That should be the real pilot before treating the template as
stable.

Routine package tests were not rerun because this task did not change R code,
tests, vignettes, examples, likelihoods, or package exports. GitHub CI should
still run after the pull request is opened.

## Next Actions

Pilot the kit in one sibling project, preferably `gllvmTMB`, then revise
placeholders and local skills based on the first adoption friction.
