# ML-first SD article and first repair wave, 4 November 2026

Reader: Shinichi and the maintainer finishing this lane. Status: WORK IN PROGRESS. Totoro package check2 is RUNNING at this snapshot. The canonical LSS refresh and three bounded completion reviews have passed. Full package, CI, PR merge, main verification and final public-URL checks remain PENDING. Focused frozen-source verification is accepted, and Julia documentation has built twice. This report is not a completion certificate.

## 1. Goal

Deliver the approved ML-first route audit, paired R/Julia article and bounded first repair wave. Preserve the full existing SD-regression programme, its evidence denominator and foreign work. Keep G5 calibration and D-342 REML policy deferred.

## 2. Implemented

The R bridge consumes existing validated structured conditional fields for stored `mu` predictions on selected Gaussian, Poisson, NB2, Gamma and Binomial routes. Stored link predictions add the fitted field contribution; response predictions apply the fitted link. Ordinary Gaussian reconstruction stays on its existing path. Explicit `newdata` keeps random effects at zero; the neighbouring Binomial response-conversion path now honors the fitted logit, probit or cloglog link.

The route-audit view preserves all 21,246 required rows, original fields and identities. Admission, implementation, exact-source runtime, receipt linkage, independent review, output, documentation and calibration remain separate. Six source-admission grants describe the three selected article scopes across native and Julia engines. Other unknown rows are not counted as absent implementations.

The R article retains Bernoulli and Poisson examples and adds the checked continuous-predictor Gamma relmat example, a generated method/scope table, SD-scale figure and prediction-quantity explanation. The paired direct-Julia guide is being integrated in its separate repository. Numerical probes and retained setup failures have a source/artifact receipt. Qualified structured fitted values also retain their fixed link predictor when population values round or overflow; response residuals use the retained observed response to avoid cancellation. No new family, likelihood, formula grammar or estimator policy is introduced.

## 3a. Decisions and Rejected Alternatives

Reused the exported per-row structured contribution instead of adding another predictor API. Built the link predictor directly rather than inverting rounded population probabilities. The same neighbour audit later found that conditional `fitted()` inverted rounded or overflowing population values and that residual rebasing could lose a small response beside a huge mean. Retained fixed predictors and observed responses now avoid those losses on the qualified path, with legacy payload-only fallbacks preserved. The Binomial neighbour failure justified using its actual fitted link on explicit-newdata response prediction too.

Kept Gamma seed 20261104 despite its weak fitted SD trend: estimated one-unit multiplier ratio about 1.073 versus generating 1.492. Changing seeds to improve the article would hide estimation error. Native and bridge objective checks use the predeclared absolute tolerance `1e-5`; no tolerance was loosened.

The initial Gamma bridge call copied native `control(se=FALSE)` and was refused before fitting. The documented default-control call passed. The failed attempt remains recorded. Reused the already merged stored-loglik fix `8646e8d14`, rather than duplicating it.

Assumptions made without asking: interpreted source-admission scope as six exact engine rows, not a whole-family capability claim; interpreted the missing Binomial -26.9 provenance as an unresolved locator task, not permission to substitute the scalar-q1 seed. If either interpretation changes, retain the current records and add a separately scoped grant or reproduction.

## 4. Files Touched

R implementation and tests: `R/julia-bridge.R`; `man/predict.drmTMB_julia.Rd`; `tests/testthat/test-julia-structured-stored-prediction.R`; `tests/testthat/test-julia-b34-structured-fitted-bridge.R`.

Audit and evidence: `tools/general-sd-regression/current_route_status.py`; `tools/general-sd-regression/tests/test_current_route_status.py`; `docs/dev-log/general-sd-regression/current-route-status.tsv`; `current-route-source-audit.json`; `article-route-adjudications.json`; `article-capability-summary.md`; `gap-reproduction-20261104.tsv`; and `evidence/ml-first-20261104/`. The evidence prefix's artifact manifest enumerates its scripts, logs, source snapshot and public synthetic data.

