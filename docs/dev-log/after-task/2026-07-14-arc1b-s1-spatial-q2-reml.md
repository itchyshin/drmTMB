# After Task: Arc 1b-S1 Spatial q2 REML

## 1. Goal

Admit native-TMB REML for one exact bivariate-Gaussian fixed-covariance
spatial q2 location-intercept cell and stop at `point_fit_recovery`.

## 2. Implemented

`REML = TRUE` now accepts matching labelled
`spatial(1 | p | site, coords = coords)` intercepts in `mu1` and `mu2` when
`sigma1`, `sigma2`, and `rho12` are intercept-only, response pairs are complete,
weights are one, no known `meta_V()` covariance is supplied, and no additional
ordinary random effect, direct-SD formula, or `corpair()` regression is present.
A narrow R-side admission helper opens this existing native covariance path. No
C++ likelihood rewrite was required. Every adjacent shape remains rejected.

## 3. Mathematical Contract

With response-major ordering \(y=(y_1^\top,y_2^\top)^\top\), endpoint-specific
fixed-effect design \(X=\operatorname{blockdiag}(X_1,X_2)\), and
\(C=ZK_{sp}Z^\top\), the fitted covariance is

\[
V=\begin{bmatrix}
s_1^2C+\sigma_1^2I & \rho_s s_1s_2C+\rho_{12}\sigma_1\sigma_2I\\
\rho_s s_1s_2C+\rho_{12}\sigma_1\sigma_2I & s_2^2C+\sigma_2^2I
\end{bmatrix}.
\]

The restricted objective uses the same \(V\), response-major ordering,
coordinate-covariance normalization and jitter, fixed-effect rank, and
correlation transforms as TMB. The extracted `sdpars$mu` values are \(s_1\)
and \(s_2\); `corpairs(level = "spatial")` reports \(\rho_s\), distinct from
residual `rho12`.

## 3a. Decisions and Rejected Alternatives

The slice reuses the already exact native Gaussian covariance engine and adds
only a fail-closed R admission predicate. A C++ likelihood rewrite was rejected
because the dense independent oracle showed that the existing objective already
implements the target model. Broader provider, slope, range, scale-side,
interval, and coverage admissions were rejected from this slice because each
needs its own equation, oracle, recovery, and inference evidence.

## 4. Files Touched

The implementation and exact contract tests are in `R/drmTMB.R`,
`tests/testthat/test-reml-bivariate-spatial-q2.R`, and the focused recovery
test/runner. The equation alignment, recovery design, compact Totoro artifact,
capability-ledger sources/generator/tests/generated surfaces, README, NEWS,
ROADMAP, formula grammar, known limitations, spatial/capability vignettes,
check log, and team-improvement record are synchronized.

## 5. Checks Run

- Focused Arc 1b/oracle/recovery/conformance tests: passed; the final direct
  admission/oracle file passed 41/41 expectations.
- Full source-tree `devtools::test()`: 0 failures, 62 known warnings, 24
  expected optional-Julia skips.
- `devtools::document()`: passed.
- Genuine `devtools::check(args = "--as-cran")` rerun: 0 errors, 0 warnings,
  0 normalized notes; raw long-test NOTE only.
- `pkgdown::check_pkgdown()`: no problems; `pkgdown::build_site()`: completed.
- Capability generator: 30 outputs current; 35 ledger unit tests passed;
  18/18 runtime routes passed; repository Mission Control validator passed.
- Live `http://127.0.0.1:8823/` readback: active branch/status and served
  673-cell surface agree with the repository.
- `git diff --check`: passed.

## 6. Tests of the Tests

The independent dense REML calculation matches TMB at the optimum and two
displaced parameter vectors to about `3e-13`. A deliberately wrong
correlation-layer oracle does not match. Direct negative tests cover the
unlabelled, unmatched, mismatched-label/group/coordinate, multiple-block,
slope, predictor-dependent residual, q4, scale-only q2, q2-plus-q2, mesh,
non-Gaussian, random-`rho12`, weighted, missing-response, known-`V`,
direct-SD, spatial-`corpair()`, ordinary-mixture, animal, and `relmat()`
neighbours. The recovery runner test reconstructs all six design cells,
retains every attempt, writes the four required artifacts, and enforces the
50-worker cap.

