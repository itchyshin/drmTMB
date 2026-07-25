# Handover: Arc 7B known-`V` heterogeneity ladder

## State

Branch: `codex/arc7b-meta-v-heterogeneity-ladder`.

The implementation snapshot is `f86fed0188ca14356bc098d962e2675e22c39593`.
It adds local-only L/LS/LSS/LSSS/DH evidence machinery. The accompanying
closeout documents record the final no-go.

## What the next session must know

The six-cell source-pinned local sentinel retained all fits. Dense LSS has
clean convergence/`pdHess` but both direct-SD coefficient profiles are
`nonfinite_interval`. This is negative interval-feasibility evidence. Fisher
and Rose both returned DRAC NO-GO. Do not submit remote compute, replace the
profile procedure, calculate coverage, promote a cell, or claim reader-ready
layered meta-analysis.

DH is distinct from LSS: it randomizes log residual SD. It is not validated by
the additive Gaussian direct oracle and has fitting/extractor smoke evidence
only. The DGP now uses genuinely nested effect IDs with two repeated rows per
effect; do not regress to unique observation labels.

## First reads

1. `docs/design/241-arc7b-meta-v-heterogeneity-ladder-contract.md`
2. `docs/dev-log/evidence/2026-07-24-arc7b-meta-v-heterogeneity-ladder-local-sentinel.md`
3. `docs/dev-log/after-task/2026-07-24-arc7b-meta-v-heterogeneity-ladder.md`
4. `inst/sim/run/sim_run_meta_v_lss_smoke.R`

## Resume only with a new goal

Start a new, explicitly approved interval-engineering arc. It must define a
dense direct-SD target that has a finite profile route, add endpoint/
`tmbprofile` agreement and bootstrap completion accounting, re-run the local
sentinel on a committed source SHA, and obtain Fisher/Rose review before a
separate DRAC approval. Draft PR #828 (`codex/arc7-metav-b0`) remains open,
draft, and unmerged; it is not part of this branch.
