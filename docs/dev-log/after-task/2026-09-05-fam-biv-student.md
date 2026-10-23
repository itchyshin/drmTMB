# After-task: admit `biv_student()` through `engine = "julia"` (leaf fam-biv-student)

Date: 2026-09-05
Branch: `claude/parity-fam-biv-student` (worktree
`~/local-scratch/parity-joint/wt-fam-biv-student`, cut from `origin/main`,
re-merged with `origin/main` at `4c1f5a63a` during the run)
DRM.jl pin: `430ef64cc` (`~/local-scratch/parity-joint/drmjl-430ef64cc`)
Acceptance ledger: `.unlazy/parity/gates/leaf-fam-biv-student.md`

## 1. What the leaf was asked to answer

Does DRM.jl's `biv_student` tag actually route end to end through the bridge,
and does it land on the same target as native TMB? If it does not, open the
DRM.jl PR first and mark the drmTMB gate blocked.

## 2. The answer

It routes, and **DRM.jl needed no change at all**. Probed directly at the pin
before any R edit, `DRM._bridge_family("biv_student")` returns `Student()`
(`src/bridge.jl`), and because bivariate-ness is a property of the FORMULA in
DRM.jl the keyed `mu1`/`mu2` parts select `src/bivariate_student.jl`.
`DRM.drm_bridge(formula = <mu1/mu2/sigma1/sigma2/nu/rho12>, family =
"biv_student", data = ...)` returned `converged = true`, 8 coefficients,
`loglik = -336.5381977591065` on a shape-only Julia-side draw, and
`dpars = ["mu1", "mu2", "nu", "rho12", "sigma1", "sigma2"]`. The pin clone's
`src/` is unmodified by this leaf.

## 3. What was refused before (G1 RED, measured verbatim)

The family was refused TWICE on the R side. On `origin/main` source, with the
same call that fits natively:

* `drmTMB(bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, nu = ~1,
  rho12 = ~1), family = biv_student(), data = dat, engine = "julia")` aborted
  with: ``` `biv_student()` is implemented only for `engine = "tmb"`; the Julia
  route is deferred. ```
* `drm_julia_family_tag("biv_student")` aborted with ``` `engine = "julia"`
  currently supports Workflow G fixed-effect families (Gaussian, bivariate
  Gaussian, Student-t, lognormal, Poisson, NB2, Gamma, Beta, Binomial) and
  large-p phylogenetic Poisson, NB2, Gamma, Beta, or Binomial models. ```

The control in the same session: the identical call on `engine = "tmb"` FITTED,
`logLik = -273.1043807510`. So the refusal was about the route, not a
malformed call.

## 4. What changed

* `R/julia-family-registry.R` -- ONE row, `spec("biv_student", fe = TRUE)`.
* `R/drmTMB.R` -- retired the family-specific `engine = "julia"` abort, which
  fired before the registry was ever consulted. Without this the registry row
  alone could not admit the family.
* `R/julia-bridge.R` -- (i) a `biv_student` branch in
  `drm_julia_bridge_default_dpar_labels()` defaulting `sigma1`, `sigma2`,
  **`nu`**, `rho12`; (ii) `drm_julia_refuse_biv_student_beyond_native()` and
  its intercept-only predicate, plus the call site; (iii) a `biv_student`
  guard at the head of `confint.drmTMB_julia()`; (iv) the `fe_biv_student`
  capability row.
* `tests/testthat/test-julia-family-biv_student.R` -- new focused-test limb.
* `tests/testthat/test-julia-family-registry.R` -- the two pins this one row
  moves; no pin deleted.
* `tests/testthat/test-biv-student.R` -- retired a stale expectation that
  pinned the removed abort (see section 6).
* `inst/extdata/julia-capabilities.tsv`, `docs/dev-log/dashboard/julia-capabilities.tsv`
  -- REGENERATED via `Rscript tools/write-julia-capability-comparison.R`.
* `docs/design/258-coefficient-naming-contract.md` (section 8.10), `NEWS.md`.

## 5. Receipts (all measured this run)

Same draw throughout: `tests/testthat/test-biv-student.R`'s own
`simulate_biv_student_truth`, n = 400, seed 6401, `beta1 = c(0.2, 0.45)`,
`beta2 = c(-0.3, -0.25)`, `sigma1 = 0.55`, `sigma2 = 0.85`, `nu = 7`,
`rho12 = 0.35`. Comparator code from the pin's own tools.

| axis | result |
| --- | --- |
| coefficients (`parity_numeric`, tol 1e-4) | `PARITY_PASS`, max abs diff `3.77097286063943e-07`, 8/8 matched by name |
| logLik | `-928.707976349488` (tmb) vs `-928.707976349514` (julia), diff `2.56932253250852e-11` |
| Wald SE (`parity_se.R`, rtol 1e-3) | `SE_PASS`, `2.04553020577425e-07` abs / `9.01334041867385e-07` rel over 8 SEs |
| negative control (`se_julia[1] * 1.10`) | `NEGATIVE_CONTROL_OK`, rel `0.0909089730666066` |

