# Ultra-Plan — Arc 2a: a `mu` random intercept for every family (drmTMB 0.6.0)

Status: **PLAN, approved 2026-07-12.** Supersedes the earlier thin draft of this file.
Built with the full ultra-plan discipline: brain query (roster + prior decisions), three
parallel code-exploration agents (seam-map, 5-family investigation, evidence/test harness),
and a NotebookLM grounded literature search (Ranganathan, notebook `7742e05e`, 76 sources).
Companion evidence: `scratchpad/arc2a-notebooklm-synthesis.md`.

## Context

**Why.** The ratified 0.6.0 candidate-arcs doc
(`docs/dev-log/2026-07-12-0.6.0-candidate-arcs-plan.md`, Arc 2, split 2a) names the
highest-leverage usability win: **five families still reject all random effects**
(binomial, cumulative_logit, skew_normal, tweedie, zero_one_beta), while random intercepts
are the single most-used feature for applied eco/evo. Goal: let drmTMB honestly claim
*"at least a random intercept on the mean, everywhere"* — a bounded, systematic, headline
deliverable and the foundation Arcs 1 (REML) and 3 (structured effects) build on.

**Outcome.** `(1 | group)` on `mu` accepted, fitted, evidence-backed for all five families,
with honest scope docs (no slope/`sigma` creep), branch left merge-ready behind an
adversarial review gate.

---

## Key finding — the work is SMALLER and SAFER than it looks

1. **The machinery is global, not per-family.** `u_mu`, `mu_re_value`, `mu_re_index`,
   `mu_re_term`, `log_sd_mu` are read unconditionally in `src/drmTMB.cpp` (≈L322, L409).
   Working families (gaussian, poisson, nbinom2, gamma, lognormal, beta, **beta_binomial**)
   use a standard `if (n_mu_re_terms > 0) { eta_mu += mu_re_value * log_sd_mu-scaled u_mu }`
   block (template: lognormal/gamma `src/drmTMB.cpp:2472-2526`). Each rejecting family gates
   it off via `n_mu_re_terms = 0` + a `map` `factor(NA)`. **This arc adds a per-branch block +
   R plumbing — it builds no new RE infrastructure.**

2. **The cumulative_logit "threshold aliasing" fear is already resolved in the code.**
   `ordinal_mu_model_matrix` drops the fixed intercept (`R/drmTMB.R:14604-14610`); the
   cutpoints *are* the intercepts (ordered log-increments, `src/drmTMB.cpp:3024-3030`). A
   **zero-mean** random intercept is therefore identified — the `ordinal::clmm` setup — and the
   branch already adds a group contribution to `mu(i)` for phylo (`src/drmTMB.cpp:2986-2996`).
   Residual difficulty is *weak identifiability with few groups*, a recovery-evidence problem,
   not a parameterisation blocker.

3. **Siblings already did most families.** zero_one_beta's sibling `beta_binomial` already has
   the mu-RE block (`src/drmTMB.cpp:2862-2879`) — near-copy. tweedie ≈ working Gamma branch.
   skew_normal's `mu` is the marginal mean by construction (`xi = mu - omega·mean_shift`,
   `src/drmTMB.cpp:2447`), so a zero-mean RE does **not** trade off against skew `alpha`.

**Per-family difficulty (easiest → hardest):** `tweedie → skew_normal → binomial → zero_one_beta → cumulative_logit`.

| Family | model_type | R rejection site | C++ branch | Note |
|---|---|---|---|---|
| tweedie | 16 | `R/drmTMB.R:8697` (`validate_tweedie_random_terms`) | `2593-2621` (log) | ≈ Gamma; `p∈(1,2)` estimated, orthogonal to mean RE |
| skew_normal | 17 | `R/drmTMB.R:8645` (`validate_skew_normal_random_terms`) | `2427-2468` (identity) | `mu` = marginal mean; clean vs `alpha` |
| binomial | 18 | `R/drmTMB.R:5429` (inline) | `2917-2983` (logit) | keeps fixed intercept; interleave RE with `mi()` plug-in |
| zero_one_beta | 15 | `R/drmTMB.R:4991` (generic bar reject) | `2782-2858` (logit) | copy beta_binomial block; R never extracts term yet |
| cumulative_logit | 13 | `R/drmTMB.R:5704` (syntactic bar reject) | `2984-3051` | intercept already dropped → identified; needs few-group recovery evidence |

