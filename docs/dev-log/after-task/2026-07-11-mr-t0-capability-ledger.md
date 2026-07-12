# After Task: MR-T0 Capability Ledger and Generated Surface

## Goal

Create the auditable capability-ledger foundation for the post-CRAN
missing-response arc, correct the two false zero-inflated ticks, and show the
generated surface before any family implementation.

## Implemented

MR-T0 now separates the unchanged 668-cell model/inference census from an
18-route missing-response execution axis. Six routes are admitted but
unverified at G1; twelve are rejected/planned at G0; none receives a verified
tick before G3 recovery.

`tools/capability_ledger.py` validates immutable cell IDs, evidence references,
append-only transitions, denominators, enums, baseline counts, and route truth.
It deterministically generates the census projections, widget JSON, canonical
Markdown and HTML surfaces, a pkgdown vignette include, and the MR-T0 tranche
summary. CI now checks generation, unit tests, and live R reconciliation before
the Linux R-CMD-check.

The canonical HTML combines the new missing-response execution board with the
original whole-package per-family capability map requested by Shinichi. The
retained map still shows dpars, fixed/random/structured effects, REML, inference
tier, and both missing-data axes; its missing-response column is regenerated
from the corrected ledger.

## Mathematical Contract

MR-T0 changes no likelihood. It records the later implementation contract that
a wholly missing response contributes zero to the observed-data log likelihood
under an ignorable missingness mechanism. G1 records code admission only; G2
requires likelihood/sentinel/extractor validation; G3 requires known-DGP
recovery and is the first verified-tick gate.

## Files Changed

- Ledger: `docs/dev-log/dashboard/capability-ledger/`
- Generator: `tools/capability_ledger.py`
- Runtime oracle: `tools/check-capability-runtime.R`
- Generator tests: `tools/tests/test_capability_ledger.py`
- Canonical surfaces: `docs/dev-log/dashboard/capability-surface.{md,html}`
- Generated pkgdown include:
  `vignettes/includes/capability-ledger-missing-response.md`
- Article integration: `vignettes/capability-and-limits.Rmd`
- CI: `.github/workflows/R-CMD-check.yaml`
- Behavioral route guard:
  `tests/testthat/test-missing-response-family-gate.R`
- Dashboard documentation and check log.

The dated 2026-07-11 capability files remain archived snapshots.

## Checks Run

- `python3 tools/capability_ledger.py --check`: passed; 24 generated outputs.
- `python3 -m unittest tools/tests/test_capability_ledger.py`: 5 passed,
  including deterministic generation, intentional stale/missing output
  failures, and a synthetic G3 promotion proving future ticks do not require
  generator changes.
- `Rscript --no-init-file tools/check-capability-runtime.R`: passed; 18 routes,
  6 G1, 12 G0, 0 verified.
- `devtools::test(filter = "missing-response-family-gate")`: 13 expectations
  passed, including explicit zero-inflated and hurdle rejection behavior.
- `devtools::document()`: passed and produced no roxygen/NAMESPACE drift.
- Direct `rmarkdown::render()` of `capability-and-limits.Rmd`: passed.
- `pkgdown::check_pkgdown()`: no problems.
- `pkgdown::build_article("capability-and-limits")`: passed.
- `git diff --check`: passed.
- Browser audit: 18 route cards, 12 G0, 6 G1, 0 verified, 668 detailed
  model rows, 18 retained per-family rows, nine retained family-map columns,
  corrected `zi_poisson`/`zi_nbinom2`, valid GitHub evidence links, responsive
  390-pixel layout without page overflow, and working light/dark theme toggle.

A full `devtools::test()` was started and progressed without failures through
the missing-response files and well into the Phase 18 tests. It was intentionally
interrupted when the user asked to avoid the uneconomical broad run; subsequent
visual changes were verified by the focused gates above. The CI workflow owns
the eventual whole-package check.

## Tests Of The Tests

The Python unit test changes one byte in a generated file and confirms
`--check` fails, and separately confirms a missing generated file fails. The R
behavioral test constructs zero-inflated Poisson, zero-inflated NB2, and hurdle
NB2 requests with a missing response and requires the actual front door to
reject for the intended reason. A copied allow-list cannot satisfy this test.

The independent final audit initially withheld completion because the generator
hard-locked the MR-T0 6/12/0 baseline and the retained family map treated every
future gate except G1 as G0. The generator now derives every count, accepts
evidence-consistent G2-G5 transitions, renders the actual future gate, and has a
synthetic G3 regression test. The same pass added a skip link, column scopes,
and server-rendered 668 rows for no-JavaScript readers.

The re-review found one remaining copy of the baseline lock in the live R
checker. It now enforces generic capability/G1+ and verified/G3+ consistency
instead. The final independent verdict is **DONE**.

## Consistency Audit

The legacy model census remains exactly 668 cells with status counts 283
implemented, 343 rejected by design, and 42 not implemented. Its TSV projections
remain byte-identical; only `_widget_data.json` changes its generated date. The
missing-response axis is separate and has exactly 18 route IDs.

The original visual's false missing-response claims for `zi_poisson` and
`zi_nbinom2` are corrected to G0/rejected. The retained family map and the new
route board read those states from the same ledger.

## GitHub Issue Maintenance

Parent issue [#761](https://github.com/itchyshin/drmTMB/issues/761) tracks the
approved MR-T0--MR-T7 arc, its route/gate deltas, and the G3 completion bar.

## What Did Not Go Smoothly

The historical census is tab-separated but contains literal quote characters
that are not CSV quoting. The first projection normalized those quotes. The
generator now imports and writes the historical census literally, restoring
byte identity. Historical evidence fields also mix paths with internal cell
names; MR-T0 preserves them verbatim while requiring resolvable paths for all new
evidence.

The first new surface replaced too much of the original reader-friendly family
map. Shinichi clarified that the new execution board should supplement—not
replace—the comprehensive package view. The final surface now includes both.

## Team Learning

The capability surface needs two coordinated views: a route-level execution
board for systematic work and a dense family-level map for understanding the
package. Both must be generated from controlled sources, but they serve
different readers and should not be collapsed.

## Known Limitations

MR-T0 implements no missing-response family. The six G1 routes still need the
shared MR-T1 sentinel/residual/accounting/recovery audit. G4/G5 interval and
coverage campaigns remain outside this arc. Historical model evidence strings
are preserved rather than normalized during this migration.

## Next Actions

1. Shinichi reviews the generated surface and the economical ultra-plan.
2. Do not start a family tranche yet.
3. If authorized, execute MR-T1 only: repair the shared validation harness and
   audit the six currently admitted routes.
