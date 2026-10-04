# drmTMB R–Julia parity, Arc 1: the honest ledger (v2, for G0)

```
🎯 GOAL
Solo platform: Claude Code (read from tools/session_ownership.sh: "PLATFORM: Claude Code").
Lane taken: Arc 1 branches off origin/main 7f7293f2d (#1421 merged 2026-09-24 14:48 UTC).
  Other lanes: codex #1304 (assigned to this lane, read-only; never edited), #1110, #1111,
  #1417, #1418, #1033; claude #1419, #1191. Arc 1 does not touch R/drmTMB.R.
Deliverable: a parity matrix whose every non-GREEN row carries a machine-checked honest state
  (CITED-PARTIAL, FENCED, or OWNER-DECISION with a named owner), an admission census proving
  every route the bridge admits joins a ledger row or a refusal gate, refusals in R for every
  measured silent-substitution route, an evidence-cited issue close list, and a written
  absorption of #1304. All as draft PRs; nothing merged, closed, or promoted without Shinichi.
HEADLINE: one command, `Rscript tools/parity-honesty-gate.R`, that prints the honest state of
  all 45 rows and exits non-zero while any row is UNCITED or DEFECT. It turns the destination
  from a reading exercise into a check, and it keeps the ledger honest after Arc 1 ends.
IN PARALLEL: generator join fixes · pure-R admission census · issue census · #1304 read-through.
DEFER (Arc 2, on the decision map only): lifting any fence, new routes (#1304's `marginal=`
  and NB2 coupled covariance), claim_status promotion, AGHQ/VA/h2 wiring, anova() LRT wiring,
  same-seed bootstrap design (D-213 #3), #1191/#1129 precision bar.
DISCIPLINE: verify = gate-check --reverify on every leaf + fresh adversarial review before any
  "honest" claim · compute = local Mac, JULIA_NUM_THREADS=4, OPENBLAS_NUM_THREADS=1, Julia
  1.13.0 via JULIA_HOME, every run estimated first (D-139) · closure = honesty gate prints
  uncited=0 defect=0 on the stacked branch, and the only non-green rows left are FENCED,
  CITED-PARTIAL, or OWNER-DECISION rows listed in "What stands between Arc 1 and the destination".
```

## Pre-G0 amendments (2026-09-24; Rose and Noether reviews; these override the text below where they differ)

The plan below is the blind-picked arm, kept verbatim so the record matches what was chosen. Two
reviews ran before G0: Rose (claims and scope) returned READY WITH FIXES, and Noether (semantics of
the honest-state vocabulary) returned CONSISTENT WITH FIXES with five blocking gaps. Each fix is
listed with the finding it answers.

**Base and ownership**
- A1 (Rose 1). #1421 merged as `7f7293f2d`; its branch is deleted. Arc 1 branches start from
  `origin/main`. T8 is moot. Read every "stacked on #1421" below as "based on origin/main".
- A2 (Rose 2). #1111 (open Codex PR) also edits `R/julia-bridge.R`, the file S4 and S7 change. S0
  gains a step: diff #1111's `R/julia-bridge.R` hunks against the refusal functions S4/S7 touch. If
  the line ranges overlap, that becomes ticket **T10** for Shinichi (D-87) before S4 starts; if they do
  not, record the ranges in `recon.md` and lease only the functions S4 edits.
- A3 (Rose 3). #1304 is 63 commits ahead and 301 behind, 77 files. S9 is re-costed to 3 h, and
  leaf-S9 G1 counts commits as well as files.

**Honest-state vocabulary (S1a), made one rule per state**
- A4 (Noether 1, precedence). `pm_honest_state()` evaluates in this order and returns the first
  match: DEFECT, GREEN, FENCED, OWNER-DECISION, CITED-PARTIAL, CITED-LIMITED, UNCITED. A fence
  applies to a whole row only when a gate or fence entry names that row's capability; fence wording
  inside a `claim_boundary` does not fence the row.
- A5 (Noether 2, DEFECT). DEFECT is never parsed from boundary text. It comes from a committed
  override list, `inst/extdata/julia-defects.tsv` (capability, receipt path, finding), filled only
  from S2/S3 measurements. A DEFECT row is cleared by S4's refusal, after which it reads FENCED
  through its new gate.