Reader and maintainer documentation: `vignettes/predictor-dependent-random-sd.Rmd`; `docs/dev-log/known-limitations.md`; `docs/dev-log/check-log.md`; `news/sd-article-ml.md`; this report; `docs/dev-log/plan-actual/2026-11-04-sd-article-gaps.md`. The lane goal, acceptance design, plan and status files live under `LOOP/lanes/sd-article-ml/`. The final integrator must reconcile this list with the final scoped diff before completion. Foreign work and the protected stash are preserved.

## 5. Checks Run

| Check | Current evidence and outcome |
|:--|:--|
| `python3 tools/general-sd-regression/tests/test_current_route_status.py` | 20 tests passed in the report-assembly rerun; `execution/report-python-current.log` |
| Structured stored-prediction pure-R file | Final 66 expectations passed, including cancellation, overflow and rounded-Binomial regressions; accepted `frozen-verification-final/structured-prediction.log`. Earlier 44-expectation phase retained |
| Ordinary conditional prediction and component neighbours | 20 and 27 expectations passed; same retained focused logs |
| `test-julia-b34-structured-fitted-bridge.R` | 26 live blocks executed; final log retains one Gamma relmat slope `NA/NaN function evaluation` warning and an unlabeled-A warning |
| Independent reader's fresh article render | Passed in 8.81 seconds on source SHA `c2853d4cc8de74e3fcdf8d60a7f9468e1670b458b2f5c866b9cf6d49ce7b2d1c`; optional Julia chunks were not run by that render |
| Gamma candidate, seed 20261104 | Native own-Laplace logLik gap about `-2.02e-11`; bridge gap zero, against `1e-5`. Both convergence codes zero; ratio error remains visible |
| Evidence integrity checker | `python3 docs/dev-log/general-sd-regression/evidence/ml-first-20261104/check_artifacts.py` checks captured artifacts, original 35-file bytes and the expanded 23-record numerical ledger with six ZeroOneBeta attempts |
| Accepted frozen verification | Five jobs exit zero; `EXECUTIONS_COMPLETED_SOURCE_UNCHANGED`; before/after source and DLL maps identical |
| Existing stored-loglik regression | Accepted direct-Julia run passes 38/38 assertions; existing fix reused |
| LSS current-source check and canonical refresh | Accepted checker passes `labels=12 rows=72 checks=8 tolerance=4e-06`; canonical receipt then refreshed against Julia c037268c76d29234a2174354ae4319b4d98e7c29. Public runner PASS in 61.941 seconds, source unchanged, current-source checker PASS. Prior receipt retained |
| Julia docs build and browser inspection | Complete build passed twice; math/layout inspected. Immutable raw-data ref e8a666769fc436e73c7121a4c49b1d9c92866776 awaits pushed HTTP readback |
| Package check | Totoro check2 RUNNING at snapshot; PID174675, `~/codex-runs/sd-article-ml-20261104-check2`, archive SHA-256 274e0fba02a3d5d4a8b40c2f508bd70ddc595606ddb6a427e445e9c446b1625e. No full-package pass yet |
| Independent completion panel | Mechanical, reader and source/math reports have no blocking finding in inspected scope; these are review results, not package or integration completion |
| CI, gated PR merge, main and public-URL checks | PENDING |
| After-task validator | Report structure passes; completion validation correctly stops on unmet `.unlazy/sd-article-ml/GATES.md` and `leaf-s1.md` gates. No full closeout pass claimed while integration remains open |

The external execution directory is `/Users/z3437171/Documents/Codex/2026-11-04-sd-article-plan/execution/`. The committed evidence prefix contains copied logs and hashes; external pointers retain earlier setup attempts. The original current-source snapshot remains historical. The accepted `frozen-verification-final/receipt.json` separately binds its actual five jobs to unchanged before/after source and DLL hashes. R bridge SHA-256 is `4d5c188f10fc73f75ddf0a602fa5d97bb1880f5f65b3469752e9d469f6159ab7`; native DLL SHA-256 is `29dcf6d30daed35200951533fabbaad6bed5e715c383b9fe15f6d5ce6a5567de`. This is a focused runtime qualification, not a full-package or integration pass.

