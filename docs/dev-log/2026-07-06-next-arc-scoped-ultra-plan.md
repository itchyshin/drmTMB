# Ultra-Plan: drmTMB intervals, coverage & structured-covariance arc

Meta: 2026-07-06 · author Claude (Opus 4.8) · scoped execution plan for the arc that follows
the Q-Series `104/104` close. **This is the executable plan.** Its landscape/scoping input is
[`2026-07-06-next-arc-ultraplan.md`](2026-07-06-next-arc-ultraplan.md) (the three-track analysis,
kept as the design rationale); the method decision + research is in
[`2026-07-06-arc-interval-method-research-memo.md`](2026-07-06-arc-interval-method-research-memo.md).

## Context

`104/104` on `main` (`6c89feaa`) is a **fit/recovery** surface: every catch-all cell has one
recovered representative, but only 8 cells carry `inference_ready` intervals and coverage;
`supported` authority is `0/104`. The next milestone is **depth** — honest intervals and
coverage — plus admitting the structured-covariance families kept `planned`. Because the
method decision makes this an *extension of existing profile + bootstrap infrastructure*
(`R/profile.R`), not a new-method research project, the arc is tractable and mostly R-side.

## Goal (one sentence)

Convert the `104/104` fit surface into one carrying honest, calibrated intervals — by rolling
the **profile-first** route across the tractable low-q Gaussian bulk and proving one new
capability each in the non-Gaussian and structured-covariance tracks — while keeping the
honesty boundary explicit: `supported` stays `0/104`; the arc caps at `inference_ready`.

### Detailed goal statement (definition of done, in/out)

**Done when:**
1. **Track A — Gaussian profile extension (the bulk).** The exemplar
   `qseries_spatial_q1_sigma_one_slope` is certified and flipped to `inference_ready`, and the
   same certified profile route is rolled out to the **~23 low-q Gaussian companion cells**
   (each cleared through the promotion gate, row-local). High-q A2 (q4/q6/q8/q12) excluded.
2. **Track B — first count-family structured-SD interval (the headline).** One count exemplar
   (Poisson/NB2 structured SD) gets a documented interval route where none exists, coverage-
   gridded and promoted — *bounded* by the count Laplace-attenuation caveat.
3. **Track C — one new structured-covariance capability.** The smallest genuinely-new slice
   (ZI phylo/animal/relmat **S**, or same-family q=2 non-count labelled cross-term **M**) lands
   with `inst/COPYRIGHTS` provenance, tests, and a recovery demonstration.

**Success criterion for every row flipped (exemplar and bulk alike):** coverage grid
**MCSE ≤ 0.01**, **pdHess/finite ≥ 0.95**, **miss-balance** within tolerance; **4-lens**
(Curie/Noether/Fisher/Rose) + **Fisher/Rose/Grace sign-off** + an **ADEMP contract** (design
217); **full `devtools::test()` green** + **CI green**; all four board validators exit 0.

**Explicitly NOT claimed (boundaries):**
- `supported` stays `0/104`. The skew / miss-asymmetry fix and BCa are banked for a later
  sub-project. The arc caps at `inference_ready`.
- Count intervals are honest only where the first-order Laplace approximation is adequate
  (attenuation biases count RE SDs downward); cells outside that regime stay short of
  `inference_ready` with the reason recorded.
- A2 high-q stays blocked on the design-220 Hessian/identifiability wall.
- No board padding — the bulk is the ~23 low-q Gaussian companions with a genuine profile
  route, plus one exemplar each in B and C; not exhaustive family coverage.

## Decisions locked (Shinichi, 2026-07-06)

| # | Decision | Rationale |
|---|---|---|
| 1 | **Profile-likelihood CIs are the star**; one plain parametric bootstrap the only fallback (no BCa). | Profile is drmTMB's hero method — asymmetry-respecting, boundary-aware, already the endpoint solver in `R/profile.R`. Wald has a finite-rate blocker (0.936 < 0.95) exactly where profile helps. |
| 2 | **`supported` DEFERRED** — arc caps at `inference_ready`. | The ~6:1 miss-asymmetry is a finite-sample skew; the fix (skew-aware interval / REML) is a separate sub-project. BCa banked. |
| 3 | **Breadth: exemplar per track + roll out the A1 bulk.** | Depth on B/C (one representative each), but Track A's low-q Gaussian bulk (~23 cells) is cheap enough to roll out fully. |
| 4 | **Compute: Totoro calibrates, DRAC Nibi certifies.** | Totoro (no queue) for fast triage/sizing; Nibi (SLURM array, `/project`) for the certified, provenanced evidence of record. |

## Phase 0 — Spike [DONE ✓ 2026-07-06]

