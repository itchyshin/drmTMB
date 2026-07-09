# Handover — drmTMB, 2026-07-08 night → next Claude

Meta: 2026-07-08 · from Claude (Opus 4.8) · **to the next Claude session** · repo `drmTMB` ·
`main` = `15d4412b` (pushed) · tag `v0.2.0.9001` (pushed). This SUPERSEDES the earlier
`2026-07-08-evening-claude-handover.md` — read that + the after-task
`2026-07-08-reml-surfaces-ayumi-fisher.md` for the deep detail; this doc is the delta since.

**You are Claude, picking up drmTMB. The board is honest and stable. Your mission is the
Ayumi-derived work (a real bug + a possible weak-ID defect + tests/docs) and the two banked
capability slices.** The repo is authority — trust `main`, not any chat memory.

---

## The ONE thing that must not be re-litigated (or we burn another campaign)

**The 8 `inference_ready` cells are correct. Do NOT demote them.** They were audited, an initial
"5/8 FAIL" reading was produced, and it was **WRONG** — it applied the `supported` bar
(nominal-exact coverage + symmetric misses) to the `inference_ready` tier. At small `g`,
**~0.90 coverage + upper-tail miss asymmetry is EXPECTED**, not a defect (banked doctrine,
LEARNINGS 2026-06-27; re-confirmed on a fresh N=600 run: g=8 profile 0.898–0.915, dead-on the
banked ~0.91). Two tiers, different bars:
- `inference_ready` = honest interval at achievable small-sample coverage (≥ a g-floor;
  g8→0.91), skew documented, calibration-aware channel (profile > bc > wald). **The 8 meet this.**
- `supported` = nominal-exact + balance. **Correctly withheld at g=8.**
This is now enforced in code: `tools/gate-inference-ready.R` returns BOTH tiers;
`tools/gate-inference-ready-driver.R` runs it over all 8 →
`docs/dev-log/dashboard/inference-gate-results.tsv` (all 8 `inference_ready=PASS`, `supported=no`).
**If you find yourself about to demote a small-`g` VC cell for ~0.90 coverage or one-sided misses —
STOP and re-read `~/shinichi-brain/memory/LEARNINGS.md` (top entry).**

---

## What shipped since the evening handover

