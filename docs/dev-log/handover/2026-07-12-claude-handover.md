# Handover to Claude — missing-response arc finished, 2026-07-12

Meta: Codex → Claude · repository `drmTMB` · source `main` at
`d06bf0159e57d44b28f75656f977c838e0262041` · handover branch
`handover/2026-07-12-claude` · parent issue #761.

## Mission and outcome

The MR-T0–MR-T7 missing-response arc is complete. PRs #762 and #765–#771 are
squash-merged. All 18 fitted response routes have independent G3
recovery-verified missing-response evidence; the generated ledger and live
runtime oracle both report 18 verified and zero G0–G2. No route remains to
implement in this arc.

The public capability article now preserves both views Shinichi requested:

1. the generated 18-route missing-response execution board; and
2. the 18-family whole-package map covering dpars, fixed/random effects,
   structured providers, REML, interval maturity, missing responses, and
   predictor-side `mi()`.

G3 is deliberately bounded: fixed-seed 25% MCAR recovery of every fitted dpar
for the named route and effect structure. It is not G4/G5 coverage, blanket
random/structured support, MNAR, response plus `mi()`, or non-Gaussian REML.

## Mission control

| Workstream | State | Durable evidence | Claude action |
| --- | --- | --- | --- |
| MR-T0 ledger foundation | DONE, merged #762 | generated ledger, transitions, runtime oracle | none |
| MR-T1 legacy six | DONE, merged #765 | six independent G2/G3 route suites | none |
| MR-T2 continuous four | DONE, merged #766 | guarded Student/skew-normal/lognormal/Gamma routes | none |
| MR-T3 boundary two | DONE, merged #767 | Tweedie and zero-one-beta atom/sentinel evidence | none |
| MR-T4 encoded two | DONE, merged #768 | beta-binomial whole-row and ordinal-level evidence | none |
| MR-T5 truncated NB2 | DONE, merged #769 | guarded density plus truncation normalization | none |
| MR-T6 mixtures three | DONE, merged #770 | separate ZIP/ZINB2/hurdle evidence | none |
| MR-T7 certification | DONE, merged #771 | final local gates and three independent reviews | none |
| final-main 3-OS CI | GREEN | run 29189567500 | none |
| final-main pkgdown | GREEN and live | run 29190476542; live article verified | none |
| final sanitizer matrix | GREEN | run 29189568352; clang-ASAN, clang-UBSAN, and GCC-ASAN passed | none |
| parent issue #761 | CLOSED, completed | final evidence comment 4951033349 | none |
| CRAN 0.5.0 | EXTERNAL / separate track | `v0.5.0` frozen at `095409c0` | wait for CRAN; do not conflate with this arc |

## Exact verification evidence

- capability generator: 30/30 outputs current;
- generator tests: 6/6;
- runtime oracle: 18 routes, 18 verified, zero G0–G2;
- repaired inventory guards: 18/18;
- combined missing-data suite: 1,314 pass, two known beta-binomial warnings,
  two unavailable-Julia skips, and no empty test;
- final `devtools::test()` under `NOT_CRAN=true`: 37,542 pass, 62 known
  warnings, 24 unavailable-Julia skips, zero failures, 1,507.1 seconds;
- genuine `devtools::check(args = "--as-cran")` with explicit
  `env_vars = c(NOT_CRAN = "false", ...)`: 0 errors, 0 warnings, 0 notes,
  5 minutes 51.8 seconds;
- full `pkgdown::check_pkgdown(); pkgdown::build_site();
  pkgdown::check_pkgdown()`: clean;
- final-main macOS, Ubuntu, and Windows R-CMD-check:
  <https://github.com/itchyshin/drmTMB/actions/runs/29189567500>;
- final-main pkgdown build/deploy:
  <https://github.com/itchyshin/drmTMB/actions/runs/29190476542>;
- live article:
  <https://itchyshin.github.io/drmTMB/articles/capability-and-limits.html>;
- sanitizer matrix:
  <https://github.com/itchyshin/drmTMB/actions/runs/29189568352>;
