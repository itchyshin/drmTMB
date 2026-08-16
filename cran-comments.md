## Submission summary

This is the first CRAN submission of drmTMB, version 0.7.0.

drmTMB fits univariate and bivariate distributional regression models with
Template Model Builder: one formula per distributional parameter, so location
(`mu`), scale (`sigma`), shape, zero inflation, and bivariate residual
correlation (`rho12`) can each carry their own linear predictor.

These comments describe one identified artifact:

* tarball `drmTMB_0.7.0.tar.gz`
* SHA-256 `0d150ef38b8d3b8b2d3dca084a62f8242832048b01e60caa4b08c5388b95e075`
* size 10,087,906 bytes
* built from commit `302ac2579969f7d5f949a73610468c9f73f938c8`

Check results below fall into two classes, and this file keeps them distinct:

* **Exact-bytes** — run against the tarball above: the local
  `R CMD check --as-cran` and the valgrind run.
* **Same-source** — run at commit `302ac2579`, the commit this tarball was
  built from, with the checking service building its own tarball from that
  source: the three-platform matrix, the sanitizer runs, and win-builder.

## R CMD check results

`R CMD check --as-cran --run-donttest` on the tarball above, R 4.6.0
(2026-04-24), aarch64-apple-darwin23:

```
Status: 1 NOTE
```

0 ERRORs, 0 WARNINGs. The single NOTE is:

```
* checking CRAN incoming feasibility ... NOTE
Maintainer: 'Shinichi Nakagawa <itchyshin@gmail.com>'

New submission
```

This is expected for a first submission.

`checking installed package size` reports **INFO**, not a NOTE: installed size
31.7Mb, of which `libs` is 13.7Mb and `doc` is 11.6Mb. The compiled size is
intrinsic to a Template Model Builder package, which compiles one C++ template
covering every family; CRAN's `glmmTMB` shows the same pattern. The vignette
directory carries the worked ecological and evolutionary examples that make the
distributional grammar usable.

## Test environments

**Exact-bytes**, run against the tarball identified above:

* macOS aarch64 (local), R 4.6.0 — `R CMD check --as-cran --run-donttest`:
  Status 1 NOTE, as above.
* valgrind (memcheck) 3.22.0 with R 4.5.3, `--leak-check=full`, on a documented
  seven-file subset of the test suite: zero findings attributable to drmTMB's
  compiled code (no `drmTMB.so` frame in any error backtrace), 0 bytes
  definitely or indirectly lost, 0 test failures. Remaining contexts trace to
  glibc thread-local storage via the `cli` package, `libR`, and TMB/CppAD
  headers.

**Same-source**, at commit `302ac2579` (GitHub Actions and R-hub build their
own tarballs):

* ubuntu-latest, windows-latest, macos-latest (R release, GitHub Actions):
  all passing. The Windows job runs the package's full test suite (larger than
  the CRAN-lane subset).
* R-hub `clang-ubsan`: Status OK, including all vignette rebuilds — no
  undefined-behaviour findings.
* R-hub `gcc-asan`: tests, examples, and `--run-donttest` clean — no
  address-sanitizer findings.
* R-hub `clang-asan`: no sanitizer findings of any kind. The job itself exits
  non-zero because three numerically delicate spatial/phylogenetic vignette
  example fits do not converge in that unoptimized instrumented build; the
  same vignettes rebuild cleanly in every other environment, including
  clang-ubsan's instrumented build.
* R-hub `rchk`: tool findings confined to R internals and TMB's templated
  `objective_function<double>::operator()()` — none attributable to this
  package's code; the same pattern rchk shows for other large TMB packages.
* win-builder (R-release, R-devel, R-oldrelease): submitted against the exact
  tarball on 2026-08-16; results will be reflected here when they arrive.

## Downstream dependencies

There are none: this is a first submission, so there are no reverse
dependencies to check.

## Test-suite design for CRAN

The test suite distinguishes a CRAN lane from the full local lane. On CRAN,
long-running simulation-based recovery tests are skipped (`skip_on_cran()`),
leaving roughly 12,000 assertions that complete in about four minutes of test
time in the local CRAN-shaped check. The full recovery evidence runs on the
package's own infrastructure and is documented in the repository's dev-log.