## 7a. Issue Ledger

Open issues #714, #555, and #33 were inspected as the closest REML,
structured, or bivariate matches. None owns this exact fixed-covariance q2
intercept slice, so no issue was changed or closed. Unrelated PR #781 remains
parked and untouched. Arc 1b-S1 will use its own focused PR.

## 8. Consistency Audit

README, NEWS, ROADMAP, likelihood/formula design, known limitations, the
formula-grammar and spatial/capability vignettes, capability ledger, generated
census/surface, rendered pkgdown pages, and live Mission Control all state the
same exact cell and recovery-only tier. Exact scans were:

```sh
rg -n "all bivariate non-phylogenetic structured effects|any bivariate non-phylogenetic structured REML|does not admit.*bivariate" README.md ROADMAP.md NEWS.md docs/design/01-formula-grammar.md docs/dev-log/known-limitations.md vignettes pkgdown-site
rg -n "Arc 1b-S1|point_fit_recovery|fit_spatial_q2_reml|exact bivariate-spatial q2|all other bivariate non-phylogenetic" pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/articles/capability-and-limits.html pkgdown-site/articles/spatial-models.html pkgdown-site/articles/formula-grammar.html pkgdown-site/news/index.html
```

No `_pkgdown.yml` navigation change was needed because existing spatial,
capability, and formula-grammar pages own the new text.

## 9. What Did Not Go Smoothly

The first Totoro install attempt exposed an environment/library wrinkle and
was rerun from the exact source commit in an isolated library. The campaign
then completed cleanly. The first `--as-cran` check exposed a test that assumed
the source-only recovery runner existed inside the built package; it now runs
fully in source checkouts and skips only when the correctly excluded runner is
absent. The repository Mission Control validator also passed while the live
port-8823 board still read a stale checkout; direct HTTP readback found and
repaired that routing gap. Rose's first closeout re-audit also caught stale
boundary wording in the canonical generated ledger after the code and public
docs had been repaired; the ledger source, evidence, assertions, generated
surfaces, and admission-helper locator were synchronized and revalidated.
Two retained low-information campaign attempts recorded `NaNs produced` during
optimizer evaluation; both returned convergence-code-zero fits and were not
removed from the denominator. Two other attempts had non-positive Hessians and
nine hit a predeclared target boundary; all are disclosed in the artifact.

## 10. Known Residuals

This is `point_fit_recovery`, not interval, coverage,
`inference_ready_with_caveats`, or `supported` evidence. It does not cover
spatial slopes, estimated range or mesh/SPDE models, animal/`relmat()`
bivariate REML, scale-side q2, q4+, non-Gaussian REML, AI-REML, missing-response
or aggregation routes, broad bridge parity, or the proposed distribution-wide
`sd()` arc.

## 11. Team Learning

An existing engine path can require only an admission change, but still needs
an independent objective oracle and a test that the oracle itself can fail.
Source-only runner tests need an explicit built-package boundary. Mission
Control closeout requires live HTTP readback, not only repository validation.

## 12. Cross-Product Coverage

Code, equations, formula grammar, help, vignettes, NEWS/README/ROADMAP,
capability ledger, generated HTML, live Mission Control, and the Totoro artifact
all describe the same exact cell and recovery-only maturity. No Julia/DRM.jl
bridge claim was added; the native R/TMB package remains the evidence source.
This arc does NOT cover incomplete-pair missingness, non-unit weights, known
sampling covariance, aggregation, Julia-engine parity, non-spatial providers,
spatial slopes/range/mesh, scale-side or larger endpoint blocks, non-Gaussian
families, intervals, coverage, AI-REML, or the proposed `sd()` arc.

## 13. Next Actions

Fresh Fisher, Noether, and Rose closeout verdicts are PASS. Commit and push the
consolidated evidence; open the focused PR; wait for green current-head CI; and
leave the PR unmerged until Shinichi gives separate explicit authorization. Do
not begin the next arc or the banked `sd()` candidate.
