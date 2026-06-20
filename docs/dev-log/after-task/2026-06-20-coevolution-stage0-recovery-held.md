# After-task: coevolution Stage 0 — phylo_interaction SD recovery -> evidence banked, HELD diagnostic

**Date:** 2026-06-20 · **Author:** Ada (autonomous, owner-directed) · **Gate:** Fisher (ENDORSE-AS-HELD) + numerical correctness verified directly (Curie subagent rate-limited)
**Branch:** `shannon/overnight-audit-gaps-20260619`

## Task goal

design 178 Stage 0: validate that the headline coevolutionary `phylo_interaction()`
term (Hadfield et al. 2014, the `A^(p) (x) A^(h)` Kronecker effect) recovers on its
own — the honest single-component baseline before the Stage-1 additive engine
extension. Promote a cell only if a scoped granular row exists; otherwise bank as a
HELD diagnostic (relmat / phylo-SD precedent).

## Files created or changed

- `docs/dev-log/simulation-artifacts/2026-06-20-coevolution-phylo-interaction-recovery/`
  (new) — `run.R`, `README.md`, `tables/coevolution-recovery-{fits,summary}.csv`,
  `run-500.log`, `session-info.txt`.
- `docs/design/178-coevolution-tale-of-two-phylogenies.md` — Stage 0 bullet marked
  DONE; new "Stage 0 evidence" subsection with the measured recovery + verification.
- `docs/dev-log/check-log.md`, this report. status.json activity + timestamp.

No package change; no matrix/finish cell flipped.

## Checks run and exact outcomes

- Smoke (2 reps): clean fit, coev SD recovered, 0 errors, pdHess 1.000.
- 500 reps/cell, ladder n_host = n_parasite in {6, 10, 14}; 1500 fits; 0 errors;
  pdHess 1.000; elapsed ~512 s.
- Recovery: coevolutionary SD rel bias **-6.4% / -2.5% / -1.6%** (consistent
  estimator). Slope rel bias <= 0.2% (Wald 0.940-0.962); sigma unbiased; intercept
  near-unbiased mean, Wald 0.906 / 0.922 / 0.930 (mean/phylo-field confounding).
- Independent 30-rep re-run reproduced (-3.6% / -4.0% / -1.8%; 0 errors; pdHess
  1.000) — n_sp=14 endpoint matches the 500-rep within MC noise.
- `validate-mission-control.py`: `mission_control_ok` (counts unchanged — no flip).
  `git diff --check` clean.

## Verification (adversarial)

- **Numerical correctness** (Curie's role; subagent hit a session rate-limit twice,
  so performed directly in-thread): the DGP's `kronecker(A_parasite, A_host)` with
  host-fastest `expand.grid` matches the model's `kronecker(precision2, precision1)`
  and `obs_node = (node2-1)*n1 + node1` (`R/drmTMB.R:8809-8815`); the augmented
  `S^-1` tip-marginal equals `sd^2 * (A_p (x) A_h)` with unit-diagonal `A`, so
  `sd_coev = 0.7` maps 1:1 to `fit$sdpars$mu`. The monotone bias-shrink toward 0 is
  the positive control: a transposed/mis-scaled DGP would not converge to 0.
- **Inference/scope** (Fisher): ENDORSE-AS-HELD. Two required README edits applied —
  (1) removed a confounded cross-diagnostic overclaim ("most identifiable of the five
  components" ranks four unmeasured components; the phylo-SD contrast confounds
  species count with n_each replication and total N); (2) added the intercept-Wald-
  below-0.93-floor disclosure to the Boundary section. Also fixed a factual slip
  ("balanced trees" -> rcoal).

## Consistency audit

- No cell value changed; design 168 / status.json matrix counts untouched
  (validator green, 25/68). The only registry-visible change is a status.json
  activity entry + timestamp. design 178 and the artifact are in sync.
- HELD rationale matches the relmat precedent: there is no granular coevolution /
  `phylo_interaction` row, and the aggregate "Structural dependencies" row cannot be
  flipped by one sub-type.

## Tests of the tests

- Positive control: the bias converges to ~0 with species count (a constant rel
  bias would indicate a scaling bug; a transposed Kronecker would not converge).
- Reproducibility: independent 30-rep re-run matches direction + magnitude.
- Scope guard: SD rows carry `wald_coverage = NA` (no interval claim); only the two
  fixed effects get `confint` coverage.

## What this unblocks

This is the validated single-component baseline for design 178 Stage 1 (the additive
engine extension summing host-main + parasite-main + coevolution). The coevolutionary
component recovers honestly alone, so Stage 1 builds on validated ground; the
"needs adequate N" contract is now quantified for the interaction term.

## Follow-ups (not done here)

- Stage 1 engine extension (multi-block structured RE per dpar) — scoped this session
  into sub-slices 1A/1B/1C with a file:line change-map (banked separately in design
  178). Gauss-level, TDD-first.
- Coevolutionary-SD interval calibration (profile/bootstrap) — not run; the wald/
  profile side of the interaction term remains unclaimed.
