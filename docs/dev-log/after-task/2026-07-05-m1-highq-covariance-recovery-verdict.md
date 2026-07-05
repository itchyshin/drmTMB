# After Task: M1 — high-q covariance recovery verdict (104/104 arc)

Meta: 2026-07-05 · Claude (Shannon) · branch `drmtmb/fix-family-conventions` · M1 of the
Q-Series 104/104 ultra-plan.

## 1. Goal

M1 of the 104/104 arc: confirm whether drmTMB's among-endpoint structured covariance is
PD-by-construction and endpoint-generic (q2/q4/q6/q8), then build only what's missing.
Prove it by recovering a known 8-endpoint Σ at Santi-scale n and preserving the working q4
fit. Do NOT admit q6/q8 rows, change intervals/coverage, or touch claims/dashboard.

## 2. Implemented (evidence, no engine edits)

- **P1.1 diagnosis:** the TMB engine already has TWO PD-by-construction among-endpoint
  correlation paths — `UNSTRUCTURED_CORR` (default `qgt2_corr_parameterization=0`) and a
  partial-correlation Cholesky (`drm_partial_correlation_cholesky_corr`, `=1`), plus a
  Cholesky density kernel that stays finite as ρ→±1 (`src/drmTMB.cpp:124,159,181`). Unit
  tests already prove C++ = R algebra at q=8 for both (`test-phylo-utils.R:821,968,1340`,
  186 assertions pass).
- **The documented "q8 blocker" (docs/design/220) was a data-size misdiagnosis:** the
  admission gate that declared q8 blocked estimated a **36-parameter** covariance (8 SDs +
  28 correlations) from **16 groups** (all 3 hard seeds, variant `more_levels`, `n_levels=16`;
  `…2026-06-29-q4-animal-partial-correlation-admission-probe-local/`). A non-PD Hessian there
  is the correct answer, not an engine failure.
- **Recovery sim** (`docs/dev-log/simulation-artifacts/2026-07-05-m1-highq-recovery/`,
  streamed per-fit): see §5.
- **No engine C++/R change.** P1.2 (log-Cholesky reparam) is a NO-OP.

## 3a. Verdict

- **q4 all-four (4 SD + 6 corr): CLEAN at Santi-scale.** Fails at n=64 (conv=1, pdHess=FALSE,
  cap-saturated), pristine at n=512/1024 (**conv=0, pdHess=TRUE**, no cap-saturation, rmse
  ~0.05). This is Santi's STAN-matched case; the failure→success flip with n *is* the
  data-size principle proven end-to-end.
- **q8 all-four one-slope (8 SD + 28 corr): recovers, `pdHess=FALSE` is genuine.** rmse falls
  0.48→0.33→0.18→0.15→0.116 as groups grow 16→1024; cap-saturation gone by n=256. But
  `pdHess=FALSE` **persists at 1024 groups**, is **not** an iteration cap (`iter.max=8000`),
  and the partial-Cholesky path does not fix it → some of the 28 correlations are genuinely
  weakly identified (near-singular Hessian).

## 3b. Inference doctrine (Shinichi, 2026-07-05)

`pdHess=TRUE` is the ideal, not the only door. For q8: **full (re-maximizing) profile is the
PRIMARY CI tool** — it parallelizes across targets via `confint(..., method="profile", workers=)`
(`R/profile.R:90`, `profile_parallel_plan`), so the 28+ targets fan across cores in reasonable
wall-clock; **bootstrap** is the fallback. **ELR / "estimated profile" is EXCLUDED** for these
targets (it under-covers when the target correlates with the nuisances; q8's correlations are
mutually correlated by construction). Getting q8 to `pdHess=TRUE` is a separate
**reduced-rank factor-analytic** estimation arc (glmmTMB `rr()` / Meyer-WOMBAT), gated by
recovery-vs-truth — NOT part of M1 and NOT a few-days fix.

## 4. Files touched

- `docs/dev-log/simulation-artifacts/2026-07-05-m1-highq-recovery/` (helpers + streaming
  runners 03/04 + results TSVs + logs)
