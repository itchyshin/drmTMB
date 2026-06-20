# After-task: Binomial coverage figure -> visual cell covered

**Date:** 2026-06-20 · **Author:** Ada (autonomous, pushes held) · **Gate:** Florence (approve)
**Branch:** `shannon/overnight-audit-gaps-20260619`

## Task goal

Reduce the matrix "Bernoulli/binomial response family" **visual** cell from
`planned` with a Florence-approved, honest coverage figure built from
already-verified evidence (no new simulation).

## Files created or changed

- `docs/dev-log/figure-audits/2026-06-20-binomial-coverage/plot-binomial-coverage.R`
  (new) — plotting script.
- `docs/dev-log/figure-audits/2026-06-20-binomial-coverage/binomial-coverage-wald-profile-v3.png`
  (new) — the approved figure (v1/v2 superseded; v3 is the evidence file).
- `docs/dev-log/figure-audits/2026-06-20-binomial-coverage/README.md` (new) —
  figure-audit record incl. the Florence review cycle and alt-text.
- `docs/design/168-r-julia-finish-capability-matrix.md` + `status.json` — binomial
  `visual` cell `planned -> covered`.
- `docs/dev-log/check-log.md`, `status.json` activity/timestamp, this report.

No package R/C++ change.

## Checks run and exact outcomes

- Render: `Rscript plot-binomial-coverage.R` -> 20 rows (12 Wald + 8 profile),
  coverage range 0.930-0.972. PNG written at 144 dpi.
- Render-proof: inspected each rendered PNG (v1, v2, v3) directly before acting.
- `python3 tools/validate-mission-control.py`: `mission_control_ok` (counts
  unchanged; binomial row already carried evidence_url for its covered cells).
- `git diff --check`: clean.

## Consistency audit

- The promotion moves only the binomial `visual` cell in design 168 + status.json
  (in sync). No other cell touched. The figure visualises the SAME coverage
  numbers already banked and Rose+Fisher-verified at the Wald/profile promotions.
- Activity `who = Florence` (a standing-review name; validator-valid).

## Tests of the tests

- The figure is built from committed CSV artifacts, not refits, so it is
  reproducible from the banked evidence.
- Florence (the designated figure gate) ran two adversarial passes and explicitly
  checked the overclaiming hazards a boundary reviewer would (title register,
  band-as-threshold, MCSE framing, cross-facet comparability, accessibility) and
  approved only v3.
- The weakest cell (profile cbind slope n=240, coverage 0.930, lower MCSE bar
  ~0.908) is shown honestly and unclipped — the display does not hide the soft cell.

## What did not go smoothly

- v1 had overlapping x-axis labels (fixed by moving encoding to a row facet before
  review). v2 drew a "revise" (comparability + sole-colour encoding). Both
  resolved in v3.
- Full relabel of Wald cells by `n` was not possible: the artifact CSVs carry no
  reliable cell_id->n map. Resolved the comparability concern via the caption and
  documented the design grid instead of guessing labels.

## Team learning and process improvements

- For a **visual** cell over already-verified data, Florence is the right gate; a
  separate Rose+Fisher pass is redundant when the figure only visualises evidence
  those lenses already certified. Record which lens gated which cell type.
- Render-proof discipline (fresh PNG filename per revision, inspect the exact
  image) caught the v1 label overlap and confirmed the v3 fixes.

## Design-doc updates

- `168` matrix binomial `visual` cell updated. No other design doc affected.

## pkgdown/documentation updates

- None required now. The figure lives in the dev-log figure-audits; if a binomial
  article or pkgdown gallery wants it later, the script + PNG are ready.

## GitHub issue maintenance

- Deliberately unchanged (pushes held). Evidence trail: the figure-audit README,
  check-log, and this report.

## Known limitations and next actions

- `visual = covered` is a coverage DISPLAY of fixed-effect Wald + profile
  evidence, not a calibration proof, and native TMB only. Random/structured
  effects, bivariate/mixed, the Julia bridge, and headline coverage are unchanged.
- A natural follow-up: surface this figure in a binomial pkgdown article/gallery
  (would also support the binomial `docs` cell, currently partial).
