# A8b RED baseline and RED CONTROLS -- biv_gaussian_residual

Two kinds of negative evidence for leaf A8b, both measured, not asserted.

1. The **RED baseline** (G1): what the route did BEFORE any change, on the
   DRM.jl pin `430ef64cc`.
2. The **RED controls** (G6): each positive gate re-run with the change backed
   out, showing it FAILS, then the source restored byte-identically.

## 1. RED baseline (G1)

Measured 2026-09-05, `wt-a8b` at `origin/main` (`3714cc80e`), DRM.jl pin
`/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc`, one Julia
session, `threads = FALSE`. Fixture `gaussian-bivariate-rho12` (n = 180),
`bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)`,
`family = biv_gaussian()`. Both engines converged.

### `profile_targets()` on the `engine = "julia"` fit -- 9 rows, ALL not ready

```
                      parm         target_class   dpar        term profile_ready          profile_note
1    fixef:mu1:(Intercept)         fixed-effect    mu1 (Intercept)         FALSE missing_tmb_parameter
2              fixef:mu1:x         fixed-effect    mu1           x         FALSE missing_tmb_parameter
3    fixef:mu2:(Intercept)         fixed-effect    mu2 (Intercept)         FALSE missing_tmb_parameter
4              fixef:mu2:x         fixed-effect    mu2           x         FALSE missing_tmb_parameter
5  fixef:rho12:(Intercept)         fixed-effect  rho12 (Intercept)         FALSE missing_tmb_parameter
6 fixef:sigma1:(Intercept)         fixed-effect sigma1 (Intercept)         FALSE missing_tmb_parameter
7 fixef:sigma2:(Intercept)         fixed-effect sigma2 (Intercept)         FALSE missing_tmb_parameter
8                   sigma1 distributional-scale sigma1  (constant)         FALSE missing_tmb_parameter
9                   sigma2 distributional-scale sigma2  (constant)         FALSE missing_tmb_parameter
```

`all(!targets$profile_ready)` = `TRUE`.

### `confint()` -- refused R-side, before any Julia call

`confint(fit_julia, parm = "fixef:mu1:x", method = "profile")`, verbatim:

```
Julia-engine target "fixef:mu1:x" is not ready for profile or bootstrap
intervals.
i Inventory note: "missing_tmb_parameter".
```

`method = "bootstrap"` on the same `parm`: byte-identical message.

`confint(fit_julia, parm = "fixef:rho12:(Intercept)", method = "profile")`,
verbatim:

```
Julia-engine target "fixef:rho12:(Intercept)" is not ready for profile
or bootstrap intervals.
i Inventory note: "missing_tmb_parameter".
```

`method = "bootstrap"` on that `parm`: byte-identical message.

### The comparator existed all along

The SAME model fitted with `engine = "tmb"` listed 10 targets, all
`profile_ready = TRUE`, and profiled both compared targets without complaint:
`fixef:mu1:x` -> `[0.1988954, 0.4607054]`, `fixef:rho12:(Intercept)` ->
`[0.204977, 0.497659]`. The gap was on the bridge, not in the model.

### And on the Julia side

Through the real R shim (`drm_julia_call_fixef_inference`) against the pin,
`method = "bootstrap"` reached DRM.jl and threw:

```
ArgumentError: fit-based bootstrap requires a univariate `DrmFit` created by
`drm`; bivariate and formula-less internal fits are not yet supported
```

## 2. RED CONTROL (b) -- drmTMB: readiness change reverted

RE-MEASURED 2026-09-05 against the shipped file (the earlier committed hashes
here matched neither the shipped file nor `origin/main` and are replaced
below with what was actually measured). The one changed expression in
`drm_julia_wald_targets()` was replaced with the pre-A8b rule
(`fixef_profile_ready <- !is_biv && !is.null(object$bridge_payload)`) and
`tests/testthat/test-julia-biv-inference.R` re-run WITHOUT the live env
(`DRMTMB_JULIA_TESTS`, `DRM_JL_PATH`, `DRM_JL_PHYLO_PATH` all unset), so the
one live block is expected to SKIP rather than run, not fail or error.

```
R_SHA_BEFORE = ede62299f1044ba93ce443a20b9df0e82b2166bc64ae6484d309558d15884c0c
planted      = 125e8e1df23deccdd993f5fa2b46c957cc6a17ac29740d170c593813fb1c2ec3
```

Result with the pre-A8b rule in place, offline: **2 failures and 2 errors**
across the file (19 expectations pass, 1 block skipped for the missing live
env):

| testthat block | expectations reached | failed | errored |
|---|---|---|---|
| residual bivariate fit reports every fixed-effect target as profile-ready | 5 | 2 | no |
| bivariate fit carrying a covariance provider stays not-ready | 6 | 0 | no |
| bivariate fit with no bridge payload is still refused | 2 | 0 | no |
| residual bivariate route contributes no duplicate SD rows | 4 | 0 | **yes** |
| target validator still refuses what the engine cannot profile | 4 | 0 | no |
| confint() routes to the Julia fixef entry point | 0 | 0 | **yes** |
| live: profiles and bootstraps the residual bivariate fixed effects | 0 | 0 | no (SKIPPED: DRM.jl engine not available) |

For contrast, the SAME file with the shipped (post-A8b) rule in place and the
SAME offline environment (no live env) reaches 37 passed expectations, 0
failures, 0 errors, and the same one block skipped; with the live env set (as
in the qualification run) it reaches 57 passed expectations, 0 failures, 0
errors, 0 skipped -- the "57 expectations pass ... 0 failures" claim already
in this document was correct, it was only the hash pair above and the
"3 failures and 3 errors" planted-rule tally that were wrong.

```
R_SHA_AFTER  = ede62299f1044ba93ce443a20b9df0e82b2166bc64ae6484d309558d15884c0c   (restored byte-identically; confirmed equal to R_SHA_BEFORE)
```

## 3. RED CONTROL -- DRM.jl: source change reverted

`src/inference.jl` was replaced with its parent-commit content and
`test/test_bridge_biv_inference.jl` re-run.

```
JL_SHA_BEFORE = 41e008bda2bcd2afd5904feb7698fe75a7bfa93eb6a006c426badd2a925ca6d8
reverted      = 3b2ac17b2b1acd03ff3359bc588d924d424f5ba5e78894a0d26d9abe90e1c589
```

The bootstrap testset errors with exactly the baseline message:

```
Got exception outside of a @test
ArgumentError: fit-based bootstrap requires a univariate `DrmFit` created by
`drm`; bivariate and formula-less internal fits are not yet supported
```

The PROFILE testset still passes 27/27 with the source reverted -- which is the
positive finding the scout predicted and this control confirms: **profile
needed no DRM.jl change at all**; only bootstrap did.

```
JL_SHA_AFTER  = 41e008bda2bcd2afd5904feb7698fe75a7bfa93eb6a006c426badd2a925ca6d8   (restored byte-identically)
```

## 4. RED CONTROL (a) -- profile tolerance tightened to 1e-9

Recorded in `a8b-biv-qualification-receipt.md`. Both compared targets FAIL at
1e-9 (deltas 2.15e-06 and 6.45e-06), so the 1e-4 comparison is live rather
than vacuous. `tol_red` is a script parameter, not committed state, so nothing
was edited and nothing needed restoring.
