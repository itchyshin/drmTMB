# Session Handoff: A1 landed · Arc C landed · coverage campaign run overnight

**Meta:** 2026-07-25 evening → 2026-07-26 05:00 · from Claude · target **Claude** ·
Shinichi asleep from ~20:10, returning 05:00. This doc stands alone.

---

## Mission (the durable why)

drmTMB is univariate/bivariate distributional regression on TMB. **`0.7.0` is the first
CRAN submission; `0.6` is the dev cycle and is never submitted** (Shinichi 2026-07-25,
brain `D-86`, mirroring gllvmTMB's `D-66`). That gives runway, which is what licensed
sequencing **defects before capability** this session.

---

## What landed

| Item | State |
| --- | --- |
| **PR #843 — Arc A1, marginal simulation** | **MERGED** (`ac0d3e55`). Verified tip `9c09ec10` is an ancestor of main. |
| **PR #841, #829, #839** | merged (pkgdown closeout, duplicate nav link, Arc A handover) |
| **PR #844 — staged-eta Godambe** | opened as draft to stop 2 local-only commits rotting; **the eta lane took it, merged it, renumbered its design doc 243→244** |
| **PR #845 — Arc C** | **MERGED** (`08c02003`). CI green on the exact tip `5a80fa5a`; all three D-43 lenses' flip conditions met. |
| **PR #848 — coverage evidence + this handover** | **MERGED** (`33266bac`). Every headline figure re-derived from the committed CSV before merge. |
| **PR #849 — Arc A2 `phylo_interaction` marginal draws** | **MERGED** (`12553ff2`). Fisher DONE. |
| **brain `D-86`** | written + committed (`5b56974`) |
| **Mission Control** | drmTMB board refreshed (`a958d2f`); `do_not_repeat` 30 → 38, appended not rewritten |

**A1's substance:** `simulate.drmTMB()` reused the fitted MAP `û` in every replicate, so
`confint(method = "bootstrap")` was **anticonservative for every random-effect model**.
Now `re.form = NULL` (marginal) is the default; `NA` is the old behaviour. Fisher
independently reproduced `z = −0.2053` marginal vs `z = 8.39` conditional.

**Arc C's substance:** A5 (beta `mi()` clamp ordering) and A7 (19 rotted citations made
rot-proof) shipped. **F5 was attempted and reverted** — see below, it is the most
important result of the night.

---

## ⚠ READ FIRST — the overnight campaign RESULT

**It ran, it finished clean, and it BOTH confirmed A1's mechanism AND refuted the
prediction that A1 was sufficient.** Write-up drafted at
`scratchpad/246-marginal-bootstrap-coverage.md` — **land it in `docs/design/` as `246-`**
(245 is taken by the F5 record; the eta lane took 244).

240/240 shards, **72,000 interval rows, zero attrition, zero bootstrap refit failures.**

| Estimand (nominal 0.95) | marginal (new default) | conditional (old) | gap |
| --- | --- | --- | --- |
| **RE SD** `sd:mu:(1\|g)` | **0.8714** [0.8653, 0.8774] | **0.5092** [0.5002, 0.5181] | **+0.362** |
| `sigma` | 0.9319 | 0.9320 | +0.000 |
| `fixef:mu:x` | 0.9437 | 0.9356 | +0.008 |

RE SD by `n_groups` 10/25/50 → marginal 0.810 / 0.889 / 0.915; conditional 0.517 / 0.513 / 0.498.

**Verdict against the pre-registered predictions:**
1. marginal attains ~0.95 → **NOT SUPPORTED.** It attains **0.871**.
2. conditional under-covers the RE SD → **SUPPORTED, massively.** 0.509 for a nominal 0.95,
   flat in `n_groups` — the signature of a bias that does not wash out. Median width 0.256
   vs 0.481: the old intervals were about **half as wide as they should be**.
3. fixed effect is a control → **SUPPORTED.** Gap 0.008 vs 0.362; residual `sigma`
   unmoved to four decimals.

**So: A1's mechanism claim is confirmed and quantified — the damage was confined to the
between-group variance component exactly as diagnosed. But A1 IS NOT SUFFICIENT.** The
marginal bootstrap still under-covers the RE SD materially at realistic group counts.

