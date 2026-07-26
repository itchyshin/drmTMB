# Arc D — scale-clamp and profile-identifiability contract: ultra-plan

**Status:** plan-only · **Date:** 2026-07-26 · **Depends on:** Arc C / PR #845
**Owners:** Fisher (inference contract), Gauss (numerics), Noether (objective/profile consistency), Rose (closeout)

```text
🎯 GOAL
Decide, before implementation, what a scale clamp may do to profile-likelihood
endpoints for `sd()` regression parameters. Preserve the known K=12
non-identification signal; do not mistake a finite clamp-shaped endpoint for
information from the data.
```

## Decision context

Arc B identified nine unguarded `exp()` sites for regression-predicted log-SDs.
Arc C tested the tempting repair of reusing the residual `logsigma_clamp` band
at those sites. It was correctly reverted: in the dense K=12 meta-V LSS
negative control, the default band produced a finite profile interval for a
non-identified direct-SD slope, while an effectively inactive band restored
`profile_failed`. The finite endpoint was therefore bound-induced false
precision, not a numerical repair.

This arc is a contract decision, not an implementation authorization.

## Hard fences

- Do not edit the nine `sd()` predictor sites in this arc's plan phase.
- Do not change `interval_status`, the capability ledger, or public inference
  until the owner approves a selected design.
- Do not launch the 177-cell interval campaign, simulation, recovery, coverage,
  bootstrap, or full-refit study.
- Do not expose PR #846's private association sandwich engine through `vcov()`,
  confidence intervals, profiles, `confint()`, or public documentation.
- Do not treat a finite interval as identified merely because a clamp bound was
  reached.

## Prior-work sweep receipt

| Source | What is reusable | What it rules out |
| --- | --- | --- |
| `docs/dev-log/after-task/2026-07-25-arc-b-cpp-numerical-audit.md` | The nine-site audit finding and its deliberately low-to-medium, plausible status | Calling overflow demonstrated or silently repairing it as a routine numerical defect |
| `docs/design/170-sigma-phylo-conditioning-and-logsigma-clamp.md` | Existing residual-scale clamp semantics and control surface | Assuming residual-scale stability semantics automatically transfer to profile endpoints for `sd()` slopes |
| `docs/design/241-arc7b-meta-v-heterogeneity-ladder-contract.md` | The dense K=12 negative control and fail-closed profile contract | Promoting an interval merely because a profile returns finite numbers |
| `docs/design/245-f5-sd-regression-clamp-and-identifiability.md` | The decisive clamp-on/off experiment and three candidate designs | Reusing the tight residual clamp unchanged at all nine sites |
| PR #845 / Arc C report | A5/A7 are independent; F5 was reverted | Bundling F5 into a numerical-hardening closeout |

No external literature search is required to select the internal API and
identifiability contract. If a later selected design makes a new methodological
claim, perform a focused literature check before public wording.

## Planned slices and gates

### D0 — contract inventory (read-only)

Map all nine `sd()`-predictor `exp()` sites, every route that evaluates them in
fitting and profiling, and every consumer of `interval_status` / profile
completion. Produce a single equation-to-source map and classify each site as
fit-only, profile-only, or shared.

**Gate:** Fisher, Gauss, and Noether agree that the map includes the dense K=12
negative-control path. No code change.

### D1 — design decision (read-only)

Compare only these three designs, using the K=12 negative control and a stable
interior control as required discriminators:

1. A pure overflow guard near floating-point overflow (about `+/-700`), without
   pretending to supply the residual clamp's inner-Laplace conditioning.
2. A tight clamp with an explicit `clamp_limited` interval outcome whenever an
   endpoint is shaped by the bound.
3. A clamp during fitting but an unclamped profile objective, with an explicit
   accounting of objective comparability and endpoint failure modes.

For each, state the exact user-facing status, ledger consequence, negative
control result, diagnostics, testable invariants, and rejected alternatives.

**Owner decision gate:** Shinichi selects one design in writing. Without that
approval, stop after D1 and hand over the comparison.

### D2 — selected-design implementation (requires a new approval)

After approval only, make one narrow implementation PR with matching C++/R
contract, regression tests that distinguish pre- and post-change behavior, and
updated design/API documentation. Falsifying tests must not be described as
behavioural proof when they pass against the pre-change kernel.

**Gate:** Noether verifies identical mathematics across symbolic statement, R
status handling, and the TMB template; Fisher verifies that a clamp-limited
endpoint cannot enter any interval-ready or coverage gate as an ordinary `ok`
interval.

### D3 — validation and closeout (separately compute-gated)

Run local sentinel tests first. Any simulation, profile campaign, full-refit
comparison, or coverage/recovery study needs fresh owner approval and runs on
Totoro or DRAC, never GitHub Actions. Retain all attempts and keep the K=12
historical failure as a negative control.

## Acceptance conditions for the plan phase

1. A reviewer can trace every one of the nine sites to its fit/profile status
   consumer.
2. The chosen design has an explicit result for both the K=12 historical
   failure and a stable interior control.
3. Public `confint()` semantics and ledger gates cannot misclassify
   clamp-shaped false precision as ordinary identified inference.
4. Arc C's A5/A7 closeout remains independent; this plan does not reopen F5 by
   implication.
5. The private association sandwich implementation remains private pending its
   separately approved validation program.

## Review plan

Use Fisher first for the inferential contract, Gauss for numerical/objective
semantics, Noether for source-to-mathematics alignment, and Rose for the final
scope and handover audit. The plan review must record any disagreement before
D2 is proposed to the owner.

### Phase-0 review receipt and model routing

The pre-plan Fisher and Rose reviews agreed that Arc C should close before this
arc starts; both required the K=12 negative-control interpretation to remain
load-bearing. Fisher's review additionally fenced the private association
sandwich engine from public validation. The live Codex roster exposed
`gpt-5.6-terra` and `gpt-5.6-sol`; no Luna selector is available in this
session. If D0 is dispatched, use Terra for mechanical source inventories and
Sol for the Fisher/Noether decision review. No agent should implement D2 before
the owner decision gate.

## Exact next action

First close PR #845 only after its exact-tip CI is green and its F5 reversion
is retained. Then start D0 read-only on a fresh branch from merged `main`; do
not implement a candidate design without the D1 owner decision.
