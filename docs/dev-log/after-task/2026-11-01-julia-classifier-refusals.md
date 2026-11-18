# After Task: Julia classifier refusals that the lane now admits

## 1. Goal

A full R CMD check of 7309d3cd8 on Totoro (no Julia, no sdmTMB) reported test failures. This note covers the six failures where a test expects a refusal, or FALSE, from an R-side Julia classifier that now admits the input. For each one we decided whether the admission is intended or an accidental widening of the classifier.

## 2. Verdict

All six are stale tests. No R source was changed. Every admission traces to commit b87566680 (the squashed lane commit) and is backed by a Julia route with its own test or after-task evidence. The tests were written before those admissions and were not updated.

## 3. Per-failure table

| Test:line | Cause class | Evidence | Fix |
| --- | --- | --- | --- |
| test-julia-binomial-nonlogit-structured-sd-bridge.R:22 (two failures, probit and cloglog) | (a) stale test | The failing formula is `animal(1 | id, pedigree = pedigree)` with `sd(id, level = "animal") ~ z`. `drm_julia_binomial_animal_sd_intercept_route_admitted()` is TRUE for it, and `drm_julia_refuse_binomial_nonlogit_sd()` returns without error for both links (probed on Totoro). The branch `structure %in% c("A", "pedigree")` was added in b87566680. Intent is confirmed by test-julia-binomial-animal-pedigree-sd-bridge.R, which asserts `expect_no_error(drm_julia_refuse_binomial_nonlogit_sd(...))` for probit and cloglog and has live fits for both. The animal block `1 + x` with `A =` stays refused (that part of the test still passes). The 2026-10-27 after-task note that lists pedigree as blocked is older than that admission. | Swapped the pedigree case for a still-refused route of the same kind, a precision-matrix slot: `relmat(1 | id, Q = Q)` with `sd(id, level = "relmat") ~ z`. Probe confirms it is refused for both links, and the 2026-10-27 note keeps `Q_precision` blocked. |
| test-julia-phylo-nongaussian.R:59 (two failures, probit and cloglog) | (a) stale test | `drm_julia_bridge_family_type()` now returns "binomial" for probit and cloglog (b87566680; before it, it aborted for every non-logit link). This is deliberate. The silent-logit risk the old comment describes is now covered one step up: `drmTMB_julia_bridge()` calls `drm_julia_refuse_binomial_nonlogit_sd()` first, and per-link family tags (`binomial_probit`, `binomial_cloglog`) are chosen by `drm_julia_structured_family_tag()`. A fixed-effect probit or cloglog formula is refused by that guard (checked). | The loop now asserts the classifier returns "binomial" for both links, and that `drm_julia_refuse_binomial_nonlogit_sd(bf(y ~ x), binomial(link = lk))` still aborts with "does not match that route", so the test can still fail if the guard is removed. Added a cauchit case that the classifier itself still refuses with the "DRM.jl" message. |
| test-julia-structured.R:176 | (a) stale test | `drm_julia_structured_matrix()` now marshals an animal `Ainv`; the refusal for unsupported families moved to `drm_julia_structured_payload()` (error "admits animal `Ainv` only for supported Poisson or Binomial animal SD regression routes", line 11442 of R/julia-bridge.R). The function comment says so. This is the intended gate, since the Poisson and Binomial animal SD routes consume `Ainv`. | The assertion now calls `drm_julia_structured_payload()` for a Gaussian `animal(1 | id, Ainv = Ainv)` and expects `animal.*Ainv.*Poisson or Binomial`. Gaussian Ainv remains refused, now checked at the right layer. |
| test-julia-binomial-sd-links-bridge.R:32 | (a) stale test | `drm_julia_binomial_sd_link_route_admitted(structured, link = "cloglog")` is TRUE. The cloglog phylogenetic SD route was admitted deliberately in the 2026-10-26 cloglog slice (docs/dev-log/after-task/2026-10-26-julia-binomial-cloglog-phylo-bridge.md: Julia test 29/29, live bridge filter 71 passed on the paired DRM.jl candidate). The code rejects links outside logit, probit, cloglog. | The cloglog expectation is now TRUE. Added a cauchit expectation of FALSE as the still-refused link of the same kind. |

## 4. Checks

Run on Totoro (4 cores at most, nothing left running), after `pkgload::load_all(".")`, with `testthat::test_file(..., reporter = "silent")`:

| File | passed | failed | error | skipped |
| --- | --- | --- | --- | --- |
| test-julia-binomial-nonlogit-structured-sd-bridge.R | 10 | 0 | 0 | 3 |
| test-julia-phylo-nongaussian.R | 18 | 0 | 0 | 2 |
| test-julia-structured.R | 76 | 0 | 1 | 1 |
| test-julia-binomial-sd-links-bridge.R | 8 | 0 | 0 | 1 |

The one error in test-julia-structured.R is at line 239 ("structured payload requires intercept-only mu and sigma ~ 1"). It is a different stale refusal outside this group: `relmat(1 + x | id, K = K)` with Gaussian is now admitted by the payload. It was already in the original failure log and is not addressed here. The skips are live-Julia tests, which need Julia and were not run.

## 5. What this does not cover

- Live Julia fits were not rerun; the admissions rest on the existing after-task and test evidence cited above.
- The 2026-10-27 after-task note still lists pedigree as blocked for non-logit Binomial; that line is superseded by test-julia-binomial-animal-pedigree-sd-bridge.R and was left unedited.
- Neighbouring failures from the same log (for example `drm_julia_binomial_correlated_sd_component` not found, and the relmat slope test) belong to other groups.
