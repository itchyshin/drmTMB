# After Task: Slice 51 Phase 6 Profile Audit

## Goal

Start Phase 6 in a controlled way: create the GitHub tracking issues, audit the
current profile-likelihood boundary, and publish a slice plan before adding more
interval code.

## Implemented

- Created GitHub issue #30 for Phase 6 profile-likelihood inference and
  interval reporting.
- Created GitHub issue #31 for Phase 6b tutorial quality upgrades.
- Updated `ROADMAP.md` with Phase 6 Slices 51-60 and Phase 6b Slices 61-68.
- Added a Slice 51 target-audit table to
  `docs/design/12-profile-likelihood-cis.md`.
- Recorded this check-log and after-task note.

## Mathematical Contract

No likelihood or interval algorithm changed in this slice. The contract is a
status boundary:

- direct profile targets can be profiled only when `profile_targets()` marks
  them as `target_type = "direct"` and `profile_ready = TRUE`;
- response-scale row profiles require explicit `newdata`;
- q4 correlations, ICCs, repeatability, phylogenetic signal, and other nonlinear
  summaries remain derived or planned targets until a direct or fix-and-refit
  profile method exists.

## Files Changed

- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-slice-51-phase-6-profile-audit.md`

## Checks Run

- `gh issue list --repo itchyshin/drmTMB --state open --limit 100 --json number,title,labels,assignees,state,updatedAt,url`
- `gh issue view 5 --repo itchyshin/drmTMB --json number,title,body,labels,updatedAt,url`
- `gh issue view 4 --repo itchyshin/drmTMB --json number,title,body,labels,updatedAt,url`
- `PATH=/opt/homebrew/bin:$PATH air format ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-15-slice-51-phase-6-profile-audit.md`
- `git diff --check`
- `Rscript -e 'devtools::test(filter = "profile-targets|corpairs|summary", reporter = "summary")'`
- `Rscript -e 'pkgdown::build_site()'`
- `Rscript -e 'pkgdown::check_pkgdown()'`
- `rg -n "issues/30|issues/31|Slice 51|Slices 51-60|Slices 61-68|q4 ordinary and phylogenetic correlations" ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-15-slice-51-phase-6-profile-audit.md pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`

## Tests Of The Tests

No new test files were added because this slice changed issue tracking and
documentation only. The focused `profile-targets`, `corpairs`, and `summary`
tests still ran, so the existing profile/reporting surfaces stayed green after
the roadmap and design-note edits.

## Consistency Audit

The open issue list showed no dedicated Phase 6 or Phase 6b tracking issue.
Issue #5 remains the covariance-block programme, and issue #4 remains the
large-data readiness programme. The new issues keep profile-likelihood
inference and tutorial quality from being hidden inside those broader feature
threads.

## What Did Not Go Smoothly

The GitHub connector could read repository data but could not create issues
because the integration returned a 403. Grace switched to the authenticated
`gh` CLI, which created both issues successfully.

## Team Learning

- Ada should keep Phase 6 as small, auditable slices rather than a single broad
  inference rewrite.
- Boole should keep target names user-facing and separate from raw TMB parameter
  names.
- Fisher should treat profile likelihood as the main path for bounded variance
  and correlation parameters, with bootstrap as fallback.
- Pat should make every interval example answer "what does this bound mean?"
  rather than only showing syntax.
- Grace should keep GitHub issue creation on the `gh` CLI path when the
  connector lacks issue-write permission.
- Rose should keep derived q4 and nonlinear interval claims visibly marked as
  unavailable until tests prove otherwise.

## Known Limitations

Slice 51 is an organization and audit slice. It does not add new profile
interval support, derived q4 intervals, profile plots, or tutorial examples.

## Next Actions

Slice 52 should stabilize the target namespace and test the direct-versus-
derived profile inventory across representative fitted model classes.
