# Paired hosted diagnostic outcome review

Verdict: the standalone comparison is verified; prefix qualification is absent. Overall completion remains pending, and the original two candidate CI failures remain unresolved. The new pass does not establish a baseline defect, flake or harmless regression.

Independent Codex, 7 November 2026 UTC. I inspected terminal diagnostic run 42331688804's retained metadata/job log, `hosted-paired-results/`, the original baseline/candidate logs and the decision rules. All evidence paths here are under `/Users/z3437171/.codex/evidence/next-prior-plan-20261106`, except the rules and original CI receipts under R `docs/dev-log/gaussian-ri-priors-20261106/hosted-ci-baseline/`. R is `/Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB`. No fit, test, agent or GitHub write was started; only this report was authored.

## Artifact and outcome audit

The terminal metadata records completed/failure at diagnostic source `108792b0d3b34665aebb06a7ff7541e2d8808c5a`. The job log records all four starts/finishes and successful artifact upload. All twelve payload hashes in `QUALIFICATION.json` match actual files, including both zero-byte logs, the result table, four environment files and three machine/runtime files. The qualification sidecar is additional metadata.

| Source/mode | Exit | Elapsed seconds | Verified result |
| --- | ---: | ---: | --- |
| Baseline `86ee1c2a`, standalone | 0 | 246.55 | 44/44, standalone-complete marker |
| Candidate `385fde27`, standalone | 0 | 217.37 | 44/44, standalone-complete marker |
| Baseline, prefix | 124 | 1,200.09 | Empty log; no fit or prefix result |
| Candidate, prefix | 124 | 1,200.10 | Empty log; no fit or prefix result |

`results.json` retains all four distinct combinations. Both prefix hashes are the empty-file SHA-256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`. These are timeouts in the denominator, not original assertion failures or successful prefix executions. Configured source paths are recorded for both; actual loaded paths are observable only in the standalone logs.

The two Projects and two Manifests are semantically identical after normalizing the DRModels checkout paths. The Manifest matches the frozen prefix dependency environment under that same substitution, including 118 other dependency records. Both standalone logs identify the intended loaded package, Julia 1.13.3, `CPU_NAME=emeraldrapids`, one Julia thread and ILP64 OpenBLAS with one thread. This controls the runner for the completed pair, without establishing CPU/library equivalence to the earlier CI jobs.

Both original victim hashes equal `57788efeecc74c2d7bef374446f2c335194754a22de033da8965feab1e31d5a5`; I also reproduced that hash from each immutable source's Git blob. Both data hashes equal `50282830f7316c3426fd9bb10870ce37dbb7985a99d64aba2b19a691c3ef4ebe` before comparing fit results. The eight recorded diagnostic fields match exactly, including explicit parameter bitstrings, iteration count 53, objective `532.9732053643258` and gradient maximum `6.368950922208683e-9`. Extreme SD coefficients `-35.316914102114715` and `34.17616262509883` accompany singular-Hessian warnings and recorded reciprocal condition `6.827653639066237e-17`. Those warnings remain part of the result; matching point estimates do not establish reliable Wald uncertainty or a well-identified interior optimum.

The original hosted baseline test passed 44/44. Candidate attempts 1 and 2 each failed the existing `slope_fit.converged` assertion, with reciprocal condition `5.752216336949239e-17` reported in their logs. All three retry qualification hashes match. Parsing the baseline/retry package listings independently gives 118 named versions and no differences. Equal listed versions do not identify the original CPU, BLAS binary, compilation flags or fit trajectory. Condition-number differences alone do not identify the failed convergence condition.

## Decision rules and diagnostic limitation

The standalone result follows the rules' `both_pass` branch: the earlier failure remains unreproduced in this completed mode. Both prefixes follow `timeout`: preserve them and do not close qualification. Neither timeout satisfies `baseline_and_candidate_fail`, because no original assertion outcome was observed. The earlier hosted baseline-pass/candidate-fail evidence still requires potential-regression investigation.

The rules file says it was recorded at 03:15:05 UTC. The job log shows both standalone attempts finished by 03:05:16, while the final prefix ended at 03:45:17. Thus these rules were recorded before the terminal result, but after the standalone outcomes were available. Their conservative interpretation is appropriate; they cannot be described as fully blinded, pre-result rules for the standalone comparison.

A material configuration mismatch is verified in the raw logs: original baseline and retry CI precompiled with `--code-coverage=@/home/runner/work/DRModels.jl/DRModels.jl`; this diagnostic used `--code-coverage=user`. Those configurations differ in coverage scope and may differ in dependency compilation cost. Cold JET compilation under broader instrumentation is a plausible explanation for the prefix delay, not a demonstrated cause. The empty logs localize nothing: the runner does not flush phase output before reaching fit diagnostics, and startup imports precede the first log message. Python restores the victim after timeout, but kills only the direct Julia process; surviving precompile children could affect the next attempt. The artifact contains no process-tree receipt proving that happened or proving it did not.

## One next experiment

Run one **prefix-only baseline/candidate pair with the exact CI coverage scope**, on one hosted machine with the same frozen environments and unchanged assertions. Use `--code-coverage=@<that checkout root>` and the remaining recorded CI compilation flags. Keep CPU/BLAS settings fixed and record the actual loaded BLAS library identity; a CPU/BLAS sweep would add factors before the prefix has produced any usable outcome.

Make this a localized compilation-versus-fit experiment: flush timestamped stderr milestones before imports, around package/JET precompilation and before/after each included test file, then retain the same parameter/data/gradient diagnostics at the victim. Record precompile completion separately from test completion. Start each attempt in its own process group, terminate and reap the whole group on timeout, and verify no child remains before the other source starts. Retain the existing bounded budgets and all failures; do not extend time blindly. If compilation still exhausts the budget, report an identified setup/compilation limit rather than a fit failure. If both prefixes reach the victim, apply an explicitly frozen outcome table to their original assertion and numerical diagnostics. This single pair addresses the missing prefix comparison while testing the concrete coverage mismatch; it does not presume that mismatch caused the original candidate failure.

Style self-review: 3/10 perceived AI-like style, moderate confidence, whole technical report. Located strengths are the four-attempt table and the explicit rule-timing paragraph; both prevent positive results from swallowing missing evidence. Science gate: pass within this receipt scope, with causal and uncertainty limits retained. Facts gate: pass against inspected hashes, logs and parsed manifests. References gate: pass for the local artifact names and source identifiers used. No independent style evaluation was performed.
