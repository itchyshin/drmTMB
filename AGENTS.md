# drmTMB Agent Instructions

`drmTMB` is an R package for fast univariate and bivariate distributional
regression using Template Model Builder.

> **▶ Latest handover — start here (2026-07-05, → Claude).** Q-Series v1
> practical-surface checkpoint and multi-day takeover. The active branch is
> `drmtmb/fix-family-conventions`, pushed at
> `3262655f59c1da69eef1a1950a94ea1a6698eb33` after recovering exact Gaussian
> q2 scale-only point-fit/extractor rows for `spatial`, `animal`, and `relmat`.
> Current Q-Series v1 truth is 104 rows, practical v1 surface 94/104 (90.4%),
> Gaussian core 59/67 (88.1%), basic distribution recovery 35/37 (94.6%),
> exact `inference_ready` still 8/104, structured `supported` still 0/104, and
> post-v1 rows 10/104. This is not a full Q-Series completion claim: no q4/q8
> promotion, no new coverage authorization, no REML/AI-REML expansion, and no
> public-support wording. Product decision recorded: finish `drmTMB` as the
> primary R/TMB package first; keep `DRM.jl`/Julia optional and later, not
> required for v1. `gh` was unavailable in the shell, so the branch is pushed
> but draft PR creation may need the browser compare page. START HERE:
> [`docs/dev-log/handover/2026-07-05-claude-handover.md`](docs/dev-log/handover/2026-07-05-claude-handover.md).
>
> **▶ Latest handover — start here (2026-07-01, → Codex).** Q-Series Tranche 3 clean start.
> Tranche 2 is done and merged: PR #684 and PR #685 landed on `main`, with local
> `HEAD` and `origin/main` verified at `4d6d2339eb48`, no open drmTMB PRs, a clean
> worktree, `mission_control_ok`, and final-base R-CMD-check success for #685 on
> macOS/Ubuntu/Windows (`https://github.com/itchyshin/drmTMB/actions/runs/28492010510`).
> The current Q-Series support-cell truth is 104 rows, 8 interval/coverage
> `inference_ready` rows, 0 structured `supported` rows, 0 high-q
> (`q4`/`q6`/`q8`) `inference_ready` rows, and 0 non-Gaussian interval/coverage
> `inference_ready` rows. Do **not** claim the Q-Series is finished. The next
> work is Tranche 3: q4 admission before coverage, with Rose/Fisher/Gauss/Noether
> review before any status claim.
> START HERE:
> [`docs/dev-log/handover/2026-07-01-codex-handover.md`](docs/dev-log/handover/2026-07-01-codex-handover.md).
>
> **▶ Prior handover (2026-06-29, → Codex).** Q-Series evidence board continuation.
> The active branch is `codex/qseries-sigma-inference-ready` at local
> `HEAD=77b634ed` with a large dirty working tree. The 104-row support-cell widget is present
> and separates fit, interval, coverage, stability, recovery, diagnostic, blocked, and planned
> states. `tools/validate-mission-control.py` is green after the q2-plus-q2 local-smoke
> contract cleanup; Fisher/Rose signed off the next q2-plus-q2 smoke as a tiny
> Totoro/FIIA `n=5` run for only the six within-block targets, and also signed off
> the q2 intercept local-smoke gate for only the 12 q2 intercept targets. The
> q1 `mu` intercept rows also have Fisher/Rose-reviewed Totoro/FIIA `n=5` smoke
> contracts, but those rows remain `point_fit/planned/planned`. Do **not**
> claim the Q-Series is finished: only 5 rows are
> interval+coverage `inference_ready`; Gaussian q4/q6/q8, all q8, and all non-Gaussian
> interval/coverage claims remain unfinished. Nibi/Rorqual are reachable; the latest
> non-interactive host check found Totoro auth denied, no `fiia` alias, and reachable `fir`
> without a `drmTMB` checkout, so resolve host access/checkout before running either smoke.
> START HERE:
> [`docs/dev-log/handover/2026-06-29-codex-handover.md`](docs/dev-log/handover/2026-06-29-codex-handover.md).
>
> **▶ Prior handover (2026-06-28, → Codex).** Small-sample interval arc.
> The bias correction is now the **DEFAULT** for location-axis structured-RE SD targets:
> `confint(fit)` applies a t(g−1) width + a `+log(g/(g−1))` centre shift (simulation-calibrated,
> ~2× the leading-order REML SD term — *not* "REML in closed form"). Engine-validated nominal
> coverage at the deployment default **g=8 (0.954, all four providers)**; **q2 mu-slope (phylo,
> relmat) promoted to `inference_ready`** (interval + coverage). `supported` is **withheld** —
> measured 6:1 right-tail miss asymmetry + g-dependence → a REML-unblock or skew-aware-interval
> arc. **Supersession note:** the old "15 commits at `9ae75bf1` are unpushed"
> warning is no longer current. The consolidation branch
> `claude/local-coverage-grids-sigma-q2` has been pushed, and the active Q-Series
> widget/status continuation is PR #685 from `codex/qseries-sigma-inference-ready`.
> Verify the current branch/head with `git status --short --branch` before editing.
> Run R with
> `R_PROFILE_USER=/dev/null Rscript --no-init-file` (the `.Rprofile` R-4.5 lib segfaults R 4.6).
> START HERE:
> [`docs/dev-log/handover/2026-06-28-codex-handover.md`](docs/dev-log/handover/2026-06-28-codex-handover.md).
>
> **▶ Prior handover (2026-06-27).** Q-series structured-RE completion lane.
> 4 PRs banked (draft, stacked): #675 (relmat-NB2, CI recorded) · #676 (count-sigma rejection) ·
> #677 (sigma-slope coverage scaffolding — **deploy-ready**) · #678 (non-Gaussian family
> rejection; q-series cells 90→98). q2-slope coverage runner verified-ready (MCSE fix pending);
> q4-location runner HELD (defects). Coverage execution is **maintainer-run on fir** (agent is
> exfiltration-blocked from transferring code to the cluster). See:
> [`docs/dev-log/handover/2026-06-27-claude-handover.md`](docs/dev-log/handover/2026-06-27-claude-handover.md).
>
> **▶ Prior handover (2026-06-14).** The Ayumi σ-phylo arc just closed
> (DRM.jl#289 REML on all four among-axis axes; drmTMB#542/#543; reply posted to
> `Ayumi-495/LS_ecogeographical-rules#2`). Rehydration anchor:
> [`docs/dev-log/codex-handover-2026-06-14-ayumi-arc-closeout.md`](docs/dev-log/codex-handover-2026-06-14-ayumi-arc-closeout.md).
> **Top open task: #544** (bridge-gate-drift audit + a gate-vs-engine CI guard; sister
> mirror gllvmTMB#488). **No CRAN.** Decisions pending the maintainer: DRM.jl#280, #270.

