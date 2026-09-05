## Resubmission

This resubmission addresses the example issues identified by Konstanze
Lauseker:

* `meta_vcov_bivariate()` is exported in the generated `NAMESPACE` and its
  executable example is kept on `?meta_vcov_bivariate`. The unrelated
  `?drm_formula` and `?random_effect_scale_formulas` pages contain no examples
  for this helper. A regression test now checks both the generated and loaded
  namespace exports.
* The commented-out calls in `?confint.drmTMB` and `?corpairs` are executable
  examples. The 99-refit bootstrap call is wrapped in `\donttest{}`; the other
  calls run as regular examples.
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
* SHA-256 `1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`;
* size 4,368,396 bytes;
* built from clean commit `6170fbeeea65f22444d7b0934f4e808c40744d22`.

Results are separated into exact-byte checks and same-source checks. The
local and win-builder checks used the tarball above. GitHub Actions and R-hub
checked the exact source commit but built their own archives.

## R CMD check results

The exact tarball was checked locally with R 4.6.0 on macOS using
`R CMD check --as-cran --run-donttest --no-manual`:

```
Status: 1 NOTE
```

There were 0 errors and 0 warnings. The NOTE was the expected first-submission
NOTE:

```
Maintainer: 'Shinichi Nakagawa <itchyshin@gmail.com>'

New submission
```

The selected CRAN test lane completed in 45 seconds elapsed (54 seconds
reported) with `FAIL 0 / SKIP 30 / PASS 3501`. Installed size was 24.8 MB,
including 13.7 MB of compiled libraries and 4.7 MB of documentation.

## Test environments

Exact-byte win-builder checks completed on all three Windows arms:

* R-devel r90424: 1 NOTE, 0 errors, 0 warnings; tests 149 seconds;
  `FAIL 0 / SKIP 30 / PASS 3501`.
* R-release 4.6.1: 1 NOTE, 0 errors, 0 warnings; tests 152 seconds;
  `FAIL 0 / SKIP 30 / PASS 3501`.
* R-oldrelease 4.5.3: 1 NOTE, 0 errors, 0 warnings; tests 110 seconds;
  `FAIL 0 / SKIP 30 / PASS 3501`.

The incoming checks identify `centile`, `misspecification`, and `uncalibrated`
as possible misspellings. These are intentional statistical terms: centile
curves describe fitted distributional references; misspecification describes
an incorrect model; and uncalibrated marks intervals without route-specific
coverage calibration.

R-devel and R-release also echoed a stale 404 for
`function-map-cheatsheet.png` from earlier same-package/version checks. The
final source and tarball contain neither that link nor the attributed installed
HTML file, the returned Windows binary does not contain it, and a fresh
network-enabled exact-tarball check while the URL returned 404 produced only
the first-submission NOTE. No candidate URL is being excused by this comment.

Same-source GitHub Actions checks succeeded on macOS, Ubuntu, and Windows with
the full development suite. R-hub clang-ASAN, clang-UBSAN, and GCC-ASAN also
succeeded with no sanitizer findings and `PASS 3501`. The R-hub rchk job
remains visibly red: its protection findings are in installed TMB headers and
none cites `drmTMB.cpp`.

## Test-suite design

The CRAN lane retains representative compiled, family, formula, extractor,
error-path, and release-identity tests. Long recovery, simulation, optional
Julia, and development-only reader audits remain in the full `NOT_CRAN=true`
repository suite; they are not run on CRAN. The bounded Windows lane completes
in under three minutes on every tested R version.

## Downstream dependencies

There are no CRAN reverse dependencies because this is the package's first
submission.