- independent repaired-tree verdicts: Rose/Noether DONE, Fisher/Curie DONE,
  Grace/Pat DONE.

The full repair history and claim audit are in
`docs/dev-log/after-task/2026-07-12-mr-t7-missing-response-certification.md`.

## Critical decisions and gotchas

- `v0.5.0` remains frozen at `095409c0`; never move that tag for this
  development arc.
- CRAN resubmission/acceptance is an external release track. Do not claim the
  package is on CRAN until CRAN confirms it.
- The earlier R-hub `valgrind`/`rchk` failures are known dependency/TMB
  framework noise by maintainer direction. Do not re-chase them. The requested
  final sanitizer evidence is only clang-ASAN, clang-UBSAN, and GCC-ASAN.
- Shell `NOT_CRAN=false` was insufficient for the genuine check because
  `devtools` supplied its own default. Pass `NOT_CRAN="false"` through
  `devtools::check(..., env_vars = ...)` explicitly.
- The first three reviewer passes were NOT DONE. They found stale estimator
  citations, two vacuous family-inventory tests, stale allow-list/G0 prose, a
  missing public 18-family view, and non-final-tree check evidence. All were
  repaired before the three DONE re-reviews.
- The capability source of truth is generated. Do not hand-edit the generated
  board/map without changing and testing `tools/capability_ledger.py`.
- No new public function, formula grammar, likelihood parameterization, or
  G4/G5 promotion was authorized.

## Paths modified in the July 11–12 landed window

This list is the complete `095409c0..d06bf015` path delta. It includes the
separate incoming-pretest release fix that landed during the same window as
well as MR-T0–MR-T7.

```text
.Rbuildignore
.github/workflows/R-CMD-check.yaml
AGENTS.md
CRAN-SUBMISSION
DESCRIPTION
NEWS.md
R/drmTMB.R
R/methods.R
R/missing-data.R
README.md
ROADMAP.md
cran-comments.md
docs/design/149-missing-data-design.md
docs/dev-log/2026-07-11-missing-response-all-families-ultra-plan.md
docs/dev-log/after-task/2026-07-11-cran-incoming-pretest-resubmission-fix.md
docs/dev-log/after-task/2026-07-11-mr-t0-capability-ledger.md
docs/dev-log/after-task/2026-07-11-mr-t1-missing-response-legacy-six.md
docs/dev-log/after-task/2026-07-11-mr-t2-continuous-missing-response.md
docs/dev-log/after-task/2026-07-11-mr-t3-atom-boundary-missing-response.md
docs/dev-log/after-task/2026-07-11-mr-t4-encoded-missing-response.md
docs/dev-log/after-task/2026-07-11-mr-t5-truncated-missing-response.md
docs/dev-log/after-task/2026-07-11-mr-t6-count-mixture-missing-response.md
docs/dev-log/after-task/2026-07-11-v0.5.0-independent-cran-readiness.md
docs/dev-log/after-task/2026-07-12-mr-t7-missing-response-certification.md
docs/dev-log/check-log.md
docs/dev-log/dashboard/README.md
docs/dev-log/dashboard/capability-census/_widget_data.json
docs/dev-log/dashboard/capability-ledger/README.md
docs/dev-log/dashboard/capability-ledger/cells.tsv
docs/dev-log/dashboard/capability-ledger/evidence.tsv
docs/dev-log/dashboard/capability-ledger/schema.json
docs/dev-log/dashboard/capability-ledger/tranches/MR-T0.md
docs/dev-log/dashboard/capability-ledger/tranches/MR-T1.md
docs/dev-log/dashboard/capability-ledger/tranches/MR-T2.md
docs/dev-log/dashboard/capability-ledger/tranches/MR-T3.md
docs/dev-log/dashboard/capability-ledger/tranches/MR-T4.md
docs/dev-log/dashboard/capability-ledger/tranches/MR-T5.md
docs/dev-log/dashboard/capability-ledger/tranches/MR-T6.md
docs/dev-log/dashboard/capability-ledger/transitions.tsv
docs/dev-log/dashboard/capability-surface.html
docs/dev-log/dashboard/capability-surface.md
docs/dev-log/dashboard/estimator-surface-conformance.tsv
docs/dev-log/handover/2026-07-12-missing-response-arc-closeout.md
docs/dev-log/known-limitations.md
src/drmTMB.cpp
tests/testthat.R
tests/testthat/helper-missing-response.R
tests/testthat/test-animal-relmat-gaussian.R
tests/testthat/test-missing-data-capability-gate.R
tests/testthat/test-missing-data-control.R
tests/testthat/test-missing-response-beta.R
tests/testthat/test-missing-response-binomial.R
tests/testthat/test-missing-response-biv-gaussian.R
tests/testthat/test-missing-response-boundaries.R
tests/testthat/test-missing-response-boundary.R
tests/testthat/test-missing-response-continuous.R
tests/testthat/test-missing-response-count-mixtures.R
tests/testthat/test-missing-response-encoded.R
tests/testthat/test-missing-response-family-gate.R
tests/testthat/test-missing-response-gaussian.R
tests/testthat/test-missing-response-nbinom2.R
tests/testthat/test-missing-response-poisson.R
tests/testthat/test-missing-response-recovery.R
tests/testthat/test-missing-response-truncated-nbinom2.R
tests/testthat/test-profile-targets.R
tools/capability_ledger.py
tools/check-capability-runtime.R
tools/tests/test_capability_ledger.py
vignettes/capability-and-limits.Rmd
vignettes/includes/capability-ledger-family-map.md
vignettes/includes/capability-ledger-missing-response.md
vignettes/missing-data.Rmd
```

