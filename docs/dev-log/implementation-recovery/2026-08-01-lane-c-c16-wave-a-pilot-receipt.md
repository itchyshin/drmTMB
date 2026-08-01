# C16 Wave A pilot receipt — phylo and animal

## Scope

This receipt covers the first three exact leaves only: `mc-0583` (zero-one-beta
`mu` phylo q1), `mc-0593` (zero-one-beta `sigma` phylo q1), and `mc-0584`
(zero-one-beta `mu` animal q1).  It is not a ledger transition and does not
transfer evidence to another provider, endpoint, or q-gate.

## Source

- Recovery-runner isolation: `24772ebc22aa54db7ce6cb20887c1f018fd7cf3b`.
- Strengthened phylo-mu oracle/telemetry: `0ea56a9970250c2deae178f0f8a2b5520b2c408e`.
- The C16 worktree was clean before the source-pinned phylo reruns; receipt
  directories were then created as untracked local evidence.

## Results

| Cell | Result | Decision |
| --- | --- | --- |
| `mc-0583` | Four/ four source-pinned phylo-`mu` fits converged, had positive-definite Hessians, gradients below 0.01, non-boundary SDs, mode correlations above 0.90, and an unclamped fixed `log_sigma` range. | **BLOCKED from promotion** pending a retained fixed/IID comparator and current-source oracle command receipt. |
| `mc-0593` | Four/ four source-pinned phylo-`sigma` fits pass convergence, Hessian, gradient, mode, support, clamp, boundary, and SD-error gates. The zero-SD run is retained as diagnostic-only. | **BLOCKED from promotion** pending explicit cell/endpoint/DGP metadata, unclamped-range record, fixed/IID comparator, and oracle command receipt. |
| `mc-0584` | Run 1 retained four formula-environment failures.  The narrowly repaired runner's Run 2 has four/ four passing fits at source `191961219`. | **BLOCKED from promotion** pending the same complete control/oracle receipt as the other leaves; the failed run remains in the denominator. |

The other seven exact leaves also have source-pinned four/ four local passes:
`mc-0585`–`mc-0587` (`mu`) and `mc-0594`–`mc-0597` (`sigma`).  Their raw
receipts are retained separately.  This extends the local fixture evidence;
it does not satisfy their individual source-equivalence, control, and fresh
review gates.

The pre-commit `mc-0583` smoke directory is retained but excluded: its source
SHA precedes the runner commit.  The committed-source rerun is the only
candidate recovery evidence.

## Independent review

Fresh Fisher, Noether, and Rose reviews unanimously block promotion.  Their
common finding is not an invalid carrier: `mu` correctly receives the phylo
field and `sigma` correctly receives it on the log-sigma scale.  The missing
elements are source-bound full-oracle execution, complete control telemetry,
and tracked receipt integration.  No review licenses profiles, intervals,
coverage, or a q2-plus companion row.

The source-pinned Wave A oracle/finite-difference/dependency suite now passes
for every exact leaf in `2026-08-01-lane-c-c16-wave-a-oracle-tests-run-4`.
Earlier oracle runner attempts are retained: run 2 records the shell-quoting
failure and run 3 is superseded because its command label was inaccurate.  Run
4 is the admissible oracle-command receipt.

A separate eight-attempt IID control (four `mu`, four `sigma`) passes at source
`a04f086bd`; it validates the shared endpoint carriers without substituting
for any provider-specific structured recovery result.

## Next bounded repair

1. Add a current-source oracle-command receipt and fixed/IID controls for the
   two phylo leaves.
2. Correct only the animal formula object binding; rerun all four attempts.
3. Add current-source oracle-command receipts and matching fixed/IID controls
   for every one of the ten exact leaves.
4. Re-review each leaf independently before any ledger edit.
