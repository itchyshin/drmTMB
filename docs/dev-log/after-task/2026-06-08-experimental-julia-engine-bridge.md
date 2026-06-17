# After Task: Experimental Julia Engine Bridge

Supersession note: this note records the first experimental bridge as it stood
on 2026-06-08. Later 2026-06-09 slices changed the Gaussian phylogenetic
default route, reduced bridge overhead, added partial covariance, and admitted
profile/bootstrap `confint()` for one Gaussian phylogenetic SD target; see
`docs/dev-log/after-task/2026-06-09-julia-sparse-lbfgs-phylo-default.md`,
`docs/dev-log/after-task/2026-06-09-julia-bridge-overhead-reduction.md`,
`docs/dev-log/after-task/2026-06-09-julia-confint-bridge-slice.md`, and
`docs/dev-log/after-task/2026-06-09-julia-profile-bridge-parity.md`.

## Goal

Implement the first usable `drmTMB(..., engine = "julia")` path from R into
DRM.jl, without overstating coverage beyond the tested Gaussian bridge slice.

## Implemented

`drmTMB()` now accepts `engine = c("tmb", "julia")`. The default `engine = "tmb"`
keeps the existing native path. The experimental `engine = "julia"` path
validates the request, serializes `bf()` formula entries to parameter-keyed
strings, calls `DRM.drm_bridge()` through JuliaCall, and reconstructs a
lightweight `drmTMB_julia` object with common fitted-model methods.

The R bridge is intentionally limited to Gaussian one-response and two-response
models plus one Gaussian phylogenetic mean cell:
`phylo(1 | species, tree = tree)` with `sigma ~ 1`. Non-Gaussian families are
rejected until coefficient-scale parity tests cover the DRM.jl and drmTMB
parameterization differences.

## Mathematical Contract

For this slice, the bridge preserves the Gaussian public parameter contract:
`mu` is the response mean, `sigma` is the residual standard deviation, and
`rho12` is the residual correlation in two-response Gaussian models. The R side
does not yet translate non-Gaussian coefficient scales such as NB2 dispersion or
Student-t degrees of freedom.

For the Gaussian phylogenetic mean cell, the Julia default uses DRM.jl's
all-node sparse conjugate-EM route. The bridge treats Julia `resd_*` coefficients
as structured-effect scale summaries under `fit$sdpars`, not as fixed effects.
That EM route returns point estimates, fitted values, residual `sigma`, and the
marginal likelihood, but no finite fixed-effect covariance matrix yet.

## Files Changed

- `R/drmTMB.R`
- `R/julia-bridge.R`
- `DESCRIPTION`
- `NAMESPACE`
- `man/drmTMB.Rd`
- `NEWS.md`
- `vignettes/julia-engine.Rmd`
- `_pkgdown.yml`
- `tests/testthat/test-julia-bridge.R`
- `docs/dev-log/check-log.md`

The companion DRM.jl worktree changed `src/bridge.jl`, `src/DRM.jl`,
`src/gaussian_core.jl`, `src/location_only.jl`, `test/test_bridge.jl`,
`test/test_conjugate_em.jl`, `test/runtests.jl`, and the bridge status docs.

## Checks Run

```sh
julia --project=. test/test_bridge.jl
```

Result in `DRM.jl`: 30 passes, no failures.

```sh
julia --project=. test/test_conjugate_em.jl
```

Result in `DRM.jl`: 21 passes, no failures.

```sh
Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-julia-bridge.R")'
```

Result in `drmTMB`: 43 passes, no failures, warnings, or skips.

```sh
Rscript -e 'cat(requireNamespace("JuliaCall", quietly = TRUE), "\n")'
```

Result: `FALSE`; the main local R library does not have JuliaCall installed.

Temporary-library JuliaCall smoke:

```sh
tmp_lib=$(mktemp -d /tmp/drmtmb-juliacall-lib-XXXXXX)
R_LIBS_USER="$tmp_lib" Rscript -e '... install.packages("JuliaCall", lib = Sys.getenv("R_LIBS_USER")); devtools::load_all(); options(drmTMB.DRM.jl.path = "/Users/z3437171/Dropbox/Github Local/DRM.jl"); fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, engine = "julia") ...'
```

Result: JuliaCall activated the local DRM.jl project and returned a
`drmTMB_julia` object with 24 observations, logLik -32.71, convergence 0, and
finite `mu` and `sigma` coefficients.

Temporary-library JuliaCall phylogenetic smoke:

```sh
tmp_lib=$(mktemp -d /tmp/drmtmb-juliacall-lib-XXXXXX)
R_LIBS_USER="$tmp_lib" Rscript -e '... fit_tmb <- drmTMB(bf(growth ~ temperature + phylo(1 | species, tree = tree), sigma ~ 1), data = dat); fit_julia <- drmTMB(..., engine = "julia") ...'
```