**Verified today** (Mac, `load_all`), the arc's core premise holds for the A1 exemplar:
- `qseries_spatial_q1_sigma_one_slope` (`sigma ~ spatial(1 + x | site, coords)`, gaussian) fits
  with `convergence=0`, `pdHess=TRUE` (3 seeds; 8 sites × 20 obs).
- `drm_profile_targets()` lists **both** SD targets — `sd:sigma:spatial(1 | site)` and
  `sd:sigma:spatial(0 + x | site)` — each `profile_ready = TRUE`. **No engine/extractor slice
  needed.**
- `confint(method = "profile", profile_engine = "endpoint")` returns **finite** intervals for
  both targets on all 3 seeds, visibly asymmetric vs Wald and boundary-aware (one slope lower
  bound → 0.000).
- **Honest limit:** 3 benign seeds do not reproduce the 0.936 finite-Wald *rate* blocker;
  whether profile clears ≥0.95 finite-rate + coverage is a grid question → Phase 1.
- Artifact: `scratchpad/a1-spatial-sigma-slope-spike.R` (throwaway; evidence folded here).

## Strategy in one paragraph

The whole arc is a **two-dispatch compute campaign** wrapped in review. Track A's ~23 low-q
grids are cheap (~10–30 core-hours total), so the bottleneck is human dispatch + gating, not
FLOPs. Optimize for fewest cluster round-trips: **Totoro** runs one combined pilot to triage +
size the whole bulk (no queue, ~minutes), then **one Nibi `--array` job** certifies all cells
in parallel with clean provenance. Tracks B and C barely touch the clusters (B is method-
research + small count grids; C is local C++/R). Profile is primary everywhere; the single
bootstrap is the fallback when a profile endpoint fails to bracket.

## The team — roster, role in this arc, and model

Personas map to `.claude/agents/` (mirrors `.codex/agents/`). Model = default tier, overridable per slice.

| Persona | Agent type | Role in this arc | Default model |
|---|---|---|---|
| **Ada** | integration_reviewer | Orchestrator: decomposition, dispatch, coherence across code/math/docs/tests/ledger; merge/split calls | Fable 5 (Opus for hard calls) |
| **Fisher** | inference_reviewer | **Central this arc**: interval reliability, coverage denominators/MCSE, miss-balance, profile-vs-Wald + count Laplace-attenuation honesty, sizing SR475 vs SR1000 | **Opus 4.8** |
| **Rose** | systems_auditor | Claim-honesty gate before ANY board flip; the hardcoded-count test sweep; "assume ten more" | **Opus 4.8** |
| **Curie** | simulation_tester | Coverage grids + DGP; Totoro pilot & Nibi array drivers; the g-sweep | Sonnet (driver) / Opus (DGP design) |
| **Noether** | math_consistency_reviewer | profile target ↔ SD parameter ↔ C++ same-model contract; the new Track-C covariance branch | **Opus 4.8** |
| **Gauss** | tmb_engineer | Track C engine only (ZI routing / q2 non-count cross-term); count-SD interval refit plumbing (Track B) | **Opus 4.8** (C++) |
| **Grace** | reproducibility_engineer | CI, coverage denominators, DRAC/Totoro provenance, **the ledger done-gate**, validator lockstep | Sonnet (Haiku polling) |
| **Boole** | formula_reviewer | Track C formula grammar (ZI phylo/animal/relmat; q2 cross-term syntax + error messages) | Sonnet |
| **Emmy** | architecture_reviewer | Extractors/S3 for new targets (`drm_profile_targets`, `sdpars` for count SD, `confint`) | Sonnet |
| **Florence** | figure_reviewer | The interval figures (Confidence Eye): profile-vs-Wald finite-rate + coverage-vs-truth | Sonnet |
| **Jason** | landscape_scout | Verify the UNVERIFIED memo citations (count-GLMM interval + Laplace attenuation); BCa lit (banked) | Sonnet (Fable synthesis) |
| **Darwin** | audience_reviewer | Do the certified intervals answer real evo questions (variance heterogeneity)? | Sonnet |
| **Pat** | user_tester | Can an applied user get + read a profile CI without confusion? | Sonnet |
| **Shannon** | (me / orchestrator) | Coordination, live-toolchain runs, runbooks, consolidation, handovers | Opus 4.8 (this session) |

### Model assignment policy

**Spend Opus on the verifiers and the Track-C engine; Haiku on sim plumbing; Sonnet in
between; Fable orchestrates.** Never adjudicate coverage/miss-balance on Haiku; never burn Opus
on TSV regeneration or CI polling. Opus: Fisher (interval/coverage adjudication), Rose (final
audit), Noether (math contract), Gauss (C++), Curie (DGP design). Sonnet: grid drivers,
extractor/parser/error-message work, docs. Haiku: sim batches, result collection, ledger TSV
regen, CI-status polling.

