# After-task: Confidence Eye coverage figures -> rho12 + non-Gaussian visual cells covered

**Date:** 2026-06-20 · **Author:** Ada (autonomous, owner-directed) · **Gate:** Florence
**Branch:** `shannon/overnight-audit-gaps-20260619`

## Task goal

The maintainer asked the coverage figures to use the Confidence Eye grammar (not
plain error bars; triangles permitted). Rebuild the rho12 and non-Gaussian
coverage figures with eyes from already-verified data, refresh the binomial to the
eye grammar for family consistency, and promote the visual cells.

## Files created or changed

- `docs/dev-log/figure-audits/_coverage-eye-helper.R` (new) — shared vertical
  Confidence Eye helper (quadratic-loglik lens, mirrors plot_corpairs()).
- `docs/dev-log/figure-audits/2026-06-20-rho12-recovery/` (new) — eye figure v5 +
  script + README.
- `docs/dev-log/figure-audits/2026-06-20-nongaussian-recovery/` (new) — eye figure
  v3 + script + README.
- `docs/dev-log/figure-audits/2026-06-20-binomial-coverage/` — eye figure v5 +
  script + updated README; the bar figure png + old script git-removed (preserved
  at 3f47503c).
- `docs/design/168-...md` + `status.json` — matrix rho12 + non-Gaussian visual
  cells planned -> covered; finish-board rho12 visual planned -> covered; activity
  + timestamp.
- `docs/dev-log/check-log.md`, this report.

## Checks run and exact outcomes

- Rendered all three eye figures; coverage ranges rho12 0.920-0.964, non-Gaussian
  0.926-0.970, binomial (Wald 0.946-0.964 / profile 0.930-0.972). Render-proof:
  every render inspected directly.
- `validate-mission-control.py`: `mission_control_ok` (matrix/finish/capability
  counts unchanged by cell-status edits). `git diff --check` clean.

## Consistency audit

- All three coverage figures now share one grammar (the eye helper), satisfying
  the class-specific consistency rule (Rose). The binomial was refreshed so the
  family does not mix bars and eyes.
- The eye is labelled MC uncertainty on the coverage estimate, NOT model
  uncertainty, in subtitle + caption of each figure (honest provenance).
- Grammar-contract note recorded: coverage plots use eyes only "for a specific
  reason" per design 39; the maintainer request is that reason.

## Tests of the tests

- Figures are built from committed CSV artifacts (no refit), so reproducible.
- Florence ran two rounds and caught a real defect (rho12 n=300 eye clipped by the
  y-axis = geometrically dishonest); the fix (expand ylim) was verified in the
  re-render. The honest weak cells (rho12 slope n=300 = 0.920; student n=300
  mu:x = 0.926) are shown unclipped.
- Underlying coverage numbers were Rose+Fisher-verified at the earlier cell
  promotions, so Florence is the right gate for these visual cells.

## What did not go smoothly

- First eye render clipped the widest (n=300) rho12 eye at the ylim floor, and the
  polygon fill produced a filled-square legend key. Both fixed (ylim; show.legend
  = FALSE on the polygon) and re-approved.
- The eye grammar differs from the documented coverage-plot default (dots + MCSE
  bars); applied as the maintainer's explicit "specific reason" exception, recorded
  in each README + the check-log.

## Team learning and process improvements

- A reusable `_coverage-eye-helper.R` now exists; future coverage figures should
  use it for one consistent grammar.
- Vertical Confidence Eyes can clip at axis limits where MCSE is large; always set
  ylim to contain the full +/- 1.96 MCSE lens, or the lens is dishonestly amputated
  (Florence catch).

## Design-doc updates

- `168` matrix visual cells updated. The visualization grammar doc (39) already
  permits the eye-for-a-reason exception; no doc change needed.

## pkgdown/documentation updates

- None now. The figures live in dev-log figure-audits; a future figure-gallery
  vignette could surface them (would also support the docs cells).

## GitHub issue maintenance

- Deliberately unchanged here (pushes held; branches already pushed). Separate
  R<->Julia coordination (Route A bug, bridge parity state) handled in its own
  step.

## Known limitations and next actions

- Visual cells are coverage DISPLAYS of already-verified evidence, not new
  inferential claims. Non-Gaussian Wald and rho12 bridge/profile cells are unchanged.
- A figure-gallery vignette surfacing these eyes would lift the binomial / rho12 /
  non-Gaussian `docs` cells (currently partial).
