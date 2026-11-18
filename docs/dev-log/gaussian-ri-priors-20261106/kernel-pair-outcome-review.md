# Kernel-pair outcome audit and gate adjudication

Verdict: YES. This establishes a bounded pre-existing, kernel-sensitive failure sufficient for G5's explicitly adjudicated baseline-exception path and qualification of the approved prior-only draft PRs for review. Repairing the old binomial fixture is not a prerequisite for this slice. G6 final reconciliation remains required. Original candidate CI stays red; this report authorizes no merge or release.

Independent Codex, 7 November 2026 UTC. I read `APPROVED-PLAN.md`, the current `GATES.md`, all kernel-pair artifacts and their copied R receipts. The kernel artifacts are under `/Users/z3437171/.codex/evidence/next-prior-plan-20261106/kernel-pair/`; the R gate and receipt root is `/Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB/docs/dev-log/gaussian-ri-priors-20261106/`. No fits, tests, agents or GitHub writes were performed. Only this external report was authored.

## Verified controls and outcomes

All fourteen hashes in `QUALIFICATION.json` match actual files, including the four raw logs, controller/probe, plan, runtime/source records and environment files. All fifteen files copied into R `hosted-ci-baseline/kernel-pair/` match the external originals byte for byte. All four prescribed cells and their nonzero failures remain in `results/results.json`; none timed out or reported a diagnostic-gradient exception.

| Actual OpenBLAS core | Pre-slice baseline `86ee1c2a` | Candidate engine `ff10a2f9` | Maximum recorded gradient |
| --- | --- | --- | ---: |
| Cooperlake | 44/44, exit 0, converged | 44/44, exit 0, converged | 6.368950922208683e-9 |
| Haswell | 43/44, exit 1, not converged | 43/44, exit 1, not converged | 3.112200773758289e-7 |

Each Haswell log contains exactly one original assertion failure, `slope_fit.converged`; there is no second failed assertion or added prior. Each Cooperlake log has no failed assertion. The original fixture/seed is retained: all four original-victim hashes equal `57788efeecc74c2d7bef374446f2c335194754a22de033da8965feab1e31d5a5`, and all data hashes equal `50282830f7316c3426fd9bb10870ce37dbb7985a99d64aba2b19a691c3ef4ebe`.

The probe checks the actual loaded library core through `openblas_get_corename64_`; all four expected/actual core pairs agree. The logs identify the same `znver5` host target, one Julia thread, one BLAS thread, intended loaded package paths and common OpenBLAS library path. The driver fixes the Julia executable and other command flags while changing the kernel environment setting. `RUNTIME-IDENTITY.json` supplies binary/library and reviewed wrapper hashes; I verified the identity record's hash and its consistency with the local controller/probe/environment files, without independently rehashing remote binary bytes.

Projects and Manifests are semantically identical after normalizing source paths, and their dependency entries match the frozen reference, including 118 other records. The post-run source record identifies baseline `86ee1c2a` and candidate `ff10a2f9`, original victim bytes and empty source/victim differences. I also confirmed that the candidate's PR documentation head `385fde27` differs from `ff10a2f9` in none of `src`, `test`, Project or Manifest.

Within each core, the two sources have exactly the same eight recorded fit/identity fields, including explicit parameter bitstrings, plus the same condition diagnostics. Cooperlake gives 53 iterations and reciprocal condition `6.827653639066237e-17`; Haswell gives 52 iterations and `5.752216336949239e-17`. Both objectives are essentially equal despite different trajectories along a near-singular variance configuration. That is not a reason to override the honest convergence flags or weaken the assertion.

## Why G5 can close with this exception

G5 already permits measured suites that “pass or have explicitly adjudicated baseline failures.” The approved plan requires one measured full-suite pass per final source; that work was independently qualified earlier: repaired-source Julia 1.10.12 covered all 561 selected files over eight successful shards, R's full/source-tree checks passed, and the frozen 36 comparisons plus 87-expectation live receipt passed. This four-cell diagnostic does not replace those suites or reduce the planned prior-validation coverage.

The new experiment supplies the missing baseline adjudication for the specific additional unpenalized binomial failure. The unchanged pre-slice source fails the unchanged assertion under the verified Haswell kernel, and the prior candidate reproduces its complete recorded numerical result within that kernel. Both pass under the verified Cooperlake kernel. Together with the earlier source-path trace, this demonstrates that adding Gaussian coefficient-prior support is not necessary for this failure and reveals no source-dependent difference in this controlled experiment. It supports a bounded numerical-backend-sensitive baseline exception, rather than an assertion repair inside the unrelated prior feature.

The historical attribution limit remains exact. Haswell reproduces the assertion and condition value seen in both original candidate CI failures. Those jobs did not record their actual OpenBLAS kernel, so the match is consistent with this mechanism without proving their kernel was Haswell or proving every historical failure had this cause. Record the original CI attempts as failed, with their raw evidence retained. The exception adjudicates the demonstrated pre-existing failure class; it does not turn those workflow conclusions green or establish universal backend robustness.

## Required remaining work

1. Record this explicit exception in G5 with both sources, actual kernels, four outcomes and the historical-attribution limit. Keep all failed attempts and the frozen oracle/threshold history. No further fit campaign or binomial fixture change is required to qualify the approved prior slice for draft review.
2. Finish G6: commit only owned evidence/documentation, reconcile STATE, after-task reports, check logs and draft PR descriptions to the final qualified-with-exception status, and preserve older reviewer reports as source/timestamp-bound snapshots. Current wording that still calls baseline jobs or paired diagnostics live needs updating. Link the kernel receipt and this independent adjudication; do not describe the original candidate CI as passing.
3. Verify final production/test/project equivalence to R `5d0f1596` and J `ff10a2f9`, refresh final artifact/source links, and recheck the four protected dirty configuration files and PR #1651 head protection. Keep both prior-only PRs draft, isolated and unmerged. Track any binomial boundary-fixture/optimizer robustness repair separately, preserving its original failure evidence and scientific purpose.

The remaining work is final evidence and review reconciliation, not a missing mathematical or numerical validation of the approved Gaussian prior route. Merge/release readiness remains outside this verdict.

Style self-review: 3/10 perceived AI-like style, moderate confidence, whole gate review. Located strengths are the four-cell table and the distinction between a demonstrated baseline exception and unknown historical hardware. Science gate: pass within this controlled comparison and approved scope; no coverage, posterior or universal-stability claim is made. Facts gate: pass against inspected files/hashes and prior independently qualified receipts, with remote binary verification explicitly bounded. References gate: pass for the local evidence paths and exact gate wording. No independent style evaluation was performed.
