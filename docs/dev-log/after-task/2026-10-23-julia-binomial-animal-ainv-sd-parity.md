# After Task: Julia Binomial animal-intercept SD with Ainv

## 1. Goal

Allow the R bridge to fit one complete-data Binomial animal-intercept SD
regression with labeled animal covariance or precision input in the paired
Julia engine, comparing both forms with native TMB on independent data.

## 2. Implemented

The Julia bridge now admits the exact Binomial animal-intercept shape when the
formula includes one matching `sd(id, level = "animal")` target. It passes
labeled `A` as covariance or labeled `Ainv` as precision. Same-data comparisons
fit each form in both engines and compare `A` with `Ainv` within each engine.
Other Binomial structured shapes and Binomial animal matrices without the
matching SD formula remain refused.

## 3a. Decisions and Rejected Alternatives

The existing animal precision interface is reused. This slice does not add a
new public argument or change how supplied relationship matrices are scaled.
The Binomial bridge admission remains limited to the tested intercept plus
matching SD formula; it does not admit other Binomial structured fits.

## Mathematical Contract

Let $u \sim N(0, A)$ and let $D=\operatorname{diag}(\exp(W\alpha))$. The
animal effect is $b=Du$, so its covariance is $DAD$. Supplying `Ainv`
provides $A^{-1}$; the bridge passes it as precision and does not normalize
the matrix. Thus the SD formula gives a multiplier, and the marginal group SD
is that multiplier times the square root of the supplied covariance diagonal.

## 4. Files Touched

- `R/julia-bridge.R`: exact Binomial animal-intercept admission and matrix-input guard for `A`/`Ainv`.
- `tests/testthat/test-julia-binomial-animal-sd-regression.R`: admission,
  rejection, same-data TMB/Julia comparisons for `A` and `Ainv`, and
  same-engine covariance/precision equivalence.
- `NEWS.md`, `docs/design/01-formula-grammar.md`,
  `docs/dev-log/internal-roadmap.md`, `vignettes/formula-grammar.Rmd`, and
  `vignettes/structural-dependence.Rmd`: synchronized the narrow capability
  claim and its limits.
- `docs/dev-log/check-log.md`: recorded the focused checks.

The checks used the dirty candidate worktrees at native HEAD `425bee815` and
Julia HEAD `70dbf564e`. The source files contain broader in-flight work; these
short hashes identify their base commits, not isolated feature diffs.

## 5. Checks Run

- `PATH="$HOME/.juliaup/bin:$PATH" DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" Rscript -e 'devtools::test(filter = "julia-binomial-animal-sd-regression", reporter = "summary")'`: passed; two live Julia tests ran. The new test fit both `A` and `Ainv` in
  TMB and Julia, and compared coefficients, log likelihoods, and named group-SD
  predictions.
- `Rscript -e 'pkgdown::check_pkgdown()'`: no problems found; existing Pandoc `--mathml` deprecation warnings only.
- `Rscript -e 'rmarkdown::render("vignettes/structural-dependence.Rmd", output_file = "/private/tmp/structural-dependence-general-sd.html", quiet = TRUE)'`: rendered successfully; existing Pandoc `--mathjax` deprecation warning only.
- Changed-file `git diff --check` and a trailing-whitespace scan of the new test: passed. The whole-worktree `git diff --check` separately reports an existing extra blank line at EOF in `tests/testthat/test-binomial-sd-integration.R`, outside this slice.
- After-task structure validation passed. The acceptance-ledger subcheck returned `UNKNOWN` because its required node or gate-check command was not runnable; no programme gate advanced.
- SHA-256: `R/julia-bridge.R` `fa20e95c7fa8fc615418aea90726f7414bd710385d24b312c69af7dee48dc0bc`; test test `ef4414c7f0ee01e1273ee08f98baacb7a8df8a620f4efa58493d9197782db56b`.

## 6. Tests of the Tests

Before the implementation, the new test failed because the specific Binomial
animal-intercept admission helper did not exist. The final test checks the
supported covariance and precision payloads, rejects the Binomial animal
matrix route without the matching SD formula, and runs both TMB and Julia with
both inputs on the same independent synthetic data. It also checks same-engine
`A`/`Ainv` equivalence. The comparisons cover the SD coefficient, log
likelihood, and name-aligned group-SD predictions.

## 8. Consistency Audit

The source guard, formula example, NEWS entry, and structural-dependence guide
now describe the same route. The audit used:

```sh
rg -n -i 'Julia.*Ainv|Ainv.*Julia|Ainv matrix only|Ainv.*Poisson animal' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml vignettes/structural-dependence.Rmd
```

The current documentation no longer says the Julia animal `Ainv` bridge is
Poisson-only. Older after-task reports retain their dated scope. Formula
grammar changes were not needed; this admits an existing marker plus an
existing SD formula.

## 7a. Issue Ledger

`gh issue list --state open --search 'Binomial animal Ainv Julia SD regression' --json number,title,url --limit 20` returned no matching open issue. No issue was opened or changed.

## 9. What Did Not Go Smoothly

The first live invocation omitted the Juliaup path and the fixture initially
returned unnamed list components. A later audit also caught that the fixture's
permuted covariance labels were not matched to the group-level SD predictor;
the fixture ordering was corrected and the live parity test rerun. JuliaCall
printed a harmless setup message before running the paired project.

## 10. Known Residuals

This is one complete-data Binomial logit animal-intercept route for labeled
`A` and `Ainv`. It does not establish other links, animal slopes with precision
input, pedigree bridging, profile or bootstrap refitting, interval calibration,
or broad family/effect parity. The test is point-comparison evidence only and
does not close any programme gate. Full package checks and the broader
family/effect universe remain open.

## 11. Team Learning

Name every returned synthetic-fixture field explicitly. For paired Julia tests,
set `PATH` and `DRM_JL_PATH` in the command so a passing result proves the live
engine ran rather than only the mock-driven bridge. Continue the required-row
audit and implement the next missing family/effect route in both engines.

## 12. Cross-Product Coverage

This slice covers one complete-data Binomial logit location intercept with a
predictor-dependent animal SD, labeled `A` and `Ainv`, native TMB and Julia
engines, and coefficient, log-likelihood, group-SD prediction, and
within-engine covariance/precision comparisons. It does NOT cover other
response families or Binomial links, pedigree input, animal slopes with `Ainv`,
other providers or combined effects, missing-data models, marginal simulation
through the R bridge, profile/bootstrap refitting, interval calibration, or
package-wide R/Julia checks. These fits are evidence only for this
matrix/provider/effect/endpoint cell.

## Prose Assessment

**Style:** 2/10, medium confidence; the report names the exact route and tests,
though the required headings create a regular report structure. **Genre and
coverage:** engineering after-task report, read in full. **Evidence and repair:**
“Same-data comparisons fit each form in both engines” describes the tested
inputs directly; no change needed. **Gates:** science = pass for this narrow
route, with broader claims explicitly excluded; facts = pass against the focused
test output and current source; references = not applicable because no external
citations appear. **Provenance:** self-review of draft SHA-256
`3f02e4102f0f1aa54a4163bc0e312536767c0386e98f3311c399bec791d01b2e`,
2026-10-23; no held-out style controls used.