## Core Scope

- Support one-response and two-response models only.
- Use one formula per distributional parameter.
- Prioritize location, scale, shape, zero inflation, random-effect scale, and
  residual correlation.
- Higher-dimensional multivariate models belong to `gllvmTMB`, not `drmTMB`.
- Meta-analysis is Gaussian regression with known sampling covariance; do not
  introduce `meta_gaussian()` or `tau ~` syntax without an explicit design
  decision.
- `rho12` is the canonical residual bivariate correlation parameter. `rho` may
  become an alias later, but docs and tests should use `rho12`.
- Bivariate models should prefer separate response formulas (`mu1 = y1 ~ ...`,
  `mu2 = y2 ~ ...`). `mvbind()` is only shorthand for identical location
  formulas.

## Design Rules

1. Do not add a new family without simulation tests.
2. Do not add user-facing functions without roxygen2 documentation.
3. Do not change formula grammar without updating
   `docs/design/01-formula-grammar.md`.
4. Do not change likelihood parameterization without updating
   `docs/design/03-likelihoods.md`.
5. Do not add random effects before fixed-effect likelihoods are tested.
6. Keep pull requests small and focused.
7. Every meaningful change should update `docs/dev-log/check-log.md`.
8. Every completed task or phase should create an after-task or after-phase
   report following `docs/design/10-after-task-protocol.md`.
