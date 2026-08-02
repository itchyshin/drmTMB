# C18 `mc-0604` completion review — animal-model relatedness zero-one-beta `zoi` q1

## Decision

**GO — point-fit recovery only.** `mc-0604` is the exact ordinary-ML
`zero_one_beta()` route with one unlabelled q1 `animal(1 | ..., ...)`
intercept on `zoi`'s linear predictor. This is a single-cell ledger
transition. It does not support profiles, intervals, coverage, inference
readiness, q2-plus effects, slopes, labels, covariance, simultaneous
zoi+coi structured effects, or structured effects in another
distributional parameter.

## History: this was not a clean first-pass GO

The D-43 completion panel first reviewed the eight-cell C18 recovery run
(commit `6dcaf0a1a`, "seven pass, one blocked") and returned **NOT-DONE
from two of three reviewers**, withholding the milestone claim, over three
defects found in the surrounding implementation rather than in the
recovery evidence itself:

- **F1** — `summary()` crashed for every non-phylo atom provider (animal,
  relmat, phylo_interaction): `validate_profile_targets()`'s allowlist
  never gained the profile-target notes `R/profile.R` emits for those
  fits, so the most basic post-fit call died with an internal error. A
  cell whose `summary()` crashes is not implemented.
- **F2** — `zoi ~ spatial(...)` / `coi ~ spatial(...)` were code-admitted
  and fitted despite spatial being deferred to the mesh/SPDE lane by owner
  decision; `drm_reject_phase1_terms` told users spatial was
  "Implemented" for the atoms, and mc-0606/mc-0616 carried zero recovery
  evidence.
- **F3** — a missing response combined with a structured atom effect was
  admitted, against the design doc's section 8 refusal.

None of the three defects touched `mc-0604`'s recovery evidence — the four
retained fits below were not re-run. All three were repaired in commit
`2b60076fd` (allowlist extended; spatial refusal restored and the
user-facing hint corrected; a missing-response guard added inside
`drm_build_zero_one_beta_spec`). The reviewers' own stated remedy was that,
once repaired, the eight passing atom cells convert to GO on the existing,
unchanged recovery evidence — which is the review recorded below. This is
not presented as a clean first-pass GO; it is a repaired second pass on
evidence that never needed to change.

## Evidence bound to the decision

- Four planned source-pinned recovery attempts (seeds `2026080201-2026080204`) are
  retained in
  `docs/dev-log/implementation-recovery/2026-08-02-lane-c-c18-mc-0604-zob-animal-zoi-q1-local-recovery/raw-attempts.tsv`; all
  four passed `fit_ok`/`pdHess`/finite-gradient convergence, the C16 bar
  (mean relative tau error <= 0.40), and the C18-specific per-group
  separation filter (`n_separated_groups = 0` in all four attempts, every
  group retaining a zero, a one, and an interior observation).
- `docs/dev-log/implementation-recovery/2026-08-02-lane-c-c18-mc-0604-zob-animal-zoi-q1-local-recovery/summary.tsv` records
  4/4 passing attempts, mean relative tau error **0.152**, decision
  `PASS_POINT_RECOVERY_LOCAL`.
- Minimum conditional-mode correlation against the simulated latent field
  across the four seeds was **0.62**.
- A separate `tau_truth = 0` boundary-diagnostic control in the same
  directory is retained as a sanity check only (`decision =
  BOUNDARY_DIAGNOSTIC_ONLY`); it is not part of the recovery gate and does
  not substitute for it.
- `docs/dev-log/implementation-recovery/2026-08-02-c18-atom-dgp-feasibility`
  binds the recovery DGP to the 28,800-fit Totoro identifiability campaign
  that selected it as the only setting clearing the full bar for both
  atoms.

## Fresh independent review

| Lens | Verdict | Scope checked |
| --- | --- | --- |
| Noether | GO | Parameter map, zoi endpoint routing, animal structured-atom oracle, F1/F2/F3 repair scope. |
| Fisher | GO | Exact DGP, retained four attempts, local recovery threshold, per-group separation filter, and carrier-control diagnostic. |
| Rose | GO | Claim boundary, source equivalence, retained attempts, no-profile fence, and honest history of the D-43 repair. |

All three reviews apply only to `mc-0604` at `point_fit_recovery` grade.
