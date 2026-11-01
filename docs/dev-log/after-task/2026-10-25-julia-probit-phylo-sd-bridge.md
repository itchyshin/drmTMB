# After Task: Julia probit phylogenetic Bernoulli SD bridge

## 1. Goal

Admit and check the tree-based phylogenetic-intercept SD-regression route for Bernoulli probit models through the R-to-Julia bridge.

## 2. Implemented

The bridge now admits the matching `sd_phylo(group) ~ fixed_predictors` formula only for the probit phylogenetic-intercept route. It continues to refuse the corresponding cloglog phylogenetic route and retains the existing ordinary intercept/slope admission rules. A gated live test fits the same independent synthetic data with Julia and native TMB and checks convergence, SD-coefficient agreement, likelihood agreement, predictor-aligned tip SDs, and slope recovery.

The model uses `log(s_j) = w_j alpha` and `b ~ N(0, D K D)`, where `K` retains the supplied tree scaling. The SD is a multiplier of that covariance; this change does not normalize the tree or add a Bernoulli residual scale.

## 3a. Decisions and Rejected Alternatives

### Mathematical contract

The implementation retains the supplied tree scale. Normalizing `K` would change the meaning of the SD multiplier and break parity with the native TMB route.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-binomial-phylo-sd.R`
- This report
- `docs/dev-log/check-log.d/2026-10-25-julia-probit-phylo-sd-bridge.md`

## 5. Checks Run

- Each Mac command used `PATH=/Users/z3437171/.juliaup/bin:$PATH`, `JULIA_HOME=/Users/z3437171/.juliaup/bin`, `DRM_JL_JULIA_HOME=/Users/z3437171/.juliaup/bin`, `DRM_JL_PATH=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia`, `DRMTMB_JULIA_TESTS=true`, `JULIA_NUM_THREADS=1`, and `OPENBLAS_NUM_THREADS=1`.
- `Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd", reporter = "summary")'`: passed; both live phylogenetic tests ran.
- `Rscript -e 'devtools::test(filter = "julia-binomial-nonlogit-(intercept-slope|slope)-sd-bridge", reporter = "summary")'`: completed without failures; Julia bridge glue ran and the test output reported one live test.
- `Rscript -e 'devtools::test(filter = "julia-binomial-sd$", reporter = "summary")'`: completed without failures; five live tests ran. Julia reported Hessian-boundary warnings for two fits, so their Wald uncertainty is not treated as reliable evidence.
- `python3 tools/general-sd-regression/tests/test_universe.py`: passed, 17 tests in 38.015 seconds.
- `git diff --check -- R/julia-bridge.R tests/testthat/test-julia-binomial-phylo-sd.R`: passed.
- A Totoro attempt reached a JuliaCall startup segmentation fault before model fitting. That run is not counted as test evidence.

## 6. Tests of the Tests

The bridge admission test verifies that probit phylogenetic SD regression is admitted, the analogous cloglog route is refused, and ordinary cloglog intercept-SD regression remains admitted. Before the helper change, the new admission assertion failed because every structured non-logit formula was rejected. The live probit test uses an independent tree-based Bernoulli data-generating process and compares Julia with the adjacent TMB fit rather than relying on optimizer convergence alone.

## 8. Consistency Audit

The bridge and test use the existing `sd(group, level = "phylogenetic") ~ ...` syntax. These searches found that existing Julia documentation describes probit only for ordinary intercept/slope routes:

```sh
rg -n -i 'probit|phylo.*sd|structured.*random' vignettes/julia-engine.Rmd docs/design/01-formula-grammar.md docs/design/06-distribution-roadmap.md docs/design/capability-status.md NEWS.md docs/dev-log/known-limitations.md
rg -n -C 3 'Binomial|probit|phylogenetic' vignettes/julia-engine.Rmd docs/design/01-formula-grammar.md
rg -n -C 2 'Bernoulli|binomial.*phylo|Julia' README.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md
```

The required-row ledger marks Julia probit phylogenetic rows as blocked base-link plumbing based on its pinned DRM.jl source hash `b1832c7a686decf4e3d7a06ad8382bf164b9d8d4`. Seventeen universe-generator tests confirm that the generated rows match those pinned inputs. This is not a stale artifact: the tested route is a newer working-tree capability beyond that baseline. When the Julia source pin advances, the ledger will need route-specific evidence so admitting the tree-intercept exception does not imply general probit support.

Public documentation and the capability ledger have not yet been synchronized. Keep the route described as a development-candidate exception until those records are updated and reviewed. No generated reference or pkgdown navigation changed in this slice.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --state open --search 'Bernoulli probit phylogenetic SD Julia' --json number,title,url --limit 20` returned no matching issues. No issue was changed.

## 9. What Did Not Go Smoothly

Totoro's R process segfaulted while JuliaCall initialized. The Mac run succeeded after setting both `PATH` and `JULIA_HOME` to the installed Juliaup shim. The lane preflight also stalled while collecting the repository-wide lease census; this prevented a reliable path lease for the public-documentation edits.

## 11. Team Learning

When a family link is admitted only for one structured route, a family-wide base-link status is too coarse to describe it. Preserve the blocked status for unsupported combinations and add a reviewed route-level exception instead of relabelling the entire link as supported.

## 10. Known Residuals

This is one fixed-seed point-recovery and cross-engine comparison for one tree-based probit intercept route. It does not establish interval coverage, broad recovery, simulator parity, cloglog phylogenetic support, matrix-input probit routes, or general non-logit structured effects. Julia/TMB fit agreement for this case does not establish calibrated uncertainty.

## 12. Cross-Product Coverage

Demonstrated cell: Bernoulli probit, one tree-based phylogenetic random intercept, and one fixed SD predictor, fitted through the R-to-Julia bridge and matched to native TMB on the same synthetic data. This does not cover other Julia probit providers, cloglog phylogenetic effects, cross-engine simulator parity, or interval calibration.

Next actions: update the Julia engine guide and development NEWS with this exact route and its candidate-only boundary; when the candidate source pin advances, extend the capability-universe generator to represent the route-specific tree-intercept exception without admitting other blocked Julia probit combinations; then continue the Bernoulli capability matrix and the remaining supported response families.
