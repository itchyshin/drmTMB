# Capability ledger contract

This directory is the source of truth for drmTMB's generated capability
surface. Edit the ledger sources, record a transition, then regenerate; do not
hand-edit the generated census, Markdown, HTML, JSON, vignette include, or
tranche summaries.

## Axes

- `model_surface`: the current 671-cell census of family, distributional
  parameter, effect, provider, dimension, estimator, implementation status, and
  inference evidence. IDs `mc-0001`--`mc-0668` preserve the imported census;
  `mc-0669`--`mc-0671` retain the rejected Arc 3a neighbourhood after three
  legacy provider rows became exact q1 intercept admissions.
- `missing_response`: 18 user-visible fitted routes tracked independently from
  model inference maturity.

The axes answer different questions. Completing missing-response validation
does not promote `supported`, `inference_ready_with_caveats`, REML, structured
effects, intervals, or missing-predictor support.

## Files

- `cells.tsv` stores current state under immutable cell IDs. `mc-0001` through
  `mc-0668` freeze the imported model IDs, `mc-0669`--`mc-0671` are additive
  Arc 3a boundary rows, and `mr-*` IDs name exact
  missing-response routes.
- `evidence.tsv` stores one-to-many evidence. Historical model provenance was
  imported verbatim even where the old census used internal cell names rather
  than paths.
- `transitions.tsv` is append-only. Every work-state change must name evidence,
  reason, actor, commit, and date.
- `schema.json` defines fields, enums, denominators, and the verified-tick gate.
- `tranches/` contains generated tranche summaries.

## Missing-response gates

| Gate | Meaning |
|---|---|
| G0 | rejected or absent |
| G1 | builder/kernel route implemented |
| G2 | likelihood identity, direct sentinel mutation, and extractor/accounting contract |
| G3 | known-DGP recovery for all fitted distributional parameters |
| G4 | finite correctly named interval at a known-DGP point |
| G5 | archived replicated coverage evidence |

The visible verified ✓ begins at G3. MR-T0 seeded six admitted routes at G1 and
twelve rejected routes at G0. MR-T1 promotes those six routes to G3 with
separate passing G2 contract evidence and G3 recovery evidence; the remaining
twelve routes stay at G0 until their scheduled tranches.

## Commands

```sh
python3 tools/capability_ledger.py --check
python3 tools/capability_ledger.py --summary
python3 tools/capability_ledger.py --write
python3 -m unittest tools/tests/test_capability_ledger.py
Rscript --no-init-file tools/check-capability-runtime.R
```

`--bootstrap` is a one-time migration command and refuses to overwrite an
existing ledger.
