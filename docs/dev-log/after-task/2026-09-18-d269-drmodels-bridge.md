# D-269: compatible DRModels / DRM bridge

## Task goal

Allow the optional Julia backend to use either the renamed DRModels package or
legacy DRM without changing model contracts or the default TMB backend.

## Files created or changed

`R/julia-bridge.R` selects the module after project activation and binds it to
`drmTMB_backend`; all direct calls and generated Julia helpers use that alias.
`R/julia-joint-call.R` uses the same alias for capability checks and dispatch.
The path resolver prefers the canonical option/environment settings and retains
legacy settings and both sibling directory names. Tests, README, NEWS, and the
Julia-engine vignette describe this transition.

## Checks run and exact outcomes

The focused R command was:

```r
pkgload::load_all(".", compile = FALSE, quiet = TRUE)
testthat::test_local(".",
  filter = "julia-(module-compat|joint-call|fe-only-fence|bootstrap-tree)$",
  stop_on_failure = TRUE, load_package = "none", reporter = "summary")
```

All four files passed; three pre-existing missing-fixture skips remain. The new
module compatibility file passed 36 assertions. An ignored symlink to the
installed `drmTMB.so` avoided recompiling unchanged TMB code; this check is R glue
evidence, not proof of a fresh package build. `git diff --check` passed.

A real R/JuliaCall smoke on Julia 1.10.0 loaded the legacy module and fitted
24 Gaussian observations with `bf(y ~ x, sigma ~ 1)`, seed 269:
`D269_LIVE_PASS module=DRM logLik=-2.703051`. Julia used four threads and BLAS one.
The renamed checkout smoke reached `DRModels` but failed during dependency load:
ForwardDiff was not installed in that environment. No canonical fit is claimed.

## Consistency audit

Searched executable module references with
`rg -n 'DRM\.|using DRM|isdefined\(DRM' R/julia-bridge.R R/julia-joint-call.R`.
Generated helpers and the profile capability probe share the selected alias.
Historical evidence and model-capability descriptions retain their original names.
No likelihood, family registry, TMB source, dependency, or version changes.

## Tests of the tests

Before implementation, the new regression file produced 11 failures/errors.
It now exercises canonical/legacy module preference, errors from both loads,
path precedence, both sibling paths, helper registration, and cached setup.
The canonical smoke exposed braces in Julia error traces being interpreted as
cli expressions; the diagnostic now interpolates the captured text safely and a
`Tuple{Base.PkgId}` regression covers it.

## What did not go smoothly

JuliaCall initially could not find Julia on PATH. Setting `JULIA_HOME` to the
installed Julia directory fixed discovery. The canonical environment needs its
owner to instantiate dependencies. Open PR #1111 touches documentation in the
bridge file; the coordinator therefore approved stacking on its branch
`codex/julia-current-surface-docs`, not publishing a competing PR against main.

## Team learning and process improvements

Exercise a real import failure: mock messages without braces missed a diagnostic
bug. Keep module identity centralized across generated code and ordinary calls.

## Design-doc updates

None: this is package-name compatibility, with no estimator or formula change.

## pkgdown/documentation updates

Updated setup instructions, canonical option/environment precedence, legacy
fallbacks, README companion link, and NEWS. No site build or deployment.
`R/drmTMB.R` and `man/drmTMB.Rd` belong to active PR #1110 and are explicitly
excluded. Its owner must incorporate the same setup text and regenerate help
with roxygen after reconciling that PR; no man pages were hand edited here.

## GitHub issue maintenance

This compatibility PR stacks on #1111. No issue closures, changes to #1380,
merges, releases, registry actions, or GitHub settings are authorized here.

## Known limitations and next actions

Obtain a successful canonical DRModels smoke once its checkout is instantiated.
R CMD check with compilation/full tests was estimated at 45–90 minutes and was
not launched under the bounded-check authorization. Run that check after approval.
Review and land the stack in dependency order; this task does not merge it.
