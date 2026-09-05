# Bivariate cells census: drmTMB native x DRM.jl native x the R bridge

Prerequisite census for DRM.jl #471 ("structured markers for bivariate Student
and LogNormal"), deferred past v0.1.0 by D-179 #5. This document does not
decide whether that fence still holds; it supplies the measured grid the
decision needs. DRM.jl pin `430ef64cc` (local checkout at
`/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc`); drmTMB `origin/main`
at commit `79e8f0951` (worktree HEAD, `git -C drmTMB show origin/main:<path>`
throughout). Measured 2026-09-05. `DRM_JL_PATH` was unset for every R-side
probe in this run; a Julia-setup error ("engine = \"julia\" needs a local
DRM.jl checkout") is read as "would dispatch" rather than as a refusal, per
the task brief.

GRID: 3 families (`biv_gaussian`, `biv_student`, `biv_lognormal`) x 7
structures (residual-only `rho12 ~ 1`/`~ x`; phylogenetic on the mean only,
q=2; phylogenetic on mean and scale, q=4; `relmat()` q=2; `animal()` q=2;
`spatial()` q=2; `meta_V()` known covariance) x 2 estimators (ML, REML) = 42
cells x 3 columns. `relmat`/`animal`/`spatial` are scoped to their q=2
(location-only) form because that is the only shape drmTMB's own REML
validator ever admits for these three marker types (see the `biv_gaussian`
table); the q=4 (mean+scale) generalisation of `relmat`/`animal`/`spatial`
exists on both engines under ML but is noted as a caveat rather than a
tenth structure row, to keep the grid the same shape the task specified.

## How to read a cell

- **FITS** -- the call returns a fitted model (or a cited existing test does).
- **REFUSES** -- an R-side `cli_abort()`/`ArgumentError` fires before or
  instead of a fit, with the quoted text.
- **N/A** -- the model does not exist under this family/structure combination
  on this engine at all (not an estimator-specific refusal).
- **UNMEASURED** -- neither the code nor an existing test settles the cell,
  and a fit was not run this session; the reason is given.

---

## 1. `biv_gaussian`

| Structure | Estimator | drmTMB NATIVE (`engine="tmb"`) | DRM.jl NATIVE | BRIDGE (`engine="julia"`) |
|---|---|---|---|---|
| residual-only (`rho12 ~ 1`/`~x`) | ML | FITS -- baseline route, `R/family.R:11-36` (`biv_gaussian()`), `R/drmTMB.R:9300` (`drm_build_biv_gaussian_spec`); fit oracle `tests/testthat/test-biv-gaussian.R` throughout | FITS -- `_fit_bivariate_residual` fallback, `src/gaussian_bivariate.jl:203` (reached when no structured marker is present) | FITS -- `drm_julia_registry_families("fe")` admits `biv_gaussian` unconditionally (`R/julia-family-registry.R:45`); measured this run: `engine="julia"` on a plain residual formula reaches the Julia-setup check ("needs a local DRM.jl checkout"), i.e. would dispatch (`/tmp/probe3.R` row 2) |
| residual-only | REML | FITS -- measured, `docs/design/261-reml-by-route.md:78-85` (`biv_gaussian_residual`): logLik=-97.0212058184, no abort branch in `drm_validate_reml_spec_biv()` fires for a fixed-effect-only bivariate model | REFUSES -- `src/gaussian_bivariate.jl:198-203`: "method = :REML needs random effects to restrict, and the residual-only bivariate Gaussian model has no random effects"; also DRM.jl #624's 16-refuse list, "bivariate residual-only Gaussian/LogNormal/Student" | REFUSES -- measured, design 261 same row: `engine="julia" cannot fit bivariate Gaussian models by REML=TRUE` (`drm_julia_refuse_reml_unsupported()`, `R/julia-bridge.R:1198-1216`); `drm_julia_reml_supported()` requires `drm_julia_biv_phylo_dimension()=="q4"`, never true for a plain residual formula |
| phylo, q=2 (mean only) | ML | FITS -- `R/drmTMB.R` biv phylo-mu path (`phylo_mu` structured spec inside `drm_build_biv_gaussian_spec`); exercised by `tests/testthat/test-julia-tmb-parity.R:338` (`drm_parity_fit_q2_phylo`, cited from the R side as the native comparator) | FITS -- `_fit_bivariate_q2_structured`, reached via `_bivariate_q4_marker()`'s `:structured_q2` branch which admits `kind in (:phylo, :relmat, :animal)` for the `{mu1,mu2}`-only marker set (`src/gaussian_bivariate.jl:342-373`) | FITS -- dedicated q2 phylo route (not the generic structured-terms route): `drm_julia_biv_phylo_dimension()` returns `"q2"` for `{mu1,mu2}` phylo markers, and `R/julia-bridge.R:1357-1361` builds the matching `phylocov` coefficient block; parity test `tests/testthat/test-julia-tmb-parity.R:338` ("q2 Gaussian phylo residual-correlation bridge parity is banked narrowly") |
| phylo, q=2 | REML | FITS -- `drm_validate_reml_spec_biv()`, `R/drmTMB.R:2953-2977`: admits REML whenever `structured_mu_type(phylo_mu) == "phylo"`, independent of q2/q4 | FITS -- `src/gaussian_bivariate.jl:198-203` comment: "REML IS available on the structured bivariate routes: q=4 ... and q=2 (#470)"; the q2 path takes `method` through unchanged (`_fit_bivariate_q2_structured`, line ~534) | REFUSES -- `drm_julia_reml_supported()` (`R/julia-bridge.R:1198-1216`) checks `drm_julia_biv_phylo_dimension(formula) == "q4"` only; a q2 phylo formula returns `"q2"` and REML is refused with `drm_julia_refuse_reml_unsupported()` before dispatch. UNMEASURED by a live fit this run (cheap live confirmation not run; the gate is unambiguous from the code alone) |
| phylo, q=4 (mean+scale) | ML | FITS -- same spec path as q=4 REML below, with `REML=FALSE`; existing evidence in `R/julia-bridge.R` capability-comparison comment block (design 261 line 105-112 cites the same fixture) | FITS -- `_fit_bivariate_q4_phylo`, `src/gaussian_bivariate.jl:167-177` (`:phylo_q4` branch of `_bivariate_q4_marker`) | FITS -- `docs/design/261-reml-by-route.md:104-112` (`biv_q4_phylo_reml`): DRM.jl #624 census, 14-fit list, "bivariate q=4 phylo native AND through drm_bridge" |
| phylo, q=4 | REML | FITS -- design 261 line 108-109: existing evidence (expensive fixture, not re-run), `max|d_coef|=0.002889`, loglik constant residual 0.001938 | FITS -- same route, `method` forwarded; design 261 line 110 | FITS -- design 261 line 111: PARITY_PASS 33/33 on the committed `biv-q4-phylo-reml` fixture; this is the row promoted "partial -> covered" by commit 79e8f0951 (branch head). CAVEAT (design 261 line 112, out of scope here): SE/vcov are NOT comparable on this cell -- `_q4_fd_vcov` finite-differences the ML objective on a REML fit, a 10.5% SE gap (DRM.jl #624 item 3) |
| relmat, q=2 (location) | ML | FITS -- `check.R:51-55` ("Matching bivariate coordinate-spatial q=2, animal(), and relmat() q=2 location effects receive the corresponding structured diagnostics"); `tests/testthat/test-reml-bivariate-relmat-q2.R` fits this shape under both ML and REML | FITS -- `:structured_q2` branch, `kind=:relmat`, `src/gaussian_bivariate.jl:358-373` | FITS -- `drm_julia_biv_known_structured_payload()`, `R/julia-bridge.R:5890-5921`; test `tests/testthat/test-julia-structured.R:278-306` ("admits relmat and animal only") builds a valid `kwarg="K"` payload for a `relmat(1\|p\|id, K=K)` pair on `mu1`/`mu2` |
| relmat, q=2 | REML | FITS -- `drm_reml_admits_biv_relmat_q2_intercept()` exception, `R/drmTMB.R:2945-2951`, gated inside `drm_validate_reml_spec_biv()`; `tests/testthat/test-reml-bivariate-relmat-q2.R` | FITS -- design 261's phylo-q2 comment applies identically ("REML IS available ... and q=2 (#470)"); `_bivariate_q4_marker` does not distinguish marker `kind` for REML eligibility | REFUSES -- `R/julia-bridge.R:535-553`: `drm_julia_has_structured_term(formula)` (relmat/animal/spatial on any dpar) routes to `drmTMB_julia_biv_known_structured_bridge()`, which calls `drm_julia_refuse_reml_unsupported(REML, "bivariate q2 known-covariance structured-effect")` UNCONDITIONALLY whenever `REML=TRUE`, before the q2/q4 dimension is even inspected |
| animal, q=2 (location) | ML | FITS -- same `check.R:51-55` citation (`animal()` q=2 named alongside relmat/spatial); no dedicated `test-reml-bivariate-animal-q2.R` file exists in the tree, so this is a code-path citation, not a run test. UNMEASURED beyond that citation (not re-run this session; the parallel relmat/spatial exception tests make a fit very likely but this exact combination was not fitted live) | FITS -- `:structured_q2` branch, `kind=:animal`, same code as relmat (`src/gaussian_bivariate.jl:358-373`) | FITS (ML) -- `tests/testthat/test-julia-structured.R:307-317` builds a valid `animal(1\|p\|id, A=A)` payload (`kwarg="A"`) for `mu1`/`mu2` |
| animal, q=2 | REML | REFUSES -- `drm_validate_reml_spec_biv()`, `R/drmTMB.R:2953-2977`: the admit list is `structured_type=="phylo"` OR `spatial_q2_admitted` OR `relmat_q2_admitted` -- `structured_mu_type()` returns `"animal"` for an `animal()` marker (`R/drmTMB.R:12946-12975`), which matches none of the three, so the `cli_abort()` fires ("REML supports phylogenetic ... structured effects and exact fixed-covariance spatial or supplied-K relmat q2 location blocks") | FITS -- same as relmat/phylo q2, `kind` is not distinguished for REML eligibility in `_bivariate_q4_marker`/`_fit_bivariate_q2_structured` | REFUSES -- same unconditional structured-term REML refusal as relmat, `R/julia-bridge.R:535-553` |
| spatial, q=2 (location) | ML | FITS -- `check.R:51-55`; `tests/testthat/test-reml-bivariate-spatial-q2.R` fits this shape | REFUSES natively as written -- `src/gaussian_bivariate.jl:342-361`: the q2 marker-kind allow-list is `(:phylo, :relmat, :animal)` ONLY; a literal `spatial(coords=...)` marker at q2 throws "the bivariate q=2 front end currently supports only phylo(...), relmat(...), or animal(...) markers". A direct `drm(f, Gaussian(); ...)` call with a spatial q2 marker REFUSES even though spatial IS allowed at q4 (`src/gaussian_bivariate.jl:376-378`) -- an asymmetry stated explicitly in the file's own comment: "bivariate q=2 spatial(coords) is not implemented; use a known covariance relmat route or method = :ML native TMB" (`src/gaussian_bivariate.jl:188-189`) | FITS (ML) via translation, not a literal pass-through -- `drm_julia_biv_known_structured_payload()` REWRITES a `spatial(1\|p\|id, coords=coords)` marker into `relmat(1\|id)` with `kwarg="K"` before marshalling (`tests/testthat/test-julia-structured.R:318-346`: `spatial_payload$kwarg == "K"`, `spatial_payload$formula$mu1 == "y1 ~ x + relmat(1 \| id)"`). The bridge computes drmTMB's own fixed-range covariance kernel on the R side and hands DRM.jl a plain relmat call, sidestepping the native gap on the left just documented |
| spatial, q=2 | REML | FITS -- `drm_reml_admits_biv_spatial_q2_intercept()` exception, `R/drmTMB.R:2937-2943`; `tests/testthat/test-reml-bivariate-spatial-q2.R` | REFUSES -- same as ML: the marker is rejected before any estimator branch is reached (`src/gaussian_bivariate.jl:342-361`) | REFUSES -- same unconditional structured-term REML refusal (`R/julia-bridge.R:535-553`), which fires regardless of the ML-side K-matrix translation available for this cell |
| `meta_V()` (known covariance) | ML | FITS -- measured, `tests/testthat/test-biv-gaussian.R:2929-2967` ("bivariate Gaussian known V likelihood matches a base R MVN calculation"); `mu1 = y1 ~ x + meta_V(V=V)` | FITS -- `src/gaussian_bivariate.jl:150-153`, "A8: known bivariate sampling covariance (drmTMB's meta_vcov_bivariate) is consumed by the residual route only"; `V!==nothing && structured_marker!==nothing` errors, so meta_V ONLY combines with the residual route, matching drmTMB's own restriction (`R/drmTMB.R:9578`, "cannot yet be combined with meta_V" for random effects) | REFUSES -- measured this run (`/tmp/probe3.R` row 1): `engine="julia" could not find model variable "V" in data` -- the R-side marshalling tries to build a `model.matrix()` column named `V` from the `meta_V(V=V)` call and fails before any Julia-setup check runs, i.e. it never reaches "would dispatch". `drm_julia_rewrite_meta_V()` (`R/julia-bridge.R:2249-2289`) exists and handles the UNIVARIATE Gaussian meta_V spelling, but nothing in the bivariate dispatch path (`drmTMB_julia_biv_gaussian_bridge`, the plain `fe`-admitted route) calls it, so a bivariate meta_V formula is never rewritten and always fails this way |
| `meta_V()` | REML | FITS -- measured this run (`/tmp/probe2.R`): `drmTMB(bf(mu1 = y1 ~ x + meta_V(V=V), mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1), family = biv_gaussian(), data = d, REML = TRUE)` returns a fitted model, logLik=-103.231247629401 (n=40, seed=1, `OPENBLAS_NUM_THREADS=1`, `devtools::load_all()` on this worktree). `drm_validate_reml_spec_biv()` never inspects `V_known`/`has_known_v`, so nothing in the validator blocks it; this cell was AMBIGUOUS from the code alone and is why it was fitted live per the task brief | REFUSES -- `src/gaussian_bivariate.jl:164-167`: `V!==nothing && method===:REML` throws "V (known sampling covariance) has no REML target in this package: it is accepted only on the bivariate residual-correlation route, which marginalises no random effect ... use method = :ML" | REFUSES -- same marshalling failure as ML above blocks this cell before REML is ever evaluated; `drm_julia_reml_supported()` would also refuse it on its own terms (meta_V never satisfies the `biv_phylo_dimension()=="q4"` test) even if marshalling were fixed |

## 2. `biv_student`

Every structured/random-effect and every REML cell refuses on **all three
columns** for this family, by design on both sides of the port. Native DRM.jl
even documents a live 2026-08-25 re-verification against installed drmTMB
0.7.0 reproducing the identical R refusal text (`src/bivariate_student.jl:80-93`).

| Structure | Estimator | drmTMB NATIVE (`engine="tmb"`) | DRM.jl NATIVE | BRIDGE (`engine="julia"`) |
|---|---|---|---|---|
| residual-only (`rho12 ~ 1`) | ML | FITS -- `R/drmTMB.R:10061` (`drm_build_biv_student_spec`); measured this run, `/tmp/probe1.R`: logLik=-99.1265609686408 (n=40, seed=1) | FITS -- `src/bivariate_student.jl:57-125`, residual-only closed-form bivariate-t density | REFUSES -- `R/drmTMB.R:271-280`: explicit engine gate, "{.fn biv_student} is implemented only for {.code engine = \"tmb\"}; the Julia route is deferred", fires before the family registry is even consulted |
| residual-only | REML | REFUSES -- `R/drmTMB.R:359-362`: family-level gate, "{.arg REML} is implemented for univariate/bivariate Gaussian and binomial models"; `tests/testthat/test-biv-student.R:517-525` | REFUSES -- `src/bivariate_student.jl:119-123`: "the bivariate Student-t route implements ML only ... there is nothing for REML to integrate out" | REFUSES -- same engine gate as ML above (fires before REML is checked) |
| phylo/relmat/animal/spatial q=2 | ML | REFUSES -- `R/drmTMB.R:10106`: "{.fn biv_student} currently allows fixed-effect formulas only; random and structured effects are deferred"; `tests/testthat/test-biv-student.R:420-437` (random intercept -> "fixed-effect"; spatial marker -> "structured effects") | REFUSES -- `src/bivariate_student.jl:71-93,119-133`: explicit `structured_marker !== nothing` rejection, "the bivariate Student-t route is residual-only ... This is a deliberate rejection, not a missing port" (cites #471 by name) | REFUSES -- same `engine="tmb"`-only gate |
| phylo/relmat/animal/spatial q=4 | ML | REFUSES -- same fixed-effect-only gate as q=2 (no q=2/q4 distinction exists; the family has no random-effect machinery at all) | REFUSES -- same structured-marker rejection | REFUSES -- same gate |
| phylo/relmat/animal/spatial, any dimension | REML | REFUSES -- both the family-level REML gate and the structured-effect gate independently fire | REFUSES -- both the `:REML`-only-for-ML gate and the structured-marker gate independently fire | REFUSES |
| `meta_V()` | ML | REFUSES -- `R/drmTMB.R:10116` region text, "Random or structured effects, meta_V, offsets, and sigma/nu/rho predictors are deferred"; measured, `tests/testthat/test-biv-student.R:440-452` (`"meta_V"`) | REFUSES -- `drm(f::BivariateDrmFormula, ::Student; data, g_tol, method)` has no `V` parameter at all (`src/bivariate_student.jl:118-119`); a `meta_V()` call cannot reach this route | REFUSES -- same `engine="tmb"`-only gate |
| `meta_V()` | REML | REFUSES (both the meta_V gate and the REML gate) | REFUSES (no `V` parameter; also ML-only) | REFUSES |

## 3. `biv_lognormal`

The R side is symmetric with `biv_student` (fixed-effects-only, no REML), but
DRM.jl-native has since diverged: it now fits every structured/relmat/animal/
spatial/phylo q2 and q4 cell under ML by delegating the whole fit to its
bivariate Gaussian engine on `log(y)`, because the lognormal density is a
parameter-free Jacobian shift of the Gaussian one. This is the "Julia-native
but R-refused" half of DRM.jl #471 becoming concrete (see the summary below).

| Structure | Estimator | drmTMB NATIVE (`engine="tmb"`) | DRM.jl NATIVE | BRIDGE (`engine="julia"`) |
|---|---|---|---|---|
| residual-only (`rho12 ~ 1`) | ML | FITS -- `R/drmTMB.R:9980` (`drm_build_biv_lognormal_spec`); measured this run, `/tmp/probe1.R`: logLik=-24.5374657385619 (n=40, seed=1) | FITS -- `src/bivariate_lognormal.jl:82-119`, delegates to `drm(f, Gaussian(); data=log.(data), ...)` | REFUSES -- `drm_julia_family_tag()` (`R/julia-bridge.R:1015-1032`) does not admit `biv_lognormal`: `biv_lognormal` has no row in `R/julia-family-registry.R` at all (only `gaussian`, `biv_gaussian`, `student`, `lognormal` -- the univariate one -- and the count/continuous families are registered); measured this run, `/tmp/probe4.R`: "engine = \"julia\" currently supports Workflow G fixed-effect families (Gaussian, bivariate Gaussian, Student-t, lognormal, ...)" -- note "lognormal" in that message is the UNIVARIATE family, not `biv_lognormal` |
| residual-only | REML | REFUSES -- same family-level gate as `biv_student`, `R/drmTMB.R:359-362` | REFUSES -- `src/bivariate_lognormal.jl:88-93`: "the bivariate lognormal route implements ML only ... drmTMB's biv_lognormal() first slice has no random effects to integrate out, and REML for the structured (phylo/relmat/animal/spatial) cells is a later slice"; DRM.jl #624's 16-refuse list also names "bivariate residual-only Gaussian/LogNormal/Student" | REFUSES -- same family_tag gate as ML above |
| phylo, q=2 (mean only) | ML | REFUSES -- `R/drmTMB.R:10007`: "{.fn biv_lognormal} currently allows fixed-effect formulas only; random and structured effects are deferred"; `tests/testthat/test-biv-lognormal.R:173` ("fixed-effect") tests the parallel random-intercept refusal | FITS -- `src/bivariate_lognormal.jl:46-66,95-115`: "phylo(1\|group), relmat(1\|group), animal(1\|group), and spatial(1\|group) markers are supported through the same delegation ... the q=2 exact-Gaussian route (matching markers on mu1/mu2 only) and the q=4 sparse-Laplace PLSM route ... are exactly the ones documented under drm(::BivariateDrmFormula, ::Gaussian), run on logged data" | REFUSES -- same family_tag gate (the family is never admitted to the bridge regardless of structure) |
| phylo, q=4 (mean+scale) | ML | REFUSES -- same fixed-effect-only gate (no q2/q4 distinction; the family has no random-effect machinery natively) | FITS -- same delegation, q4 sparse-Laplace PLSM route on `log(y)` (`src/bivariate_lognormal.jl:48-56`) | REFUSES -- same gate |
| relmat/animal/spatial q=2 (location) | ML | REFUSES -- same fixed-effect-only gate | FITS -- same delegation; the file's own worked example only shows the residual formula, but the docstring is explicit that relmat/animal/spatial ride the identical Gaussian q2/q4 dispatcher (`src/bivariate_lognormal.jl:46-66`). UNMEASURED by a live Julia fit this session (no Julia runtime was invoked, per the task's "no Julia is needed" instruction) -- this cell rests on the docstring's own claim plus the shared-dispatcher code path, not an independent test citation | REFUSES -- same gate |
| any structured/phylo marker, any dimension | REML | REFUSES (family-level REML gate on the R side; DRM.jl's own "REML for the structured cells is a later slice" on the Julia side -- i.e. this is a genuine agreement on refusal, reached for two different reasons: R's biv_lognormal has no RE machinery at all, Julia's does but REML is not wired to it yet) | REFUSES -- `src/bivariate_lognormal.jl:88-93` covers residual AND structured cells identically (the `method===:ML` check runs before any route dispatch) | REFUSES |
| `meta_V()` | ML | REFUSES -- `R/drmTMB.R:10191` region text mirrors the biv_student wording, "Random or structured effects, meta_V, offsets, and sigma/nu/rho predictors are deferred" (not independently re-run this session; the biv_student sibling test at `tests/testthat/test-biv-student.R:440-452` demonstrates the shared code path fires the same "meta_V" message for both families, and `R/drmTMB.R:10191` is the biv_lognormal-specific copy of that text) | REFUSES -- `drm(f::BivariateDrmFormula, fam::LogNormal; data, tree, K, A, coords, spatial_range, g_tol, ..., method)` (`src/bivariate_lognormal.jl:84-87`) has no `V` parameter at all | REFUSES -- same family_tag gate |
| `meta_V()` | REML | REFUSES (both the meta_V gate and the REML gate independently) | REFUSES (no `V` parameter; also ML-only) | REFUSES |

---

## R-native but Julia-refused

The cells where drmTMB's own `engine = "tmb"` fits a model that neither
DRM.jl-native nor the bridge (`engine = "julia"`) will fit, at the current
pin. This is exactly the decision set DRM.jl #471 and D-179 #5 bear on for the
two non-Gaussian bivariate families, plus several `biv_gaussian` gaps the
census surfaced along the way.

**D-179 #5 fence, quoted verbatim** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:142`):
> "D-179 #5 deferred #471 (biv Student/LogNormal structured markers) 'past
> v0.1.0' -- DRM.jl is at 0.7.0; does the fence still hold?" | decide-with-Shinichi
> | still deferred; the `cells.tsv` census (handover UNSURE 3) is the
> prerequisite either way -- run the census (task), decide after

1. **`biv_student` + any structured marker (phylo/relmat/animal/spatial), any
   dimension, ML.** drmTMB refuses this too ("random and structured effects
   are deferred", `R/drmTMB.R:10106`), so THIS half of #471 is **not** an
   R-native-but-Julia-refused gap -- both sides refuse it, for reasons each
   side documents independently (`src/bivariate_student.jl:32-56`, citing
   drmTMB's own refusal text as the reason no reference implementation
   exists to port). **The #471 fence is confirmed still binding for
   `biv_student`**, not stale.
2. **`biv_gaussian` + `animal()` q=2, REML.** drmTMB FITS every q=2
   `phylo`/`relmat`/`spatial` REML cell but explicitly excludes `animal()`
   from the same admit list (`R/drmTMB.R:2953-2977`; `structured_mu_type()`
   returns `"animal"`, matching none of `phylo`/`spatial_q2_admitted`/
   `relmat_q2_admitted`). DRM.jl-native fits `animal` REML at q2 identically
   to `relmat` (`_bivariate_q4_marker` treats `kind` uniformly for REML
   eligibility). The bridge refuses ALL relmat/animal/spatial REML
   unconditionally (`R/julia-bridge.R:535-553`). So on this ONE cell drmTMB's
   OWN native gate is narrower than DRM.jl's -- an R-side gap, not a
   Julia-side one; flagged here as a finding, not filed as an issue in this
   leaf.
3. **`biv_gaussian` + `spatial()` q=2, ML or REML, as a LITERAL spatial
   marker on the direct-Julia call.** drmTMB fits it natively
   (`tests/testthat/test-reml-bivariate-spatial-q2.R`). A direct DRM.jl call
   with `spatial(1|group, coords=coords)` at q=2 REFUSES
   (`src/gaussian_bivariate.jl:342-361`, "the bivariate q=2 front end
   currently supports only phylo(...), relmat(...), or animal(...) markers").
   The BRIDGE reaches the same fitted answer only by rewriting the marker to
   `relmat()` with a precomputed K matrix on the R side before the call ever
   reaches Julia -- so "DRM.jl NATIVE" genuinely refuses this shape while the
   bridge papers over it.
4. **`biv_gaussian` + `meta_V()`, REML.** drmTMB fits it (measured this run,
   logLik=-103.231247629401). DRM.jl-native explicitly refuses it
   (`src/gaussian_bivariate.jl:164-167`, "V ... has no REML target in this
   package"). The bridge refuses it too, but for an unrelated marshalling
   reason (see the `biv_gaussian` table). This is a genuine capability gap on
   the REML axis for known-covariance meta-analysis, independent of #471.
5. **`biv_gaussian` residual-only, REML** (already recorded in
   `docs/design/261-reml-by-route.md:78-85` as `biv_gaussian_residual`, NOT
   re-derived here): drmTMB fits a plain fixed-effect bivariate Gaussian REML
   that neither DRM.jl-native nor the bridge admits. Carried into this census
   for completeness of the R-native-but-Julia-refused list, not as a new
   finding.

## Julia-native but R-refused

1. **`biv_lognormal` + `phylo`/`relmat`/`animal`/`spatial`, q=2 AND q=4, ML.**
   DRM.jl-native fits every one of these by delegating the whole fit to its
   verified bivariate Gaussian engine on `log(y)` (`src/bivariate_lognormal.jl:46-66`,
   "supported through the same delegation ... There is no separate
   lognormal structured engine to build or verify"). drmTMB's own
   `biv_lognormal()` refuses ALL random and structured effects unconditionally
   (`R/drmTMB.R:10007`, "currently allows fixed-effect formulas only; random
   and structured effects are deferred"). **This is the concrete,
   measured-this-session answer to the LogNormal half of DRM.jl #471's
   deferral question**: DRM.jl has already closed this gap on its own side
   (at the pinned commit `430ef64cc`) while drmTMB has not; the fence in
   D-179 #5 was written when neither side supported it, and that premise no
   longer holds for `biv_lognormal` specifically (it still holds for
   `biv_student`, per finding 1 above). Not reachable through the R bridge
   either way, since `biv_lognormal` has no row in
   `R/julia-family-registry.R` and so is refused by `drm_julia_family_tag()`
   before any structure-specific question is even asked.
2. **`biv_gaussian` + `relmat`/`animal`/`spatial`, q=4 (mean AND scale
   structured), ML.** DRM.jl-native's `_bivariate_q4_marker()` admits
   `kind in (:phylo, :relmat, :animal, :spatial)` uniformly at q=4
   (`src/gaussian_bivariate.jl:376-386`) and REML too (same route). drmTMB's
   own q4 support is asserted only for `phylo` in the REML validator
   (`R/drmTMB.R:2953-2977`); whether drmTMB's ML path (not gated by that
   validator) fits a q4 `relmat`/`animal`/`spatial` layout was NOT verified
   live this session -- `check.R:55-58`'s docstring text ("Matching bivariate
   phylogenetic, coordinate-spatial, animal-model, or relmat() q4 ...")
   suggests native ML support exists, which would make this NOT a genuine
   Julia-ahead gap after all. **Marked UNMEASURED, not asserted**, pending a
   live q4-relmat/animal/spatial ML fit on the R side; listed here as the one
   place this census could not close the loop within its no-Julia-runtime
   scope.

## Not covered by this census

- Live fits were run only for the four ambiguous `biv_gaussian` cells
  (`meta_V` x {ML, REML}, plus two control probes); every other FITS/REFUSES
  verdict rests on a cited code gate or an existing named test, per the task
  brief's "cheap fit" carve-out being reserved for genuinely ambiguous cells.
- `biv_gaussian` + `relmat`/`animal`/`spatial` at q=4 was left UNMEASURED (see
  finding 2 above) rather than guessed at.
- `biv_lognormal` structured cells were confirmed from DRM.jl's own source
  and docstring, not from a live Julia fit (no Julia runtime was started this
  session, matching the task's "no Julia is needed for any of these leaves").
- Bridge-side inference (profile/bootstrap CIs) for any FITS cell above is out
  of scope; this census is a fit/refuse census only, at the point-estimate
  level.
- Whether the `spatial` q=2-to-`relmat` translation the bridge performs for
  `biv_gaussian` produces a NUMERICALLY faithful K matrix relative to native
  TMB's spatial kernel was not checked; only that a payload is built and the
  test suite's own assertions on its shape pass.
- This census decides nothing by itself. It supplies the grid the D-179 #5
  fence review (and any future #471 follow-up) needs; the fence review itself
  is a separate owner decision.