## Phases — slices, owners, parallelization, compute, time

**Legend:** ⟶ sequential · ∥ parallel · ⏱ wall-clock (with parallelism). Times are ranges;
the pacing item is review/gating, not compute.

### Phase 1 — A1 exemplar certification ⟶ (the template) ⏱ 2–4 days
Certify the spiked exemplar end-to-end; this fixes the reusable route for the bulk.
- **P1.1 Totoro pilot** (n≈150) for both exemplar SD targets — profile + Wald finite-rate,
  pilot coverage, MCSE, miss-side. Owner: Curie (driver) + Fisher (design). Compute: **Totoro**
  (self-contained runbook; human/Codex runs). *Reuses `tools/run-structured-re-sigma-slope-coverage-grid.R` (shards 3–4).*
- **P1.2 Size the certify run.** Fisher rules SR475 vs SR1000 from pilot MCSE + skew. If the
  profile finite-rate < 0.95 for the intercept SD (the documented blocker), the fallback is the
  single bootstrap; if neither clears, the exemplar stays `planned` honestly (do not force).
- **P1.3 Nibi certify** — SR475/SR1000, sharded (intercept + slope). Owner: Grace (runbook) →
  human/Codex runs → paste back TSVs. Compute: **DRAC Nibi** (`--array`, `/project/def-snakagaw`).
- **P1.4 Gate + promote.** MCSE ≤ 0.01, finite ≥ 0.95, miss-balance; ADEMP (design 217);
  4-lens + Fisher/Rose/Grace. Flip the one row (row-local, no propagation). Rose audit → full
  `devtools::test()` + CI green → PR → merge with Shinichi's OK. Owner: Ada + Rose.

### Phase 2 — A1 bulk rollout (~23 low-q Gaussian) ∥ ⏱ 1–2 weeks
Reuse the Phase-1 route across the bulk. Review, not compute, is the pacing item.
- **P2.1 Enumerate the exact cells** from the release ledger (`family_class=gaussian`,
  low-q, `interval_status=planned`) — produce the authoritative list (the "~23" made exact).
  Owner: Grace/Curie (Haiku sweep + Fisher confirm).
- **P2.2 Totoro triage pilot** — one combined job (n≈150) across ALL enumerated cells at once
  (≤96 cores, no queue). Classify: clean · boundary/pdHess-holdout (like the excluded
  `animal sigma:x`) · needs-SR1000. Sizes the certify run. Owner: Curie + Fisher. Compute: **Totoro**.
- **P2.3 Nibi certify array** — one `--array=1-N` job over the cells that pass triage, rep
  counts per P2.2. Owner: Grace (runbook) → human/Codex. Compute: **DRAC Nibi**.
- **P2.4 Batched gate + promote.** Batch the 4-lens + Fisher/Rose/Grace; flip rows in batches;
  **run the FULL `devtools::test()` each batch** (board flips break hardcoded-count tests —
  the repeat lesson) and reconcile validators/ledger in lockstep. Owner: Rose + Grace + Ada.

### Phase 3 — Track B: first count-family structured-SD interval method (headline) ∥ ⏱ 2–4 weeks
Design-first; can run parallel to Phase 2 once its design lands.
- **P3.1 Verify the research** (quarantine rule): Jason/Fisher read the primary sources behind
  the count-GLMM interval + first-order Laplace-attenuation claims in the memo. Gate before build.
- **P3.2 Method design.** Profile route for a count structured SD: the χ̄² (½χ²₀+½χ²₁) mixture
  null as σ→0, a Laplace/AGQ refit per grid point; one bootstrap fallback. Owner: Fisher +
  Curie (DGP) + Gauss (refit plumbing). Scope to count/group regimes where attenuation is small.
- **P3.3 Exemplar recovery + interval smoke** on one count structured-SD cell (enumerate a
  fitting Poisson/NB2 structured-SD row from the ledger; note `..._nbinom2_..._rejected` rows
  are `interval=unsupported` — pick an admitted count cell). Bound by the Laplace caveat.
- **P3.4 Coverage grid + gate + promote** the one exemplar (Totoro pilot → Nibi), same gate.

