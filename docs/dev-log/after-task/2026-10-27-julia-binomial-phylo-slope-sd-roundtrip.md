## 1. Goal

Complete the Binomial phylogenetic slope-only SD bridge slice for logit,
probit, and cloglog, including marginal simulation, save/reload behavior, and
an exact capability-ledger record.

## 2. Implemented

The Julia bridge now admits the slope-only tree route for all three tested
Binomial links. The marginal simulator supplies the observed slope as the
latent-field loading, and a uniquely identified slope target may omit
`coef = "x"`. The focused test checks fit convergence, same-data coefficient
and log-likelihood agreement with native TMB, tip-level SD predictions, and
logit save/reload prediction and marginal simulation.

The source-backed universe generator now marks only the exact Julia
probit/cloglog tree-backed `phylo_numeric_slope` cells as admitted. Other
non-logit Julia Binomial rows in the generated ledger remain blocked pending
row-specific review. Three focused-test records were linked to the exact Julia
logit, probit, and cloglog capability rows; no row was promoted to supported.

## 3a. Decisions and Rejected Alternatives

- Keep the implementation to one q1 tree-backed slope-only field. Do not open
  an intercept-plus-slope block or generalize the non-logit link admission.
- Keep the tree covariance on its existing raw branch-length scale. The live
  test reports the corresponding scale warning and compares both engines on
  that same supplied tree.
- Treat this as point-fit and output evidence. Interval coverage remains
  deferred under the active goal.
- Assumptions made without asking: the existing unique slope target is
  sufficient to omit `coef`; if users need multiple slope targets in this
  route, they must select the coefficient explicitly.

## 4. Files Touched

- `R/julia-bridge.R`
- `R/julia-simulate.R`
- `tests/testthat/test-julia-binomial-phylo-slope-sd.R`
- `tools/general-sd-regression/universe.py`
- `tools/general-sd-regression/tests/test_universe.py`
- `docs/dev-log/general-sd-regression/universe-contract.md`
- `docs/dev-log/general-sd-regression/required-rows.tsv`
- `docs/dev-log/general-sd-regression/required-universe.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-phylo-slope-sd-bridge-20261027/`
- `README.md`, `NEWS.md`, `docs/dev-log/internal-roadmap.md`,
  `docs/dev-log/known-limitations.md`,
  `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`
- `docs/dev-log/check-log.md` and
  `docs/dev-log/check-log.d/2026-10-27-julia-binomial-phylo-slope-sd-bridge.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md` and `arcs.md`
- This report

The exact R and paired Julia candidate heads and source hashes are recorded in
the evidence folder. Those hashes identify the tested files within the dirty
candidate worktrees.

## 5. Checks Run