The four NB2 seeds retain eight fits and four comparisons. Seeds 20261022 and 20261025 returned plain-fit nonconvergence with negative-loglik disadvantages about 29.38 and 23.17 relative to explicit constant SD; their counterparts converged. Seeds 20261023 and 20261024 agreed to about `1.4e-10` or better. This is not a failure-rate estimate or a false-positive convergence result. Gradients were unavailable.

ZeroOneBeta seed 20261409 returned convergence code zero and coefficients with minimum interior response about `2.58e-56`; SE quality and gradient were not independently verified. Seed 20261412, minimum about `1.55e-311`, threw in the SE Hessian. No current point-convergence claim follows from that exception. The predecessor and accepted frozen reruns repeat that mixed ZeroOneBeta outcome, retaining six attempts across three batches. The scalar-q1 Binomial locator seed 20261017 returned moderate SD coefficients and does not reproduce the unlocated historical -26.9 case. The original NB2 probe core remains unchanged, so its recorded direct-script scope is preserved.

## 6. Tests of the Tests

The new structured prediction tests first failed at the original conditional-payload refusal. The repaired suite checks seven family/link combinations, serialization, malformed or absent fields and explicit-newdata behavior. The added non-logit test exposed the neighbouring inverse-link error before its repair. New red controls reproduced loss in fitted values for cancelling extreme fields and rounded Binomial probabilities, then response-residual cancellation. The repaired cases now contribute to the final 66 expectations, with red/green logs retained.

Audit regressions reject lost/duplicate identities, unsafe root escapes, compiled-binary contamination of a source snapshot, suffix-only manifest binding and stale or incomplete source-admission evidence. Independent review found the suffix-binding weakness before acceptance. A new interface-specific source-binding regression prevents granting both Julia public interfaces from an unrelated source file.

The live stored-output file independently assembles conditional contributions and retains wrong-order/wrong-population separations. Gamma fitting is checked against a hand-density, Newton-mode dense Laplace objective at each engine's own coefficients. These controls test their specified failure classes; they do not establish calibration or the untested cross-product.

## 7a. Issue Ledger

The first repair wave does not close the wider SD programme. Retained numerical findings refer to the existing known-limitations ledger. Existing Julia PR 1223 requires overlap review before any corresponding numerical repair. The merged stored-loglik fix is reused, and its accepted full regression passes 38/38; it is not an unfixed implementation issue.

No external issue comment, new issue, closure or post was made by the report slice. Any final overlapping-issue and authorized tracker reconciliation remains PENDING with integration; the bounded completion reviews do not close the numerical tickets. Do not create duplicate issues to replace missing provenance.

## 8. Consistency Audit

The known-limitations top SD-output block no longer claims that stored prediction is unavailable for every Julia fit. It separates newly reconstructed structured `mu` outputs, existing ordinary Gaussian behavior, remaining missing-payload refusals and explicit-newdata RE-zero predictions. The historical ZeroOneBeta statement is preserved and qualified by the current mixed outcomes.

The article pairs `Cov(b)=D_s K D_s`, public `sd(id, level="relmat") ~ z` syntax and marginal SD `s_g sqrt(K_gg)`. Constant Gamma `sigma` is an estimated conditional coefficient of variation, not a known dispersion or latent SD multiplier. The reader answered all five interpretation questions and inspected the actual two-panel figure. Julia math/layout was also inspected in the browser after two complete documentation builds. These local views do not certify final deployed URLs.

Status-inventory reconnaissance used this exact command:

```sh
rg -n 'sd-article|stored.*predict|structured.*predict' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml --max-count 3
```

