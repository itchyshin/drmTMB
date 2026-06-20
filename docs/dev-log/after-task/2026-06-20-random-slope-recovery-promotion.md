# After-task: Gaussian random-slope recovery -> Random slopes point cell covered

**Date:** 2026-06-20 · **Author:** Ada (autonomous, owner-directed) · **Gate:** Curie + Fisher
**Branch:** `shannon/overnight-audit-gaps-20260619`

## Task goal

Owner chose "run new recovery sims for harder capabilities". Produce a native
Gaussian random-slope recovery (a harder cap than fixed-effect-only) and promote
the matrix "Random slopes" point cell if the evidence is clean.

## Files created or changed

- `docs/dev-log/simulation-artifacts/2026-06-20-gaussian-random-slope-recovery/`
  (new) — `run.R`, `tables/random-slope-recovery-summary.csv`,
  `tables/random-slope-fits.csv`, `session-info.txt`, `README.md`.
- `docs/design/168-...md` + `status.json` — "Random slopes" point cell
  `partial -> covered` (scoped); evidence_url repointed; activity + timestamp.
- `docs/dev-log/check-log.md`, this report.

No package R/C++ change.

## Checks run and exact outcomes

- Smoke (3 reps): confirmed fit + `fit$sdpars$mu` extraction names. Pilot (50) then
  500 reps. 1000 fits total; 0 fit errors; pdHess 1.000.
- Recovery (rel bias, n_group=40 / 80): b0 +1.0%/+0.3%; b1 -0.8%/-0.1%; sd_int
  -2.8%/-1.0%; sd_slope -6.7%/-1.1%; sigma 0.0%. Fixed-effect Wald coverage n=40
  b0 0.932 / b1 0.922; n=80 b0 0.960 / b1 0.946.
- `validate-mission-control.py`: `mission_control_ok` (counts unchanged).
  `git diff --check` clean.

## Consistency audit

- Only the "Random slopes" point cell moved (design 168 + status.json in sync).
  Wald / profile / bootstrap / simulation / bridge cells on that row unchanged.
- The scoped claim (point recovery; RE-SD bias disclosed; rho excluded; Wald held)
  is identical across the matrix prose, status.json next text, and the artifact README.

## Tests of the tests

- Deterministic (`master_seed`), reproducible. The n_group ladder {40, 80} is the
  test of consistency: the RE-SD bias shrinks with group count (the signature of
  correct ML variance-component behavior, not a defect).
- Fisher independently recomputed the headline rel-bias numbers from the raw
  5000-row per-fit CSV and they matched the summary exactly; the SD-extraction
  regex correctly separates sd_int from sd_slope (0 collapsed reps).
- The sim was sensitive enough to surface a real small-n effect (sd_slope -6.7%,
  bias/MCSE -6.2 at n=40) rather than rubber-stamping; that drove the honest
  "covered up to a documented shrinking bias" framing.

## What did not go smoothly

- The pilot (50 reps) showed a spurious -18.7% rel bias on the small intercept at
  n_group=40 that vanished at 500 reps (+1.0%) -- Monte-Carlo noise at 50 reps;
  the 500-rep scale was necessary to separate noise from the real RE-SD bias.
- Used the CORRELATED random-slope model (`(1 + x | id)`); the design-168 milestone
  orders independent slopes before correlated. Curie+Fisher judged the correlated
  model subsumes independent for point recovery (a procedural skip, not an
  evidentiary gap), and scoped the claim accordingly.

## Team learning and process improvements

- RE variance-component recovery must be read with an n_group ladder: a single
  small-n cell can look "biased/failed" when it is correct estimator behavior. The
  consistency trajectory (bias -> 0 as groups grow) is the evidence that the
  point estimator is sound; "covered" then means "recovered up to a documented,
  shrinking ML bias", which must be stated, not hidden.

## Design-doc updates

- `168` "Random slopes" point cell updated with the scoped claim.

## pkgdown/documentation updates

- None now. A future figure (Confidence Eye of the recovery) could lift the
  Random slopes visual cell; not done this slice.

## GitHub issue maintenance

- Deliberately unchanged (branch pushed; no single issue maps to this scoped
  point-cell promotion). Evidence: the artifact README + check-log + this report.

## Known limitations and next actions

- Covered is POINT recovery only, native Gaussian, one correlated block. Next
  natural slices: an independent-slopes-only confirmation; a random-slope RE-SD
  interval-calibration study (would address the wald/profile cells); a Confidence
  Eye recovery figure (visual cell); the same pattern for non-Gaussian random slopes.