| commit | what |
|---|---|
| `5bad4b86` | G1 driver — binding gate over all 8 cells from their REAL replicate files (evidence_url is heterogeneous; 3 schemas; q2's points at a design doc). `gate-inference-ready.R` refactored to library+CLI. |
| `25b92a98` | G2 sigma one-slope adjudication, N=600, LOCAL (20 cores, ~25 min, no Codex). |
| `15d4412b` | **TWO-TIER gate** — corrects the "5/8 FAIL" category error; all 8 hold `inference_ready`. |
| (hub `3b34c34`) | LEARNINGS: tier-confusion rule banked at top of active file. |

Plus, **posted to Ayumi** (her repo, not ours):
- **#3 close-out** (`issuecomment-4920398985`) — the `se_group_sd` ceiling fix CONFIRMED at her
  real scale (10,440-tip bivariate REML: no ceiling, finite SEs, `pdHess=TRUE`, 28.3 s). Her
  ML/REML check reproduced both predictions (O(p/n): +3.2% at n=378 → +0.16% at 10,440).
- **#4 science** (`issuecomment-4920399065`) — the M3 finding (climate modulates phylogenetic SD)
  is the headline; the caution is her **point 6** (inflated SE with clean `pdHess`).

---

## Next Immediate Steps — the mission (all LOCAL; this Mac runs the toolchain; NO Codex needed)

Ordered by leverage. Tasks #16–20 arose from Ayumi's issues; C1/C2 were banked.

1. **#16 — Fix the `phylo_mu_diagnostics` false positive.** [real user bug, quick, do first]
   `check_phylo_mu_diagnostics()` at `R/check.R:2554` reports `status=error` when the scalar
   `min_phylo_sd` is `NA`. But an `sd_phylo(...) ~ .` model has a per-species SD **surface**
   (`has_sd_phylo_model==1`), so the scalar is `NA` and the check mis-fires. Fix: summarize the
   fitted surface (`obj$report()$sd_phylo_group` min/median) instead; error only on genuinely
   non-finite/non-positive fitted SDs. Add a test.

2. **#18 — Investigate point 6.** [possible real defect; could touch her M3 fits]
   Two bivariate M2 fits: inflated SE on the 2nd trait despite `conv=0`/`pdHess=TRUE`, with
   `rho12 ≈ 0.02`. Hypothesis: weak identification of the phylo cross-correlation when the two
   axes are near-uncorrelated (block goes soft at the boundary). Minimal repro: sim biv phylo
   with `rho12=0`; compare SE under single-start vs multi-start vs profile. Decide: better default
   starts / a `check_drm` warning / a documented boundary. **A clean `pdHess` is necessary, not
   sufficient — this is exactly this week's theme.**

3. **#17 — Ayumi-fixture regression test.** Request `R/16_diag_biv_reml_ceiling_check.R` + her
   data/tree (~300–400 tips), turn into a CI test asserting biv `sd_phylo1/2` REML → finite SEs
   with `se_group_sd=FALSE`. Locks in the ceiling fix.

4. **#20 — ML-vs-REML guidance note** (user-facing FAQ/vignette): p/n framing; ML fine ≥ few
   hundred tips; REML for small subclades; REML shifts the SD *level* not the coefficients on
   `sd_phylo`. **#19** (stretch): a `check_drm` diagnostic flagging inflated-SE-despite-clean-Hessian.

5. **C1 — REML provider-gate relaxation** (spatial/animal/relmat). R-side only, recovery-validated
   this session (40/40 intercept debiasing, `scratchpad/reml_provider_ladder.R`). Admits the FIT;
   certification runs through the two-tier gate. Noether math review. Add defaults for any new
   state to ALL constructors AND hand-built test fixtures (`test-phylo-utils.R` lesson).

6. **C2 — location-scale-scale attempt 2** (Ayumi's `sd_phylo()` + `sigma~phylo()`, design 222).
   Deep C++; reverted once. Start from design 222 "Attempt 1": leading suspect is the surface
   scaling only TIP rows while the GMRF prior is over the AUGMENTED node set. Gauss+Noether. Gate
   on `scratchpad/location_scale_scale_recovery.R` (arm B passes, arm C inverts). **NOTE: none of
   Ayumi's M1–M7 need this — it is off her critical path**, so it's lower urgency than #16/#18.

---

## Gotchas / failed approaches (do not repeat)

- **Tier confusion** — the headline above. Small-`g` ~0.90 coverage is expected.
- **A clean fit can be a wrong model.** The location-scale-scale C++ converged (`pdHess=TRUE`) and
  returned inverted parameters; caught only by the recovery gate. Point-6 (#18) is the same shape.
- **I posted DRAFT files with their "do not post" headers still attached** to Ayumi's issues, then
  had to edit both in place. **Strip draft scaffolding BEFORE the post call.** Always verify the
  posted body's first line and `@username`.
- **`bf()` uses NSE** — `tree`/`coords` must be bare symbols, not `env$tree`.
- **Hand-built TMB data lists** (`test-phylo-utils.R`) mirror the `src/drmTMB.cpp` `DATA_*`
  contract — every new `DATA_INTEGER` must be added there too or `MakeADFun()` aborts.
- **`read.delim` coerces `"TRUE"`/`"FALSE"` to logical** — use `colClasses="character"`.
- **`--as-cran` needs `_R_CHECK_FORCE_SUGGESTS_=false`** (metafor/spelling not installed) or it
  aborts at "checking package dependencies" with exit 0 — a false green.
- **Never-commit** (untracked, leave them): `scratchpad/ayumi-*.md`, `scratchpad/pick_seed.R`,
  `scratchpad/reml_rung1_probe.R`, `scratchpad/s2-grammar.patch`, `scratchpad/*.log` (gitignored).

---

## Mission control

| repo · branch | state | plan by leverage |
|---|---|---|
| **drmTMB** · `main` `15d4412b` (pushed) · tag `v0.2.0.9001` · full `devtools::test()` FAIL 0, `--as-cran` 0E/0W/2N, 4 validators exit 0 | Board honest: 8 `inference_ready` (correct), 0 `supported` (withheld). `se_group_sd` ceiling fix validated at Ayumi's 10,440-tip scale. Two-tier gate + driver landed. | **1.** #16 phylo_mu_diagnostics bug · **2.** #18 point-6 weak-ID · **3.** #17 fixture test · **4.** #20 ML/REML doc (+#19 stretch) · **5.** C1 provider unlock · **6.** C2 loc-scale-scale (off Ayumi's path) |

**Toolchain (this Mac runs it live — NO Codex needed for any of the above):**
```sh
OPENBLAS_NUM_THREADS=1 NOT_CRAN=true R_PROFILE_USER=/dev/null Rscript --no-init-file \
  -e 'devtools::load_all("."); testthat::test_dir("tests/testthat", filter="reml")'
# --as-cran: add _R_CHECK_FORCE_SUGGESTS_=false. C++ changes recompile via load_all (~1-2 min).
# Local coverage campaigns: 20 cores here; xargs -P; OPENBLAS_NUM_THREADS=1. No cluster needed at this scale.
```
Spawn **Rose** (`systems_auditor`) before any board/public claim; **Fisher** (`inference_reviewer`)
for coverage/tier questions; **Noether** for math↔code; **Gauss** for C++ (C1/C2).

## How to Resume

1. Rehydrate: read this doc + the `AGENTS.md` "▶ Latest" snapshot + the after-task
   `docs/dev-log/after-task/2026-07-08-reml-surfaces-ayumi-fisher.md` (§12 cross-product) +
   `~/shinichi-brain/memory/LEARNINGS.md` (top: tier confusion).
2. Confirm board honesty is unchanged: `Rscript tools/gate-inference-ready-driver.R` →
   all 8 `inference_ready=PASS`. Do not re-audit toward demotion.
3. Start with **#16** (clean, verifiable bug), then **#18**.

### One-command resume (paste in your own authenticated terminal, from the repo root)
Interactive:
```
claude "Rehydrate from docs/dev-log/handover/2026-07-08-night-claude-handover.md + the AGENTS.md snapshot, then start task #16 (fix the phylo_mu_diagnostics false positive in check_drm for sd_phylo models). Do NOT demote the 8 inference_ready cells — they are correct (tier confusion; see LEARNINGS)."
```
Autonomous, clean context:
```
claude -p "Rehydrate from docs/dev-log/handover/2026-07-08-night-claude-handover.md + the AGENTS.md snapshot, then execute the Next Immediate Steps in order (#16, #18, #17, #20). Do NOT demote the 8 inference_ready cells. Two-slope + supported deferred." --max-budget-usd 8
```
