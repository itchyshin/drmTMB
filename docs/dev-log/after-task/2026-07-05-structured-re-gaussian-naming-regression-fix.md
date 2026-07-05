# After Task: Structured-RE Gaussian Naming Regression Fix

Meta: 2026-07-05 · Claude takeover session · branch `drmtmb/fix-family-conventions`
(fix commits `ce4b8b97`, `e87ce23c`) · draft PR #730

## 1. Goal

Opening draft PR #730 ran the ubuntu R-CMD-check (CI run 28740033018), which
**failed with 122 test failures** — a regression the branch carried but had never
surfaced because prior sessions ran only focused tests, never the full suite. The
goal of this slice: root-cause the regression, fix it with the smallest correct
change, restore the full suite to green, and record it honestly.

## 2. Implemented

Two model-type-gated fixes plus one stale-test update:

- `split_tmb_sdpars` (R/drmTMB.R): the bivariate branch now lumps all structured
  location-scale SDs into the flat `mu` block for `biv_gaussian`, while univariate
  Gaussian and non-Gaussian families keep per-dpar blocks (`sigma`/`nu`/`zi`/`hu`).
- `structured_mu_random_effect_key` (R/drmTMB.R): now takes `model_type` and
  returns the generic `_mu` block for Gaussian/biv_gaussian, endpoint-aware names
  for non-Gaussian. Threaded through all three call sites
  (`split_tmb_random_effects`, `phylo_mu_contribution`, `structured_effects_table_row`).
- `tests/testthat/test-structured-re-q2-rejections.R`: updated to the restored
  flat-`mu` contract (`fit$sdpars$mu` with endpoint-encoded keys; `sd:mu:sigma1:`
  targets), matching the q4 tests and the served dashboard ledger.
- `tests/testthat/test-nbinom2-location-scale.R`: updated one stale rejection
  message (separate root cause; see §3a).

Result: full local test suite green (0 failures), down from 122.

## 3a. Decisions and Rejected Alternatives

**Root cause.** Two structured-RE naming changes made during the q-series
non-Gaussian admit work were model-type-blind:

- `fd9d8dc8` changed the biv_gaussian `split_tmb_sdpars` branch from
  `out$mu <- c(out$mu, sd_phylo)` (flat) to a per-endpoint loop. Correct for
  non-Gaussian; wrong for biv_gaussian, which broke 122 consumer tests
  (summary, profile-targets, per-provider Gaussian, phase18) that read `sdpars$mu`.
- `fd9d8dc8` + `abf4ff5c` made `structured_mu_random_effect_key` endpoint-aware to
  support `_sigma`/`_zi`/`_nu`/`_hu` blocks for non-Gaussian families, but it also
  caught Gaussian sigma-only fits, renaming `spatial_mu` -> `spatial_sigma` and
  breaking `ranef(fit, "<provider>_mu")` lookups.

**Why the flat `mu` contract for biv_gaussian, not per-endpoint.** The established
contract — encoded by ~30 test files, the core extractors, and the checked-in
dashboard (`structured-re-q4-profile-target-bridge-map.tsv` records
`sd:mu:sigma1:phylo(...)`) — lumps all structured biv location-scale SDs into
`$mu`. Only one test (the q2 scale-only file) had adopted per-endpoint `$sigma1`,
an incomplete migration. Restoring the flat contract and updating that one test
touched the fewest files and made the suite internally consistent. Completing a
per-endpoint migration instead would have required rewriting ~40 assertions plus
dashboard evidence.

Rejected alternatives:

- Unconditional `out$mu` for all model types: rejected — it broke the tested
  non-Gaussian per-endpoint contract (`test-nongaussian-structured-boundary.R`).
- Per-endpoint everywhere (complete the migration): rejected — largest churn,
  contradicts the dashboard and q4 tests.
- Leaving the branch red for Codex: the user directed a local fix this session.

