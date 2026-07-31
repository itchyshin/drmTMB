# After Task: AOI-2D0–D2 pre-prediction diagnostic receipt

## 1. Goal

Implement an internal pre-prediction diagnostic payload for the frozen-margin
Bernoulli x ordinary-NB2 AOI-2 runner; replay a small, deterministic set of
retained AOI-2 seeds locally; and retain an internal receipt. This is a
diagnostic slice only. The AOI-2 point-recovery result remains on HOLD.

## 2. Implemented

`drm_pair_aoi2_diagnostic_payload()` records the association-fit status,
coefficient/eta bounds, likelihood finiteness, all unresolved-status flags,
optimizer and multistart details, score and curvature, endpoint/integration
summaries, and response diagnostics. It is internal and is captured by the
AOI-2 runner before `predict()` is attempted.

The runner now retains fitted association coefficients, diagnostics, and an
explicit prediction status/message when the pre-existing public prediction
fence rejects a `boundary_unresolved` fit. It neither relaxes nor changes that
fence.

## 3a. Decisions and Rejected Alternatives

The payload records observed conditions without assigning one exclusive cause
to an unresolved fit. In particular, hard parameter cap, non-finite
log-likelihood, optimizer convergence, multistart disagreement, weak
curvature, score failure, and NB2 endpoint failure are retained as separate
nonexclusive flags.

Rejected alternatives: reclassifying the 708 retained unavailable attempts
from their generic old prediction error; replaying the full campaign locally;
or using three replays to assert the cause of every failed attempt. A later
diagnostic analysis must work from a separately frozen, sufficiently broad
replay design.

## 4. Files Touched

- `R/associate-pairs.R`
- `tools/run-aoi2-bernoulli-nb2-recovery.R`
- `tests/testthat/test-aoi2-diagnostic-payload.R`
- `tests/testthat/test-aoi2-recovery-dispatch.R`
- `docs/dev-log/simulation-artifacts/2026-07-31-aoi2d0-local-replays-r2/`
- this receipt

No public article, reference documentation, exported API, capability ledger,
generated capability surface, or uncertainty method was changed.

## 5. Checks Run

Focused validation passed:

```text
devtools::test(filter =
  "aoi2-diagnostic-payload|aoi2-recovery-dispatch|associate-pairs-bernoulli-nb2")
```

The deterministic local replays use source commit
`72c97adc77b63fb5e6f907f5b2006606a6afaf19`, with seed lineage retained from
the completed campaign source commit
`b01e94f8d50951f6dd7cd5c1dc02a04b9bd93329`:

| Retained campaign class | Formula, n, replicate, seed | Replay outcome |
| --- | --- | --- |
| interior | `mixed`, 360, 1, 2026308901 | interior; prediction available |
| near-boundary | `numeric_interaction`, 360, 7, 2026508907 | near-boundary; prediction available |
| unavailable | `transformation`, 360, 6, 2026608906 | boundary-unresolved; prediction unavailable |

All three replays retained a finite, all-`ok` NB2 conditional-interval row
summary and a maximum relative integration error below `2.7e-7`.

For the one replayed boundary-unresolved fit, the payload records
`diagnostic_score_failure = TRUE`; hard-cap, non-finite-log-likelihood,
convergence, multistart, weak-curvature, and endpoint flags are false. The
existing prediction error remains `Cannot predict from a boundary-unresolved
association fit.` This is a seed-level diagnostic observation only.

## 6. Tests of the Tests

The focused tests construct an NB2 endpoint failure and a synthetic fit with
every pre-prediction status trigger. They verify that the payload preserves
the flags, optimizer data, endpoint message, score/curvature records, and
row-status labels. The runner test verifies payload capture occurs before the
prediction call and that an unavailable prediction records a separate status.

## 7a. Issue Ledger

No issue or pull request was opened, changed, or closed. This internal
instrumentation does not alter the AOI-2 evidence status.

## 8. Consistency Audit

The implementation keeps the public association object and prediction method
unchanged. `predict.drm_pair_association()` continues to fail closed for
`boundary_unresolved`; no `vcov()`, `confint()`, standard error, profile,
interval, covariance, coverage, or capability route was added.

## 9. What Did Not Go Smoothly

The original campaign records could retain only the generic prediction error,
because prediction was called before fitted association state was copied into
the result row. That limitation cannot be reconstructed from the old rows.
The new payload fixes retention for future diagnostic replays without
rewriting any original campaign artifact.

## 10. Known Residuals

The three replays exercise the three observed outer statuses, not the 3,000
attempt campaign. They therefore cannot estimate trigger prevalence or
explain the programme-wide availability failure. The original AOI-2 result is
unchanged: 14 of 15 cells failed the prespecified interior-availability gate,
and the programme remains **HOLD_NO_POINT_RECOVERY_CLAIM**.

## 11. Team Learning

Fail-closed prediction must not erase the fit-level evidence that led to the
fence. Retaining a diagnostic payload before prediction makes later causal
diagnosis possible while preserving the public no-prediction boundary.

## 12. Cross-Product Coverage

This work covers only internal diagnostic retention and three exact local
replays for the AOI-2 Bernoulli x ordinary-NB2 fixed-effect runner. It does NOT cover formula classes, point recovery, covariance, standard errors,
intervals, coverage, random or structured association effects, missingness,
weights, offsets, other family pairs, or AOI-3.

## Next Actions

Preserve the AOI-2 HOLD. If the owner later authorizes a diagnostic campaign,
freeze a separate replay sample and analysis contract that reports all
nonexclusive trigger flags. Do not begin AOI-3 or change public capability
claims from this receipt.
