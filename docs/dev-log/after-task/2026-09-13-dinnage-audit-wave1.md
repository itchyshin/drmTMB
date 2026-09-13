# After Task: Russell Dinnage's independent evaluation — response map, issues, and waves 1–2

## Goal

Turn Russell Dinnage's independent evaluation of drmTMB 0.7.0 (report pinned
at `945da24f`, dated 2026-08-29; 1 Critical, 10 Major, 23 Moderate, 26 Minor,
5 UX items) into tracked, attributed work, and fix the Critical and Major
findings with tests.  Shinichi's instructions: file the findings as GitHub
issues now, attributing each to Russell; commit to wave 1 (Russell's own
three-hour list) plus every Major; work on a fresh branch off `main`.

## Implemented

Every finding was re-verified against `main` at `4bfb9d721` (700 commits
after the pin): 54 present, 1 fixed since (Mi-14), 1 moved (Mi-13), 1 a
decision rather than a code state (Md-K).  Fifty-five issues were filed as
#1306–#1360 with the `audit-dinnage` and `severity:` labels, and two findings
were posted as comments on existing issues (#1301 for S2, #1240 for the
`anova()` papercut).  The map is
`docs/dev-log/audits/2026-09-13-dinnage-independent-evaluation-response.md`;
the drafts and `FILED.tsv` sit under
`docs/dev-log/issue-drafts/2026-09-13-dinnage-audit/`.

Branch `claude/audit-dinnage-wave1-20260913` carries, one commit per finding:
C1 (two-sided clamp detector; `check_drm()` reports the lower arm as a note),
Md-A, M1 (weights outside the `mi()` two-point mixture at ten sites), Md-D,
Md-E, Md-N, Md-M, Mi-9, and, merged from two sibling branches, S1, S4, S5, M4
(all thirteen families masked) and a regression lock for M3.  An independent
Fisher review (`docs/dev-log/audits/2026-09-13-dinnage-wave1-review.md`)
accepted C1, M1 and M4 with changes that were then applied, and rejected the
first S3 attempt, which was reverted.

## Mathematical Contract

M1 changes the likelihood only when `weights` are combined with a Bernoulli
`mi()` covariate: the contribution is now `w · log(p1 f1 + p0 f0)` with the
imputation prior weighted, as Russell prescribed; `weights = NULL` or all-ones
weights are bit-for-bit unchanged.  C1, Md-A, M3, M4, S1, S4 and S5 change
diagnostics, extractors and simulation output, not estimands.  S3 is
untouched: the review found the documented exponential PC prior correct and
the measured effect to be the log-scale MAP not being parameterisation
invariant, which is a design decision (issue #1312).

## Files Changed

`R/drmTMB.R`, `R/check.R`, `R/methods.R`, `R/family-dpq.R`,
`R/mspl-estimator.R`, `src/drmTMB.cpp`, `src/drm_response_kernels.h`,
`src/drm_numeric.h`, the `man/` pages regenerated from them, `NEWS.md`, and
tests: `test-clamp-active-guard.R`, `test-clamp-extension.R`,
`test-dinnage-audit-wave1.R`, `test-dinnage-audit-wave2a.R`,
`test-dinnage-audit-wave2b.R`, `test-missing-response-count-mixtures.R`,
`test-missing-response-truncated-nbinom2.R`.  Documents: the response map,
the review, the issue drafts, this report, the check-log shard, the
plan-versus-actual record, and the handover.

## Checks Run

See `docs/dev-log/check-log.d/2026-09-13-dinnage-audit-wave1.md` for the
per-file results on the merged branch and the local `R CMD check --as-cran`
on a clean export.  Each finding's ledger gate (`.unlazy/`, untracked) was
re-verified by the checker, not by reading the builder's summary; every
new test was shown to fail on the pre-fix code.

## Tests Of The Tests

Negative controls are recorded per finding in the commit messages: the
lower-arm clamp test fails on `origin/main`; the weight-invariance test
fails on the old kernel; `fitted_distribution()$p(0)` had length 1 before
and 300 after; `vcov(type = "robust")` raised nothing before; `AIC()` with a
foreign fit returned a scalar before; `simulate()` at masked rows was
non-`NA` for the count families before.  The two count-mixture tests that
had pinned finite draws at masked rows were shown to break only through `NA`
propagation, not through a stated invariant, before they were repaired.

## Consistency Audit

Three corrections were made to our own statements the same day: the S3
issue's posting-time note (overturned by review; correction posted on
#1312), the M1 issue's scope (eleven non-Bernoulli sites still carry the
bias; note posted on #1307), and the A2 scout's fan-out (five sub-agents
spawned against a five-live cap; three stopped, recorded as drift).

## GitHub Issue Maintenance

Opened #1306–#1360.  Commented on #1301, #1240, #1312, #1307.  Labels
created: `audit-dinnage`, `severity: critical|major|moderate|minor`.  None
closed; closures follow the merge of this branch.

## What Did Not Go Smoothly

The scout that cross-matched the report spawned five children of its own,
exceeding the live-agent cap; briefs now say "do not spawn sub-agents".  The
S3 builder corrected documentation on a premise the package's own C++
comments contradicted; the independent review caught it.  M1 was fixed at
the ten identical sites but eleven quadrature sites remain.  The message
tool was unavailable, so follow-ups from the review were applied by the
orchestrator rather than sent back to the builders.

## Team Learning

An independent reviewer with a fresh context changed three of four verdicts
materially; the builders' own tests would have passed every one of them.
File the response map before the fixes: it turned sixty findings into
tracked issues within the first two hours and made every later correction
a comment rather than a retraction.

## Known Limitations

M1 remains open for eleven imputation families (#1307).  S2 waits on the
D-252 scale audit (#1301).  S3 (#1312) and the four count-mixture masking
contract are decisions for Shinichi.  S6 (percentile bootstrap bias) needs a
design note before code.  M2 is unstarted.  Moderate and Minor findings are
tracked, not fixed, beyond the five in wave 1.

## Next Actions

Push the branch and open a draft PR; Shinichi decides S3 and reviews the
M4 count-mixture contract; a second session takes M1's eleven sites, M2, S6
and the S2 reconciliation from
`docs/dev-log/handover/2026-09-13-claude-handover-dinnage-audit.md`.
