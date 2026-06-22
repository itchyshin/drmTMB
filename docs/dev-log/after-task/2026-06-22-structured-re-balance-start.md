# After Task: Structured Random-Effect Balance Start

## 1. Goal

Start the broader structured random-effect balance arc after the Ayumi
phylo-balance closeout. The scope is q1, q2, q2-plus-q2, and q4 status across
`phylo()`, `spatial()`, `animal()`, `relmat()`, and q1
`phylo_interaction()`, not a phylo-only follow-on.

## 2. Implemented

SR001-SR010 are banked as a governance and evidence tranche. The tranche adds a
validator-owned matrix, a 100-slice ledger, a design note, dashboard
documentation, this after-task report, and a check-log entry. The subsequent
native ML q1 evidence tranche is recorded separately in
`docs/dev-log/after-task/2026-06-22-structured-re-native-ml-q1.md`.

The matrix separates fit status, inference status, and bridge status for each
structured cell. It records current ML coverage, unsupported inference or
bridge cells, q4 point/status boundaries, and count-model q1 boundaries without
promoting native REML, R bridge support, or interval coverage.

## 3. Decisions and Rejected Alternatives

The main decision is to treat "balanced" as a structured matrix, not as a
single yes/no label. A route can be fitted while its inference, coverage, REML,
or bridge row remains unsupported.

I rejected carrying forward the narrower phylo-only plan as the primary
implementation arc. It was useful for the Ayumi question, but it would miss the
same imbalance risk for `spatial()`, `animal()`, and `relmat()`.

## 4. Files Created or Changed

- `docs/design/207-structured-random-effect-balance-100-slices.md`
- `docs/dev-log/dashboard/structured-re-balance-matrix.tsv`
- `docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/after-task/2026-06-22-structured-re-balance-start.md`
- `docs/dev-log/check-log.md`
- `tools/validate-mission-control.py`

## 5. Checks Run

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/tmp/drm-status.json
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/tmp/drm-sweep.json
tools/validate-mission-control.py
git diff --check
rg -n "(supports|implements|implemented|available|ready|promotes|validates|proves).*(native q4 REML|q4 AI-REML|HSquared AI-REML|R bridge support|10,440-tip|non-Gaussian REML|public optimizer)|10,440-tip.*(ready|supported|available|implemented)|AI-REML (solves|validates|supports)" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml docs/design/206-ayumi-follow-on-implementation-slices.md docs/design/207-structured-random-effect-balance-100-slices.md docs/dev-log/dashboard/README.md docs/dev-log/dashboard/structured-re-balance-matrix.tsv docs/dev-log/dashboard/structured-re-balance-100-slices.tsv
```

Outcomes:

- Both dashboard JSON files parsed cleanly.
- `tools/validate-mission-control.py` passed and reported 27 structured RE
  matrix rows plus 100 structured RE balance-slice rows.
- `git diff --check` was clean.
- The status-inventory overclaim scan returned no positive hits.

## 6. Tests of the Tests

The validator now checks the structured matrix schema, required row IDs,
allowed structured types, input scopes, q1/q2/q2-plus-q2/q4 dimensions, status
vocabularies, evidence links, and forbidden AI-REML promotion patterns. It also
checks the 100-slice ledger row count, SR001-SR100 IDs, order, 10-row waves,
dependency order, banked-row evidence, and bridge-status vocabulary.

## 7. Issue Ledger

No GitHub issue was touched. This is local mission-control work only. Any
future issue update should happen after SR011-SR100 produce row-specific fit,
inference, or bridge evidence.

## 8. Consistency Audit

The new design note and dashboard rows keep these boundaries explicit:

- REML / AI-REML wording remains exact-Gaussian only.
- q4 Patterson-Thompson REML is not HSquared AI-REML.
- q4 point/status support is not q4 interval coverage.
- Direct DRM.jl evidence is not R-via-Julia bridge support.
- Count-model q1 structured `mu` support is not non-Gaussian REML support.
- `phylo_interaction()` remains q1 pair-level, not a q2/q4 covariance family.

## 9. What Did Not Go Smoothly

The first draft matrix undercounted ordinary count-model q1 support for
`animal()` and `relmat()`. That was corrected before validator ownership so the
matrix does not recreate the imbalance it is meant to catch.

## 10. Known Limitations and Next Actions

This tranche does not implement new model code. It banks the corrected plan and
the validation scaffolding. The next implementation evidence starts with the
native ML q1 tranche for `phylo()`, `spatial()`, `animal()`, `relmat()`, and
`phylo_interaction()`.

Native broad structured REML, structured slope covariance, q4 interval
coverage, R-to-Julia bridge parity, spatial mesh/SPDE, sparse large-pedigree
animal routes, generic direct-SD structured grammar, non-Gaussian q2/q4, and
structured `rho12` remain open.

## 11. Team Learning

For structural dependence, "works" must name the dimension, endpoint, input
source, estimator, inference target, and bridge route. That is the only way to
avoid answering an Ayumi-style balance question with a technically true but
operationally misleading sentence.