**CONSEQUENCE — do not soften this.** `confint(method = "bootstrap")` **must not be
described as inference-ready for random-effect SDs** (81% coverage at `n_groups = 10`).
**No cell may be promoted on this** — it is coverage evidence pointing *down*, and the
asymmetric tier fence forbids promotion regardless. **Nothing is retracted:**
`bootstrap_R = 0` across all 151 evidence artifacts, verified at A1's gate.

**Open questions worth an arc:** why does marginal stop at ~0.87 — percentile intervals
near a variance boundary, `R = 199` too small for a tail quantile, or Laplace refit bias at
low group counts? Those are separable. Would BCa or bootstrap-t close it? Does the
shortfall extend to structured REs now that Arc A2 widened `phylo_interaction`?

**Artifacts:** `ssh totoro 'cd ~/drm_work && Rscript a1_analyse.R'`; raw
`~/drm_work/results/*.csv` + `a1_coverage_results.tar.gz` (2.3 MB, also pulled to
`scratchpad/campaign/`). Boundary: Gaussian random intercept only, complete data,
percentile intervals, `R = 199`. Says nothing about non-Gaussian families, structured REs,
`sd() ~ x`, bivariate, or missing data.

---

## The night's most important finding: F5

Arc C set out to fix three findings and shipped two. **The one it did not ship is the
result.**

Clamping the `sd(g) ~ x` predictor (nine sites, not the five the audit listed) made the
Arc 7B dense-LSS **negative control** pass — which was the failure, not the success:

| `logsigma_clamp` | profile for `sd(study):z_study`, dense K=12 |
| --- | --- |
| `c(-12, 12)` (clamp active) | **finite** `[-4.1428, 27.7859]`, `conf.status = profile` |
| `c(-200, 200)` (clamp off) | **`profile_failed`**, `NA` |

Widening the bound restores the non-identification, so the finite endpoint was **the
bound, not the data** — and that is worse than the `[0, Inf]` it replaced, because it
passes any "is the interval finite" gate.

Fisher's framing at the gate: **the real defect is that `interval_status` cannot
distinguish *ok because identified* from *ok because clamped*.** Full record:
`docs/design/245-f5-sd-regression-clamp-and-identifiability.md`.

---

## Next arc — Arc D, and its decisive constraint

Plan: `~/.claude/plans/arc-d-clamp-identifiability.md`. Three candidate designs in doc 245.

**Blast radius, scouted with citations:**
- Only **9** ledger cells involve a modelled RE-scale regression.
- **Exactly one has interval evidence: `mc-0017`** (`inference_ready_with_caveats`, brain
  `D-62`, promoted via DRAC-fir reproducible coverage). It profiles
  `sd_phylo(spp_id) ~ x_tau` and is **directly exposed to `src/drmTMB.cpp:2826`**, one of
  the nine F5 sites.
- **THE CONSTRAINT:** `mc-0017`'s certified coverage was measured with **no clamp** on the
  `sd()` path. **Any Arc D design that changes interval endpoints invalidates that
  evidence and requires re-running its coverage campaign.** Asymmetric tier fence applies.
- The K=12 config that caught F5 has **no ledger cell** — it is a research sentinel, not a
  certified claim.
- Residual clamp (16 sites) and the 9 `sd()` sites are **architecturally disjoint**.
- Design 2 (`clamp_limited`) needs genuinely new machinery: the existing clamp diagnostics
  are hardcoded to residual REPORT names and have **no notion of an interval endpoint**.

---

## ⚠ A CODEX LANE RAN CONCURRENTLY TONIGHT — reconcile ownership

`AGENTS.md` says the two tools run **sequentially, never concurrently, per repo**. That
did not hold tonight. While this Claude session worked, a Codex lane merged **#846**
(`codex/general-latent-normal-association-sandwich`) and opened **#847**
(`codex/arc-d-inference-contract-plan`) — an **Arc D plan written independently of mine**,
within about an hour of it.

Nothing collided and both plans are sound, but **two lanes planned the same arc**. Decide
which owns Arc D before either implements. The two artifacts:
- Codex: `docs/dev-log/2026-07-26-arc-d-scale-clamp-profile-contract-ultra-plan.md` (#847,
  draft, plan-only, stacked on #845, well-fenced)
- Claude: `~/.claude/plans/arc-d-clamp-identifiability.md`

**Codex's plan does not carry the `mc-0017` blast-radius constraint** (verified: 136 lines,
no mention). I posted it as a comment on #847 rather than duplicating their work —
`pull/847#issuecomment-5081790699`.

