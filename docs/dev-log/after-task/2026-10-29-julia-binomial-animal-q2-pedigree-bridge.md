# After Task: Julia Binomial Animal q2 Pedigree Bridge

## 1. Goal

Check whether the existing animal intercept-plus-slope SD route can use a pedigree through the R-to-Julia bridge for Binomial logit, probit, and cloglog models.

## 2. Implemented

Added a fixed-seed recovery test for 72 related animals, an intercept and numeric slope, and separate group-level SD predictors. The bridge converted the pedigree to its additive relationship matrix and passed the observed-animal covariance in the data's first-seen order. No model or bridge source change was needed for this route.

The mathematical contract checked by the fixture is

For animals (i,j) and random-effect coefficients (a,c), the tested structured block uses

\[
\operatorname{Cov}(b_{ia}, b_{jc}) = A_{ij}\,\tau_{ia}\,R_{ac}\,\tau_{jc},
\qquad \log \tau_{ia} = W_i\alpha_a.
\]

Here (A) is the observed-animal principal submatrix of the pedigree relationship matrix. Unobserved parents remain marginalized through that submatrix. The Bernoulli SD predictors act on the link-scale latent coefficients.

## 3a. Decisions and Rejected Alternatives

The existing pedigree-to-covariance bridge was reused because the test confirmed its observed-animal ordering and q2 fitting path. No likelihood or bridge rewrite was needed. Broader support wording and capability promotion were left to the documentation and capability audit lane.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-animal-q2-pedigree.R`: synthetic DGP, payload-order check, native/Julia fit comparison, SD recovery and prediction checks, and marginal simulation smoke check.
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-q2-pedigree-bridge-20261029/`: receipt, tested-source hashes, and passing console log.
- `docs/dev-log/check-log.d/2026-10-29-julia-binomial-animal-q2-pedigree-bridge.md`: concise check receipt.
- `docs/dev-log/after-task/2026-10-29-julia-binomial-animal-q2-pedigree-bridge.md`: this report.

The candidate source heads are drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`. The evidence directory records hashes for the dirty source snapshot actually tested.

## 5. Checks Run

- `PATH="/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin:$PATH" JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 NOT_CRAN=true DRMTMB_JULIA_TESTS=true DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-binomial-animal-q2-pedigree.R", reporter = "summary")'`: passed with one live JuliaCall test covering logit, probit, and cloglog.
- The test checks exact pedigree-to-covariance marshalling, native and Julia convergence, log-likelihood agreement within 0.2, both coefficient-specific SD outputs, and marginal binary simulation.
- `gh issue list --state open --search 'Binomial animal q2 pedigree SD' --limit 10`: no matching open issue.
- Coverage calibration, full test suite, full site build, and package check were not run.

## 6. Tests of the Tests

The first run found that the new prediction assertion compared group values by position. The two engines can return the same groups in different orders. The test now checks the labels and aligns predictions by animal name before comparing them. The passing rerun confirmed the intended route across all three links.

## 7a. Issue Ledger

No matching open issue was found, so no issue was changed.

## 8. Consistency Audit

The test, bridge payload, and covariance formula use the same first-seen animal order and observed-animal covariance. This is a candidate-level recovery result. No capability row or public support statement was promoted. The current public formula table describes the Binomial q2 bridge with supplied `A`; it does not yet mention this pedigree-input evidence. The documentation and capability audit remains a separate lane, so that shared page was left untouched for its owner to reconcile.

The source graph could not be queried because the `graft` command is unavailable in this shell. Focused source inspection and the test run provide the evidence recorded here.

## 9. What Did Not Go Smoothly

The first assertion assumed matching vector order. Aligning by animal labels fixed the test without relaxing the numerical tolerance or changing model code.

## 10. Known Residuals

This is one synthetic pedigree fixture for one q2 animal block and three Binomial links on the current development candidates. It does not establish interval calibration, coverage, all animal layouts, other providers, broad family support, or release readiness. The broader required-row inventory remains open, and its capability status is unchanged.

The after-task structural checker found 13 acceptance ledgers that are not runnable because Node or `gate-check` is unavailable. Their state remains UNKNOWN, not satisfied.

## 11. Team Learning

Compare group-level outputs by their labels whenever a bridge can reorder matrix rows to match the data.

## 12. Cross-Product Coverage

**Covers:** the R-to-Julia bridge and native TMB comparison for one animal q2 pedigree route under Binomial logit, probit, and cloglog; fitting, coefficient-specific SD extraction, group-SD prediction, and marginal simulation. **Does NOT cover:** other animal layouts, other providers or families, save/reload, profile or bootstrap workflows, the full package suite, site rendering, broad Julia parity, or interval coverage.

Memory receipt: I used the general-SD memory entry to preserve the candidate-only and non-coverage boundaries. `route.py` returned no LOAD-FIRST manifest and `graft` is unavailable in this shell. Golden Set: not run; this provider-input regression is outside the registered repeated-mistake classes.

## Next Actions

Continue with another unresolved Bernoulli SD row after checking the exact required-row entry and source ownership. Reconcile this pedigree q2 wording with the documentation and capability audit lane before publishing a broader support claim.

## Writing Assessment

**Style:** 2/10, medium confidence; this is a short, source-bound technical report with concrete scope limits. **Genre and coverage:** after-task report, whole draft reviewed. **Evidence and repair:** “The first assertion assumed matching vector order” names the cause and repair; no change needed. **Gates:** science = pass for the stated model contract; facts = pass against the saved test log and source manifest; references = not applicable because the report contains no external citations. **Provenance:** self-review, draft version 1, 2026-10-29; related SD after-task reports were already seen.
