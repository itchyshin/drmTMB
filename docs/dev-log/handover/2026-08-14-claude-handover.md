# Session Handover: native reader contracts to external-oracle validation

Meta: 2026-08-14 · from Codex · target Claude · handover-only branch
`codex/2026-08-14-claude-handover-reader` from final `origin/main`
`6637b9f016e368705a05e3ece15ddec9f227e809`.

## Critical Context

The native-reader contract arc is **DONE and landed**. PR #1027 and PR #1028
are merged, their exact branch heads are ancestors of `origin/main`, and the
exact post-merge main run `31839487304` is green. Do not reopen that arc merely
because its retained branches still exist.

The user is also handing the response-missingness formula lane to Claude. That
is a distinct implementation/evidence programme with its own handover:
`docs/dev-log/handover/2026-08-14-claude-handover-response-missing-formulas.md`
on `codex/response-missing-formula-surface` at actual pushed head `63ee00c43`.
Do not absorb its 15-cell univariate queue, bivariate harness, or REML design
into this reader-validation lane.

The next high-leverage reader/trustworthiness direction is the
**External-Oracle + Real-Analysis Gauntlet**, joining issue #859 with the
bounded one-off comparison work in issue #60. It is **OWED as a fresh Ultra
Plan, not pre-authorized implementation**. Orient, reconcile live ownership,
present the requested actions and gates, and wait for Shinichi's explicit
approval before Phase 3 execution.

## Goals / Mission

Make established native `drmTMB` workflows trustworthy from a reader's seat:

1. preserve the newly landed public reader contracts;
2. test overlapping models against independent `lme4` and `glmmTMB` oracles;
3. exercise realistic data-to-interpretation workflows rather than only
   package-authored smoke fixtures; and
4. turn every discrepancy into a focused repair, actionable unsupported
   boundary, or documented limitation without adding models or estimands.

## What Was Accomplished

### PR #1027 — reader corpus and private-slot removal

- Added a complete 37-vignette manifest, exact contributor permissions, and
  exact reader exceptions.
- Added a fail-closed linter with 21 adversarial expectations.
- Migrated 13 reader articles from private fit slots to exported diagnosis and
  extraction paths.
- Merged branch head: `c1a756ee9`.

### PR #1028 — stable native schemas and scientific journeys

- Documented minimum reader contracts for `check_drm()`, `summary()`,
  `ranef()`, `fitted()`, and `predict_parameters()`.
- Reused one fixture set for ten native reader journeys and added 53 distinct
  scientific interpretation assertions.
- Passed 34 schema expectations, the complete native test suite, pkgdown, and
  a fresh source-tarball `R CMD check --as-cran` with 0 errors, 0 warnings, and
  the expected new-submission NOTE.
- Passed a fresh D-43 panel 3/3 `DONE` with no unresolved P0-P2.
- Merged branch head: `18a64b1fe`; final merge/main commit: `6637b9f016e`.

The exact post-merge main workflow run `31839487304` passed its required
`os-matrix` and `ubuntu-latest (release)` jobs. The exact PR #1028 head run
`31820837703` also passed macOS, Ubuntu, and Windows.

## Current Working State

| Classification | Surface | Current truth |
| --- | --- | --- |
| DONE | Native reader contract | PRs #1027 and #1028 merged through `6637b9f016e`; main CI green |
| OWED | External-oracle + real-analysis plan | Scope issues #859 and #60 into two reviewable PRs; implementation requires fresh approval |
| PROTECTED | Response-missing formula surface | Separate Claude handover on pushed branch `codex/response-missing-formula-surface@63ee00c43` |
| PROTECTED / CARRIED-OVER | Joint-MI two-predictor work | Local `codex/joint-mi-two-predictor@cbbf380bd`, 3 ahead / 12 behind `origin/main`; unpushed and owned elsewhere |
| PROTECTED | Primary checkout | Dirty `claude/handover-freshness-0718`; never clean, stage, rebase, or use as the implementation base |
| PROTECTED | Release, MSPL, calibration, Julia | Separate lanes and deferred boundaries; no work owed by this handover |

## Key Decisions & Rationale

- **Use independent installed-package oracles.** Issue #859 identifies shipped
  `lme4` and `glmmTMB` corpora that target profile pathologies, matched model
  agreement, and old-fit compatibility. They test drmTMB against evidence it
  did not manufacture itself.