R already runs `extract_random_mu_terms` before rejecting for tweedie/skew_normal/binomial;
zero_one_beta and cumulative_logit reject the bar *syntactically* and need the extract step added.

**Per-family edit recipe (verified minimal edit points).** The R RE builder
(`build_random_mu_structure`, `R/drmTMB.R:11764`), the `map` (`factor(NA)` on empty, `:16363`),
and all extractors (`ranef`/`VarCorr`/BLUP via `transform_mu_random_effects` `:18991`) are
**shared and family-agnostic — no per-family edit**. Each family needs only:
1. **R rejection → permissive** validator (mirror `validate_positive_continuous_mu_random_terms`, `:8658`);
2. **R build** — call `build_random_mu_structure` in the spec builder, thread `re_mu` (mirror poisson `:6147/6174`);
3. **R data block** — swap hardcoded dummies (`n_mu_re_terms=0`) for `re_mu$…` (mirror gaussian `:16914`);
4. **R start/params** — `u_mu = rep(0, re_mu$n_re)`, `random_names="u_mu"` when `n_re>0` (mirror `:15460, 4075`);
5. **C++ (load-bearing)** — paste one `if(n_mu_re_terms>0){ eta_mu += …; nll -= dnorm(u_mu,0,1,true); REPORT/ADREPORT }`
   block into the family branch, copied from **poisson `src/drmTMB.cpp:3054-3105`**; recompile.

The C++ block is **copied per branch** (not shared), which is why a family silently ignores
`u_mu` until the block is pasted. This is the one unavoidable per-family C++ edit.

---

## Scope — exactly in / out

**IN:** `mu`-side random **intercept** `(1 | g)`, estimator **ML**, for the 5 families above.
Plus a **first-class fix-`p` escape hatch for tweedie** (glmmTMB-style `map`) so tweedie RE
fits are usable despite the σ_u²↔p↔φ flat-likelihood trade-off. **Evidence bar = DG2 + honest
small-cluster-bias caveat**; DG3 multi-seed coverage is **deferred** to pair with Arc 1 (REML).

**OUT (must stay rejected — scope honesty):** random **slopes** `(x | g)` (Arc 2b);
`sigma`/shape/inflation-dpar RE `nu/zi/hu/zoi/coi` (Arc 2c); structured providers
`phylo()/relmat()/spatial()/animal()` (Arc 3); correlated `(1|p|g)` blocks; non-Gaussian REML
(SR159 guard stays intact). The sibling `_re_slope` and `sigma _re_*` ledger rows stay rejected.

---

## Division of labour (sequential, never concurrent — AGENTS.md)

Claude can do R-side wiring, docs, pure-logic tests. **TMB recompile + real fits + recovery
sims are the live toolchain** → Codex or a compiling Claude session; hand off turnkey at the
seam (`protocols/handoff.md`). Deferred DG3 multi-seed recovery → **Totoro** (needs MFA), never
GitHub Actions (D-50).

---

## Slices, roles, models

Standing roster (brain `agents/team-roster`): **Ada** orchestrates · **Rose** closes/audits ·
**Gauss** TMB/numerics · **Boole** formula grammar · **Fisher** inference/identifiability ·
**Curie** recovery testing · **Noether** math↔code↔doc · **Emmy** R architecture · **Jason**
scout · **Ranganathan** NotebookLM · **Grace** CI/release.

