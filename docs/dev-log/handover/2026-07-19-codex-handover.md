# Handover → Codex (2026-07-19): AGHQ + non-Gaussian REML arc COMPLETE; next = 3-cell mu-slope coverage batch on DRAC

You are **Codex**, picking up drmTMB from a Claude session. This doc stands alone — you will not
see the Claude chat. Read `AGENTS.md` (native) first, then this doc, then the linked after-task.
**You run the LIVE toolchain** (real R/TMB fits, `R CMD check`, sims, DRAC/Totoro campaigns) — the
next arc is a coverage campaign, squarely your lane.

---

## Goals / mission

drmTMB = fast univariate/bivariate distributional regression on TMB, marching toward a v1.0 capability
surface. The live programme turns `point_fit_recovery` ledger cells into **`inference_ready_with_caveats`**
with honest, pre-registered Monte-Carlo coverage evidence, one cell at a time. North star: usable packages
for ecology & evolution, not one-off analyses.

## Plans / roadmap (what's next, by leverage)

1. **[RECOMMENDED] The 3-cell mu random-slope coverage batch (breadth).** Sibling cells to the just-promoted
   mc-0227, all `mu ordinary_re_slope`, still `point_fit_recovery`: **skew_normal `mc-0464`, tweedie
   `mc-0539`, zero_one_beta `mc-0575`**. These are HIGHER-information than cumulative_logit, so — like
   binomial — they may reach nominal under **plain ML-Laplace profile coverage** (NOT the O3 AGHQ+Cox-Reid
   machine; that was only needed for the lowest-information ordinal family). The mc-0242 machinery carries
   over unchanged (the `[0.925,0.975]` exact-binomial gate + finite-profile policy + ledger mechanics); only
   the 3 family DGPs are new. **Ideal DRAC job array** (all clusters connected 2026-07-18). A pre-compute
   scout ran earlier (workflow `wf_f9d4b5e4-983`, per the 2026-07-18 handover).
2. **Cross-repo: the same arc in gllvmTMB.** They are on the identical two-lever path; an FYI note is in their
   dev-log (`gllvmTMB/docs/dev-log/2026-07-18-two-lever-…-news-from-drmTMB.md`). Their d-dimensional latent
   makes AGHQ a curse-of-dimensionality grid, NOT a drop-in — the binomial-O2 gate-relaxation ports cheaply,
   the AGHQ half does not.
3. **Harden mc-0227** (optional, small): a matched-Laplace-fold or external ordinal reference (upgrade from
   internally-validated), or a boundary-corrected 50:50-χ² pivot to firm the M=40 exploratory rung.
4. **PR #794 rebase** (parked): the capability-surface tooling (AGHQ display column + parity doc) needs
   rebase onto main + `capability_ledger.py --write` regenerate + ledger tests before merge; don't merge its
   stale surface files.

## What was accomplished (this session)

**The AGHQ + non-Gaussian REML arc — built, validated, and mc-0227 PROMOTED.** Full detail:
[docs/dev-log/after-task/2026-07-18-mc0227-o3-aghq-coxreid-coverage-promotion.md](../after-task/2026-07-18-mc0227-o3-aghq-coxreid-coverage-promotion.md).

- **O2 — binomial Cox-Reid REML by gate-relaxation:** relaxed the two Gaussian-only gates (`R/drmTMB.R:234`
  + `drm_validate_reml_spec`) to admit `binomial`. The existing `beta_mu` Laplace fold IS the joint-Laplace
  restricted likelihood == `glmmTMB(REML=TRUE)` (matched **7.3e-9**). No C++ change.
- **O3 — nested AGHQ + Cox-Reid estimator** (`R/aghq-coxreid.R`, **pure R, no TMB/DLL**): adaptive-GH over
  the scalar RE (Newton mode-find + warm-start cache) + Cox-Reid adjusted profile over the fixed effects
  (incl. cumulative_logit cutpoints on the pinned θ₀+log-gap scale); profile CI on the natural RE-SD scale.
  Validated: ordinal AGHQ vs brute-force **6.4e-9**; binomial AGHQ vs `glmer(nAGQ=25)` **3.6e-5**;
  nq=1==Laplace exact.
- **Architecture (design doc `docs/design/224`):** the recombination is **nested and external** (AGHQ
  marginalizes the latent, THEN Cox-Reid adjusts the fixed effects) — NOT a joint TMB `random=` fold. This
  seam was caught by an adversarial 14-agent S1 workflow before any code.
