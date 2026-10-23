# After task: win-builder Julia hang after #1061

**Reader:** Shinichi / next Cursor. **Purpose:** record why the post-#1061
julia-skip tarball (`8764b2fe…`) still hung on Ligges R-release and what fixed it.

## Root cause (3 sentences)

The #1061 `^julia` invert filter correctly kept `test-julia-*.R` off the CRAN
lane — confirmed in hung `testthat.Rout` from
[`v57uv6zakfKO`](https://win-builder.r-project.org/v57uv6zakfKO/), which still
shows the `^julia` filter before the hang. It did not stop
`test-binomial-response.R`, which still called `drmTMB(..., engine = "julia")`
inside `expect_error()` after a probit fit printed `<summary.drmTMB>`. Workflow
G admits fixed-effect binomial into the Julia bridge, so that call entered
`JuliaCall::julia_setup()` and hung win-builder for ~10448s at "Loading setup
script for JuliaCall..." (Julia 1.11.3 on the host).

## Fix

1. `drm_julia_cran_lane_blocked()` + hard abort in `drm_julia_setup()` on the
   non-interactive CRAN lane unless `DRMTMB_JULIA_TESTS=true`.
2. Harden `drm_skip_live_julia()` to the same predicate (plus `skip_on_cran()`).
3. Replace the obsolete binomial `expect_error(engine = "julia")` with a pure-R
   `drm_julia_family_tag("binomial")` check.
4. Expand `test-cran-lane-filter.R` to prove filter + blocked predicate.

## Explicit non-claims

No `submit_cran`. No Ligges email. No #1033. `platform-clean` not advanced.
