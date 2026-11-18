# D-43 Julia completion panel: fixed priors with Gaussian mean random intercept

Date: 2026-11-06
Reviewer: build reviewer 2, fresh Luna medium requested (actual runtime routing is not independently observable from this shell; treat as requested, not verified).
Scope: read-only audit of the Julia API, tests, docs, and license boundary at `DRM.jl` HEAD `ff10a2f9adb23c0e315d50e8c2094d6d27ed1d82` against base `86ee1c2a38cd79c55dbbd71afd7374a3095aad3c`. No tests/fits, edits, or GitHub actions were run here. Current full Julia suite remains live/pending under the coordinator's qualification run.

## Verdict

The current Julia interface, tests, and documentation are coherent for the narrow route: Gaussian ML with normal/ridge priors on fixed `mu`/`sigma` coefficients, one independent mean random intercept integrated by the default exact Gaussian route, and an unpenalized random-intercept SD. The objective adds the coefficient prior once outside the integrated random-effect likelihood; active priors label the fit MAP while preserving the data log-likelihood separately. Zero-precision ridge remains the ML case.

I found no newly reachable fixed-prior MAP confidence interval or p-value endpoint admitted as calibrated on the audited public paths. One gap in the earlier review history is visibly addressed at this head: the shared variance-ratio emitter now refuses MAP intervals, and the new regression test checks `heritability`, `icc`, and `repeatability` for both `:delta` and `:profile`. This is source/test evidence only; it does not establish interval calibration. Runtime and whole-suite qualification remain pending.

## Source facts and exact spans

- Prior constructors/resolution: `src/fixed_priors.jl:12-24,27-37,42-68`. Normal priors include the density constant; ridge adds `lambda * beta^2 / 2`; zero lambda carries zero precision and zero constant. Resolver rejects empty/overlapping selections and expands named columns.
- Metadata / estimator classification: `src/gaussian_core.jl:457-469`. Active prior wraps the fit as `:MAP`, keeps `data_nll` metadata and prior specs, and retains the fitted data loglik; all-zero ridge remains `:ML`.
- Integrated Gaussian random-intercept path: `src/gaussian_ranef.jl:622-699,833-838`. The existing Woodbury marginal ML objective is used, with `_fixed_prior_value` added once outside it; REML is not used when priors are present. Group SD parameter remains part of the likelihood parameter vector, with no prior row added for it. `src/gaussian_ranef.jl:1733-1739` rejects explicit `marginal=:Laplace` for this mean-RE route and states the exact supported route.
- Public docs: `docs/src/priors.md:1-74`. The examples show the ordinary and one-mean-intercept Gaussian routes; supported and refused cases are enumerated; active MAP likelihood/objective distinction and local-curvature caveat are described. Docs explicitly say likelihood-ratio tests, AIC/BIC, CIs, profiles, and bootstrap refits are refused, and that prediction SE/simulation are not qualified.
- Native regression tests: `test/test_fixed_priors_gaussian_ranef.jl:3-78` checks exact prior addition to objective, gradient/Hessian decomposition, data loglik, route refusals, coefficients/ranef, update, and zero-ridge/empty-prior identity. `:Laplace`, REML, VA, missingness, non-unit/unsupported controls, and structured random effects are covered as refusals. Lines 80-95 cover real-factor name resolution and fit behavior.
- Ratio regression tests: `test/test_fixed_priors_variance_ratios.jl:3-29` checks both interval methods for all three public accessors and proves zero-ridge estimates remain equal to unpenalized estimates. Lines 31-42 ensure other MAP penalties keep their existing ratio status.
- Ratio guard: `src/heritability.jl:593-613` rejects active fixed-prior MAP fits before either `:delta` or `:profile` ratio interval can be returned.
- Wald summaries: `src/summary.jl:316-356,358-379` documents and implements NaN/withholding for z, p, and interval columns on fixed-prior MAP fits. SE remains displayed as local penalized curvature, consistent with docs.
- Likelihood profiles: `src/inference.jl:223-246,302-...` rejects active fixed-prior MAP `confint` before method dispatch and `profile_result` has its own guard (graft span `src/inference.jl:331-425`). `src/introspection.jl:38-79` marks profile targets unavailable. `src/visualization.jl:35-96,118-199` guards `profile_curve` and `parameter_surface`.
- Other inference routes: bootstrap refits reject fixed-prior MAP at `src/inference.jl:2243-2245`; prediction SE, simulation, and bias-corrected intervals have explicit MAP guards (`src/gaussian_core.jl:2437-2438,2739-2741,3062-3065`; `src/bias_correct.jl:97-102`). Model comparison has `_map_compare_guard` at `src/comparison.jl:244-251`, called by `lrt_boundary` at `src/chibar.jl:166-176`. AIC/BIC refuse at `src/gaussian_core.jl:3496-3502,3512-3518`.
- Bridge: `src/bridge.jl:743-791` resolves public prior coordinates against Julia design columns and checks them against `prior_expected`; it only transports the numeric design route. Raw factor frontend parity is not established and must not be claimed.
- License: the audited slice adds Julia source/tests/docs/news/adapter only; the adapter at `tools/gaussian-ri-prior-adapters/julia-native.jl:1-67` is fresh Julia numerical transport code. No drmTMB R implementation/source was added in this diff. Repository `LICENSE` remains MIT. The existence of `drmTMB`-generated frozen numerical references is not vendored GPL source.

## Limits / pending

- This is a source and test audit, not an execution receipt. Do not report the current full Julia suite as complete until the coordinator's live run returns.
- Existing full-suite and oracle history belongs to its recorded earlier source heads; it does not qualify the current `ff10a2f` head. No interval calibration is implied.
- The docs do not claim Gaussian fixed-prior interval validity. Local inverse-Hessian curvature is exposed as curvature, with Wald tests/intervals withheld.
- The R bridge adapter tests coordinate transport, not an R-native factor formula frontend. Keep the raw-factor refusal and no parity claim.
- `lane_preflight.sh` could not be used in this environment: the script exits with a Python `SyntaxError` at its shell `case` arm. Route lookup also found no worktree LOAD-FIRST manifest. These operational issues do not alter the source verdict.

## Coordination note

Checkout status at review: branch `codex/gaussian-ri-priors-20261106`, exact requested HEAD, ahead 4 of `origin/main`; only `.claude/settings.json` and `.cursor/hooks.json` are dirty and were left untouched. No merge, release, commit, or GitHub post was made.

🌱 graft saved ~3,802,420 tokens this turn (graph estimates against full-file baselines; not measured token or cost savings).