Result: a 32-species data set with phylogenetic signal returned
`logLik_diff = 7.52e-09`, `max_mu_coef_diff = 1.60e-06`,
`max_sigma_coef_diff = 2.29e-05`, `max_fitted_diff = 1.22e-03`,
`max_sigma_fit_diff = 1.51e-05`, and `uncertainty = unavailable,FALSE`.

```sh
Rscript -e 'rmarkdown::render("vignettes/julia-engine.Rmd", output_dir = "/tmp/drmtmb-julia-engine-preview", quiet = TRUE)'
```

Result: the new article rendered without errors at
`/tmp/drmtmb-julia-engine-preview/julia-engine.html`.

Article-output parity checks:

- Numeric Gaussian plant-growth example: native TMB and Julia engine matched
  with `max_abs_coef_diff = 2.57e-06`, `max_abs_fitted_diff = 2.09e-06`,
  `max_abs_sigma_diff = 2.70e-06`, and logLik difference `5.77e-10`.
- Bivariate Gaussian plant-trait example: native TMB and Julia engine matched
  with `max_abs_coef_diff = 3.31e-06`, `max_abs_sigma1_diff = 4.07e-06`,
  `max_abs_sigma2_diff = 2.24e-06`, `max_abs_rho12_diff = 1.87e-06`, and logLik
  difference `1.93e-09`.

Warm-session `system.time()` smoke checks:

- `n = 120`: native TMB median `0.013` s, Julia-engine median `0.014` s,
  median speedup `0.93x` over three reps.
- `n = 5000`: native TMB median `0.114` s, Julia-engine median `0.036` s,
  median speedup `3.17x` over three reps.
- Phylogenetic warm-session rows were superseded by the later AVONET/Hackett
  rerun recorded below. The current rows are `n = 100`, `n = 1000`, and
  `n = 9993`, not a rounded 10,000-species row.

These timing rows are local smoke evidence for the currently supported
fixed-effect Gaussian bridge. They are not a release-grade benchmark.

```sh
Rscript -e 'yaml::read_yaml("_pkgdown.yml")'
```

Result: the pkgdown configuration parsed and included `julia-engine` in the
article list.

```sh
git diff --check -- vignettes/julia-engine.Rmd _pkgdown.yml
```

Result: no whitespace errors.

## Tests Of The Tests

The Julia bridge test compares bridge output against native DRM.jl Gaussian
location-scale fits, including fixed-effect, bivariate, and phylogenetic paths.
The conjugate-EM test pins the default all-node sparse route for the Gaussian
phylogenetic mean cell and keeps `:gls` available as the dense comparison route.
The R test checks formula and tree marshalling, the reconstructed object
methods, structured-scale handling, and guardrails that fail before JuliaCall is
needed, including weights, non-default control, `skew_normal()`, unsupported
phylogenetic neighbours, and unsupported non-Gaussian families.

Follow-up parity-policy patch:

- The R bridge now sends `g_tol = 1e-4` for the admitted Gaussian
  `phylo(1 | species)` mean cell. This matches the direct DRM.jl sparse-EM
  smoke tolerance and avoids the too-strict generic default used in the earlier
  bridge smoke rows.
- The R bridge now converts Julia's Brownian phylogenetic SD back to drmTMB's
  correlation-matrix SD scale by multiplying by `sqrt(tree height)` before
  storing `fit$sdpars$mu`.
- The focused R test was rerun after this policy patch:
  `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'`
  returned 44 passes, no failures, warnings, or skips.
- A later follow-up found Julia 1.10.0 under
  `/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin`
  and reran the live JuliaCall 100/1000/9993 AVONET/Hackett bridge timing rows.
  The resulting CSV is
  `docs/dev-log/benchmarks/julia-bridge-phylo-gaussian-2026-06-09.csv`.

## Consistency Audit

The NEWS and `drmTMB()` help page describe the bridge as experimental and
Gaussian-only with one admitted Gaussian phylogenetic mean cell. The R
guardrails match that wording. Non-Gaussian routes remain native
`engine = "tmb"` until coefficient-scale parity tests are added. The
Julia-engine article repeats the same boundary, gives Gaussian one-response,
two-response, and phylogenetic examples as `eval = FALSE` bridge calls, prints
local native TMB versus Julia-engine output checks, shows how to plot
Julia-engine fitted values with `ggplot2`, and tells users what to try when
unsupported syntax errors.

The article now states the default-route policy: Gaussian phylogenetic mean
models can use all-node sparse EM; non-Gaussian phylogenetic models should
target sparse Laplace after parity tests; and profile/bootstrap acceleration
should reuse the same per-family defaults rather than expose an untested global
algorithm switch.

The article also explains why the phylogenetic speedup is smaller than the
fixed-effect Gaussian speedup: native `drmTMB` already uses a sparse
phylogenetic precision for this route, so the comparison is sparse TMB/Laplace
style optimization versus sparse Julia all-node EM, not dense tip-covariance
TMB versus sparse Julia.

## GitHub Issue Maintenance

