# leaf-biv-animal-reml: bivariate Gaussian `animal()` q2 REML same-target receipt

Admits REML for `drmTMB(bf(mu1 = y1 ~ x1 + animal(1 | p | id, A = A), mu2 =
y2 ~ x2 + animal(1 | p | id, A = A), sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
family = biv_gaussian(), REML = TRUE)`. Before this leaf, `animal()` was
refused on this exact shape while `relmat()` and `phylo()` were admitted;
this receipt establishes that the refusal was a scope decision, not a
mathematical one, and quotes the numbers that prove the widened admission is
correct.

DRM.jl shas: pin used for every LIVE run below,
`430ef64ccca5642c5abebd72194e00895314dfc2` (`DRM_JL_PATH`); `origin/main` of
DRM.jl read via `git show` for source citations,
`d3efbad2f402cffb01e08eaf4efb25888d5fed96`.

## G0/G1: baseline on origin/main (802522384), `arc1b_s2r_fixture()` (x1 != x2)

Fixture: `g = 14` (AR(1), phi = 0.4), `m = 4`, seed `2026071502`, matching
`tests/testthat/test-reml-bivariate-relmat-q2.R`'s own oracle fixture. Script:
`scratchpad/2026-09-05-biv-animal-reml-g1-red.R`.

1. **TMB `animal()` REML = TRUE refuses** (verbatim):
   > For bivariate models, `REML` supports phylogenetic (`phylo()`)
   > structured effects and exact fixed-covariance spatial or supplied-`K`
   > relmat q2 location blocks.
   > i The spatial exception requires matching labelled `spatial(1 | p |
   > site, coords = coords)` intercepts in `mu1` and `mu2`, constant
   > `sigma1`, `sigma2`, and `rho12`, complete response pairs, unit weights,
   > and no other random-effect layer.
   > i The relatedness exception has the same boundaries and requires
   > matching labelled `relmat(1 | p | id, K = K)` intercepts; supplied
   > precision `Q`, animal, slopes, q4+, and scale-side bivariate relmat
   > REML routes remain deferred.
   > i Known covariance, missing or weighted response pairs, and additional
   > random, direct-SD, or corpair layers remain outside both exact
   > exceptions; use an admitted cell or set `REML = FALSE`.

2. **TMB `animal()` REML = FALSE fits**: `estimator = "ML"`,
   `opt$convergence = 0`, `logLik = -69.9131557981`, `df = 10`
   (`length(opt$par)`).

3. **TMB `relmat()` with the SAME matrix used as `A`, REML = TRUE (control)**:
   `estimator = "REML"`, `opt$convergence = 0`,
   `logLik = -74.5213647031`, `opt$objective (nll) = 74.5213647031`,
   `attr(logLik, "df") = 10` (`length(opt$par) = 6` fixed + 4 marginalised
   `beta_mu1`/`beta_mu2` coefficients). This is the control that shows the
   refusal in item 1 is keyed on the marker NAME `animal`, not the
   mathematics: same K, same intercept-only sigma1/sigma2/rho12 shape, same
   x1 != x2 mean design.

4. **DRM.jl direct call, provider-blindness** (bypasses the R<->Julia
   bridge, which refuses this whole cell unconditionally for REML = TRUE
   regardless of provider -- see "Bridge is untouched" below). Script:
   `probe_direct_julia.jl`, run against a SHARED-x fixture (seed
   `2026090501`, `g = 14`, `m = 4`; DRM.jl's own bivariate q2 structured
   route requires `mu1` and `mu2` to share one fixed-effect design):

   ```
   animal(A=K), method=:REML: estimation_method=REML, converged=true,
     loglik=-65.2776470082161, reml_loglik=-65.2776470082161
   relmat(K=K), method=:REML: estimation_method=REML, converged=true,
     loglik=-65.2776470082161, reml_loglik=-65.2776470082161
   loglik identical? true   theta identical? true   max|d_theta| = 0.0
   ```

   Bit-identical between `animal(A = K)` and `relmat(K = K)` on the same
   numeric matrix: DRM.jl's REML implementation runs the SAME
   `make_coevo_problem_from_covariance()` code path regardless of marker
   name (`src/gaussian_bivariate.jl` `_fit_bivariate_q2_structured`).

## G2: implementation

