# After task: first fixed-effect prior slice

## 1. Goal

Help applied users regularize separation and unstable fixed coefficients in drmTMB and DRModels.jl, with explicit distributional-parameter, coefficient and intercept selection. Shinichi approved implementation and isolated overlap on 5 November 2026. Merge, release and publication remain unauthorized.

## 2. Implemented

The R package now has normal/ridge constructors, a preview resolver, compiled objective contributions, separate likelihood/prior reporting, local-curvature labels and guards against unsupported inference. Gaussian mu/sigma and binomial-logit mu are the first admitted fixed-effect blocks. The Julia twin has independently written constructors, resolver and native fitting support, plus bridge metadata and corresponding guards. No random-effect SD prior or sampler was added.

## 3. Mathematical Contract

For each selected coefficient, Normal(m,s) adds `0.5*((beta-m)/s)^2 + log(s) + 0.5*log(2*pi)`. Ridge adds `0.5*lambda*beta^2`, omitting the normal density constant. The normal prior is on the regression coefficient of the chosen link predictor, with no additional coefficient-link Jacobian. Gaussian sigma coefficients are on log SD. Zero ridge adds nothing and retains ML controls and diagnostics. Active priors produce penalized/MAP estimates and local curvature; no full posterior or calibrated interval claim is made.

## 3a. Decisions and Rejected Alternatives

Use exact final-matrix coefficient selection, require an intercept policy for whole-block selectors, and keep priors out of formula grammar. Include normal density constants but retain the conventional constant-free ridge objective. Preserve zero-strength ML behaviour and fail closed on unsupported priors. Keep the existing phylogenetic penalty interface unchanged. Generic SD priors, posterior sampling and wider family admission remain separate stages. Julia code was written from the equations; GPL R/C++ source was not copied into its MIT source.

## 4. Files Touched

R code: `R/fixed-effect-priors.R`, `R/fixed-priors-workflow.R`, the fit entry/spec, compiled TMB template, bridge, summary/diagnostic and inference entry points. Tests: `test-fixed-effect-priors.R` and `test-fixed-priors-workflow.R`. Documentation: roxygen/man, pkgdown navigation, the prior article, a design note and a news fragment. Proposal, source manifests, receipts and this checkpoint live under `docs/dev-log/priors-lane-20261105/`. Julia changes and its own report remain in the separate DRModels.jl worktree.

Unrelated `.claude/settings.json` and `.cursor/hooks.json` edits were already present in this checkout and must remain unstaged. This lane did not edit the original dirty checkouts or PR #1651's worktree. The main check log has only a new pointer section; existing receipt entries and NEWS were left unchanged, with detailed evidence and news in new fragments.

## 5. Checks Run

Closeout R source aggregate SHA-256: `6495656050f6f5a958c0151bad8730c124dbff55aea6fa39e5d133f01596da5c`. Local and remote manifests match all 76 covered source/test files. The candidate compiled with the standard optimized compiler flags on Totoro. New focused tests pass; the 10-file affected suite passes, with two explicitly recorded live-engine skips. Final Julia source aggregate SHA-256: `a30e347285f925af2e128ed6350fafe4d6b9035668444606bfa2fcea13e26653`. Its focused suite passes 82 checks and its 14-file affected suite passes.

Five live bridge fixtures pass coefficient, data-likelihood, prior, total-objective, prior-gradient, selector and inference-guard comparisons. Maximum coefficient gap is 4.30e-11 and maximum data-likelihood gap 1.07e-12. These measurements concern the named fixtures only. Tutorial code executes; rendered R HTML and an isolated Julia prior page exist. Pkgdown configuration checks pass. The refreshed R package check on the closeout source completed with zero errors and two warnings from omitted vignette outputs in the intentionally unbuilt-vignette archive; examples and usage checks passed.

The full R run on predecessor source `c53a03570e8263f8c75e2c95929d03f069b3c97d0694fed8cab5e7113cfbc28f` finished in 3,433 seconds with failures. It exposed the API and fixture omissions described below. Those checks pass after correction. The registry-path mismatch and both parallel bootstrap endpoint differences reproduce exactly on baseline `9fea3036791e9bd836e080d9297cd04b1b29c2f8` with the same optimized compiler and installed-test configuration. The differences are about 2e-13; existing identical-value assertions were retained.

The final full Julia run reached its 90-minute limit and exited 124. It is incomplete, not a pass. Its source remains a30e3472 and the process group has no remaining members. The retained output contains passing partial summaries but cannot establish the unrun remainder. No full-suite success is claimed.

## 6. Tests of the Tests

Tests failed first for missing constructors/request guards. Independent densities, analytic prior gradients/Hessians and central differences check the compiled objective at a common parameter vector. Same-named mu/sigma columns receive different priors to expose wrong-block mapping. Intercept omission, density constants and the factor of one half in ridge have separate assertions. The Gaussian conditional ridge solution is checked at 1e-7; objective checks use 1e-10; scaled finite-difference gradient and Hessian checks use 1e-6 and 1e-5. No tolerance was relaxed. A standalone negative-control harness accepts the unchanged compiled target and rejects all six deliberately altered observations: dropped sigma contribution, penalized excluded intercept, wrong ridge factor, missing prior gradient, duplicated penalty and dropped rebuild metadata. These are oracle sensitivity checks using corrupted observations, not six rebuilt source mutants.

Real factor/interaction and no-intercept fits test final-column selection. Aliased selected and unselected blocks fail; preview and fit use the same rank check. Zero ridge is compared with ordinary ML controls, objective, prediction and geometry as applicable. Update retains priors unless an explicit Julia estimator switch asks for ML. These are numerical and regression checks, not interval-coverage experiments.

## 8. Consistency Audit

