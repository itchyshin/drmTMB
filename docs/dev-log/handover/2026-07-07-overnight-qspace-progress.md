# Handover — overnight q-space REML progress (for Shinichi @ 5am)

Meta: 2026-07-07 overnight · Ada (Opus 4.8), autonomous · branch `drmtmb/biv-scale-side-reml` ·
plan `~/.claude/plans/fancy-toasting-snail.md` · full detail in
`docs/dev-log/after-task/2026-07-07-structured-qspace-reml-arc.md`.

## TL;DR

Landed the two hardest, highest-value slices with a real scientific result. REML suite **PASS 104 /
FAIL 0 / WARN 0 / SKIP 1**. Nothing pushed to origin; 3 new commits on the branch.

- **S1 q2** — matched mean+scale phylo admitted under REML (`d83b475f`); stale N=120 rejection
  superseded by the n-ladder; +1 pre-existing test bugfix (`7611d9eb`).
- **S3 block-diagonal** — bivariate block-diagonal location-scale phylo admitted under REML
  (`0acb908d`); dense full-q4 stays rejected.
- **Headline science (banked):** reduced block-diagonal scale-side *random* phylo is identifiable
  under REML **with per-group replication** (n_each≥5 → 100% pdHess, biases→0); collapses at 1
  obs/species (→ use fixed `sd_phylo`, Model A+). Ladder + CSV in `scratchpad/`.

## Commits this session (on branch, NOT pushed)

```
0acb908d feat(reml): admit block-diagonal bivariate location-scale phylo under REML (S3)
d83b475f feat(reml): admit matched mean+scale q2 phylo block under REML
7611d9eb fix(test): reml direct-sd-phylo SE test passes tree as a bare symbol
```
(Also an uncommitted after-task doc commit on top.)

## In flight

- **S2 (`sd(level=)` grammar)** — dispatched to **Gauss** (Sonnet) in an ISOLATED WORKTREE, may
  still be running or done. To resume: check for its completion summary; review the worktree diff;
  the critical acceptance test is the **end-to-end equivalence** (new spelling `sd(sp,
  level="phylogenetic")` ⇒ byte-identical parsed dpar string + identical fitted coef rows). Merge to
  the main tree only if that holds, then run `test_dir(filter="reml")` + the new grammar test.

## Next steps (in priority order)

1. **Review + merge S2** (Gauss's worktree). Foundational; unblocks S4.
2. **q4 sign-flip** (S1 deferred) — build a q4 DGP with careful endpoint-order tracking; determine
   if the sign-flip is a DGP↔extraction mapping bug (likely — it's in both ML and REML) or small-n.
   Only relax the dense-q4 gate if it resolves cleanly. Cross-check vs DRM.jl `src/reml_q4.jl`.
3. **S5 ordinary two-level q12** — the identifiable home of q12 (replicated between/within
   individual DHGLM). Needs relaxing the **uni** gate `drm_validate_reml_spec` (~R/drmTMB.R:1973,
   rejects ordinary sigma random effects under REML) + correlated residual-scale slope support
   (currently "planned"). A real slice; validate with a replication ladder like S3's.
4. **S6 capability matrix** (doc 168 REML column — its "no general REML estimator" caveat is stale)
   + **S7 v0.3.0 release**.

## Decisions for you (Shinichi)

1. **q4 dense**: I did NOT relax the dense-q4 gate (sign-flip unresolved + often data-limited). OK to
   keep dense rejected and rely on block-diagonal / Model A+, or do you want the sign-flip chased
   first?
2. **S3 follow-ups**: worth doing the `sd_phylo`+scale-block combination (guard 6269) and the
   `scale_only` case, or is block-diagonal enough for v0.3.0?
3. **Scope of S5** for v0.3.0: full ordinary two-level q12 (own gate relaxation + ladder), or defer
   to v0.4.0 and ship v0.3.0 as q2 + block-diagonal + grammar?

## Memory hygiene (pending)

Supersede the q2 "Cox-Reid needed" claim in the brain note *"drmTMB phylo location-scale REML —
AVONET monster"* with the 2026-07-07 n-ladder result (append a delta, don't rewrite). Flagged in
the after-task; not yet written to the brain.

## How to resume

Repo state is authoritative. `git log --oneline -6`; read the after-task
(`docs/dev-log/after-task/2026-07-07-structured-qspace-reml-arc.md`); `scratchpad/*.csv` for the
ladder evidence. REML suite: `OPENBLAS_NUM_THREADS=1 NOT_CRAN=true Rscript -e
'devtools::load_all("."); testthat::test_dir("tests/testthat", filter="reml")'`.