Open issue lookup found `itchyshin/drmTMB#499` as the matching R-side bridge
tracker and `itchyshin/DRM.jl#5` as the Phase 1.5 roadmap tracker. I attempted
to post local progress comments with the test evidence, but the installed GitHub
integration returned 403 `Resource not accessible by integration` for both
repositories. No issue comment was posted.

## What Did Not Go Smoothly

`Pkg.test(test_args = ["test_bridge.jl"])` in DRM.jl still ran the broader test
suite because the package test runner ignores `ARGS`; that broad run was stopped
and replaced with the direct `julia --project=. test/test_bridge.jl` command.
JuliaCall was absent from the main R library, so the actual R-to-Julia smoke used
a temporary R library under `/tmp` rather than changing the user library.

## Team Learning

Keep the bridge acceptance split into two layers: a Julia primitive test that
compares against native DRM.jl fits, and an R guard/object test that can run
without JuliaCall. Add a separate integration test only when JuliaCall is
available in a temporary or CI library.

## Known Limitations

The R bridge does not support weights, imputation, missing-data routes,
non-default control settings, random-effect scale formulas, phylogenetic slopes
or predictor-dependent phylogenetic `sigma`, `corpair()` formula entries,
non-Gaussian families, newdata prediction, simulation, intervals, bootstrap,
profile workers, or persistent Julia fit handles.
The article was rendered directly, but a full pkgdown site build was not run in
this dirty detached worktree.

## Next Actions

Add a temporary-library JuliaCall integration smoke to CI when the dependency
story is settled. Then add a proper phylogenetic benchmark script with
cold-start, warm-start, memory, version, replicate, and repeated-observation
columns. Add coefficient-scale parity tests before admitting non-Gaussian
families through the R bridge, and design profile/bootstrap Julia workers only
after the single-fit route is parity-tested for the same model cell.

## AVONET/Hackett Article Update

The Julia-engine article now uses the real AVONET/Hackett avian data as the
large phylogenetic example when a sibling `pigauto` or `BACE` checkout is
available. The local pigauto handle is
`../pigauto/avonet/AVONET3_BirdTree.csv` plus
`../pigauto/avonet/Stage2_Hackett_MCC_no_neg.tre`; the mirrored BACE handle is
`../BACE/dev/testing_data/AVONET.csv` plus `Hackett_tree.tre`.

Local inspection found 9,993 complete AVONET species for `Mass`,
`Hand-Wing.Index`, `Beak.Length_Culmen`, and `Wing.Length`, and all 9,993
matched the Hackett tree tips. The article therefore labels the large
phylogenetic row as 9,993 species instead of rounding it to 10,000.

The warm-session smoke rows now printed in the article are:

```text
model                         n      species   rows   tmb_s    julia_s   speedup   logLik_diff   max_coef_diff   sd_phylo_diff   tmb_conv   julia_conv
AVONET phylogenetic Gaussian  100    100       100    1.186    0.175     6.78      8.57e-02      8.08e+00        3.31e-03        0          1
AVONET phylogenetic Gaussian  1000   1000      1000   2.567    0.265     9.69      6.38e-05      6.11e-04        3.16e-04        0          0
AVONET phylogenetic Gaussian  9993   9993      9993   61.697   15.870    3.89      1.24e-04      8.01e-03        8.11e-06        1          0
```

The 100-species row is explicitly a warning row. In that small tree-order
subset, the residual-versus-phylogenetic variance split sits near a boundary,
so native TMB and the current Julia EM baseline can return visibly different
variance-component scales even when fitted means are close. The 1,000 and 9,993
species rows are the useful AVONET parity smoke rows, with one caveat: native
TMB returned convergence code 1 on the default 9,993-species row. A TMB-only
diagnostic with `drm_control(se = FALSE)` still took 57.942 s and returned
convergence code 1, so that large-row issue is not just standard-error
calculation.

The algorithm wording was also tightened. DRM.jl's all-node sparse conjugate
EM route remains the current admitted baseline for the Gaussian
`phylo(1 | species)` mean cell, and it uses Takahashi selected-inverse trace
terms. It is not described as the settled fastest Julia algorithm. GLLVM.jl's
fast Gaussian phylogenetic work points toward sparse L-BFGS or TMB-like
marginal optimisation as the next algorithm comparison, but DRM.jl's current
dense `:lbfgs` comparison route is not the same thing and is not the right
9,993-tip default. The next benchmark should compare the current EM baseline
against a sparse likelihood/optimizer route and possible SQUAREM-style
acceleration before changing the Julia default policy.

Checks:

- `Rscript --vanilla -e 'rmarkdown::render("vignettes/julia-engine.Rmd", output_dir = "/tmp/drmtmb-julia-engine-preview", quiet = TRUE)'`
  passed.
- Rendered-source scan for `AVONET`, `Hackett`, `9993`, `settled fastest`,
  `Takahashi`, `L-BFGS`, `sparse EM`, and the 9,993 timing values passed.
- `git diff --check -- vignettes/julia-engine.Rmd docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-08-experimental-julia-engine-bridge.md`
  passed.
