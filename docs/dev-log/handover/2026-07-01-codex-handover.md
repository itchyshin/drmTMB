# Session Handoff: Q-Series Tranche 3 Clean Start

Meta: 2026-07-01 · from Codex to Codex · context high

You are Codex, picking up `drmTMB` after the Q-Series Tranche 2 merge gate.
Read `AGENTS.md` first, then this file. This is a clean-main handover: the
Tranche 2 support-cell stack has been merged, and the next work should start
from Tranche 3, not by reopening Tranche 2 unless a new audit finds drift.

## Critical Context

Tranche 2 is done. PR #684 and PR #685 are merged into `main`; local `HEAD` and
`origin/main` were both `4d6d2339eb48` at handoff, with a clean worktree and no
open `drmTMB` pull requests.

Do not say the whole Q-Series is finished. The source-of-truth support-cell
table still has 104 rows. Exactly 8 rows are interval/coverage
`inference_ready`; no structured row is `supported`; no Gaussian high-q
(`q4`/`q6`/`q8`) row is `inference_ready`; and no non-Gaussian row has interval
or coverage `inference_ready` status.

The next scientific arc is Tranche 3: q4 admission before coverage. It is a
denominator, Hessian, transform, and interval-target admission problem, not a
large coverage-grid problem yet.

## Mission Control Summary

| Area | Current state | What this means |
| --- | --- | --- |
| Repository | `drmTMB` on `main` | Start from `origin/main`, not the old feature branches. |
| Main SHA | `4d6d2339eb48` | Merge commit for PR #685. |
| Merged PRs | #684, #685 | Tranche 2 evidence/status work is durable on `main`. |
| Open PRs | none at handoff | No stacked Q-Series PR remains open. |
| Final CI | R-CMD-check success, run `28492010510` | macOS, Ubuntu, and Windows all passed for #685's final-base SHA `792cc3c3`. |
| Mission control | `mission_control_ok` | Validator saw 104 Q-Series cells and 8 inference-evidence summary rows. |
| Support cells | 104 rows | Source of truth: `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`. |
| Gaussian rows | 67 | Includes 24 high-q rows and 9 q8 rows. |
| Non-Gaussian rows | 37 | Recovery/rejection evidence only; no interval or coverage claim. |
| Inference-ready | 8 rows | See the exact cell list below. |
| Structured supported | 0 rows | Do not claim structured-RE `supported`. |
| High-q inference-ready | 0 rows | q4/q6/q8 remain future arcs. |
| Non-Gaussian inference-ready | 0 rows | Non-Gaussian interval/coverage remains unsupported future work. |

Current `inference_ready` rows:

```text
qseries_phylo_q1_mu_intercept
qseries_phylo_q1_sigma_one_slope
qseries_phylo_q2_mu1_mu2_one_slope
qseries_spatial_q1_mu_intercept
qseries_animal_q1_sigma_one_slope
qseries_relmat_q1_mu_intercept
qseries_relmat_q1_sigma_one_slope
qseries_relmat_q2_mu1_mu2_one_slope
```

## What Was Accomplished

- PR #684, "Consolidate Q-Series v1 small-sample interval status", merged at
  `a178314e2b73330e9049be7cb46e0a1541bffac0` on 2026-07-01.
- PR #685, "Promote q1 sigma phylo/animal/relmat evidence", merged at
  `4d6d2339eb482f574293f30464276b284cb3e949` on 2026-07-01.
- PR #685 was retargeted to `main` after #684 landed, then a fresh
  final-base R-CMD-check workflow was dispatched and passed:
  `https://github.com/itchyshin/drmTMB/actions/runs/28492010510`.
- The final compact audit found:
  `rows=104`, `structured_supported=0`, `inference_ready=8`,
  `highq_inference_ready=0`, and `nongaussian_inference_ready=0`.
- The latest Tranche 2 after-task report is:
  `docs/dev-log/after-task/2026-07-01-q-series-tranche2-status-closure-sync.md`.

## Current Working State

- Working: `main` is clean and matches `origin/main` at `4d6d2339eb48` before
  this handover branch was created.
- Working: mission control passed from clean main with
  `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`.
- Working: the Q-Series widget/table is present near the top of
  `docs/dev-log/dashboard/index.html` and is sourced from
  `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`.
- In progress: this handover branch is docs-only and should not change package
  behavior or status cells.
- Not working / blocked: q4/q6/q8 admission and all non-Gaussian
  interval/coverage claims remain unfinished.

## Key Decisions & Rationale

- Tranche 2 is closed as a row-level evidence and status arc. It does not imply
  broad structured-RE support.
