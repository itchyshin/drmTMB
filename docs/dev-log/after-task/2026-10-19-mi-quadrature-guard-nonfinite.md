# mi() quadrature guard: classed error on non-finite values

## 1. Goal

Close the two non-blocking follow-ups the R reviewer left on #1513 (recorded
on #1532): non-finite values passed silently through the post-fit `mi()`
quadrature accuracy guard in `R/mi-weights.R`, and the live Beta
`weights = 2` fit in `tests/testthat/test-mi-weights-1459.R` had no
`skip_on_cran()`.

## 2. Implemented

`drm_mi_quadrature_inaccurate_hits()` had three silent exits. A NA or NaN
Beta/zero-one-Beta missing-row mean was dropped by `mu[is.finite(mu)]`. A NA,
NaN, or infinite Gamma log CV returned no hit. A finite log CV whose `exp()`
overflowed to `Inf` also returned no hit. Each site now calls the new
`drm_abort_mi_quadrature_guard_nonfinite()`, which raises class
`drmTMB_mi_quadrature_guard_nonfinite` and names the predictor and the
offending value. An absent log CV (length zero) still returns no hit; that is
a missing slot, not a non-finite value. The live Beta weights test now starts
with `skip_on_cran()`, like its Gamma sibling.

## 3. Decisions and Rejected Alternatives