9. If code is ported from `gllvmTMB` or another package, document provenance in
   `inst/COPYRIGHTS` before treating the change as complete.

## Standard Commands

```r
devtools::document()
devtools::test()
devtools::check()
pkgdown::check_pkgdown()
```

## Recovery Checkpoints

For long Codex runs, stream failures, or handoffs, create a compact recovery
checkpoint before continuing:

```sh
Rscript tools/codex-checkpoint.R --goal "current task" --next "next command or edit"
```

The script writes a Markdown snapshot under
`docs/dev-log/recovery-checkpoints/` with git status, changed files, diff stat,
the newest check-log evidence, newest after-task reports, and exact commands for
the next agent to rerun. A checkpoint is only a handoff aid: repository state is
authoritative, so always rerun `git status` and `git diff` before editing.

## Definition of Done

A feature is done only when implementation, tests, documentation, examples,
check logs, after-task notes, and review are all present.

## Writing Style

For user-facing prose, developer notes, after-task reports, and release text,
write for a named reader and keep the prose concrete. The main readers are
applied ecology, evolution, and environmental-science users, plus statistical
method developers and R package contributors.

- Name the purpose before mechanics.
- Pair symbolic equations, R syntax, and interpretation when explaining models.
- Use concrete terms, files, equations, functions, or numerical results rather
  than vague phrases such as "various factors" or "significant improvements".
- Use active voice when the agent matters.
- Do not turn prose into bullets unless the content is a genuine list.
- Keep terms stable: `sigma`, `rho12`, `sd(group)`, `meta_V(V = V)`,
  `phylo()`, `spatial()`, `mu`, and `nu` should not drift across documents.
  Mention deprecated `meta_known_V(V = V)` only as a compatibility alias.
  Mention `tau` only when explaining a second shape parameter or when
  contrasting drmTMB's `sigma` with meta-analysis notation.
- Support factual, statistical, or literature claims with a citation, local
  evidence, or a clear note that the statement is a design assumption.
- Define location, scale, shape, and coscale at first use; connect coscale to
  residual correlation `rho12`.
- For tutorials and error-message docs, tell the reader what to try next when a
  model or syntax is unsupported.

Use the project-local `prose-style-review` skill for substantial README,
vignette, pkgdown, after-task, release, or paper-oriented text. This skill was
adapted from lessons in `yzhao062/agent-style`; do not copy that project into
this repository or add it as a package dependency without a separate decision.

## Multi-Agent Collaboration

Codex and Claude Code may both contribute to this repository. All agent work
must follow the same project rules:

- preserve the univariate/bivariate scope;
- avoid unreviewed likelihood or formula-grammar changes;
- update design docs when architecture changes;
- add tests with implementation;
- do not revert changes made by another agent or human unless explicitly asked;
- prefer small, reviewable commits or pull requests.

When an agent hands work to another agent, leave enough context in
`docs/dev-log/check-log.md` or the relevant issue/PR for the next agent to
continue without rediscovering the whole problem.

Claude Code should read this file first. It should not introduce a parallel
agent configuration system inside the package unless the project owner asks for
one.

