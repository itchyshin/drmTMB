# Bernoulli selected-SD q1: independent candidate evidence

## 1. Goal

Bind one strict Bernoulli selected-SD case to its fixture, helper, actual R and Julia candidates, and independent likelihood references. This is a first-delivery candidate check within the approved general SD goal.

## 2. Implemented

The runner selects the exact existing `test_that("public Julia Bernoulli SD outputs match the fitted target")` expression from `tests/testthat/test-julia-binomial-sd.R`. It preserves all 57 original AST statements and appends one reference call inside that test, reusing its two fitted objects. The old test, helper, fitting source, seed, and thresholds were not edited. The fixture has 300 independent groups, 12 rows per group and one Bernoulli trial per row. The SD predictor is `sd(id) ~ w`; there is no residual `sigma` coefficient.

The independent reference computes each group's scalar log joint density from `dbinom()` and `dnorm()`, optimizes the group mode with `stats::optimize()`, and computes curvature analytically. Its Laplace value checks native TMB. A five-node physicists' Gauss–Hermite rule built from a Jacobi eigensystem checks Julia's adaptive quadrature. Five-node rule moments through degree eight, Gaussian normalization at three SDs, and one-node quadrature versus Laplace passed. An independent Fisher review cleared the math and runner before the live fit. The model relationship is written term by term in `tools/general-sd-regression/bernoulli-q1-evidence/PLAN.md`.

## 3a. Decisions and Rejected Alternatives

Native and Julia negative log likelihoods were compared with their own reference approximations at their own fitted coefficients. Their optimized cross-engine likelihood gap is 2.02208111. That is descriptive, not an equality gate: the objectives use different approximations and were evaluated at different fitted parameter vectors, so the gap cannot be attributed quantitatively to either cause alone.

The profile and bootstrap workflows requested with `R=3` were checked for finite ordered endpoints and target routing only; the number of successful bootstrap refits was not captured. I did not add a repeated coverage study, change source, or claim calibrated uncertainty.

The default assumption was that an owned depot overlay followed by read-through depots would keep Julia cache writes separate; the successful import and unchanged source manifests support this for the measured run. If that assumption fails on another machine, make another private depot rather than editing the candidate source.

## 4. Files Touched

Created `tools/general-sd-regression/bernoulli-q1-evidence/{PLAN.md,reference.R,run.R,run-live.sh,pin.py}`; created `docs/dev-log/general-sd-regression/evidence/bernoulli-q1-independent-20261028/` with the receipt, two identical 186-file source manifests, exact-byte source capsule, fixture RDS, setup logs, live log and exit code; created this report and `docs/dev-log/general-sd-regression/bernoulli-q1-check-fragment.md`. A separate scratch project at `/Users/z3437171/Documents/Codex/2026-10-28/drm-bernoulli-q1.59eBZj/` holds copied Julia Project/Manifest, a symlink to the SD candidate's `src`, owned depot overlay, extracted test and process ID. No shared source, public docs, issue or other lane's cache was edited. The older `julia-bridge-source-bound-20261024-rerun/receipt.json` remains byte-identical at SHA-256 `d12731890ecd9a9b21fb97e456697ef3f35cc55ea27bee0850239da9a2ac466c`.

## 5. Checks Run

`Rscript tools/general-sd-regression/bernoulli-q1-evidence/run.R --dry-run` selected one test by exact name, verified original test SHA-256 `721658fe990bd3147fd030572320fc7d60bbe78bed4c87f21b928f8d6e60d23f` and helper SHA-256 `acd2153d99bc46d4094cbf5d9a1abd05febd00cb9e9e2a3619d3325925df9018`, and showed 57 statements preserved. The pure reference controls passed before fitting.

The Julia import pilot loaded candidate `pkg/src/DRModels.jl` under Julia 1.10.12 and measured `_BINOMIAL_RANEF_AGHQ_K=5`; copied Project/Manifest matched the candidate byte for byte. The R load pilot used R 4.6.0 and loaded DLL SHA-256 `afde22660f3bc7577f9e6cb261356ceb11c31ef1c50ad27199295e3e1a71b7dc`, the same as `src/drmTMB.so`. C++ source mtime was 22:48:01 and object/DLL mtime 22:48:41 on 2026-10-27. This is chronological build consistency, not a cryptographic rebuild proof.

The selected live case ran from 07:31:26 to 07:32:53 UTC, 87 seconds against a declared 15-minute upper estimate. It passed 1 live case, 53 expectations, 0 skips and 0 failures. Native negative log likelihood was 2277.245843760257 versus independent Laplace 2277.245843748281 (absolute error 1.20e-8, bound 1e-6). Julia negative log likelihood was 2275.223762651749 versus independent five-node adaptive quadrature 2275.223762651570 (absolute error 1.79e-10, bound 1e-5). One-node quadrature versus Laplace differed by 4.65e-9. Both fitted SD predictors stayed in the clamp's identity region (absolute maxima 0.806 native, 0.782 Julia; boundary 9). Native `pdHess` and Julia bridge convergence were both true. The 80% profile SD-slope interval was [0.34007, 0.69542]; the bootstrap interval requested with `R=3` was [0.56272, 0.67148]. These are one-dataset workflow results; successful-refit count was not captured.