This handover branch itself modifies only `AGENTS.md` and this file.

## Landing state

| State | Item | Why / resume command |
| --- | --- | --- |
| LANDED | MR-T0–MR-T7 implementation and certification | merged to `main` at `d06bf015`; no resume needed |
| CARRIED-OVER, user-owned | 24 untracked post-CRAN drafts, shard logs, Ayumi files, recovery probes, and `scratchpad/function-map-draft/` | pre-existing and outside this arc; preserve exactly; inspect with `git status --short` only if Shinichi assigns that work |
| CARRIED-OVER, historical archive | handoff gate reported 354 commits across numerous old local branches | pre-existing local branch archive, unrelated to MR-T0–MR-T7; do not push, merge, delete, or resume en masse |
| CARRIED-OVER, docs-only | `handover/2026-07-12-claude` | handover PR intentionally left open for human review; resume with `gh pr view --web` after locating its PR URL in this file or GitHub |

The mandatory `/Users/z3437171/shinichi-brain/tools/handoff_gate.sh` was run
before this document was written. It failed only on the two declared
pre-existing classes above: the 24 untracked files and historical local branch
archive. Current `main` itself was synchronized with `origin/main` before this
branch was cut.

## What is working, in progress, and blocked

- Working: implementation, tests, ledger, runtime oracle, public docs, live
  pkgdown, and final-main three-OS CI.
- In progress: nothing inside the missing-response arc.
- Blocked: nothing inside the missing-response arc.
- External: CRAN's decision on 0.5.0. The submit button and any reply remain
  Shinichi's.

## Next immediate steps for Claude

1. Rehydrate this file and the current `AGENTS.md` snapshot.
2. Treat the missing-response arc as closed; do not reopen implementation or
   promote G4/G5 without a new goal.
3. Check the external CRAN state only when Shinichi asks or forwards a new CRAN
   message. Keep any CRAN repair on an isolated release-fix branch.
4. If planning the next missing-data arc, use the generated capability surface
   as the systematic checklist. Candidate work must be separately scoped; this
   handover authorizes no new implementation.
5. Preserve all declared untracked and historical local state.

## Claude versus Codex roles

Claude should own the next bounded planning, prose, or pure-logic slice when
Shinichi requests it. Codex should own live R/TMB fits, complete package checks,
sanitizers, and rendered-site verification. The tools run sequentially in this
repository: do not assume another live agent is editing concurrently.

## One-command resume

```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-12-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps."
```
