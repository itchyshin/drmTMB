# After Task: Julia Binomial Non-Logit SD Evidence Registration

## 1. Goal

Register focused probit and complementary log-log predictor-dependent SD
evidence against the exact Julia Binomial candidate rows, while retaining the
broader base-link block.

## 2. Implemented

Added four source-bound evidence records: ordinary intercept and independent
numeric-slope cells for each link. The evidence join now links 58 receipt
records to 47 candidate rows, leaving 19,071 of 19,118 rows without a receipt.
The four candidate rows remain `blocked_base_plumbing`; all still have
`direct_sd_claim=none`. This records narrow focused evidence and changes no
support status.

## 3a. Decisions and Rejected Alternatives

Kept the frozen candidate universe unchanged. An attempted edit to generated
row-reason text was reverted after the universe test showed that the file must
remain an exact expansion of its pinned inputs. The narrower distinction is
recorded in the evidence summaries instead. No assumptions beyond treating the
two existing live bridge receipts as covering both link-specific candidate
rows were needed; each test and source hash is bound in `sources.sha256`.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-24-julia-binomial-nonlogit-sd-ledger-registration.md`

The existing R and Julia source, tests, receipts, and required-row universe
were read but not changed in this registration step.

## 5. Checks Run

- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed; 19,118
  candidates, 47 linked rows, 19,071 unlinked rows, 58 evidence records.
- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`:
  passed, 11 tests.
- `python3 tools/general-sd-regression/tests/test_universe.py`: passed, 17
  tests in 42.0 seconds after restoring the frozen generated-row text.
- The four new records remain `unreviewed`; no formal goal gate is closed.

## 6. Tests of the Tests

The ledger test suite verifies receipt hashes, source-manifest binding, exact
row matching, and invalid evidence rejection. The universe suite caught the
attempted generated-row edit; after restoration it confirmed that the frozen
candidate artifact still matches the pinned universe expansion.

## 7a. Issue Ledger

No issue was searched, opened, edited, or closed during this bookkeeping step.

## 8. Consistency Audit

The four receipts point to the existing focused intercept and slope test logs.
Each record binds the executed R test source through the source hash manifest.
The generated summary agrees with the row-level overlay. The general Julia
Binomial probit/cloglog base-link route remains blocked; these records document
only the tested direct-SD shapes.

## 9. What Did Not Go Smoothly

The first attempt changed generated row-reason text, which invalidated the
frozen universe artifact. I restored the exact source-generated text and
reran the universe suite successfully. The lane-preflight script also reported
the runtime as unknown; no conflicting ref was reported for the focused slope
test file.

## 10. Known Residuals

Evidence review remains `unreviewed`; receipt linkage does not establish
implementation admission or calibrated uncertainty. General non-logit
Binomial support, other links and formula shapes, broader family/effect/
provider/backend coverage, and all deferred interval-coverage work remain
outstanding. No full package check or documentation render was needed for this
ledger-only step.

## 11. Team Learning

Do not hand-edit generated required-row descriptions to clarify a new narrow
exception. Keep the universe artifact pinned and express cell-specific nuance
in the evidence overlay and dated inventory notes.

## 12. Cross-Product Coverage

**Covers:** R/TMB and paired DRM.jl synthetic probit/cloglog intercept and
independent numeric-slope direct-SD bridge receipts, exact candidate-row
linkage, and the frozen-universe regression checks.

**Does NOT cover:** general Julia non-logit Binomial fitting, structured or
correlated effects, other families or endpoints, calibrated intervals, or
programme completion.

**Memory receipt:** queried the Shinichi brain for the random-effect SD
hierarchy and project decisions. `route.py` returned no LOAD-FIRST manifest
for this worktree, and the repository has no local `memory/00-INDEX.md`; source
and test files remain the technical evidence. Golden Set review was not
relevant to this evidence-only ledger update, so the Golden Set was not run.

**Golden Set:** Not in scope for this evidence-only ledger update; it made no
code change and asserts no implementation correctness.

**Prose assessment:** Style 3/10, medium confidence. Genre/coverage: internal
after-task report, reviewed in full. Evidence/repair: the exact linked-row
counts in section 2 and the narrow support boundary in section 10 are concrete
and consistent; no prose change needed. Gates: science = not applicable to
ledger registration; facts = pass against the reconciler and final test logs;
references = not applicable because the report cites no literature. Provenance:
self-review of this saved draft on 2026-10-24; project examples were already
seen, so this is not a held-out style assessment.
