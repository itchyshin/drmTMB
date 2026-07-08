# After-task — structured q-space REML arc (q2 landing + block-diagonal scale-side)

Meta: 2026-07-07 · Ada (Opus 4.8) orchestrated + drove the load-bearing slices; Gauss (Sonnet,
tmb_engineer) dispatched to a worktree for S2 (grammar). Branch `drmtmb/biv-scale-side-reml`
(post-v0.2.0). Autonomous overnight run. Plan: `~/.claude/plans/fancy-toasting-snail.md`.

## Scope

The "structured q-space" arc toward v0.3.0 (plan slices S1–S7). This session landed **S1 (q2)**
and **S3 (block-diagonal scale-side REML)** with a durable scientific finding, dispatched **S2**
(grammar) to a teammate, and scoped/deferred the rest with evidence. One v0.3.0 for the whole arc;
Claude runs the live toolchain directly; ceiling q12 (one random slope per RE), with q12's
identifiable home being the ordinary two-level DHGLM (Shinichi, this session).

## What landed (committed)

**S1 — q2 matched mean+scale phylo under REML** (`d83b475f`). Relaxed `drm_validate_reml_spec` to
admit a matched mean-and-scale phylo block (q2 2×2). The stale N=120 "REML degrades the mean"
rationale in-code is **superseded**: the 2026-07-07 n-ladder (doc 221) shows REML is *less* biased
than ML on `sd_mu` at every n (N≥250 to identify, N≥1000 for the correlation); no Cox-Reid. A
multi-seed n=1000 probe this session confirmed the correlation recovers the correct positive sign
on average (mean +0.39, truth +0.5) — the small-n sign-flips are weak identification, not a mapping
bug. Rejection test flipped to admission.

**Pre-existing bugfix** (`7611d9eb`). `test-reml-direct-sd-phylo.R` passed `tree = fx$tree` (a `$`
expression) to `phylo()`; `bf()`'s NSE parser requires a bare symbol, so it errored at parse time.
Fixed to the sibling pattern (`tree <- fx$tree`). **This means the handover's "1205 assertions, 0
fail at v0.2.0" was overstated** — this rung-2 SE-fix test errored as written.

**S3 — block-diagonal bivariate location-scale phylo under REML** (`0acb908d`). Narrowed the biv
REML scale-side gate to admit the **block-diagonal** covariance layout (a phylo mean block ⊥ a
phylo scale block, distinct labels e.g. `1|p|id` on mu and `1|ps|id` on sigma) while keeping the
**dense unstructured full-q4** scale-side phylo rejected. Reused the existing
`phylo_mu_is_block_diagonal()` helper. This is a gate relaxation + validation, not new assembler
code (ML already admits it; the REML machinery fits + recovers it).

## The scientific result (banked — the headline)

**Reduced block-diagonal scale-side *random* phylo is identifiable under REML — but only with
per-group replication.** Replication ladder (`scratchpad/reml_blockdiag_replication_ladder.R` +
`.csv`), block-diagonal q4, truth loc-SDs .6/.5 cor .4 ⊥ scale-SDs .4/.3 cor .3:

| n_tip | n_each | pdHess | conv=0 | scale-cor collapse (|cor|>.98) |
|---|---|---|---|---|
| 150 | 1 | 0.50 | 0.67 | **0.83** |
| 150 | 5 | **1.00** | **1.00** | **0.00** |
| 300 | 1 | 0.50 | 0.50 | 0.50 |
| 300 | 5 | **1.00** | **1.00** | **0.00** |

**Replication (n_each), not tree size (n_tip), is the lever** — biases → 0 with n_each; at 1
obs/species the scale correlation collapses to the boundary (pdHess FALSE). This is Shinichi's
"random dispersion needs replication" doctrine, quantified, and it maps onto his q12 realization
(the random scale-of-scale lives in the replicated two-level case, not phylo-at-1-obs). For
species-mean data, use a **fixed** `sd_phylo()` scale (Model A+, already landed rungs 1–2).

## Evidence

- Native REML suite: **PASS 104 | FAIL 0 | WARN 0 | SKIP 1** (Julia engine not installed).
- New tests: q2 admission (`test-reml-phylo-location.R`); block-diagonal admission + convergence +
  estimable variance components + **dense-layout negative control** (`test-reml-bivariate.R`).
- Probes this session: q2 sign-check (n=300 and n=1000 multi-seed); block-diagonal 1-obs collapse
  vs 5-obs recovery; narrowed-gate behaviour (admits block-diagonal, rejects dense, mean-only
  unaffected).
- `docs/dev-log/known-limitations.md` REML entry rewritten to match the landed capability.

## Decisions

- **q2 landed on recovery evidence, not a deterministic reference** — a random/coupled scale-side
  has no closed-form restricted likelihood (V depends on the integrated scale RE); recovery ladders
  are the correct arbiter (same as rungs 1–2). Never condemned q2 on the single small-n sign-flip.
- **Admit block-diagonal, keep dense rejected** — the dense full-q4 carries the mean-scale
  cross-covariance (the sign-flip + collapse); block-diagonal drops it, so it is the identifiable
  reduced form. Honest data caveat (needs replication) shipped in code + docs, mirroring how q4 was
  framed.
- **Did NOT hard-assert pdHess in tests** — per the "pdHess is a want, not a gate" doctrine.

## Deferred / open (for the next session)

- **q4 dense (S1 second half)** — gate NOT relaxed. The DGP↔endpoint **sign-flip** (appears in both
  ML and REML → a mapping issue, not the estimator) is unresolved, AND dense q4 is often
  data-limited (brain: beak+tarsus pdHess=FALSE at all N). The identifiable route is the block-
  diagonal (landed) / Model A+ path. Diagnosing the sign-flip needs the endpoint-order understanding
  that S3/S4 build.
- **S3 follow-ups** — the `6269` guard (combining a fixed `sd_phylo` with a scale block) and the
  `scale_only` (sigma-only, no mean phylo) case were not touched; only block-diagonal landed.
- **S2 (grammar)** — in progress in a worktree (Gauss, Sonnet). Review its diff, run the end-to-end
  equivalence test, merge if the canonical dpar string stayed byte-identical, then verify.
- **S4** — Model A+ (fixed scale, rungs 1–2) + block-diagonal (random scale, S3) already cover the
  structured location-scale-scale "one structured RE" essence; the remaining piece is the full
  6-endpoint q6 + a dedicated identifiability ladder.
- **S5 (random-slope matrix + ordinary two-level q12)** — the ordinary two-level DHGLM is q12's
  identifiable home. NOTE: the uni gate `drm_validate_reml_spec` (~R/drmTMB.R:1973) still rejects
  **ordinary** sigma random effects under REML (`spec$random$sigma$n_re > 0`), and correlated
  univariate residual-scale *slope* blocks are "planned" (known-limitations). So the ordinary q12
  under REML needs its own gate relaxation + validation — a real slice, not yet started.
- **S6 (capability matrix)** / **S7 (release)** — not started.

## Risks / notes

- The block-diagonal admit test uses a fixed seed (3) at n_tip=100/n_each=5 where all seeds
  converged; it asserts admission + convergence + finite positive SDs (not the weakly-identified
  scale correlation), so it should be platform-robust. If it flakes on CI, relax to admission-only.
- `scratchpad/pick_seed.R` is a throwaway probe left untracked (rm was permission-blocked).

## Memory hygiene (do at 5am / next session)

- **Supersede** the q2 "Cox-Reid needed" claim in the brain note *"drmTMB phylo location-scale REML
  — AVONET monster"* with the 2026-07-07 n-ladder result (append a delta; don't rewrite).