- Live bridge command: `devtools::test(filter = "julia-binomial-phylo-slope-sd", reporter = "summary", stop_on_failure = TRUE)` with Julia 1.10.0 and the paired local DRM.jl candidate. Exit 0; 30 expectations passed and one live Julia bridge test ran. The fixed-seed fixture covers logit, probit, and cloglog; only logit checks save/reload and marginal simulation.
- Universe tests: `python3 -m unittest discover -s tools/general-sd-regression/tests`. **33 tests passed** in 39.622 seconds.
- Regenerated the capability rows with `python3 tools/general-sd-regression/universe.py`; the frozen denominator remains 19,118 rows.
- Evidence integrity: `python3 tools/general-sd-regression/reconcile_evidence.py` passed with 19,118 candidate rows, 75 linked rows, 19,043 unlinked rows, and 95 evidence records.
- `Rscript -e 'pkgdown::check_pkgdown()'` exited 0 and found no problems. Existing Pandoc `--mathml` deprecation warnings remain.
- `git diff --check` passed on the bridge, simulator, focused test, universe source and tests, contract, generated rows, and evidence ledger.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R <report>` passed; `closeout.py check <report>` passed; the prose check reported zero findings.
- A combined `pkgdown::check_pkgdown(); pkgdown::build_site()` process did not finish its site build and remained idle for more than seven minutes; it was stopped. No rendered-site result is claimed.
- No full `devtools::test()`, `R CMD check`, or package release check was run.

## 6. Tests of the Tests

The fit-free admission test accepts logit, probit, and cloglog, and rejects
cauchit, a wrong coefficient selector, and an intercept-plus-slope phylogenetic
block. Earlier runs exposed the stale link allowlist, missing slope loading in
simulation, and an overly strict coefficient-selector check. After those fixes,
the live test exercises all three fitted links, compares each to native TMB,
and checks target predictions. The separate universe test asserts that only
the two probit/cloglog phylogenetic-slope rows escape the general blocked-link
status; the remaining non-logit Binomial ledger rows stay blocked pending
route-by-route reconciliation.

## 7a. Issue Ledger

`gh issue list --state open --search 'Binomial phylogenetic slope SD Julia bridge' --limit 10`
returned only the general test-sweep and Phase 18 issues, with no exact issue
for this bridge slice. No issue was opened, changed, or closed.

## 8. Consistency Audit

The formula remains `phylo(0 + x | species, tree = tree)` with
`sd(species, level = "phylogenetic") ~ z`. The tested latent slope SD is
`exp(alpha_0 + alpha_1 z)` on the Binomial link scale. README, NEWS, roadmap,
known limitations, formula grammar, and the formula vignette describe this as
a narrow point-recovery route and retain the unverified-block and
no-calibration boundaries. The universe contract records the exact link
exception without admitting general probit/cloglog support. The scoped status
search was:

```text
rg -n 'Binomial.*phylo.*slope|phylogenetic.*slope.*Binomial|phylo\(0 \+ x \| species\)|slope-only.*Binomial' README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd
```

**Memory receipt:** `route.py` found no candidate-worktree LOAD-FIRST
manifest. Graft was unavailable in this checkout. The lane-ownership lesson
in `MEMORY.md` says preflight reports activity while a lease reserves paths;
that shaped the scoped lease used here. No unrelated candidate edits were
reverted.

**Golden Set:** not run because this slice did not touch a known-mistake
class.

## 9. What Did Not Go Smoothly

The first logged live run completed its assertions, but the zsh wrapper then
failed because it assigned to zsh's reserved read-only variable `status`. The
corrected rerun exited 0 and replaced the log. The site build stalled after
the standalone pkgdown check; the check was rerun separately and passed.

## 10. Known Residuals

- This is one slope-only tree-backed provider layout with one synthetic
  fixture per link. It does not cover a phylogenetic intercept-plus-slope
  block, other structured providers, or general Binomial non-logit support.
- The SD estimates have point-recovery checks only. No profile, bootstrap, or
  interval-coverage claim is made.
- The Julia implementation is a development candidate requiring the paired
  local source checkout. No release or full-suite claim is made.
- Some non-logit Binomial routes may be implemented in Julia while their
  generated ledger rows remain blocked by the family-level link rule. This
  slice reconciles only the phylogenetic numeric-slope rows; neighboring rows
  need their own evidence review.
- Full pkgdown site rendering remains incomplete because the build stalled.
- The broad goal remains open: most rows in the 19,118-row universe remain
  unlinked or unreviewed.

## 11. Team Learning

An exact fitted route can invalidate a blanket base-link blocker for one
capability row without supporting the link across the family. Keep that
exception in the source generator and its regression test, and leave adjacent
rows blocked until separately exercised.

## 12. Cross-Product Coverage

- **Covers:** native TMB and the Julia bridge for the Binomial location
  phylogenetic slope-only SD route with logit, probit, and cloglog links;
  tip-level SD prediction for all three; logit save/reload and seeded
  marginal simulation.
- **Does NOT cover:** intercept-plus-slope phylogenetic blocks, matrix-input
  or other providers, spatial and phylogenetic-interaction combinations,
  other response families, general probit/cloglog Binomial effects, interval
  calibration, full-package checks, release, or the full programme.
