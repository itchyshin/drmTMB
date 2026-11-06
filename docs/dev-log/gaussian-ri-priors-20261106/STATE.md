# Gaussian random-intercept coefficient priors

Goal: implement the approved Gaussian one-IID-mean-random-intercept fixed-effect prior slice in both packages, independently validated, without merge or release.

R worktree: /Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB
Julia worktree: /Users/z3437171/.codex/worktrees/drmodels-fixed-priors-20261105/DRM.jl
Both branches: codex/gaussian-ri-priors-20261106
R base: 34c907e1c0be19553fa2e9153e2d3c2a72c86274
Julia base: 86ee1c2a38cd79c55dbbd71afd7374a3095aad3c

The existing managed worktrees are reused. Only their pre-existing dirty .claude/settings.json and .cursor/hooks.json remain unrelated and unstaged. No worktree removal, cleanup reset, merge or release is authorized. PR #1651 remains OPEN at 1bf51e2d61bd1ce0a2fb3fad914a9888544af491.

Status: independent oracle and frozen fixture authoring in progress; read-only route/ownership scout in progress; engine implementation has not begun. Oracle author will not implement either engine. Root owns orchestration/evidence; oracle worker owns only tools/gaussian-ri-prior-validation/. Root oracle lease includes that path and this evidence folder. New engine leases require actual overlap checks before editing.

Compute: tiny oracle smoke local, BLAS 1. Twelve-fixture validation and full suites on Totoro after timed preflight; do not infer runtime from prior release CI. No run over three hours without a measured pre-run and further approval. No campaign on GitHub Actions.

Broader random-effect SD/correlation priors were discussed as future architecture. They remain outside this approved slice. The current group SD is estimated without a prior.

## Checkpoint: independent oracle and native preflight

Oracle: tools/gaussian-ri-prior-validation/. Frozen manifest SHA256 c88140ec4222a3bf5a25b5132e6f05a0dd1183692db28540a76e1a93f3fa6474. Final fitted reference SHA256 85db00122f23a2d9fc408cfc11ec85d4a1ca62d1f822dd3f544c36249603833f. Root reran self-test and all checksums; independent mathematical/optimization review READY at /Users/z3437171/.codex/evidence/next-prior-plan-20261106/math-review.md. Full 12-case reference ran on Totoro in 0.178 s. All 72 attempts retained: 71 optimizer successes, 59 full-model KKT eligible, one failed; twelve restricted-boundary successes excluded. All twelve selected numerical solutions unchanged by audit.

Root-owned integration tools: tools/gaussian-ri-prior-adapters/{convert.py,compare.py,run-validation.sh}; last runner not yet created. R worker owns r-native.R/r-bridge.R there; Julia worker owns its tools/gaussian-ri-prior-adapters/julia-native.jl. TOML transport strips expected values for Julia; independent comparator handles native natural/log-group-SD derivative conventions and actual fitted parameters. Six comparator mutations rejected after a true R positive control; proof in preflight-verifier-controls.json.

Four R native and four Julia native preliminary cases PASS independent fixed-point and fitted objective/identified coefficient/interior group-SD comparisons. Results copied under preflight/ and verification logs beside this checkpoint. Exact point tau=0 uses a separate fixed-only Gaussian boundary-value calculation; native log-SD boundary derivatives are unavailable. Two preflight fitted boundaries preserve true convergence flags AND singular-Hessian warnings. Independent boundary-limit review confirmed covariance perturbations negligible and one-sided variance score positive; no flag or tolerance waiver.

R source author /root/ri_prior_r_engine: 27 new +44 existing focused assertions and runnable help example pass. Production change is narrow prior-route admission in R/fixed-priors-workflow.R; no C++ or R/julia-bridge.R changes. Docs/man updated narrowly, existing article vignettes/articles/fixed-effect-priors.Rmd renders. PR1651 texts outside the prior paragraph and all historical receipts stay untouched.
Julia source author /root/ri_prior_julia_engine: 20 new +82 existing prior assertions pass on Totoro Julia1.10.12 (base86ee1c2 with four src edits); latest message-only resolver correction rerun pending. Preserve explicit marginal=:Laplace mean-RI refusal; default :LA route is exact Gaussian, R TMB integration is Gaussian-exact. Audit control refusals before source freeze.

Bridge: local Mac attempt STOPPED before fit after disposable bootstrap lacked ForwardDiff in selected source environment. No global dependency/toolchain changes. Full live check must use Totoro's prepared Julia source at /home/snakagaw/hsq_work/drmodels-ri-prior-julia-20261106, executable /home/snakagaw/.julia/juliaup/julia-1.10.12+0.x64.linux.gnu/bin/julia, default depot. Bundle libunwind.so.8.0.1 exists, but startup workaround must be measured, not assumed. R source selector is DRMODELS_JL_PATH; JULIA_HOME points to executable directory. Stage R source in /home/snakagaw/hsq_work/gaussian-ri-priors-r-20261106, build its own DLL/library, do not load prior-run installed package by version string.

Next: finish source/control audit and narrowly commit candidates; stage pinned sources/own R DLL on Totoro; exercise four bridge cases, then full frozen 12-case x3-route grid with exact source/environment manifests. Bridge supports fit-point validation against oracle, not arbitrary-point gradient/Hessian; no new bridge test-only API will be introduced. Comparator requires actual solver status and retains unavailable quantities honestly. Follow with scoped regression/guard tests, measured full suites, worked docs and independent completion review. No merge/release. Future targeted SD/correlation direction is recorded in NEXT-SD-COR.md, outside current implementation.
