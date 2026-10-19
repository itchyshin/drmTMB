# 2026-10-16: `check_drm()` print fits 80 columns (#1534)

Reader: the maintainer reviewing the README's first diagnostic output, and the
next agent touching `print.drm_check()`.

## What changed

`print.drm_check()` handed the full data frame to `print.data.frame`, so the
`message` column (padded to about 380 characters) forced R to split the table
into three blocks at 80 columns. It now prints one block per check, with
`check`, `status` and `value` aligned on one line (the value wraps if needed)
and the full message wrapped underneath. The new internal
`format_drm_check_rows()` does the layout. No column is truncated and the
header lines (`<drm_check: ...>` and the `ok: ...; notes: ...` counts) are
unchanged. The object itself, `[.drm_check`, `attr(, "ok")` and every check
row are untouched; only the print layout changed.

The README has no printed `check_drm()` output block (only the call), so it
needed no edit.

## Forcing test

`tests/testthat/test-check-drm.R`: a beta-binomial fit that carries the #1509
`beta_binomial_sigma_boundary` row is printed at `width = 80` and `width = 60`;
every line must fit, and every check name and message must survive the wrap.
It fails on the base commit (no wrapping) and passes with the fix.

## Not done

Messages are shown for every row, not only for non-ok rows, because the lane
brief asks to keep all information. A `verbose = FALSE` mode that hides ok
messages, as the issue suggests as an alternative, is a possible follow-up.

## Rebase onto the rewritten #1509 (2026-10-19)

#1509 is still open, so this branch was rebased onto its rewritten head
(`claude/lane-c-convergence-inference` at 78a65181d), not onto `main`. Only
this PR's three commits were replayed; `git range-diff` shows each patch
unchanged, and there were no textual conflicts. `R/check.R` and
`tests/testthat/test-check-drm.R` are identical on the old and new base.

`devtools::document()` (roxygen2 8.0.0) rewrote 39 `man/*.Rd` files. None
of them comes from this PR, which changes no roxygen lines. They are older
wording from roxygen sources that `main` itself never regenerated (for
example `R/formula-markers.R` still says "The first fitted route builds"
while `man/animal.Rd` on `main` says "When a pedigree is supplied"). They
were not committed.

Full local suite on the rebased head (macOS arm64, `-O2` build, four
shards): 3 failed, 0 errors, 48,635 passed, 93 skipped.
`test-check-drm.R` passes 319 (283 on the base plus 36 from the new test).
The three failures reproduce with identical values on the base head:
`test-nbinom2-sigma-structured-recovery.R:52-53` (log-likelihood gap 9.0,
thresholds 15 and 10) and `test-associate-pairs-bernoulli-bernoulli.R:40`
(0.551583976 against 0.551583956). The two Tweedie blocks of
`test-numeric-kernel-oracle.R` do not finish on this machine: the one-row
fit drives sigma towards zero and TMB's `tweedie_logW` series loop stops
moving, which is #1585. The rest of that file passes (17 tests, 373
expectations).