This was bounded reconnaissance, not an exhaustive stale-claim audit. Final inventory reconciliation and deployed links remain PENDING; the paired Julia local build and browser checks passed. No new formula or likelihood parameterization requires a grammar or likelihood design change; output documentation changes are in generated help and the article. Existing navigation is reused because the R article already exists.

Memory receipt: the parent lane's approved plan, per-lane goal and routed context were the working map. The source-bound evidence and ownership instructions shaped the snapshot limits, scoped edits and retained failed attempts. No new cross-project discovery or global memory edit was performed by this report slice. The final Golden-Set and routed-guard completion statement remains PENDING with the parent audit; it is not inferred from this report's existence.

## 9. What Did Not Go Smoothly

A generated row-preserving audit initially had no source adjudications; preserving rows alone could not support article admission. Independent review also found suffix-only file binding, and parent regressions found binary contamination and escaping symlinks. Those classes now have targeted tests.

A Julia test dependency was unavailable on the first direct probe attempt. The initial Gamma bridge control was unsupported. Both attempts remain retained. The first full R-check attempt also stopped on missing Pandoc before tests; task-local Pandoc 3.13 was installed from verified archive SHA-256 `38aa33b325a2bc96a4c39409631212db55702f564250bcdbead180b3bf646389` before launching check2.

The predecessor frozen batch's functional jobs all exited zero. Its authoritative LSS runner compiled a fresh DLL, changing binary identity while source code stayed unchanged, so the guard stopped the batch. The final batch used the current-source checker on that valid LSS receipt and passed all five jobs with source and DLL stable. This was not a functional-test failure. The inherited statement that both extreme ZeroOneBeta seeds still failed was contradicted by the current log and RDS; the evidence receipt records the actual mixed result.

The global closeout tool previously encountered an unrelated foreign malformed unlazy ledger. This report does not alter that ledger or claim a global closeout pass. Structural and final completion checks must retain that distinction.

## 10. Known Residuals

PENDING: completion of the full package check, CI, exact-head PR integration, post-merge main checks and deployed-page/HTTP checks. Canonical LSS refresh against Julia c037268c76d29234a2174354ae4319b4d98e7c29 and the mechanical/reader/source-math completion reviews have passed their bounded scopes. The focused accepted source-freeze batch and two Julia docs builds already passed. No task-complete, release-ready or broad parity claim is made.

The reproduced NB2 optimization limitation, extreme ZeroOneBeta SE-Hessian failure and unlocated historical Binomial case remain unresolved as specified in the numerical ledger. Extreme Binomial SD clamp/output consistency is a source finding, not a repaired or calibrated extrapolation claim. G5 and D-342 remain deferred.

## 11. Team Learning

Keep source admission, runtime evidence, independent review and output contracts separate. A valid structured fitted payload does not guarantee public stored prediction consumes it. Exercise both public functions and their neighbouring links before changing a status label.

Preserve raw attempts and audit exact values rather than repeating handover summaries. The mixed ZeroOneBeta result illustrates why source/runtime readback is necessary. Do not promote this report's current snapshot into historical runtime proof. No new always-loaded guard was added; final durable learning reconciliation remains with the parent closeout.

## 12. Cross-Product Coverage

This first delivery covers selected complete-response ML article models, six scoped source-admission rows, native point examples and the named structured R bridge stored-output tests. It does NOT cover the full 21,246-row universe, every distribution/provider/block combination, missing responses, all random slopes, newdata conditional extrapolation, conditional standard errors, new groups, calibrated intervals, REML-policy changes or direct-Julia conditional `fitted()` semantics. The larger programme remains active after this milestone's eventual integration.

## Integration update: 4 November 2026, check2 finished 20:47 UTC

This dated update supersedes the earlier running-check snapshot without deleting it. Full R package check2 ended at `2026-11-04T20:47:07Z`, exit 1: 41,881 testthat passes, 1 failure, 117 warnings and 696 skips. Documentation, examples and vignettes passed. The one error came from the existing imported-generic dispatch test's source-root assumption in an installed check tree. The parent verified that the failing test source matched `origin/main`; this is an integration-harness failure rather than a newly observed SD likelihood or prediction failure.

