# Superseded checkpoints

Historical snapshots follow verbatim. Their present-tense status statements are superseded by STATE.md.

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

## Source-pinned validation started

R source commit: `251d103b310cde7df68d0db439888f8c16177fbb`. Julia source commit: `f60eb88eebdaebc3b1ac1babb81aeb942f7dc8e8`. Both were staged as exact committed trees with a shallow Git root on Totoro; protected uncommitted configuration files were excluded. Julia dependency installation and precompilation passed on Julia 1.10.12. The original harness selected 560 files; eight dry-run partitions contain 70 files each, with a verified disjoint union equal to the unsharded selection. Optional JET and parity gates are separate from this count.

The eight native Julia suite processes are running under `/home/snakagaw/hsq_work/ri-priors-final-julia-suite-20261106`, with per-shard logs, process IDs and terminal exit files. Each shard has a 10,200-second timeout. This records launch and partition evidence, not a suite pass.

The isolated R installation is compiling under `/home/snakagaw/hsq_work/drmtmb-ri-priors-final-lib-20261106`. A bounded runner waits for its actual terminal state and requires the installation success marker before starting the 12-fixture, three-route grid. It then runs a full package build/check and the source-tree test manifest and suite. Logs and terminal status files are under `/home/snakagaw/hsq_work/ri-priors-final-r-validation-20261106`. Pandoc 3.13 was verified at the existing isolated tools path. No final grid or full-suite pass is claimed yet.

A staged whitespace check flagged one trailing space in frozen oracle generator line 21. Its checksummed source was retained unchanged. Both local worktrees otherwise retain only the preexisting dirty configuration files, plus this evidence update. No push, merge or release occurred.

The independent final source review passed within the admitted route at both pinned commits; see `final-source-review.md`. Full numerical and regression qualification remains pending. The isolated R installation subsequently passed, and fixtures ri_01 and ri_02 passed on all three routes. The installed final R shared-library SHA256 is `3aead1ed4a821e1e400cc56f78b7c6f37e8ccbf3828134086025c13a7bd81126`.

The final grid stopped at ri_10 with exit 1 after ri_01 through ri_09 passed on all three routes. Native R reported convergence at objective 7.216304757921474 and group SD 4.370565582893776e-6, versus the independent optimum 3.749909336093191 reached by native Julia and the bridge. The fitted-optimum normalized error was 0.42189226470528446 against the unchanged 1e-7 limit. This is an unresolved validation failure. Raw attempts remain under the original grid directory. Independent initialization and boundary-score diagnoses were requested. The original per-case commands for unfinished ri_11 and ri_12 are running in a separate grid-tail-11-12 directory; no failed output was overwritten. Full regression jobs continue on the original pinned sources.

Configured numerical qualification subsequently passed all 36 fixture/route checks. Native R used the uniform policy in `R-MULTISTART-POLICY.md`, and native Julia and the bridge retained their original configurations. The original default results remain 35/36, with native R ri_10 failing. The aggregate and all selected raw results are in `final-numerical-evidence/`; the failed R result is preserved separately. Maximum normalized fitted-objective error was 5.371e-11, fixed-coefficient error 5.342e-8, interior group-SD error 3.571e-9, point-gradient error 9.889e-16 and point-Hessian error 6.972e-10. These satisfy the frozen limits. Full R build passed; R CMD check and the native Julia suites remain running.

The revised R article rendered successfully after the local-minimum guidance was added. Both current Julia prior-guide code blocks executed against pinned f60eb88e and printed DOC_EXAMPLES_PASS. The full Documenter site has not been rebuilt. Six Julia regression shards have exit0; shards4 and8 remain live. R CMD check reached testthat.R.
