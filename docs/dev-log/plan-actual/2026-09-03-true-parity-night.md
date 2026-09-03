# Reconciliation — drmTMB true-parity overnight lane, Claude, 2026-09-03 (Melissa, arc N6)

Lane `claude/lane-true-parity-night`, worktree `~/local-scratch/lanes/drmTMB-true-parity-night`,
envelope D-208 (Shinichi, 2026-09-02 evening). Window: launched ~23:20 UTC 2026-09-02 from
`origin/main` @ `0ceb77eb0`, running unattended toward ~05:00 local 2026-09-03.

Read-only diff of planned vs actual. Sources: `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`,
`LOOP/ultra-plan.md`; `.unlazy/night/GATES.md` and `.unlazy/night/gates/leaf-n1.md` through
`leaf-n5b.md`; `scratchpad/rose/2026-09-03-rose-n1-verdict.md`, `-n2-verdict.md`, `-n3-verdict.md`;
`gh api repos/itchyshin/drmTMB/pulls/{1122,1124,1125,1126,1128}`; `gh api
repos/itchyshin/drmTMB/issues/{1123,1127,1129,1130}`; the 2026-09-02 reconcile
(`git show claude/rev-parity-handover:docs/dev-log/plan-actual/2026-09-02-true-parity.md`) for format.

## Arc disposition — N0–N6

