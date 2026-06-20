# After-task: R-Julia bridge Route B rho12 ~ x parity -> new capability row covered

**Date:** 2026-06-20
**Author:** Ada (autonomous, pushes held)
**Branch:** `shannon/overnight-audit-gaps-20260619`; DRM.jl engine =
`DRM.jl-direct-main` `f46035d`

## Task goal

Satisfy the documented Route B promote-path — a predictor-dependent `rho12 ~ x`
bridge parity test that asserts **coefficient** parity (not just the logLik
invariant) plus a **dedicated non-phylo bivariate-`rho12` bridge capability row**
(which did not exist) — verify it adversarially, and promote that one new cell if
earned.

## Files created or changed

- `tests/testthat/test-julia-tmb-parity.R` — added the "Route B lead novelty"
  helper + test (committed first as standalone evidence, `357810d1`).
- `docs/dev-log/dashboard/julia-capabilities.tsv` — new row
  `nonphylo_biv_rho12_predictor` = `covered` (9 -> 10 capability rows).
- `docs/dev-log/2026-06-20-bridge-parity-verification.md` — Route B update section.
- `docs/dev-log/dashboard/status.json` — activity entry + `updated` timestamp.
- `docs/dev-log/check-log.md` — new top entry.
- This after-task report.

The only package change is an additive, skip-guarded test.

## Checks run and exact outcomes

- Measurement (callr-isolated, DRM.jl `f46035d`): both engines converge; all eight
  fixed-effect coefficients matched by parm name; **coefficient parity max|Δ est|
  = 1.25e-6** (rho12 intercept 1.25e-6, rho12 slope 9.7e-8), **interval (Wald
  endpoint) parity max|Δ| = 1.27e-6**, **|ΔlogLik| = 6.3e-6**.
- `devtools::test(filter = "julia-tmb-parity")` with the bridge env: **19 PASS /
  0 FAIL / 1 SKIP** (skip = Route A tracked bug).
- `python3 tools/validate-mission-control.py`: `mission_control_ok` (now 10 Julia
  capability rows; slice metrics and other counts unchanged).
- `git diff --check`: clean.

## Consistency audit

- New capability row carries all 10 required fields; `evidence_url` is a GitHub
  issue URL (validator contract); `issue = drmTMB#544`; `claim_status = covered`;
  `r_bridge_status = supported`.
- The matrix "Bivariate residual correlation rho12" row (design 168 + status.json)
  was deliberately **not** changed — its bridge cell stays `planned`.
- The aggregate "R-Julia bridge gate" row is untouched.

## Tests of the tests

- The test pins `nrow(m) == 8` and exactly two rho12 rows, and requires
  `conf.status == "wald"` for all coefficients in both engines, so a silent name
  mismatch or empty/NA confint cannot pass — a point both verifiers flagged as the
  load-bearing guard for the merge-by-name approach.
- Native Wald variances come from the TMB `sdreport` covariance; Julia Wald
  variances come from the DRM.jl-marshalled `object$vcov` (independent sources), so
  endpoint agreement tests covariance transport, not a re-test of the point.
- The asserted bound `<= 1e-4` is the guarantee (measured ~1.3e-6 is the
  observed value); the cell prose cites the asserted bound.

## What did not go smoothly

- **Rose+Fisher split.** Fisher held the new row *pending the committed evidence
  package* (the test was uncommitted and the deltas lived only in narrative) and
  held the matrix bridge cell on *claim-width* grounds; Rose promoted both.
  Resolution: (1) committed the test first (`357810d1`) and banked the deltas in
  the check-log + this report, satisfying Fisher's process objection for the new
  row, which Rose already approved; (2) **held the matrix bridge cell** on the
  split + the Route C precedent (which moved only the TSV cell) + the
  default-to-hold discipline.
- The cwd-reset hazard persisted; mitigated by pinning 540b paths + bridge env.

## Team learning and process improvements

- **Commit the re-runnable evidence (the test) before the status promotion.**
  Fisher's hold was entirely "the numbers are not in a committed file." Committing
  the test first, then promoting with an after-task that banks the deltas, is a
  cleaner sequence than bundling test + promotion in one commit; adopt it for
  future evidence-earned promotions.
- A **single-capability** matrix row's bridge cell vs an **aggregate** gate row is
  a real distinction (Rose's argument). Whether per-cell bridge parity may move a
  single-capability matrix row's bridge cell is an open policy question worth an
  explicit owner/team decision — recorded, not silently resolved.

## Design-doc updates

- None to the formal design set. The matrix (`168`) was intentionally not changed
  (matrix bridge cell held). The capability registry is the per-cell source of
  truth and gained the new row.

## pkgdown/documentation updates

- None required (internal capability promotion; no exported surface changed). The
  new test is skip-guarded and inert on Julia-less machines.

## GitHub issue maintenance

- Deliberately unchanged (pushes held). The new row references `drmTMB#544`; the
  evidence trail is the committed test, the bridge-parity doc, the check-log, and
  this report.

## Known limitations and next actions

- Covered is **Wald CI + coefficient parity** for non-phylo fixed-effect
  `rho12 ~ x`; it is engine-vs-engine parity, **not** interval coverage.
- **Open decision:** whether to move the matrix "Bivariate residual correlation
  rho12" bridge cell `planned -> covered` now that direct per-cell bridge parity
  exists (Rose: yes; Fisher: not without the stricter registry-level standard).
- Still gated: phylogenetic `rho12` (`biv_rho12_phylo`), cross-family `rho12`,
  random-effect `rho12`, profile/bootstrap bridge intervals, Route A, q4/q8,
  binomial bridge, `engine_control`.
