# Handover: drmTMB REML → the q-space arc (after v0.2.0)

Meta: 2026-07-07 · from Claude · to the next Claude session (a NEW lane) · repo `drmTMB` ·
branch `drmtmb/biv-scale-side-reml` (pushed; tag `v0.2.0` live on origin).

**You are Claude, opening a new lane to continue the drmTMB REML / q-space arc. v0.2.0 is
released. Shinichi wants to PLAN this arc first (ultra-plan) before executing — this doc is
your planning input + full state.** Authoritative design record: `docs/design/221-native-reml-finish.md`.

## What shipped in v0.2.0 (released, tagged `v0.2.0`)

Native REML for the phylogenetic **location-scale** model family — Ayumi's corrected model runs
fully under REML. Commits on the branch: `76910a35` (rung 1), `83521a01` (rung 2), `d7fd90eb`
(release marker). Tag `v0.2.0` = `d7fd90eb`.
- **Rung 1** — bivariate REML with phylo/random **means** (correlated location effects). Exact
  restricted-likelihood reference (`V = G⊗A + R⊗I`) + recovery ladder.
- **Rung 2** — phylogenetic **direct-SD** scale `sd_phylo(...) ~ predictors` (heteroscedastic phylo
  variance) under REML, uni + biv. Exact reference `V = D A D + σ²I`.
- **SE fix** — `vcov.drmTMB` now falls back to `cov.fixed`/`opt$par` for the outer
  variance-structure coefficients (e.g. `sd_phylo` betas) that the REML ADREPORT joint cov omits;
  `summary()`/`vcov()` show finite `sd_phylo` SEs under REML.
- Validation: native REML suite **47** + vcov/summary/wald/profile-targets regression **1158** = 1205
  assertions, 0 fail. R CMD check clean except a local env abort (Suggests `metafor`/`spelling` not
  installed — not a defect; re-running with `_R_CHECK_FORCE_SUGGESTS_=false`).

## The big scientific result (banked, do not re-derive) — see doc 221 + `~/.claude/memory/lessons`