- A6 (Noether 3, D-233). CITED-PARTIAL = `r_bridge_status == "partial"` with a cited
  `claim_boundary` (exactly D-233's bar). Rows with a cited boundary at `experimental`,
  `unsupported`, or a scope-limited native side read CITED-LIMITED. Both count as honest for the
  destination; the gate reports them separately so D-233's bar is not diluted.
- A7 (Noether 4, one fence source). FENCED = the row joins a `gate_id` in `julia-gates.tsv`, or its
  capability is listed in `julia-fences.tsv`. At S1a, `julia-fences.tsv` holds only decisions already
  signed (D-179 #3, #1108, D-181/D-209). Rows behind T1 to T6 read OWNER-DECISION until Shinichi
  answers; S7 then adds fences.
- A8 (Noether 5 and 6, rows 84/85). The "at least one family" fog rule is dropped. The matrix and the
  scoreboard both read interval evidence through the same S1b cellmap joined on capability, so they
  cannot disagree on these rows. Cells compared under a stated convention (rho12, REML mean-block
  SEs; D-234) are flagged in the cellmap and never count as a passing interval receipt.

**Model-identity sweep (S3)**
- A9 (Noether 7). A mismatch in the integrator label alone (same parameter names, count and df) is
  DIFFERENT-INTEGRATOR, not DIFFERENT-MODEL. `gaussian_sigma_random_intercept` is a second negative
  control with expected class DIFFERENT-INTEGRATOR. Only DIFFERENT-MODEL feeds S4(d); a
  DIFFERENT-INTEGRATOR cell feeds S5's ledger row and T5.
- A10 (Rose 5). `sweep.tsv` has a pinned header ending in a `classification` column; D3 selects that
  column by name, not by position.

**Gates**
- A11 (Rose 4). D5 becomes a join: read the TSV at `origin/main` and at the branch tip, match on
  `capability_id`, and print `PROMOTED=<n>` for ids present on both sides whose `claim_status`
  changed. EXPECT `PROMOTED=0`.
- A12 (Rose 6). D2 also requires at least one passing expectation per registry family (a floor on
  PASS, not only `FAIL 0`), so an empty test file cannot pass.
- A13 (Rose 7, 8). S7 depends on S1a as well as G1 and S4. At checkpoint C0, S0 finishes before the
  other five start; six children are dispatched in total, never more than five live.

Net effect: no new slices; S9 grows by 1.5 h (about 23.5 agent-hours in total); two new committed
data files (`julia-defects.tsv`, and `julia-fences.tsv` as planned); one possible new owner ticket (T10).

## Context

Arc 1 of the R–Julia parity programme. The programme's goal (D-203, D-213) is that every native
drmTMB workflow runs on the Julia engine too. Before any coverage is widened, the ledger that
reports parity has to be trustworthy. At the #1421 pin (DRModels `da8b3f871`) the matrix shows
4 of 45 capabilities GREEN, and the non-green states are a mix of honest boundaries, generator
bugs, stale NEXT text, missing receipts, and at least one route that silently fits a different
model. Arc 1 separates these cleanly and fixes the parts that are defects. It does not widen
coverage.

## WHAT THE BRAIN ALREADY KNOWS (Phase 0.25 sweep receipt)

| surface | evidence it ran | finding | call |
|---|---|---|---|
| repo git state | `git fetch; git rev-parse origin/main` → `54df129fe`; `git worktree list`; `git -C <#1421 worktree> status -sb` clean, 1 commit `8a3aeb02a` ahead; `git diff --stat origin/main..HEAD` 9 files, docs/receipt only; `.git/info/exclude:28` already ignores `.unlazy/` | #1421 is the base; no uncommitted work in the lane; ~30 prunable foreign worktrees (not ours) | resume on #1421 |
| lane state | `lane_preflight.sh` → FOREIGN LANE ACTIVE (codex), 11 lanes live, no leases on drmTMB, coord board committed; 17 duplicate design slots, next free 277 | no lease conflict yet; claim paths before writing | claim with `lane_lease.sh` |
| open PRs | `gh pr list --state open` | #1304 is 299 behind main, `mergeStateStatus: DIRTY`, 4 commits, ~78 files; `git merge-tree` against #1421 conflicts in README.md, parity-matrix.md, parity-scoreboard.md, a capability-ledger TSV, vignettes/formula-grammar.Rmd | absorb by folding (below), not rebasing |
| twin repo | pinned DRModels `da8b3f871`: `git grep -i ghq -- src`; `docs/dev-log/evidence/parity-intervals.tsv` read | `src/aghq_1d.jl:10` "Do not relabel the production `(1\|g)` GHQ-32 `:LA` path as AGHQ": DRModels integrates ordinary random intercepts by 32-node Gauss–Hermite, while native drmTMB uses Laplace. parity-intervals.tsv has 14 `cell_id`s, 11 match a `capability_id` verbatim, `poisson_fe` and `gauss_locscale_fe` only by renaming, `gauss_mean_only` unmapped | reuse the DRModels tables; map in drmTMB, do not edit DRModels |
| brain (semantic) | `search_notes("drmTMB R Julia parity matrix honest ledger bridge", project=shinichi-brain)` | the Laplace↔Laplace twin-hunt map; D-213 text; crown-0.6 plan. Nothing that already builds an honesty gate or admission census | none to reuse beyond decisions |
| brain (grep) | `grep -n "D-233\|D-234\|D-280" DECISIONS.md`; `grep -n "^### D-213"`; `grep -n parity AGENT_LOG.md \| tail`; `grep -in parity OPEN_QUESTIONS.md` (0 hits); `grep -in parity projects/deep-research/README.md` (0 hits) | D-213 #4 says #1116 to #1118 "stay as issues" for the reverse gap, but #1116 and #1118 have since landed (below). AGENT_LOG 2026-09-24: the re-pin found 13 stale citations that CI could not see | issue census must reconcile D-213 against NAMESPACE |
| leaf ledgers | scout read of `.unlazy/{parity,true-parity,rev-parity,night,followup}` | 35 of 89 leaves not fully checked by their own claim; most open items are "PR merged green" gates; `a8c response_mask` (9 open) is an unfunded arc; `rev-parity a4/a5` are spike decisions | reconcile as run state; adopt none wholesale |
| **Verdict** | | **Build the gap**: the honesty classification + gate, the admission census, three R-side refusals, the interval join map, and the issue close list are new. **Reuse**: all generators, the existing receipts, parity-classc.tsv and parity-intervals.tsv, the `reml-uncited/receipt.md` q4 measurement. **Resume**: #1421 as base. **Fold**: #1304's evidence. | |

Phase 0.5 grounded search: not needed; no novelty or literature claim is made.
Phase 0.6 route check: the destination is writable in one sentence (the locked one), and every
slice below names a real output path. Two either/or items remain, and both are owner decisions:
fence-or-expose for AGHQ/VA/h2, and how to disclose the integrator difference. They are tickets
on the decision map. The slices that depend on them are fenced to run after G1. **Route is
knowable** for everything else.

## Measured findings the slices are built on

These were read at the #1421 tip. Items marked INFERRED are hypotheses a slice must confirm.

1. **Join defect, zero-one-inflated beta** (`tools/write-parity-matrix.R:151,172-181`). The
   plain-family join excludes rows whose syntax mentions a modifier dpar in
   `c("zi","hu","zoi","coi")`. For `zero_one_beta`, `zoi` and `coi` are intrinsic dpars, so
   `fe_zero_one_beta` (`julia-capabilities.tsv:30`) can never join. `test-parity-matrix.R:139-143`
   hides this behind a `pending_1184` skip-list, and #1184 merged on 2026-09-06.
2. **Stale NEXT text.** Row 81 (`parity-matrix.md:81`) says "still missing its own TSV row" but
   joins `gaussian_reml_random_intercept_mu` at tsv:38. Row 65 says it waits on #1184. The NEXT
   column is curated text that nothing checks.
3. **Fragile join keys.** `pm_family_constructor()` is a 2-entry hard map; `pm_modifier_routes()`
   is a 3-row table (R:139-149, 193-201). The beta-binomial trap (row 64) is guarded but only
   for that pair.
4. **Three generators read DRModels three ways.** `write-parity-matrix.R` and
   `write-parity-scoreboard.R` take HEAD of `DRM_JL_PATH`; `write-capability-status-join.R`
   takes `DRM_JL_REPO` plus `DRM_JL_REF` (default `origin/main`). The scoreboard and the join
   stamp the drmTMB HEAD SHA; the matrix does not. The byte-identity test skips without a clone.
5. **Silent substitution, measured.** REML bivariate phylo q4: `drm_julia_biv_phylo_dimension()`
   (`R/julia-bridge.R:1347-1356`) classifies by the set of dpars carrying a phylo marker and
   ignores the marker labels. A block-diagonal call (`phylo(1|p|sp)` on means, `phylo(1|ps|sp)`
   on scales) is fitted as the dense model: df 15 against native 11, all five fixed-effect SEs
   NaN, |julia − tmb dense| = 0.020 against |julia − tmb block-diagonal| = 4.57
   (`docs/dev-log/evidence/julia-r-parity/reml-uncited/receipt.md:143-168`).
6. **Different integrator, same model.** Gaussian `sigma ~ (1|g)`: Laplace natively, GHQ-32 in
   DRModels. The gap is measured and cited as a negative control (tsv:25, bridge R:508,547).
   INFERRED, needs S2/S3 to confirm: ordinary `(1|g)` on poisson, nbinom2, binomial, gamma, and
   beta is not refused by `fe_only_random_effects` (`julia-gates.tsv:16` lists only
   student/lognormal/…), has **no ledger row** (the only `(1 |` rows are Gaussian, phylo, and
   relmat), and would reach DRModels' GHQ-32 `:LA` path. #1304's new row says the same thing:
   "`:LA` remains GHQ-32". If confirmed, that breaks destination clauses 2 and 3 at once.
7. **Hurdle NB2 cross-spelling** (row 62). Native `truncated_nbinom2()+hu` fails *inside Julia*
   (`unknown dpar "hu"`); the bridge spelling is `nbinom2()+hu`. Loud but late. It should be
   refused in R.
8. **Interval receipts cannot join.** parity-intervals.tsv is keyed by `cell_id`
   (`parity-scoreboard.md:220-222`). Bootstrap rows read INTERVAL_MISMATCH by design, because
   the engines draw their own resamples.
9. **Issues.** Evidence against `origin/main`:
   - #1116: `export(chibar_pvalue)` and `export(lrt_boundary)` are in NAMESPACE. Landed.
   - #1118: `coevolution_cor/vc/summary` are exported. Landed.
   - #499: `engine = c("tmb","julia")` and 13 bridge-payload hits. The core has landed; epic hygiene is still open.
   - #1150: no workflow runs the receipt scripts. Open.
   - #1117: `aicc` and `weights` landed; `anova.drmTMB` always aborts (`R/methods.R:2765`); there is no `update.drmTMB`. Partial, and it overlaps #1240 and #1241.
   - #1184 has merged, but the matrix's own text still waits on it.

## Decision map (what Arc 1 cannot settle)

**Destination** (locked): every one of the 45 capabilities is GREEN, or its non-green state has
a cited receipt or a signed permanent fence. Every route the bridge admits has a ledger row the
generators actually join. No bridge route silently fits a different model than the one the user
wrote. No open issue in the programme describes work that has already landed.

**Decisions so far** (locked, cited): one-directional parity (D-203, D-213 #4) · claim_status
is maintainer-only · #1304 assigned to this lane; read, then rebase or fold, never edit ·
`partial` with a cited boundary is honest (D-233) · convention-normalised rho12/REML SEs
(D-234) · both paths guarded on an optimiser-path change (D-273) · in-process relationship
tests (D-277) · D-139 estimates · cross-family bivariate fenced (D-179 #3) · engine control
surface fenced (#1108, closed) · mi() on the bridge fenced (D-181, D-209).

**Open tickets** (each is decide-with-Shinichi at G1 unless marked; recommendation first, then
the default if he says "use your judgment"):

| # | question | recommendation | default | blocks |
|---|---|---|---|---|
| T1 | AGHQ on the bridge (row 86): expose or fence? | **Fence now** with an R refusal that names the native route. Exposing is Arc 2 widening. | fence | S7 |
| T2 | VA/ELBO (row 87): expose or fence? | **Fence now**, same shape | fence | S7 |
| T3 | heritability/icc/repeatability on bridge fits (row 90): wire off `fit$bridge$vcov` or fence? | **Fence now** with a message; wiring is Arc 2 and needs its own receipt | fence | S7 |
| T4 | `anova()` LRT (row 89): both engines refuse today, so parity holds by refusal. Is that a permanent fence or Arc 2 work (#1117/#1240)? | **Record it as a fence for Arc 1**, cite it on row 89, keep #1240 open for Arc 2 | fence | S7 |
| T5 | Integrator mismatch (finding 6): when a bridge fit integrates by GHQ-32 where native uses Laplace, is a ledger row with a cited boundary enough, or must the fit say so to the user? | **Ledger row plus a one-line note in the bridge fit's `summary()`**. The user sees it at the point of use, and the change is reversible. #1304's `marginal = "Laplace"` is the Arc 2 fix. | ledger row only (no user-facing change without his word) | S5, S4d |
| T6 | Row 79 (Gaussian phylo RI + slope, 2 SD): fenced, but the matrix calls the fence "stale for Gaussian". Keep and re-cite, or open Arc 2? | **Keep and re-cite** the gate; put lifting on the Arc 2 list | keep | S7 |
| T7 | #1304 disposition (below): fold its evidence into a fresh Claude PR and carry its new API to Arc 2. Also: may a comment linking the successor be posted? | **Fold**; post the link comment after G3 | fold; no comment | S9 |
| T8 | Merge #1421 before Arc 1 PRs, or stack on it? | **Stack**, and merge #1421 when he is ready; Arc 1 PRs rebase trivially | stack | none |
| T9 (task) | Should DRModels grow a `capability_id` column in parity-intervals.tsv? | **No, not in Arc 1**. Keep a drmTMB-side `cell_id → capability_id` map with provenance; raise the upstream column as a DRModels issue after G3 | map in drmTMB | none |

**Not yet specified (fog):**
- What counts as a receipt for a *method-level* capability (profile CIs, bootstrap CIs, rows
  84/85) that spans families. Working rule for Arc 1: CITED-PARTIAL when at least one ledgered
  capability has a passing interval receipt, with the families named in the boundary. That rule
  may need Shinichi's word once he sees the rows.
- How exhaustive the admission census grid must be. Family × structure × which-dpar-carries-a-
  random-effect is combinatorial. Arc 1 samples one formula per (family, structure, dpar-slot)
  cell; interactions between two structures are not covered.
- Whether the q4 block-diagonal case has siblings: other covariance layouts that the bridge
  classifies by dpar set alone (q2 phylo, relmat). S3 is designed to find these, but its grid
  may not reach them.
- #1191/#1129 (non-Gaussian precision bar): as far as can be seen it does not block Arc 1
  honesty, because a partial row with a cited boundary is honest (D-233). It may matter if
  Shinichi wants a precision bar attached to "CITED-PARTIAL".

**Out of scope** (with reason): lifting fences, new routes, and claim_status promotion are Arc 2
by the brief. `a8c response_mask` is an unfunded arc. #1033, `_julia_skip2_artifacts/`, and
#1417/#1418/#1419 are foreign. #1110/#1111 are foreign and do not block Arc 1: they touch
`R/drmTMB.R` roxygen and bridge help, and Arc 1 edits only refusal code in `R/julia-bridge.R`,
so any conflict is textual. GitHub Actions changes (#1150) are listed for Arc 2, because
wiring receipt checks into CI costs minutes and is a separate decision under the local-checks
rule.

## How #1304 is absorbed

#1304 is 299 commits behind main and conflicting. It mixes two things:

- **Evidence about routes already admitted on main.** The finding that DRModels `:LA` is GHQ-32
  for ordinary `(1|g)` Binomial/Poisson/NB2. Its four-fixture paired-seed summaries (500 seeds
  each), which are bounded, as its body says. The S7 source-subset verifier.
- **Coverage widening.** A new public `marginal=` argument on `drmTMB()`, a new NB2 coupled
  mu/sigma random covariance structure (with a `src/drmTMB.cpp` change), and two new ledger rows
  at `r_bridge_status = supported`.

Arc 1 therefore **folds, it does not rebase** (T7). S9 reads the diff and writes
`docs/dev-log/loop/arc1-honest-ledger/pr1304-absorption.md`, which covers:

1. every file in #1304, tagged FOLD-NOW, ARC-2, or OBSOLETE (superseded by main or #1421);
2. for FOLD-NOW evidence, the DRModels SHA it was measured at (`b2caf00f`). Anything cited at the
   `da8b3f871` pin is re-measured there (S3 covers the `:LA` fact on the same fixtures) or
   carries its original SHA explicitly. No evidence is re-labelled to a pin it was not measured at;
3. the ARC-2 items, entered on the Arc 2 list verbatim with #1304 as provenance, so nothing is
   silently dropped.

Folded material lands in a fresh Claude draft PR (PR-D below) with a provenance line naming the
#1304 commits. The Codex branch is never edited. A comment on #1304 linking the successor is
drafted in the absorption note and posted only after G3.

## Slices

Scope for the acceptance ledger: `.unlazy/arc1-honest-ledger/` (already git-excluded). Work
happens in worktrees under `~/local-scratch/lanes/`, branched from `claude/r-julia-parity-20260924`.
Every write is preceded by `lane_lease.sh --claim drmTMB --paths <OWNS>`.

Model column: scout = Haiku, build = Sonnet, ceiling = the single high-tier reviewer; all passed
as explicit `model` on the Agent call and audited with `claude-routing-audit.py`. The
orchestrator is this session.

| id | slice | member | model · effort | time | output (path) | OWNS | dep |
|---|---|---|---|---|---|---|---|
| S0 | RECON: re-measure the starting state at `origin/main` and the #1421 tip (counts, PR and issue states); reconcile the 35 unchecked leaves against `gh pr view` (merge gate met by a later PR → DONE; else OWED-to-Arc-1 / ARC-2 / ABANDONED) | Shannon | scout · low | 25 min | `docs/dev-log/loop/arc1-honest-ledger/recon.md` | that file | none |
| S1a | Generator honesty: (i) family-intrinsic dpars (`zoi`, `coi`) so zero_one_beta joins; delete the `pending_1184` skip; (ii) `pm_honest_state()` gives each row one of GREEN / CITED-PARTIAL / FENCED / OWNER-DECISION / UNCITED / DEFECT, from data (TSV `claim_boundary` + `evidence_url`, gates TSV, a small committed `fences.tsv` citing the signing decision), with no curated text; (iii) derive NEXT text from state, so it cannot go stale; (iv) new `tools/parity-honesty-gate.R` prints counts and exits 1 on UNCITED or DEFECT; (v) test twins updated | Gauss (tmb_engineer) | build · high | 3 h | `tools/write-parity-matrix.R`, `tools/parity-honesty-gate.R`, `inst/extdata/julia-fences.tsv`, `tests/testthat/test-parity-matrix.R` | those 4 | S0 |
| S1b | Pin and interval join: all three generators read the pin from `source-pins.json` and refuse a clone whose HEAD ≠ pin (one DRModels read path); add `inst/extdata/julia-interval-cellmap.tsv` (`cell_id → capability_id`, provenance column; `gauss_mean_only` recorded UNMAPPED, not guessed) and join it in the scoreboard | Grace (reproducibility_engineer) | build · medium | 2 h | `tools/write-parity-scoreboard.R`, `tools/write-capability-status-join.R`, `inst/extdata/julia-interval-cellmap.tsv`, `tests/testthat/test-parity-scoreboard.R` (new or extended) | those 4 | S0 |
| S2 | Admission census (pure R, no Julia): drive the bridge's pre-Julia admission over one formula per (family × structure {none, `(1\|g)`, `(1+x\|g)`, phylo, relmat, spatial, animal, q2, q4 dense, q4 block-diagonal} × RE-carrying dpar); record ADMIT / REFUSE(gate id). An in-process test asserts every ADMIT joins a TSV row through the S1a join function and every REFUSE names a gate in `julia-gates.tsv` (D-277: computed in process, no stored list) | Curie (simulation_tester) | build · high | 2.5 h | `tools/julia-admission-census.R`, `docs/dev-log/evidence/julia-r-parity/arc1-admission-census/census.tsv`, `tests/testthat/test-julia-admission-census.R` | those 3 | census S0; join assertion S1a |
| S8 | Issue census: every open issue from `gh issue list --search "julia OR parity OR bridge OR DRModels OR engine"`; a scout pass returns candidates, then the build tier verifies each LIKELY-DONE with a command against `origin/main` and drafts the close or narrow comment | Jason (scout) → Rose (verify) | scout · low → build · medium | 1 h | `docs/dev-log/loop/arc1-honest-ledger/issue-census.md` | that file | S0 |
| S9 | #1304 read-through and absorption note (section above) | Hopper (julia-porter lens, general agent) | build · high | 1.5 h | `docs/dev-log/loop/arc1-honest-ledger/pr1304-absorption.md` | that file | S0 |
| **checkpoint C1** | Ada reads the S1/S2/S8/S9 returns; rebalances; confirms S3's estimate | | | | | | |
| S3 | Live model-identity sweep: for every ADMIT cell with a native twin, fit native and bridge on a small fixture and compare parameter-name sets, parameter count, df, and the integrator label reported by DRModels. **Positive control**: the q4 block-diagonal fit must be flagged. **Negative control**: Gaussian location-scale must pass. Values are not compared (D-234). **D-139**: pre-run on 3 cells (both controls + binomial `(1\|g)`); estimate ~2 min Julia boot + ~10 s/cell × ~40 cells ≈ 10–15 min. If the pre-run extrapolates past 30 min, stop and ask | Curie | build · medium | 1.5 h (incl. ≤30 min run) | `tools/julia-model-identity-sweep.R`, `docs/dev-log/evidence/julia-r-parity/arc1-model-identity/{sweep.tsv,receipt.md}` | those | S2 |
| S4 | Refusals in R (TDD, one gate each): (a) q4 block-diagonal refused by reading marker labels in `drm_julia_biv_phylo_dimension()`; test that block-diagonal is refused **and** dense is still admitted with its receipt unchanged (both paths, D-273); (b) `truncated_nbinom2()+hu` refused before Julia boots, message pointing to `nbinom2()+hu`; (c) the random-slope REML ArgumentError passthrough (row 70) refused in R; (d) any further DIFFERENT-MODEL cell S3 finds becomes a gate, or a T-ticket if refusing would remove a working route | Gauss | build · high | 3 h | `R/julia-bridge.R` (refusal functions only), `inst/extdata/julia-gates.tsv`, `tests/testthat/test-julia-bridge-refusals-arc1.R` | those 3 | (a–c) S0; (d) S3 |
| S5 | Ledger rows for admitted-but-unledgered routes found by S2/S3: ordinary non-Gaussian `(1\|g)` if confirmed (claim_boundary cites the GHQ-32 vs Laplace receipt from S3 and #1304), ML q4 bridge route (row 91), and non-Gaussian phylo location-scale (row 77): ledger it or gate it. New rows enter at the lowest status their evidence supports and never at `covered`; the PR asks Shinichi to review each | Gauss | build · medium | 1.5 h | `inst/extdata/julia-capabilities.tsv` (rows appended), matching `docs/dev-log/dashboard/julia-capabilities.tsv` | those 2 | S2, S3; T5 for the note |
| S6 | Residual UNCITED rows after S1 regeneration: for each, cite an existing receipt (parity-classc.tsv, parity-phylo-nongaussian.tsv, the interval cellmap) or bank a small same-target receipt (rows 73 spatial, 74 animal). Each live run estimated (≤30 min each, local) | Curie | build · medium | 2 h | receipts under `docs/dev-log/evidence/julia-r-parity/arc1-receipts/`, TSV `evidence_url` edits | those | S1a, S1b, S3 |
| S7 | Fences and owner-decision rows: encode the signed fences in `julia-fences.tsv` (D-179 #3, #1108, D-181/D-209); apply T1–T4 and T6 answers (a refusal gate per fence answer); any unanswered ticket stays OWNER-DECISION with its owner named | Rose | build · medium | 1 h | `inst/extdata/julia-fences.tsv`, `julia-gates.tsv` rows, refusal messages in `R/julia-bridge.R` | those (sequential after S4 on the same files) | G1, S4 |
| S10 | MECHANICAL-VERIFY: regenerate all three artefacts at the pin; run the honesty gate; narrow tests, then `devtools::test()` with `DRMTMB_JULIA_TESTS=true NOT_CRAN=true`; `tools/ci-receipt-staleness.sh`; tip-identity receipt regenerated **last** in each PR touching `R/`; `gate-check --reverify` on every leaf | Grace | scout · low | 45 min | `docs/dev-log/check-log.d/2026-09-2x-arc1.md` | that file | S1–S7 |
| S11 | Adversarial review: refute "honest". Pick 6 non-green rows at random and check that the cited receipt supports the stated state; re-run 3 "already landed" issue claims against `origin/main`; check that the census grid reaches every family in `julia-family-registry.R`; check that no new TSV row carries a promoted claim_status | Rose (systems_auditor) | ceiling · high | 45 min | `docs/dev-log/loop/arc1-honest-ledger/rose-review.md` | that file | S10 |
| S12 | RECONCILE plan vs actual | Melissa | build · low | 20 min | `docs/dev-log/plan-actual/2026-09-2x-arc1-honest-ledger.md` | that file | S11 |
| S13 | Close-out: after-task report, AGENT_LOG, DECISIONS entries for any T-answers; handover if Arc 1 spans sessions | Rose | build · medium | 30 min | `docs/dev-log/after-task/2026-09-2x-arc1-honest-ledger.md` | that file | S12 |

**Parallel:** batch 1 = {S0} then {S1a, S1b, S2-census, S8, S9} (5 live). Batch 2 = {S3} then
{S4, S5, S6}. S4 and S7 share `R/julia-bridge.R` and `julia-gates.tsv`, so they run
**sequentially**. S1a and S1b own disjoint files and regenerate artefacts only in S10, so
generated docs are never contended. That avoids the 2026-09-06 receipt treadmill.

**PRs (drafts, stacked on #1421):**
- PR-A = S1a + S1b: generators, gate, and maps. No `R/` change, so no tip receipt.
- PR-B = S2 + S4 + S5 + S7: census, refusals, rows, and fences. Touches `R/`, so the tip receipt is regenerated last.
- PR-C = S6: receipts.
- PR-D = S9 folded evidence.

The regenerated matrix, scoreboard, and join ride in the last PR only, so they are regenerated once.

**Fan-out budget:** checkpoint C0: 6 new children (S0 scout, S1a, S1b, S2, S8 scout+verify
reuse, S9), 0 ceiling. Checkpoint C1: S3/S6 reuse the S2 agent (Curie); S4/S5/S7 reuse the S1a
agent (Gauss) after it returns; S10 is 1 new scout; S11 is 1 ceiling. Never more than 5 live.
Never `SendMessage` a running agent.
**SCOUT SUITABILITY:** yes. S0, S8's first pass, and S10 are bounded, read-only or mechanical.
**Estimate:** ~22 agent-hours of slice work; ~2 working days wall-clock with the parallel
batches. It does not fit one session, so run it as an `/arc-loop` with the goal and ledger on
disk and a handover at each session boundary.
**Plan review before execution:** Rose (claims and scope: is anything here Arc 2 in disguise?) and
Noether (does the honest-state vocabulary say the same thing as D-233's `partial`?). One pass
each, on this file, before G0.

## Acceptance ledger (Phase 2.5 draft)

`.unlazy/arc1-honest-ledger/GATES.md`: `OWNS:` the union above; scope = Arc 1 destination.
Leaf gates are written before dispatch. `$W` = the Arc 1 worktree; `$P` = the DRModels pin
checkout.

**Destination gates (GATES.md):**
- [ ] D1: no row UNCITED or DEFECT
  CHECK: `cd $W && DRM_JL_PATH=$P Rscript tools/parity-honesty-gate.R`
  EXPECT: `uncited=0 defect=0` and exit 0
  KNOWN EXCEPTION (PR #1425 review, 2026-09-24): `uncited=0` is not yet the whole
  claim. "Non-Gaussian phylogenetic location-scale (μ + log σ)" reads CITED-LIMITED
  only because its native side is `scope-limited` (`pm_honest_state()` takes that
  path even when `r_bridge_status` is NA); it has no bridge evidence and no fence,
  the bridge ADMITS the coupled route (nbinom2/gamma/beta) with no ledger row, and
  the scoreboard still reads it UNCITED. D1 is not met until that row gets a bridge
  citation or a fence, or `pm_honest_state()` requires bridge evidence on that path.
- [ ] D1b: every OWNER-DECISION row names a ticket and an owner
  CHECK: `Rscript tools/parity-honesty-gate.R --list owner-decision`
  EXPECT: each line matches `T[0-9]+ owner=Shinichi`
- [ ] D2: every admitted route joins a ledger row or a gate
  CHECK: `Rscript -e 'pkgload::load_all(compile=FALSE); testthat::test_file("tests/testthat/test-julia-admission-census.R")'`
  EXPECT: `FAIL 0` and `SKIP 0`
- [ ] D3: no admitted cell fits a different model
  CHECK: `awk -F'\t' 'NR>1 && $NF=="DIFFERENT_MODEL"' docs/dev-log/evidence/julia-r-parity/arc1-model-identity/sweep.tsv | wc -l`
  EXPECT: `0`, and the positive-control row for q4 block-diagonal reads `REFUSED`
- [ ] D4: no LIKELY-DONE issue left without a recorded disposition
  CHECK: `grep -c "^| LIKELY-DONE .*| pending" docs/dev-log/loop/arc1-honest-ledger/issue-census.md`
  EXPECT: `0` (every such row reads `closed-by-Shinichi` or `awaiting G3`; the latter is a named blocker, not a pass)
- [ ] D5: no claim_status promoted
  CHECK: `git diff origin/main -- inst/extdata/julia-capabilities.tsv | grep '^-' | cut -f6` compared with the `+` side for existing ids
  EXPECT: no existing id changes claim_status

**Leaf gates (one file per slice; representative):**
- leaf-S1a:
  - G1: `fe_zero_one_beta` joins. CHECK: `grep -n "Zero-one-inflated beta" docs/design/parity-matrix.md`. EXPECT: no `NO TSV ROW`.
  - G2: `pending_1184` gone. CHECK: `grep -c pending_1184 tests/testthat/test-parity-matrix.R`. EXPECT: `0`.
  - G3: no curated NEXT string remains. CHECK: `grep -c "still missing its own TSV row\|waits on #1184" tools/write-parity-matrix.R`. EXPECT: `0`.
  - G4: tests pass. CHECK: `test_file("tests/testthat/test-parity-matrix.R")` with `DRM_JL_PATH=$P`. EXPECT: `FAIL 0`.
- leaf-S1b:
  - G1: a pin mismatch refuses. CHECK: run the matrix generator with `DRM_JL_PATH` pointing at a clone on another SHA. EXPECT: a non-zero exit and a message naming both SHAs.
  - G2: three generators, one read path. CHECK: `grep -c "DRM_JL_REF\|rev-parse HEAD" tools/write-parity-*.R tools/write-capability-status-join.R`. EXPECT: only via the shared pin helper.
  - G3: `gauss_mean_only` recorded as `UNMAPPED`.
- leaf-S2:
  - G1: the census covers every family in `julia-family-registry.R`. CHECK: an in-test `setdiff()`. EXPECT: empty.
  - G2: the join assertion passes, or fails only on rows listed for S5 (the list is written at dispatch from S2's first run, before S5 starts).
- leaf-S3:
  - G0 (pre-run): 3 cells complete; the extrapolated total is recorded. EXPECT: ≤30 min, else STOP.
  - G1: positive control flagged `DIFFERENT_MODEL` before S4 and `REFUSED` after.
  - G2: negative control `SAME_MODEL`.
- leaf-S4:
  - G1: the block-diagonal q4 refusal test passes.
  - G2: the dense q4 fit is still admitted, and its existing receipt test passes unchanged.
  - G3: the `truncated_nbinom2()+hu` refusal fires before Julia boots (the test mocks the Julia boot and asserts it is not called).
  - G4: the tip-identity receipt is regenerated after the last `R/` edit. CHECK: `bash tools/ci-receipt-staleness.sh`. EXPECT: `FRESH`.
- leaf-S9:
  - G1: every #1304 file tagged. CHECK: the count of tagged lines = `gh pr view 1304 --json files --jq '.files|length'`.
  - G2: no folded evidence re-labelled to `da8b3f871` without a re-measure (manual gate, reviewed by Rose in S11).
- leaf-S11: manual gate. Rose's verdict file exists and lists at least one attempted refutation per sampled row.

Gates are claimed with `gate-check.mjs --scope arc1-honest-ledger --leaf leaf-<id> --claim`. A
refused claim means the slices are not safe to run concurrently; run them in sequence.

## Approval gates

- **G0**: approve this plan. Answer T8 (stack or merge #1421). Pre-authorise the envelope below.
- **G1**: answer T1–T7 (the defaults apply if he says "use your judgment"). Only S5's summary
  note, S7, and S9's fold wait on it; S0–S4, S6, and S8 proceed meanwhile.
- **G2**: only if S3's pre-run extrapolates past 30 min (D-139).
- **G3**: every GitHub write beyond draft PRs: closing or commenting on #1116, #1118, #499; a
  comment on #1304; merging any Arc 1 PR; any claim_status change.

```
PRE-AUTHORISED AFTER G0: scoped edits in ~/local-scratch/lanes/ worktrees on the OWNS paths;
  lane_lease claims; local Rscript/Julia runs each estimated ≤30 min; testthat and
  devtools::test(); regeneration of parity artefacts; gate-check --claim/--reverify; local commits.
OPTIONAL REMOTE AUTHORITY: push arc1 branches; open PR-A..PR-D as DRAFTS. Never merge.
MUST STOP: merge/close/comment on GitHub; claim_status change; editing any foreign branch
  (#1304, #1110, #1111, reader PRs, #1033); R/drmTMB.R; a run estimated >30 min; evidence that
  a refusal would remove a route users have working (becomes a T-ticket).
```

## What stands between Arc 1 and the destination, and whose call

| blocker | owner | effect if unanswered |
|---|---|---|
| T1–T4, T6 fence-or-expose answers | Shinichi | rows 86, 87, 89, 90, 79 stay OWNER-DECISION; D1 passes, D1b lists them; the destination is not reached on those rows |
| T5 integrator disclosure | Shinichi | ledger row only; clause 3 is met on "not silent" in the ledger but not at the point of use |
| G3 issue closures (#1116, #1118, probably #499; narrowing #1117) | Shinichi | D4 names them "awaiting G3" |
| claim_status on new rows | Shinichi | rows enter experimental/partial; honest, not promoted |
| #1421 merge | Shinichi | Arc 1 stays stacked; no effect on honesty |

## Risks

- **The S2 hypothesis is wrong or larger.** If ordinary non-Gaussian `(1|g)` is admitted with
  no row, S5 grows. If the census finds many unledgered cells, S5 is split per family, and
  Arc 1 stretches by about half a day per five cells.
- **A refusal removes a working route.** S4 refuses only measured DIFFERENT-MODEL cells, and
  anything else becomes a T-ticket (the MUST STOP line).
- **The honesty vocabulary is itself a claim.** Noether reviews it before dispatch; Rose tries
  to refute it in S11.
- **Receipt treadmill.** Generated docs are regenerated once, in the last PR. The tip receipt
  comes last in PR-B.
- **Citation drift is invisible to CI.** S1b's pin check and S10's local regeneration are the
  guard. Wiring it into CI is #1150, Arc 2.
- **Collision** with #1110/#1111/#1304 on `R/julia-bridge.R`. Arc 1 edits refusal functions
  only, leases the file, and never touches `R/drmTMB.R`.
- **Julia environment.** juliaup defaults to 1.10.0; every live slice sets `JULIA_HOME` to
  1.13.0 and uses the pin checkout's copied `Manifest.toml`. S3's pre-run proves the
  environment before the sweep.
- **Leaf ledgers read as done.** S0 treats leaf checkboxes as claims and verifies merge gates
  against `gh`.

## Questions still open (for G0/G1; the brief did not answer these)

1. T5: must an integrator difference be visible in `summary()`, or is a ledger row enough?
2. T1–T4, T6: fence-now defaults; confirm or pick "expose in Arc 2" for any of them.
3. The fog rule for method-level rows 84/85 (CITED-PARTIAL when at least one family has a
   passing interval receipt): acceptable?
4. D-213 #4 says #1116 to #1118 "stay as issues". Now that #1116 and #1118 have landed, may they
   be closed at G3, and should #1117 be narrowed to anova/update in favour of #1240/#1241?

## ARM METADATA

- wall time: 11 min by the session clock (08:33:53 to 08:44:46); the three scouts ran in the background inside that window
- slice count: 14 (S0–S13; S1 split into S1a/S1b)
- sub-agents used: 3 read-only Explore scouts (2 build-tier, 1 scout-tier); no execution or editing agents