- **mc-0227 PROMOTED** `point_fit_recovery → inference_ready_with_caveats`. Totoro N=1200/cell (true SD 0.5,
  n_each=15, iid-uncentered, nodes=25):

  | M | coverage | 95% CI | finite-rate |
  |---|---|---|---|
  | 40 | 0.9515 | [0.9378,0.9630] | 0.998 (exploratory; 15.5% boundary) |
  | **80** ← certified floor | 0.9457 | [0.9313,0.9578] | 0.997 |
  | 160 | 0.9596 | [0.9467,0.9700] | 0.989 |
  | 320 | 0.9508 | [0.9369,0.9624] | 0.983 (positive control OK) |

  Every CI overlaps [0.925,0.975]; none over-covers; point bias ≈0% all M. **Memo-blind D-43 panel 3/3
  PROMOTE, certified floor M=80.**

## Current working state

- **Branch `claude/handover-freshness-0718`**, pushed. Commits: `1ed90599` (estimator + design 224 +
  binomial gates + tests), `4956c754` (mc-0227 promotion: ledger + evidence + after-task + surfaces).
- **NOT on `main`** — no PR opened yet for this arc (open one; do not auto-merge).
- **Checks green:** ledger unittest **37/37**; `capability_ledger.py --check` OK; `test-aghq-coxreid.R`
  16/16; `test-reml-binomial-coxreid.R` 8/8; full REML suite 96/0; conformance 78/0.
- **Totoro:** all campaign runs finished + cleaned up (nothing running). Work dir `~/drmTMB_o3/` (a shallow
  clone of this branch + the coverage outputs) can be reused or removed.

## Key decisions & rationale

- **Ledger keeps `estimator="ML"` for mc-0227** (Rose S8 catch): a new `AGHQ+CoxReid` token would drop
  mc-0227 from the `capability_ledger.py:872` ML family-map split and flip the slope to "absent" (no test
  catches it). Method is encoded in `claim_boundary`/`evidence`. Verified the family-map slope stays present.
- **Certified floor M=80, not the mechanical M=40** (D-43 chair): M=40 is exploratory (15.5% σ̂→0 pile-up).
- **χ²₁ pivot, not the 50:50 boundary mixture:** disclosed as a caveat; no rung over-covered.
- **The 3-cell batch is ML-Laplace coverage, NOT O3.** O3 was the depth fix for the lowest-info family.

## Files created / modified (arc diff `2a4116ca..4956c754`)

New: `R/aghq-coxreid.R`, `tools/run-o3-cumlogit-coverage.R`, `docs/design/224-*.md`,
`tests/testthat/test-aghq-coxreid.R`, `tests/testthat/test-reml-binomial-coxreid.R`,
`docs/dev-log/simulation-artifacts/2026-07-18-o3-cumlogit-slope-coverage/*` (README + M=320 raw/summary/
manifest + main log), `docs/dev-log/after-task/2026-07-18-mc0227-*.md`, this handover.
Modified: `R/drmTMB.R` (2 REML gates admit binomial), `tools/tests/test_capability_ledger.py`
(point_fit_recovery 163→162), the `docs/dev-log/dashboard/*` ledger + surfaces + census + family-map,
`docs/dev-log/dashboard/estimator-surface-conformance.tsv`, `AGENTS.md` (snapshot).
**Never commit:** `scratchpad/*` (gate-spec, D-43 panel `.js`, apply scripts, spikes) and the pre-existing
foreign untracked files (`docs/dev-log/simulation-artifacts/2026-07-08-g2-*`, `2026-07-11-post-cran-*`,
`2026-07-18-cumlogit-laplace-vs-aghq/reml-scoping-cumlogit.tsv`).

## Next immediate steps (for Codex — LIVE toolchain)

1. **Open a PR** for `claude/handover-freshness-0718` → `main` (docs+code; ledger unittest is the gate).
   Do NOT auto-merge — maintainer merges.
2. **Plan the 3-cell batch (`skew_normal`/`tweedie`/`zero_one_beta` mu-slope).** Clone the mc-0242 gate-spec
   (`scratchpad/mc0242-gamma-sigma-gate-spec.md`) and campaign driver (`tools/run-gamma-sigma-re-coverage.R`)
   — only the 3 family DGPs are new. Consolidate ONE batch S0 gate-spec, Fisher+Rose plan-review, then
   **STOP for Shinichi's explicit compute approval before any DRAC/Totoro run** (standing gate).
3. **Run it as a DRAC job array** (D-50: never GitHub Actions; results local + repo dev-log). One array over
   3 families × M-grid × N=1200. Each family that clears the `[0.925,0.975]` gate + memo-blind D-43 → promote;
   else documented non-promotion. Lowest-info families may need the O3 route (per mc-0227) — decide per family.
4. Update the ledger per cell with the mc-0227 template (`scratchpad/apply_mc0227_ledger.py` shows the exact
   surgical mechanics: keep `estimator=ML`, decrement the point_fit_recovery count, verified→verified
   transition, `--write` regenerate, unittest).

