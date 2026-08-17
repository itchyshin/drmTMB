# Non-Gaussian random-effect remaining fruit (inventory)

**Date:** 2026-08-16  
**Lane:** Cursor docs-only inventory (no C++/API; no merge; no CRAN; no missing-data / MSPL)  
**Evidence base:** `origin/main` ledger + Q-series board + Arc 4c artifact packet (paths below).  
**Quiesce:** treat any follow-on code as side-branch only until win-builder platform-clean lifts shipped-file merge block.

## Snapshot: what already fits vs rejected

### Ordinary unlabelled RI / independent slopes — DONE (do not rebuild)

| Surface | Status on `origin/main` |
| --- | --- |
| `(1 \| g)` on `mu` across fitted univariate non-Gaussian families | Arc 2a; fits |
| `(0 + x \| g)` on `mu` across those families | Arc 2b; fits |
| Profile coverage for selected independent `mu` slopes | Arc 4a/4c (see below) |
| Ordinary `sigma` RI for lognormal / Gamma / NB2 (narrow gates) | Fits; lognormal/Gamma have coverage-backed `inference_ready_with_caveats` (`mc-0382`, `mc-0242`) |

### Arc 4c — RAN and closed (not leftover compute)

Frozen S0: `docs/dev-log/2026-07-19-arc4c-three-cell-mu-slope-drac-s0.md`.  
Campaign + promotion: `docs/dev-log/simulation-artifacts/2026-07-19-arc4c-mu-slope-coverage/`,  
`docs/dev-log/after-task/2026-07-19-arc4c-mu-slope-coverage-promotion.md`,  
`docs/dev-log/handover/2026-07-19-arc4c-coverage-closeout.md`.

| Cell | Family | Result |
| --- | --- | --- |
| `mc-0464` | skew_normal | **Promoted** `inference_ready_with_caveats`; floor **M≥16** |
| `mc-0539` | tweedie | **Promoted** same; floor **M≥16** |
| `mc-0575` | zero_one_beta | **Promoted** same; floor **M≥16**; Noether WITHHOLD on interior→exact-one leakage preserved as caveat |

**Arc 4c leftovers (validation debt, not open campaign):**

1. Zero-one-beta **strictly-interior sampler** + new compute approval before claiming an exact 15% observed-boundary DGP.
2. Immutable campaign has `sd_hat`/Wald **NA** (extractor defect disclosed); no point-bias/Wald claim; prospective repair exists — do **not** backfill the frozen packet.
3. No `supported` tier; no O3/AGHQ expansion; no correlated/labelled/structured expansion from this arc.

**Public `mc-0227` (cumulative_logit independent `mu` slope):** ledger is `point_fit_recovery` for public ML-Laplace. Completed O3 AGHQ+Cox-Reid evidence is **package-private** only (see MC `claim_guard` / 0.7 capability-truth reconciliation). Not an Arc 4c leftover; separate public-estimator arc if revived.

### Correlated ordinary `(1 + x | g)`

| Class | Fit? | Claim ceiling today |
| --- | --- | --- |
| Univariate **Gaussian** `mu` / `sigma` correlated blocks | Yes | Mature Gaussian surface (see `docs/design/17-correlated-random-effect-blocks.md`) |
| **Binomial** unlabelled `(1 + x \| id)` | **Experimental point-fit** (parser + MSPL prereq tests); labelled rejected | Point-fit only; no coverage cell in ledger |
| Other non-Gaussian ordinary correlated / labelled | **Rejected** with “planned” messaging (skew_normal, tweedie, ZO-beta, Student-t, hurdle, …) | Design arc only until gates reopen |

MC `do_not_repeat` already bars opening a non-Gaussian correlated q2 route from the 2026-07-21 gllvmTMB probe without a predeclared iid control, oracle, and information ladder.

### Structured / labelled slopes (non-Gaussian)

| Surface | Fit? | Interval / coverage |
| --- | --- | --- |
| Count (Poisson / NB2) q1 structured `mu` intercept + **unlabelled** `provider(1 + x \| …)` one-slope | Recovery / point_fit on Q-series board (Rorqual rollups) | Interval/coverage still **unsupported / planned** |
| Exact labelled count-q2 forms (Poisson all four providers; NB2 phylo only) | Point-fit-only per formula grammar | Not profile-ready |
| Structured **sigma** slopes for counts | Board rows marked **rejected**; need retained fixtures before parser-ready claims | None |
| Most other NG families + structured slopes | Rejected or narrow local gates only | — |

### Ordinary / structured `sigma` slopes beyond a few gates

| Cell / family | Status |
| --- | --- |
| Gaussian ordinary `sigma` slopes | `interval_feasible` (`mc-0270`/`mc-0271`) |
| `zero_one_beta` ordinary `sigma ~ x + (0 + x \| id)` | **`interval_feasible`** (`mc-0576`); 135-trace / five-seed profile existence — **no coverage** |
| lognormal / Gamma / NB2 / Student / skew_normal / tweedie / … ordinary `sigma` slopes | Mostly **`rejected_by_design`** in ledger |
| NB2 ordinary `sigma` RI | `interval_feasible` (`mc-0403`); slopes remain rejected |