| arc | planned (arcs.md) | actual | drift | status |
|---|---|---|---|---|
| N0 | Watch R-CMD-check + pkgdown on main `0ceb77eb0`; fix via docs/receipt PR if red | Checkpoint records main `0ceb77eb0` fully green (ubuntu release, os-matrix, pkgdown, deploy = success, 2026-09-02 23:4x UTC) | match | [x] verified |
| N1 | Extend `coef_labels` to structured/known-structured/joint/xfam payloads via the one producer; delete legacy `gsub()` in `drm_julia_predict_fixed_eta()`; flip S3-G4 ABANDONED→MET; live tests one structured route + xfam + joint; predict() factor/interaction case; docs 258 §7.4 rewritten | Delivered per PR #1124 body: producer covers relmat/animal/spatial (adds `resd`), biv known-structured q2 (`phylocov`), and joint/xfam by construction with tests; pre-existing main bug fixed (fits omitting `sigma`/`sigma1`/`sigma2`/`rho12` aborted under the echo — `drm_julia_bridge_default_dpar_labels()` added); `gsub()` deleted; predict() verified live with factor×continuous interaction. Rose (`rose-n1-verdict.md`) REFUTED the headline claim "every route passes the echo": the univariate `phylo(1 \| g)` route aborted on **both** main and the branch (`resd` block for a `phylo()` term never labelled), plus a neighbour hole (user `sigma ~ 1` on dispersionless families aborted) and a test-integrity finding (16 live-test sites across 9 files swallow engine errors as skips, gated on two different env vars — filed as #1127). Repair loop `gauss-n1` landed commits `7ac9d063d`/`e93c6d3e0`/`b0c98fb81`/`fc4690ea0`; gates N1-G10–G12 written for the three findings and MET on the coordinator's own re-run (10 gates met, 10 reran). Not covered even after repair, stated in design 258 §7.7: sigma-side phylo terms and random-slope phylo blocks remain measured-broken under the echo | scope grew: a main bug fix (default-dpar labels) plus a full Rose repair loop (3 findings, 3 new gates) beyond the arc's original single-pass description; PR head moved from the build sha `c7874b6c7` (checkpoint) to the post-repair sha `fc4690ea0e6ca5b0ba41b3eba696ae843f638151` (PR #1124 current head) | PR #1124 open, draft, CI `unstable` at last check; N1-G9 (PR merged, S3-G4 flipped) still `EVIDENCE: pending` |
| N2 | Port `heritability()`, `icc()`, `repeatability()` (issue #1115); symbolic alignment table first; R implementation on Gaussian random-intercept, `phylo()`, animal/relmat; delta-method SE; known-DGP recovery; roxygen; `check_pkgdown()`; board row | Delivered per PR #1125 body, term-for-term against DRM.jl `src/heritability.jl` @ 77513aa0 (Rose Attack 1: match on every formula term). Rose (`rose-n2-verdict.md`) REFUTED 4: (i) random-slope terms (`1 + x \| blk`) were accepted and summed an intercept variance with a per-unit-of-`x` slope variance, silently dropping `eta_cor_mu` — a dimensionally incoherent number with a confident SE and CI; (ii) the documented `component` label (`"phylo(1 \| species, tree = tree)"`) does not match the actual `sdpars$mu` name (`"phylo(1 \| species)"`) in roxygen, `man/`, design doc, and after-task; (iii) roxygen is silent about the `summary()` "repeatability" row using a different (total-variance) denominator than the new `icc()`, even though the design doc and after-task disclose it; (iv) the pilot's stated bias mechanism ("expected ML downward shrinkage", -0.02) was unsupported — a 150-rep Monte Carlo at the same n gives bias ≈ -0.002, within 1 MC SE of zero (the 20-seed pilot number was noise). Coordinator's gate-check (leaf-n2.md G9/G11) records repair for (i) — random slopes now refused structurally (`eta_cor_mu` present or multi-column mu random term) with a new "refuse slope" test — and for (ii) — documented labels corrected to the actual `sdpars$mu` strings. The G9 evidence text does not mention a fix for (iii) or explicitly for (iv); checkpoint.md says "prose fixed" without naming which of (iii)/(iv) that covers | Rose-repaired at least 2 of 4 refutations with gate evidence (i, ii); (iii) the roxygen-silent-on-`summary()`-collision finding and (iv) the bias-mechanism prose are not confirmed fixed by any gate text read — see Drift of record and Morning questions | PR #1125 open, draft; leaf-n2.md 9 gates met incl. G11; N2-G10 (PR merged, #1115 closed) `EVIDENCE: pending` |
| N3 | `objective_at()`/`start=` label vocabulary reaches `rho12` and the q4 phylo covariance block (A5 finding); RED tests from the A5 receipt workaround | Delivered per PR #1128 body: `fixef:rho12:<column>`; `phylo_sd:<axis>`; and — where the plan named one "phylo covariance block" label — the actual implementation split into two distinct families, `phylo_cor:<a>:<b>` (always a bounded correlation, for q=2 and block-diagonal q>2) and `phylo_theta:<a>:<b>` (the raw unconstrained Cholesky entry for a dense block, no transform), because a single label could not serve both the bounded-correlation semantics and the raw-scale semantics without misleading a user. Rose (`rose-n3-verdict.md`) ran 5 attacks, REFUTED 2, both repaired before merge per leaf-n3.md's own note: (a) the source comment on `drm_phylo_mu_dense_theta_index()` overclaimed a one-to-one "perturb one entry, one cell moves" mapping — perturbing one raw `theta_phylo` entry actually moves every correlation cell sharing its row (TMB's `UNSTRUCTURED_CORR_t` row-wise reparameterization); comment, design 35, and after-task rewritten to what was shown, entry→position index itself unaffected; (b) `phylo_cor:` accepted values in (0.999999, 1) that silently produced `NaN` (bare R warning, no abort) — now refused outside `\|v\| < 0.999999`, with a NaN positive-control test. A third, pre-existing, un-touched finding was noted, not fixed: the plain `cor:` family's `atanh(value)` (no `/0.999999` factor) has the same class of gap at a different, sub-1e-6, boundary | plan named one "phylo covariance block" label; actual split it into `phylo_cor`/`phylo_theta` after the Rose-driven naming/semantics correction; PR head advanced beyond the sha checkpoint.md records — checkpoint says `25b3c8e59` with "Sonnet Rose pass running" and "G5 = merge pending", but the PR's current head is `6def01c6d2538571ef95a7e25dcb0f36a1e40aa0` and leaf-n3.md already contains the Rose verdict and both repairs — see Drift of record | PR #1128 open, draft; leaf-n3.md G1–G4 met on the coordinator's re-run; N3-G5 (PR merged) `EVIDENCE: pending` |
| N4 | Project `Non-Gaussian phylogenetic location-scale (mu + log sigma)` onto the board as scope-limited; deterministic indefinite-Hessian test for `check_drm()` replacing the platform-boundary premise | Delivered per PR #1126 body exactly as planned: board row added, name byte-identical to DRM.jl's, basis re-derived from `cells.tsv` (nbinom2, zero_one_beta implemented; ten families rejected_by_design); deterministic test injects an indefinite `sdr$cov.fixed`; RED control recorded (disabling the negative-eigenvalue branch fails both the new and the pre-existing indefinite test; restored byte-identically) | none observed | PR #1126 open, draft; leaf-n4.md all gates met on the coordinator's re-run, incl. the RED control (N4-G4) |
| N5 | P2 inference-qualification PRE-RUN on Totoro (D-139): one row (`plain_binomial_nonphylo`), bootstrap R=20, both engines, 1 core, <10 min, pipeline proof only | ABANDONED honestly, as arcs.md itself records. `JuliaCall::julia_setup()` segfaults the R process on Totoro's R 4.5.3 / JuliaCall 0.17.6 stack for both Julia 1.12.6 and 1.10.10 across three env variants, while a concurrent unrelated lane's own `Pkg.test()` ran cleanly under the same Julia binary throughout (so an R-embedding problem, not Julia's or DRM.jl's). N5-G2 (bootstrap CIs from both engines) is correctly `EVIDENCE: pending`, not silently marked met. Secondary finding: `confint(method = "bootstrap")` errors on `cbind(successes, failures)` binomial responses — filed as #1123 | arc abandoned per its own scope, not a plan failure — D-139/N5-G5's fail-honest rule fired as designed; N5b created as the replacement leaf | [x] ABANDONED with reason, receipt on draft PR #1122 |
| N5b | Local pre-run first; only run the full pilot (4 `partial` rows × {wald, profile, bootstrap-single-column} × 2 engines × 5 seeds) if the measured per-cell time keeps it under 30 min on ≤6 cores, else stop for the morning | Pre-run 62 s; go/no-go rule applied: measured time supported RUN; full pilot ran 69 s on 4 PSOCK workers (`mclapply` forks segfault with libjulia on macOS). All cells converged on both engines. Wald/profile endpoint deltas ≤1.6e-5. Bootstrap endpoint deltas up to 0.18, attributed to independent bootstrap RNG streams between engines at R=20 (not a parity failure by itself — same-seed resampling or a larger R is named as the actual P2 design point). `biv_gaussian_residual` fixed effects documented as not profile/bootstrap-ready on the Julia engine (Wald only) | match — executed exactly the branching rule the plan specified | [x] done, receipts on draft PR #1122; N5b-G1–G4 all met |
| N6 | Close: Melissa reconcile → this file; after-task → `docs/dev-log/after-task/2026-09-03-true-parity-night.md`; handover refreshed; vault log; lease released; `LOOP/checkpoint.md` final | This file is the Melissa reconcile deliverable, written now. checkpoint.md's `NEXT` line still reads "Then N6 close" and lists no after-task file, no handover refresh, and no lease-release evidence as of the last checkpoint write — those N6 deliverables were not yet observed as complete in any file read for this reconcile | plan sequenced N6 after all PRs merge; actual state at read time has zero of the five N0–N5(b) PRs shown as merged (all `state: open`, `draft: true`), so N6 firing now is itself ahead of its own stated precondition ("as time allows" / after merges) | [ ] not started at last checkpoint; this file is a partial N6 deliverable written out of the arc's normal sequence, at the coordinator's request |

## Drift of record

- **N5 abandoned, replaced by a local N5b.** Totoro cannot embed Julia in R on its current stack
  (`JuliaCall::julia_setup()` segfault, R 4.5.3 / JuliaCall 0.17.6, Julia 1.12.6 and 1.10.10); the
  TMB half of the pre-run completed and a real bug was found (#1123). N5b re-scoped the same
  pre-run-then-pilot design to this Mac, where the embedding works, and both the pre-run and the
  full pilot ran and produced receipts. arcs.md itself already records this as the plan (N5b's
  scope line: "Totoro cannot embed Julia in R; see leaf-n5"), so this is disclosed drift, not
  silent substitution.
- **N1 grew a main-bug fix plus a full Rose repair loop.** The plan's arcs.md line describes one
  pass: extend the producer, delete the legacy rewrite, run tests. The actual work additionally
  (a) fixed a pre-existing bug on already-merged `main` (fits that omitted `sigma` aborted under
  the echo) and (b) absorbed a three-finding Rose refutation with a dedicated repair loop
  (commits `7ac9d063d`/`e93c6d3e0`/`b0c98fb81`/`fc4690ea0`, gates N1-G10–G12). Rose's one refutation was that the univariate `phylo(1 | g)` route aborted under the
  echo on both main and the branch (its `resd` block carried no label); the repair loop labelled
  it and it now fits live through the echo (leaf-n1:G10, skip counts as failure). What remains
  outside the contract, stated in design 258 S7.7 rather than claimed: sigma-side phylo terms and
  random-slope phylo blocks, measured broken before and after, unchanged in kind.
- **N3 split `phylo_cor`/`phylo_theta` after a naming correction.** arcs.md's plan names a single
  "q4 phylo covariance block" label. Building it surfaced that the block's raw scale (dense,
  q>2, `UNSTRUCTURED_CORR_t`) and its bounded-correlation scale (q=2 and block-diagonal) are not
  interchangeable — one label would either overclaim a correlation semantics for a raw Cholesky
  entry or refuse the dense case outright. The delivered vocabulary split into `phylo_cor:` (a
  correlation, always in (-1, 1) once repaired — see below) and `phylo_theta:` (the raw entry, no
  transform, dense-only). Rose's pass then found and the builder repaired two further label-level
  problems inside this split: an overclaimed one-to-one entry→cell mapping in a code comment, and
  a silent-`NaN` boundary in `phylo_cor:` for `\|v\|` in (0.999999, 1) that the validation message
  did not warn about.
- **N2 Rose-repaired all 4 refutations; two are evidenced in the ledger only by a coordinator
  addendum.** Random-slope acceptance and the wrong documented `component` label are evidenced in
  leaf-n2.md G9/G11 ("now refused structurally", "now the actual `sdpars$mu` names"). The other two,
  the roxygen's silence on `summary()`'s total-variance denominator and the unsupported "-0.02 ML
  shrinkage" mechanism, were verified repaired by the coordinator by grep on the PR head 762ac950f
  (R/heritability.R roxygen lines 21-24; tests/testthat/test-heritability.R lines 6-16 and the
  after-task's recovery-design paragraph, both retracting the mechanism and citing Rose's 150-rep
  Monte Carlo) and recorded as an addendum to leaf-n2:G9. The gap was that the builder's gate text
  did not name them; the repair itself was complete.

- **Checkpoint.md lagged the ledger for N3 by one repair cycle, and was corrected.** At the time
  of the first read, `LOOP/checkpoint.md` recorded PR #1128 at `25b3c8e59` with the Rose pass
  still running, while `leaf-n3.md` already held the finished verdict (5 attacks, 2 refuted, both
  repaired) and the PR head was `6def01c6d`. The conductor rewrote the entry in lane commit
  `06d40af53` (all five arcs re-verified, heads listed, merge order) before this file was
  finalised. The pattern is the one checkpoint.md flags for N1 and N2: a Rose repair moves the
  head after the entry was written.

- **N2's first CI run failed on a source-tree read, fixed the same hour.** The roxygen-drift test
  added in the Rose repair read `R/heritability.R` with `readLines`; under `R CMD check` the tests
  run from the built tarball, where `R/` does not exist. The test is now tarball-safe (reads the
  source when present, otherwise the installed Rd's examples; fallback verified against `man/`).
  Lesson for the record: a test that reads the package source tree passes under
  `devtools::test()` and fails under check; the CI-like local run does not catch it either.

## What this lane did NOT cover

- No promotion of any capability row (`r_bridge_status`/`julia-capabilities.tsv` unchanged by
  every leaf's own gate — N1-G nothing touches it, N5-G3/N5b-G4 check it explicitly).
- No coverage claim (N2's delta-SE gate requires the roxygen to say "not a coverage claim";
  N5/N5b receipts are pipeline/pilot proofs only).
- No CRAN action, release, or registration (D-164 untouched).
- No DRM.jl edit (N3 in `.unlazy/night/GATES.md` checks the DRM.jl working tree fence; not
  observed to have been re-run and recorded as MET in this read).
- Sigma-side phylo terms and random-slope phylo blocks remain measured-broken under DRM.jl's echo
  (design 258 §7.7, per the N1 Rose repair's own scope statement).
- Bootstrap same-seed resampling design for cross-engine parity: N5b's bootstrap deltas up to 0.18
  at R=20 are attributed to independent RNG streams between engines, not investigated further;
  same-seed resampling or a larger R is named as the open P2 design point, not built.
- `summary()`'s derived "repeatability" row's total-variance denominator vs. the new `icc()`'s
  focal-vs-residual denominator: the naming collision is disclosed in the design doc and
  after-task, escalated to the owner, and left unresolved on both sides.
- #1127 (16 live Julia test sites across 9 files convert engine errors into skips, gated on two
  different env vars) — filed, not fixed. Two existing lanes are already named for this problem
  class and have not reached the phylo files (Rose n1 verdict).
- #1129 (`imputed()`: Gaussian `mi()` conditional modes off by 1e-4–1e-3, inner Newton not tight at
  the final theta) — filed from outside this lane, not addressed here.
- #1130 (nlminb default tolerance leaves location-scale fits ~1e-5 short of the optimum; S10
  varying-scale parity cell, the mirror image of #575) — filed from the DRM.jl lane during this
  reconcile, not addressed here.

## Merge log

- #1122 claude/night-n5-prerun @ 4197bb1ed — CI: ubuntu release + os-matrix success — merged 2026-09-03T01:01:10Z as 5aa488259
- #1124 claude/n1-label-contract-all-routes @ fc4690ea0 — CI: ubuntu release + os-matrix success on fc4690ea0 — then conflicted with main on the tip-identity receipt after #1128 landed; main merged in (da34e72bf) and the receipt regenerated last (4aa0c4600, checker PASS, no force-push) — CI on 4aa0c4600: ubuntu release + os-matrix success — merged 2026-09-03T02:23:10Z as d3d205486; S3-G4 in .unlazy/true-parity/gates/leaf-s3.md flipped ABANDONED to MET (oracle NO_GUESSING_OK, red control fails as designed)
- #1125 claude/night-n2-accessors @ 762ac950f — CI: ubuntu release FAILED (run 33699592016: test-heritability.R:195 read R/heritability.R, absent in the check tarball) — fixed on the branch at 21a6ae022 (fallback to the installed Rd examples; verified against man/ locally) — CI on 21a6ae022: ubuntu release + os-matrix success — merged 2026-09-03T02:06:17Z as 9bc9db99f (closes #1115)
- #1126 claude/night-n4-board-indefinite @ 804b10e15 — CI: ubuntu release + os-matrix success — merged 2026-09-03T00:58:16Z as ef796e7f9
- #1128 claude/night-n3-labels @ 6def01c6d — CI: ubuntu release + os-matrix success — merged 2026-09-03T01:44:59Z as fa1ebf95b

(All five landed, in the merge order checkpoint.md records: #1122 first — docs+tools only — then #1126 and #1125, both touching
`capability-status.md`, rebase whichever is second, then #1128 and the repaired #1124, both
touching `R/` and the tip-identity receipt, with the receipt regenerated on `main` after the
second of those two lands.)

## Morning questions for Shinichi

1. `summary()`'s derived "repeatability" row uses the total-variance denominator; the new `icc()`
   uses focal-vs-residual. Same word, different numbers, same fit, same term (checkpoint.md;
   Rose n2 Attack 5). Rename one, cross-reference both, or leave as documented divergence?
2. (Resolved before close, kept for the record.) N2's two prose refutations, the roxygen's silence
   on the `summary()` collision and the "-0.02 ML shrinkage" mechanism, were repaired on head
   762ac950f and verified by grep; evidence in the leaf-n2:G9 addendum. No decision needed.
3. #1127 (16 sites, 9 files, error→skip swallow on Julia live tests, two env vars) — filed, not
   fixed. Two lanes already exist for this problem class; should one absorb #1127 next, or is it
   its own arc?
4. #1123 (bootstrap CIs error on `cbind()` binomial responses) — filed, not fixed. Priority?
5. #1129 (`imputed()` conditional modes off by 1e-4–1e-3) — filed from outside this lane. Priority
   and owner?
6. #1130 (nlminb default tolerance leaves location-scale fits ~1e-5 short of the optimum; mirror
   of #575) — filed from the DRM.jl lane during this reconcile. Tighten nlminb's defaults
   globally, or only for sigma-with-covariates fits? Priority relative to #1123/#1127/#1129?
7. Sigma-side phylo terms and random-slope phylo blocks remain measured-broken under DRM.jl's
   echo after N1's repair (design 258 §7.7) — worth its own arc, or documented boundary for now?
8. N5b's bootstrap endpoint deltas up to 0.18 at R=20 are attributed to independent RNG streams
   between engines. Is same-seed resampling or a larger R the right P2 design point for a future
   pilot, and is 0.18 itself worth a closer look before assuming it is only RNG noise?
9. Fog item carried from `LOOP/ultra-plan.md` (still unresolved): is "true parity" one-directional
    (R workflows → Julia) or two-directional? N2 ported three DRM.jl-only accessors under the
    "both-ways rule D-204" cited in leaf-n2.md's OWNS line — confirm this is the intended standing
    interpretation, not a one-off exception.
10. **q4 Wald SEs across engines: an owner decision, not a bug (DRM.jl lane, 02:45 UTC).** DRM.jl #611
    (merged 88493250) established that the all-NaN bridge `vcov()` recorded in the q4 SE-axis receipt is
    the bridge's deliberate default `q4_vcov = false` for bivariate q4 phylogenetic fits
    (`src/bridge.jl:458-464`); native REML and the bridge with `options[["q4_vcov"]] = TRUE` both return
    a finite positive-definite `vcov` agreeing with an independent Hessian to below 1e-5. The seven Wald
    SEs in the `biv-q4-phylo-reml` `[se]` block stay `not_comparable` while the default stands. Three
    ways to make the block comparable, any one of which suffices: flip the bridge default in DRM.jl; add
    a size heuristic there; or have drmTMB pass `q4_vcov = TRUE` when it wants Wald SEs (the R-side
    option, which this lane could take without touching DRM.jl). Which?

## Follow-on arcs N7 and N8 (added after the 03:35 UTC close, inside the mission and envelope)

Both are drmTMB-side bugs found during the night's own work; owner-decision items (#1129, #1130, promotion, `q4_vcov`) stayed in the morning queue. Each landed as a green PR with a ledger written before dispatch and a Rose pass before merge.

- **N8, #1123, PR #1132 merged 208e0c903 (04:43 UTC).** Parametric bootstrap CIs aborted for every binomial fit written as `cbind(successes, failures)` because `response_name_from_model_frame()` returned `model.frame()`'s label `"cbind(s, f)"`, never a data column. `bootstrap_response_data()` now rebuilds both columns from the simulated successes and `trials - successes`, gated on the cbind encoding; Bernoulli and weights paths unchanged. RED test reproduced the exact error on main; a per-row trial-size invariant is tested; Rose's five attacks (other encodings, row alignment, edge rows, alternative spellings, regression) all survived. Ledger leaf-n8 all met.
- **N7, #1127, PR #1133 merged 20b107bf3 (06:50 UTC), after one red CI run.** The first run failed because CI sets `NOT_CRAN=true` and the shared gate never checked for a DRM.jl checkout, so with the swallows gone a Julia fit ran on the runner; the swallows had hidden that on every CI run to date. The one helper now skips with "DRM.jl engine not available (set DRM_JL_PATH)" when the path does not exist, while an existing non-DRM.jl path still fails loudly. All 22 tryCatch-to-skip sites in the live Julia tests removed (a paren-aware oracle counted 21 plus, after Rose, one spelled as a NULL handler followed by `skip_if(is.null(...))`; the issue said 16). One helper resolves the DRM.jl path (`DRM_JL_PATH`, `DRM_JL_PHYLO_PATH` only as a fallback inside it). No assertion removed (Rose's census: identical `expect_` counts across 11 files); a fake DRM.jl directory now yields a test error, not a skip. Removing the swallows exposed four constructs measured broken at DRM.jl 77513aa0, each now a visible skip naming the cause: `resd_sigma` (sigma-side phylo, two sites), `phylocov` at `test-julia-tmb-parity.R:348`, and `resd` for a random-slope phylo block (`test-julia-slope-nongaussian.R`). The first and last are the holes design 258 S7.7 already lists; the `phylocov` site is new and narrower.

**Added morning question 11.** The `coef_labels` producer has three remaining label gaps under DRM.jl's echo: `resd_sigma` (sigma-side phylo), `resd` for random-slope phylo blocks, and `phylocov` for the construct at `test-julia-tmb-parity.R:348`. Extend the producer (one arc, same pattern as N1's repair) or keep them as documented boundaries?

**Oracle lesson of record.** A ledger gate whose file list comes from `git diff --name-only origin/main` breaks as soon as main moves (N8 landed a test file N7 does not have); use `--diff-filter=AM`. And a text oracle for "no swallow" needs the NULL-handler shape as well as the inline `skip()` shape; the widened script is `.unlazy/night/bin/count-skip-swallow.py`.

**Runner receipt for the follow-on arcs (2026-09-03T07:10:59Z).** `.unlazy/night/bin/reverify-all.sh` (now passing `--timeout 1500` for the live gate): leaf-n7 ALL MET (7 met, reran 4), leaf-n8 ALL MET (6 met, reran 4), each in its own worktree; the six earlier leaves were not re-run (their worktrees were removed after the 02:43Z receipt) and the receipt says so per line. Pipeline `.unlazy/night/GATES.md` re-read: ALL MET. Diff-based gates on merged branches are pinned to the fork point d3d205486, with a dated note in each leaf.

## Follow-on arc N9 and two more morning questions (08:25 UTC)

**N9, PR #1135 (MERGED: PENDING at the time of writing).** The three coefficient-label gaps N7 exposed are closed on the R side, plus a fourth found on the way: for the coupled mu-and-sigma phylo block on one group DRM.jl reports `recov` under ML and `resd_mu`/`resd_sigma` under REML, so the producer now takes the fit's method (Rose confirmed every caller passes it and that the ML block's labels match DRM.jl's `L11, L22, L21` order by position). The four visible skips from N7 are gone and those tests run live. Design 258 gains S7.8.

**Morning question 12.** A plain, non-phylo random intercept on sigma, `sigma ~ (1 | g)`, aborts under `engine = "julia"` with `coef_labels is missing an entry for dpar "resd"` (Julia names `["resd_g_logsigma"]`). Measured identically on main before N9 and on the N9 head, so it is a pre-existing hole in the producer, not a regression. Same fix pattern as N9; a candidate N10 if time allows, otherwise the next lane's first slice.

**Morning question 13 (for the DRM.jl lane as much as for drmTMB).** For `phylo(1 + x | g)` DRM.jl reports one SD on non-Gaussian families, while TMB fits the construct on Gaussian only with two free SDs. N9's one-column label matches what DRM.jl echoes, but no same-model cross-engine check exists for that construct on any family both engines support. Is DRM.jl collapsing the slope block near a variance boundary, or fitting a different model? Handed to the DRM.jl lane.

**Question 13 answered by the DRM.jl lane (08:40 UTC; DRM.jl issue #620).** Neither by design nor a boundary collapse: DRM.jl's `_split_ranef` (`src/gaussian_ranef.jl:19`) keeps only the grouping symbol of a `phylo(...)` marker, so `phylo(1 + x | group)` parses as `phylo(1 | group)` on every univariate family, the slope is silently discarded, and theta, log-likelihood and coefficient names are byte-identical between the two spellings. N9's one-column label therefore matched an intercept-only model wearing a slope formula. DRM.jl is adding a fail-closed refusal of `phylo(<not 1> | group)` on the univariate routes tonight (PR to follow), with the Gaussian two-SD phylo random slope as a morning follow-up on their side. Consequences here: (1) once the pinned DRM.jl clone moves past that refusal, the Gamma phylo random-slope live test in `test-julia-slope-nongaussian.R` must expect an engine refusal (a visible, reasoned outcome) instead of a finite fit, and N7's no-swallow rule is what makes that visible; (2) design 258 S7.8's random-slope entry is caveated to say the label covers what DRM.jl echoes at 77513aa0, not a two-SD model. Morning question 13 is closed as a DRM.jl-side defect with a drmTMB test consequence. DRM.jl PR #621 (ec3d3f9d) is that refusal; after the re-pin, the Gamma random-slope live test should expect the message beginning "drm: `phylo(1 + x | <group>)` is not implemented on the univariate routes".

## Follow-on arcs N9 and N10 closed (08:50 UTC onward)

- **N9, PR #1135 merged c37bf8386 (08:48 UTC).** Coefficient labels for sigma-side phylo, random-slope phylo, q2 bivariate phylocov, and the estimator-dependent coupled block; the four N7 visible skips gone. Ledger leaf-n9 7/7.
- **N10, PR #1136 merged aa779e869 (09:42 UTC), after a docs qualification from the Rose pass (ML only under the Julia route; two-group refusal stated; no pre-check, question 14).** Plain non-phylo random intercept on sigma labelled (`resd` = `g_logsigma`), and the sdpars attribution defect the builder found fixed in the same PR (the SD now lands under `sdpars$sigma`, live-tested against the TMB engine's placement). Two-group mu-and-sigma random-intercept cases are refused by DRM.jl itself before any label check and are documented as its limitation. Ledger leaf-n10 7/7.
- Morning question 12 is therefore closed by N10; question 13 is closed by DRM.jl #620 / PR #621 with the re-pin consequence recorded above.

**What the label contract still does NOT cover after tonight** (design 258 S7.7/S7.8): two-group random intercepts spanning mu and sigma under `engine = "julia"` (DRM.jl refuses them), the two-SD phylo random slope (DRM.jl fits intercept-only at 77513aa0 and will refuse the slope form after #621), and any construct DRM.jl has no route for. Everything the pinned echo demands for the constructs the live suite exercises is now labelled, and with N7 in place a new gap shows up as a test error rather than a skip.

**Morning question 14 (from Rose's N10 pass).** Two DRM.jl route limitations now surface only after Julia boots, as DRM.jl's own `ArgumentError` forwarded through callr: REML with a sigma-side random intercept (ML only on the Julia route; TMB fits REML), and a random intercept on sigma alongside one on mu (refused as "must be the only random structure"). Should drmTMB pre-check these in `drm_julia_translate_control()` or the payload builder and refuse with its own message before starting the engine, the way it already refuses `sigma` on dispersionless families (N1)? Also from that pass: the N10 same-model fixture has its sigma-side SD near a boundary; a sturdier fixture is a small follow-up.

**Runner receipt for N9 and N10 (2026-09-03T09:52:12Z).** leaf-n9 ALL MET (7 met, reran 6) and leaf-n10 ALL MET (7 met, reran 6), each in its own worktree with the live gates at the pinned clone; earlier leaves not re-run (worktrees removed after their receipts) and the receipt says so per line. Pipeline `.unlazy/night/GATES.md` re-read: ALL MET. Main CI of record after the last code merge (aa779e869) is recorded in GATES.md once its run completes.
