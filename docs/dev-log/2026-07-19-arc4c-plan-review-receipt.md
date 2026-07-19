# Arc 4c pre-compute plan-review receipt

## Scope reviewed

Fisher and Rose reviewed the frozen three-family S0 and the full two-PR decomposition before PR-A implementation. The review covered the estimands and DGPs, all-attempt denominator, smoke selection, physical shard bijection, Fir limits and thread pins, deterministic resume, evidence gate, ledger boundary, and the compute-approval stop.

## Fisher — PASS after method corrections

Fisher required and ratified these corrections:

- primary coverage is `hits / n_attempted`; noncomputable intervals are noncoverage, while conditional-on-finite coverage is diagnostic only;
- an M=8 smoke failure excludes only M=8, but any non-exploratory smoke failure halts that family;
- M=64 is the positive control and an acceptable non-exploratory set must be a contiguous suffix ending at M=64;
- synthetic tests must include a fit error, bad Hessian, nonfinite profile, duplicates, and missing manifest rows;
- 120 ten-seed shards per approved logical cell are valid if every replicate resets `set.seed(202607190 + r)` and aggregation proves the exact `r=1:1200` bijection;
- conservative overcoverage may support `inference_ready_with_caveats` but is never called nominal.

Final Fisher verdict: **PASS for PR-A implementation; no compute authorization.**

## Rose — PASS after systems corrections

Rose required and ratified these corrections:

- work only in a fresh named worktree from fetched `origin/main`; never broadly copy or stage the dirty root;
- make smoke selection and expected denominators mechanical, including the distinction between an N=1 M=64 smoke and an N=1200 positive-control campaign rung;
- define shard `k` as exactly `r=10(k-1)+1:10k` and reject any union other than `1:1200` per approved cell;
- re-read `MaxArraySize`, partition deterministically when needed, cap total concurrency at 96, and fail before submission if more than 96 partitions would be required;
- treat PR A as its own completed infrastructure phase with checks, after-task, merge-SHA verification, and handoff before Gate A.

Final Rose verdict: **PASS for PR-A implementation; no compute authorization.**

## Maintainer disposition

Shinichi approved implementation of the ultra-plan on 2026-07-19. Under the plan's explicit boundary, this authorizes PR A but not the Fir smoke or certification array. Gate A remains a separate maintainer decision after PR A is merged and its exact `origin/main` SHA is verified.