### Phase 4 — Track C: one new structured-covariance capability ∥ ⏱ 1–2 weeks
Recommend the **ZI phylo/animal/relmat (S)** quick win first (C++ already routes to `eta_zi`;
mostly R-validator relaxation, mirrors row 87); the same-family q=2 non-count labelled
cross-term (**M**) is the stretch if time allows.
- **P4.1** Formula grammar + parser admission (Boole) → engine routing + math contract
  (Gauss/Noether, `inst/COPYRIGHTS` provenance if any gllvmTMB reuse) → recovery demonstration
  (Curie) → 4-lens → **recovery-only admission** (like row 87; interval/coverage a follow-on).

### Phase 5 — Consolidation & release ⏱ 3–4 days
Design docs (217/218 updated; promote the 221 seed if BCa research matures); NEWS/README/
pkgdown; Florence's interval figure gallery (profile-vs-Wald finite-rate + coverage);
Darwin/Pat readability pass; **Rose full claim audit**; after-task + handover. Owner: Ada +
Rose + documentation_writer/pkgdown_editor.

## Parallelization & compute map

- **Sequential spine:** P0 ✓ ⟶ **P1 (exemplar template)** ⟶ P2 (bulk). Nothing in the bulk
  fans out before the exemplar route is certified.
- **Parallel:** Track B (P3) and Track C (P4) run ∥ to P2 once their design/grammar lands;
  per-cell reviews within P2 batch ∥.
- **The two-dispatch rule (the efficiency win):** the entire A1 bulk = **1 Totoro pilot** (triage
  + size) + **1 Nibi array** (certify). Not 23 round-trips. Since Claude cannot ssh, minimizing
  human dispatches is the real optimization.
- **Golden rules:** Totoro ≤ 100 cores, `OPENBLAS_NUM_THREADS=1`; Nibi R library on `/project`
  never `/scratch`, set `--time`/`--account`, `seff` after one run to right-size.

## Verification & gates (own the verifier)

- **Per-row gate:** the promotion gate above (MCSE/finite/miss-balance + 4-lens + sign-off + ADEMP).
- **Arc done-gate — make it a ledger query, not a judgment call:** the arc is "A-complete" when
  the count of low-q Gaussian rows at `interval_status = inference_ready` in
  `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv` reaches the P2.1 target
  N (exemplar + bulk), **plus** one promoted exemplar each in Track B and Track C. Grace wires
  this as a check so "done" is verifiable.
- **Board-change discipline (every flip):** full unfiltered `devtools::test()`; reconcile the
  conversion-contract test + `qseries_v1_claim_guard.py` / `validate-mission-control.py`
  hardcoded counts in lockstep; regenerate the ledger + release-audits (they are generated, not
  hand-edited); CI via `gh pr checks N --watch; echo $?` (no pipe).

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| **Profile finite-rate doesn't clear 0.95** for the intercept SD (the documented blocker). | Fallback to the single bootstrap; if neither clears, the cell stays `planned` honestly. This is the real risk to A1's exemplar — P1.1 pilot answers it early. |
| **Count Laplace attenuation** biases count RE SDs down (Track B). | Scope B to adequate-count/group regimes; document the caveat; cells outside stay short of `inference_ready` with reason recorded. |
| **Boundary/pdHess holdouts** in the bulk (like excluded `animal sigma:x`). | P2.2 triage catches them cheaply; exclude honestly with a recorded reason, don't force. |
| **Miss-asymmetry** (~6:1) tempts a `supported` claim. | Locked: `supported` stays 0; the skew fix is a separate banked sub-project. |
| **Hardcoded-count test breakage** on board flips. | Always full `devtools::test()`; validator/ledger lockstep; batch flips to reduce churn. |
| **Some cells need SR1000 not SR475.** | Pilot (P1.1/P2.2) sizes reps from MCSE + skew before the certify dispatch. |
| **Compute is human/Codex-run.** | Self-contained runbooks; the two-dispatch campaign minimizes round-trips. |

## Timeline & milestones (rough; review-paced)

| Phase | Wall-clock | Milestone |
|---|---|---|
| P0 spike | done | ✓ profile route wired + finite for the exemplar |
| P1 exemplar | 2–4 days | `qseries_spatial_q1_sigma_one_slope` → `inference_ready` |
| P2 bulk | 1–2 weeks | ~23 low-q Gaussian rows → `inference_ready` (ledger done-gate) |
| P3 Track B | 2–4 weeks (∥) | first count structured-SD interval; one count exemplar promoted |
| P4 Track C | 1–2 weeks (∥) | one new structured-covariance capability admitted (recovery) |
| P5 release | 3–4 days | docs/figures/audit; after-task + handover; tag |

**Immediate next step:** write the P1.1 Totoro pilot runbook (Curie/Fisher) for the exemplar's
two SD targets, for a human/Codex to run — the pilot's finite-rate + MCSE decides whether the
exemplar certifies on SR475 or needs SR1000, and de-risks the whole bulk.
