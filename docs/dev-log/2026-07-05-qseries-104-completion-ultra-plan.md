# Ultra-Plan: Complete the drmTMB Q-Series to 104/104

## Context

drmTMB's structured-random-effect Q-Series is at **94/104**. The 10 remaining rows are
the **high-q Gaussian** cells (4× q6, 4× q8) and **2 non-Gaussian** design-gap rows —
work an earlier constraint (*no q4/q8 promotion*) deferred. **Shinichi has now authorized
completing the Q-Series to 104/104** as real, Bayesian-cross-validated engine capability.
Codex (the usual live-toolchain lane) is out for a few days, so **the Claude team drives
the live R/TMB work here** (the Mac R 4.6 env is working; live `devtools`/fits have run all
session).

**The decisive prior art (Santi / STAN):** the shared `phylo(1|species)` intercept on
`mu1/mu2/sigma1/sigma2` + residual `rho12` — a **q4** all-four location-scale fit (4 SDs +
6 correlations) — **already converges, recovers the among-trait phylogenetic correlation,
returns valid SEs, matches STAN, and runs ~100,000× faster** (Mammalian_decomposition#4;
wired via `engine="julia"` on `shannon/RELEASE-drmtmb`). So the all-four location-scale
phylogenetic covariance machinery **already works and is Bayesian-validated at q4.** q6/q8
are the **slope-extended** versions of that exact structure.

