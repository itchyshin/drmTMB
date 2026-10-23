# D-269: compatible DRModels / DRM bridge

## 1. Goal

Allow the optional Julia backend to use either the renamed DRModels package or
legacy DRM without changing model contracts or the default TMB backend.

## 2. Implemented

`R/julia-bridge.R` selects the module after project activation and binds it to
`drmTMB_backend`; all direct calls and generated Julia helpers use that alias.
The selected checkout's Project.toml determines its name and UUID. Resolution
and the loaded module's source must both belong to that checkout. A different
package later on Julia's LOAD_PATH is never used as a fallback, and actual
dependency/import errors propagate unchanged.
`R/julia-joint-call.R` uses the same alias for capability checks and dispatch.
The path resolver prefers the canonical option/environment settings and retains
legacy settings and both sibling directory names. Tests, README, NEWS, and the
Julia-engine vignette describe this transition.

The follow-up Rose repair also binds every dedicated cross-family test checkout
through both the canonical and legacy options. This matters when a developer has
a global canonical checkout configured: the family helper may deliberately
select `DRM_JL_XFAM_PATH`, `DRM_JL_XFAM_TIER2_PATH`, or
`DRM_JL_XSIGMA_PATH`, and that selected checkout must remain authoritative when
the production resolver runs.

## 3a. Decisions and Rejected Alternatives

Use the selected checkout's declared identity and check source provenance.
Rejected importing the canonical name and falling back on any error: stacked
Julia environments can otherwise load unrelated code and conceal real failures.
Retain the draft merge hold because this repair does not reconcile #1111.

## 4. Files Touched

This repair changes `R/julia-bridge.R`, `tests/testthat/helper-julia-bridge-path.R`,
`tests/testthat/test-julia-module-compat.R`, `tests/testthat/test-xfam-bridge.R`,
`tests/testthat/test-model-comparison.R`,
`tests/testthat/test-coevolution-accessors.R`, `tests/testthat/test-lrt-boundary.R`,
this report and `docs/dev-log/check-log.d/2026-09-18-d269-drmodels-bridge.md`.
Earlier commits in this PR also changed `R/julia-joint-call.R`, README, NEWS,
the Julia-engine vignette and its bounded bridge regression files. Ignored
`.unlazy/d269-transition/` stores the acceptance ledger and smoke scripts.

## 5. Checks Run

The focused R command was:

```r
pkgload::load_all(".", compile = FALSE, quiet = TRUE)
testthat::test_local(".",
  filter = "julia-(module-compat|joint-call|fe-only-fence|bootstrap-tree)$",
  stop_on_failure = TRUE, load_package = "none", reporter = "summary")
```

After the Rose repair, all four files passed: 296 assertions, zero failures,
three pre-existing missing-fixture skips. The module compatibility file passed
49 assertions, including real Julia subprocess tests with stacked LOAD_PATH:
canonical and legacy identities, an import failure with a sentinel dependency
error, and an already-loaded module from a different checkout. The command used
`DRMTMB_JULIA_TESTS=true` and Julia 1.10.0 via JULIA_HOME for these subprocesses.
An ignored symlink to the
installed `drmTMB.so` avoided recompiling unchanged TMB code; this check is R glue
evidence, not proof of a fresh package build. `git diff --check` passed.

A real R/JuliaCall smoke on Julia 1.10.0 loaded the legacy module and fitted
24 Gaussian observations with `bf(y ~ x, sigma ~ 1)`, seed 269:
`D269_LIVE_PASS module=DRM logLik=-2.703051`. Julia used four threads and BLAS one.
The first renamed checkout smoke reached `DRModels` but failed during dependency
load because its project lacked a working dependency manifest. A disposable
project at `/private/tmp/drmodels-smoke.n9RqeT` then used read-only symlinks to
the renamed Project/src/ext (source `f80e4bc61a1aacf300290a7145393bb8b72a81b7`)
and the legacy checkout's working Manifest. Its dependency declarations are
identical. That fresh R process passed:
`D269_LIVE_PASS module=DRModels logLik=-2.703051`.
Legacy source was `27fc9202064bbbdb36592649e46229e3cabe6cbd`.
Neither Julia source checkout was modified. These are tiny bridge smokes,
not new package-wide parity or inference evidence.

Both fresh-process Gaussian smokes were repeated after the Rose repair, with
the actual `drm_mc_julia_native()` oracle from `test-model-comparison.R` parsed
and evaluated as well. Its qualified macros, fits, AICc and likelihood-ratio
calls all used `drmTMB_backend`. Each identity returned `logLik=-2.703051` and
native `aicc=12.6061`; native and bridged AICc agreed within 1e-8. Each smoke was
under five minutes; the legacy rerun measured 21.12 seconds. The canonical
smoke retained the same disposable project/source links described above;
the renamed source head inspected after the repair smoke was
`c98cb3045bcfd0fe4acc3c99ffacc40e9743c097`, while the legacy head was unchanged.