| ID | Slice | In → Out | Dep | Role · Model · Effort |
|---|---|---|---|---|
| S0 | Seam-map confirm (R→TMB assembly) + DRM.jl twin scan | code → change-map | — | Jason+Gauss · Haiku→Sonnet · med |
| S1 | Grammar freeze: `(1\|g)` uniform; add `extract_random_mu_terms` to zero_one_beta, cumulative_logit | S0 → freeze note | S0 | Boole · Sonnet · med |
| S2 | R wiring (all 5): permissive validators; `build_random_mu_structure`; data/start; **tweedie fix-`p` API** | S1 → `R/drmTMB.R`, `R/parse-formula.R` | S1 | Gauss · Sonnet · high |
| S3 | TMB wiring (all 5): per-branch accumulation block; **tweedie fix-`p` map hatch**; recompile | S1 → `src/drmTMB.cpp` | S1 | Gauss · **Opus** · high |
| S4a–e | DG2 sentinel per family (tweedie: fix `p` at DGP; ordinal: cutpoint stability few groups) | S2+S3 → `tests/testthat/test-phase18-<fam>-mu-random-intercept.R` | S2,S3 | Curie · Sonnet · med · **∥×5** |
| S6 | Honest-scope docs + ledger (small-cluster RE-SD bias caveat; tweedie fix-`p` usage) | S4 → design docs, ledger, NEWS, roxygen | S4 | doc_writer+Boole · Sonnet · med |
| ~~S5a–e~~ | **DEFERRED (post-0.6.0, pairs Arc 1/REML):** DG3 multi-seed SD bias/coverage on Totoro | (after release) | — | Curie+Totoro · Sonnet · med |
| S7 | Adversarial CP-review, default NOT-DONE | S6 → verdicts | S6 | Fisher,Noether,Emmy,Rose · **Opus** · high · **∥×4** |
| S8 | Consolidate: after-task, issue, brain decision, merge-ready | S7 | S7 | Rose · Sonnet · med |

**Parallel sets:** {S4a–e}, {S7×4}. **0.6.0 spine:** S0→S1→(S2,S3 coupled)→S4→S6→S7→S8.
(S5 deferred.)

**Why implementation is NOT per-family-parallel:** all 5 edit the same two files
(`R/drmTMB.R`, `src/drmTMB.cpp`) + one shared `.cpp` recompile. S2/S3 are single shared-seam
passes; only investigation, evidence, and review fan out.

**Estimate:** ~10–12 dispatches for the 0.6.0 spine; does **not** fit one session — hand off
after S1 (freeze) and S3 (compiled+smoke). cumulative_logit and skew_normal may each need a
dedicated iteration. All DG2 evidence is local; the deferred DG3 campaign is the only Totoro item.

---

## Copy-from templates (verified paths — reuse, don't reinvent)

