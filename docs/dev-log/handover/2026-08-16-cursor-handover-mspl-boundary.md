# Session Handover: the MSPL boundary-penalty lane

Meta: 2026-08-16 · from **Claude** · target **Cursor** (fresh agent) ·
lane branch `claude/mspl-boundary-s0-s1` @ `a61181624`, **pushed, 0 ahead / 0 behind its remote** ·
`origin/main` = `9e42d2c94` · **no PR opened** (deliberate — see Landing State).

You are Cursor, picking up the MSPL boundary-penalty programme for drmTMB. This chat does not
transfer; this document plus the four artifacts it names are the state. **Trust the repo over this
document**, including over this sentence.

## Critical Context — read these four, in this order

1. **The programme.** `docs/dev-log/research/2026-08-16-drmtmb-mspl-transfer-packet.md` — the
   S0–S4 plan, assembled from five commissioned reviews (Fisher/inference, Noether/math,
   Gauss/engineering, Pat/user, Ranga/literature; all five are in the same directory and cited by
   the packet). **This is the plan of record. Do not re-plan it.**
2. **S1, the derivation — the load-bearing artifact.**
   `docs/design/256-mspl-boundary-penalty-derivation.md` (1,081 lines).
3. **S0, the measured defect record.**
   `docs/dev-log/simulation-artifacts/2026-08-16-mspl-s0-defect-gates/VERDICT.md` (+ its
   `PREREGISTRATION.md`, committed before results, and `results/*.csv`).
4. **The release quiesce**, which binds this lane: `docs/dev-log/coordination-board.md`.

## The question this lane answers

drmTMB implements MSPL (maximum softly-penalized likelihood) for **binomial separation** only.
Should it generalise to **boundary conditions** — random-effect SDs collapsing to zero (and
correlations at ±1)? The measured motivation: after the 2026-08-15 REML arm, boundary pile-up is
the residual of the small-`g` coverage problem — REML moved pooled coverage 0.9248 → 0.9463 but
boundary incidence only 0.153 → 0.138, with conditional-on-boundary coverage still 0.83.

## What Was Accomplished (both landed on the lane branch)

**S0 — two pre-registered defect gates, both CONFIRMED.** Totoro, ~5 min, zero failed fits.

- **A (scale equivariance, 200 reps, Gaussian A1):** the shipped penalized objective is **not**
  scale-equivariant — fitting `y` vs `100·y` and back-scaling disagree in **200/200** replicates
  (mean 0.0196, max 0.134), against an ML control equivariant to 1.2e-06. Four orders of margin,
  so it is the penalty, not the pipeline.
- **B (anchor ladder, 1,500 paired fits, shipped `estimator="mspl"` binomial route):** monotone
  pull toward `sd = 1` — bias effect +32.1 pts at `sd 0.25`, +7.9 at 0.5, +0.3 at 1 (the anchor),
  −1.3 at 2, −7.5 at 4. At `sd 0.25` it **overshoots through truth** (−30.5% → +1.5%): the
  signature of pull-toward-anchor, not bias correction.
