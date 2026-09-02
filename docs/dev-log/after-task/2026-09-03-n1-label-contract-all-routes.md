## 1. Goal

Arc N1 (overnight true-parity lane, headline arc): widen design 258's
coefficient-label producer contract (§7) from the base bridge only to the
remaining live-Julia routes -- structured (relmat/animal/spatial), bivariate
q=2 known-structured, joint missing-predictor, and cross-family -- then
delete the legacy predict-time `gsub()` punctuation rewrite in
`drm_julia_predict_fixed_eta()` and flip design 258's S3-G4 (previously
ABANDONED, per `docs/dev-log/after-task/2026-09-02-s3-label-producer.md`) to
MET.

## 2. What each route needed (discovered empirically against DRM.jl 77513aa0)

**Structured (`drm_julia_structured_payload()`) and bivariate known-structured
(`drm_julia_biv_known_structured_payload()`)** both call
`drmTMB_drm_bridge_structured(...)`, an R-registered Julia wrapper that
forwards to the SAME `DRM.drm_bridge(...)` the base bridge calls -- so
DRM.jl's `_bridge_echo_coef_labels` applies identically once `options$coef_labels`
is supplied. Both payload builders now call the ONE producer,
`drm_julia_bridge_payload_coef_labels()`, and each needed one extra block the
producer builds directly from `drm_julia_collect_structured_terms(formula)`
(no `formula$entries` counterpart at all):
- structured route: `resd` -- DRM.jl's own synthetic name for the
  general-covariance random-effect SD (`"resd_<group>"`), echoed back
  unchanged (`term$group}`, not a base-R spelling to translate). Verified
  stable across all four `drm_julia_structured_families()` (gaussian,
  poisson, nbinom2, gamma) and both `relmat`/`animal` marker types.
- known-structured (q2) route: `phylocov`, a 2x2 among-axis covariance's
  three `Sigma_a:L<row><col>` log-Cholesky entries -- SAME lower-triangular,
  column-major convention already used for the q4 phylo route, refactored
  into one shared `drm_julia_phylocov_block_labels(q)`.