- `.claude/agents/simulation-tester.md`, `.codex/agents/simulation-tester.toml` (Curie
  long-sim discipline: stream+flush, fast-first, heartbeat — learned from the empty-60-min run)
- (plan) `~/.claude/plans/snappy-honking-parrot.md` — the 104/104 ultra-plan (copied into the
  repo alongside this bank; see the handover)

No `R/`, `src/`, dashboard support-cell, ledger, or claims file changed. Mission Control
truth unchanged (94/104 / 8/104 / 0/104 / 10/104).

## 5. Checks run (streamed recovery evidence)

| block | param | n_tip | groups | conv | pdHess | max\|ρ\| | rmse | frob |
|---|---|---|---|---|---|---|---|---|
| q4 | 0 | 64 | 64 | 1 | FALSE | 0.994 | 0.331 | 1.145 |
| q4 | 0 | 512 | 512 | 0 | TRUE | 0.473 | 0.053 | 0.182 |
| q4 | 0 | 1024 | 1024 | 0 | TRUE | 0.578 | 0.055 | 0.191 |
| q8 | 0 | 16 | 16 | 1 | FALSE | 0.974 | 0.475 | 3.555 |
| q8 | 0 | 256 | 256 | 1 | FALSE | 0.863 | 0.178 | 1.329 |
| q8 | 0 | 512 | 512 | 1 | FALSE | 0.733 | 0.146 | 1.096 |
| q8 | 0 | 1024 | 1024 | 1 | FALSE | 0.789 | 0.116 | 0.870 |
| q8 | 1 | 1024 | 1024 | 1 | FALSE | 0.729 | 0.210 | 1.569 |

`test-phylo-utils.R`: 186 assertions pass (q=8 math contract, both parameterizations).

## 6. Tests of the tests

Recovery metrics compare fitted `corpars$phylo` (upper-tri) to the simulated truth
(Frobenius + per-correlation rmse); cap-saturation flagged at |ρ|>0.99; DGP uses a known 8×8
PD Σ (low-rank+diagonal). q8 syntax `(1 + x | p | species)` on all four endpoints parses and
fits (no parser gate at q8).

## 7a. Issue ledger

No GitHub issue opened/closed. Evidence-only; PR #730 (the 94/104 checkpoint) unchanged.

## 8. Consistency audit (4-lens gate — signed off, honest bar)

- **Curie:** q4 clean at ≥512; q8 recovers at adequate n; cap-saturation resolves with n;
  non-PD reflects weak-ID, not engine failure.
- **Noether:** engine unchanged; q=8 C++ = R algebra; boundary-safe.
- **Fisher:** q8 → parallel profile primary / bootstrap fallback / ELR excluded; small-n
  non-convergence = data-insufficiency per the data-size rule.
- **Rose:** no row admitted, no dashboard/claims touched; doc-220 "production-transform
  blocker" corrected as a data-size artifact.

## 9. What did not go smoothly

The first recovery sub-agent (Curie) ran ~60 min and produced nothing because it batch-wrote
results after a 10-seed × 256-tip loop; the interrupt discarded it. Fixed by a lean streaming
runner (fast-first, per-fit write+flush, heartbeat). Lesson recorded in the Curie agent files
and the brain's `LESSONS.md`.

## 10. Known residuals / arc implications

- **The feared Phase-1 engine build (log-Cholesky, ~4–7 days) is unnecessary.** The engine
  already recovers high-q Σ at adequate n. Phase 2/3 (q6/q8 rows) collapse to **parser
  admission + recovery-gating at Santi-scale + parallel profile/bootstrap intervals** — not
  engine surgery. The 104/104 arc is materially de-risked.
- **q8 `pdHess=TRUE` is the one deferred piece** → reduced-rank factor-analytic estimation
  arc (its own methods work).
- Next milestone **M2 = q6 admitted (4 providers, recovery)**.

## 11. Team learning

The "engine blocker" narrative for high-q was, at root, a violation of the data-size rule:
complex models judged on tiny fixtures. Diagnose "does it work?" only at n sized to the model,
and separate engine failure from honest data-insufficiency. `pdHess=FALSE` on a well-recovered
covariance is a routing decision (profile/bootstrap), not a verdict of failure.
