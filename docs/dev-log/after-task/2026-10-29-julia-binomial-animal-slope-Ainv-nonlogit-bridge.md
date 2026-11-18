# After Task: Julia Binomial animal-slope SD bridge with Ainv

## 1. Goal

Admit supplied animal precision matrix `Ainv` on the existing Julia Binomial animal-slope-only SD route for probit and cloglog, then verify same-data fitting against native TMB.

## 2. Implemented

The R bridge now accepts `Ainv` for the probit/cloglog animal slope-only route at both the non-logit family gate and the structured payload gate. Existing intercept, q2, and animal-plus-IID admissions remain intact. The unsupported correlated animal block and pedigree marker remain rejected.

## 3a. Decisions and Rejected Alternatives

The animal-slope fitter in DRM.jl already accepts `Ainv`; only the R bridge gates excluded this combination. I added no new likelihood code or formula syntax. I kept pedigree out of the change because this bridge does not marshal pedigree objects. Supplied `Ainv` remains the inverse of the existing relationship matrix `A`; no kernel rescaling was introduced.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-binomial-nonlogit-structured-sd-bridge.R`
- `NEWS.md`, `README.md`, `docs/design/01-formula-grammar.md`, `docs/dev-log/known-limitations.md`, and `vignettes/formula-grammar.Rmd`
- `docs/dev-log/active-lane-split.md` and `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and its generated summary
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-slope-Ainv-nonlogit-bridge-live-20261029/`
- `docs/dev-log/check-log.md`, `docs/dev-log/check-log.d/2026-10-29-julia-binomial-animal-slope-Ainv-nonlogit-bridge.md`, and this report

## 5. Checks Run

- Local bridge gate and payload test: 10 assertions passed; three live test cases were skipped with Julia bridge tests disabled.
- Live focused test on macOS with Julia 1.10.0: three live bridge test cases passed. The animal-slope fixture fits native TMB and Julia under probit and cloglog, and checks convergence, finite and named SD coefficients, slope recovery within 0.5 of truth, log-likelihood agreement within 0.1, and fitted group-SD agreement. Neighboring animal-intercept `A` and relmat-intercept checks also passed.
- Evidence reconciliation: `EVIDENCE_RECONCILIATION_PASS candidate_rows=20350 linked_rows=194 unlinked_rows=20156 evidence_records=216`. Four receipt rows were added for exact native/Julia probit/cloglog `Ainv` combinations. The rows remain unreviewed; reconciliation does not promote support.
- `pkgdown::check_pkgdown()` reported no problems. It emitted the existing Pandoc `--mathml` deprecation warnings.
- `gh issue list --state open --search 'Binomial animal slope Ainv probit cloglog' --json number,title,url --limit 10` returned `[]`; no issue was opened or changed.
- Source manifest verification passed for all listed files. `test.log` records the live test output.
- The after-task structure check passed, `slop_check.py` found 0 hits, and the exact-draft assessment and close-out compiler passed. The acceptance-ledger scan found 13 files not runnable because Node or `gate-check` is unavailable, so their state is UNKNOWN.

## 6. Tests of the Tests

The local assertions check successful admission under both non-logit links, the exact `Ainv` payload keyword and aligned matrix, and continued rejection of the correlated animal block and pedigree marker. The live fixture uses independent fixed-seed Bernoulli data and checks recovery and same-data output agreement. It does not compare against a separate likelihood oracle.

## 7a. Issue Ledger

The targeted open-issue search returned no matching issue. No issue action was needed.

## 8. Consistency Audit

The public support summary, NEWS, formula guide, vignette, and known-limitations note now distinguish slope-only `A` support under logit/probit/cloglog from `Ainv` support under probit/cloglog. The equation, R formula, and Julia precision input all refer to the same link-scale animal-slope SD. No formula grammar or likelihood parameterization changed, and pkgdown navigation did not change.

The status inventory search was: `rg -n -i 'Binomial.{0,50}animal|animal.{0,50}Binomial|Ainv.{0,50}animal' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`.

## 9. What Did Not Go Smoothly

The lane preflight and lease registry commands did not finish during this turn. I preserved the dirty worktree and limited edits to the reviewed bridge gates, a test, and directly related documentation after Shinichi assigned this SD lane ownership across both engines. The first local live attempt could not find Julia because `~/.juliaup/bin` was absent from `PATH`; adding that directory allowed the run to pass. The installed testthat version also does not accept `filter` in `test_file()`, so the focused file was run as a whole.

## 10. Known Residuals

Evidence covers one complete-data Binomial animal slope-only SD model with `Ainv` under probit and cloglog. It does not establish interval calibration or coverage, pedigree input, intercept-plus-slope correlated animal blocks, mixed animal-plus-IID parity, missing-data support, or broad Julia parity. Totoro's recorded R-to-Julia embedding failure prevents this specific bridge check there; the smoke test ran locally. The four required rows remain unreviewed.

## 11. Team Learning

JuliaCall discovers Julia through the command path. On this Mac, add `~/.juliaup/bin` explicitly to `PATH` when running bridge tests. Shinichi's direct ownership decision supersedes the older board wording that placed all Julia parity in the separate DRM parity lane; coordination on shared files remains necessary.

## 12. Cross-Product Coverage

This slice covers current R/TMB and R/Julia point fits for one complete-data Binomial animal slope-only SD model with supplied `Ainv` under probit and cloglog. It does not cover interval calibration, pedigree input, other animal layouts, other providers, or other families.

Memory receipt: `MEMORY.md:2-5` and the current direct-SD evidence ledger were consulted to preserve exact-row and evidence boundaries. Golden Set: not run; this bridge gate correction does not address a known-failure class.

Prose assessment: `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-slope-Ainv-nonlogit-bridge-live-20261029/after-task-assessment.json`.
