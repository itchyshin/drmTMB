# Arc 6 F3 — Bernoulli x ordinary-NB2 provenance success receipt

## Authorization

Before execution, the owner approved exactly:

> I approve exactly one local Arc 6 F3 Bernoulli × ordinary-NB2 provenance
> smoke at source SHA 2418d847b45891b09f719932e75985101be50116, using
> tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R and its immutable
> output directory. This approves no retry, F4, public inference, or API
> exposure.

## Execution

One clean detached worktree at the approved SHA invoked exactly:

```sh
Rscript --vanilla tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R --expected-sha=2418d847b45891b09f719932e75985101be50116 --out-dir=docs/dev-log/smoke/2026-07-26-arc6-f3-2418d847b458/attempt-001
```

The source SHA and both F1M-critical blobs matched before invocation. This is
the only attempt directory for that SHA.

## Immutable outcome

`status.csv` records `terminal_stage = complete` and
`terminal_status = success`. The DGP, Bernoulli margin, ordinary-NB2 mean and
dispersion margin, association, rectangle, sandwich, and delta stages are
`ok`; `interval` is `not_attempted`. The serialized dataset SHA-256 is
`e05ceb6cb67b7e152c9d8f0aef0837d63db543ca96ce01a0f20ece2916b47bd1`.

All artifact hashes in `metadata/artifact-sha256.tsv` were recomputed with
`shasum -a 256` and matched. The focused runner-contract suite passed with 57
expectations after the receipt was produced.

## Independent disposition

Three fresh read-only D-43 lenses reviewed provenance, inference boundaries,
and contract compliance. All returned DONE for the narrow claim:

> One staged full-refit Bernoulli x ordinary-NB2 F3 provenance smoke completed.

The reviewers required this durable authorization record. They did not approve
or infer empirical-SD calibration, SE validity, interval validity, recovery,
coverage, capability movement, public readiness, F4, or API exposure.

## Boundary

The retained `private/sandwich.rds` records a private successful computation;
its availability flags are not calibrated uncertainty evidence. This receipt
does not make a joint-MLE claim: it is a staged fixed-effect provenance smoke.
No retry occurred.