`python3 tools/general-sd-regression/bernoulli-q1-evidence/pin.py` before and after returned byte-identical 186-file manifests, SHA-256 `07552b89e1a4e611540c2bb1ca0492378441179701d26dbc87b145748f4a4fa9`. They include all R and C++ package source and actual source-tree DLL, the old test/helper, new runner/reference, full Julia `src`, Project and Manifest. The verified 7,149,787-byte `source-capsule.tar.gz` archives those exact 186 bytestrings and their manifest, SHA-256 `c15b9f44b2c8a4fe25a5d10c53a18ff30a91516df0e1fa151cb2f33960c63e21`. The fixture RDS SHA-256 is `c24dd2b2a5f776ec5fbc29ffc34fa2120b8707add6fb99ae7d2bb7e80d694ef7`; raw live log SHA-256 is `412eb3dd27834c29e50d9a2b3093b8cebf802d5b2ffe13fdb78e0ca8cf9813cc`. `receipt.json` holds exact source, runtime and result fields.

The hub closeout compiler passed this report, and the Codex efficiency gate passed. The read-only handoff gate spent about three minutes enumerating hundreds of shared repository branches. I terminated only my gate process (exit 143); that broad landing audit is inconclusive. This scope's new files remain untracked in the parent-owned dirty candidate worktree, with no commit or push authorised by this task.

## 6. Tests of the Tests

The oracle does not call package likelihood or simulation code. Its Hermite moment and Gaussian integrals detect wrong nodes, weights or Jacobian; its one-node result detects an incorrect Laplace convention. The same test body executes recovery and public predictions, tables, fitted distributions, serialization, profile and bootstrap. The new checks would fail if a likelihood objective, trial count, clamp region, target routing or interval endpoint did not match the measured case. No test was weakened after seeing results.

## 7a. Issue Ledger

No GitHub issue was opened, commented on or closed from this bounded evidence task. The approved broader general SD goal remains open; the parent lane handles its issue and public capability ledger. The old 2026-10-24 receipt omitted helper and independent oracle hashes and remains an honest historical limitation, not retroactively repaired.

## 8. Consistency Audit

I checked the existing q1 test and helper, Julia candidate `_BINOMIAL_RANEF_AGHQ_K`, `_aghq_group_logint`, and the selected-SD fitter. The fitted case has one trial per row and no residual `sigma`; neither engine's fitted SD predictor reaches the soft-clamp shoulder. The current Julia `main` head is a different source and does not have this selected-SD route, so this is candidate evidence only. No family, formula grammar, package behavior, README, NEWS, vignette, pkgdown or design claim changed. The public status inventory remains with the parent/docs owners.

## 9. What Did Not Go Smoothly

The first Julia import pilot found `IrrationalConstants` missing from the parity depot for the candidate Manifest. Adding the user depot as a read-through third path succeeded without source changes. The first R pilot loaded the package but failed while printing `getRversion()` directly through `cat()`; `as.character()` fixed that printer. Both failed logs are retained. The hub `closeout.py new` initially wrote a new empty template under the Shinichi hub because its output path is hub-relative; I immediately removed that new template and wrote this report at its intended repository path. The broad handoff gate did not finish within a useful bound, so its process was stopped and the partial log retained. No fit was run in the failed pilots.

## 10. Known Residuals

The original case gates selected-SD coefficient recovery, not fixed `mu` coefficient recovery against truth. Fitted beta estimates and full Julia covariance eigenvalues were not saved from the ephemeral fit, so no inference-readiness claim follows. A bootstrap requested with `R=3` only proves that the route returns finite ordered endpoints here; the successful-refit count was not captured, and coverage calibration remains deferred by the approved goal. The candidate Julia source is not current `main`; broad families, structured effects, correlated bivariate cases, and deployment remain outside this receipt. A source-to-DLL rebuild equivalence check was not performed; the actual loaded DLL hash and build chronology are recorded. The source manifest proves bytes stayed stable throughout this run, not that all 186 files were independently reviewed. Aggregate acceptance remains unknown: this task supplied one node of the larger goal, and the parent lane must integrate the untracked artifacts under its ownership and run its own acceptance ledger.

## 11. Team Learning

For a paired bridge test, extract the original test expression and add independent references inside its environment. This retains its seed, thresholds and public-method checks while reusing fitted objects. Pin the fixture helper and both approximation-specific references; a green bridge test without those pins is weaker evidence. Runtime depot fallback needs an owned writable first path so old private caches and source trees remain untouched.

Memory receipt: I used `route.py drmTMB` and relevant `memory/00-INDEX.md` guidance, plus the repository's approved goal, AGENTS and local source as technical truth. The routed lesson to distinguish candidate evidence from main and to avoid interval calibration claims shaped this report. I did not run the Golden Set because no known-mistake production code was changed; no hub guard or durable decision was added. Negative space: no production campaign, no source edit, no public map update, no issue action, no Git operation beyond read-only status and hashes.

Golden Set: not in scope for this evidence-only runner and receipt; no production implementation was changed.

## 12. Cross-Product Coverage

This one ordinary Bernoulli random-intercept selected-SD test covers a candidate R/TMB and candidate Julia bridge path and the named public outputs exercised by the frozen case. It does not cover current-main Julia, another distribution or effect type, fixed-mean recovery, replicated uncertainty coverage, exact marginal accuracy of AGHQ5, or the full approved SD universe. The parent lane should keep the broader acceptance ledger open.
