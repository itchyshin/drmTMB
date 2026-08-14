# Plan versus actual — native reader contract

Reconciler: Melissa. Plan source: the approved Ultra Plan in the Codex task.
This record compares the promised two-PR native reader arc with the candidate
stack based on repaired PR 1 head `c1a756ee9`, PR 2 implementation commit
`4a49eb5eb`, and scientific-journey repair head `ba431b0b3`.

## Scope

The plan promised no new function, model, estimand, likelihood, calibration,
MSPL work, Julia support, or CRAN re-freeze. Actual work stayed inside that
boundary. The only exported behavior repair is deterministic uniqueness for
colliding appended `newdata` names; the established `ranef()` empty-list and
all ordinary output shapes remain unchanged.

## Slice Reconciliation

| Slice | Planned | Actual | Verdict |
|---|---|---|---|
| S0 | fresh worktree, fences | based on `origin/main` `f5ec53634`; five protected hashes recorded | matched |
| S1 | complete corpus and linter | 37/37 manifest, three exact contributor permissions, four exact exceptions, and 21 adversarial expectations including prose-only routes | matched plus D-43 repair |
| S2 | migrate reader articles | 13 unique articles moved to exported diagnosis/extraction paths | matched plus corpus-wide repair |
| S3 | integrate PR 1 | `798af8dbc`, `c6f22c608`, and prose-linter repair `c1a756ee9`; PR #1027 | adaptive repair |
| S4 | minimum stable schemas | roxygen/Rd/tests for five established verbs; advanced components fenced | matched |
| S5 | ten scientific journeys | one shared fixture set and 53 expectations across ten distinct interpretation assertions | matched plus D-43 repair |
| S6 | mechanical verification | focused contracts, live linter, protected hashes, path-portability repair | matched plus repair |
| S7 | package gate | repaired exact source `--as-cran` 0/0/1, pkgdown green, full native suite exit 0, and repaired PR 1 exact-head CI green | matched |
| S8 | D-43 | Emmy, Fisher, and Rose each returned `DONE` after repairing the prose-route P1 and scientific-journey P2s | matched after repair |
| S9 | closeout | this reconciliation, after-task report, and check-log entry | matched at candidate close |

## Deviations

The linter test initially assumed top-level `tools/` was shipped. CI correctly
rejected that assumption; PR 1 now skips the development-only test only in a
source-tarball context while retaining the local live-corpus gate.

PR 2 gained two small verification repairs not named in the plan. The audit
script avoids reloading an already loaded namespace, which had contaminated
later mocked profile tests. The q6 receipt audit now quotes repository and file
paths, which makes the complete suite runnable from the mandated worktree path
containing a space. Both are test-infrastructure repairs, not product-scope
expansion.

The first implementation changed `ranef(no_random_fit)` from `list()` to an
error. The source-tarball test caught the compatibility break, so the change was
reverted and the existing behavior was documented explicitly. This is the
plan's stop-on-shape-change rule working as intended.

The first D-43 panel found that the syntax-only linter did not see prose routes
such as `sdpars$mu`. The repair added bare/backticked-route detection, six
article migrations (13 unique articles in the full PR), and adversarial tests.
Fisher also required a bivariate DGP that genuinely varies residual correlation
with disturbance and non-vacuous profile-readiness checks for structured SDs.

## Evidence And Claim Boundary

The earned claim is reader-contract reliability for the tested native
workflows. The evidence is deterministic API/schema testing, rendered articles,
the full native package suite, pkgdown, and a complete source-tarball check. It
does not support a new statistical accuracy, coverage, family, MSPL, Julia, or
release-readiness claim.

## Protected And Deferred Work

`R/drmTMB.R`, `R/missing-data.R`, `README.md`, `_pkgdown.yml`, and `R/profile.R`
retain their exact receipt hashes. Capability-ledger files were not changed.
The CRAN re-freeze, MSPL arc, Julia surface, simulations, new estimands, and
calibration remain deferred.
