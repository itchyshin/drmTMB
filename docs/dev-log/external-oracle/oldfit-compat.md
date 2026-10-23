# Slice S4 findings: backward-compatibility (old-fit) regression test

**Task**: issue #859, adopt glmmTMB's stored-old-fit pattern
(`old_fit.rds`/`oldfit.rds` in `test_data/`) to protect drmTMB's native
reader contract (`R/reader-contracts.R`) across releases.

**Worktree**: `.worktrees/external-oracle`, drmTMB dev version 0.7.0,
TMB 1.9.21, tested 2026-08-14.

## 1. Does the repo already ship a stored drmTMB fit?

No. Searched `inst/`, `tests/testthat/fixtures/`, and the whole repo for
`*.rds`/`*.rda`:

```
find inst -iname "*.rds" -o -iname "*.rda"   -> (none)
find tests -iname "*.rds" -o -iname "*.rda"  -> (none)
```

`tests/testthat/fixtures/` contains only `spatial-q2-confidence-eye-common.R`
(an R helper, not a serialized fit). There is no prior-release drmTMB fit
object anywhere in the tree to read back, so the glmmTMB pattern of "load a
fit saved by an old CRAN release" cannot literally be reproduced here without
first obtaining a genuine 0.6.0 (or earlier) artifact. This test therefore
builds and round-trips a fit inside the test itself, per the task's stated
preference ("prefer NOT adding a binary fixture if the test can build and
round-trip a fit itself").

## 2. Does a drmTMB fit survive `saveRDS()`/`readRDS()`?

**Crux finding: the TMB automatic-differentiation pointer genuinely dies on
every round trip, including inside the same R process/session** -- but
drmTMB's fit object, taken as a whole, functionally survives because TMB
itself transparently repairs the dead pointer the first time it is used.

Verified directly (`asNamespace("TMB")$isNullPointer`):

```
isNullPointer BEFORE saveRDS:                      FALSE
isNullPointer AFTER readRDS (same process):         TRUE
gr() called on the restored object -> auto-retapes
isNullPointer AFTER first gr() call (post-retape):  FALSE
gr from restored object:  5.686345e-08 -1.275349e-09 4.686146e-07
gr from original object:  5.686345e-08 -1.275349e-09 4.686146e-07
identical values: TRUE
```

Mechanism (confirmed by reading `TMB:::MakeADFun`'s source via `deparse`):
every `obj$fn()`/`obj$gr()` call checks `isNullPointer(ADFun$ptr)` first and,
if the pointer is dead, calls `retape(set.defaults = FALSE)` before
proceeding. Retaping reconstructs the AD tape from the plain-R `data`,
`parameters`, `map`, and `random` arguments that `MakeADFun()` keeps in
`obj$env` (confirmed by inspecting `ls(fit$obj$env)`; none of those retained
fields are themselves external pointers -- only `ADFun`/`ADGrad` are). So the
retape reproduces the original tape bit-for-bit as long as:

- the same compiled `DLL = "drmTMB"` is loaded in the reading session (true
  whenever the reader has called `library(drmTMB)` / `devtools::load_all()`,
  which is required anyway to dispatch the S3 reader methods), and
- the retained `data`/`parameters`/`map` structure is still what the current
  DLL's C++ objective expects (true within one build; **not** guaranteed
  across releases where the C++ signature or R-side spec changed -- see
  Scope below).

I confirmed this in a genuinely separate `Rscript` process too (write a fit
to `oldfit.rds` in one process, `readRDS()` it in a second, freshly started
process after `devtools::load_all()`): `check_drm()`, `summary()`, `ranef()`,
`fitted()`, `predict_parameters()`, `coef()`, `logLik()`, `vcov()`,
`predict()`, `sigma()`, and `fit$obj$fn(fit$opt$par)` all returned correct,
matching values.

### What does NOT need the TMB object at all

Scanning `fit$sdr` (the stored `TMB::sdreport()` result) found **no**
external pointers anywhere in it -- it is plain matrices/vectors. So
`summary()`, `vcov()`, `confint()`-style reads of stored standard errors, and
`logLik()` (which reads the stored scalar `fit$logLik`, not a live
re-evaluation) never depend on the TMB pointer surviving at all.

### What DOES need the TMB object, and how failure is already handled

`check_fixed_gradient()` (one row of `check_drm()`) calls
`object$obj$gr(object$opt$par)` and is the one verb in the current reader
surface that touches the pointer. The package already has two layers of
graceful degradation, both pre-existing (not added by this test):

- if `fit$obj` was dropped entirely (`drm_control(keep_tmb_object = FALSE)`),
  `check_fixed_gradient()` returns a `"note"` row
  ("TMB object was not retained; refit with
  `drm_control(keep_tmb_object = TRUE)`...") instead of touching `obj$gr()`;
- if `fit$obj` is present but `obj$gr()` throws for any reason, the row
  degrades to a `"warning"`, not a hard error, via `tryCatch()`.

I confirmed the `keep_tmb_object = FALSE` path directly: after
`saveRDS()`/`readRDS()`, `check_drm()` reports `fixed_gradient` as a `note`,
zero `warning`/`error` rows overall, and `summary()`/`fitted()` still work.

## 3. What the test asserts

`tests/testthat/test-reader-oldfit-compat.R`, two `test_that()` blocks:

1. **Round trip with the TMB object retained (the default).** Fits a small
   Gaussian model (`n = 40`), records `check_drm()`, `summary()`, `ranef()`,
   `fitted()`, `predict_parameters()`, and `obj$gr()` before serializing.
   Asserts the pointer is alive beforehand, serializes with `saveRDS()` to a
   `withr::local_tempfile()`, reads it back, and asserts:
   - the pointer is now dead (`isNullPointer()` is `TRUE`) -- this is the
     part of the test that would catch a future TMB/R serialization change
     silently making pointers "just work" without retaping, or silently
     breaking retaping;
   - every reader-contract verb reproduces its pre-serialization value
     exactly;
   - `obj$gr()` on the restored fit reproduces the pre-serialization
     gradient and the pointer is alive again afterward (retape happened).

2. **Round trip with the TMB object dropped
   (`drm_control(keep_tmb_object = FALSE)`).** Confirms the already-built
   graceful-degradation path survives serialization too: `fixed_gradient`
   reports `"note"` with the documented refit-guidance message, no
   `warning`/`error` rows appear, and `summary()`/`fitted()` still work.

Both blocks use `TMB:::isNullPointer()` (an internal, unexported TMB
function) purely to observe pointer state for the test's own assertions;
TMB is already an `Imports` dependency (`DESCRIPTION` line 39), so this adds
no new package dependency. No `skip()` is used.

## 4. Scope / what this test does NOT cover

This is a **within-version** guarantee: the fit is built and read back by
the same drmTMB build in the same test run, so it cannot detect breakage
introduced by a real cross-release change to the TMB `data`/`parameters`/
`map` structure (the scenario issue #859 and glmmTMB's `old_fit.rds` are
ultimately about). That would require an actual fit object serialized by an
older drmTMB release (e.g., a real 0.6.0 CRAN or GitHub tag) checked into
`tests/testthat/fixtures/`, which does not exist in this repository today.
A natural follow-up, once a 0.7.0 (or later) release ships, is to freeze a
small fit's RDS from that release into `tests/testthat/fixtures/oldfit.rds`
and add a companion test that reads it under the then-current development
version -- mirroring glmmTMB's pattern exactly, rather than the in-test
round trip this slice implements as the currently feasible substitute.

## 5. Verification run

```
$ R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
    'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-reader-oldfit-compat.R")'
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 15 ]
```

Wall time (package load + both test blocks): ~6 seconds.
