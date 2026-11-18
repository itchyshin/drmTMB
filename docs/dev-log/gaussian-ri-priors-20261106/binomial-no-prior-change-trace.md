# Unpenalized binomial regression trace

Conclusion: I found no source-level semantic change from base `86ee1c2a38cd79c55dbbd71afd7374a3095aad3c` to engine `ff10a2f9adb23c0e315d50e8c2094d6d27ed1d82` that changes this fixture's mathematical objective, optimizer inputs/settings, data/SD design or convergence predicate. This conclusion assumes the same supplied data and runtime state. It does not prove bitwise execution equivalence or classify the hosted failure as a baseline defect.

Independent Codex, 7 November 2026 UTC. Read-only source trace; no fits, tests, agents or GitHub writes. Source paths refer to `/Users/z3437171/.codex/worktrees/drmodels-fixed-priors-20261105/DRM.jl` at engine `ff10a2f9`. The earlier runtime qualification review is unchanged.

## Actual fit path

The fixture creates a fresh local `MersenneTwister(2026101717)`, 28 groups with eight observations and 12 trials, then stores successes/failures and predictors (`test/test_binomial_sd_public.jl:5-16`). Lines 89-92 build `cbind(successes, failures) ~ x + (0 + x | g)` with `sd(g, coef(x)) ~ z`, call `drm(..., Binomial(); data)` without priors/control/weights, and test `.converged`.

`@drm_entry` wraps the Binomial method at `src/binomial.jl:227-229`; its unchanged macro/control scope is at `src/control.jl:511-543,301-319`. `_drm_binomial_fit` defaults to `g_tol=1e-8`, `se=true`, `marginal=:LA`, `method=nothing`, `nq=5` and `priors=nothing` (`src/binomial.jl:239-244,431`). The existing prior guard is skipped, then the SD formula dispatches to `_drm_binomial_sd_regression` before the fixed-effect prior resolver (`245-262`).

The SD router identifies one IID independent slope and its explicit coefficient target (`src/binomial_sd_regression.jl:1955-2019`). With one group it skips the crossed-effects branch (`2030`). It builds the response and fixed mean design, group index, slope loading from `data.x`, and group-level SD design from the selected `z` formula (`2095-2137`), then calls `_fit_binomial_sd_regression` (`2143-2146`). Shared `_design` is in `src/gaussian_core.jl:613-677`, `_group_index` is in `src/gaussian_ranef.jl:307-322`, and `_sd_group_design` is in `src/gaussian_lss.jl:104-125`; these shared helpers were checked, rather than excluded by filename.

The objective remains negative summed group adaptive Gaussian quadrature of the binomial likelihood, with group SD mapped through the existing soft-clamped exponential (`src/binomial_sd_regression.jl:68,2187-2208`). Initial coefficients and SD starts remain at `2209-2219`. `_optimize_with_fallback` still uses a finite-sentinel wrapper, forward AD, L-BFGS and `Optim.Options(g_tol=g_tol)`, retrying with BackTracking only after an `AssertionError` (`src/binomial.jl:27-47`). No new optimizer control is passed to this route.

The fit passes `drm_optim_converged(res)` into `DrmFit` (`src/binomial_sd_regression.jl:2262-2264`). That predicate is still `Optim.converged(res) && Optim.g_converged(res)` (`src/optim_minimum_guard.jl:71`). The shared constructor then applies the unchanged finite/sentinel check `_report_converged` (`src/gaussian_core.jl:285-302`; `src/finite_inputs.jl:194-198`). `_withnll`, `_withiterations`, `_withformula` and `_withuncertainty` preserve that flag (`src/gaussian_core.jl:367-377,483-501`). No changed code assigns or overrides it on this path.

## Exhaustive changed-source check

The complete engine diff changes exactly six `src/` files:

| Changed code | Reachability for this fit |
| --- | --- |
| `gaussian_core.jl:1066-1072,1114-1118` | All changed executable lines belong to the Gaussian-dispatched `_drm_gaussian_fit(..., fam::Gaussian)` (`1011`). The Binomial call uses the separate method traced above. The new admission/complete-response checks and RI dispatch are also gated by `priors !== nothing`. Shared formula/design/fit constructors elsewhere in this file are unchanged. |
| `gaussian_ranef.jl:622-623,698,832-834` | Adds optional prior rows to `_fit_ranef_gaussian(fam::Gaussian, ...)`; Binomial's SD fitter does not call it. The shared group index remains unchanged. |
| `fixed_priors.jl:90-117` | Changes explicit `resolve_priors`, which this no-prior native call does not invoke. |
| `bridge.jl:752` | Changes `_bridge_prepare_fixed_priors`; this native call does not enter the bridge. Earlier bridge calls in this test omit priors, so the preparation function is skipped by the unchanged gate at `bridge.jl:76-80`. |
| `introspection.jl:45-48` | Adds a prior-MAP check to `profile_targets`; it does not fit or set convergence. For an ordinary no-prior fit the unchanged `_is_fixed_prior_fit` predicate is false (`gaussian_core.jl:457`), so the existing readiness branch remains. |
| `heritability.jl:595-596` | Adds an active-prior MAP interval refusal in `_emit_ratio`, outside this fitting path; remaining changes are docstrings. |

`git diff --exit-code BASE ENGINE --` returned zero for the entire fixture, Binomial router/fitter, control machinery, finite-result guard, optimizer guard, SD-design helper, quadrature implementation, input validation, module loader, test harness, Project and Manifest. Byte comparisons also confirmed unchanged shared spans: `gaussian_core.jl:123-217,227-370,374-377,483-501,613-677` and `gaussian_ranef.jl:307-322`. Engine source/tests remain unchanged in the current working tree. The added prior test files do not change the fixture source or its explicit seed; this trace does not certify every possible suite-state interaction.

## Runtime limit

The six paired local Julia 1.13.3 checks pass on both sources; hosted candidate CI still has the 43/44 result at `slope_fit.converged`, and the hosted baseline comparison remains unresolved in the coordinator's current evidence. Identical source semantics do not establish which convergence condition failed in that hosted process. Compiler specialization, dependency/runtime differences, floating-point effects or suite state are possible investigation areas, with no causal evidence supplied by this trace. Preserve the runtime failure and require its hosted comparison/adjudication; no threshold relaxation or baseline-failure label follows from this report.
