# Handover — drmTMB: REML/q-space arc complete → next arc is "turn the crosses to ticks"

Meta: 2026-07-08 · from Claude (Opus 4.8, Ada) · **to the next Claude session** · repo `drmTMB` ·
branch `drmtmb/biv-scale-side-reml` (**pushed**; 25 ahead of `main`, 0 behind, FF-mergeable) ·
15 commits this session, all green.

**You are Claude, picking up the drmTMB structured-RE programme.** The REML/q-space arc is DONE.
The next arc is the one Shinichi named: **turn every ✗ into a ✓ on the structured-RE q-series
support matrix.** Read this doc, then the doc set in §"How to resume". This doc stands alone —
you will never see the authoring session's chat.

---

## Mission (the durable why)

`drmTMB` = univariate + bivariate distributional (location-scale-shape) regression on TMB. The
programme goal is **v1.0 with honest inference**. Ayumi is pushing the research frontier with
increasingly complex phylogenetic location-scale models; the capabilities must be *there and
trustworthy* when she reaches for them.

**Shinichi's v1.0 scope (stated 2026-07-08, verbatim intent):**
- **one random slope for ALL structured random effects** — `phylo()`, `animal()`, `spatial()`,
  `relmat()` — under **Gaussian AND non-Gaussian**;
- **NO two random slopes** per random effect (defer to post-v1.0);
- cover **correlations of combinations** of location-scale-scale models as much as we can;
- his **q12** = counting *random components* (≈3 REs × (intercept + 1 slope) × 2 responses),
  **not** a dense 12×12 — *"some of them are independent of each other"* (block-structured).

⚠️ **Do not confuse two q-conventions.** drmTMB's *internal* q (see `R/drmTMB.R:~9186`) is
`q = 4 endpoints × n_coef` → q4 (intercept), q8 (+1 slope), **q12 (+2 slopes)**. The package's
"q12" is a **two-slope** block and is therefore **OUT of v1.0 scope**. Shinichi's q12 is a
component count. This tripped up the authoring session; do not repeat it.

---

## What this session accomplished

Full detail: `docs/dev-log/after-task/2026-07-07-structured-qspace-reml-arc.md` and the commit
messages (they are unusually complete — read them).

**ML/REML parity is now COMPLETE for every implemented cell.** Every combination ML fits, REML
now fits. No REML-without-ML, no ML-without-REML.