`drmtmb_code_hash 49985ec0eb413191a86c40a9c74d3a4d0c245c095bf58a91e749c1763aa5c8d6`.
Rows banked in the pin clone's `docs/dev-log/evidence/parity-fixtures.tsv`
(`fe_biv_student`) and `parity-se.tsv` (`se_biv_student`,
`negative_control_perturbed_biv_student`).

Focused test: `FAIL 0 SKIP 0 PASS 54` with `NOT_CRAN=true` and the live engine
(its live block is a hard failure, never a skip, on a refusal or a DRM.jl
abort).

## 6. Three defects the admission itself created, found and fixed

Admitting `fe = TRUE` widened the REACHABLE surface, because the A4.G17
fixed-effect fence exempts every `biv_*` tag by prefix. All measured on this
branch, through `drmTMB(..., family = biv_student(), engine = "julia")`,
before the fixes:

1. **Shapes native TMB refuses were fitted.** `sigma1 = ~ z`, `rho12 = ~ z`,
   `nu = ~ z` and `sigma1 = ~ 0 + z` each returned a converged fit while
   `engine = "tmb"` refused them ("currently allows fixed-effect `mu1`/`mu2`
   only, with intercept-only `sigma1`, `sigma2`, shared `nu`, and `rho12`").
   A shape the native engine refuses has no same-target comparator, so it can
   carry no parity receipt.
2. **An ordinary `(1 | g)` bar leaked a raw Julia stack trace** from
   `_split_bivariate_q4_rhs` naming the q=4 structured route -- a refusal, but
   an opaque one pointing at the wrong thing.
3. **`confint()` returned a 10-row Wald table** on the Julia route while the
   native route refused it outright (`R/profile.R`: "interval and profile
   claims are deferred"; `R/family.R` documents that interval inference is
   deferred for this family). SE agreement at rtol 1e-3 is not an
   interval-coverage claim and cannot stand in for one.

Fixed by `drm_julia_refuse_biv_student_beyond_native()` (1 and 2, refusing
before Julia is started, with the native wording) and the `biv_student` guard
in `confint.drmTMB_julia()` (3). `phylo()` and
`relmat()`/`animal()`/`spatial()` were already refused upstream with their own
pinned messages and are deliberately left to them.

The stale expectation in `tests/testthat/test-biv-student.R` was also unsound
independently of this leaf: it asserted `expect_error(drmTMB(..., engine =
"julia"), "engine")`, and with no Julia engine on the machine the call errored
for an unrelated reason and still matched `"engine"` -- so it passed green in
exactly the configuration that could not test the claim. It only turned red
once the engine was actually present.

## 7. Red controls (planted, measured, restored byte-identically)

Baseline `FAIL 0 SKIP 0 PASS 54 ERROR 0`.

| planted defect | focused test |
| --- | --- |
| registry row `spec("biv_student", fe = TRUE)` deleted | `FAIL 1 SKIP 0 PASS 11 ERROR 4` |
| `"nu"` dropped from the `biv_student` default-label branch | `FAIL 1 SKIP 0 PASS 34 ERROR 1` |
| `drm_julia_refuse_biv_student_beyond_native()` call site removed | `FAIL 0 SKIP 0 PASS 46 ERROR 1` |
| `confint.drmTMB_julia()` `biv_student` guard removed | `FAIL 1 SKIP 0 PASS 53 ERROR 0` |

Each file was restored with `git show HEAD:<path> > <path>`; sha256 before and
after match for both touched files, and `git status --porcelain` afterwards
shows only the untracked scratch directory. Final state re-measured:
`FAIL 0 SKIP 0 PASS 54 ERROR 0`.

## 8. What this does NOT cover

* No interval-coverage claim. `confint()` is refused for this family on both
  engines; `profile()` and `predict_parameters()` have no Julia-engine method
  at all. Bridge-side profile/bootstrap inference (G3) remains unqualified for
  every bivariate fit.
* One fixture, one seed, one n. No recovery or coverage simulation.
* No random-effect, `phylo()`, `relmat()`/`animal()`/`spatial()`, REML,
  `weights`, `meta_V()`, offset or missing-response route for this family on
  either engine -- all refused, and the refusals are now measured to agree
  across engines.
* `nu` is structurally shared across the two margins; per-margin tail
  heaviness is not available on either engine, by construction.
* Pre-existing and unrelated: `tests/testthat/test-parity-matrix.R`'s
  "regenerates byte-identically" test errors at this pin with `citation anchor
  not found in docs/design/capability-status.md: Gaussian phylogenetic random
  intercept + slope, two SDs (mean)`. That anchor is a hardcoded `st(...)`
  line in `tools/write-parity-matrix.R` (untouched here) pointing at a DRM.jl
  document that does not contain the string at `430ef64cc`; `grep -c "two SDs"`
  on that file returns `0`. Nothing in this leaf's diff is reachable from it.
