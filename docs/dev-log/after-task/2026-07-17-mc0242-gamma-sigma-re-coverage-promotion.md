# After Task: Gamma sigma random-intercept interval + coverage promotion (mc-0242)

## 1. Goal

Give the Gamma σ random intercept `(1 | id)` route (cell `mc-0242`) its first interval + coverage
evidence and, if it cleared a pre-registered gate under a fresh memo-blind D-43, promote it from
`point_fit_recovery` to `inference_ready_with_caveats` over the exact tested domain — or return a
documented non-promotion. The direct sibling of lognormal `mc-0382` (Arc 4a) and beta-phylo
`mc-0017`, reusing that methodology (Wald + profile coverage, pre-registered gate, D-43).

## 2. Implemented

- **S0 — estimand freeze + plan-review**
  (`docs/dev-log/2026-07-17-mc0242-gamma-sigma-coverage-estimand-alignment.md`, rev 2):
  estimand = population SD of the σ-RE on the log-CV scale (true 0.40), scored on the natural RE-SD
  scale (`confint(method="profile")`, `transformation="exp"`); iid-uncentered gamma DGP; the
  precedent-anchored `[0.925,0.975]` coverage-CI-overlap gate; finite-profile policy; directional
  pre-commit; M=8 pre-declared exploratory. Plan-reviewed **before compute** by Fisher (method) +
  Rose (scope) — both CONDITIONAL-DONE; every fix folded in (corrected the scale contract, the
  ledger edit locator by cell_id, the `test_capability_ledger.py` count guard, the smoke fixture).
- **S1 — machinery + gating smoke:** verified by code inspection (`has_sigma_random_effects` includes
  gamma; `profile_targets` gamma `sd:sigma:(1|id)` profile_ready) and a **local gating smoke** — one
  fit per M ∈ {8,16,32,64} on the exact coverage fixture; all four converged with a finite, in-range
  profile interval (the §6 STOP criterion passed), clearing the one residual pre-compute risk.
- **S2 — runner** (`tools/run-gamma-sigma-re-coverage.R`): gamma-only, iid-uncentered, profile + Wald
  per replicate, per-M point-bias (`sd_hat = exp(estimate)`), directional misses, finite-profile
  rate, crash-safe per-cell streaming, SMOKE mode with the STOP gate. Structure adapted from the
  Arc-4a `generate-profile.R`.
- **S3 — campaign (Totoro):** fresh `main` clone (`pkgload::load_all`, drmTMB 0.6.0.9000 @ a9b2633c),
  `OPENBLAS_NUM_THREADS=1`, 90 workers, N=1200/cell × M{8,16,32,64} = 4800 fits. **Zero failures:
  4800/4800 eligible, profile_finite_rate 1.000 at every M.** Artifacts in
  `docs/dev-log/simulation-artifacts/2026-07-17-gamma-sigma-re-coverage/`.
- **S4 — memo-blind D-43:** Fisher / Rose / **Noether** (Noether the fresh lens, not in the
  plan-review). Round 1: Noether **DONE** (full math contract verified + repro confirmed ≤5e-5);
  Fisher & Rose **conditional NOT-DONE** — science and every number confirmed exact, fix-list before
  landing. All fixes applied; a memo-blind **round 2** returned Fisher **DONE** + Rose **DONE**, so
  the panel is **3 DONE / 0 NOT-DONE — D-43 passed.**
- **S5 — promotion:** `mc-0242` → `inference_ready_with_caveats` over M ∈ {16,32,64} in the ledger,
  with `ev-mc-0242-arc4b` / `tr-mc-0242-arc4b` rows, `notes` mirrored, regenerated derived outputs.

## 3. Result and gate

| M | coverage | exact 95% CI | label | above:below | sd̂ (rel-bias) | Wald ∞ | SD=0 pin |
|---|---|---|---|---|---|---|---|
| 8  | 0.9308 | [0.9150,0.9445] | mildly a-c — exploratory | 72:11 | 0.349 (−12.7%) | 2.25% | 20.8% |
| 16 | 0.9333 | [0.9177,0.9468] | mildly a-c (borderline) | 65:15 | 0.373 (−6.9%) | 0 | 1.8% |
| 32 | 0.9450 | [0.9306,0.9572] | nominal within MC error | 45:21 | 0.387 (−3.2%) | 0 | 0 |
| 64 | 0.9458 | [0.9315,0.9579] | nominal within MC error | 48:17 | 0.393 (−1.8%) | 0 | 0 |

