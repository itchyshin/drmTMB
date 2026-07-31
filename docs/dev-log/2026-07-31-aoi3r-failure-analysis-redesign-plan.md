# AOI-3R plan-only failure analysis and redesign

```text
PLATFORM: Codex. Redesign the private Bernoulli x ordinary-NB2 AOI-3
full-refit uncertainty smoke after its all-formula local gate failed. HEADLINE:
retain pre-prediction association diagnostics and private derivative-ladder
detail before any new full refit, so a failure is classified rather than hidden
or chased by seed choice. IN PARALLEL: exact retained-evidence audit and
fail-closed smoke-contract design. DEFER: all new fits, DRAC, estimator/tolerance
repair, public API/docs/ledgers, vcov/confint, intervals, and public inference.
DISCIPLINE: new immutable source/seed map; no pooling/reclassification; a new
owner approval is required before any local smoke.
```

## Status

**PLAN ONLY — no local replay or DRAC action is authorized by this document.**
It is the prospective successor to the failed AOI-3 smoke at source SHA
`e9a24c30350ca3b5c5fc783ae161840ded905a23`.

## Retained evidence and what it does—and does not—diagnose

| Route | Retained fact | What follows | What does not follow |
| --- | --- | --- | --- |
| additive outer | association `boundary_unresolved`; final alpha estimates are not at the hard cap; private sandwich withheld as `association_unresolved` | the outer point-fit eligibility gate failed | the old output cannot distinguish score, curvature, multistart, convergence, or endpoint trigger because the runner did not retain the association payload |
| factor interaction outer | association point fit interior; private sandwich withheld as `association_step_unstable` | the fixed `h = 1e-2` versus `h/2` derivative ladder failed its stability rule | a different step/tolerance is not justified without a separate oracle study |
| transformation inners 2 and 4 | association `boundary_unresolved`; sandwich withheld as `association_unresolved` | two inner full-refits failed eligibility | their cause is unknown from the retained AOI-3 rows |

This is consistent with AOI-2D3: sampled `boundary_unresolved` rows commonly
carried nonexclusive score-failure flags, but that stratified diagnostic sample
does not identify the cause of these new AOI-3 rows.

## Team-raised constraints

- **Fisher:** retain status, all nonexclusive association triggers, multistart
  values, optimizer state, and numerical/endpoint diagnostics before any
  prediction/refit continuation; never treat unavailable fits as recoverable
  evidence by omission.
- **Rose:** existing failure labels have unknown cause unless payload is
  retained; a new diagnostic run must be immutable and cannot reclassify or
  replace AOI-2/AOI-3 results.
- **Ada:** an interior association estimate and an available uncertainty
  calculation are separate gates. The factor-interaction failure makes that
  distinction operationally essential.

## AOI-3R0 instrumentation contract (future implementation, not this plan)

For every outer and every scheduled inner attempt, record before deciding
eligibility:

1. association status, coefficients, alpha/eta, log likelihood, complete
   multistart objectives and coefficient matrix, optimizer code/message;
2. each nonexclusive association trigger: hard cap, non-finite likelihood,
   convergence, multistart disagreement, weak curvature, score, endpoint;
3. private sandwich status/reason and, where derivatives run, per-row maximum
   step difference and scale, failing-row index/count, and component labels;
4. margin `pdHess`, formula/design fingerprint, source SHA, outer/inner seed,
   original-row count, and stage at which an attempt became unavailable.

The instrumentation has no public entry point. It does not alter the objective,
optimizer starts/bounds, sandwich control, numerical tolerance, formula grammar,
or status classification. It must have forced tests for every retained trigger,
including the intentional association/prediction failure path.

## Proposed fresh-seed diagnostic smoke contract

The next local action, if separately approved, is **AOI-3R1 diagnostic smoke**,
not uncertainty calibration. It uses all five AOI-1 formula classes at `n=720`,
three fresh outer IDs per formula, and three fresh inner IDs for every scheduled
outer attempt. Its deterministic seed map must be derived and SHA-checked before
execution, with zero overlap against AOI-2, AOI-2D3, and the failed AOI-3 smoke.

It is fail-closed in two ways:

1. every one of the 15 outer and 45 scheduled inner rows is retained, including
   `not_eligible` rows with an explicit outer-stage cause;
2. it may authorize neither DRAC nor an estimator/tolerance repair. Its only
   pass is a complete, single-SHA diagnostic payload with no schema/seed/row
   mismatch. Availability and derivative outcomes are results to review, not
   seed-selection criteria.

This deliberately does not call a low failure count a pass. If no formula has
enough private-sandwich-available outer fits for a later calibration design,
AOI-3R ends with negative evidence rather than selecting a more favourable
formula or seed.

## Decision ladder after a future AOI-3R1 receipt

| Finding | Next permissible decision |
| --- | --- |
| failures chiefly association score/curvature/multistart | owner may commission a separate model-identifiability/estimand review; no tolerance change is implied |
| failures chiefly derivative-step instability while association fits are interior | owner may commission an oracle-only derivative study, comparing a proposed numerical change against independent row-kernel derivatives; no calibration yet |
| diagnostics complete and availability sufficient across every frozen formula | owner may approve a new AOI-3R2 uncertainty-smoke contract with fresh seeds |
| missing payload, mixed SHA, seed overlap, or schema mismatch | fail closed; repair instrumentation/contract only, then rerun a new diagnostic smoke |

No branch of this ladder authorizes DRAC, `vcov()`, `confint()`, standard errors,
intervals, public documentation, a capability change, or a public association
inference claim.
