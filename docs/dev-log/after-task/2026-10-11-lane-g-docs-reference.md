# Lane G: reference pages, Julia-engine guide, cheat sheet, and spatial docs

## Goal

Make the reference pages and the guides they point to say what the package
does at `main` 75845a3d, for the sixteen lane G issues of the 2026-10-11
bug-fix campaign. The reader is an applied user who moves between `?topic`
help, the Julia engine guide, and the function-map cheat sheet, and who should
not be told two different things on two pages.

## Implemented

- **#1479, #1453 (`vignettes/julia-engine.Rmd`).** The family table now spells
  the Gamma family `Gamma(link = "log")`, not base R's `gamma()`. The hurdle
  paragraph now says one call, `truncated_nbinom2()` with `hu ~ ...`, fits on
  both engines, and that `nbinom2()` with `hu` is an older Julia-only spelling
  the native engine refuses. Checked against the bridge ledger
  (`R/julia-bridge.R`, the "SAME CALL ON BOTH ENGINES since 2026-09-05" row)
  and the family registry comment in `R/julia-family-registry.R`.
- **#1475 (cheat sheet).** `function-map-cheatsheet.Rmd` and its PDF source
  `tools/function-cheatsheet-source.Rmd` no longer call Julia fitting
  "future/deferred"; they describe `engine = "julia"` as an optional route for
  supported models and link the Julia engine guide. The `rho_latent()` row now
  says it reads an experimental cross-family Julia fit, matching
  `?rho_latent`.
- **#1239 (`?confint.drmTMB_julia`, `threads`).** The argument now says that
  `threads = TRUE` cannot start Julia threads, that `JULIA_NUM_THREADS` must
  be set before the first Julia call, that a single-threaded Julia runs refits
  serially with a one-time message, and that the variable alone does not
  parallelise refits. The matching paragraph in `julia-engine.Rmd` gained the
  same two-step recipe. Both statements mirror `drm_julia_threads_hint()` and
  `drm_julia_serial_hint()`.
- **#1474 (`?spatial`).** The reference page now documents the fitted
  fixed-kappa mesh intercept, `bf(y ~ x + spatial(1 | site, mesh = mesh),
  sigma ~ 1)`, links `make_mesh()`, lists what is rejected, and shows the mesh
  example as fitted instead of "Planned". `formula-grammar.Rmd` and
  `model-map.Rmd` now scope "planned" to mesh uses beyond that route. The
  rejections were read from `validate_gaussian_mesh_spatial_term()` and the
  univariate-Gaussian guard in `R/drmTMB.R`. `spatial-models.Rmd` and
  `structural-dependence.Rmd` were already correct.
- **#1473 (`zero_one_beta()` with one kind of boundary value).** Measured on a
  300-row simulated response with 30 exact zeroes and no ones: the `coi`
  intercept ran to -23.7, `check_drm()` reported `degenerate`, and
  `is_converged()` was `FALSE`, while the `mu`, `sigma`, and `zoi` estimates
  equalled a `beta_family()` fit to the interior values and a `binomial()` fit
  to the zero indicator (both converged). `?zero_one_beta`,
  `distribution-families.Rmd`, `proportion-beta-binomial.Rmd`, and
  `capability-and-limits.Rmd` now say this and give the two-part fit as the
  thing to try instead.
- **#1245 (`location-scale.Rmd`).** A note after `sigma ~ z + (1 | group)` says
  drmTMB integrates the scale random effect with the Laplace approximation,
  that the `sigma` coefficients are conditional effects on `log(sigma)`, and
  that DRModels.jl defaults to 32-node Gauss-Hermite quadrature for the
  Gaussian case (checked in DRModels.jl `docs/src/diagnostics-and-validation/implementation-map.md`).
- **#1244 (`location-scale-scale.Rmd`).** `R_s` was already defined; the page
  now says the model has one repeatability per sex and that `repeatability()`,
  `icc()`, and `heritability()` refuse such a fit.
