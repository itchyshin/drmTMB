# AOI-3 generic two-step methods review

## 1. Goal

Ground the private AOI-3 uncertainty-design principles in third-party methods
literature without exporting drmTMB-specific methodology or changing inference.

## 2. Implemented

Created and curated a five-source public Gemini Notebook corpus, distilled its
generic two-step covariance lessons into a private dev-log memo, and corrected
the stale execution status of the failed historical AOI-3 calibration contract.

## 3a. Decisions and Rejected Alternatives

The project-specific NotebookLM prompt was rejected as an external-disclosure
risk. It was replaced with generic two-step questions only. The memo does not
adopt a finite-sample threshold or declare the analytic sandwich valid; those
remain a later, separately authorized calibration decision.

## 4. Files Touched

- `docs/dev-log/2026-07-31-aoi3-full-refit-calibration-contract.md`
- `docs/dev-log/2026-07-31-aoi3-generic-two-step-methods-review.md`
- `docs/dev-log/after-task/2026-07-31-aoi3-generic-methods-review.md`

## 5. Checks Run

- `notebooklm auth check --test --json` — PASS, including token fetch.
- Source list/fulltext spot checks — PASS: five final sources were ready and
  readable; five off-target/non-primary sources were deleted.
- `git diff --check` — PASS.

## 6. Tests of the Tests

The corpus was deliberately challenged by a project-specific query, which the
external safety layer rejected. The safer generic query returned cited sources;
the memo retains that distinction rather than presenting generic evidence as a
package-specific validation.

## 7a. Issue Ledger

- Historical AOI-3 contract still described itself as executable after its
  failed smoke — corrected to superseded-for-execution.
- Generic two-step methods grounding — recorded privately.
- AOI-3R2 smoke and calibration — deferred pending explicit owner approval.

## 8. Consistency Audit

The memo, revised historical contract, AOI-3R2 contract, and existing handover
all retain the same public boundary: no `vcov()`, `confint()`, standard errors,
intervals, capability promotion, or public association claim.

## 9. What Did Not Go Smoothly

The project-specific research prompt could not be sent externally. Some initial
generic NotebookLM asks returned no captured output, so only the successful
cited generic synthesis is used. Report/audio/video artifacts were fired and
remain pending.

## 10. Known Residuals

The generic literature does not prove this package's implementation or set its
finite-sample thresholds. The notebook could not be registered in the external
brain vault from this restricted worktree; its ID and complete corpus record
are retained in the memo.

## 11. Team Learning

Memory receipt: AOI's private/public inference boundary and external-data
guard shaped this review. Golden Set: not in scope; this is a private literature
distillation and stale-status correction, not a release or capability change.

## 12. Cross-Product Coverage

This review covers ✓ generic two-step covariance principles and the rationale
for complete-refit bootstrap comparison. It does NOT cover ✗ drmTMB-specific
asymptotics, sandwich implementation, numerical derivatives, local smoke,
DRAC, coverage, public APIs, other family pairs, random/structured association
effects, missingness, weights, offsets, REML, or public inference.
