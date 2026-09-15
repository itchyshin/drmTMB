# Session handover: Claude → next Claude session — Dinnage audit, second arc

**From:** Claude (Fable), 2026-09-13.  **Branch:** `claude/audit-dinnage-wave1-20260913`
in `/Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1`, pushed as a draft PR.
Sibling branches `claude/audit-dinnage-wave2a-20260913` and `…-wave2b-…` are merged into it.

## Critical context

Every finding of Russell Dinnage's independent evaluation is a GitHub issue
(#1306–#1360, label `audit-dinnage`).  The response map is
`docs/dev-log/audits/2026-09-13-dinnage-independent-evaluation-response.md`;
the independent review is `docs/dev-log/audits/2026-09-13-dinnage-wave1-review.md`.
Do not re-verify what the map already records; do not re-file issues.

## OWED next steps (in order)

1. **M1, eleven remaining sites** (#1307): `src/drmTMB.cpp` `mi_family` 2–12
   quadrature blocks still multiply `weights(i)` inside the mixture.  Apply the
   same `w · log(mixture)` form with a weighted prior, one per-family
   invariance test (weights 1 vs 2 leave the MLE unchanged), TDD.
2. **M2** (#1308): `sigma()`/`predict()`/`residuals()` report the unclamped
   predictor; route through `drm_softclamp_log_sd()` (touches `R/drmTMB.R`,
   `R/methods.R`).
3. **S6** (#1315): write a design note before code — percentile bootstrap
   doubles ML bias; options are Wald/profile default or bias-corrected
   bootstrap.  Fisher review required before any code.
4. **S2** (#1301 comment): reconcile with the D-252 three-scale audit before
   touching `drm_constant_residual_sigma()`.

## Decisions waiting on Shinichi

- S3 (#1312): keep the log-scale MAP and document its mode at `1/rate`, or
  penalise on the SD scale so shrinkage toward zero holds.
- M4 count-mixture contract: `simulate()` now returns `NA` at masked rows for
  all thirteen families (two tests repaired to that invariant); confirm.
- Whether to send Russell the map now or after the draft PR merges.

## Do not

Merge or release; touch the 071 lane (PR #1304 is green as a draft and done);
run campaigns; spawn sub-agents from a scout.

## Landing state

CARRIED-OVER: `claude/audit-dinnage-wave1-20260913` · draft PR #1361 (CI green on os-matrix and the blind-spot job; release shards re-running after the C17 receipt re-certification) · why: awaits Shinichi's decisions on S3 (#1312) and the M4 count-mixture contract before merge · resume: `cd /Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1 && git pull && cat docs/dev-log/handover/2026-09-13-claude-handover-dinnage-audit.md`
FINDING-OF-RECORD: an outside, pre-registered, fresh-context audit found what months of inside review missed  vault-note: [[2026-09-13-why-an-outside-audit-found-what-we-missed]]
FINDING-OF-RECORD: S3's documented PC prior is correct; the measured defect is the log-scale MAP not being parameterisation-invariant  vault-note: [[DECISIONS#D-263]]
