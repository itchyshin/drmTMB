# Julia non-Gaussian phylo bootstrap tree forwarding

## 1. Goal

Remove the obsolete R-side refusal for a Julia-engine fixed-effect bootstrap
on a non-Gaussian phylogenetic fit, and preserve the exact coupled phylo
formula that DRM.jl requires for a Gamma mean/scale fit.

## 2. Implemented

`drm_julia_call_fixef_inference()` now reaches the Julia bridge for a
non-Gaussian phylogenetic bootstrap. Its generated Julia wrapper passes
`tree = tree_obj` to the generic `DRM.bootstrap_result()` branch, while the
Gaussian branch retains its existing `algorithm`, `g_tol`, and
`check_converged = true` arguments.

The R serializer now preserves a shared explicit covariance label as
`(1 | tag | phylo(group))` for non-Gaussian paired mu/sigma phylo routes. A
pair without labels receives the deterministic internal
`drmTMB_phylo_locscale` tag. Different or one-sided labels fail before the
bridge can coalesce them. Gaussian coupled-phylo options remain unchanged;
Gamma sends only `g_tol = 1e-8` and does not receive the Gaussian-only
`phylo_coupled` keyword.

## 3a. Decisions and Rejected Alternatives

The bridge keeps this as a narrow translation repair. It does not add a new
Julia family keyword, infer coupling for arbitrary independent effects, or
widen public family support. An explicit shared label is preserved; only an
already-admitted paired unlabelled route receives a deterministic internal
tag.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-bootstrap-tree.R`
- `tests/testthat/test-julia-inference.R`
- this report

## 5. Checks Run

The first R-only regression red check was
`Rscript --vanilla -e 'devtools::test(filter = "julia-bootstrap-tree", reporter = "summary")'`.
It failed at `test-julia-bootstrap-tree.R:25` with the intended obsolete
refusal, "not available on a phylogenetic non-Gaussian fit" (terminal chunk
`5b5bb0`, 2.89 s). After removing the refusal and forwarding the tree, the
same command passed its two expectations (chunk `33c7c9`, 3.05 s).

The Gamma-options red check failed because the actual options had the extra
`phylo_coupled = TRUE` field (chunk `200123`, 3.73 s). The narrowed
Gaussian-only option branch then passed (chunk `0c2285`, 2.96 s).

The labelled-Gamma serialization red check showed the old collapsed payload
`phylo(1 | species)` on both axes (chunk `848049`, 3.11 s). The serializer
then passed after emitting `(1 | tree_boot | phylo(species))` (chunk
`38dd0d`, 2.61 s). The final focused pure-R run passed 11 expectations:
`Rscript --vanilla -e 'devtools::test(filter = "julia-bootstrap-tree", reporter = "summary")'`.
After the cache-key regression was added, the retained final focused command
passed 16 expectations. Its exact stdout/stderr receipt is
`/private/tmp/drm-parity-20260830/bridge-bootstrap-tree/pure-r-julia-bootstrap-tree-20260831T211100Z.log`
(SHA-256 `0a9aab47b51bde82439219e006ac96a80fa8499f091bdcda469fecd636d3d776`).

`Rscript --vanilla -e 'devtools::test(filter = "julia-inference", reporter = "summary")'`
also passed its available checks. Its four live Julia cases were skipped
because their `callr` children did not receive a DRM.jl path; that result is
not live-engine evidence. `git diff --check` passed.

### Retained pure-R transcript receipt

The terminal tool retained pure-R output in its transcript instead of files.
This report is the on-disk receipt; no standalone log paths are claimed. The
same command above produced these red failures before their narrow repairs:

```
1. Julia-engine bootstrap intervals for fixed effects are not available on a
   phylogenetic non-Gaussian fit.
2. Gamma phylo_locscale options had an extra phylo_coupled = TRUE field.
3. The tagged Gamma payload collapsed to phylo(1 | species).
4. A Gaussian payload cached first contaminated the following Gamma payload.
```

The final output was:

```
Testing drmTMB
julia-bootstrap-tree: ................

DONE
```

## 6. Tests of the Tests

The first regression was observed failing at the obsolete R refusal before
the implementation changed. The focused tests inspect the actual Julia-call
tree argument, the public bridge payload strings, Gamma versus Gaussian
options, the untagged deterministic tag, and both mismatched-label cases.
They do not merely search source text.

## 8. Consistency Audit

`rg` found no remaining obsolete refusal text in `R/julia-bridge.R` or
`tests/testthat/*.R`. The change is internal bridge plumbing; no README,
vignette, pkgdown, NEWS, or formula-grammar claim was widened.

## 9. What Did Not Go Smoothly

The first public R attempt was sandbox-blocked before fitting when JuliaCall
could not create its manifest lock. The scoped rerun then exposed two real
boundaries: Gamma was incorrectly given the Gaussian-only
`phylo_coupled` keyword, and generic label collapsing erased the explicit
coupled tag. Both were retained as pure-R regression tests before the
corresponding narrow changes.

## 7a. Issue Ledger

No design document, pkgdown page, NEWS entry, GitHub issue, commit, or push
was changed. The work remains within the already-approved R/Julia bootstrap
forwarding programme.

## 10. Known Residuals

The retained public R/Julia coupled-Gamma fixture check passed under its hard
60-second process-group cap at one and four Julia threads: run receipts
`actual-r-threads1-20260831T210144Z` (29.800 s) and
`actual-r-threads4-20260831T210213Z` (27.360 s) in
`/private/tmp/drm-parity-20260830/bridge-bootstrap-tree/`. Both used the
lossless original binary fixture values, BLAS thread count one, `B = 2`, seed
4001, and the shared `mu:x` target. Each retained 2/2 bootstrap refits with
zero failures and matched the direct Julia reference at tolerance `1e-12`.
Source hashes were unchanged across the R calls.

This evidence establishes only the explicit coupled Gamma
`fixef:mu:x` bootstrap path through `engine = "julia"`. It does not establish
native Gamma parity (native Gamma has a different structured-effect boundary),
profile or coverage calibration, other targets or families, larger bootstrap
counts, or broad bridge support. The existing opt-in live Poisson phylo test
was skipped because its `callr` child had no DRM.jl path; the focused pure-R
suite does not qualify it as executed live evidence.

## 11. Team Learning

For a cross-language structured model, the R formula string is part of the
contract. A generic label-normalization helper can be valid for Gaussian q4
while destroying the semantic tag a non-Gaussian location-scale parser needs;
test the serialized payload as well as the forwarded keyword list.

## 12. Cross-Product Coverage

The executed cross-product covers the coupled Gamma mean/scale phylogenetic
formula, the `mu:x` coefficient, `B = 2`, seed 4001, and one and four Julia
threads. It does NOT cover native Gamma parity, other families and structured
formula forms, profile or coverage calibration, larger bootstrap counts, or
the skipped opt-in Poisson live path.
