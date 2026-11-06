# After Task: Julia Binomial related-matrix plus IID SD regression

## 1. Goal

Fit one complete-data Binomial location model with a related-matrix random intercept and an independent ordinary random intercept. Give each target its own group-level SD regression, expose the targets consistently through the R bridge, and retain marginal simulation.

## 2. Implemented

The Julia candidate now fits the pair jointly with a sparse Laplace approximation. The related field uses the supplied covariance `K` without normalization. The R bridge admits the exact intercept pair and preserves target-specific coefficient blocks. R marginal simulation draws both fields. Focused same-data tests cover logit, probit, and complementary log-log links.

## 3a. Decisions and Rejected Alternatives

The model uses independent latent fields with

\[
u \sim N(0, D_r K D_r), \qquad v \sim N(0, D_i^2), \qquad
\eta_j = x_j^\top\beta + u_{g(j)} + v_{h(j)},
\]

where `log(diag(D_r)) = W_r alpha_r` and `log(diag(D_i)) = W_i alpha_i`. The supplied `K` keeps its raw scale, consistent with the agreed Julia kernel rule and the native comparison. This slice does not add random slopes or estimate a correlation between the two fields.

## 4. Files Touched

- Julia candidate: `src/binomial_sd_regression.jl`, `src/inference.jl`, and new `test/test_binomial_relmat_iid_sd.jl`.
- drmTMB bridge candidate: `R/julia-bridge.R`, `R/julia-simulate.R`, and new `tests/testthat/test-julia-binomial-relmat-iid-sd-bridge.R`.
- Scope and user documentation: `README.md`, `NEWS.md`, `docs/design/01-formula-grammar.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`, and `vignettes/formula-grammar.Rmd`.
- This report and `docs/dev-log/check-log.md`.

The candidate worktrees are based at drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`. Both contain other in-progress edits. Those edits were preserved; only the scoped route and documentation were changed here.

## 5. Checks Run

- Julia direct synthetic test on Totoro, Julia 1.10.12: `test/test_binomial_relmat_iid_sd.jl` passed 9/9 checks, including convergence, target-specific SD coefficient direction, finite predictions, and binary marginal simulation.
- Live R bridge test on macOS, Julia 1.10.0: `test-julia-binomial-relmat-iid-sd-bridge.R` passed its pure admission checks and live same-data fits for logit, probit, and cloglog. The test compares native TMB and Julia likelihoods, both SD coefficient blocks, and group-level SD predictions; it also checks marginal binary simulation.
- `rmarkdown::render("vignettes/formula-grammar.Rmd", output_file = "/tmp/formula-grammar-relmat-iid.html")` completed. It emitted the existing Pandoc `--mathjax` deprecation warning.
- `pkgdown::check_pkgdown()` reported no problems. It emitted existing Pandoc `--mathml` deprecation warnings.
- Scoped `git diff --check` passed for all changed files in both worktrees.
- The after-task structure check passed. Its acceptance-ledger check found 13 ledgers that could not be run because Node or `gate-check` was unavailable; their state is UNKNOWN, not satisfied.
- `gh issue list --state open --search 'Binomial relmat IID SD' --limit 10` returned no matching issue. No issue was changed.

The initial Totoro attempt with default Julia 1.12 failed during Markdown precompilation with a stack overflow before loading the test. Rerunning under the available Julia 1.10.12 passed. The R bridge initially could not find Julia because its bin directory was absent from `PATH`; adding the installed Julia 1.10.0 bin directory allowed the live test to run.

## 6. Tests of the Tests

Before implementation, the direct Julia test failed with the expected single-relmat-target admission error, and the R admission test failed because the mixed-route helper did not exist. The first live bridge run then caught an incorrect assumption that the bridge should label both SD blocks `sd`; the implementation now uses the descriptor-specific labels for multiple targets. The direct recovery fixture also showed that 18 IID groups gave an unstable SD-slope direction, so its fixed-seed design now uses 40 related-matrix groups and 40 IID groups. The final direct test passed without weakening the directional checks.

## 7a. Issue Ledger

The open-issue search found no route-specific issue. No issue was opened, closed, or edited.

## 8. Consistency Audit

The formula and scope records now describe one relmat intercept plus one IID intercept with two SD formulas, for example `sd(iid_group) ~ w` and `sd(rel_group, level = "relmat") ~ z`. They identify the Julia code as development-candidate support and state that interval calibration and broad provider parity remain open. The formula grammar article rendered successfully, and pkgdown found no navigation or reference problems.

Status inventory search: `rg -n -i 'binomial.{0,90}(relmat|related.matrix|structured|SD regression)|((relmat|related.matrix).{0,90}binomial)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`. These were the exact current-status files searched; pkgdown navigation did not need a change.

## 9. What Did Not Go Smoothly

Julia was not available through the default local shell path, and Totoro's default Julia 1.12 precompile failed before the test loaded. The direct fixture also exposed a target-order assumption and inadequate group count. Those were fixed by resolving blocks through target metadata and increasing the fixed-seed group count. The R bridge test exposed a label mismatch that pure admission tests could not detect.

## 10. Known Residuals

This is one complete-data Binomial route for a single relmat intercept plus a single independent IID intercept. It does not cover slopes, correlated blocks, additional providers, other response families, profile/bootstrap behavior for this mixed route, coverage calibration, or shared/released DRM.jl support. The bridge comparison uses fixed tolerances and is point/output evidence, not uncertainty calibration. The broader predictor-dependent SD programme remains open.

## 11. Team Learning

When a formula contains multiple SD targets, bridge block labels must be resolved from each target descriptor. Formula order is not a stable identity. Recovery tests should map assertions by target metadata and use enough groups for both SD regressions.

## 12. Cross-Product Coverage

This slice covers the Julia direct fit, R-to-Julia bridge, native TMB comparison, target-specific SD extraction and prediction, and marginal binary simulation for this one Binomial relmat-plus-IID intercept pair. It does NOT cover other random-effect types, random slopes, other distributions, correlated cross-provider effects, interval calibration, or release-level Julia parity.
