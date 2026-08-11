## Submission summary

This is the first CRAN submission of drmTMB, version 0.7.0.

drmTMB fits univariate and bivariate distributional regression models with
Template Model Builder: one formula per distributional parameter, so location
(`mu`), scale (`sigma`), shape, zero inflation, and bivariate residual
correlation (`rho12`) can each carry their own linear predictor.

These comments describe one identified artifact:

* tarball `drmTMB_0.7.0.tar.gz`
* SHA-256 `2176e4b81b887e8d944456e4a74fa581afda959d0d2a5468c89bc700d693cda9`
* size 9,925,713 bytes
* built from commit `a75c3c9013e1e7c4ab8e56aa13baf5e668b99c76`

Check results below fall into two classes, and this file keeps them distinct:

* **Exact-bytes** — run against the tarball above: the local `R CMD check --as-cran`
  and the valgrind run.
* **Same-source** — run at commit `a75c3c901`, the commit this tarball was built
  from, with the checking service building its own tarball from that source: the
  three-platform matrix and the sanitizer runs. These describe the same source,
  not the same bytes.

## R CMD check results

`R CMD check --as-cran --run-donttest` on the tarball above, R 4.6.0 (2026-04-24),
aarch64-apple-darwin23:

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
31.3Mb, of which `libs` is 13.7Mb and `doc` is 11.4Mb. The compiled size is
intrinsic to a Template Model Builder package, which compiles one C++ template
covering every family; CRAN's `glmmTMB` shows the same pattern. The vignette
directory carries the worked ecological and evolutionary examples that make the
distributional grammar usable.

## Test environments

**Exact-bytes**, run against the tarball identified above:

* macOS aarch64 (local), R 4.6.0 — `R CMD check --as-cran --run-donttest`:
  Status 1 NOTE, as above.
* valgrind (memcheck) 3.22.0 with R 4.5.3, on a documented seven-file subset of
  the test suite: `ERROR SUMMARY: 0 errors from 0 contexts`, 0 bytes definitely
  or indirectly lost, across 1,653 assertions. This is a named subset, not the
  full suite; the full suite exceeds the wall-clock budget under memcheck. The
  subset excludes `test-binomial-response.R` because it initialises Julia, whose
  precompilation cache segfaults under memcheck for reasons outside this package.

**Same-source**, run at commit `a75c3c901` with the service building its own
tarball from that source:

* GitHub Actions ubuntu-latest, macOS-latest, windows-latest, R-release —
  success on all three.
  Run: https://github.com/itchyshin/drmTMB/actions/runs/31435894784
* R-hub clang-asan, clang-ubsan, gcc-asan — success on all three.
  Run: https://github.com/itchyshin/drmTMB/actions/runs/31435909361

R-hub's `rchk` job reports a failure. Every protection finding is inside TMB's
own header, `TMB/include/tmb_core.hpp` (lines 1241/1243, 1512/1515, 2275/2277),
reported as `[UP] attempt to unprotect more items than protected` and `[PB]
possible protection stack imbalance`. Three further lines are rchk describing its
own analyser limitation (`ignoring variable ... as it has address taken, results
will be incomplete`) and carry no file path. There are no protection findings
attributable to `src/drmTMB.cpp`.

**Outstanding before upload:** win-builder (R-release and R-devel) has not been
run against this tarball. Submission should not proceed until it has.

## Submission notes

* `DESCRIPTION` quotes the method name 'Tweedie' and hyphenates
  "semi-continuous" to resolve possible-spelling flags.
* Routine check time on the CRAN lane is bounded by keeping the exhaustive
  simulation harness and heavy diagnostics in the package's non-CRAN test lane
  (`NOT_CRAN=true` in repository CI). On the CRAN lane, `checking tests` runs in
  203s/227s.
* Random-effect SD profile intervals warn at variance-component boundaries
  (`drmTMB_profile_boundary_warning`). A 10-group gate measured conditional
  undercoverage matching `lme4` on the same seeds. This is documented in
  `?confint.drmTMB` and is a property of the estimator at small group counts,
  not a packaging defect.
* The package is labelled experimental in its lifecycle badges deliberately: the
  distributional grammar is stable, but several families are still gaining
  simulation-based recovery evidence.

## Reverse dependencies

This is a new package; there are no reverse dependencies.

## Notes for the CRAN team

* The required inference engine is bundled TMB. `JuliaCall` is Suggested only,
  supporting an optional experimental `engine = "julia"` backend; Julia-backed
  tests are skipped on CRAN.
* `License: GPL (>= 3)` with `LinkingTo: TMB` (GPL-2) follows the arrangement
  already on CRAN in `glmmTMB` (AGPL-3, `LinkingTo: TMB`).
* Code reused from the sister package gllvmTMB is recorded with its upstream
  commit in `inst/COPYRIGHTS`.