- **Do not vendor comparator data.** `glmmTMB` is AGPL-3. Read installed
  fixtures through `find.package()` under `skip_if_not_installed()`; first
  inspect package dependency and CI policy before changing `Suggests`.
- **Keep comparisons scale-aligned.** Explicitly convert `sigma`, variance,
  NB2 size/theta, and meta-analysis heterogeneity notation. A numerical
  mismatch on incomparable scales is not evidence.
- **Use deterministic one-off fits first.** No simulation or remote campaign is
  authorized. If any proposed run is expected to exceed 30 minutes, apply the
  estimate/pre-run/approval rule before starting it.
- **No broad redesign.** The reader arc intentionally stabilized existing
  verbs. New discrepancies should become surgical fixes, tested errors, or
  visible limitations—not a reporting helper, new family, likelihood, formula
  grammar, or estimand.
- **Julia stays post-0.7.** Neither this handover nor the oracle gauntlet audits
  or repairs Julia routes.

## Files Created / Modified by the Landed Reader Arc

### PR #1027

- `inst/reader-contracts/private-access-exceptions.csv`
- `inst/reader-contracts/vignette-manifest.csv`
- `tests/testthat/test-reader-vignette-contracts.R`
- `tools/check-reader-contracts.R`
- `vignettes/animal-models.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/convergence.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/implementation-map.Rmd`
- `vignettes/meta-analysis.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/model-selection.Rmd`
- `vignettes/phylogenetic-models.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/relmat-known-matrices.Rmd`
- `vignettes/spatial-models.Rmd`
- `vignettes/which-scale.Rmd`

### PR #1028 and closeout

- `R/check.R`
- `R/predict-parameters.R`
- `R/reader-contracts.R`
- `docs/dev-log/after-task/2026-08-14-native-reader-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/plan-actual/2026-08-14-native-reader-contract.md`
- `man/check_drm.Rd`
- `man/native_reader_contracts.Rd`
- `man/predict_parameters.Rd`
- `tests/testthat/test-reader-journeys.R`
- `tests/testthat/test-reader-public-schema.R`
- `tools/audit-b2-q6-serial-proof-cohort.R`
- `tools/run-reader-workflow-audit.R`

### This transfer

- `docs/dev-log/handover/2026-08-14-claude-handover.md`

## Landing State

The global handoff gate did not exit cleanly because the protected primary
checkout is dirty and it counts hundreds of unpushed commits across unrelated
local branches. That is global coordination evidence, not permission to
reconcile foreign work. The reader deliverable itself is landed and verified.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `origin/main@6637b9f016e` | yes | yes | #1027 + #1028 merged | LANDED |
| `codex/native-reader-contracts@c1a756ee9` | yes | yes | #1027 merged | LANDED; retained branch |
| `codex/native-reader-contract-schemas@18a64b1fe` | yes | yes | #1028 merged | LANDED; retained branch |
| `codex/2026-08-14-claude-handover-reader` | pending this handover commit | pending | pending | CARRIED-OVER handover only; do not merge without review |
| `codex/response-missing-formula-surface@63ee00c43` | yes | yes | none | PROTECTED; separate Claude handover |
| `codex/joint-mi-two-predictor@cbbf380bd` | yes | no | none | CARRIED-OVER / PROTECTED foreign work |
| Dirty primary `claude/handover-freshness-0718` | mixed | mixed | unrelated | PROTECTED; never clean or stage |

## Mission-Control Summary

| Lane | State | What is true now | Next by leverage |
| --- | --- | --- | --- |
| Native reader contracts | DONE | Public post-fit schemas, private-slot linter, 10 scientific journeys landed and green | Preserve as regression baseline |
| External validation | OWED plan | Issues #859 and #60 open; no implementation authorized by this transfer | Ultra Plan two PRs: oracle harness, then real-analysis workflows |
| Response-missing formulas | SEPARATE CLAUDE HANDOVER | 185 validated cells; 15 univariate ML cells remain per its own handover | Follow its own prompt and branch only |
| Joint MI | PROTECTED | Three local commits ahead of main, unpushed | Reconcile only under that lane's authority |
| CRAN / MSPL / Julia / calibration | DEFERRED OR SEPARATE | No claim or release action owed here | Do not touch |