| slice | commit | result |
|---|---|---|
| q2 matched mean+scale phylo under REML | `d83b475f` | stale N=120 "Cox-Reid needed" verdict **superseded** |
| pre-existing test bugfix | `7611d9eb` | `tree = fx$tree` → bare symbol (v0.2.0's "0 fail" was overstated) |
| block-diagonal biv location-scale phylo under REML | `0acb908d` | + the **replication** finding |
| `sd(..., level=)` unified scale grammar | `b8c36770` | legacy `sd_phylo*` soft-deprecated (lifecycle) |
| ordinary sigma REs under REML (uni) | `feba9018` | gate 1973 relaxed |
| biv labelled scale-side sigma block under REML | `99138cfa` | gate 2046 narrowed |
| capability matrix + NEWS | `4275e701` | doc 168's "no general REML estimator" caveat was stale |
| **dense q4 + biv mu-sigma cors + q>2 blocks under REML** | `1b3e852b` | **two prior verdicts overturned** |
| **correlated residual-scale slope block (C++)** | `6b0ed817` | new ML engine capability |
| q-completeness matrix (reproducible) | `cccf2c47` | `scratchpad/q_completeness_matrix.R` |

### Two prior verdicts overturned by evidence (do not re-chase)

1. **q2 "REML degrades the mean, needs Cox-Reid"** → a below-floor small-`N` artefact. At N≥250
   REML is *less* biased than ML on `sd_mu` at every n. No Cox-Reid.
2. **dense q4 "sign-flip + always collapses"** → an **under-powered-fit** artefact.
   `scratchpad/q4_signflip_diagnostic.R` builds a q4 DGP with exactly ONE nonzero correlation and
   proves it lands on the **right endpoint pair with the right sign** — the mapping is correct.
   The "flip" was a collapsed variance component (`sd:mu2`→0.08) leaving its correlations
   unidentified at the boundary. With adequate information (n_tip≥~200 **and** n_each≥~10) the
   dense q4 converges and recovers, and **REML is strictly better than ML** there (pdHess 0.75 vs
   0.50; SDs debiased toward truth). Rejecting it under REML while ML admitted it was an
   **inverted gate**.

### The standing data caveat (banked doctrine, quantified)

**Scale-side variance components need within-group REPLICATION.** Below the floor, REML can
*underperform* ML. Ladders: `scratchpad/reml_*_ladder.R`, `reml_ordinary_sigma_re_probe.R`.
Uniform across intercept / slope / correlated blocks: n_each ≥ ~8 → REML debiases; n_each = 3 →
REML worse. Block-diagonal phylo: n_each ≥ 5 → 100% pdHess, 0% collapse; 1 obs/species → collapse
(use a FIXED `sd(level="phylogenetic")` scale = Model A+). `pdHess` is a **want, not a gate**.

### New engine capability (C++)

`sigma ~ x + (1 + x | id)` — a **correlated residual-scale intercept-slope block** — now exists
(previously only *independent* residual-scale slopes). The univariate likelihood
(`src/drmTMB.cpp`, `model_type == 1`) now applies the same-dpar `eta_cor_sigma` conditioning; the
DATA/PARAMETER plumbing already existed globally but was only consumed by the bivariate loop.
Recovery validated: truth (sd_int .50, sd_slope .30, ρ +.50) → (.494, .295, .494), all biases
≤ 0.006, pdHess 1.00 (`scratchpad/correlated_scale_slope_recovery.R`). This unlocks the ordinary
two-level DHGLM with correlated slopes on **both** location and scale, under ML and REML.

---

## THE NEXT ARC — "turn all the crosses to ticks"

### The authoritative picture (source of truth)

**Authority rule (doc 218):** the validator-owned TSV is truth; prose is derived.
→ `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` (**104 rows**).
**`docs/design/210-structured-slope-status.md` is STALE** — it says labelled structured slope
blocks are rejected; the TSV records them admitted. Trust the TSV.

Exclude `slope_class = multiple_slope` (**9 rows** — the q6/q12 *two-slope* blocks, admitted
2026-07-05 recovery-only). **Shinichi deferred these from v1.0.** That leaves **95 v1.0 cells**:

| | count |
|---|---|
| **fits** | **94 / 95** (the 1 miss is an `ordinary`-provider biv-q8 cell, `diagnostic_only`) |
| **interval-ready** (`inference_ready`) | **8** |
| **coverage-ready** | **8** |
| `supported` | **3** |

**So: fitting is done. Inference is 8/95.** That is the arc.

### The 8 inference-ready cells (Gaussian only)

- `intercept_only q1 mu` — phylo ✓, spatial ✓, relmat ✓ (animal ✗)
- `independent_one_slope q1 sigma` — phylo ✓, animal ✓, relmat ✓ (spatial ✗)
- `labelled_slope_covariance q2 mu1+mu2` — phylo ✓, relmat ✓ (spatial ✗, animal ✗)

Everything else is ✗ (planned/unsupported) or ◐ (`diagnostic_only`: q4 `mu1+mu2` labelled,
q4 all-four intercept, q8 all-four labelled). **Every non-Gaussian cell fits and NOT ONE has an
interval or coverage.**

### Three workstreams

**(a) FIT-GAP — univariate labelled structured slope block. [engine]**
`phylo(1 + x | p | sp)` on univariate `mu` is **rejected**, and **no TSV cell exists for it**.
The engine's labelled structured slope covariance was only ever built **bivariate** (q2/q4/q8
`mu1+mu2` / all-four). Since bivariate handles the strictly *harder* case, this is plausibly a
gate + assembler routing job rather than new C++ — **but verify, do not assume** (see Gotchas).

**(b) FIT-GAP — non-Gaussian structured slope covariance. [engine]**
No cells exist for: non-Gaussian **labelled** slope covariance; non-Gaussian **bivariate**
structured (q2/q4/q8); non-Gaussian matched `mu+sigma` one-slope. Needed for v1.0
("Gaussian AND non-Gaussian"). Likely per-family C++ blocks (`model_type` is family-dispatched).