**nbinom2 stale test (separate).** `sigma ~ phylo(1 | species)` (intercept-only)
on nbinom2 is correctly rejected, but the branch's own `4898359c` added
`validate_count_structured_sigma_term`, replacing the pre-branch generic
"Structured non-Gaussian paths" deferral with a more specific
"intercept-plus-one-slope" message. The `test_that` intent ("keeps planned
neighboring routes closed") is satisfied — the route stays closed; only the
expected message string was stale. Updated the message, not the behavior.

## 3b. Mathematical Contract

No likelihood, covariance, or parameter-transform change. This is a block-naming /
extractor-routing fix. The `biv_gaussian` structured SDs and their profile targets
keep the flat-`mu` naming they had on `main`; non-Gaussian structured SDs keep the
per-dpar naming the branch introduced.

## 4. Files Touched

- `R/drmTMB.R` (split_tmb_sdpars branch gate; structured_mu_random_effect_key
  model_type gate + one call site)
- `R/methods.R` (structured_mu_random_effect_key call sites: phylo_mu_contribution,
  structured_effects.drmTMB, structured_effects_table_row signature)
- `tests/testthat/test-structured-re-q2-rejections.R`
- `tests/testthat/test-nbinom2-location-scale.R`

No `src/`, dashboard support-cell, ledger, or claim-surface file changed. Mission
Control truth is unchanged (94/104 / 8/104 / 0/104 / 10/104).

## 5. Checks Run

- `devtools::load_all()`: clean (no syntax errors).
- Focused verification (parallel local runs), before/after the fix:
  summary 18->0, profile-targets 44->0, phylo-gaussian 34->0,
  animal-relmat-gaussian 68->0, spatial-gaussian 30->0, phase18 x6 ->0,
  nbinom2-location-scale 2->0, structured-re-q2-rejections 0,
  structured-re-conversion-contracts (236) 0, nongaussian-structured-boundary 0,
  structured-effects 0.
- Full local suite (`run-full-suite.R`, silent reporter over all `test-*.R`):
  `total_fail=0 total_error=0` after the fix (the single red file in the
  pre-nbinom2-edit run was nbinom2, since resolved and re-confirmed).
- `git diff --check`: clean.

## 6. Tests of the Tests

Every edited assertion was set from **observed** engine output, not guessed: a
scale-only spatial fit was run and its `names(fit$sdpars)`, covariance summary
`from_sd_target`/`to_sd_target` captured before updating the q2 test; the nbinom2
message was taken from the live `cli_abort` string.

## 7a. Issue Ledger

No GitHub issue opened/closed. Fix commits `ce4b8b97`, `e87ce23c` pushed to
`drmtmb/fix-family-conventions`; draft PR #730 re-runs CI on push.

## 8. Consistency Audit

- **Rose:** the fix restores the established main/dashboard `sd:mu:` contract; no
  claim-surface, ledger, or Mission Control change. The q2 test now matches the
  dashboard rather than diverging from it.
- **Fisher:** no inference/coverage/support boundary moved; point-fit/extractor
  behavior for q2 scale-only is unchanged, only the SD block label.
- **Noether/Gauss:** no likelihood or transform change; block naming is now
  model-type-consistent (Gaussian generic `_mu`; non-Gaussian endpoint-aware).
- **Grace:** full suite green locally; ubuntu CI re-run in flight on push.

## 9. What Did Not Go Smoothly

The first fix attempt (route mu-endpoints to `$mu`, keep sigma per-endpoint) was
based on incomplete evidence and broke the q4 all-four tests, which expect sigma
in `$mu`. Reading the q4 tests and the dashboard revealed the true established
contract (everything in `$mu` for biv_gaussian), and a parallel subagent found the
independent ranef `structured_mu_random_effect_key` half of the regression. The
final fix is model-type-gated on both paths and preserves the non-Gaussian
contract that the first attempt would also have broken.

## 10. Known Residuals

- The definitive cross-check is the ubuntu CI full-suite run on the pushed head;
  confirm green on #730.
- The Day-1 triage after-task and check-log were written before this regression
  was known; this report is the correcting record. The 94/104 practical surface
  and the 10-row post-v1 triage are unaffected.

## 11. Team Learning

Focused-tests-only hid a broad regression for many commits; the full suite (or the
ubuntu CI it mirrors) must gate a branch before it is called clean. The regression
had a single shape — a naming migration that was correct for the new non-Gaussian
families but silently changed the Gaussian contract — and appeared in two
independent functions (`split_tmb_sdpars`, `structured_mu_random_effect_key`). The
Rose principle held: finding one model-type-blind site meant looking for the second.
