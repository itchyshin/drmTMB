# After Task: Q-Series v1 Public Prose Sync for Shape and zi Local-Fit Rows

## 1. Goal

Synchronize public and status prose after the Q-Series v1.0 practical surface
admitted two row-specific local fit-only/extractor rows:
`student()` `nu ~ phylo(1 | id, tree = tree)` and zero-inflated `poisson()`
`zi ~ spatial(1 | id, coords = coords)`.

The goal was prose hygiene only. No API, formula grammar, likelihood,
dashboard cell, validator status, interval, coverage, or compute decision was
changed.

## 2. Implemented

`README.md`, `ROADMAP.md`, `NEWS.md`, and
`docs/dev-log/known-limitations.md` now name the two exact formulas as
row-specific local fit-only/extractor gates. The same prose keeps neighbouring
shape, inflation, structured non-Gaussian, bridge, q2/q4/q8, REML, AI-REML,
interval, coverage, `inference_ready`, `supported`, and public-support claims
out of scope.

`docs/dev-log/check-log.md` now records the prose sync and validation evidence.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Keep the wording row-specific and formula-specific.
- Treat this as a claim-boundary sync, not a status promotion.
- Use existing generated Q-Series release status as the source of truth.

Rejected alternatives:

- Do not add new examples or tutorials.
- Do not regenerate dashboard sidecars.
- Do not run Totoro, DRAC, or local recovery/coverage compute.
- Do not make a broad `student()` shape or zero-inflated count support claim.

## 3b. Claim Boundary

The admitted rows are:

```text
student(): nu ~ phylo(1 | id, tree = tree)
poisson() with zi: zi ~ spatial(1 | id, coords = coords)
```

Both are local fit-only/extractor rows. They do not establish Wald/profile
intervals, retained-denominator rates, coverage, `inference_ready`,
`supported`, q4/q8 promotion, bridge support, REML, AI-REML, or broad
shape/inflation/structured non-Gaussian support.

Rose-style audit: public files now use exact exceptions instead of bare
"planned" wording where the two local-fit gates exist, and they keep the same
no-promotion boundary where neighbouring routes remain planned.

## 4. Files Touched

- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-04-q-series-v1-public-prose-sync.md`

## 5. Checks Run

- `python3 tools/qseries_v1_claim_guard.py --summary`: passed with
  `qseries_v1_claim_guard_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, 104 Q-Series support cells, 8 exact
  `inference_ready` rows, and 0 `supported` rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`:
  passed with practical v1.0 surface 84/104 (80.8%),
  basic-distribution recovery 28/37 (75.7%), exact `inference_ready` 8/104,
  supported authority 0/104, and post-v1.0 rows 20/104.
- `git diff --check`: passed.

## 6. Tests of the Tests

The stale-wording scan still reports fenced phrases such as "beyond the exact
... local-fit gate"; it no longer reports the targeted public files as making a
bare broad Student-t `nu`, zero-inflated structured-effect, or shape/inflation
support claim. The claim guard independently accepts the public files.

## 7a. Issue Ledger

- No API, grammar, likelihood, validator, dashboard sidecar, or support-cell
  status issue was opened by this prose-only sync.
- The only checker issue was report-format debt: the first after-task draft
  missed required audit sections, and this revision adds them.

## 8. Consistency Audit

- README, ROADMAP, NEWS, and known-limitations now use the same exact formulas
  for the two row-specific local-fit gates.
- The prose matches the generated release status: 104 Q-Series rows, 84/104
  practical v1.0 rows, 8/104 exact `inference_ready` rows, and 0/104
  `supported` authority rows.
- No text in this slice changes coverage authorization, promotion status, or
  retained-denominator policy.

## 9. What Did Not Go Smoothly

- One earlier text-search command let shell backticks execute inside an `rg`
  pattern; it produced a harmless `command not found` message and made no file
  edits.
- The first after-task report draft was too short for the checker and required
  this audit-section expansion.

## 10. Known Residuals

- Older historical NEWS and roadmap entries still describe the state at the
  time of their original slice. Current top-level wording now supplies the
  exact exceptions and boundaries.
- The next v1.0 candidate queue remains 20 rows; this task did not attempt to
  move any additional rows.

## 11. Team Learning

Rose: prose synchronization after a row-level admission needs an explicit
claim audit, because stale broad "planned" language and over-broad "supported"
language are both failure modes.

Ada: the cheapest safe closeout here was documentation alignment plus claim
guard validation, not additional compute.

## 7. Follow-Up

Continue the v1.0-prep arc from the generated Q-Series candidate queue. Do not
treat this prose sync as new validation evidence.
