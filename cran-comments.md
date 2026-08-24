## Submission summary

This is the first CRAN submission of drmTMB, version 0.7.0.

drmTMB fits univariate and bivariate distributional regression models with
Template Model Builder. One formula is supplied for each distributional
parameter, allowing location (`mu`), scale (`sigma`), shape, zero inflation,
and bivariate residual correlation (`rho12`) to have separate predictors.

These comments describe one identified artifact:

* tarball `drmTMB_0.7.0.tar.gz`;
* SHA-256 `115abfa9c378833fc77aec94487c836e098331d4d7a49098936e405fc89919dc`;
* size 5,546,071 bytes;
* 948 archive entries;
* built from clean commit `fb8e6c1a5e297941de1f7b05cf516ace0d35dbe9`.

The SHA-256 and size provide a client-side chain of custody for the uploaded
file; they are not server attestation. Results are separated into exact-byte
and same-source checks. The local and win-builder checks used the tarball
above. GitHub Actions and R-hub checked the exact source commit but built their
own archives.

## R CMD check results

The exact tarball was checked locally on macOS using
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

A separate CRAN-like lane ran with `NOT_CRAN=false`; it also had one expected
first-submission NOTE and no errors or warnings. The full
`NOT_CRAN=true` exact-artifact suite completed with
`FAIL 0 / WARN 70 / SKIP 308 / PASS 21123`. The CRAN-like lane completed in
55 seconds with `FAIL 0 / WARN 19 / SKIP 30 / PASS 3501`.

## Test environments

Exact-byte win-builder checks completed on all three Windows arms:

* R-devel r90443: 1 NOTE, no check errors or warnings; raw tests
  `FAIL 0 / WARN 64 / SKIP 30 / PASS 3501`; results:
  <https://win-builder.r-project.org/ta4JWy8N2LQr/>.
* R-release 4.6.1: 1 NOTE, no check errors or warnings; raw tests
  `FAIL 0 / WARN 19 / SKIP 30 / PASS 3501`; results:
  <https://win-builder.r-project.org/2BcwsfbcFJej/>.
* R-oldrelease 4.5.3: 1 NOTE, no check errors or warnings; raw tests
  `FAIL 0 / WARN 19 / SKIP 30 / PASS 3501`; results:
  <https://win-builder.r-project.org/G2J7Ad8zMIRw/>.

The incoming checks identify `centile`, `misspecification`, and
`uncalibrated` as possible misspellings. These are intentional statistical
terms: centile curves describe fitted distributional references;
misspecification describes an incorrect model; and uncalibrated marks intervals
without route-specific coverage calibration.

Same-source GitHub Actions checks succeeded on macOS, Ubuntu, and Windows:
<https://github.com/itchyshin/drmTMB/actions/runs/32669424670>. R-hub
clang-ASAN, clang-UBSAN, and GCC-ASAN also succeeded with no sanitizer
findings: <https://github.com/itchyshin/drmTMB/actions/runs/32669426464>.
The R-hub rchk job remains visibly red; its protection findings cite installed
TMB headers rather than `drmTMB.cpp`. This is retained as an attributed
diagnostic, not represented as a passing platform check.

## Test-suite design

The CRAN lane retains representative compiled, family, formula, extractor,
error-path, and release-identity tests. Long recovery, simulation, optional
Julia, and development-only reader audits remain in the full `NOT_CRAN=true`
repository suite; they are not run on CRAN. The bounded Windows lane completes
in under two minutes of test time on every tested R version.

## Downstream dependencies

There are no CRAN reverse dependencies because this is the package's first
submission.
