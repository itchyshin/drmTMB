# Session Handoff: pkgdown reader-surface formal closeout

**Meta:** 2026-07-22 · Codex · formal-closeout lane

## Critical Context

The reader-surface audit is closed at frozen merged revision `1a972b8e` after
the formal evidence commit on `codex/pkgdown-formal-closeout`. Do not reopen the
32 article audits unless a new, concrete P1/P2 reader defect is found.

## What Was Accomplished

The closeout now has an explicit 68-topic eight-batch ledger, clean-worktree
render/read-back receipt, plan-versus-actual reconciliation, repaired stale
audit provenance, and a 3/3 READY D-43 verdict. `bivariate-coscale` is no
longer owner-held: its interval text is reportable but not coverage-certified.

## Current Working State

- Working: formal reader-surface assurance is complete.
- In progress: no pkgdown repair item.
- Not working / blocked: CRAN, deployment, platform matrix, Julia-engine work,
  capability promotion, and simulation remain outside this lane.

## Key Decisions & Rationale

`98` reference HTML files means 69 canonical sitemap routes plus 29 alias
redirects; it is not 98 audited Rd topics. The audit claim ceiling remains the
0.6 release-scope manifest and capability ledger.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/pkgdown-formal-closeout` formal-closeout evidence | yes | no | none | LANDED locally; no push/merge authorized in this lane |

## Next Immediate Steps

1. If a maintainer wants to merge this evidence branch, inspect the D-43 record
   and normal Git diff first.
2. Treat any later reader claim change as a new page-specific documentation
   task, with the manifest/ledger as its ceiling.

## Blockers / Open Questions

None for formal audit closure. External release, deployment, and CRAN decisions
remain separate maintainer decisions.

## Gotchas & Failed Approaches

The sandbox cannot resolve the CRAN sidebar hostname used by pkgdown; use a
permitted local rerun for a full render. Do not use only the sitemap to count
reference pages: it omits no-index alias redirects.

## How to Resume

Read `docs/dev-log/release-audits/2026-07-22-pkgdown-reader-surface-d43.md`,
`docs/dev-log/release-audits/2026-07-21-site-audit/final-validation-receipt.md`,
and this handoff. Then inspect `git log -1` on `codex/pkgdown-formal-closeout`.