## Next Immediate Steps — OWED Only

1. Run lane preflight, fetch/prune, and reconcile this handover against live git
   and the coordination board. Classify every item as `OWED`, `DONE`,
   `RETRACTED`, or `PROTECTED` before editing.
2. Verify `origin/main` still contains merge heads `c1a756ee9` and `18a64b1fe`
   and inspect any main CI newer than run `31839487304`.
3. Read issues #859 and #60 plus
   `/Users/z3437171/Dropbox/Github Local/Shinichi/memory/lane-notes/FOR-DRMTMB-2026-07-28-bolker-brief.md`.
4. Use the `ultra-plan` skill for a fresh, bounded plan. The recommended shape
   is two PRs:
   - PR 1: non-vendored `lme4`/`glmmTMB` oracle harness, pathological profile
     fixtures, matched-model agreement, and old-fit compatibility boundary;
   - PR 2: 8-10 real data-to-interpretation workflows, resulting focused
     repairs, reader article/design note, and closeout evidence.
5. Present the plan, dependency changes, expected checks, and any run estimated
   above 30 minutes for explicit approval. Do not enter implementation before
   approval.
6. Once approved, start from a fresh worktree off then-current `origin/main`.
   Keep the response-missing and joint-MI paths fenced and use small,
   issue-linked PRs.

## Blockers / Open Questions

- Confirm whether `lme4` and `glmmTMB` are already accepted optional test
  dependencies in the package/CI policy before changing `Suggests`.
- Decide which installed fixtures are stable enough to be load-bearing versus
  diagnostic-only; upstream internal object names can drift across releases.
- Define scale conversions and tolerances before observing comparator results.
- The external corpora do not cover `rho12 ~ predictors`, random-effect scale
  modelling, or every structured covariance route. Preserve simulation-only
  boundaries rather than forcing a comparator.
- The response-missing and joint-MI lanes actively own missing-data files.
  Re-measure exact files before any edit; overlap requires Shinichi's decision.

## Gotchas / Failed Approaches

- Do not use the protected primary checkout as a work base. Create a fresh
  worktree from fetched `origin/main`.
- Do not infer readiness from retained branch names: both reader branches are
  already merged and DONE.
- The response-missing handover's metadata names pre-handover implementation
  head `e376eea32`; the actual pushed branch head including its handover commit
  is `63ee00c43`.
- Reader prose in `R/methods.R` invalidated a capability receipt that pins the
  entire file even though the authenticated model surface was unchanged. The
  successful repair restored `R/methods.R` byte-for-byte and moved prose to
  `R/reader-contracts.R`. Do not redo or casually disturb that receipt.
- Retargeting a PR base did not automatically trigger the desired workflow.
  The prior lane verified exact tree equivalence and dispatched exact-head CI;
  use commit-specific evidence rather than a nearby green badge.
- The global handoff gate reports unrelated dirty/unpushed state. Never answer
  it by pushing, cleaning, rebasing, or staging foreign branches.
- This handover branch initially tracks `origin/main`; push it explicitly with
  `git push -u origin codex/2026-08-14-claude-handover-reader`, never bare
  `git push`.

## How to Resume

Claude should work in a fresh worktree, not the primary checkout. First verify
whether its environment can compile and run the R/TMB package. If not, Claude
can complete orientation, design, prose, and pure-logic work and route exact
live-toolchain verification back to Codex/CI rather than guessing.

```sh
cd '/Users/z3437171/Dropbox/Github Local/drmTMB'
bash ~/shinichi-brain/tools/lane_preflight.sh .
git fetch --prune origin
git status --short --branch
git rev-parse origin/main
git merge-base --is-ancestor c1a756ee9 origin/main
git merge-base --is-ancestor 18a64b1fe origin/main
```

Safe first package checks after creating the fresh worktree:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-reader-public-schema.R"); testthat::test_file("tests/testthat/test-reader-journeys.R")'
R_PROFILE_USER=/dev/null Rscript --no-init-file tools/check-reader-contracts.R
```

To inspect the protected unpushed joint-MI lane without mutating it:

```sh
git -C '/Users/z3437171/Dropbox/Github Local/drmTMB-joint-mi' status --short --branch
```

**Paste-ready prompt:**

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-14-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