`drm_reml_admits_biv_animal_q2_intercept(spec)` added at `R/drmTMB.R`
(mechanical third wrapper around the existing generic
`drm_reml_admits_biv_exact_q2_intercept(spec, provider, representation)`,
`provider = "animal"`, `representation = "A"` -- exactly parallel to
`relmat`'s `representation = "K"`). `drm_validate_reml_spec_biv()`'s admit
`if` now also checks this helper; the refusal message's relatedness bullet
now names both `relmat(1 | p | id, K = K)` and `animal(1 | p | id, A = A)`,
and the deferred list drops bare `animal` (replaced by "pedigree-built animal
matrices") since the supplied-`A` route is no longer deferred. No `src/`
(C++) change: `src/drmTMB.cpp` has zero occurrences of `"animal"`/`"relmat"`
and the q2 quadratic-form block is fully provider-agnostic (confirmed in
scouting; re-confirmed here by the bit-identical fit below).

## G3: same-target receipt

### (a) TMB `animal()` REML vs TMB `relmat()` REML control, same K, x1 != x2 fixture

Both `estimator = "REML"`, `opt$convergence = 0`,
`tmb_random_names = c("u_phylo", "beta_mu1", "beta_mu2")` for both.

| quantity | animal() | relmat() control | difference |
|---|---|---|---|
| `opt$objective` (nll) | 74.5213647031 | 74.5213647031 | `0` (exact) |
| `logLik` | -74.5213647031 | -74.5213647031 | `0` (exact) |
| `opt$par` (6-vector) | identical | identical | `max\|d_par\| = 0` (exact) |

Exact machine agreement (not merely `<= 1e-8`): swapping `animal(1 | p | id,
A = K)` for `relmat(1 | p | id, K = K)` with the same numeric matrix produces
byte-identical optimizer trajectories, because both build the identical
`Q_phylo` precision block in `src/drmTMB.cpp` (no branch on marker
identity).

### (b) TMB `animal()` REML vs native DRM.jl REML (direct call), shared-x fixture

Fixture: seed `2026090501`, `g = 14`, `m = 4`, one shared `x` predictor on
`mu1` and `mu2` (required by DRM.jl's own q2 route). TMB script:
`scratchpad/2026-09-05-biv-animal-reml-g3-tmb-shared-x.R`; the same
comparison is repeated as a live testthat assertion in
`tests/testthat/test-reml-biv-animal.R`'s "matches native DRM.jl REML"
test, executed via a direct `JuliaCall::julia_call()` (bypassing the bridge,
which refuses this cell unconditionally -- see below).

| quantity | TMB (`engine = "tmb"`) | DRM.jl (direct, `method = :REML`) | \|difference\| |
|---|---|---|---|
| estimator | `REML` | `REML` | agree |
| logLik (restricted) | -65.2776470088 | -65.2776470082161 (`reml_loglik`) | `5.84e-10` |
| mu1 `(Intercept)` | 0.09762791 | 0.09762790519861095 | `4.80e-09` |
| mu1 `x` | 0.49095522 | 0.4909552240133248 | `4.01e-09` |
| mu2 `(Intercept)` | 0.1370577 | 0.13705768319664452 | `1.68e-08` |
| mu2 `x` | -0.2774525 | -0.27745253408106374 | `3.41e-08` |
| sigma1 | 0.2756763 | 0.27567625828091463 | `4.17e-08` |
| sigma2 | 0.3372765 | 0.33727647720924386 | `2.28e-08` |
| rho12 | 0.09406757 | 0.09406749654270559 | `7.35e-08` |

All differences are `<< 1e-4` (solver-precision level, not the statistical
1e-4 bar the ledger asks for). Coefficient names agree exactly: both engines
report `c("(Intercept)", "x")` for `mu1` and `mu2`.

**SE comparison -- NOT AVAILABLE, a pre-existing DRM.jl boundary, not a
defect introduced by this leaf**: DRM.jl's bivariate q2 STRUCTURED route
(`_fit_bivariate_q2_structured` in `src/gaussian_bivariate.jl`) sets
`V = fill(NaN, length(theta), length(theta))` unconditionally for every
provider (`phylo`/`relmat`/`animal`) and both estimators (ML and REML) --
confirmed live this run: `vcov diag = [NaN, NaN, NaN, NaN, NaN, NaN, NaN,
NaN, NaN, NaN]`. There is no DRM.jl SE to compare `rtol 1e-3` against for
this cell on EITHER marker, so the ledger's SE leg of G3 is recorded here as
"not comparable, both sides equally" rather than skipped. This mirrors the
already-documented `biv_q4_phylo_reml` row in `docs/design/261-reml-by-
route.md` ("SE/vcov are NOT comparable"). Out of this leaf's Scope to fix.

### (c) RED CONTROL: unsupported animal representation stays refused

`animal(1 | p | id, Ainv = Q_animal)` (precision representation, the analogue
of relmat's deferred `Q =`) under `REML = TRUE` still refuses (verbatim,
after G2's widening):
> For bivariate models, `REML` supports phylogenetic (`phylo()`) structured
> effects and exact fixed-covariance spatial, supplied-`K` relmat, or
> supplied-`A` animal q2 location blocks.
> i ...
> i The relatedness exception has the same boundaries and requires matching
> labelled `relmat(1 | p | id, K = K)` or `animal(1 | p | id, A = A)`
> intercepts; supplied precision `Q`/`Ainv`, pedigree-built animal matrices,
> slopes, q4+, and scale-side bivariate relmat/animal REML routes remain
> deferred.
> i ...

## G4: estimator honesty

`fit$estimator == "REML"` on the TMB fit (both fixtures, quoted above).
`fit$bridge$estim_method` is N/A for this cell: the R<->Julia BRIDGE refuses
this whole cell unconditionally for `REML = TRUE`, for BOTH `relmat()` and
`animal()`, independent of `drm_validate_reml_spec_biv()`'s admit list
(`R/julia-bridge.R`, `drm_julia_has_structured_term()` fires before family
dispatch, then `drm_julia_refuse_reml_unsupported()` cli_aborts). This leaf's
Scope is the R-side native validator only and does not touch
`R/julia-bridge.R`; the direct-`JuliaCall` route above is the only way to
reach DRM.jl's own REML estimator string for this cell, and it reports
`estimation_method(fit) === :REML` (quoted above as `estim_method = "REML"`
via `oracle$estim_method` in the live test).

## G5: `docs/design/261-reml-by-route.md`

Regenerated via `Rscript tools/write-reml-route-table.R`: byte-identical to
the committed file (`diff` empty). No row in that table corresponds to the
bivariate q2 relmat/animal REML cell -- its 30 rows are drawn from
`inst/extdata/julia-capabilities.tsv` capability IDs (which has no
`biv_gaussian` relmat/animal q2 row) plus A5's three ordinary-random-effect
shapes; the closest row, `general_covariance_structured`, is the UNIVARIATE
relmat cell, a different route. "No other row moves" holds trivially: no row
moved, because none existed for this cell to move.

## G6: RED CONTROL -- revert and restore

`git diff origin/main -- R/drmTMB.R` isolated and stashed
(`git stash push -- R/drmTMB.R`), restoring `R/drmTMB.R` to origin/main byte-
for-byte:

* Restored sha256: `6f1f5de146b59e882461fe27df835ffa5024ed24a29ced450a978478d2afbcb8`
  (matches `git show origin/main:R/drmTMB.R | sha256sum` exactly).
* Against that reverted state, `tests/testthat/test-reml-biv-animal.R`
  fails: 5 of 6 tests error with the ORIGINAL refusal text quoted verbatim
  above (item 1 under G1); only the "unsupported representations still
  refuse" test incidentally passes (it was already true before this leaf).
* `git stash pop` restored the implementation; sha256 after restore:
  `6a646b66f19bda3904ad8fdc9251550d8d7737c698488b0e7fd2c70f39efc752` (matches
  the sha measured immediately after G2's edit, before the revert).
* An unsupported marker (the Ainv/precision animal representation) stays
  refused with an accurate message after the widening -- quoted in G3(c)
  above.

## Bridge is untouched (confirms the scout's `OWNS` conditional does not fire)

`R/julia-bridge.R`'s structured-term REML gate
(`drm_julia_has_structured_term()` + `drm_julia_refuse_reml_unsupported()`)
already refuses this ENTIRE cell unconditionally for `REML = TRUE`,
independent of provider, before this leaf and after it. No change was made
to `R/julia-bridge.R`.

## Files

* `build_shared_x_fixture.R`, `data.csv`, `K.csv`: the shared-x fixture (seed
  `2026090501`) used for the DRM.jl same-target leg -- `build_shared_x_fixture.R`
  regenerates `data.csv`/`K.csv` deterministically from the seed.
* `probe_direct_julia.jl`, `probe_direct_julia.log`: the standalone
  (non-JuliaCall) Julia script and its output for the provider-blindness
  check (G1 item 4).
* `sha256(tests/testthat/test-reml-biv-animal.R)` at receipt time:
  `f7444726fc2315ecf30577d7c3766efbdffde443d6cb52f64539af8d382b3328`.
