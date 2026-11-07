# After Task: Beta animal matrix-input SD regression

## 1. Goal

Verify and document the existing native Beta animal-intercept SD route when its
relationship is supplied as covariance `A` or precision `Ainv`, complementing
the pedigree-input case.

## 2. Implemented

The focused synthetic test now fits the same Beta animal `mu` q1 intercept
through pedigree, jointly permuted supplied `A`, and matching `Ainv` inputs.
It checks convergence, recovery of the SD slope, observed-animal prediction
labels and values, agreement with the pedigree log likelihood, and
constant-SD equivalence for each provider. The vignette now demonstrates the
two supplied-matrix forms. Design, inventory, adapter, limitation, roadmap,
NEWS, and check-log text state the same scope.

The matrix-input fits agree with the pedigree fit on this synthetic case. The
evidence covers point recovery for one Beta `mu` animal intercept and does not
support a broader claim about arbitrary matrix inputs.

## 3a. Decisions and Rejected Alternatives

The slice reuses the existing animal covariance and precision paths because
the fit-level comparison shows that they already admit this Beta SD formula.
No C++ or likelihood change was needed. We retained the 19,118-row capability
denominator and its `direct_sd_claim` values unchanged.

Assumptions made without asking: the existing Beta animal-intercept route is
the intended matrix-input scope; if that is wrong, the support statement and
test should be narrowed to the requested providers.

## 4. Files Touched

- `tests/testthat/test-beta-animal-pedigree-sd-regression.R`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `vignettes/formula-grammar.Rmd`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/internal-roadmap.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-20-beta-animal-matrix-sd.md`

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "beta-animal-pedigree-sd-regression", reporter = "summary")'`: passed, exit 0; the focused test file includes pedigree, `A`, and `Ainv` fits.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", output_file = "/private/tmp/predictor-dependent-random-sd-beta-animal-matrix.html", quiet = TRUE)'`: passed; only the existing Pandoc `--mathjax` deprecation warning appeared.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'pkgdown::check_pkgdown()'`: passed with existing Pandoc `--mathml` deprecation warnings.
- `gh issue list --state open --search '"Beta animal" in:title,body' --json number,title,url`: no matching open issues.
- Targeted stale-wording search across the capability map and current user-facing docs: completed; the active documentation now consistently names pedigree, `A`, and `Ainv`. The historical first-slice report still states the limits that applied when it was written.
- `git diff --check` for the changed tracked files: passed.
- Report structure check via the brain's `check-after-task.R` function: passed. The full goal's acceptance ledger remains open because the broader programme is unfinished.

## 6. Tests of the Tests

The test varies the order of the named covariance rows and columns together,
then constructs `Ainv` from that reordered covariance. It compares both fits'
log likelihoods with the pedigree route and compares predicted group SDs with
the fitted coefficient formula. These checks would expose a provider-order
mapping error or an input-specific constant-SD discrepancy.

## 7a. Issue Ledger

No matching open issue was returned by the search recorded in section 5. No
issue was opened, edited, or closed.

## 8. Consistency Audit

The formula reference, formula-grammar vignette, predictor-dependent-SD
vignette, native family adapter map, current limitation, roadmap, inventory,
and NEWS now identify pedigree, `A`, and `Ainv` as the tested Beta animal
intercept inputs. They continue to label interval calibration and Julia parity
as open. The 19,118-row denominator and its direct-SD claims are unchanged.

Exact searches used:

```sh
rg -n -i 'beta.*(pedigree|animal|A/Ainv)|animal.*(pedigree|A/Ainv).*beta|A/Ainv.*open|pedigree.*only' docs/design/01-formula-grammar.md docs/dev-log/known-limitations.md docs/dev-log/internal-roadmap.md vignettes/formula-grammar.Rmd NEWS.md docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md
rg -n -C 2 'Beta.*animal|animal.*Beta|A/Ainv|pedigree-derived' docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd NEWS.md
```

Memory receipt: repository source, current worktree evidence, and the project
after-task protocol were used; no second-brain memory file was changed.

Golden Set: not run; this provider-input follow-up adds no new family or
formula parser feature.

## 9. What Did Not Go Smoothly

The brain-level report generator resolved this worktree to the separate
second-brain repository and attempted to write there, where writes are not
available. It did not create a file. This report follows drmTMB's local
after-task protocol instead.

## 10. Known Residuals

Interval calibration, Julia parity, other Beta animal effect shapes, and
broader provider combinations remain unverified. The full predictor-dependent
SD goal remains active with its required rows and gates open.

## 11. Team Learning

For structured SD regression, test each public covariance input independently
even when all inputs share a builder. Jointly permuting labeled matrices and
comparing likelihoods provides a compact check that the provider mapping is
preserved.

## 12. Cross-Product Coverage

Covers: native R/TMB Beta `mu` animal q1 intercept SD regression with pedigree,
supplied covariance `A`, and supplied precision `Ainv`; one synthetic
point-recovery fixture and the documented prediction/constant-SD outputs.

Does NOT cover: Julia, other response families, other Beta random-effect
shapes or endpoints, general matrix-order invariance, interval calibration,
uncertainty coverage, or the full predictor-dependent random-effect SD goal.