## Also in flight at handover-write time

- **Arc A2 — MERGED** (#849). The Frobenius concern I raised is **resolved by
  measurement**, not argument. Fisher re-ran the recovery across R: **0.0225/0.0237 at
  R = 2e4 → 0.0112/0.0117 at 8e4 → 0.0059/0.0052 at 3.2e5** — ~2× per 4× R, textbook
  `1/sqrt(R)`. The elevation above the 0.011–0.021 band at fixed R was finite-sample noise
  on a larger 36×36 matrix, not bias. Fisher also confirmed the premise *structurally*: the
  same object is passed as TMB's `Q_phylo` and `src/drmTMB.cpp:672-682` shows the fit-side
  density is `u ~ N(0, sd² Q⁻¹)`.
- **PR #836** — `MERGEABLE/CLEAN`, green CI, but flagged **draft** by its author. Left
  alone deliberately; content is now purely historical. Needs an owner decision.

---

## Open follow-ups worth an arc

1. **Why does the marginal bootstrap stop at ~0.87?** Separable candidates: percentile
   intervals near a variance boundary · `R = 199` too small for a tail quantile · Laplace
   refit bias at low group counts. Would BCa or bootstrap-t close it?
2. **The covariance-recovery figures in `docs/design/243` are still ad-hoc.** All five
   structures' relative-Frobenius numbers (phylo 0.0204, spatial 0.0113, relmat 0.0199,
   animal 0.0207, phylo_interaction 0.0225) come from one-off scripts and are **not
   reproducible from anything committed**. Raised by Fisher at the #849 gate; predates
   tonight (true of #843 too). Worth a committed harness that regenerates all five at
   **matched R and matched dimension** — and any such figure must carry its `R` and its
   matrix size, because the statistic shrinks as `1/sqrt(R)` and grows with dimension.
   *I started this at 22:35 and deliberately discarded it*: what I had printed the numbers
   rather than reproducing them, which is worse than nothing.
3. **A5 still has no falsifying test** (see Arc C's after-task report).
4. **Does the RE-SD coverage shortfall extend to structured REs**, now that
   `phylo_interaction` has marginal support?

## Gotchas paid for tonight — do not re-learn these

1. **Run BOTH gates, on the commit you are gating.** CI and the local suite disagreed in
   *opposite* directions on consecutive arcs: Arc B green under `test_dir` / ERROR under
   `R CMD check`; A1 the exact mirror, because
   `test-estimator-surface-conformance.R` resolves `R/profile.R` from a source checkout and
   does not evaluate under `R CMD check`. **CI passed while a real defect was live.**
2. **A gate result must name the commit it was measured on.** A banner claimed "CI pass"
   for a green measured on the previous commit. Caught by the third reviewer.
3. **Never scope an anchor audit to the rows a test enforces.** Six anchors drifted; one
   was enforced, five were silently wrong while the suite stayed green.
4. **A regression test is worthless until you have seen it FAIL on pre-repair source.**
   Three were written; two passed pre-repair. Tests that fit a model and assert on the
   result let the optimizer pick tame coefficients and never reach the defect — drive the
   compiled kernel at hand-set parameters instead.
5. **Line-number anchors rotted three times in one session.** They are now converted to
   `model_type == N` labels, which cannot rot.
6. **Never re-pin a negative control to make a suite green.** Classify first: stale
   assertion, real defect caught, or broken infrastructure. Tonight it was #2.
7. **Do not tell a sub-agent another lane owns a file when that lane is you.**
8. **"Ahead of main" ≠ unmerged** — squash merges leave branches ahead forever. Conversely
   two staged-eta branches were genuinely **local-only** despite a handover claiming the
   whole estate was pushed. Verify with `git ls-remote`.
9. **Totoro needs no Duo.** Key auth works directly; the absent `~/.ssh/cm-*` socket does
   **not** mean unreachable. I claimed it did and was wrong.

---

## Resume

```bash
cd "/Users/z3437171/Dropbox/Github Local/drmTMB" && git fetch origin
gh pr list --state open
ssh totoro 'ls ~/drm_work/results | wc -l; test -f ~/drm_work/CAMPAIGN_DONE && echo DONE'
```

Then: analyse the campaign (full denominator, report against the pre-registered
prediction), merge #845 if its CI is green and the D-43 gate is satisfied, and start Arc D
from `~/.claude/plans/arc-d-clamp-identifiability.md`.