**(c) INTERVAL/COVERAGE CAMPAIGN — 86 cells ✗ → `inference_ready`. [simulation programme]**
**This arc is ALREADY SCOPED AND METHOD-DECIDED.** Do not re-derive it:
- `docs/dev-log/handover/2026-07-06-claude-handover.md` (START HERE for this workstream)
- `docs/dev-log/2026-07-06-next-arc-ultraplan.md` (plan)
- `docs/dev-log/2026-07-06-arc-interval-method-research-memo.md` (research)

> **Method DECIDED (Shinichi, 2026-07-06):** profile-likelihood CIs are the **star**, one plain
> bootstrap fallback, **`supported` DEFERRED — cap at `inference_ready`**, BCa banked.
> Track **A1 (Gaussian profile extension)** is the first slice; candidate cells identified,
> **NOT yet spiked.**

### ⚠️ Is "all crosses → ticks" actually achievable? Honest answer: **yes, as scoped.**

There IS a real wall, and it is **already routed around**. Doc 218 §2–§5 proves:
all four interval methods (Wald, Wald-t, profile, percentile-bootstrap) are **centred on the
shrunk variance-component estimate**; no interval method fixes a biased *centre*. The oracle
recompute reaches nominal (0.887 → 0.956), but the *usable* bias estimator **failed** — the
parametric-bootstrap prototype recovers ~−0.01 against the oracle's −0.13. Doc 218 concludes
`supported` at deployment-g needs a **research-grade bias-correction derivation** — *"a maintainer
commission, not an autonomous engineering task."*

**That wall gates `supported`, NOT `inference_ready`.** Because Shinichi capped the target at
`inference_ready` (2026-07-06), the arc is achievable by engineering + compute. **Do not promise
`supported`.** If a future session is tempted to promote a row to `supported`, it must first
commission the bias-correction derivation.

### Deferred (explicitly, by Shinichi 2026-07-08)

- **two random slopes per RE** (the 9 `multiple_slope` rows: q6 two-slope location, q12 two-slope
  all-four). Already admitted `point_fit`/`extractor_ready` recovery-only. Leave them.
- `supported` promotion (see wall above).
- Ordinary-provider biv-q8 labelled cell (the single fit miss; `ordinary`, not structured).

---

## Key decisions & rationale (durable)

1. **Recovery-to-truth outranks second-order flags.** `pdHess=FALSE` is not failure; route CIs
   through profile/bootstrap. Every REML admission this session was gated on a **recovery ladder**,
   not a deterministic reference (a coupled/random scale-side has no closed-form restricted
   likelihood — recovery is the correct arbiter).
2. **Never condemn an estimator on one small-n result.** Both overturned verdicts were small-n /
   under-powered artefacts. Run the n-ladder (and the *replication* ladder) first.
3. **Admit with an honest data caveat rather than gate.** Dense q4 and the scale-side blocks are
   information-hungry, not broken. Gating them under REML while ML admits them is an inverted gate.
4. **Validate before admitting.** Where a gate covered two conditions and only one was validated
   (e.g. biv `sigma$n_re` vs `mu_sigma$n_cors`), the gate was *narrowed*, not removed.

---

## Files created / modified (this session's real diff, `a2ac0372..HEAD`)

Source: `src/drmTMB.cpp`, `R/drmTMB.R`, `R/parse-formula.R`, `R/random-effect-scale-formulas.R`,
`R/drmTMB-package.R`, `DESCRIPTION`, `NAMESPACE`, `man/drmTMB-package.Rd`,
`man/random_effect_scale_formulas.Rd`

Tests: `tests/testthat/test-reml-ordinary-sigma.R` (new), `test-sd-level-grammar.R` (new),
`test-reml-bivariate.R`, `test-reml-phylo-location.R`, `test-reml-direct-sd-phylo.R`,
`test-gaussian-random-intercepts.R`

