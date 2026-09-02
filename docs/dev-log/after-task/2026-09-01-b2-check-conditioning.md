## 1. Goal

Give `check_drm()` a machine-readable Hessian-conditioning number (minimum eigenvalue, condition number) so a `drmTMB` fit's near-singularity is comparable, not just a bare `pdHess` boolean. This is the R-side half of DRM.jl issue #569, whose `check_drm(fit; grad_tol)` already returns `min_eigval` and `cond`.

## 2. Implemented

A new additive check, `hessian_conditioning`, inserted immediately after `hessian_positive_definite` in `check_drm.drmTMB()`'s row list. It evaluates `object$obj$he(object$opt$par)` (mirroring how `check_fixed_gradient()` already calls `object$obj$gr()`), symmetrizes it, and reports `min_eig` and `cond` (`max(abs(eig))/min(abs(eig))`). For an MSPL fit it reuses the eigenvalues `drm_mspl_hessian_diagnostics()` already computed via `optimHess()` on the unpenalized Laplace objective, rather than recomputing them.

Status logic, deliberately layered to avoid duplicating or contradicting the existing `hessian_positive_definite` warning:
- Non-positive minimum eigenvalue -> `"warning"` (same severity class as the existing non-PD-Hessian warning).
- Positive minimum eigenvalue but condition number above `1e8` -> `"note"` (a clean-but-flat direction, the same "pdHess is necessary, not sufficient" phenomenon `check_standard_errors_inflated()` already documents for a near-flat correlation or `nu`; kept as a note so it does not flip a fit's `attr(x, "ok")`).
- Otherwise -> `"ok"`.

Degradation paths, each with a stated reason (never a bare `NA`):
- `object$obj` not retained (`keep_tmb_object = FALSE`) -> `"note"`.
- Random-effect fits -> `"note"`: TMB's `obj$he()` raises `"Hessian not yet implemented for models with random effects"` for any Laplace-marginalized fit, so this is checked and short-circuited before calling `he()`.
- `he()` throws for any other reason, or returns non-finite entries, or eigen-decomposition fails -> `"warning"` with the caught message.
- MSPL fit whose stored eigenvalues are absent/non-finite -> `"note"`.

The message text explicitly states these numbers are "a genuinely different read of the fit's conditioning than TMB's internal pdHess flag -- comparable across fits, not claimed to be numerically identical to any raw TMB gradient or Hessian quantity" (constraint 4).

## 3a. Decisions and Rejected Alternatives

Considered deriving eigenvalues from `object$sdr$cov.fixed` instead (its condition number is algebraically identical to the Hessian's, since `cov.fixed = solve(hessian.fixed)`). Rejected in favor of calling `obj$he()` directly, because `cov.fixed` requires a successful `pdHess` (`drm_has_sdreport_covariance()`), so it would degrade exactly where the diagnostic is most useful -- a fit whose Hessian is only *slightly* non-PD or whose `sdreport()` failed but whose TMB object still exists. Calling `obj$he()` also mirrors the existing `check_fixed_gradient()` pattern (evaluate the AD object post hoc at the stored optimum), keeping the two checks structurally consistent.

Considered making any ill-conditioning a `"warning"` (as first written). Rejected after the real check_drm() test suite showed a legitimate, previously-passing Student-t `nu` fit (`test-check-drm.R:434-450`) had `pdHess = TRUE` but a genuinely near-zero Hessian eigenvalue (~7.9e-9, driven by AD numerical noise on a weakly identified `nu` direction) -- exactly the phenomenon `check_standard_errors_inflated()` already treats as a `"note"`. Matching that existing severity convention (warning only for non-PD, note for PD-but-flat) kept the new check honest without silently degrading it to always-ok.

Did not add an SE fallback to `vcov.drmTMB()` -- out of scope per the task brief (separate arc gated on a statistical decision).

## 4. Files Touched

`R/check.R`; `man/check_drm.Rd` (regenerated); `tests/testthat/test-check-conditioning.R` (new); this report.

## 5. Checks Run

`Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-check-conditioning.R")'`: seen to FAIL first (feature absent, 9 assertion failures across 5 test blocks), then PASS after implementation (`[ FAIL 0 | WARN 0 | SKIP 0 | PASS 16 ]`).

`devtools::test(filter = "check")` (via `testthat::test_dir("tests/testthat", filter = "check")` with `testthat::set_max_fails(Inf)`): `[ FAIL 0 | WARN 3 | SKIP 1 | PASS 279 ]`. The 3 `WARNING` lines are pre-existing `sd_phylo()`/`sd_phylo1()`/`sd_phylo2()` deprecation notices unrelated to this change; the 1 `SKIP` is an existing "On CRAN" skip.

Did not run the full `devtools::test()` suite, per instruction (43-46 minutes, run once at the integration gate). Confirmed the two known pre-existing `test-missing-predictor-gaussian.R` failures were not touched (not in the `check` filter, not re-run here).

## 6. Tests of the Tests

The first implementation (status `"warning"` for any condition number above `1e8`, regardless of sign of the minimum eigenvalue) broke 3 previously-passing `test-check-drm.R` tests (`attr(chk, "ok")` expected `TRUE`, got `FALSE`) at lines 425, 441, 478 -- all Student-t `nu` fits with a genuinely flat but positive-definite `nu` direction. Diagnosed by printing the raw Hessian and its eigenvalues directly (`fit$obj$he(fit$opt$par)`) to confirm the 5th (nu) row/column was at the AD noise floor (~1e-8 to 1e-11), not merely a differently-scaled parameter. Fixed by splitting severity: non-positive minimum eigenvalue stays `"warning"`, positive-but-ill-conditioned becomes `"note"`. Re-ran the same 3 tests plus the full `check`-filtered suite to confirm the fix and rule out a second regression.

## 7a. Issue Ledger

Addresses the R-side half of DRM.jl issue #569 (drmTMB and DRM.jl `check_drm()` parity: `min_eigval`/`cond` were Julia-only). Not closed here -- this is the R-side diagnostic only; comparing the two sides' numbers for an actual twin fit is out of scope for this slice. No version bump, no push, no merge, no release action.

## 8. Consistency Audit

Diffed `check_row(...)`-emitted check names before/after this change (`grep -oE 'check_row\(\s*\n?\s*"[a-z0-9_]+"'` on `git show HEAD:R/check.R` vs the working tree): the only difference is the addition of `"hessian_conditioning"`. All ~35 existing check names are unchanged, unreordered, and unrenamed. `devtools::document()` was run but only `man/check_drm.Rd` was kept; it also regenerated `man/confint.drmTMB.Rd` (stale roxygen `\code{}` markup drift unrelated to this change, e.g. `\code{exp()}` -> `exp()`) and two untracked man pages (`drm_julia_joint_prepare.Rd`, `drm_julia_joint_result.Rd`) from other lanes' in-progress roxygen comments -- all reverted/removed, since they are out of scope for this slice (`git status --porcelain` confirms only `R/check.R`, `man/check_drm.Rd`, and the new test file are touched).

## 9. What Did Not Go Smoothly

`obj$he()` unconditionally errors ("Hessian not yet implemented for models with random effects") for any Laplace-marginalized fit; this was not obvious from the constraint brief and required checking `length(object$obj$env$random) > 0L` up front rather than relying on a caught error, so random-effect fits get a stated `"note"` reason instead of a `"warning"` about a caught exception.

## 10. Known Residuals

This does NOT compare drmTMB's new numbers against DRM.jl's `check_drm()` output for a shared twin fit (`min_eigval`/`cond` field-by-field parity is unverified). Does NOT touch `vcov.drmTMB()`'s hard-abort behavior on a failed/non-PD Hessian (explicitly out of scope). Random-effect fits (Laplace-marginalized) cannot get a Hessian-conditioning number from `obj$he()` at all -- reported honestly as unavailable, not attempted via a different route (e.g. `sdr$jointPrecision`). The `1e8` condition-number threshold and the note/warning split by sign of the minimum eigenvalue are this slice's judgment call, not a value taken from DRM.jl or an external convention; a future slice may want to recalibrate it once R-Julia parity comparisons exist.

## 11. Well-Conditioned vs Ill-Conditioned Comparison

Well-conditioned fit (`y ~ x1, sigma ~ 1` on 80 independent observations): `min_eig=160.0; cond=2.170`, status `"ok"`.

Ill-conditioned fit (`y ~ x1 + x2, sigma ~ 1` on the same data with `x2 = x1 + rnorm(n, sd = 1e-8)`, i.e. near-perfect collinearity): `min_eig=-0.00000000000003635; cond=16823472960118778.` (~1.68e16), status `"warning"`.

## 12. Follow-up: B2-G3 adversarial-pass fix (tolerance, and the random-effect scope gap)

An adversarial pass, reproduced independently by the coordinator, refuted the "purely additive" claim in section 8: `hessian_conditioning` was additive in *names* but not in *verdict*. `bf(y ~ x + x2, sigma ~ 1)` with `x2 = x + 1e-9*rnorm(n)` had `pdHess = TRUE`, all standard errors finite, and an ok gradient check, yet `hessian_conditioning` alone flipped `attr(ck, "ok")` to `FALSE` on `min_eig = -3.57e-14` against a top eigenvalue of ~400-600 -- a bare sign test with no tolerance, firing on floating-point round-off.

**Diagnosis.** `object$obj$he()` is TMB's AD Hessian, not a finite-difference one, so its own roundoff floor sits at O(eps) relative to scale (empirically `|min_eig| / max_abs_eig ~ 1e-16` to `1e-17` in repeated near-duplicate-predictor constructions, i.e. within ~1-2 orders of magnitude of `.Machine$double.eps` itself, ~2.22e-16), not the O(sqrt(eps)) floor associated with finite-difference derivatives. A genuinely resolved (non-roundoff) tiny eigenvalue, constructed by making the collinearity looser (`sd = 1e-6` instead of `1e-9`) so the true curvature is bigger than the AD roundoff floor, sat 4-5 orders of magnitude above that floor (`min_eig ~1.2e-10` against the same ~600-scale top eigenvalue). That gap is where the tolerance lives.

**The fix.** `tol <- hessian_conditioning_eps_multiplier * .Machine$double.eps * max(max_abs_eig, 1)`, with `hessian_conditioning_eps_multiplier <- 100` (headroom for accumulated rounding across the Hessian's O(p^2) entries). Three regimes, justified in a code comment directly above `hessian_conditioning_row()`:
1. `min_eig < -tol` -> `"warning"` (robustly, resolvably negative; matches `check_hessian()`'s existing non-PD severity).
2. `abs(min_eig) <= tol` -> `"ok"`. The sign is not trustworthy at this scale and any condition number computed by dividing by it is itself roundoff-dominated (two runs of the same construction, differing only in seed/session, produced condition numbers an order of magnitude apart: `1.68e16`, `1.26e16`, `1.12e16`). `pdHess` already reports whether TMB itself judged the fit positive-definite; fabricating a numerically unstable condition number here would be exactly the "decoration, not signal" failure the original brief warned against. The raw `min_eig`/`cond` values are still reported in the row's `value` field for transparency; only the *status* defers.
3. `min_eig > tol` -> resolvable positive curvature; condition number computed normally, `"note"` above `1e8`, matching the existing `check_standard_errors_inflated()` severity convention for a clean-pdHess-but-weakly-identified direction.

I considered a looser `sqrt(eps) * max_abs_eig` tolerance (as the coordinator's message suggested as one example form, and as `check_known_v()` already uses elsewhere in this file for a user-supplied covariance matrix's eigenvalues). Rejected it here: `check_known_v()`'s eigenvalues come from ordinary floating-point arithmetic on user data, not AD, so the looser floor is appropriate there; applied to an AD Hessian, `sqrt(eps) * max_abs_eig` (~1e-6 to 1e-5 for these fits) would have swallowed the resolved `sd = 1e-6` case's genuine `1.2e-10` eigenvalue as well, discarding real signal it did not need to discard.

**Regression coverage (`tests/testthat/test-check-conditioning.R`).** Replaced the earlier "ill-conditioned" test, which had relied on a near-duplicate-predictor fit with `sd = 1e-8` noise -- itself, it turned out, at the same roundoff floor as the reported defect (`min_eig ~ -3.6e-14`, empirically indistinguishable run-to-run from the `sd = 1e-9` defect case) -- with two tests:
- A deterministic, reproducible "genuinely (resolvably) indefinite" test that mocks `obj$he()` to return `diag(c(500, 300, 150, -50))`: unambiguously beyond any defensible tolerance, so it is not a floating-point coin flip. Confirms `status == "warning"` and `attr(chk, "ok") == FALSE`.
- A regression test reproducing the reported defect exactly (`x2 <- x + 1e-9 * rnorm(n)`), asserting `pdHess == TRUE`, `hessian_conditioning` status `"ok"`, and `attr(chk, "ok") == TRUE` with no `"warning"`/`"error"` row anywhere in the table.

Also added a random-effect fit test (see next paragraph) and kept all prior tests (well-conditioned ok row, `keep_tmb_object = FALSE` note, `obj$he()`-errors warning, unchanged check names).

**Red-first evidence.** Before this fix, in this same session, the exact reproduction of the reported defect (`x2 <- x + 1e-9*rnorm(n)`, `n = 200`, seed 1) produced `hessian_conditioning` status `"warning"` with `attr(ck, "ok") == FALSE` -- the defect as reported. After the fix, the identical script produces status `"ok"` with `attr(ck, "ok") == TRUE`.

**Second finding: the row does not exist for random-effect or REML fits.** `obj$he()` has no Laplace support ("Hessian not yet implemented for models with random effects"), so `hessian_conditioning` was already, silently, a permanent `note` with value `NA` for every mixed-model fit -- the model class the R/Julia parity programme is mostly about. Not fixed here (a design question, not a patch), but now stated plainly in three places: the roxygen `@details` on `check_drm()` ("**This row is unavailable for any random-effect or REML fit**... always a `note` with value `NA` there, never a computed number"), the code comment above `check_hessian_conditioning()` ("IMPORTANT SCOPE LIMIT... do not read a `note` row here as evidence that a random-effect fit's Hessian is well- or ill-conditioned"), and the `note`'s own message text ("NOT AVAILABLE for this fit because it has random effects... This is a scope limit of the diagnostic, not a report that the fit is fine"). A new test (`check_drm() reports hessian_conditioning as an explicit note for random-effect fits`) locks in the message wording (`"NOT AVAILABLE"`, `"random effects"`).

**Correction to prior prose.** All documentation and comments say "Hessian" (from `obj$he()`), never "covariance" -- confirmed by grep; no change was needed on this branch's own text, the earlier miswording was in an outside reviewer's own notes, not this code.

**Verification.** `tests/testthat/test-check-conditioning.R`: `FAIL 0 | WARN 0 | SKIP 0 | PASS 28`. `devtools::test(filter = "check")` (`testthat::test_dir("tests/testthat", filter = "check")`, `set_max_fails(Inf)`): `FAIL 0 | WARN 3 (pre-existing sd_phylo deprecation notices) | SKIP 1 | PASS 291`. Did not run the full suite (another run already in progress per the coordinator).
