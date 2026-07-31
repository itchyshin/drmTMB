# C14 canonical integration blocker

## 1. Goal

C14 was to reconcile the canonical capability ledger with retained Lane C
point-fit evidence, restoring package-boundary taxonomy and moving only exact,
source-bound candidates.

## 2. Scope completed

The clean C14 rebind branch imported the bounded zero-one-beta structured q1
implementation paths, retained provider-specific recovery runners, and reran
the focused zero-one-beta test file. The test file passed on the integrated
source. No ledger status, generated capability output, Mission Control source,
or Future-extension classification was changed.

## 3. Recovery evidence retained

Five structured `sigma` fixtures passed their four retained local attempts:
phylo, animal, relmat, spatial, and phylo-interaction. Structured `mu` fixtures
passed for phylo, relmat, spatial, and phylo-interaction. The structured `mu`
animal fixture is retained as `BLOCKED_LOCAL_FIXTURE` with zero valid attempts;
it is not a point-fit claim.

## 4. Independent review

Noether found the q1 map and endpoint routing technically sound for the nine
passing structured providers. Fisher retained a point-fit-only boundary. Rose
found that the ledger representation cannot receive those transitions as-is.

## 5. Blocking finding

`mc-0583`--`mc-0587` and `mc-0593`--`mc-0597` have `q_gate = na`: each is a
representative row collapsing q1, q2, q4, q6, q8, and q12. The new evidence is
only for one exact q1 intercept form. Changing any representative row to
`implemented` would falsely assert recovery for its untested high-q forms.

## 6. Provenance finding

Several historical recovery runners either omit a source SHA or record a
pre-integration SHA. A later source-SHA attempt exposed that this must be
treated as a separate evidence-binding problem, not corrected by relabelling
old raw results. Raw results remain retained; none is replaced or discarded.

## 7. Claim boundary

The passing fixtures are local technical point-fit evidence only. They do not
support profiles, intervals, coverage, calibration, inference readiness,
REML, q2-plus forms, labelled covariance, cross-dpar combinations, or a
family-wide structured zero-one-beta claim.

## 8. Tests run

`devtools::load_all(); testthat::test_file("tests/testthat/test-zero-one-beta.R")`
passed. `python3 tools/capability_ledger.py --check` passed before any ledger
edit.

## 9. Superseding C14-A taxonomy repair

After this blocker receipt, the independent classification-only C14-A repair
was completed. It restores 330 source-pinned package-boundary rows to
`rejected_by_design / deferred / none`, records 330 matching non-evidence
transitions, and regenerates the canonical ledger outputs. The verified
intermediate census is **314 implemented / 330 package boundaries / 33
actionable not implemented**. Its source and guard are recorded in
`docs/dev-log/dashboard/capability-ledger/c14-boundary-taxonomy.md`.

This corrects the sentence above that said the canonical ledger remained
unchanged; no point-fit promotion was made, and every C14-B promotion blocker
remains in force.

After user approval, C14-B then split the ten lossy structured zero-one-beta
representatives into exact q1 leaves plus ten explicit q2-plus boundary leaves.
The canonical model denominator is now 687, with 314 implemented, 340 package
boundaries, and 33 actionable leaves. This preserves the blocker: only a
source-bound q1 evidence bridge and independent GO can promote each leaf.

## 10. Status

**BLOCKED.** The requested `328 / 330 / 19` census is not derivable honestly
from the current representative-row taxonomy. The canonical ledger therefore
remains unchanged.

## 11. Required successor

A new, separately approved taxonomy arc must introduce non-lossy q1 leaf
representation (or another audited exact-cell representation), preserve the
existing q>1 representative rows as not implemented, bind every retained
fixture to an immutable source revision, then rerun ledger generation and the
Mission Control canonical-source check.

## 12. Handoff

Resume from `codex/lane-c-c14-evidence-rebind`. Do not promote the nine q1
providers or alter the 330 package-boundary classification until the taxonomy
decision above is approved.

## 13. C14 provenance repair and authorized three-cell exception

The taxonomy decision was approved, followed by a source-binding audit. Seven
structured q1 receipts remain blocked because their immutable execution source
differs from the C14 target; the invalid sigma-spatial run-1 is not used. The
raw SHA substitutions introduced in `7915c60f8` were restored from its parent
without changing any attempts, estimates, or runner hashes.

Only `mc-0568`, `mc-0569`, and `mc-0576` have raw receipt SHAs that are
byte-identical in the relevant R/TMB/test paths to the C14 target. Each has
four retained passing attempts and fresh Fisher, Noether, and Rose GO at
point-fit-recovery grade only. Shinichi explicitly authorized the named
frozen-census exception, so the ledger now records **317 implemented / 340
rejected-by-design / 30 actionable not implemented**. No interval, profile,
coverage, calibration, or inference-ready claim is made.