**Data-size principle (hard rule, Shinichi):** q8 estimates 8 SDs + **28** correlations — a
complex model *requires* a large dataset (Santi's trees: 1,221–3,117 tips). **Correct
non-convergence on a small/over-complex fixture is a data-requirement result, not an engine
failure.** Every gate is sized to the model; we separate *engine failure* from *honest
data-insufficiency*.

## Goal (one sentence)

Build the 8 high-q Gaussian rows (q6 two-slope location, q8 one-slope all-four) and the 2
non-Gaussian structured rows as honest **fit + recovery** (+ boundary-aware intervals where
practical), STAN/Bayesian-cross-validated, taking the Q-Series to **104/104** with per-row
Curie/Fisher/Noether/Rose gates and no inflated coverage/support claims.

## Decisions locked (Shinichi, this session)

1. **104/104 bar = honest fit + recovery + STAN cross-check.** Boundary-honest profile CIs +
   coverage are a **per-row, Fisher-gated follow-on**, not a blocker for calling a row done.
   ⇒ ~3–4 weeks to 104; intervals after.
2. **Sequencing: q6 before q8.** Build the smaller covariance (6 SD + 15 corr) first to
   de-risk the engine, then q8 (8 SD + 28 corr).
3. **Gaussian-8 first (→ 102/104 headline), then the 2 non-Gaussian rows immediately after
   (→ 104).** Non-Gaussian design can run in parallel but the headline is Gaussian-complete.
4. **Compute authorized: DRAC job arrays + Totoro** for the recovery campaigns (Santi-scale),
   Totoro (≤100 cores) for calibration, local Mac for engine dev.

## Strategy in one paragraph

Reparameterize the latent group-level covariance to **log-Cholesky** (Σ = LLᵀ, PD by
construction) so the 15/28 correlations can't cap-saturate at ±1; add **PX-EM warm-start**
(already landed in sister engine HSquared.jl #186) + **Marquardt ridge** for start/boundary
robustness; drive every recovery/coverage gate at **Santi-scale data** on **DRAC/Totoro job
arrays**; validate against **STAN** as the north-star (as Santi's q4 already does). Build
per-provider, fan out the 4 providers × 2 q-levels in parallel once the shared engine lands.

## Phase-1 research findings (condensed)

| Finding | Source | Implication |
|---|---|---|
| q4 all-four phylo location-scale works + matches STAN, 100,000× faster | Mammalian_decomposition#4 | Machinery exists; q6/q8 extend it, not from scratch |
| q6 = 2-slope location-only (6 SD + 15 corr); q8 = 1-slope all-four (8 SD + 28 corr) | `docs/design/01-formula-grammar.md:139,185,990` | q8 is the bigger covariance; the real challenge |
| Blocker = raw free-correlation cap-saturation / non-PD, NOT the q-level | `…q4-animal-production-transform-gate.tsv`; `218:121-130` | Fix by reparameterization, not brute force |
| Fix = log-Cholesky PD-by-construction (+ PX-EM warm-start, ridge) | brain ENGINEERING-NOTEBOOK; NotebookLM KB `3b3d2ec5…` | Concrete, evidence-backed engine route |
| Admission: extractor_ready + fixture/recovery; supported = 3-bridge parity | `218:20-71`; `216:54-59` | Defines "row done" and the interval/support ceiling |
| 2 non-Gaussian rows need family DGP/recovery contracts first | `docs/design/59`; `218:87` | Separate, design-first track |

_(In-flight scouts refine specifics: internal engine data-flow — exact q4 covariance
params + q6/q8 rejection sites + reuse-vs-new; prior-art/blockers — #570/#555/#293/#291 and
whether q4 intervals are practical; external SAS/ASReml/FA — unstructured vs reduced-rank.)_

**Engine has TWO orthogonal, composable covariance pieces (do not conflate):**
- **Among-endpoint covariance Σ** (8×8 / 28 corr over mu1,mu2,σ1,σ2) → **log-Cholesky**
  (PD-by-construction) — the NEW reparam that kills cap-saturation.
- **Within-provider phylogenetic structure A** → the **full-node-tree** representation
  (**Hadfield & Nakagawa 2010**): augment the tree with internal nodes so the phylo effect is
  a **sparse Gaussian-Markov / pruning structure** (sparse *precision*), not the dense n×n tip
  covariance. TMB Laplace exploits the sparsity → **O(n), not O(n³)** — THIS is why Santi's
  fits are ~100,000× faster than STAN and scale to 3,117 tips / 50-tree sweeps
  (Mammalian_decomposition#2, "the same result"). **drmTMB almost certainly already uses this
  for q1–q4** (that IS the speed win); q6/q8 must confirm it composes with the *larger* Σ and
  that scalability holds at the big n these models need.
- Full latent covariance ≈ **Σ ⊗ A** (log-Cholesky endpoint block ⊗ sparse node-tree).
- **Provenance for write-up:** cite Hadfield & Nakagawa (2010, JEB) + Bolker `phylog.rmd` for
  the edge/node-incidence; NOT R. Dinnage in public artifacts (repo memory).

## The team — roster, role in this arc, and model

Personas map to `.claude/agents/` (mirrors `.codex/agents/`). Model column = default tier
for that persona's work in this arc (overridable per-slice).

| Persona | Agent type | Role in the 104/104 arc | Default model |
|---|---|---|---|
| **Ada** | integration_reviewer | Orchestrator: owns decomposition, dispatch, coherence across code/math/docs/tests/dashboard; the merge/split calls | Fable 5 (me/Shannon drives; Opus for hard integration calls) |
| **Gauss** | tmb_engineer | **The engine**: log-Cholesky reparam in `src/drmTMB.cpp`, PX-EM warm-start, ridge, q6/q8 parser admission, extractors | **Opus 4.8** (hard C++/likelihood) |
| **Noether** | math_consistency_reviewer | Proves the symbolic covariance ↔ R syntax ↔ TMB C++ describe the *same* model; FD/gradient contract | **Opus 4.8** (correctness-critical) |
| **Curie** | simulation_tester | Recovery sims per provider×q-level at Santi-scale; the sim harness; DRAC/Totoro job arrays | Sonnet (drivers) / Opus (design of the DGP) |
| **Fisher** | inference_reviewer | Owns inference claims: interval reliability, coverage denominators, identifiability, the STAN cross-check, the data-size honesty rule | **Opus 4.8** (adjudication) |
| **Rose** | systems_auditor | Claim honesty gate before ANY status move; dashboard ↔ evidence; the "assume ten more" sweep | **Opus 4.8** (final audit) |
| **Boole** | formula_reviewer | q6/q8 formula grammar: the `(1 + x + z \| p \| id)` / all-four shared-label syntax, parseability, error messages | Sonnet |
| **Emmy** | architecture_reviewer | S3/extractors/API: `corpairs()`, `ranef()`, `summary()`, `sdpars` for the bigger covariance; internal coherence | Sonnet |
| **Grace** | reproducibility_engineer | CI, coverage denominators, served Mission Control, DRAC/Totoro provenance, no host-pooling | Sonnet (Haiku for polling) |
| **Florence** | figure_reviewer | The **STAN-vs-drmTMB** comparison figures (Confidence Eye) — the north-star validation visual | Sonnet |
| **Darwin** | audience_reviewer | Biological framing: do the q6/q8 examples answer real evo questions (coevolution of means/variances)? | Sonnet |
| **Pat** | user_tester | Applied-PhD-student workflow: can a user fit q8 and read the among-trait correlations without confusion? | Sonnet |
| **Jason** | landscape_scout | External-methods scouting (SAS/ASReml/FA/reduced-rank), novelty framing for the paper | Sonnet (Fable for synthesis) |
| **Shannon** | (me / orchestrator) | Coordination, planning, live-toolchain runs, consolidation, handovers | Fable 5 |

## Model assignment policy (Fable 5 · Opus 4.8 · Sonnet · Haiku)

| Model | Use for | Examples in this arc |
|---|---|---|
| **Opus 4.8** | Hardest reasoning where a wrong call is expensive | log-Cholesky C++ + likelihood (Gauss); math-consistency proof (Noether); coverage/interval adjudication (Fisher); final claim audit (Rose); DGP design (Curie) |
| **Fable 5** | Orchestration, fast synthesis, plan iteration, mid-complexity review | Ada/Shannon orchestration; research synthesis; the STAN-comparison design; PR narratives |
| **Sonnet** | Competent mechanical implementation & focused debugging | fixtures & test scaffolds (Curie); parser/error-message work (Boole); extractor wiring (Emmy); docs/roxygen; per-provider recovery drivers; focused root-cause (worked well for the ranef fix) |
| **Haiku 4.5** | Cheap high-volume mechanical | running sim batches; parsing/collecting results; dashboard TSV regen; grep/inventory sweeps; CI-status polling; log triage |

Rule: **spend Opus on the covariance engine and the verifiers; spend Haiku on the sim
plumbing; Sonnet in between; Fable orchestrates.** Never run a 28-correlation coverage
adjudication on Haiku, and never burn Opus on TSV regeneration.

## Phases, slices, owners, parallelization, compute, time

**Legend:** ⟶ sequential dependency · ∥ parallel · ⏱ wall-clock estimate (with parallelism +
compute). Times are ranges; engine work is inherently uncertain.

### Phase 0 — Bank the base & set up ⏱ 0.5 day
- **P0.1** Merge PR #730 (green 94/104 + regression fix) to `main`; cut a fresh arc branch
  `qseries/high-q-completion` off `main`. Owner: Ada/Shannon (Fable). *(Needs the one 3-OS
  `workflow_dispatch` check first — Grace, Haiku to trigger+poll.)*
- **P0.2** Stand up the **STAN north-star fixture**: a reduced copy of Santi's q4 model +
  its STAN fit as the ground-truth comparator harness (reused for q6/q8 by extension).
  Owner: Curie (Sonnet) + Fisher (Opus review).
- **P0.3** Pull Santi's exact q4 spec from `shannon/RELEASE-drmtmb` + DRM.jl as the base to
  extend. Owner: Shannon (Fable).

### Phase 1 — Log-Cholesky covariance engine  ⟶ THE ENABLER (sequential spine)  ⏱ 4–7 days
Everything downstream depends on this. Serial, on Opus.
- **P1.1** Map the current q4 latent-covariance parameterization in `src/drmTMB.cpp` +
  the R covariance registry (from the in-flight engine scout). Owner: Gauss (Opus) + Noether.
- **P1.2** Reparameterize the latent covariance to **log-Cholesky** (unconstrained log-diag +
  off-diag → Σ = LLᵀ). Must be endpoint-count-generic (q2/q4/q6/q8). Owner: Gauss (Opus).
- **P1.3** **q4 regression gate:** the reparam MUST reproduce Santi's working q4 fit +
  STAN match bit-for-bit (recovery, SEs, corpairs). Non-negotiable — do not break what works.
  Owner: Curie (Sonnet run) + Noether (Opus, FD/gradient equivalence) + Fisher (Opus, STAN match).
- **P1.4** Add **PX-EM warm-start** (copy HSquared.jl #186 pattern) + **Marquardt ridge** as
  opt-in robustness. Owner: Gauss (Opus).
- **P1.5** First **q8 recovery at Santi-scale** (large-n sim) to prove PD-by-construction
  kills cap-saturation. Owner: Curie (Sonnet driver, Haiku batch) on DRAC/Totoro.
- **Gate:** Gauss+Noether+Curie+Fisher sign-off that the engine recovers a known 8×8 Σ at
  adequate n and preserves q4. **Discussion:** Gauss proposes the C++; Noether checks the
  math contract; Curie shows recovery; Fisher rules on whether n was adequate (data-size rule).

### Phase 2 — q6 two-slope location (4 providers) ∥  ⏱ 3–5 days  [FIRST — de-risk the engine]
Smaller covariance (6 SD + 15 corr, location-only) — prove the pipeline + log-Cholesky at 15
correlations here before the bigger q8. Fan out the 4 providers in parallel once P1 lands.
Each provider = one pipeline: parser admission (Boole, Sonnet) → fixture + **Santi-scale
recovery** (Curie, Sonnet driver + Haiku batch, DRAC) → extractor check `corpairs/ranef/summary`
(Emmy, Sonnet) → **4-lens gate** (Curie/Noether/Fisher/Rose). Row counts at recovery + STAN
match (intervals = follow-on).

### Phase 3 — q8 all-four (4 providers) ∥  ⏱ ~1 week
The bigger covariance (8 SD + 28 corr), reusing the proven Phase-2 pipeline.
- **P3.{phylo,spatial,relmat,animal}** per provider: identical pipeline to q6.
- **Animal is hardest** (the transform gate, `docs/design/220`): if raw log-Cholesky still
  struggles at Santi-scale, fall back to **reduced-rank factor-analytic** for animal q8
  (Gauss/Opus) — honest, estimable, standard (Meyer/WOMBAT/glmmTMB `rr()`). ⏱ +2–3 days.
- **Compute:** DRAC job arrays (one seed per `$SLURM_ARRAY_TASK_ID`), Santi-scale trees/n.
- **Discussion per provider:** Boole (syntax parses?) ↔ Emmy (extractors surface among-axis
  correlations?) ↔ Curie/Fisher (recovery + adequate n, per the data-size rule).

### Phase 4 — 2 non-Gaussian rows  ⏱ ~1 week (design-first, partly parallel to 2/3)
- **P4.1** nbinom2 spatial q1 simultaneous structured types: DGP/extractor/recovery contract
  (Curie/Opus design) → additive multi-provider count-mu engine gap (Gauss/Opus) → recovery.
- **P4.2** broad non-Gaussian structured slope (family-class): per-family DGP + recovery
  contract; ordinary count recovery exists (Rorqual) but needs interval-route design.
- **Owners:** Curie (design, Opus) + Gauss (engine, Opus) + Fisher (scope, Opus) + Rose (claims).
- **Decision gate:** are these in v1-104, or a documented follow-on? (see Key Decisions).

### Phase 5 — Intervals, coverage & 3-bridge parity  [FOLLOW-ON, post-104, per-row Fisher-gated]  ⏱ +2–4 weeks after
**Not a blocker for 104/104** (decision #1). AFTER a row is recovery-admitted, add
boundary-honest profile CIs (the hero method) where a Wald is suspect + coverage sims at
Santi-scale (DRAC); optional DRM.jl + R-via-Julia bridge parity for `supported`. Per-row,
Fisher-gated. Santi's q4 already has valid SEs, so intervals are reachable; q8 coverage at
scale is the frontier (#555). Owners: Fisher (Opus) + Curie (sims) + Grace (denominators/CI)
+ Rose (claims).

### Phase 6 — Consolidation & release  ⏱ 3–4 days
Dashboard → 104/104; design docs 216/218/220 updated; NEWS/README/pkgdown; the STAN-vs-drmTMB
figure gallery (Florence); Darwin/Pat readability pass; **Rose full claim audit**; after-task
+ handover; tag. Owner: Ada/Shannon (Fable) + Rose (Opus) + documentation_writer/pkgdown_editor
(Sonnet).

## Parallelization & compute map

- **Sequential spine:** P0 ⟶ **P1 (engine)** ⟶ everything. P1 is the gate; nothing high-q
  fans out before it.
- **Parallel after P1:** 4 providers × {q6, q8} = up to 8 recovery pipelines ∥; the 2
  non-Gaussian tracks ∥; per-row reviews (Fisher/Noether/Rose) ∥.
- **Compute (where the DRAC/Totoro nudge pays off):**
  - **DRAC job arrays** (Fir/Nibi/Rorqual/Narval) for the recovery + coverage campaigns —
    one seed per `$SLURM_ARRAY_TASK_ID`, Santi-scale trees. This is the only way q8 coverage
    at adequate n is affordable. R library on `/project`, never `/scratch`.
  - **Totoro** (384 cores, no queue, ≤100 at a time) for quick calibration / start-ladder
    tuning between DRAC runs.
  - **Local Mac** for engine dev (P1) + focused recovery checks.
- **Agent fan-out:** dispatch the 8 provider×q pipelines as parallel sub-agents in one
  message (Sonnet drivers), each with a self-contained brief + output path; Opus reserved for
  the engine + the verifier agents; Haiku for the sim-batch/collection sub-agents.

## Timeline & milestones

| Milestone | Gated on | ⏱ cumulative |
|---|---|---|
| M0 base banked, STAN harness up | P0 | ~0.5 day |
| **M1 log-Cholesky engine recovers Σ + preserves q4/STAN** | **P1 (critical path)** | ~1 week |
| M2 q6 admitted (4 providers, recovery) | P2 | ~1.5 weeks |
| M3 q8 admitted (4 providers, recovery) | P3 | ~2.5 weeks |
| **M4 102/104 Gaussian-complete (headline)** | P2+P3 | ~2.5 weeks |
| **M5 2 non-Gaussian rows → 104/104** | P4 | ~3–4 weeks |
| M6 104/104 consolidated, audited, tagged | P6 | ~3.5–4 weeks |
| M7 intervals + coverage + bridge parity (per-row follow-on) | P5 | +2–4 weeks after |

**Total to 104/104 (recovery + STAN match): ~3–4 weeks** (decision #1). Intervals + coverage
follow per-row after, Fisher-gated.

## Verification & gates (own the verifier)

Every admitted row passes a **4-lens gate**, run as parallel verification sub-agents (Opus):
1. **Curie** — recovery of known truth at **adequate n** (data-size rule).
2. **Noether** — symbolic ↔ R ↔ TMB identical model; gradient/FD clean.
3. **Fisher** — inference claim honest; interval/coverage only where evidence supports; STAN
   cross-check where available.
4. **Rose** — no inflated wording; dashboard = evidence; "assume ten more" sweep.

North-star: **drmTMB must keep matching STAN** (as Santi's q4 does) as we extend to q6/q8 —
the single most convincing validation.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| log-Cholesky breaks Santi's working q4 | P1.3 hard regression gate: bit-for-bit q4 + STAN match before any q8 |
| q8 still won't converge at scale | reduced-rank factor-analytic fallback (Meyer/WOMBAT/glmmTMB `rr()`), honest + estimable |
| "non-convergence = failure" misread | data-size rule: size gates to the model; correct non-ID ≠ engine failure |
| Coverage at scale infeasible (#555) | scope v1-104 to point-fit+recovery; intervals as documented follow-on (Decision #1) |
| Compute cost of coverage campaigns | DRAC job arrays; only run coverage on rows we intend to promote to inference_ready |
| Claim drift (94→104 inflation) | Rose gate before every status move; supported needs 3-bridge parity |

## M1 empirical findings (2026-07-05) + inference doctrine

Recovery sim (`docs/dev-log/simulation-artifacts/2026-07-05-m1-highq-recovery/`, streamed):
- **q4 all-four (4 SD + 6 corr): CLEAN at Santi-scale.** Failed at n=64 (conv=1, pdHess=FALSE,
  cap-saturated), **pristine at n=512/1024** (conv=0, **pdHess=TRUE**, no cap-saturation, rmse
  ~0.05). Data-size principle proven end-to-end; this is Santi's STAN-matched case.
- **q8 all-four one-slope (8 SD + 28 corr): recovers but `pdHess=FALSE` persists.** rmse falls
  0.48→0.33→0.18→0.15 as groups grow 16→64→256→512; cap-saturation gone by n=256. But `conv=1`
  + `pdHess=FALSE` at 512 **even with iter.max=8000** (not an iteration cap) and **param-1
  partial-Cholesky did not fix it** → some of the 28 correlations are genuinely weakly
  identified (near-singular Hessian), not an optimizer bug.

**Inference doctrine for q8 pdHess=FALSE (Shinichi, 2026-07-05):** `pdHess=TRUE` is the ideal
but never the only door. The CI trio always applies — for q8, **our full (re-maximizing)
profile is the right PRIMARY tool** (tens of refits, boundary-honest, no Hessian needed),
**bootstrap the fallback**. Do NOT use **ELR / "estimated profile"** (nuisances *fixed* at the
MLE) for q8 correlation targets: it under-covers exactly when the target correlates with the
nuisances, and q8's 28 correlations are mutually correlated by construction — the one case ELR
is wrong. ELR stays deferred (prior decision, post-v1.0). M1's bar is met by
**recover + no cap-saturation + profile/bootstrap inference**, not by pdHess=TRUE alone.

**Deferred to a separate ESTIMATION-ALGORITHM arc (NOT M1, NOT a few-days fix — Shannon's
call):** resolving q8 `pdHess=FALSE` needs a lower-dimensional/better-conditioned route —
**reduced-rank factor-analytic** covariance (glmmTMB `rr()` / Meyer-WOMBAT; the real lever, a
genuine C++ + parser + test build) is the headline; warm-start ladders (q4→q8) are a cheap
experiment worth trying in that arc but unlikely to fix genuine weak-ID. Remember: this is
methods work for its own arc, gated by recovery-vs-truth, not something to bolt onto M1.

## Decisions — resolved & remaining

**Resolved (Shinichi, this session):**
1. **Interval scope** → 104/104 bar = **fit + recovery + STAN match**; boundary-honest CIs +
   coverage are a per-row Fisher-gated **follow-on** (Phase 5). ~3–4 weeks to 104.
3. **Sequencing** → **q6 before q8** (de-risk the engine on the smaller covariance first).
4. **Non-Gaussian** → **Gaussian-8 first** (→ 102/104 headline), then the 2 non-Gaussian
   immediately after (→ 104); their design can run in parallel.
+ **Compute** → **DRAC job arrays + Totoro authorized** (Santi-scale recovery), Mac for engine dev.

**Recommended defaults (confirm as the in-flight scouts land):**
2. **q8 covariance target** → **unstructured log-Cholesky** primary; **reduced-rank FA**
   (Meyer/WOMBAT/glmmTMB `rr()`) only as the animal fallback if scale-recovery still struggles.
5. **"Supported" bar** → native TMB recovery + **STAN cross-check** suffices for v1 admission;
   full DRM.jl 3-bridge parity reserved for the eventual `supported`-tier promotion (post-104).
