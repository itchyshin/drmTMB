# After Task: Live Julia Bernoulli Phylogenetic SD Bridge

## 1. Goal

Exercise predictor-dependent phylogenetic SD fitting through the R-to-Julia bridge on independent synthetic Bernoulli data, then verify public SD outputs against native TMB.

## 2. Implemented

Added an opt-in live test to `tests/testthat/test-julia-binomial-phylo-sd.R`. It generates a 36-tip tree, rescales its height to one, assigns a continuous predictor across tips, and simulates Bernoulli responses from a predictor-dependent phylogenetic SD model. It fits the same formula with Julia and TMB and checks convergence, coefficient and log-likelihood agreement, slope recovery within the existing 0.5 tolerance, and prediction/`sdpars` agreement with the fitted design. Production code and public formula syntax did not change.

## 3a. Decisions and Rejected Alternatives

### Mathematical contract

The test uses `log(tau_j) = alpha_0 + alpha_z * z_j` and `b ~ N(0, D K D)`. The tree is scaled to unit height so the raw phylogenetic covariance and its unit-diagonal correlation form have the same scale in this cross-engine comparison. The test does not change or normalize the package's general kernel convention.

No production-code or formula-language change was needed: the current candidate bridge already supports the tested target. The exploratory boundary fit was retained as a limitation rather than relaxed into a passing recovery condition.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-phylo-sd.R`
- `docs/dev-log/check-log.md`
- This report and its assessment record.

## 5. Checks Run

- `DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRMTMB_JULIA_TESTS=true JULIA_NUM_THREADS=4 JULIA_DEPOT_PATH='/private/tmp/codex-drmtmb-julia-depot:/Users/z3437171/.julia' OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd", reporter = "summary")'` — exit 0; one live Julia test ran, the focused bridge test passed, and the live bridge summary confirmed execution. Julia 1.10.0. Candidate source HEADs were drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`, both with uncommitted changes.
- `JULIA_DEPOT_PATH='/private/tmp/codex-drmtmb-julia-depot:/Users/z3437171/.julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. --startup-file=no -e 'using DRModels, Test; println("DRModels loaded; Julia ", VERSION); include("test/test_binomial_phylo_sd_regression.jl")'` from `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia` — 21/21 assertions passed, including the dense Laplace oracle and constant-SD equivalence checks.
- `git diff --check -- tests/testthat/test-julia-binomial-phylo-sd.R` — passed.
- On the seeded comparison, both engines converged to log likelihood `-727.834`; Julia estimated the SD intercept/slope as `-1.8677110`/`0.8296641` and TMB as `-1.8677110`/`0.8296643`. The generating values were `log(0.35) = -1.049822` and `0.55`: slope error `0.280` met the existing `0.5` tolerance, while intercept error `0.818` did not receive a recovery claim.
- A separate exploratory seed produced an extreme SD-boundary estimate in both engines. The realized low-SD group effects were compressed relative to truth, so that one draw is not evidence of an optimizer defect. It remains a warning that a converged fit is not recovery evidence by itself.

## 6. Tests of the Tests

The direct Julia test compares the fitted Laplace objective with an independent dense numerical oracle. The live R bridge test uses a generated data set, checks the neighbouring native-TMB route, aligns tip predictions to the declared tip order, and verifies that public predictions agree with the coefficient design matrix. The deterministic seed keeps the recovery check repeatable.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --state open --search 'Bernoulli phylogenetic SD Julia bridge' --json number,title,url --limit 20` returned `[]`. No issue was changed.

## 8. Consistency Audit

The test exercises the existing `sd(species, level = "phylogenetic") ~ z` syntax. The status inventory still labels Julia Bernoulli SD as candidate-only and broad family coverage and interval calibration as open. Searches run:

```sh
rg -n -i 'sd\(.*\)|Bernoulli|calibrat|Julia' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
rg -n 'phylo.*(Bernoulli|binomial)|binomial.*phylo|sd\(.*level.*phylogenetic' tests/testthat
```

No user-facing support claim, example, formula grammar, generated reference page, or pkgdown navigation changed, so no site build or documentation regeneration was needed.

## 9. What Did Not Go Smoothly

An initial live call passed `se = FALSE` to the Julia engine; the bridge correctly rejected this TMB-only control before fitting. The corrected run omitted that control. One exploratory data set grouped predictor values by tip index and landed at an SD boundary; the permanent test assigns continuous predictor values across tips and aligns predictions explicitly by the tree's declared tip order.

## 10. Known Residuals

This is one synthetic seed, and only the SD slope is checked against the existing recovery tolerance; the fitted intercept was less accurate. It does not establish calibrated intervals, robust recovery across seeds, simulator covariance parity, or support in released/shared DRM.jl. The R and Julia candidates are dirty local worktrees. The simulator's raw-versus-correlation covariance question remains open under a separate source-ownership review.

## 11. Team Learning

Keep optimizer success, recovery, and interval calibration as separate evidence. A single synthetic fit can converge in both engines and still land far from truth. Cross-engine tests must use a shared covariance scale and compare tip predictions by labels, not incidental row order.

## 12. Cross-Product Coverage

Demonstrated cell: Bernoulli location, one phylogenetic intercept, fixed SD predictor, height-one tree, and one R/TMB plus Julia comparison on candidate checkouts. This test does NOT cover other response families, ordinary or correlated random effects, other structured providers, bivariate models, non-location parameters, simulator covariance calibration, profile/bootstrap interval calibration, or released/shared DRM.jl. These remain in the programme's capability ledger.

Extend Bernoulli recovery over independent seeds and predeclared information conditions, including boundary frequency and all-attempt denominators; do this on Totoro/DRAC after the run design and binary provenance gates are satisfied. Reconcile ownership of the Julia simulator source before making simulator changes. Continue the all-family and all-effect capability ledger without treating this slice as programme completion.