Shinichi's thesis, validated end-to-end: **coupled location-scale blocks were never an algorithm
problem — it was always identifiability.** Evidence:
- **q2** (matched mean+scale) recovery ladder: the N=120 "REML degrades the mean" verdict is a
  small-sample artefact (below q2's N≥250 identifiability floor). At N≥250 REML is *less* biased
  than ML on `sd_mu` at every n; bias→0 with n. **No Cox-Reid needed.**
- **q4** (full 4×4) runs under REML with `pdHess=TRUE` on a genuine well-conditioned signal, where
  ML false-converges — REML rescued it.
- **pdHess concordance:** REML is *better*-conditioned than ML (rate 0.93 vs 0.83; P(REML PD | ML
  PD)=0.96–1.00). `pdHess=TRUE` is a want, not a gate — profile/bootstrap CIs are the standing
  fallback.
- **DURABLE LESSON (banked in LESSONS):** "sample-size-first applies to estimator-correctness
  verdicts, not just convergence." A single small-n recovery result is insufficient to condemn an
  estimator; run the n-ladder first.

## Validated but NOT yet landed to source (in-session `assignInNamespace` overrides only)

- **q2 / q4** (matched mean+scale; the block parameterisation) — validated by the ladders above but
  the source gates still reject them (`drm_validate_reml_spec` matched mean+scale reject `~:2014`;
  the biv q>2 reject). Landing = relax the gates + tests, like rungs 1–2.
- **q4 TODO:** a phylo mean–scale correlation came back sign-flipped vs the DGP truth in *both* ML
  and REML — a DGP↔endpoint-ordering mapping to verify before a q4 ladder ships (NOT a REML issue).

## THE NEXT ARC — planning input (Shinichi will ultra-plan this first)

Working title: **"The structured q-space: location-scale-scale + random slopes."** Rough slices
(dependencies noted) — these are the raw material for the plan, not a fixed order:

1. **q2/q4 source-landing** (task #8 evidence exists) — relax the matched mean+scale / q>2 REML
   gates, land + tests + the pdHess-concordance protocol. Mostly independent; good warm-up.
2. **`sd(..., level=)` unified scale grammar** (task #12) — retire `sd_phylo()`/`sd_phylo1/2()` for
   `sd(..., level = "phylogeny")`; lifecycle-deprecate (keep aliases). The foundation for the
   structured scale.
3. **Reduced-block / structured-covariance grammar** — allow *selected* correlations (not
   all-or-nothing q4 blocks; the q3a gap). Relax the guard at `R/drmTMB.R:6272` for the
   **block-independent** case. Rationale below.
4. **Structured q5/q6 (location-scale-scale)** — the 6-endpoint model (mu1,mu2, sd_phylo1,2,
   sigma1,2) with **structural zeros from phylo ⊥ residual independence** (Shinichi's key insight:
   the sparse block-separable form is tractable where dense q6 is not). Identifiability ladder on
   Totoro. Depends on 2+3.
5. **Random-slope support matrix** (task #13) — a ticks/nots table: which RE types (ordinary, phylo,
   spatial, animal, relmat, kernel/SPDE) support ≥1 random SLOPE, on which dpar (mu/sigma/sd), under
   **ML AND REML** (parity). Random slopes multiply q fast (q12+). Cross-cutting; big.
6. **Capability matrix** (task #9) — the authoritative REML column incl. the q-space + random-slope
   coverage.
7. **Release v0.3.0.**

## Key decisions / rationale (durable)

- **v0.2.0 scope = rungs 1+2** (direct-SD location-scale REML — Ayumi's model). q2→q6 are the next
  arc (the block parameterisations). Confirmed with Shinichi.
- **The 6272 guard is deliberate but over-broad.** It blocks `sd_phylo` + a q4 block because they
  double-count the *same* phylo variance. But when the phylo-scale and residual-scale are separate
  **independent** components (phylo ⊥ residual — the standard variance decomposition), there is no
  double-counting; the structured q6 is identifiable AND block-separable (removes the ill-conditioning
  at its source). This is why "structured q6 is not as difficult." (Shinichi, 2026-07-07.)
- **REML parity principle:** whatever ML supports for Gaussian, REML should too (validate per cell).
- **Version:** v0.2.0 (minor bump; REML is a feature). Next release likely v0.3.0.

## Gotchas / how we worked (do not relearn)

- **In-session gate relaxation for probes:** `assignInNamespace("drm_validate_reml_spec[_biv]",
  function(spec) invisible(TRUE), ns="drmTMB")` after `load_all` — validate first, then land the
  gate in source. Scratchpad ladders: `scratchpad/reml_rung1_ladder.R`, `reml_q2_ladder.R`.
- **The disciplined loop per cell:** recall (brain/doc 221) → probe (does it run + rough recover) →
  exact restricted-likelihood reference (correctness) → recovery ladder (bias→0 with n; REML≤ML
  bias; SEs match; pdHess concordance — Totoro for big n) → relax source gate → tests → land.
- `bf()` uses **NSE** — build formula strings + `eval(parse(text=...))` when programmatic (can't pass
  a formula in a variable).
- `drm_profile_targets()` returns ~n **per-tip** `derived_group_scale`/`random-effect-sd` rows —
  filter to the coefficient rows when debugging SE mapping.
- Toolchain works locally (`NOT_CRAN=true Rscript -e 'devtools::load_all(".")'`); Totoro for
  multi-seed ladders (OPENBLAS_NUM_THREADS=1, ≤100 cores). Full R CMD check aborts without
  Suggests `metafor`/`spelling` — install them or `_R_CHECK_FORCE_SUGGESTS_=false`.
- **Main is 9 commits behind this branch** (FF-mergeable, 0 conflicts). v0.2.0 is tagged on the
  branch commit; a FF merge to `main` puts the tag in main's history whenever Shinichi wants it.

## Task board (drmTMB session tasks)

#8 q2/q4 ladder (evidence banked; land to source) · #9 capability-matrix REML column · #12
`sd(level=)` grammar · #13 random-slope support matrix. (#6, #7 done; #10 NotebookLM research
notebook `3b3d2ec5` "Fast Algorithms" ~240 sources, background import may be incomplete — a research
aid, not blocking.)

## Mission-control

| repo · branch | state | shipped | next arc |
|---|---|---|---|
| **drmTMB** · `drmtmb/biv-scale-side-reml` | **v0.2.0 released** (tag live); 9 ahead of main (FF) | REML rungs 1–2 (biv phylo means; `sd_phylo~climate`); vcov SE fix; 1205 assertions green | structured q-space: q2/q4 landing · `sd(level=)` · reduced-block grammar · q5/q6 ladder · random-slope matrix · v0.3.0 |

## How to resume (NEW lane — plan first)

1. Read **this doc**, then `docs/design/221-native-reml-finish.md`, then `~/.claude/memory/lessons`
   (the sample-size-first + pdHess-not-failure doctrine), then the task board.
2. **Ultra-plan the arc** (Shinichi drives) — decompose the 7 slices above, size each, pick the order
   (q2/q4 landing is the low-risk warm-up; `sd(level=)` + reduced-block grammar unlock q5/q6).
3. Execute slice-by-slice with the disciplined loop (recall → probe → reference → ladder → gate →
   tests → land). Totoro for the ladders. Never condemn an estimator on one small-n result.

One-command resume (interactive):
`claude "Rehydrate from docs/dev-log/handover/2026-07-07-claude-reml-q-arc-handover.md + docs/design/221-native-reml-finish.md, then help me ultra-plan the structured q-space arc."`
