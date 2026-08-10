# Plan vs actual — Arc D + Phase B closeout (2026-08-09)

Reconciler: Melissa. Plan source: `~/.claude/plans/mellow-popping-mango.md`
(closeout revision). This is a light, receipt-based reconciliation, not an
implementation review.

## 1. Scope

Plan: land both branches with the R surface already built; "nothing remains to
*make it work*." Actual matches, plus adaptive growth: Arc D shipped **five**
R edit sites, not the plan's four (commit `b4ae15cb3` body; after-task
`docs/dev-log/after-task/2026-08-09-arcd-binomial-link-r-surface.md` §2), and
fixed three pre-existing defects outside the named scope (bivariate
`link_code`, `test-phylo-utils.R`, `binomial_start()` hardcoded logit — all
three visible in `git diff HEAD~1 HEAD` on `R/drmTMB.R` and
`tests/testthat/test-phylo-utils.R`). No scope was silently dropped.

## 2. Evidence / verification

Plan claimed both `--as-cran` gates already green at 0/0/1. Confirmed for the
final tree: after-task docs state `--as-cran` was re-run post-fix on both
branches (Arc D §5: "re-run after the defect in §9 was fixed"; Phase B §5:
"re-run on the final tree"). Test counts match the plan's evidence table
(Arc D 78+186ish via 66+60+15 targeted files; Phase B 32+52+143). One claim
from the known-deviations list — "`--as-cran` restarted three times" — is
**not** independently corroborated by any repo receipt; only one explicit
rerun-after-fix is documented.

## 3. Model routing

Two ceiling-tier children this checkpoint (Emmy, Noether) against the
one-per-checkpoint norm. Both are attributable in the repo: Noether's
correction to design 252 §4 is quoted and attributed in
`docs/design/252-binomial-link-generalisation.md:112-120`; Emmy's go/no-go
review is referenced in the same doc (`:8-10`, `:157`) and in the PR body.
Both agent names (`Emmy-D8`, `Noether-B5`) also appear as active session
agents, consistent with two ceiling-tier launches. The stated justification —
Emmy's verdict became the release gate once the target moved to 0.7.0 — is
recorded in `docs/design/252-binomial-link-generalisation.md:8-10`. The model
tier itself (Opus) is not independently verifiable from repo files.

## 4. Safety gates

`--as-cran` and Emmy's review became release-blocking only after the owner's
0.7.0 retarget (`docs/design/252-binomial-link-generalisation.md:1-20`, direct
quote: *"I want 0.7 - we can do it."*). `DESCRIPTION` is unchanged at `0.6.0`
on both branches (`grep -i ^Version DESCRIPTION`). No capability-ledger or
census file appears in either branch's `git diff --stat origin/main HEAD` for
tracked ledger/census paths. No candidate-preparation artifact found. Gates
held as designed.

## 5. Public claims

PR #973 (`gh pr view claude/binomial-link-generalisation`): **OPEN**, not
merged, title targets 0.7.0, body states "does not advance the release rung."
Claim boundary (`point_fit_recovery`, no new campaign, census unchanged) is
stated identically across the commit message, after-task report, design doc
§9, and `NEWS.md:18-20` — no drift between venues. No PR exists for the Phase
B branch (`gh pr view claude/mspl-binomial-inference-promotion` → "no pull
requests found"), matching the plan's "no PR (owner-fenced)."

## 6. Handoff state

Plan step 5 (new handover entry + `AGENTS.md` "Latest" block) had not run at
verification time — `AGENTS.md`'s top block is still dated 2026-08-08, and the
only 2026-08-09 handover file (`docs/dev-log/handover/2026-08-09-claude-arcd-links-handover.md`)
is the *incoming* handover committed at `96d3896aa`, not a new closeout entry.
This is not drift: the plan sequences the handover (step 5) after this
reconciliation (step 3), so it is simply not yet reached.

## Deviation table

| Deviation | Tag | Evidence | Decision-owner |
|---|---|---|---|
| Arc D grew 4→5 R edit sites (delta-method derivative arm) | adaptive | commit `b4ae15cb3` body; after-task §2; design doc `252:63-68` | pre-execution plan review (agent) |
| 3 pre-existing defects fixed out of scope (bivariate `link_code`, phylo-utils, `binomial_start` logit-hardcode) | adaptive | `git diff HEAD~1 HEAD -- R/drmTMB.R tests/testthat/test-phylo-utils.R`; after-task §9 | discovered mid-task, recorded with reason |
| Emmy condition 1 (remove `= 0` default, `src/drm_response_kernels.h:27`) deferred | unclear | default confirmed still present, no diff on that file; no repo-written justification found (checked design 252, after-task §10, NEWS.md, scratchpad) | Emmy-D8 review (record not located) |
| `--as-cran` "restarted three times" | unclear | only one rerun-after-fix documented (after-task §5 both branches); no count of 3 in any file | unverified — settle by asking the session or checking tool logs |
| Two ceiling-tier (Opus) children this checkpoint (Emmy, Noether) | adaptive | design doc `252:8-10, 112-120`; both named as active session agents | owner norm exception, justified by release-gate status |
| Owner moved target 0.7.1 → 0.7.0 mid-session | adaptive | design doc `252:1-20`, direct quote recorded | Shinichi (explicit) |
| S0 scout over-reported (phantom file write; 2 false `profile.R` breaks) | adaptive | `scratchpad/arcD-S0-recon.md:1-2, 30-40` — orchestrator's correction | caught and corrected same session |
| "Silent wrong-model bug" reported then retracted (multi-line grep miss) | adaptive | `scratchpad/2026-08-09-brain-lessons-DRAFT.md:44-48` | self-caught, recorded as a lesson |

## DEFER-list breach check

- Candidate prep / release rung: not breached — `DESCRIPTION` still `0.6.0` on
  both branches; no candidate-freeze artifact found.
- MSPL PR: not breached — no PR exists for `claude/mspl-binomial-inference-promotion`.
- SE-calibration campaign: not breached — no dated 2026-08-09 Totoro/campaign
  artifact found under `scratchpad/` or `docs/dev-log/simulation-artifacts/`.
- Emmy condition 1: not breached (deferred as planned) — but see "unclear" row
  above; the *reason* is not receipt-backed.

## Routed to

- **Ada** — scope/routing axes (1, 3): five-site growth and two-child routing.
- **Rose** — closeout/claims axes (4, 5, 6): gate discipline, PR claim
  consistency, pending handover step.
- **Fisher/Noether** (domain reviewers) — method evidence underlying the
  Emmy condition-1 deferral and the Jeffreys-weight correction, to settle the
  "unclear" rows.