- **B, RMSE pass — the result that reframes the whole lane.** On RMSE, **MSPL beats ML at every
  cell** (−29% at sd 0.25, −18%, −4%, −3%, **−34% at sd 4**), and eliminates boundary collapse
  entirely (**42% of ML fits ≈ 0 at sd 0.25; MSPL 0%** — Chung et al. 2013's 45–47% reproduced
  in-package). **So the defects are parameterisation bugs in an estimator that already
  outperforms ML on point estimation** — not a case against MSPL. This does *not* transfer to
  interval coverage (Chung's α=2-vs-α=3 split; F4 below).

**S1 — the derivation, and its results are stronger than "a proposal".**

- **The penalty form is FORCED, not chosen.** Theorem 1: exact scale-equivariance + boundedness-
  above (E2) together admit **only** `Q(log σ_u − log s)` with `s` a *data-derived* scale
  statistic. The anchor-free class is exactly the affine one, which violates E2 and is one-sided
  — which *derives* `blme`'s documented >800 divergence rather than noting it separately.
- **Chosen form:** `P_v(θ) = c_g · Q_{κ−,κ+}(log σ_u − mean_i η_i^σ)` with `Q` the shipped
  negative Huber, defaults `κ− = κ+ = 1`; the anchor is `log σ` for constant-sigma Gaussian.
- **Rate derived, not asserted:** `c_g = 2√(q_v/g)`, from **Proposition 2** — the efficient
  information for `log σ_u` is bounded above by `2g` uniformly in `n_per`, `σ`, `σ_u`. Closed
  forms verified numerically against differentiated expected information over a 168-point grid,
  max relative error **1.5e-10**.
- **Equivariance: PROVED exactly** (penalty gradient orthogonal to the scale orbit).
- **Scope finding:** the anchor defect is **not universal** — it bites only identity-link location
  REs (gaussian, skew_normal, bivariate Gaussian), which is exactly the A1/D-117 target. On every
  log/logit route the scale group acts by translation, so the shipped anchor is already correct
  there. (This is why S0-A found the defect on the Gaussian port while S0-B's binomial pull is a
  *shrinkage-target* effect, not an equivariance bug. Two different properties — do not conflate
  them.)
- **Košuta et al. 2026 read in full**; the data-augmentation route is **rejected** with reasons
  (fixed O(1) strength → no softness rate → the AIC/BIC hazard; anchor degenerates at q=1).

## Current Working State

- **Working:** S0 (complete, evidence committed), S1 (complete, committed, pushed).
- **Blocked by gate:** S2. Design 256 ends with **two unchecked sign-off boxes** — an independent
  Noether re-check and a Fisher inference re-check — and states: *"S2 (implementation) must not
  start before both boxes are checked."* **That gate is real and is your first task.**
- **Not started:** S3 (campaign), S4 (heritability ratio-target simulation).

## Key Decisions & Rationale

- **Surface it as `penalty`, not `estimator`.** Design 250 already disclaims `estimator = "mspl"`
  as *not* an alias for the `penalty` mechanism; a third overloaded meaning lands in the gap that
  disclaimer fenced. Extend the `drm_phylo_penalty()`/MAP vocabulary instead (Pat's review, §3).
- **Opt-in, never default.** The primary RE-SD audience asks *"is there any among-group
  variance?"* — a never-zero estimator erases that question by construction; and a penalized
  default destroys the lme4-to-1e-6 agreement that is the sole basis for attributing the D-117
  shortfall to the ML estimator class rather than to drmTMB.
- **REML × penalty stays mutually exclusive.** The existing hard reject is the mathematically
  defensible position (Noether §5); the softness rate would need re-derivation against REML's own
  effective information. Do not relax it.
- **Keep it knob-free if possible.** The theory constrains the rate; the derivation determines the
  anchor from the data scale rather than from the user. A penalty you must tune is one whose
  calibration is unfinished.

## Files Created / Modified (all on the lane branch, all pushed)

```
docs/design/256-mspl-boundary-penalty-derivation.md
docs/dev-log/research/2026-08-16-drmtmb-mspl-transfer-packet.md
docs/dev-log/research/2026-08-16-mspl-transfer-{fisher-verdict,noether-math,gauss-engineering,pat-practitioner,ranga-literature}.md
docs/dev-log/simulation-artifacts/2026-08-16-mspl-s0-defect-gates/{PREREGISTRATION.md,VERDICT.md,s0_defect_gates.R,results/expA_equivariance.csv,results/expB_anchor_ladder.csv}
docs/dev-log/handover/2026-08-16-cursor-handover-mspl-boundary.md   (this file)
```

The five research notes were committed on `claude/07-freeze-3-evidence` (the release lane) and are
already **on `origin/main`**; the design doc, S0 artifacts and this handover are on
`claude/mspl-boundary-s0-s1`.

## Landing State

| Item | State |
| --- | --- |
| `claude/mspl-boundary-s0-s1` @ `a61181624` (5 commits) | **LANDED to origin**; **no PR** — deliberate: it is docs+sim only and nothing is owed to `main` yet. Open one when S2 lands, or earlier if you want review. |
| Totoro `~/mspl-s0/` (runner + `results/`) | **CARRIED-OVER** — the CSVs are small and *are* committed; the remote copy is convenience only. Resume: `ssh snakagaw@totoro.biology.ualberta.ca 'ls ~/mspl-s0/results'` |
| The 0.7.0 release lane (`claude/07-freeze-3-evidence`, candidate `302ac2579`) | **PROTECTED — not yours.** Frozen, quiesced, waiting on win-builder. Do not touch it. |
| `claude/eloquent-driscoll-521fa1` (peer lane, 4 commits incl. a held test-guard) | **PROTECTED FOREIGN** — pushed, unmerged, held by the quiesce. |
| Primary checkout `AGENTS.md`, `' M'` unstaged | **PROTECTED — do not stage.** A deliberate pigauto-lane edit (removing a false D-37 citation). Never stage from the primary checkout. |

## Next Immediate Steps — OWED only

1. **Lane preflight** (`bash ~/shinichi-brain/tools/lane_preflight.sh .`), fetch/prune, reconcile
   this document against live git, and classify every item `OWED / DONE / RETRACTED / PROTECTED`
   before editing anything.
2. **The S1 sign-off gate — this is the whole job before code.** Run the two re-checks as *fresh,
   adversarial* reads (default: NOT ACCEPTED), then tick the boxes in design 256 §sign-off or
   record what fails:
   - **Noether re-check:** Theorem 1's proof (incl. the Cauchy step and the E2 argument), the
     closed-form `I_g` and Proposition 2 re-derived *independently*, the `c_g` rate argument, the
     §8 condition-by-condition verification, and Condition COMP.
   - **Fisher re-check:** whether §13's predictions are genuinely falsifiable as written, whether
     K1/K2 are the right killers, whether P3's size class is defensible, and whether the
     ML-defined-boundary scoring rule (P4) is correctly binding on the campaign design.
3. **Only if both pass — S2**, narrow: the derived penalty on the A1 iid `sd(group)` cell only, as
   a **`penalty` vocabulary extension** (not an estimator token), experimental, fit visibly
   MAP-labeled, `confint` withheld. Tests ship with implementation. **Verification obligation
   carried from design 256 §4.2:** confirm each family's equivariance-weight row against the
   family constructors in `R/family.R` and **fail loudly** rather than defaulting to `s ≡ 1` for
   any family you cannot classify. S0's Experiment A is your **regression test** — the new form
   must pass it with the ML control's profile.
4. **S3 (campaign) is NOT yours to launch unprompted.** It needs a pre-registration and Shinichi's
   compute approval (D-139: estimate first, >30 min ⇒ plan + pre-run test + approval).

## Blockers / Open Questions

- **S1's own three risks, from the derivation** — carry them into S2/S3, do not discover them
  again:
  1. **The sign flip is relocated, not removed** — E2 forbids dropping the upper guard, so bias
     still turns downward above `σ_u = σ`. Structural.
  2. **The penalty may be too soft to matter** — max displacement **0.21 SE at g=10, 0.04 SE at
     g=40**. So S3's prediction "beat REML's 0.828 conditional coverage" **may fail on its own
     arithmetic**. Diagnostic from the derivation: *any large S3 repair at g=40 should be read as
     an implementation error first.*
  3. **F4 is not cured and never will be** — boundary-*flag* deletion is structural at every `g`,
     so Fisher's ML-defined-boundary paired-seed scoring is load-bearing, not hygiene.
- `§11`'s q=1 degeneracy claim is **AGENT-INFERRED** from Košuta's main text; Web Appendix B.II
  was not fetched and could contradict it.

## Gotchas / Failed Approaches (do not repeat)

- **Do not validate on the D-117 grid alone.** Its `sd_mu ∈ {0.5, 1.0}` sits at/below the anchor,
  so it *structurally cannot* separate "corrects bias" from "pulls toward 1 where 1 is the truth"
  (F2). Any grid must span the anchor — 0.25→4 is the minimum.
- **Do not read bias tables without RMSE.** The bias-only view made MSPL look harmful at sd 2–4;
  RMSE reversed it. Score both.
- **Do not conflate equivariance with the shrinkage target** (S1 §4.2) — S0-A and S0-B measure
  different properties.
- **A negative grep is not evidence of absence** — earlier in this arc a slice was spent "adding"
  a disclosure that already existed under different phrasing.
- **Check the tool grant, not just the model tier** — three sub-agents this session had the right
  model and no `Write` tool, and returned content they could not file.
- **Verify the premise, not just the mechanism** — the same session polled the wrong mailbox for
  nine hours because a working query was asked of a mailbox that could never hold the answer.

## How to Resume

```sh
cd '/Users/z3437171/Dropbox/Github Local/drmTMB'
bash ~/shinichi-brain/tools/lane_preflight.sh .
git fetch --prune origin
git worktree add .worktrees/mspl-cursor claude/mspl-boundary-s0-s1   # or reuse .worktrees/mspl-s0s1
```

**Never work in the primary checkout** — it sits ~1000 commits behind on
`claude/handover-freshness-0718` and carries a deliberate unstaged edit.

R runs as `R_PROFILE_USER=/dev/null Rscript --no-init-file` (the repo `.Rprofile` segfaults R 4.6).
Compute: **Totoro** (`ssh snakagaw@totoro.biology.ualberta.ca`, ControlMaster socket live, no Duo),
**≤150 cores** (D-143), `OPENBLAS_NUM_THREADS=1`; keep the Mac quiet — the S0 runner is at
`~/mspl-s0/`, and drmTMB installs are at `~/drmtmb-valgrind-302ac2579/lib` (0.7.0 candidate) and
`~/d117_100k/lib` (0.6.0). DRAC only for replicated grids/GPU, `sbatch` with `--time`/`--account`,
never login-node compute. **No campaign is authorised by this handover.**

**Paste-ready prompt:**

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-16-cursor-handover-mspl-boundary.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