Noether's math review and an independent integration review returned scoped READY after their reported issues were fixed. Pat found no remaining reader-blocking issue after interpretation and recovery guidance were added. The last Julia prose/code alignment suggestion was incorporated. Examples are explicitly teaching data. They explain both the logit and log-SD coefficient scales and avoid interpreting local curvature as sampling covariance.

No family, formula grammar or likelihood parameterization changed. Existing phylogenetic penalties and MSPL remain separate. No existing parity ledger row or signed tolerance was promoted or weakened. The R and Julia source hashes above identify snapshots, not the repositories' baseline Git HEADs.

## 9. What Did Not Go Smoothly

The first source archive contained macOS metadata sidecars, which Linux tried to compile. A metadata-free archive in a fresh directory corrected that staging error. A staged R-only `--no-libs` reinstall omitted the shared object; a normal cached-object installation corrected it. Initial admission guards encountered the default log-sigma clamp only after control parsing; defaults now use the unclamped target for active priors, while explicit clamps refuse. Zero ridge preserves ordinary controls.

A live JuliaCall startup crashed before model code. The existing PR #1565 documented the launch-only bundled-libunwind workaround; the retry passed without importing or editing that PR. The remote archive initially lacked Git metadata, causing a source-only audit to stop before its intended assertion. Exact-baseline Git metadata restored the premise without changing source bytes, and that audit passed on rerun. Predecessor full runs were stopped only after final-source runs were active; their partial logs remain distinct.

Review copies of captured output trim trailing horizontal whitespace and empty lines at EOF only. The normalization receipt records raw and review-copy hashes; raw logs remain on Totoro. The compile-log excerpt retains the compiler, optimized flags and installation result, with the full raw log separately identified.

A full Julia docs build failed on a joint-missing-data convergence assertion. The same example failed on clean main with the same Julia version and byte-identical docs dependency manifest. That existing example was left unchanged. The new prior page was checked independently.

## 11. Team Learning

The full R run also exposed three integration omissions. Putting `priors` before `...` changed the handling of unnamed arguments, so it is now named-only after `...`. Raw TMB phylogeny fixtures needed the five new empty prior vectors. The cheatsheet and reader-contract manifest needed the four exports and one article. The corrected unused-argument, export, reader-contract and 22-test phylogeny modules pass. A fresh scoped integration review accepted these corrections. No tolerance changed.

Fresh reviews exposed inference escapes through summary tables and profile helpers, zero-strength changes to ML diagnostics, estimator-switch retention and preview/fit rank disagreement. Tests now cover those paths. The practical lesson is to check the user-visible inference and rebuild surface, not just the optimizer objective. Final-source manifests and separate predecessor logs prevent later guard fixes from inheriting earlier validation claims.

The managed worktree tools supplied the isolated lanes. The generic launcher was not used to create a second checkout or alter Claude permissions. No agent configuration improvement is included in the feature commit.

## Documentation Updates

The new design note states equations, coefficient scales, selector semantics, inference limits and the compute envelope. R roxygen documentation and aliases were generated; unrelated regeneration changes were removed. The article has a continuous-exposure question, dynamically computed coefficient interpretations and exact-column recovery instructions. Pkgdown reference and article indexes include the new feature. No deployed site was changed.

## 7a. Issue Ledger

Bounded open-issue searches found no matching general fixed-coefficient-prior issue. No new issue, comment, draft PR, push, merge or release was created. Existing cleanup, documentation and inference PRs were inspected for overlap; Shinichi authorized isolated prior-only changes. Their branches and working changes were preserved.

## 10. Known Residuals

This is a bounded fixed-effect slice. It does not admit other families, random effects, missing-data models, nonunit weights, REML/MSPL combinations, SD priors or posterior sampling. Partial priors do not guarantee a finite optimum in every unpenalized separating direction. The local Hessian is not a calibration study. The live bridge requires the documented host workaround in the tested environment. The full-site Julia docs failure is an existing example/environment limitation.

Current state: the approved fixed-effect slice is implemented and its bounded acceptance checks are complete. The full Julia suite remains incomplete at its declared limit; no full-suite success is claimed. Local implementation checkpoints are R `5aea077bf` and Julia `07b25dc4f2ecb3a1f01ea322ffb0eb64c6584338`; a separate evidence commit records this closeout. No push, merge or release occurred. Read `docs/dev-log/priors-lane-20261105/EXECUTION.md` before resuming after a context boundary.


## 12. Cross-Product Coverage

This slice covers fixed-effect Gaussian identity-link mu and log-link sigma, and binomial-logit mu, with complete model variables, implicit/unit weights and dense full-rank designs. Normal and ridge selectors cover exact columns and explicit intercept inclusion/exclusion, including named factor interactions and no-intercept factor columns. Native TMB, native Julia and the R-to-Julia bridge have independent or same-target fixture checks as recorded above. Zero ridge is checked separately from active MAP requests.

Downstream checks cover objective/gradient/Hessian contributions, local covariance interpretation, likelihood-only reporting, point predictions, preview, update retention/estimator switching, summary/coeftable display and refusal of unsupported intervals or likelihood comparisons. Empty prior data vectors exercise the no-prior TMB path; affected regression suites check ordinary Gaussian/binomial and existing inference/bridge behaviour.

The slice does NOT cover bivariate prior blocks, other response families or links, random effects or SD regressions, covariance-provider priors, missing-data engines, nonunit weights, sparse/aggregated prior fits, REML, MSPL, combinations with phylogenetic penalties, generic SD priors, tmbstan, posterior predictive simulation, calibrated intervals, a recovery campaign, all possible contrast codings, or general cross-engine parity. Existing unsupported rows and release gates remain unchanged.