The task suggested `drmTMB_mi_weights_nonfinite` as an example class. In this
file "weights" means observation weights (#1459), and a zero, NA, or
non-finite observation weight on a missing-x row already has its own error
(`drmTMB_mi_zero_weight_missing`). The
values checked here are the fitted prior mean and CV, so the class follows the
guard's own `drmTMB_mi_quadrature_*` family. The existing
`drmTMB_mi_quadrature_nonfinite` was not reused, because its message describes
a NaN or `-Inf` log-likelihood row, which is a different failure.

## 4. Files Touched

`R/mi-weights.R`, `tests/testthat/test-mi-quadrature-1476-1477.R` (three new
`test_that()` blocks), `tests/testthat/test-mi-weights-1459.R` (one
`skip_on_cran()`), `inst/extdata/env-skip-census.tsv` (one count, re-derived
by `tools/write-env-skip-census.R`), `NEWS.md`, `docs/design/03-likelihoods.md`
(one sentence in each of the Beta and Gamma guard passages), and this report.
No C++, no C17 pinned file, and no generated documentation changed.

## 5. Checks Run

- Red on unchanged `R/`: the three new blocks gave 8 failures (Beta NA and NaN;
  Gamma log CV NA, NaN, `Inf`, `-Inf`; second-slot NaN; CV overflow at log CV
  710), each "Expected ... to throw a error with class
  <drmTMB_mi_quadrature_guard_nonfinite>".
- Green with the fix, `NOT_CRAN=true`: `test-mi-quadrature-1476-1477.R` and
  `test-mi-weights-1459.R` both 0 failures, 0 errors.
- `python3 tools/capability_ledger.py --check`: OK (31 generated outputs).
- `python3 tools/capability_ledger.py --check-c14-receipt-equivalence`: OK
  (3 eligible, 7 source-different retained receipts; C17 current-source
  compatibility PASS).
- C17 recertification: see section 9. Not rewired.
- Full local suite on this Mac, in two passes because the first one hung
  (section 9). Pass 1, `devtools::test()` at 27f36e9de: the 269 files before
  `numeric-kernel-oracle` ran, with five numbered failures. Two were
  `test-env-skip-census.R`, caused by this branch's new `skip_on_cran()`;
  `tools/write-env-skip-census.R` re-derived the census (`test-mi-weights-1459.R`
  cran-lane sites 1 to 2, commit 00601a9df) and the file then passed 5/5. One
  was `test-associate-pairs-bernoulli-bernoulli.R:40` (`eta` 0.551583976
  versus 0.551583956 at `tolerance = 1e-8`) and two were
  `test-nbinom2-sigma-structured-recovery.R:52-53` (log-likelihood gaps).
  Those three fail identically on unchanged `origin/main` on this Mac; the
  nbinom2 test is skipped on CI by `skip_fragile_recovery()`. Pass 2, the
  remaining 185 files (`objective-at` to `zi-poisson`): 34,759 expectations,
  0 failed, 0 errors, 14 skips, 39 warnings, 113.2 minutes.

## 6. Tests of the Tests

All eight new expectations failed on the unchanged helper and pass on the fix.
The second-slot case proves the error reaches `missing_predictor2`, not only
slot 1. The existing warning tests (Beta mean near 0, Gamma CV at least 3, the
healthy Gamma fit that must not warn) still pass, so the error did not replace
the warning on finite values.

## 7. Issue Ledger

Refs #1532, which stays open for its Gamma CV and Poisson items. No new issue.

## 8. Consistency Audit

NEWS, the design doc, the helper, and the tests name the same class and the
same three cases. The only caller of the helper is the post-fit call in
`R/drmTMB.R`. On a live fit, the earlier fitted-objective probe usually stops
a fit with non-finite `mi()` parameters first (class
`drmTMB_mi_quadrature_nonfinite`), so the new error is mainly a backstop that
removes the silent path inside the helper itself.

## 9. What Did Not Go Smoothly

`tools/recertify-c17.py` first refused because the tracked runner output
folder `2026-08-01-lane-c-c17c1-c14-model15-compatibility-run-1` (committed in
2d2db519f) already exists. It was moved to `/tmp`, the tool was run, and the
folder was restored; `git diff` on it is empty. The second run then refused to
rewire: `mean_tau_relative_error` moved by 4.3e-12 (mc-0568), 1.3e-11
(mc-0569), and 5.3e-12 (mc-0576) against the committed receipt, and the
tolerance is exact. The committed receipt was produced on a Linux host. The
same runner on unchanged `origin/main` (5aa693bab) on this Mac gave the same
three values bit for bit (0.0990031773657071, 0.166077467316444,
0.0613049351662347), and all five pinned blobs match. So the gap comes
from Linux-versus-macOS arithmetic, and this change plays no part. The
tolerance was not raised and the manifest was not rewired. `R/mi-weights.R` is not a C17 pinned file,
so both ledger checks pass without a new receipt.

The first full-suite pass hung in `test-numeric-kernel-oracle.R` after 365
expectations. Two stack samples showed a single direct `obj$fn()` call inside
TMB 1.9.21's `tweedie_logW()` (`tiny_ad/tweedie/tweedie.cpp`), calling only
`log()`, which places it in the bound search. That loop steps `j += 5` from
`jmax = y^(2-p) / (phi (2-p))` and cannot terminate once `jmax` exceeds 2^53.
That a tiny `phi` pushed `jmax` past 2^53 here is AGENT-INFERRED from the
source; the call's arguments were not captured. Unchanged `origin/main` on this Mac stopped at the same 365th
expectation and was killed after 15 minutes. CI completes that file, so the
trigger depends on the platform. The file was excluded from pass 2.

## 10. Known Residuals

C17 stays certified by the existing Linux receipt. An exact recertification
needs the Linux host that produced it. `test-numeric-kernel-oracle.R` was not
run to completion on this Mac, on main or on the branch. The three Mac-only
failures in two files above are pre-existing. `devtools::document()` (roxygen2 8.0.0)
rewrote 39 `man/*.Rd` files from roxygen text already on main; none come from
this change, `NAMESPACE` and `DESCRIPTION` are unchanged, and the output is
left uncommitted as instructed.

## 11. Team Learning

When a recertification tool demands exact reproduction, run the same tool on
unchanged main on the same machine before reading drift as a behaviour change.
That one control run separates platform arithmetic from a real regression.

## 12. Cross-Product Coverage

Covers the R-side accuracy guard for Beta and Gamma `mi()` terms in both
slots. Zero-one-Beta shares the Beta branch but has no separate test. This
does NOT cover the C++ quadrature itself, the Julia route (which refuses
Beta/Gamma `mi()`), or any change to the guard thresholds.