The parent changed only `tests/testthat/test-fixef-imported-generic-dispatch.R` for this repair. The test derives the package path from the loaded namespace and detects development versus installed mode. Its fresh child process keeps `pkgload::load_all()` for development and uses `loadNamespace()` with the exact parent library for an installed package. The coefficient and random-effect dispatch assertions remain unchanged. Source and installed-library checks each pass all three assertions, with zero failures, warnings or skips. The independent review finds no weakening, skip path or class-coverage loss. This targeted result does not replace the full-package recheck.

The evidence prefix now retains `integration-dispatch-repair/`: failed check log, both green logs, independent review, exact diff and receipt binding source hashes. The complete failed test output stays external with a hash/size pointer. All prior frozen batches, six ZeroOneBeta attempts and original NB2 denominators remain intact. This report's file inventory therefore also includes the one integration-test repair and its evidence, with implementation owned by the parent.

Full check3 is PREPARING, with no PID at this snapshot. Its estimate is 80–120 minutes, based on about 83 minutes for check2. R new-head CI remains pending; Julia documentation and preview checks pass, and Julia test shards remain pending. Full package, CI, merge, main and public-URL gates stay open. No additional model scope, likelihood, public API, tolerance or calibration grant follows from this test-harness repair.

Check3 launched at `2026-11-04T20:50:09Z` and is RUNNING on Totoro under `~/codex-runs/sd-article-ml-20261104-check3`, PID `237407`, for archive SHA-256 `49a69b322add471e7fd250685becd2da88051f00882aa64526db069dca79674e`. Its source-identity record binds seven source/test/doc members to current bytes. The 80–120 minute estimate is retained, with stop/re-estimate at `22:50:09Z`; no outcome is claimed yet.

## Current-ref integration update: 4 November 2026, Julia 1cd856f6

The Julia CI namespace repair is committed as `1cd856f63fa8a2a62a2e181e00790a0d812fb8af`. It removes one conflicting `const D = Distributions` declaration and qualifies 29 dotted references. A real Julia 1.10 red run reproduces the `Main.D` collision. Namespace smokes pass 3/3 on both Julia 1.10 and 1.13, and the AST comparison passes 3/3 with a deliberate-tolerance-change negative control. Independent review finds no blocker within this alias correction. Julia engine source, `Project.toml`, fixtures, fit calls and tolerance assertions are unchanged; the foreign-owned Binomial fixture remains untouched.

These isolated namespace smokes use an existing exploratory guard and do not qualify the full quadrature grid. The prior stable PR shard3 pass remains historical evidence, without attributing it to this change. `integration-julia-namespace-repair/` retains the bounded receipt, red/green/AST logs and review; generated verification-script hashes point to external copies rather than copying the full Julia test source into this R repository.

The canonical LSS public workflow now uses Julia `1cd856f6`. Its runner reports PASS in 59.17 seconds; the refresh guard reports 59.8389805 seconds with source and DLL maps unchanged before and after. The authoritative current-source checker passes 12 labels, 72 rows and 8 checks at tolerance `4e-6`. `lss-1cd-current.json` matches canonical `public-001.json` byte for byte. The new log, guard and refresh script are retained, while c037 and earlier receipts remain unchanged.

Full R check3 remains RUNNING at this snapshot: Totoro PID237407, start `2026-11-04T20:50:09Z`, stop/re-estimate `22:50:09Z`, archive SHA-256 `49a69b322add471e7fd250685becd2da88051f00882aa64526db069dca79674e`. R source-head CI `41910728363` on `6a1b35ea7afd97b96c64b0a68994b4b66b5d61ce` is running. Julia CI `41917279603` and docs `41917279899` are running. The impending R documentation/receipt/generated-view commit adds no model-source change. Package, CI, gated merge, main and public-URL gates remain open; no calibrated-interval, REML or broader-family grant follows from this update.