The three edited oracle files were also run using `testthat::test_local()`
with filter `^(model-comparison|coevolution-accessors|lrt-boundary)$` and
`NOT_CRAN=false`, `DRMTMB_JULIA_TESTS=false`: 131 assertions, zero failures,
11 explicit skips (five longer non-CRAN tests and six live Julia tests).
This bounded run does not revalidate the q4 or boundary-test live fits.

For the family-checkout precedence follow-up, the module-compatibility file
passed 44 assertions with zero failures or errors and one live-Julia skip. The
cross-family bridge file passed 54 assertions with zero failures or errors and
four unavailable-live-engine skips. Both focused runs completed in under ten
seconds after package loading; no campaign or full check was launched.

## 8. Consistency Audit

Searched executable module references with
`rg -n 'DRM\.|using DRM|isdefined\(DRM' R/julia-bridge.R R/julia-joint-call.R`.
Generated helpers and the profile capability probe share the selected alias.
The model-comparison, boundary-test and coevolution native oracles now also use
that alias, including qualified formula macros. Shared test path resolution
accepts canonical options/environment settings, retains family-specific
overrides and legacy fallbacks, and checks canonical-only settings do not skip.
All three dedicated cross-family checkout routes now carry the helper-selected
path into the production resolver's canonical option; structured `relmat`
configuration was inspected but was not changed because it is not a
family-specific caller in this finding.
Historical evidence and model-capability descriptions retain their original names.
No likelihood, family registry, TMB source, dependency, or version changes.

## 6. Tests of the Tests

Before implementation, the new regression file produced 11 failures/errors.
It now exercises checkout-bound canonical/legacy module identity, unchanged
dependency errors, path precedence, both sibling paths, helper registration,
and cached setup. Real subprocesses assert the exact selected identity rather
than merely accepting either name. A previously loaded foreign module is
refused even if its declared name and UUID match. The `Tuple{Base.PkgId}` error
regression checks the original condition object is preserved.
An ignored fault-injection runner replaced the loader only in a fresh R
process with its old import-canonical/catch/fallback behavior. The new tests
then produced four failures: wrong stacked identity, swallowed dependency
failure (two assertions), and foreign cached source accepted. Tracked source
was unchanged by this experiment.

For the follow-up precedence regression, the first run failed at
`drm_test_local_drmjl_path()` because that test-only binding helper did not yet
exist. A separate reproduction showed the full defect directly:
`HELPER=family-selected RESOLVER=global-canonical`. After adding the helper and
wiring the three cross-family caller routes, the regression evaluates
`drm_julia_setup()`'s default `path` expression and obtains `family-selected`.

## 9. What Did Not Go Smoothly

JuliaCall initially could not find Julia on PATH. Setting `JULIA_HOME` to the
installed Julia directory fixed discovery. Open PR #1111 touches documentation
in the bridge file. Attempting the coordinator-approved stack exposed that its
branch was 914 main commits behind and produced genuine conflicts, including a
modify/delete conflict for the fence test. The rebase was aborted cleanly.
The coordinator then approved a narrow main-based draft PR with a merge hold
until #1111 is merged or formally closed and the compatibility PR is reconciled.
No foreign branch was rewritten.

During the repair, the sandbox denied Julia's normal manifest-usage lock on
the legacy smoke. The approved rerun outside the sandbox passed. The canonical
smoke passed but JuliaCall reported its dependency-install subprocess returned
status 1 in the sandbox; the working installed dependencies still loaded.

## 11. Team Learning

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

## 7a. Issue Ledger

This compatibility PR targets main with an explicit #1111 merge hold. No issue closures, changes to #1380,
merges, releases, registry actions, or GitHub settings are authorized here.

## 10. Known Residuals

R CMD check with compilation/full tests was estimated at 45–90 minutes and was
not launched under the bounded-check authorization. Run that check after approval.
Reconcile the older #1111 PR before merging this compatibility change; this task
does not merge either PR. Main help/roxygen work remains with #1110's owner.
NEWS.md lines 5–6 and `vignettes/julia-engine.Rmd` lines 59–60 still describe
the former canonical-first/fallback loader. They require the wording
"loads the package declared by the selected checkout and verifies its source"
before merge. The coordinator explicitly withheld edits to these paths under
the overlapping-ownership guard; this repair leaves both untouched and records
the wording correction as a pending ownership hold.
The family-specific follow-up is test-configuration evidence only; its four
live cross-family cells skipped because no dedicated checkout was configured,
so it does not add numerical cross-family parity evidence.

## 12. Cross-Product Coverage

The repair covers canonical and legacy checkout selection, stacked-environment
isolation, native oracle dispatch, shared test configuration, and tiny Gaussian
bridge/native comparison fits. It does NOT cover a fresh full R package check,
live q4 or boundary-inference parity, regenerated #1110-owned main help, R
releases, Julia package-wide validation, Pages deployment, or other repositories.

Memory receipt: the coordinator supplied the routed D-269 constraints and Rose
findings; this repair independently ran lane preflight and verified its exact
lease. Golden Set was not run: this bounded correction used the explicit
stacked-environment and canonical-only regression cases above.
