# Hosted CI evidence delta

Verdict: the new receipts establish successful hosted R checks on all three platforms and a passing hosted Julia baseline shard 3. The original Julia candidate attempt remains failed; its diagnostic retry has no terminal result in the supplied snapshot. Overall qualification remains pending. No baseline-defect attribution, merge or release is supported.

Independent Codex review, 7 November 2026 UTC. Scope is the new artifacts in `R/docs/dev-log/gaussian-ri-priors-20261106/hosted-ci-baseline/`, where R is `/Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB`. I checked raw logs, recorded hashes, terminal workflow metadata and current documentation. I ran no fits, tests, agents or GitHub actions and changed only this external report. Earlier reviewer reports retain their exact hashes.

## R terminal result

`R-CI-final-d9c0902e.json` records run 42315004155, attempt 1, completed/success at `d9c0902e014de93f8fb6abbcfe55817d57101012`. All five jobs, including the source-tree job and three OS package checks, completed successfully. All three raw log hashes match `R-CI-final-qualification.json`; their checkout source and final test summaries agree:

| Platform | Pass | Fail | Warn | Skip |
| --- | ---: | ---: | ---: | ---: |
| Windows | 41,933 | 0 | 124 | 720 |
| macOS | 42,020 | 0 | 116 | 703 |
| Linux | 42,013 | 0 | 117 | 703 |

Every package log ends with two NOTEs: the existing top-level `news` directory and the report-only `spelling.Rout` comparison. I confirmed `news` exists at pre-slice base `34c907e1c`. These hosted counts and two NOTEs belong to this run; they do not replace the earlier local check's counts and one NOTE. Each raw hosted footer explicitly reports zero live Julia bridge tests and 138 skipped. Live bridge qualification remains supplied by the separate guarded receipt. A current Git comparison confirms no production/test change from engine `5d0f1596` through the R documentation head `21061cd7`.

## Julia original attempt and baseline

All three hashes in `Julia-CI-original-and-retry.json` match the terminal attempt-1 metadata and candidate shard-3/4 logs. `Julia-CI-original-final-385fde27.json` records attempt 1 completed/failure at `385fde27d369270afb2353ddf1fbd9f301f2b4ce`: shards 1, 2 and 4 succeeded, shard 3 and `ci-ok` failed. Shard-1/2 success is metadata evidence; their raw logs are outside this delta's supplied set.

The raw Julia 1.13.3 shard-3 log contains one `Test Failed` event: `test_binomial_sd_public.jl:92`, `slope_fit.converged`, followed by 43 passes, one failure and package-test failure. The shard-4 log has no `Test Failed` event, reports the new Gaussian RI prior tests 43/43 and native factor selectors 5/5, and ends with `Testing DRModels tests passed`. This supports these new tests; it does not widen raw-factor bridge support or qualify the failed candidate workflow.

The hosted baseline shard-3 log matches SHA-256 `c22b36e3add0faf48e9bd276e2736909ace0addce0b62abac4d7e61b55aa491e`. It records Julia 1.13.3 at exact pre-slice source `86ee1c2a38cd79c55dbbd71afd7374a3095aad3c`, the same testset 44/44, and the package-pass marker. Its qualification identifies run 42318931694/job 128238649958 as successful. This is a passing baseline shard, not a completed baseline matrix or proof of identical hosted dependency/state conditions.

The recorded debug retry is attempt 2/job 128272640509 at unchanged candidate source, with status `in_progress` at recording. The supplied evidence contains no terminal retry log. Keep attempt 1 visible even if the retry later passes, and adjudicate the differing hosted results explicitly. Baseline shard-4 jobs remain pending in the coordinator's supplied status; I did not wait for or poll them.

## Documentation and protection

`STATE.md` correctly distinguishes completed R CI, successful baseline shard 3, terminal failed candidate attempt 1 and pending retry. `GATES.md` appropriately leaves G5/G6 unchecked. Two final-report updates remain: R `docs/dev-log/after-task/2026-11-06-gaussian-ri-fixed-priors.md:45` still says current-head R checks are running; the Julia counterpart at line 45 should add the passing hosted baseline shard and distinguish original attempt 1 from the live retry. Keep earlier timestamped qualification/reviewer artifacts as historical snapshots rather than rewriting them.

The four configuration files still match the hashes in `protected-state-audit-20261107T0214.json`. That audit's PR/head records remain timestamped evidence; this delta did not re-query GitHub. No protected work or prior receipt was edited. Final reconciliation still needs terminal retry/baseline results, an explicit candidate-failure decision, corrected current reports and exact-head protection checks.

Style self-review: 3/10 perceived AI-like style, moderate confidence; whole technical report reviewed. The platform table separates counts clearly, while the Julia paragraphs necessarily repeat attempt/source distinctions; no repair needed. Science gate: pass within the stated receipt scope, with no calibration or causal attribution claim. Facts gate: pass against the identified logs/metadata and documentation spans. References gate: pass for the local artifact names and source identifiers actually inspected. This is self-review, not independent style validation.
