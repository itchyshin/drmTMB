# Claude Handover: Skew-Normal Artifact Lane

Date: 2026-06-10

## Read First

Claude Code should read `AGENTS.md` before making changes. The current local
checkout at `/Users/z3437171/Dropbox/Github Local/drmTMB` is dirty and detached
at `b4a4d7be` (`Record q8 endpoint recovery audit`). Do not assume this checkout
is current, clean, or safe to edit broadly.

The completed skew-normal artifact-lane work was done in a separate recovery
checkout at `/private/tmp/drmTMB-skew-normal-recovery`, then merged through
GitHub PR #517. The source of truth is now `origin/main`, not the local detached
worktree.

## Completed Work

PR #517 was merged:

- PR: https://github.com/itchyshin/drmTMB/pull/517
- Merge commit: `784615f0ad2230eb86d95217f2b549aa29aa7f26`
- Branch used: `codex/skew-normal-recovery-artifacts`
- Remote branch was deleted by the merge.

The PR added a Phase 18 fixed-effect `skew_normal()` artifact lane:

- DGP: `inst/sim/dgp/sim_dgp_skew_normal_fixed_effect.R`
- fit summariser: `inst/sim/fit/sim_summarise_skew_normal_fixed_effect.R`
- smoke runner: `inst/sim/run/sim_run_skew_normal_fixed_effect_smoke.R`
- smoke summariser: `inst/sim/run/sim_summary_skew_normal_fixed_effect_smoke.R`
- grid writer: `inst/sim/run/sim_write_skew_normal_fixed_effect_grid.R`
- Actions dispatch: `inst/sim/run/sim_run_actions_cell.R`
- registry row: `inst/sim/registry/phase18_structured_workflow_registry.csv`
- workflow task: `.github/workflows/phase18-simulation-grid.yaml`
- focused tests:
  - `tests/testthat/test-phase18-skew-normal-fixed-effect.R`
  - `tests/testthat/test-phase18-actions-runner.R`
  - `tests/testthat/test-phase18-structured-workflow-registry.R`

The DGP and default grid use moderate sample sizes (`n = 720`, `1440`) because
skew-normal shape recovery is sample-size dependent. Tiny cells are plumbing
checks, not evidence for recovery quality.

## Verification Already Done

Local checks in the recovery checkout:

```sh
Rscript --vanilla -e 'devtools::test(filter = "phase18-skew-normal-fixed-effect", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "phase18-actions-runner", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "skew-normal|phase18-skew-normal-fixed-effect|phase18-actions-runner", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "phase18-structured-workflow-registry", reporter = "summary")'
Rscript --vanilla -e 'pkgdown::build_article("robust-student"); pkgdown::build_article("model-map"); cat("articles_ok\n")'
Rscript --vanilla -e 'pkgdown::check_pkgdown(); cat("pkgdown_check_ok\n")'
git diff --check
```

CI on PR #517 passed on all platforms:

- macOS R-CMD-check: pass
- Ubuntu R-CMD-check: pass
- Windows R-CMD-check: pass

Useful verification commands:

```sh
gh pr view 517 --repo itchyshin/drmTMB --json state,mergedAt,mergeCommit,statusCheckRollup
gh issue view 3 --repo itchyshin/drmTMB --json state,title,url
```

## Issue State

Issue #3 auto-closed after merge even though the PR body said not to close it.
It was reopened with this note:

> Reopening after PR #517. That PR added the fixed-effect Phase 18 skew-normal
> artifact lane, but the broader issue remains open for formal high-replicate
> grids, comparator evidence, and richer random/structured/bivariate
> skew-family surfaces.

Current intended state: issue #3 stays open.

## Important Boundaries

What is now usable:

- univariate fixed-effect `skew_normal()` artifact lane;
- `mu`, `sigma`, and `nu` fixed-effect predictors;
- public moment-scale DGP contract;
- repeatable smoke/grid artifact infrastructure;
- optional profile/bootstrap interval artifact columns.

What is not done:

- formal 500/1000-replicate operating-characteristic evidence;
- fitted external comparator grids;
- random effects for skew-normal;
- structured effects;
- known covariance;
- bivariate skew-normal;
- residual `rho12` under skew-normal;
- latent `skew(id)`;
- skew-t;
- alias grammar.

Do not promote those future surfaces in docs/status wording.

## Local Checkout Warning

At handover time, the main local checkout is dirty with many tracked and
untracked files, including earlier skew-normal, q8, Julia bridge, model
selection, and CRAN-readiness work. It is also detached at `HEAD`.

Before editing locally, run:

```sh
git status --short --branch
git log --oneline -5 --decorate
git fetch origin main
git log --oneline -5 --decorate origin/main
```

If continuing package work, prefer a clean branch from `origin/main` or a fresh
worktree. If using the current dirty checkout, first reconcile which local files
already contain pre-merge versions of PR #517 changes. Do not revert local
changes without explicit owner instruction.

## Recommended Next Slice

The next useful skew-normal slice is not more plumbing. It should be a formal
pilot:

1. Run a deliberately sized fixed-effect skew-normal grid, starting around 200
   replicates before any 500-1000 replicate expansion.
2. Stratify by simple constant-scale cells first, then heteroscedastic and
   predictor-varying `nu` cells.
3. Report convergence, `pdHess`, bias, RMSE, MCSE, false-positive behaviour for
   true `nu = 0`, and interval availability separately.
4. Keep the claims sample-size dependent: small `n` can fail or be weak; larger
   `n` should improve shape recovery if the implementation is behaving.
5. Only after that, add fitted-model comparator evidence on the public
   `mu`/`sigma`/`nu` scale.

If the next agent is asked to continue q8 instead, keep that separate from
skew-normal. q8 remains diagnostic-artifact territory unless deliberately sized
coverage/power evidence exists.