Docs: `NEWS.md`, `docs/design/01-formula-grammar.md`,
`docs/design/168-r-julia-finish-capability-matrix.md`, `docs/dev-log/known-limitations.md`,
`docs/dev-log/ml-reml-coverage-2026-07-07.md` (**the ML/REML coverage record**),
`docs/dev-log/after-task/2026-07-07-structured-qspace-reml-arc.md`,
`docs/dev-log/after-task/2026-07-07-sd-level-grammar-phylo-canonicalization.md`,
`docs/dev-log/handover/2026-07-07-overnight-qspace-progress.md`,
**this doc**, and the `AGENTS.md` snapshot edit.

Evidence (`scratchpad/`, committed): `q4_signflip_diagnostic.R`, `reml_dense_q4_ladder.R`,
`reml_blockdiag_replication_ladder.R` (+ `.csv`), `reml_ordinary_sigma_re_probe.R`,
`reml_biv_sigma_re_probe.R`, `reml_parity_gaps_3A_ladder.R`, `correlated_scale_slope_recovery.R`,
`ml_reml_parity_audit.R`, `q_completeness_matrix.R`, `s5_ordinary_twolevel_scope.R`

**Never stage:** `scratchpad/*.log`, `scratchpad/pick_seed.R`, `scratchpad/s2-grammar.patch`,
`scratchpad/reml_rung1_probe.R` (untracked throwaways).

---

## Gotchas / failed approaches (the expensive lessons — read these)

