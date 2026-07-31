# AOI-3R1 diagnostic-smoke contract

## Status

**NOT EXECUTABLE WITHOUT A FURTHER OWNER APPROVAL.** This replaces neither the
failed AOI-3 smoke nor its retained outputs. It defines a diagnostic-only
successor with fresh immutable provenance.

## Fixed scope

- Pair: frozen-margin, complete-pair Bernoulli x ordinary-NB2.
- Margins: existing fixed-effect ML `binary ~ x1 + x2` and
  `count ~ x1 + x2, sigma ~ 1`.
- Association formulae: additive, mixed, factor interaction, numeric
  interaction, transformation; no random/structured effects, missingness,
  weights, offsets, REML, or new family pairs.
- Per formula: `n = 720`, three outer attempts, three scheduled inner attempts
  for each outer; 15 outer and 45 inner rows total.

## Fresh-provenance requirements

Before a run, freeze in a committed manifest:

1. a new source SHA and runner/schema hash;
2. all 60 seeds, proven unique and disjoint from the prior AOI seed manifests;
3. formula truths, factor levels, fixed new-data rows, and exact association
   design fingerprints;
4. the AOI-3R0 payload schema and failure taxonomy.

The committed AOI-3R2 manifest is
`docs/dev-log/simulation-artifacts/2026-07-31-aoi3r2-diagnostic-manifest/manifest.csv`.
It is a run authorization boundary, not evidence that the successor ran.

The runner must first attach a valid outer payload whenever the outer fit
exists, including when its sandwich is unavailable. Each scheduled inner row
then either records its own payload (`diagnostic_payload_origin = "inner"`) or
inherits that valid outer payload (`"outer"`) with an explicit eligibility
reason. An outer failure before a valid payload is not repaired or inferred;
the corresponding inner row remains payload-less and invalidates the run.

The result root must be new and immutable. Every outer and inner row records
the payload before any prediction, sandwich, or eligibility decision. The
runner must continue to record an inner row after an outer failure as
`not_eligible` with that outer's explicit payload reason.

## Pass/fail boundary

`AOI3R1_DIAGNOSTIC_COMPLETE` requires only: all expected rows are present,
every row has one source SHA and unique frozen seed, every payload validates,
and the reducer retains every status/reason. It is not an availability,
recovery, covariance, interval, or coverage pass.

Any provenance/schema/seed mismatch is `AOI3R1_DIAGNOSTIC_INVALID`. Any
association/sandwich failure with a valid payload remains a scientific result,
not a run invalidation. No numeric tolerance, estimator, or optimizer repair is
permitted in AOI-3R1.

## Explicitly deferred

No local smoke is launched by this contract. No DRAC job, calibration, public
uncertainty method, `vcov()`, `confint()`, profile, standard error, capability
ledger change, public article update, or association claim is authorized.