- Stability, interval feasibility, coverage, recovery, diagnostics, blocked,
  and planned states remain separate signals. A stable fit is not
  `inference_ready` unless interval and coverage gates pass for that exact row.
- No structured row should be called `supported` from current evidence.
- Gaussian q4/q6/q8 rows require admission gates before coverage: denominator
  retention, convergence, `pdHess`, gradient/profile warnings, boundary
  estimates, finite intervals, and interval-target maps must be explicit first.
- q8 does not inherit q4 evidence.
- Non-Gaussian rows remain recovery-only or rejection-contract work. Do not use
  REML, AI-REML, interval, coverage, or public support wording for them.
- Rose audit is mandatory before any tier/status claim. Fisher owns the
  inferential gates: coverage, MCSE, miss balance, denominator rules, and
  non-claims.
- Totoro is available as a fast no-queue CPU host alongside DRAC, but keep host
  provenance and denominators separated unless a run design explicitly allows
  pooling. Keep Totoro around 50 workers by default and under 100 unless the
  maintainer explicitly raises the cap.

## Files Created / Modified

This handover branch changes only:

```text
AGENTS.md
docs/dev-log/handover/2026-07-01-codex-handover.md
```

The broad Tranche 2 implementation, dashboard, tests, artifacts, and reports
are already on `main` through PR #684 and PR #685. Do not restage those files
from memory; inspect the current repo state first.

## Next Immediate Steps

1. Rehydrate and verify the clean checkpoint:
   ```sh
   git checkout main
   git pull --ff-only origin main
   git status --short --branch
   R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py
   ```
2. Recheck the Q-Series invariants before starting Tranche 3:
   ```sh
   R_PROFILE_USER=/dev/null Rscript --no-init-file -e '
   x <- read.delim("docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv", check.names=FALSE)
   ready <- x$interval_status == "inference_ready" | x$coverage_status == "inference_ready"
   stopifnot(nrow(x) == 104)
   stopifnot(sum(x$structure_provider != "ordinary" & x$fit_status == "supported") == 0)
   stopifnot(sum(ready) == 8)
   stopifnot(sum(x$dimension_pattern %in% c("q4", "q6", "q8") & ready) == 0)
   stopifnot(sum(x$family_class == "non_gaussian" & ready) == 0)
   '
   ```
3. Start Tranche 3 with a Rose/Fisher/Gauss/Noether orientation, not with
   coverage jobs:
   - read `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv`;
   - read q4 after-task reports named `docs/dev-log/after-task/2026-06-29-q-series-q4-*`;
   - read the q4 runner and summarizer scripts before editing them;
   - identify exact q4 cell IDs and interval targets for admission.
4. Freeze the q4 admission denominator contract before compute:
   - fit failure;
   - convergence;
   - `pdHess`;
   - gradient warnings;
   - profile warnings;
   - boundary estimates;
   - finite direct-SD intervals;
   - derived-correlation interval status.
5. Do not launch a q4 coverage grid until q4 admission passes at least:
   `pdHess >= 95%`, finite direct-SD intervals `>= 95%`, and retained failures
   in denominators.

## Blockers / Open Questions

- Which exact q4 provider/target should open Tranche 3? Choose from current
  dashboard evidence, not by analogy with q1/q2.
- Are derived correlations ready to be interval targets, or should q4 admission
  restrict itself to direct SD targets first? Noether and Fisher should decide
  before the TSV changes.
- Should Totoro be used for the first q4 diagnostic smoke, or should Nibi/Rorqual
  own the first formal run root? Grace should choose after checking reachable
  source checkouts and artifact paths.

## Gotchas & Failed Approaches

- `mission_control_ok` emits a long line. Redirect it to a temp file when you
  only need the first chunk.
- `git show --stat HEAD` on the Q-Series merge commit is enormous because PR
  #685 carried many artifacts. Use targeted paths and `git diff --name-only`
  instead of broad merge-stat output.
- Do not infer q4/q8 readiness from q1/q2 interval success. High-q failures are
  dominated by Hessian conditioning, finite interval rates, and target geometry.
- Do not import non-Gaussian recovery evidence as interval or coverage evidence.

## How to Resume

From the repo root in a new Codex session:

```text
Rehydrate from docs/dev-log/handover/2026-07-01-codex-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps. Confirm the Tranche 2 merged-main invariants first; then start Tranche 3 q4 admission before coverage. Rose audit is mandatory before any tier/status claim.
```

Codex should run the live R/TMB toolchain: real fits, `devtools::test()`,
`devtools::check()`, mission-control validation, simulations, and rendering.
Claude should own planning/prose review if the lane moves back into a
non-toolchain design or public-claim wording pass.
