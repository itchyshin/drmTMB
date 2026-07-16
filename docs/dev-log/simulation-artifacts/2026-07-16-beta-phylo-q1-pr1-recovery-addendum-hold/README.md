# Beta phylogenetic q1 recovery addendum: HOLD

This directory preserves the separately predeclared `m = 4` replication
addendum exactly as produced on Totoro. It does not replace or relax the
original `m = 2` HOLD.

**Provenance erratum:** after this HOLD was banked, a complete seed-set audit
found that 1,197/1,200 numeric DGP seeds overlap the original campaign because
the offset masters differed by only one. The result remains an immutable HOLD,
but it is not fresh independent evidence. A separately committed design
repairs seed provenance without changing any gate.

## Provenance

- Source commit: `b6f74622d5c1041e438d7ac8b1ce654a40a55bc3`
- Runner: `tools/run-beta-phylo-q1-recovery.R --mode=addendum`
- Host: Totoro
- Parallelism: 32 R workers, BLAS threads pinned to one
- Master seed: `2026071602`
- Grid: `g = 64, 256, 1024`, `m = 4`, 400 attempts per cell
- Retained denominator: 1,200/1,200 uniquely keyed attempts

## Frozen-gate result

All fits succeeded with convergence code zero. Positive-definite Hessian rates
were 0.9975, 0.995, and 1.000 for `g = 64, 256, 1024`. Both fixed-slope bias
gates passed in the two certification cells, the `g = 1024` mean log-`tau`
bias gate passed at `0.0618`, and every RMSE non-increase gate passed.

The campaign is nevertheless a **HOLD** because the predeclared `g = 256`
absolute mean log-`tau` bias was `0.2470`, above the frozen `0.10` threshold.
Three of 400 fits in that cell were boundary-flagged. Removing them after the
fact would not rescue the frozen verdict; even the descriptive non-boundary
mean log-`tau` bias was `-0.1683`. The raw-`tau` and median summaries are
diagnostic only and do not replace the predeclared mean log-scale gate.

Together, the original and addendum campaigns show improving recovery with
more species and more within-species replication, but neither authorizes the
planned `point_fit_recovery` ledger promotion across its frozen ladder. No
further campaign, threshold change, or direct-`sd()` PR follows automatically
from this result.

## SHA-256

```text
3c4d1eb2826f17d936fc85a07e7096166527ede00bb2e3901feacb5c2955503c  design.tsv
e9cf03b84a5195bbd8c71ae685dcae9ba3f80d6475ec8bb85eaab79793efb145  gates.tsv
c0649b852b6a75903ad760eedbfae30445f2543d31d36cc7216f0053be6b3646  raw-attempts.tsv
e12d8211087d2c9af357b7dd0d402674f7ba230f9cd08c18e86f3fcbbe0e8b54  rmse-difference.tsv
7c3faefc23dc093463e2bd690ff7515b4afab749eec19f2e275072336214e726  session-info.txt
f3f0bd033e910eeeb0c39b78bae69837ee3b2c18d7e6088edab0fada97fe6c38  summary.tsv
```