- **DG2 sentinel:** `tests/testthat/test-beta-location-scale.R:97-144` ("beta mu supports
  ordinary random intercepts") + `new_beta_random_intercept_data()`; Gaussian helper style in
  `tests/testthat/test-gaussian-random-intercepts.R`; wired examples
  `test-phase18-{poisson,nbinom2}-mu-random-effect.R`.
- **DG3 recovery quartet (deferred):** clone `inst/sim/dgp|fit|run/sim_*_bounded_response_mu_random_intercept.R`
  on shared engine `inst/sim/R/{sim_registry,sim_runner,sim_aggregate,sim_uncertainty}.R`.
- **Streaming/gating discipline:** `inst/dg3-power-arm/harness.R` (NOT_CRAN gate, flush-per-fit,
  sha256 metadata) — reuse the discipline, not the adequacy statistic.
- **R plumbing template:** lognormal `extract_random_mu_terms` →
  `validate_positive_continuous_mu_random_terms` → `build_random_mu_structure`.

## Artifacts to update per family (verified)

- **Ledger (source of truth):** `docs/dev-log/dashboard/capability-ledger/cells.tsv` flip rows
  **mc-0059** (binomial), **mc-0225** (cumulative_logit), **mc-0463** (skew_normal),
  **mc-0538** (tweedie), **mc-0567** (zero_one_beta): `capability_status→implemented`,
  `work_status→verified`, `evidence_tier→point_fit_recovery`. Add `ev-*` rows to `evidence.tsv`.
  **Regenerate** `capability-surface.md/.html` via `tools/capability_ledger.py` (never hand-edit).
  Leave `_re_slope`/`sigma _re_*` rows rejected.
- **Design docs:** `docs/design/04-random-effects.md:224` (claim boundary + impl bullets);
  `docs/design/03-likelihoods.md` routes 13/15/16/17/18 (copy the working-route prose).
- **`NEWS.md`**, `?family` / roxygen.
- Do **NOT** touch `structured-re-*.tsv` (different, structured-provider axis).

---

## Evidence bar / claim boundary — resolved by NotebookLM grounded search

Full synthesis: `scratchpad/arc2a-notebooklm-synthesis.md` (notebook `7742e05e`, 76 sources;
web sources are UNVERIFIED triage; claims resting only on the notebook's generated report are
flagged UNVERIFIED).

**Decision.** The honest 0.6.0 claim is **"a `mu` random intercept is accepted and its SD is
recovered at a known DGP under ML-Laplace, with a documented small-cluster downward-bias
caveat"** → **DG2 = `point_fit_recovery`** is the release bar; DG3 coverage deferred. Rationale:

- **RE-SD is biased downward under Laplace with few/small clusters** (fixed effects stay fine);
  AGHQ is the accepted fix but is not readily available in the TMB single-Laplace path — so
  **document the bias** rather than claim unbiasedness.
- **REML is not classical for non-Gaussian GLMMs**, but a Laplace integrated-likelihood "REML"
  (glmmTMB `REML=TRUE`) is meaningful and reduces small-cluster bias. Default **ML**; report the
  method honestly; treat any ML-vs-REML gap as a bias diagnostic. SR159 stays intact — REML
  broadening is Arc 1.

**New design requirements surfaced by the search (folded into S2/S3/S6):**
- **tweedie:** σ_u²↔p↔φ flat-likelihood trade-off — estimate `p` by default but **ship a
  first-class way to FIX `p`** (map hatch) + good pilot inits; fix `p` at the DGP for DG2.
- **skew_normal:** `mu` already the mean (Azzalini centred) → no α aliasing — but **guard against
  the singular information matrix / diverging α̂ as α→0** (bounding/penalisation) with an RE.
- **binomial (and all five):** ship the small-cluster RE-SD downward-bias caveat in `?family` + vignette.
- **cumulative_logit:** mean-zero RE + no free fixed intercept (already satisfied); DG2 must
  confirm cutpoint stability with few groups.

---

## Plan review (before S2 — cheap, catches wrong slicing)

- **Boole:** is `(1|g)` parsing truly uniform once `extract_random_mu_terms` is added to the two
  syntactic-reject families, or does cumulative_logit need a bespoke parse branch?
- **Fisher:** is DG2 the right release bar (confirmed via the literature above), and is the
  caveat wording defensible?

## Verify (mandatory)

1. Per-family DG2 sentinel green in `devtools::test()`.
2. `rcmdcheck --as-cran` clean after S3 recompile (0/0/0).
3. Docs carry the honest small-cluster RE-SD downward-bias caveat (no "unbiased" claim); tweedie fix-`p` documented.
4. **D-43 gate:** 3 fresh agents (Fisher/Noether/Emmy) review the completion claim, each
   defaulting NOT-DONE; ≥2 NOT-DONE withholds "done". Rose checks scope honesty (SR159 intact,
   no slope/`sigma` creep, sibling ledger rows still rejected).

## Consolidate

5 family branches accepting `(1|g)` on `mu`; DG2 sentinels; updated design docs + regenerated
ledger; NEWS; after-task report in `docs/dev-log/after-task/`; one parent GitHub issue; a brain
DECISION note. Branch merge-ready — **do not merge without S7**.

---

*Discipline: symbolic/interface first → freeze → shared-seam impl → per-family DG2 evidence →
honest-scope docs → fresh NOT-DONE-default CP-review. Heavy campaigns → Totoro/DRAC, never
Actions. `/ask-brain` before deriving; durable decisions → files.*
