# Slices 1049-1058: Light Check Vignette Source Fix

## Goal

Ada ran a light `R CMD check` gate after the Phase 18 runner work and fixed the
vignette-source failures it exposed.

## Problem Found

The first check run failed while sourcing vignette code:

- `vignettes/convergence.Rmd` tangled example chunks that referenced
  `check_drm(fit)` without a constructed fit in the source stream.
- `vignettes/large-data.Rmd` tangled example chunks that referenced `dat`
  without constructing the large example dataset in the source stream.

Both articles are example-style guides with non-evaluated chunks, so they
should not contribute executable source chunks to R CMD check.

## Change

- Added `purl=FALSE` to executable chunk headers in
  `vignettes/convergence.Rmd`.
- Added `purl=FALSE` to executable chunk headers in
  `vignettes/large-data.Rmd`.
- Verified direct tangling with `knitr::purl()` now produces no executable
  example hits for those two files.

## Validation

Command:

```sh
Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = c('--no-build-vignettes'))"
```

Result:

- 0 errors, 0 warnings, 1 note.
- The remaining note was: unable to verify current time.
- Duration: 5m 11.8s.

## Team Learning

- Ada: example-only vignettes need purl hygiene, not only `eval = FALSE`.
- Grace: the package now clears the light check gate with no errors or
  warnings after the vignette-source fix.
- Pat: the example prose stays visible in rendered articles while no longer
  being treated as runnable check code.
- Rose: preserve this as a release-readiness lesson for future example-heavy
  tutorial edits.

## Known Limitations

- This was a light check with `--no-build-vignettes` and no manual.
- The single note was environmental time verification, not a package-source
  issue observed in this run.

## Next Actions

1. Run `git diff --check`.
2. Write a final recovery checkpoint before stopping at 03:30.
