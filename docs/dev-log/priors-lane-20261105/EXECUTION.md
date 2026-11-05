# Approved execution checkpoint

Goal: implement and independently validate the first fixed-effect prior slice in both packages. Shinichi approved on 5 November 2026. No merge or release.

R root: /Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB
R branch: codex/fixed-effect-priors-20261105
R baseline: 9fea3036791e9bd836e080d9297cd04b1b29c2f8

The R kernel agent owns new constructors, resolver and compiled tests. Parent owns workflow integration, reporting, guards and documentation. Unrelated .claude/settings.json and .cursor/hooks.json modifications are preserved and must never be staged.

Read PLAN.md for the approved API and numeric gates. Priors use the final beta_mu and beta_sigma columns. Normal penalties include constants; ridge is exactly 0.5 lambda beta squared without a constant. Zero lambda is recorded but leaves estimator ML. Generic SD priors and tmbstan are excluded.

Remote workspace: /home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b on Totoro. One compiler process; BLAS threads one. Provisional build estimate 15 minutes. Smoke first, then four-fixture batch estimated under two minutes after build.

Current state: source-only constructor/selection and admission tests pass. Compiled validation pending. R request admission rejects unsupported family/effects before setup. Julia managed worktree creation tool is still pending; original Julia checkout remains untouched. Julia source inspection exposed overlapping PRs #1214/#1218/#1106/#1055. An asynchronous owner decision is pending for isolated prior-only edits in their shared files. Do not edit those files until answered.

Next: finish generated docs, deploy R source snapshot, compile/install on Totoro, inspect one smoke fit, then run the independent oracle and workflow tests. Check the pending worktree tool and owner response before Julia writes.

Update: owner approved isolated Julia prior-only changes despite overlapping PR files. Julia root /Users/z3437171/.codex/worktrees/drmodels-fixed-priors-20261105/DRM.jl, branch codex/fixed-effect-priors-20261105. Its worker owns that checkout and scoped lease. Native Gaussian/binomial and bridge smoke checks are in progress on Totoro.

R compiled prior oracle and workflow suites passed on Totoro. First smoke fit took 0.071 seconds and had finite populated coefficients, gradient, prior term and data log-likelihood. Source deployment initially included AppleDouble sidecars; rebuilt without macOS metadata into r-src-clean. R-only staged --no-libs reinstall lost the new shared object, so normal cached-object installation is used instead. Corrected the prior/default control boundary: ordinary optimizer-list defaults are parsed before disabling the default clamp; explicitly configured clamps still refuse. Added tests. Direct Gaussian coefficient oracle tightened to 1e-7 after stripping only irrelevant expected-vector names. Objective checks tightened to 1e-10, FD gradient/Hessian remain 1e-6/1e-5. No tolerances were relaxed.

R affected-regression run is running via regression-r.R, installed candidate, log evidence/r-regression-initial.log. Latest source adds bridge prior payload/tag validation and summary interval/p-value guards; must install/retest final source after Julia fields stabilize. Main check-log and NEWS remain protected; per-file evidence/news fragments are used. Keep .claude/.cursor config changes out of staging.

Live bridge result: launch-only LD_PRELOAD of Julia 1.10.10's bundled libunwind avoided the existing JuliaCall host startup crash (PR #1565 read, not edited). R/TMB versus R-to-Julia on frozen Julia source aggregate 22ab4049778f7888f24509b3668adf3d50341178245e37786211015ba632dd00 passed three fixtures: Gaussian mu/sigma, binomial partial prior, Gaussian zero ridge. Maximum coefficient gap 2.03e-11, maximum data log-likelihood gap 1.78e-15 in that bounded set. No general parity or calibration admission. First failed startup exit139 log remains separate. Mirror released for final Julia guard fixes.

Julia final source aggregate d8fad19a2bbf7cac678ac2a0c7a28376f850e8efecd7a88e91c0cf55da6cbfdd; focused 78/78 reported pass. Full Julia suite still on older efd2 snapshot; retain this distinction. Independent reviewers found and prompted fixes for weights, summary/other inference escapes, zero-ridge separation metadata, and explicit update-to-ML. R resolver preview now also checks rank of unselected blocks, matching fit admission. R zero ridge now preserves ordinary default likelihood controls rather than disabling the default clamp. Those final R fixes require reinstall and focused/regression rerun.

Full R suite: remote PID 1393278, process group 1393277, 90-minute cap, installed earlier candidate. Results/log under evidence/r-full*; registered sim_meter label drm-priors-r-full-20261105. Baseline tracked docs/tools/vignettes support archive was supplemented without overwriting existing candidate files. No source R edits during that run; final source will use a separate install path. Final source checks must name the snapshot actually exercised.