1. **The `eta_cor_sigma` SEGFAULT.** I mirrored the *bivariate* loop's guard `if (cor_id >= 0)`.
   Wrong: the **generic mu-side builder** (which sigma reuses) sets `cor_id >= 0` on the **base
   intercept rows too** — it marks correlation-GROUP MEMBERSHIP — with `pair_index = -1`. That
   dereferences `u_sigma(-1)`. Correct guard: **`cor_id >= 0 && pair_idx >= 0`** (mirrors the mu
   loop's `cor_id >= 0 && mu_re_pos(idx) == 1`).
   **The crash was LUCKY.** Had `pair_index` been `0` instead of `-1`, it would have silently
   conditioned every intercept on `u_sigma(0)` — a wrong model that fits cleanly and returns
   plausible numbers. **Always gate a new covariance wiring on a known-truth recovery test.**
2. **`isolation: "worktree"` MIS-BRANCHED.** An agent worktree branched from a commit *predating
   the whole REML arc*, not from HEAD. The agent's work was correct but built on the wrong base.
   **Always have a worktree agent print `git branch --show-current` and `git merge-base` first.**
3. **Doc 210 is stale.** Prose drifts; the TSV is authority (doc 218's Authority Rule).
4. **`bf()` uses NSE.** `tree = fx$tree` fails — it needs a **bare symbol** (`tree <- fx$tree`
   first). This bug sat in a committed test and made "1205 assertions, 0 fail" an overstatement.
5. **Shell-escaping.** Regex parens in `Rscript -e '...'` break (`'\('` is an invalid R escape).
   Write probe scripts to files. Also: **`timeout` does not exist on macOS.**
6. **Prior "q8 blocker" (doc 220) was a data-size misdiagnosis** (36 params / 16 groups) — see the
   2026-07-05 M1 verdict in `AGENTS.md`.

---

## Blockers / open questions

- **(a)** Is the univariate labelled structured slope block a gate/routing job or new C++? The
  bivariate path routes through a general `re_cov` machinery (`theta_re_cov`), distinct from the
  pairwise `eta_cor_*` path. **Unverified.** Read `build_structured_mu_structure()` and the
  labelled-block assembler before estimating.
- **(b)** Non-Gaussian structured slope covariance almost certainly needs per-family C++
  (`model_type` dispatch). Unscoped.
- **(c)** The interval campaign needs compute (Totoro / DRAC). Scoped in the 2026-07-06 ultraplan.
- `animal` q1 `mu` intercept is ✗ where phylo/spatial/relmat are ✓ — an odd asymmetry worth a look.
- `spatial` is ✗ on `q1 sigma` one-slope and `q2 mu1+mu2` where the others are ✓.

---

## Mission control

| repo · branch | CI / checks | what shipped | plan by leverage |
|---|---|---|---|
| **drmTMB** · `drmtmb/biv-scale-side-reml` (pushed, 25 ahead of `main`, FF-mergeable) | reml 120 · gaussian-random-intercepts 425 · gaussian-location-scale 80 · parse 72 · sd-level 32 — **0 FAIL, 0 WARN**. Full `devtools::check()` NOT run this session. | ML/REML parity complete; `sd(level=)` grammar; dense-q4 + biv mu-sigma + q>2 admitted; **correlated residual-scale slope block (C++)**; two verdicts overturned | **1.** (c) interval campaign Track A1 (already scoped, method decided) · **2.** (a) uni labelled structured slope block · **3.** (b) non-Gaussian labelled/biv structured slopes · **4.** v0.3.0 release (S7) · *deferred:* two-slope, `supported` |

**Release state:** `NEWS.md` has a `0.3.0 (development version)` section; `DESCRIPTION` is **not**
version-bumped. v0.3.0 (S7) was never cut. Decide whether to cut it before or after the next arc.

---

## How to resume

Repo state is authoritative — trust it over any chat memory.

1. `git log --oneline -8` · `git status --short` (branch should be `drmtmb/biv-scale-side-reml`,
   clean but for untracked `scratchpad/*.log`).
2. Read, in order:
   - **this doc**
   - the `AGENTS.md` "▶ Latest — start here" snapshot block
   - `docs/dev-log/ml-reml-coverage-2026-07-07.md` (the ML/REML coverage record)
   - `docs/dev-log/handover/2026-07-06-claude-handover.md` + `2026-07-06-next-arc-ultraplan.md`
     + `2026-07-06-arc-interval-method-research-memo.md` (**the interval/coverage arc**)
   - `docs/design/218-structured-q-series-completion-map.md` (§Authority Rule, §2–§5 the wall)
3. **The source of truth is the TSV**, not prose:
   `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`.
   Re-derive the ✓/✗ picture yourself — do not trust this doc's counts blindly:
   ```r
   t <- read.delim("docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv")
   v <- t[t$slope_class != "multiple_slope", ]   # v1.0 scope: drop two-slope
   table(v$interval_status); table(v$coverage_status)
   ```
4. **Spawn Rose (`systems_auditor`) before any public/claim statement** — the repo's mandatory
   scope-honesty lens. Also available: Curie (recovery), Noether (math↔code), Fisher (inference).
5. Toolchain (this Mac runs it live — Claude does NOT need Codex for R):
   ```sh
   OPENBLAS_NUM_THREADS=1 NOT_CRAN=true Rscript -e \
     'devtools::load_all("."); testthat::test_dir("tests/testthat", filter="reml")'
   ```
   Heavy multi-seed ladders → Totoro (`≤100 cores`, `OPENBLAS_NUM_THREADS=1`) or DRAC.
   C++ changes require recompile via `devtools::load_all()` (~1–2 min).

### One-command resume (paste in your own authenticated terminal, from the repo root)

Interactive (you steer):
```
claude "Rehydrate from docs/dev-log/handover/2026-07-08-claude-handover.md + the AGENTS.md snapshot, then start the crosses-to-ticks arc: begin with workstream (c) Track A1 (Gaussian profile extension) per the 2026-07-06 ultraplan. Do NOT promote any row to supported."
```

Autonomous, clean context:
```
claude -p "Rehydrate from docs/dev-log/handover/2026-07-08-claude-handover.md + the AGENTS.md snapshot, then execute the Next Immediate Steps. Target inference_ready ONLY; supported is deferred. Two-slope rows are out of scope."
```

### Next immediate steps

1. Re-derive the ✓/✗ counts from the TSV (step 3 above). Confirm 95 v1.0 cells / 8 interval-ready.
2. Read the 2026-07-06 ultraplan; **spike Track A1** (Gaussian profile extension) on the
   candidate cells. This is the highest-leverage move: it converts the largest block of ✗ → ✓.
3. In parallel (independent), scope workstream **(a)**: read the labelled-block assembler and
   answer "gate or C++?" with file:line evidence before writing anything.
4. Keep two-slope deferred. Keep `supported` deferred.