- **#1237, #1249 (thread policy, docs halves).** The full policy lives in
  `?drmTMB-parallel`, added by the perf lane's PR #1510, so this lane does not
  write a second copy. `large-data.Rmd` gained one paragraph that states the
  core fact (the package is compiled without OpenMP: `TMB::openmp(DLL =
  "drmTMB")` returns 1 and the install log has no `-fopenmp`), says to keep
  BLAS at one thread under `parallel = "multicore"`, and points to
  `?drmTMB-parallel`.
- **#1140 (roxygen drift).** See below.

## Already fixed on main (no text change)

#1346 (`?residuals.drmTMB` already names Student-t, skew-normal, and beta
Pearson scales), #1341 (`?summary.drmTMB` names emmeans in See also and
`?residuals.drmTMB` has a DHARMa example), the documentation half of #1320
(`?predict.drmTMB` already explains that `type = "response"` is not always
`E[Y]`), and #1230 (the skew-normal and Tweedie sections already match the
overview table). #1231 has its own open draft PR, #1434.

## The #1140 finding

Regenerating man pages on untouched `main` changed 40 files. One commit,
592aecaa (#1400, 2026-09-20), had rewritten the prose of 40 Rd files by hand
without touching their roxygen sources, so `devtools::document()` silently
reverted it in 38 pages; 2d29f9fe (#1420) had already reverted one sentence in
`?beta_family` that way. The remaining five hunks were link targets resolved
from the local help index. No `\code{}` markup was lost under roxygen2 7.3.1.
This lane ported the #1400 prose back into the roxygen blocks so that
regeneration reproduces the committed pages.

## Checks Run

- `roxygen2::roxygenise(".", roclets = "rd")` (7.3.1) after the port: the only
  Rd changes outside the intended pages (`spatial`, `zero_one_beta`,
  `beta_family`, `confint.drmTMB_julia`) are link-target noise, which was not
  committed.
- All 11 changed vignettes knit with `rmarkdown::render()`.
- `tools/check-reader-contracts.R` is clean under `C.UTF-8`; spelling adds only
  "OpenMP" (now in `inst/WORDLIST`); `tools/capability_ledger.py --check` OK.
- C17 receipt: `tools/recertify-c17.py --label lane-g --tolerance 2e-11`. The
  worst drift was 1.322e-11, and a `--dry-run` on a clean main worktree in the
  same container gave the same three numbers, so the drift is environmental.
- Full suite, installed build, R 4.3.3: 15 failed, 134 errors, 111 skipped,
  47,326 passed. Unmodified main gave the same totals and the same 147 failing
  tests (`%||%` on R < 4.4, no Julia, missing Suggests, non-UTF-8 locale).
- CI run 38112355789 on `fa20d1a1`: all six checks green.

## What Did Not Go Smoothly

The cheat-sheet PDFs in `pkgdown/assets/cheatsheets/` still carry the old
Julia sentence. `tools/build-function-pdfs.py` uses macOS Arial fonts and falls
back to Helvetica here, so rebuilding in this container would have changed the
look of the PDF; it needs a rebuild on the maintainer's machine.

## Team Learning

A hand edit to a generated file is a debt that the next routine
`document()` collects. Edit the roxygen block, regenerate, and keep only the
hunks for the block you changed.

## Rebase onto #1508 (cleanup run)

Rebased onto `claude/lane-d-formula-methods` at `790d70a4c` (itself on
`main` `6beb1f2a0`). `R/profile.R` and `?confint.drmTMB` keep the
cluster-aware workers sentence and the OpenMP/BLAS facts. Intermediate C17
receipt commits were skipped and recertified once:
`python3 tools/recertify-c17.py --label pr-1511 --tolerance 1e-10`,
|change| 0.

`vignettes/large-data.Rmd` now carries all three Windows/parallel notes:
main's `parallel = "cluster"` sentence (#1523), #1506's multicore-abort /
serial example, and this lane's OpenMP/BLAS paragraph. The vignette knits
with `rmarkdown::render()` (chunks stay `eval = FALSE`). Reader-contracts
OK; `test-release-identity.R` 20 pass; `test-reader-vignette-contracts.R`
35 pass.
