# After Task: Animal q2 Universe Correction

## 1. Goal

Correct the finite SD-regression universe to represent a correlated animal
intercept and numeric slope within one endpoint, then link the completed
Bernoulli bridge evidence to its exact rows.

## 2. Implemented

Added the `animal_correlated_block` mechanism and `A2-animal-within` q2 rule.
The generated denominator now has 20,350 rows, 28 mechanism templates, and
150 engine/mechanism rule rows. Its 672 new rows remain obligations; they do
not imply that every family, engine, or provider input is implemented. Added
12 hash-verified evidence records for the supplied-A Binomial animal q2 bridge
across two coefficient targets, three links, and both engines.

## 3a. Decisions and Rejected Alternatives

Kept the new q2 mechanism separate from independent animal q1 fields and
labelled cross-endpoint animal blocks. Kept Julia non-logit admissions limited
to the tested A-covariance input; pedigree and A-inverse rows remain blocked or
unresolved as generated. No assumption changed the coverage-calibration
deferral or promoted a denominator row to general support. Assumptions without
asking: none.

## 4. Files Touched

- `tools/general-sd-regression/universe.py`
- `tools/general-sd-regression/tests/test_universe.py`
- `docs/dev-log/general-sd-regression/mechanism-templates.tsv`
- `docs/dev-log/general-sd-regression/block-rules.tsv`
- `docs/dev-log/general-sd-regression/required-rows.tsv`
- `docs/dev-log/general-sd-regression/required-universe.md`
- `docs/dev-log/general-sd-regression/universe-contract.md`
- `docs/dev-log/general-sd-regression/block-dimension-contract.md`
- `docs/dev-log/general-sd-regression/universe-final-review.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/after-task/2026-10-29-animal-q2-universe-correction.md`
- `docs/dev-log/check-log.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

## 5. Checks Run

- `python3 -m py_compile tools/general-sd-regression/universe.py tools/general-sd-regression/tests/test_universe.py`: passed.
- `python3 tools/general-sd-regression/tests/test_universe.py`: 22 tests passed.
- `python3 tools/general-sd-regression/universe.py`: generated 20,350 rows.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed; 20,350 candidate rows, 173 rows with evidence, 193 evidence records.
- Scoped `git diff --check` on the edited generator, tables, generated artifacts, contracts, check log, and programme checkpoint: passed.
- The prior q2 bridge run passed its focused R-to-Julia tests (2 live tests); retained Julia suites passed 33/33 logit and 20/20 probit/cloglog checks. These are narrow point/output checks, not interval calibration.

## 6. Tests of the Tests

The new generator test failed before the universe change because no animal
within-endpoint q2 rows existed. It now checks the two target coefficients,
both engines, Binomial and Gamma rows, and the distinct within-endpoint
layout. It also checks that single-endpoint Binomial structural exclusions
remain limited to the cross-endpoint block.

## 7a. Issue Ledger

The open-issue search for “animal q2 SD universe” returned no matching issue.
No issue was created, edited, or closed.

## 8. Consistency Audit

Updated the mechanism table, block rule, deterministic generator, generated
ledger and summary, universe contract, block-dimension contract, and the
independent-review note. The review note states that its Oct 17 decision
predates this correction and that G0 remains open. The evidence reconciliation
keeps all direct-SD claims at `none`. No formula syntax, likelihood, public
documentation, or fitted model changed.

## 9. What Did Not Go Smoothly

The candidate checkout has no project `LOAD-FIRST` manifest, and the `graft`
command is unavailable in this shell. The route check reported the missing
manifest. The lane registry was slow and identified this runtime as unknown;
the user’s explicit ownership instruction and path leases governed the work.
The closeout helper initially wrote its template to the Shinichi brain
checkout; I removed that accidental file and created the report in this
project.

## 10. Known Residuals

The Oct 17 independent review does not review this correction. The 20,350-row
denominator still needs family × endpoint × provider/input × layout source
classification and mathematical/identifiability review. The 12 Binomial
evidence records cover supplied A only. Coverage calibration, pedigree and
A-inverse q2 bridge parity, and broad Julia family parity remain open.

## 11. Team Learning

For structured effects, encode within-endpoint correlated coefficient blocks
separately from cross-endpoint covariance. A q=0 cross-endpoint exclusion
cannot stand in for an audit of within-endpoint q2.

Memory receipt: `MEMORY.md` candidate-slice guidance informed the narrow
evidence boundary; `route.py` found no project manifest. Golden Set: I reviewed
`memory_regression.py --list` and identified completion-overclaim and
branch/worktree cases as relevant, but no transcript-level verdict was run
because no transcript file was available.

Prose assessment: style 2/10, medium confidence; genre is a technical
after-task report, reviewed in full. One located repair was changing the old
review status to “predates this correction,” which prevents readers from
mistaking it for review of the new rows. Science gate: pass for the bounded
ledger claim; facts gate: pass against generator output, tests, and evidence
reconciliation; reference gate: not applicable because no external references
are cited. Provenance: self-review, this report, 2026-10-29; no controls were
consulted.

## 12. Cross-Product Coverage

Covers: denominator representation of one animal endpoint with correlated
intercept and slope; both engines and all declared response endpoints/provider
inputs as obligations; focused supplied-A Binomial bridge evidence for logit,
probit, and cloglog.

Does NOT cover: general implementation across the 20 response families, every
animal input, all effect types, interval coverage, closure of G0, or release
readiness.