## Ranked post-quiesce fruit (top 5)

Do **not** start shipped-file implementation until quiesce lifts. Docs-only design on a side branch / worktree is OK now.

### 1. Ordinary non-Gaussian correlated `(1 + x | g)` — binomial wedge → family menu

- **Claim ceiling:** `point_fit_recovery` first (binomial already experimental); coverage later, never `supported` in the first arc.
- **Likely files:** `R/drmTMB.R` family gates; `src/drmTMB.cpp` only if Cholesky/report paths need NG carriers; `docs/design/17-*.md` + `01-formula-grammar.md`; `tests/testthat/test-binomial-correlated-re-mspl-prereq.R` pattern; ledger cells.
- **Evidence needed:** predeclared ordinary iid control; external or dense marginal oracle; information / n_each ladder; treatment of gradient exceptions (MC fence).
- **Compute:** Totoro pilot → DRAC/Fir certification only after design freeze + owner approval.
- **Docs-only now?** **Yes** — symbolic alignment + ADEMP sheet before any gate flip.
  Written 2026-08-16 as
  [`docs/design/257-nongaussian-ordinary-correlated-slope.md`](../../design/257-nongaussian-ordinary-correlated-slope.md)
  on `cursor/ng-correlated-slope-design`. No code until quiesce lifts.

### 2. `mc-0576` zero-one-beta ordinary `sigma` slope coverage

- **Claim ceiling:** `inference_ready_with_caveats` inside a frozen M / SD / n_each domain (reuse Arc 4b/4c profile gate pattern).
- **Likely files:** coverage runner (new or Arc 4c cousin); `tests/testthat/test-zero-one-beta.R`; ledger `mc-0576`; artifact README under `docs/dev-log/simulation-artifacts/`.
- **Evidence needed:** N≈1200/M profile all-attempts coverage; atom/support diagnostics retained.
- **Compute:** Totoro smoke → DRAC/Fir array.
- **Docs-only now?** **Yes** — freeze DGP + gate before submit.

### 3. Admit ordinary `sigma` independent slopes for lognormal and/or Gamma (sibling to existing `sigma` RI)

- **Claim ceiling:** `point_fit_recovery` → `interval_feasible`; coverage only after recovery panel.
- **Likely files:** `R/drmTMB.R` rejection → admission; family tests; ledger rows currently `rejected_by_design` (`mc-0384`/`mc-0385`, `mc-0246`/`mc-0247`).
- **Evidence needed:** multi-seed recovery + pdHess honesty; within-group replication rule for scale slopes.
- **Compute:** Totoro recovery first; coverage later.
- **Docs-only now?** **Yes** — exact expression contract (match ZO-beta Z5 lesson: same raw symbol, not name-only).

### 4. Count structured `mu` one-slope **intervals** (recovery already banked)

- **Claim ceiling:** `interval_feasible` then fenced `inference_ready_with_caveats`; not public `supported`.
- **Likely files:** profile target wiring for structured SDs; Q-series board status columns; count-specific interval runner; ledger structured slope cells.
- **Evidence needed:** count-aware denominator + profile availability; separate from ordinary iid Arc 4c.
- **Compute:** Totoro smoke → DRAC/Fir.
- **Docs-only now?** **Yes** — interval-route design (board `next_gate` already points here).

### 5. Arc 4c debt: ZO-beta strictly-interior sampler rerun (`mc-0575`) **or** public estimator path for ordinal O3

- **5a ZO-interior:** claim ceiling unchanged; cleans DGP caveat. Files: campaign DGP helper + new artifact. Compute: Fir/DRAC with **new** approval. Docs-only now: sampler design.
- **5b Public O3:** expose AGHQ+Cox-Reid through a named public route then bind `mc-0227` calibration — larger product decision; `docs/design/224-*`, `R/aghq-coxreid.R`. Docs-only now: product/estimator contract only.

Prefer **5a** if the goal is cheap honesty; prefer **5b** only with an explicit owner goal (not a quiet follow-on).

## What NOT to do until quiesce lifts

- Rebuild ordinary `(1|g)` / `(0+x|g)` admission or Arc 2a/2b recovery.
- Merge fruit work to `main` / ship C++/API under the win-builder quiesce.
- Touch **missing-data** or **MSPL** lanes (foreign / parked).
- Submit / re-freeze **CRAN**.
- Re-run Arc 4c certification or promote `supported` from existing Arc 4c rows.
- Open NG correlated q2 from the gllvmTMB probe without the predeclared control/oracle/ladder.
- Treat private O3 evidence as public `mc-0227` interval permission.
- `git add -A`; stage explicit paths only if anything is committed later.

## Operator pointer

Post-quiesce default start: **docs design for slice 1 (NG correlated)** in parallel with **slice 2 gate freeze (`mc-0576` coverage)** — both docs-first; compute only after owner approval.
