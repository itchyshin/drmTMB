## Resubmission

This resubmission addresses the example issues identified by Konstanze
Lauseker:

* `meta_vcov_bivariate()` is exported in the generated `NAMESPACE` and its
  executable example is kept on `?meta_vcov_bivariate`. The unrelated
  `?drm_formula` and `?random_effect_scale_formulas` pages contain no examples
  for this helper. A regression test now checks both the generated and loaded
  namespace exports.
* The commented-out calls in `?confint.drmTMB` and `?corpairs` are executable
  regular examples. The 99-refit bootstrap call also runs normally; the complete
  `?confint.drmTMB` example block takes under 2 seconds in the exact-tarball
  timing check.
* The package contains no `\dontrun{}` examples. The association confidence-
  interval and streamlined association-prediction examples both run normally.

## Submission summary

This is the first CRAN submission of drmTMB, version 0.7.0.

drmTMB fits univariate and bivariate distributional regression models with
Template Model Builder. One formula is supplied for each distributional
parameter, allowing location (`mu`), scale (`sigma`), shape, zero inflation,
and bivariate residual correlation (`rho12`) to have separate predictors.

These comments describe one identified artifact:

* tarball `drmTMB_0.7.0.tar.gz`;
* SHA-256 `76e43f576fc3f651b97f95690f4aa7b1e0ed683c9c6fba544a923fa1d4c5da7c`;
* size 5,546,561 bytes;
* 949 archive entries;
* built from clean commit `9abcc00b74a1286e6fa47156af7d84c249d2134c`.

Results are separated into exact-byte checks and same-source checks. The
local and win-builder checks used the tarball above. GitHub Actions and R-hub
checked the exact source commit but built their own archives.

## R CMD check results

The exact tarball was checked locally with R 4.6.0 on macOS using
`R CMD check --as-cran --run-donttest`:

```
Status: 1 NOTE
```

There were 0 errors and 0 warnings. The NOTE was the expected first-submission
NOTE:

```
Maintainer: 'Shinichi Nakagawa <itchyshin@gmail.com>'

New submission
```

The selected CRAN test lane completed in 46 seconds elapsed (58 seconds
reported) with `FAIL 0 / SKIP 30 / PASS 3501`. Installed size was 24.8 MB,
including 13.7 MB of compiled libraries and 4.7 MB of documentation.

The examples completed in 15 seconds elapsed (16 seconds reported), including
the reviewer-named bootstrap, profile, and association examples. The PDF and
HTML manuals were both rebuilt successfully.

## Test environments

Fresh same-source GitHub Actions checks on macOS, Ubuntu, and Windows and R-hub
clang-ASAN, clang-UBSAN, GCC-ASAN, and rchk checks were started for commit
`9abcc00b74a1286e6fa47156af7d84c249d2134c`. Their final results will replace
this sentence before upload. External results for predecessor artifacts are not
attributed to this resubmission candidate.

## Test-suite design

The CRAN lane retains representative compiled, family, formula, extractor,
error-path, and release-identity tests. Long recovery, simulation, optional
Julia, and development-only reader audits remain in the full `NOT_CRAN=true`
repository suite; they are not run on CRAN. The bounded Windows lane completes
in under three minutes on every tested R version.

## Downstream dependencies

There are no CRAN reverse dependencies because this is the package's first
submission.