**Firmly-certified floor M ≥ 32** (both CIs inside [0.925,0.975] and bracket 0.95). **M=16 promoted
as a borderline extension** (CI straddles 0.925, not firmly certified — matches mc-0382's M=16).
**M=8 excluded** (pre-declared exploratory; coverage passes the band but the arm is degenerate:
20.8% of profiles pin at SD=0, 2.25% Wald ∞-width, −12.7% bias). All three pre-registered
predictions confirmed: above-U miss dominance (Laplace bias-low signature); point bias monotone with
M; profile fixes the ∞-width artifact (100% finite where Wald degenerates).

## 4. Mathematical contract (Noether, DONE)

DGP `sigma_i=exp(-0.6+u[id])`, `shape=1/σ²`, `scale=μ·σ²`, `mu=exp(0.2+0.5x)` gives E[y]=μ, CV[y]=σ
exactly (verified against `src/drmTMB.cpp` model_type 5 and the R `rgamma(scale=)` call). The
profiled `sd:sigma:(1|id)` is on the natural RE-SD scale (`transformation="exp"`, R/methods.R:4309),
compared to truth 0.40 on that same scale — no Jacobian/scale mismatch; the exp map is monotone so it
cannot change the coverage number, and it is exactly why profile returns finite intervals at the
SD→0 boundary where log-SD Wald blows up. Harness strings `log_sd_sigma` / `sd:sigma:(1 | id)`
resolve for gamma (1200/1200 non-NA at every M).

## 5. Decisions & rejected alternatives

- **Promote M∈{16,32,64}, not M≥32-only:** matches the mc-0382 precedent (whose M=16 was 0.9325);
  M=16 kept with an explicit borderline/not-firmly-certified caveat rather than dropped.
- **iid-uncentered DGP** over the Arc-2c mean-centered recovery DGP — centering changes the
  finite-sample SD estimand (Arc-4a v1 failure mode). The divergence is disclosed and the per-M point
  bias is measured *at the coverage fixture* to repair the missing centered-vs-uncentered link.
- **Venue Totoro, not DRAC** — cheap ordinary iid σ-RE (~4,800 fits, minutes), not DRAC-shaped.
- **Fisher's "M=64 CI upper → 0.9580" correction REJECTED:** the pipeline value is 0.95794991…,
  which rounds to **0.9579**; Fisher's 0.9580 was a mis-rounding (caught by reading the TSV directly).

## 6. Files created / modified

- New: `tools/run-gamma-sigma-re-coverage.R`;
  `docs/dev-log/simulation-artifacts/2026-07-17-gamma-sigma-re-coverage/` (README, repro-check,
  campaign raw/summary/manifest, local smoke raw/summary/manifest, campaign-totoro.log).
- Ledger: `cells.tsv` (mc-0242 flip: evidence_tier, primary_evidence_id, claim_boundary, next_gate,
  notes, updated_commit/date), `evidence.tsv` (+`ev-mc-0242-arc4b`), `transitions.tsv`
  (+`tr-mc-0242-arc4b`); regenerated derived outputs (surface md/html, census, family-map).
- `tools/tests/test_capability_ledger.py`: point_fit_recovery count 164→163.
- **R package source (`R/`, `NAMESPACE`, `man/`, `src/`) NOT changed** — the profile + gamma σ-RE
  machinery already existed on `main` (A0 fix included).

## 7. Checks run

- Local gating smoke: all M finite in-range profile + convergence (STOP passed).
- Campaign: 4800/4800 eligible, profile_finite_rate 1.000, zero fit/convergence/Hessian/profile
  failures.
- `python3 tools/capability_ledger.py --write && --check`: **OK (30 generated outputs)**.
- `python3 -m unittest tools.tests.test_capability_ledger`: the point_fit_recovery count guard now
  passes (163). **One unrelated failure** — see §10.
- Cross-platform repro (local Mac-ARM smoke vs Totoro x86, seed 20260901): **≤5e-5** for M∈{16,32,64}.
- `--as-cran` not required (`R/` unchanged).

## 8. Tests of the tests

The runner's coverage indicator, exact-binomial CI, MCSE, and directional-miss logic reuse the
proven Arc-4a `generate-profile.R` code. Two independent D-43 reviewers (Fisher, Noether) recomputed
the promotion-arm Clopper–Pearson CIs and coverage from the raw hits/N rather than trusting the
pipeline columns; both matched exactly. The M=8 SD=0 boundary pile-up (20.8%) and the M=64 CI-upper
value were re-derived from raw by hand before entering the claim.

## 9. Consistency audit

The `claim_boundary` leads with the worst-in-range (M=16 0.9333), names the single fixture, uses the
frozen directional labels, states MC-coverage-backed-unlike-interval_feasible, names AGHQ (not REML,
citing mc-0243) as the residual lever, fences M=8 + the recovery-fixture divergence + "mc-0382 is not
gamma evidence". `notes` was **substituted** (not appended) to mirror the new claim_boundary, so no
stale point_fit_recovery prose survives in the promoted row (Rose's silent-desync catch). Edits keyed
to cell_id mc-0242, not line 246/mc-0243.

## 10. What did not go smoothly / known residuals

- **Bash/Agent safety classifier ("claude-opus-4-8 temporarily unavailable") was intermittently down
  for long stretches** — forced many retries on the Totoro polls, the repro check, and the ledger
  runs (the same gotcha the 2026-07-17 handover flagged).
- **One pre-existing unittest failure, unrelated to mc-0242:**
  `test_active_qseries_surfaces_keep_debug_only_routes_diagnostic` asserts a Poisson-spatial-slope
  string in `pkgdown-site/llms.txt`. That string is present in the generated README but absent from
  `llms.txt`; since `--check` passes (all 30 generated outputs in sync) yet llms.txt lacks a string
  README has, `llms.txt` is a **git-ignored, pkgdown-generated** artifact this arc touches zero times
  (the failing assertion at line 1349 is unchanged by the branch) — stale generated-artifact drift,
  not a gamma regression. The point_fit_recovery count test itself passes; confirmed in the D-43
  round-2 by Rose running both `--check` and the unittest. Flagged for a separate pkgdown-llms rebuild
  task; out of scope here.
- **Repro check covers M∈{16,32,64}** (the promoted range); M=8 was not in the local smoke's recorded
  rows and is excluded from promotion regardless.

## 11. Team learning

- **A dispersion-parameter σ-RE (Gamma CV) covers as well as its log-scale-SD sibling (lognormal)** at
  the same fixture — 0.9333/0.9450/0.9458 vs mc-0382's 0.9325/0.9242/0.9408 — with the same
  mildly-anti-conservative signature and the same profile-fixes-∞-width behaviour. The cross-repo
  small-sample-coverage map's "profile is the star for a bounded/skewed estimand" holds for a
  dispersion RE, not only a location RE.
- **Verify a reviewer's "trivial" fix too:** Fisher's M=64 CI-upper "correction" (0.9580) was itself a
  mis-rounding of 0.95795; reading the source TSV caught it. Sub-agent outputs — including their
  self-corrections — are leads, not ground truth.
- **Pre-registering M=8 as exploratory paid off:** its coverage numerically cleared the band, which
  without the frozen §4.6 declaration would have invited a post-hoc argument to promote a degenerate
  (20.8%-boundary-pinned) arm.

## 12. Next actions

1. Open one successor PR for this arc (do NOT merge without Shinichi's approval).
2. Separate task: rebuild `pkgdown-site/llms.txt` so the Poisson-spatial diagnostic string matches the
   README (pre-existing staleness surfaced here).
3. Broader iid coverage/bias evidence (more true-SD/n_each/M, or a bias-corrected/AGHQ interval) before
   expanding beyond the exact tested domain or tier; firmer certification of M=16 and any M=8 claim.
4. `reviewed_by` on `ev-mc-0242-arc4b` = the D-43 panel; ratification stands with a maintainer PR review.