## Blockers / open questions

- Which arc first is Shinichi's call (3-cell batch recommended; alternatives above).
- **Standing compute gate:** no smoke/campaign fit until a plan-reviewed batch S0 gate is approved.
- **mc-0227 residuals** (all disclosed in the claim_boundary): M=40 exploratory; χ²₁ pivot not
  boundary-corrected; no external ordinal oracle (internally validated); guarantee conditional on the
  finite-profile + one-sided scoring rule.

## Gotchas / failed approaches

- **The O3 estimator is PURE R** (`R/aghq-coxreid.R`) — you can `source()` it directly on a compute node with
  no TMB compile. The 3-cell batch, however, uses the REAL drmTMB ML-Laplace fits (TMB) → needs the package
  compiled (`pkgload::load_all` off a fresh clone; installed drmTMB on Totoro was stale 0.1.4).
- **Totoro is shared** — cap at ≤100 cores; a parallel run launched twice this session pushed load to 420
  (fixed by killing the duplicate). Pin `OPENBLAS_NUM_THREADS=1`.
- **The driver writes raw TSV only at the END** — a killed run loses per-rep raw (summary survives in the
  `.log`); mc-0227's M=40/80/160 raw was not persisted for this reason (summaries + M=320 raw are filed).
- **Ledger:** key edits by `cell_id`, never line number; keep `estimator=ML`; substitute stale prose, don't
  append; a promotion MUST decrement `test_capability_ledger.py`'s point_fit_recovery count.
- **`rm` was sandbox-blocked in the Claude session** — Codex has full toolchain, so this won't bind you.

## How to resume (TARGET = Codex)

1. `AGENTS.md` is native — read the "▶ Latest — start here" snapshot, then THIS doc, then the after-task.
2. Team mirror `.codex/agents/*.toml` (Rose audit mandatory before any capability claim; default NOT-DONE).
3. **Live-env exports** for drmTMB fits/checks (adapt to your shell):
   ```bash
   export NOT_CRAN=true               # run the full testthat suite, not the CRAN subset
   # R + a C++ toolchain for TMB (src/drmTMB.cpp); pkgload::load_all(".") off a fresh clone
   # Totoro (shared, ≤100 cores): ssh via the ControlMaster socket; OPENBLAS_NUM_THREADS=1
   # DRAC: Duo MFA per login; SLURM job arrays; depot/Rlib on /project not /scratch (60-day purge)
   ```
4. Verify state: `git fetch`; branch `claude/handover-freshness-0718` at `4956c754`;
   `python3 -m unittest tools.tests.test_capability_ledger` → 37/37.
5. **Codex runs the live work:** open the PR, plan + run the 3-cell DRAC campaign, `R CMD check`, adjudicate.
   Planning/prose/refactor can stay Claude-side if the work later hands back.

**One-command resume (paste in the repo root when you start Codex):**
```
Rehydrate from docs/dev-log/handover/2026-07-19-codex-handover.md + the AGENTS.md snapshot, then open the PR for this branch and plan the 3-cell mu-slope coverage batch (skew_normal/tweedie/zero_one_beta) as a DRAC job array — pre-compute plan-review, STOP for my compute approval before any run.
```

## Mission-control summary

| Lane | Branch / PR | State | What shipped | Next by leverage |
|---|---|---|---|---|
| AGHQ + non-Gaussian REML (mc-0227) | `claude/handover-freshness-0718` (`4956c754`), pushed, **no PR yet** | **DONE, needs PR** | O2 binomial REML + O3 nested AGHQ+Cox-Reid; mc-0227 → inference_ready_with_caveats (D-43 3/3, floor M=80); doc 224; 37/37 | Open PR; do not auto-merge |
| 3-cell mu-slope batch | — | Not started | pre-compute scout `wf_f9d4b5e4-983` | **Batch S0 gate → Fisher+Rose → STOP for approval → DRAC array** |
| gllvmTMB same arc | — | FYI left | cross-repo note in their dev-log | Their own session; binomial-O2 ports, AGHQ doesn't |
| PR #794 (surface tooling) | `claude/capability-surface-aghq-parity` (draft) | Parked | AGHQ display column | Rebase + `--write` + ledger tests |

## Cross-tool routing (Claude ↔ Codex)

- **Codex (you) — live toolchain:** open the PR, run `R CMD check`, build the 3-family coverage machinery,
  run the DRAC/Totoro campaign, render. This handover's next arc IS live compute → your lane.
- **Claude — planning/prose/logic:** ultra-planning a new arc, refactors, doc/prose, pure-logic tests, and
  the adversarial review workflows (S1-style derive→verify→critique, memo-blind D-43 panels).
- Coordinate via `protocols/handoff.md`; the two tools run **sequentially, one at a time per repo**.