The launchable team agents live in two mirrored directories: `.codex/agents/`
for Codex and `.claude/agents/` for Claude Code. The two sets are one-to-one and
share verbatim instruction bodies. When an agent is added or its instructions
change, update both directories in the same change so the runtimes do not drift.
Every standing review name below now has a launchable agent: the job-function
agents carry the named perspectives (Gauss = `tmb_engineer`, Curie =
`simulation_tester`, Rose = `systems_auditor`, Grace =
`reproducibility_engineer`, Jason = `landscape_scout`, Pat = `user_tester`), and
the review-only perspectives have dedicated files (Ada = `integration_reviewer`,
Boole = `formula_reviewer`, Noether = `math_consistency_reviewer`, Darwin =
`audience_reviewer`, Florence = `figure_reviewer`, Emmy = `architecture_reviewer`,
Fisher = `inference_reviewer`). These review agents are still launched only for
bounded tasks, not run continuously.

## Standing Review Roles

These names are shorthand for recurring review perspectives. They do not run
continuously; the orchestrator should launch them only for bounded tasks. Use
these canonical names when reporting team perspectives; do not rename them in
status updates or project notes.

| Name | Role | Primary questions |
| --- | --- | --- |
| Ada | Orchestrator and integrator | What should happen next, and are code, math, docs, tests, pkgdown, and git consistent? |
| Boole | R API and formula reviewer | Is the syntax memorable, parseable, and internally consistent? |
| Gauss | TMB likelihood and numerical reviewer | Is the likelihood correct and numerically stable? |
| Noether | Mathematical consistency reviewer | Do the symbolic equations, R syntax, and TMB implementation match exactly? |
| Darwin | Ecology/evolution audience reviewer | Does the example answer a real biological question for the target audience? |
| Florence | Scientific figure editor and visualization reviewer | Are plots publication-quality, interpretable, accessible, and honest about uncertainty? |
| Fisher | Statistical inference reviewer | Do simulations, comparator checks, likelihood profiles, and identifiability diagnostics support the claim? |
| Pat | Applied PhD student user tester | Can a new applied user follow the tutorial, interpret output, recover from errors, and avoid hidden jargon? |
| Jason | Landscape and source-map scout | What do related packages and papers already do, and what should `drmTMB` learn or avoid? |
| Curie | Simulation and testing specialist | Do recovery tests cover ordinary, edge, and malformed-input cases without becoming too slow? |
| Emmy | R package architecture reviewer | Are S3 methods, object structures, extractors, and internal APIs coherent? |
| Grace | CI, pkgdown, CRAN, and reproducibility engineer | Will this pass on all platforms, deploy cleanly, and avoid compiled-code or dependency risk? |
| Rose | Systems auditor | What discrepancies, repeated mistakes, stale wording, unsupported claims, and missing feedback loops are accumulating? |

Figure quality is shared work. Florence leads the final scientific-figure
standard, but Pat, Fisher, Rose, Darwin, Grace, Boole, and Noether should help
before a figure reaches her: they should notice missing uncertainty, wrong data
grain, unsupported-looking syntax, weak reader guidance, stale claims, failed
render evidence, and figures that are technically present but visually
unhelpful. Use the project-local `figure-visual-audit` skill when plots,
figure galleries, simulation graphics, or rendered pkgdown pages are under
review. A good figure should help users understand the model and help the team
catch wrong assumptions.

## Team Improvement Loop

When a task exposes a better way for the team to work, record it in
`docs/dev-log/team-improvements.md`. Low-risk documentation, process, and local
skill improvements can be implemented immediately. Product, architecture, or
validation-policy changes need a normal task, evidence, and review.

## pkgdown Policy

The pkgdown site is a first-class project artifact. User-facing features should
include reference documentation and, when substantial, an article or tutorial.
Keep `_pkgdown.yml` synchronized with exported functions and vignettes.

## Hermes Policy

Hermes is optional external lab orchestration. It is not a package dependency
and should not be installed inside this repository or required for development.

<!-- shinichi-hub -->
> Read first — personal operating contract & second brain (house rules, memory, agents): /Users/z3437171/Dropbox/Github Local/Shinichi/AGENTS.md  (repo rules override the hub where they differ)
