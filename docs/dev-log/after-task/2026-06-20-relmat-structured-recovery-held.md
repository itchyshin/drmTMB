# After-task: relmat (known-K) structured recovery -> evidence banked, cell HELD partial

**Date:** 2026-06-20 · **Author:** Ada (autonomous, owner-directed) · **Gate:** Curie + Fisher (both HOLD)
**Branch:** `shannon/overnight-audit-gaps-20260619`

## Task goal

Second harder-cap recovery (owner chose "new recovery sims for harder caps"):
native Gaussian relmat (user-supplied known relatedness) random-intercept
recovery, to promote the "Structural dependencies" point cell if the evidence is
clean and in scope.

## Files created or changed

- `docs/dev-log/simulation-artifacts/2026-06-20-relmat-structured-recovery/` (new)
  — `run.R`, `tables/relmat-recovery-summary.csv`, `tables/relmat-recovery-fits.csv`,
  `session-info.txt`, `README.md`.
- `docs/design/168-...md` + `status.json` — "Structural dependencies" next-gate text
  gains the relmat sub-type milestone; the **point cell is unchanged (partial)**.
- `docs/dev-log/check-log.md`, this report. status.json activity + timestamp.

No package change; no matrix/finish cell flipped.

## Checks run and exact outcomes

- Smoke (1 rep): confirmed relmat fit + sdpars name `relmat(1 | id)`; relmat SD
  0.602 vs truth 0.6. Pilot (50) then 500 reps; 1000 fits; 0 errors; pdHess 1.000.
- Recovery (rel bias n_id=40 / 80): b0 +0.8%/+0.8%; b1 +0.4%/+0.2%; sd_relmat
  -3.0%/-1.0%; sigma -0.2%/+0.1%. Fixed-effect Wald coverage 0.936-0.960 (all cells).
- `validate-mission-control.py`: `mission_control_ok` (counts unchanged -- no flip).
  `git diff --check` clean.

## Consistency audit

- No cell value changed; only the "Structural dependencies" next-gate text gained
  the relmat milestone (design 168 + status.json in sync). The evidence is banked,
  the boundary stays visible -- exactly the matrix's `partial` semantics.

## Tests of the tests

- Deterministic, reproducible; n_id ladder shows the structured-RE SD bias shrinks
  with levels (correct ML behavior). Both Curie (sim design) and Fisher (claim
  boundary) independently validated the artifact AND independently reached HOLD on
  the aggregate-row scope -- the verification caught an aggregate-row overclaim
  before it shipped.

## What did not go smoothly

- The recovery was clean (cleaner than random slopes -- known-K identifiability is
  strong, Wald coverage clean at every cell), but it does NOT flip a matrix cell:
  "Structural dependencies" is a six-sub-type aggregate row and relmat is one. The
  honest outcome is a held cell + banked evidence, not a promotion. This is the
  aggregate-row lesson (same shape as ADEMP): a single sub-capability sim cannot
  flip a broad row.

## Team learning and process improvements

- **Aggregate rows need a granularity to promote into.** rho12 could be promoted
  because a narrow per-capability TSV row existed; "Structural dependencies" has no
  per-sub-type matrix/registry row, so clean sub-type evidence has nowhere honest to
  land except the (wrong-granularity) aggregate cell. If the team wants structured
  sub-types to be individually promotable, add per-sub-type rows (animal / phylo /
  relmat / spatial / kernel / SPDE) to the matrix or a capability registry.
- Recovery sims for aggregate rows should be planned as a SET (cover most sub-types)
  before expecting a cell flip; a single sub-type banks a milestone, not a promotion.

## Design-doc updates

- `168` "Structural dependencies" next-gate text updated with the relmat milestone.

## pkgdown/documentation updates

- None.

## GitHub issue maintenance

- Deliberately unchanged (branch pushed; no issue maps to a held sub-type milestone).

## Known limitations and next actions

- "Structural dependencies" point stays partial. To flip it: comparable recovery
  for animal and phylo (next), then spatial/kernel/SPDE; OR add per-sub-type rows so
  relmat can be promoted at its own granularity (a structural decision for the owner).
- The relmat recovery is also clean on fixed-effect Wald coverage -- a future
  structured-effects wald promotion could use it once the row's granularity is settled.