**Joint (`R/julia-joint-missing.R` / DRM.jl's `drm_bridge_joint`) and
cross-family (`drm_julia_xfam_axes()` / `DRM.fit_mixed_family`)** never ask
DRM.jl for a name at all: both build the coefficient vocabulary entirely
R-side (`mu_names <- colnames(spec$X$mu)`, `axes$mu1$coef_names <-
colnames(X)`) and the Julia function returns bare numeric vectors that R
names itself. `drm_bridge_joint()` (Julia side,
`src/joint_missing_bridge.jl`) builds `out["coef_names"]` LITERALLY as
`blocks .* "_" .* terms` from the payload's `mu_names`/`sigma_names`/
`predictor_names` -- there is no round trip to widen. These two routes were
under the contract by CONSTRUCTION before this arc touched anything; what
this arc added is the tests that measure it, not new production code (and
confirmed `predict.drmTMB_julia_xfam()` is its own dedicated S3 method,
never reaching the legacy gsub() path in the first place).

**A base-bridge gap found along the way (not a new route).**
`drm_julia_bridge_payload_coef_labels()` only labelled dpars present in
`formula$entries`. DRM.jl's echo demands a label for EVERY block it fits,
including a dispersion/shape dpar the R formula never names (mirroring the
SAME `~1` default `default_dpar_entry()` in `R/drmTMB.R` silently inserts
for the native TMB engine's own family spec builders, without ever writing
that default into `formula$entries`). This meant ANY Julia-engine fit whose
formula omitted `sigma` -- e.g. the ordinary, common
`drmTMB(bf(mu = y ~ x), gaussian(), engine = "julia")` -- already aborted on
the ALREADY-MERGED base bridge before this arc touched anything. Confirmed by
reproducing it directly. `drm_julia_bridge_default_dpar_labels()` fills these
in as `"(Intercept)"`, gated on a new `family_type` parameter threaded into
the producer from all three call sites that carry one: dispersionless
families (`poisson`, `binomial`) get no default; `biv_gaussian` defaults
`sigma1`/`sigma2`/`rho12`; every other admitted family defaults `sigma`
(`student` ALSO defaults `nu`). Measured directly against `DRM.drm_bridge`
for every family `drm_julia_family_tag()` admits (gaussian, student,
lognormal, poisson, nbinom2, gamma, beta, binomial, biv_gaussian).

## 3. Exact error texts hit and fixed

- `drm_bridge: coef_labels is missing an entry for dpar "resd" (1 fixed-effect
  columns; Julia names: ["resd_g"]); the R side must supply names for every
  dpar when sending coef_labels` -- structured route, fixed by the `resd`
  block above.
- `drm_bridge: coef_labels supplies names for unknown dpar "resd"; the model
  has dpars: mu1, mu2, sigma1, sigma2, rho12, phylocov` -- known-structured
  (q2) route, discovered while probing what block name to use; the correct
  block for THIS route is `phylocov` (2x2), not `resd` (the q2 route's shared
  relmat/animal term is a bivariate random effect with an among-axis
  covariance, not a scalar SD).
- `drm_bridge: coef_labels is missing an entry for dpar "sigma" (1
  fixed-effect columns; Julia names: ["sigma_(Intercept)"]); the R side must
  supply names for every dpar when sending coef_labels` -- the base-bridge
  default-dpar gap, reproduced on a bare `bf(mu = y ~ x)` Gaussian fit (no
  structured term at all) and on `bf(mu1 = y1 ~ x, mu2 = y2 ~ x)`
  `biv_gaussian` (missing `sigma1`/`sigma2`/`rho12` too).
- `drm: bivariate q=2 structured Julia route currently requires mu1 and mu2
  to use the same fixed-effect design` -- a probing mistake (mismatched mu1/
  mu2 designs in a hand-built Julia-side test), not a drmTMB bug; noted for
  completeness since it shaped the final biv known-structured test fixture.

## 4. Verification

- Offline (no Julia, `env -u DRM_JL_PATH -u DRMTMB_JULIA_TESTS`): full
  `test-coefficient-labels.R` (114 assertions, 0 failures) and the filtered
  suite `coefficient-labels|julia-bridge|julia-structured|julia-joint|xfam`
  (193 non-live assertions, 0 failures/errors, 20 live tests correctly
  skipped).
- Live (`DRM_JL_PATH` = the pinned 77513aa0 clone, `DRMTMB_JULIA_TESTS=true`):
  all 4 new live tests pass -- relmat structured fit (fixed-effect names
  identical to a same-formula native TMB fit), cross-family fit, joint fit,
  and the Rose-A10-style predict(newdata) case (factor + `x*z` interaction on
  a structured Julia fit, finite response, no punctuation rewrite anywhere).
  Separately re-verified the base-bridge default-dpar fix on gaussian
  (mu-only), biv_gaussian (mu1/mu2-only), nbinom2 (mu-only), and confirmed
  Poisson still gets NO default sigma (dispersionless).
- `grep -rEn 'gsub\([^)]*(__bridge_|& )' R/` returns nothing (N1-G4).
- `python3 -m unittest tools/tests/test_capability_ledger.py` -> OK (80
  tests), C14/C17 checks pass.
- `Rscript tools/check-julia-phylo-labels-receipt.R
  docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json
  --current --self-test` -> `PHYLO_LABEL_RECEIPT_PASS labels=12 rows=72
  checks=8 tolerance=4e-06`, all 12 corruption self-tests correctly rejected,
  regenerated LAST on this arc's final R/ state
  (`PHYLO_LABEL_PUBLIC_PASS elapsed=35.799`).

## 5. NOT covered / deferred

- `student`'s `nu` default and `lognormal`/`beta`'s `sigma` default were
  verified against `DRM.drm_bridge` directly (Julia-side, bypassing R) but
  NOT exercised end-to-end through a live `drmTMB(..., engine = "julia")`
  fit in this arc's tests -- only gaussian/nbinom2/biv_gaussian/poisson were
  (§4). The `drm_julia_bridge_default_dpar_labels()` logic covers them by the
  same mechanism, but no dedicated regression test pins the student/lognormal/
  beta cases; a future arc should add one if a live fit for those families
  without an explicit `sigma`/`nu` formula is found to regress.
- Row 7's term-order disagreement (design 258 §3/§6) is unchanged and out of
  this arc's scope -- still refused by the existing validator + the R-side
  cross-check, not newly addressed.
- No DRM.jl-side change; the echo (`_bridge_echo_coef_labels`,
  `src/bridge.jl`) was read only, at the pinned 77513aa0 clone, per this
  lane's invariant (DRM.jl is a read-only foreign lane).
- Full `devtools::test()` was NOT re-run (per `LOOP/GOAL.md`'s "full suite
  NOT re-run unless R/ code outside the guard changes" -- this arc's only
  code changes are inside `R/julia-bridge.R`, the Julia payload path).

## 6. Gate summary (leaf-n1, `.unlazy/night/gates/leaf-n1.md`)

G1-G7 verified directly (commands and output captured in this session);
G8 (Rose adversarial pass) and G9 (PR merge + S3-G4 flip in
`.unlazy/true-parity/`) are explicitly out of this leaf's scope per the
dispatch brief ("G1-G7 are yours (G8 Rose, G9 the coordinator)").

| Gate | Result |
|---|---|
| N1-G1 (unit tests, 4 builders) | `ALL_BUILDERS_LABEL_OK` |
| N1-G2 (live echo, 3 routes) | `LIVE_ECHO_ALL_ROUTES_OK` |
| N1-G3 (live structured predict) | `STRUCTURED_PREDICT_OK` |
| N1-G4 (no punctuation rewrites) | `NO_GUESSING_ANYWHERE_OK` |
| N1-G5 (design doc, all routes covered) | `SPEC_ALL_ROUTES_OK` |
| N1-G6 (CI-like + ledger guard) | `CI_LIKE_AND_GUARDS_OK` |
| N1-G7 (lss-tip-identity receipt, regenerated last) | `TIP_RECEIPT_OK` |

## 7. Commits (branch `claude/n1-label-contract-all-routes`, off `origin/main` @ `0ceb77eb0`)

- `949a1ebf3` feat(julia-bridge): widen coef_labels producer to structured/known-structured routes; fix base-bridge default-dpar gap
- `c4e6bbf66` test(julia-bridge): coef_labels contract on structured/known-structured/joint/xfam routes
- `eb27ece37` docs(design-258): S7.4 rewritten -- every bridge route now under the coef_labels contract
- `722aeaf71` evidence(lss-tip-identity): regenerate the public-001 receipt on N1's final R/ state
