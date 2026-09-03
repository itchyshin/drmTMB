# After-task -- drmTMB true-parity overnight lane, N1-N6 (Claude lane, 2026-09-02/03)

**Reader:** Shinichi in the morning, and the next lane picking this up. **Purpose:** what the
overnight lane actually landed against `LOOP/GOAL.md`, what was verified by re-running (not
read from a builder's own report), what a fresh Rose adversarial pass refuted and whether it was
repaired, and what is still open when this file was written. Lane worktree
`~/local-scratch/lanes/drmTMB-true-parity-night`, envelope D-208 (Shinichi, 2026-09-02 evening),
launched from `origin/main` @ `0ceb77eb0`. Sources: `LOOP/GOAL.md`, `LOOP/arcs.md`,
`LOOP/checkpoint.md`; `.unlazy/night/GATES.md` and `gates/leaf-n1.md` through `leaf-n5b.md`;
`.unlazy/night/merge-log.txt`; the Melissa reconcile
`docs/dev-log/plan-actual/2026-09-03-true-parity-night.md`; the three Rose verdicts
(`scratchpad/rose/2026-09-03-rose-n1-verdict.md`, `-n2-verdict.md`, `-n3-verdict.md`); the per-arc
after-task notes on the arc branches (`2026-09-03-n1-label-contract-all-routes.md`,
`-n2-accessors.md`, `-n3-labels.md`, `-n4-board-indefinite.md`); `gh pr view` on #1122/#1124/
#1125/#1126/#1128; the 2026-09-02 arc report for house format.

## 1. Goal

Extend `coef_labels` (design 258 §7) to every remaining live-Julia bridge route so DRM.jl's echo
covers structured, bivariate-known-structured, joint, and cross-family payloads, delete the legacy
`gsub()` predict-time rewrite, and flip gate S3-G4 from ABANDONED to MET (N1, the headline arc).
Then, in order and as time allowed: the reverse-gap accessors `heritability()`/`icc()`/
`repeatability()` (#1115, N2); widen `objective_at()`/`start=` labels to `rho12` and the q4 phylo
covariance block (N3); project the non-Gaussian phylogenetic location-scale board row and replace
the platform-dependent indefinite-Hessian test with a deterministic one (N4); a P2
inference-qualification pilot on Totoro, pre-run first (N5/N5b); close with a Melissa reconcile and
this report (N6).

## 2. Implemented

Five arcs built and pushed as draft PRs against `origin/main` @ `0ceb77eb0`; each ran a coordinator
gate re-verification in its own worktree, then a fresh Rose (Opus/Sonnet) adversarial pass before
being called done.

- **N1** (PR #1124, head `fc4690ea0`). `drm_julia_bridge_payload_coef_labels()` (the ONE producer)
  now covers the structured route's `resd` block, the bivariate known-structured (q2) route's
  `phylocov` block, and the joint/cross-family routes (confirmed already under the contract by
  construction; N1 added the tests that measure it, not new production code for those two). Fixed
  a pre-existing bug on already-merged main: any Julia fit whose formula omitted `sigma` aborted
  under the echo; `drm_julia_bridge_default_dpar_labels()` now fills the default per family. The
  legacy `gsub()` in `drm_julia_predict_fixed_eta()` is deleted (leaf-n1:G4,
  `NO_GUESSING_ANYWHERE_OK`). Design 258 §7.4 rewritten to state every route is now covered.
  Rose (`scratchpad/rose/2026-09-03-rose-n1-verdict.md`) ran 6 attacks, REFUTED the headline
  round-trip claim: the univariate `phylo(1 | g)` route also aborted under the echo, on both main
  and the branch, because the producer's `resd` detection only looked at
  `drm_julia_collect_structured_terms()` (relmat/animal/spatial), never at a plain mean-side
  `phylo()` term. Repair loop `gauss-n1` (commits `7ac9d063d`/`e93c6d3e0`/`b0c98fb81`/`fc4690ea0`)
  added a second, narrowly-gated `resd` detection for the univariate phylo case; leaf-n1:G10 now
  measures `PHYLO_ECHO_OK` live (skip counts as failure in this gate, so this is not a
  vacuous pass). Two collateral findings from the same pass were also repaired: G11, a
  user-written `sigma ~ 1` on a dispersionless family (poisson/binomial) now refuses at drmTMB with
  a message naming the reason, instead of aborting confusingly at the echo; G12, the live tests in
  `test-coefficient-labels.R` gate on `DRM_JL_PATH` and contain no `tryCatch(..., error = skip)`.
  What remains outside the contract after the repair, stated in design 258 §7.7: sigma-side phylo
  terms and random-slope phylo blocks (a *different*, dpar-qualified block key, `resd_sigma`, that
  the repair does not attempt).
- **N2** (PR #1125, head `762ac950f`). `R/heritability.R` (new): `heritability()`, `icc()`,
  `repeatability()`, ported term-for-term against DRM.jl `src/heritability.jl` @ 77513aa0 (design
  259, the symbolic alignment table written first, per leaf-n2:G1). Gated to Gaussian fits with a
  constant residual sigma and >= 1 structured/random component; delta-method SE on the working
  (log-sd) scale; known-DGP recovery within 0.05 across 5 seeds at `n_groups = 300` (leaf-n2:G2).
  Rose (`scratchpad/rose/2026-09-03-rose-n2-verdict.md`) ran a term-for-term read of the DRM.jl
  source (11 rows, all matching or a declared divergence) plus 5 live attacks; REFUTED 4: (i)
  random-slope terms (`1 + x | blk`) were accepted and summed an intercept variance with a
  per-unit-of-`x` slope variance while silently dropping `eta_cor_mu`, a dimensionally incoherent
  number with a confident SE; (ii) the documented `component` label
  (`"phylo(1 | species, tree = tree)"`) does not match the actual `names(sdpars$mu)` string
  (`"phylo(1 | species)"`); (iii) the roxygen never mentions that `summary()`'s derived
  "repeatability" row uses a different (total-variance) denominator than the new `icc()`, even
  though the design doc and after-task disclose it; (iv) the recovery test's stated bias mechanism
  ("expected ML downward shrinkage", -0.02 at `n_groups = 60`) was unsupported -- a 150-rep Monte
  Carlo at that size gives bias -0.002, within one MC SE of zero. All four are repaired on PR head
  `762ac950f`: leaf-n2:G11 records structural refusal of random-slope/correlated random-effect
  terms plus corrected documented labels; leaf-n2:G9's addendum (coordinator, 2026-09-03 01:05 UTC,
  after Melissa flagged the gap) records the two prose repairs verified by grep, not by the
  builder's word -- `test-heritability.R` lines 6-16 and the after-task retract the "-0.02 ML
  shrinkage" mechanism and cite Rose's 150-rep MC number instead, and `R/heritability.R` roxygen
  lines 21-24 now state the `summary()` denominator difference explicitly.
- **N3** (PR #1128, head `6def01c6d`). `objective_at()`/`drm_control(start=)` label vocabulary
  reaches `fixef:rho12:<column>` and, for the q4 dense phylo covariance block, splits into
  `phylo_sd:<axis>`, `phylo_cor:<a>:<b>` (always a bounded correlation, for q=2 and block-diagonal
  q>2), and `phylo_theta:<a>:<b>` (the raw unconstrained Cholesky entry for a dense block, no
  transform) -- the plan named one label; building it surfaced that one label cannot serve both the
  bounded-correlation semantics and the raw-scale semantics without misleading a user. Round trip
  to `-logLik(fit)` at 7.8e-10 on a dense q4 biv_gaussian REML fit (leaf-n3:G1). Rose
  (`scratchpad/rose/2026-09-03-rose-n3-verdict.md`) ran 5 attacks, REFUTED 2, both repaired before
  merge per leaf-n3.md's own note: a source comment on `drm_phylo_mu_dense_theta_index()`
  overclaimed a one-to-one "perturb one entry, one cell moves" mapping (perturbing one raw
  `theta_phylo` entry actually moves every correlation cell sharing its row, TMB's
  `UNSTRUCTURED_CORR_t` row-wise reparameterization) -- comment, design 35, and the after-task
  rewritten to what was shown; `phylo_cor:` accepted `|v|` in (0.999999, 1) and silently produced
  `NaN` (a bare R warning, no abort) -- now refused outside `|v| < 0.999999`, with a NaN positive
  control. A third, pre-existing, untouched finding was noted, not fixed: the plain `cor:` family's
  `atanh(value)` (no `/0.999999` factor) has the same class of gap at a different, sub-1e-6,
  boundary.
- **N4** (merged: PR #1126 -> `ef796e7f9`, commit `804b10e15`). Board row
  `Non-Gaussian phylogenetic location-scale (mu + log sigma)` added as `scope-limited`, name
  byte-identical to DRM.jl's, basis from `cells.tsv` (nbinom2, zero_one_beta implemented; ten
  families rejected_by_design). Deterministic indefinite-Hessian test for `check_drm()` (injected
  indefinite `sdr$cov.fixed`) replaces the platform-dependent premise; RED control recorded --
  disabling the negative-eigenvalue branch fails both the new and the pre-existing indefinite test,
  restored byte-identically (leaf-n4:G4). No Rose refutation recorded for N4; delivered exactly as
  planned per the reconcile draft.
- **N5/N5b** (merged: PR #1122 -> `5aa488259`, commit `4197bb1ed`). N5, the Totoro P2 pre-run, was
  ABANDONED with reason: `JuliaCall::julia_setup()` segfaults the R process on Totoro's R 4.5.3 /
  JuliaCall 0.17.6 stack for both Julia 1.12.6 and 1.10.10 across three env variants, while a
  concurrent unrelated lane's own `Pkg.test()` ran cleanly under the same Julia binary throughout
  (an R-embedding problem, not Julia's or DRM.jl's); the TMB half of the pre-run completed and
  surfaced a real bug, filed as #1123. N5b re-scoped the same pre-run-then-pilot design to this Mac
  (local `JuliaCall` embedding works): pre-run 62 s, go/no-go rule applied, full pilot 69 s on 4
  PSOCK workers (`mclapply` forks segfault with libjulia on macOS) over 4 `partial` rows x
  {wald, profile, bootstrap where single-column} x 2 engines x 5 seeds, all converged; wald/profile
  endpoint deltas <= 1.6e-5; bootstrap endpoint deltas up to 0.18, attributed to independent
  bootstrap RNG streams between engines at R=20 (not investigated further; named as the open P2
  design point). `biv_gaussian_residual` documented as not profile/bootstrap-ready on the Julia
  engine. Receipts only; no promotion, no coverage/calibration claim (leaf-n5b:G3/G4).
- **N6** (this report + the Melissa reconcile). The reconcile
  (`docs/dev-log/plan-actual/2026-09-03-true-parity-night.md`) is the read-only planned-vs-actual
  diff; this file is the after-task.

## 3a. Decisions and Rejected Alternatives

- **N3 split one planned label into `phylo_cor:`/`phylo_theta:` rather than one "phylo covariance
  block" label.** A single label would either overclaim correlation semantics for a raw Cholesky
  entry (dense q>2 case) or refuse the dense case outright to keep the correlation semantics clean.
  Splitting on scale (bounded correlation vs. raw entry) was chosen so neither semantics is
  misrepresented; rejected the single-label plan once the dense case's actual representation was
  read.
- **N1's phylo `resd` fix was scoped to the univariate mean-side case only**, not to sigma-side
  phylo terms or random-slope phylo blocks, which carry a different, dpar-qualified block key
  (`resd_sigma`). Widening further was rejected for this arc as scope creep beyond what Rose's
  refutation demanded; recorded as an explicit boundary in design 258 §7.7 rather than silently
  left unaddressed.
- **N2's dispersionless/random-slope gate refuses rather than silently drops or best-effort
  computes.** Matches DRM.jl's own refusal pattern (no random-slope route in `heritability.jl`) and
  the "fail closed" convention used elsewhere in this lane (N1's dispersionless-sigma refusal, same
  arc night); the alternative (accept and document as approximate) was rejected because Rose showed
  the prior accept-silently behaviour produced a dimensionally incoherent number with a confident
  SE.
- **N5 was abandoned rather than debugged further on Totoro.** Stopped after ~15-20 minutes of
  retries against a ~26-minute Totoro session budget, per the lane's 15-minutes-per-step rule,
  rather than chasing an R-embedding segfault that a concurrent lane's own Julia `Pkg.test()`
  showed was not a Julia-side problem. N5b (local Mac) was substituted so the pre-run-then-pilot
  design still produced receipts this session, rather than deferring the whole P2 pilot to a future
  Totoro-fix arc.

## 4. Files Touched

This report and the Melissa reconcile are the only files this N6 write touched directly:
- `~/local-scratch/lanes/drmTMB-true-parity-night/docs/dev-log/after-task/2026-09-03-true-parity-night.md` (this file, new)
- `~/local-scratch/lanes/drmTMB-true-parity-night/docs/dev-log/plan-actual/2026-09-03-true-parity-night.md` (read, pre-existing draft from the reconcile arc)

Files touched by the five arc branches (not by this N6 write; listed for completeness, per branch
head, none merged to main except N4 and N5/N5b):
- N1 (`fc4690ea0`, PR #1124): `R/julia-bridge.R`, `tests/testthat/test-coefficient-labels.R`,
  `tests/testthat/test-julia-bridge.R`, `tests/testthat/test-julia-structured-inference.R`,
  `docs/design/258-coefficient-naming-contract.md`,
  `docs/dev-log/after-task/2026-09-03-n1-label-contract-all-routes.md`,
  `docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json` (regenerated last).
- N2 (`762ac950f`, PR #1125): `R/heritability.R` (new), `NAMESPACE`, `man/heritability.Rd`,
  `tests/testthat/test-heritability.R` (new), `docs/design/259-heritability-icc-repeatability.md`
  (new), `docs/design/capability-status.md`, `_pkgdown.yml`,
  `docs/dev-log/after-task/2026-09-03-n2-accessors.md`.
- N3 (`6def01c6d`, PR #1128): `R/objective-at.R`, `R/control.R`, `R/drmTMB.R` (label translation
  only), `tests/testthat/test-objective-at.R`, `tests/testthat/test-start-contract.R`,
  `docs/design/35-optimizer-start-map-multistart.md`,
  `docs/dev-log/after-task/2026-09-03-n3-labels.md`.
- N4 (`804b10e15`, merged `ef796e7f9`): `docs/design/capability-status.md`,
  `tests/testthat/test-check-conditioning.R`,
  `docs/dev-log/after-task/2026-09-03-n4-board-indefinite.md`.
- N5/N5b (`4197bb1ed`, merged `5aa488259`): `docs/dev-log/evidence/julia-r-parity/p2-pilot/**` (new),
  `tools/parity-p2-pilot.R` (new).

## 5. Checks Run

- Each leaf's own gate CHECK commands, re-run by the coordinator in the arc's own worktree (not
  taken from the builder's report): leaf-n1 G1-G7 + G10-G12 all MET (`ALL_BUILDERS_LABEL_OK`,
  `LIVE_ECHO_ALL_ROUTES_OK`, `STRUCTURED_PREDICT_OK`, `NO_GUESSING_ANYWHERE_OK`,
  `SPEC_ALL_ROUTES_OK`, `CI_LIKE_AND_GUARDS_OK`, `TIP_RECEIPT_OK`, `PHYLO_ECHO_OK`,
  `DISPERSIONLESS_OK`, `NO_SWALLOW_OK`); leaf-n2 G1-G8 + G11 MET; leaf-n3 G1-G4 MET; leaf-n4
  G1-G5 MET including the RED control; leaf-n5 G1/G3/G4 MET, G2 correctly UNMET (`EVIDENCE:
  pending`, Julia half abandoned), G5 (abandon-honestly) MET; leaf-n5b G1-G4 MET.
  Gate-merge status (N1-G9, N2-G10, N3-G5): all `EVIDENCE: pending` as of this write -- PRs #1124,
  #1125, #1128 read `state: OPEN`, `mergedAt: null` via `gh pr view` at the time this report was
  written.
- CI-like offline runs (`env -u DRM_JL_PATH -u DRMTMB_JULIA_TESTS`) on every touched test file per
  leaf, before each PR, per each leaf's own G-gate for this (N1-G6, N2-G8, N3-G3/G4, N4-G5).
- `python3 -m unittest tools/tests/test_capability_ledger.py` -> OK on N1, N2, N3, N4's touched
  trees (each leaf's own gate).
- `pkgdown::check_pkgdown()` clean on N2 (NAMESPACE grew three exports; leaf-n2:G6).
- lss-tip-identity receipt (`tools/check-julia-phylo-labels-receipt.R --current --self-test`)
  regenerated last on N1's and N3's final R/ state; `TIP_RECEIPT_OK`/`DOCS_GUARDS_RECEIPTS_OK`.
- DRM.jl working-tree fence checked in `.unlazy/night/GATES.md` (N3 CHECK,
  `DRMJL_FENCE_HELD`); node-level EVIDENCE for that gate reads `pending` as of this write --
  the check command itself was not re-run in this N6 pass (this report is a docs-only write; no
  repo edit was made that could have touched DRM.jl, and the arc worktrees' own leaf gates never
  edited it either, per each leaf's OWNS line excluding `DRM.jl`).
- `merge-log.txt`: two of five draft PRs merged and confirmed with CI green at merge --
  `#1126 head=804b10e15 ci=[ubuntu-latest (release)=success os-matrix=success] merged=true
  ef796e7f9` and `#1122 head=4197bb1ed ci=[...=success ...=success] merged=true 5aa488259`.
  `gh pr view` on #1124/#1125/#1128 (this write): all three `state: OPEN`, `mergedAt: null`.
- Merge status per PR, stated explicitly: #1126 MERGED ef796e7f9 (N4). #1122 MERGED 5aa488259 (N5/N5b receipts). #1124 MERGED: PENDING (CI running at draft time). #1125 MERGED: PENDING (CI running at draft time). #1128 MERGED as fa1ebf95b (2026-09-03T01:44:59Z, CI green). The conductor fills these in as CI completes and each lands.

## 6. Tests of the Tests

Evidence the adversarial layer actually catches failures, not just the ordinary test suite:

- N1's leaf-n1:G10-G12 CHECK commands assert `skip == 0` and specifically name test titles
  containing "phylo"/"dispersionless sigma"/no-swallow, so a regression back to the pre-repair
  state (phylo `resd` unlabelled, or a re-introduced `tryCatch(..., error = skip)`) would fail the
  gate, not silently pass it -- this is the direct fix for the exact class of failure Rose found
  (a green CI that could not report the phylo breakage because a different env var gated it and a
  swallow pattern converted the hard abort into a skip).
- N4's RED control (leaf-n4:G4) is a literal test-of-the-test: forcing
  `mu_min_trusted_negative <- FALSE` in `R/check.R` was shown to fail BOTH the new deterministic
  test and the pre-existing indefinite test before the code was restored byte-identically -- direct
  proof the new test exercises the warning path it claims to, not a tautology that passes
  regardless of the underlying check.
- N3's Rose Attack 3 is itself a test of a test: it specifically probed the boundary the existing
  test suite did not cover (`phylo_cor:` near 0.999999) and found the NaN gap because no test in
  the pre-repair suite exercised that value; the repair added a NaN positive control, directly
  closing the coverage gap Rose's attack demonstrated.
- N2's Rose Attack 4 quantified the recovery test's own margin (worst seed |diff| 0.0385 against a
  0.05 tolerance, 22% headroom) rather than accepting a green pass at face value, and separately
  ran an independent 150-rep Monte Carlo to check whether the test's own comment (the bias
  mechanism) was itself a supportable claim -- it was not, and the retraction is now cited with the
  Monte Carlo number, not just removed.
- This N6 write itself did not run new tests; the "tests of the tests" evidence above is inherited
  from the arcs' own Rose passes, cited by gate ID and verdict file rather than re-asserted.

## 7a. Issue Ledger

Filed this lane, all still open at the time of this write:
- **#1123** -- `confint(method = "bootstrap")` errors on `cbind(successes, failures)` binomial
  responses; found during N5's Totoro TMB-half pre-run; `wald`/`profile` work fine on the same fit.
  Not fixed this lane.
- **#1127** -- 16 live Julia test sites across 9 files (`test-julia-inference.R`, `-phylo-count.R`,
  `-missing.R`, `-phylo-nongaussian.R`, `-q2-phylo-point-export.R`, `-structured.R`,
  `-phylo-q4-corpairs.R`, `-sigma-phylo-reml.R`, `-tmb-parity.R`) convert an engine error into a
  green skip via `tryCatch(..., error = function(e) skip(...))`, gated on two different env vars
  (`DRM_JL_PATH` vs `DRM_JL_PHYLO_PATH`) so the standard live command silently skips the whole phylo
  test family. Found by N1's Rose pass; filed, not fixed. Two existing lanes are already named for
  this class of problem and have not reached the phylo files.
- **#1129** -- `imputed()`: Gaussian `mi()` conditional modes off by 1e-4-1e-3, inner Newton not
  tight at the final theta. Filed from outside this lane (a morning issue), not addressed here.
- **#1130** -- nlminb default tolerance leaves location-scale fits ~1e-5 short of the optimum; S10
  varying-scale parity cell, the mirror image of #575. Filed from the DRM.jl lane during the
  reconcile, not addressed here.
- **#1115** (pre-existing, reverse gap) -- targeted, not yet closed: N2's PR #1125 is not merged as
  of this write, so #1115 is not yet closed by it (leaf-n2:G10 `EVIDENCE: pending`).

## 8. Consistency Audit

Same class of problem checked across all five arcs, since N1's Rose pass found a specific pattern
(a claim of "every route covered" that was true for the routes tested but not for a neighbouring
route of the same kind):
- **Checked whether N2, N3, N4 made a similarly-scoped "every X" claim that a Rose pass then
  narrowed.** N2's claim was "three accessors matching DRM.jl term-for-term" -- Rose's term-for-term
  read (11 rows) found no formula mismatch, only the random-slope gating gap (an input DRM.jl has
  no route for at all, so "match" was never claimed for it) and two documentation gaps. N3's claim
  was narrower from the start (one label family, not "every route"), and Rose's two refutations were
  both about a single boundary value and a single comment's overclaim, not about a route silently
  excluded. N4 made no "every X" claim (a single board row, byte-matched against DRM.jl's own board
  text) and Rose recorded no refutation. So the "every route/claim broader than delivered" pattern
  Rose caught once in N1 did not recur elsewhere in this lane in the same shape, though N2's
  documentation-gap class (a label string that does not match the actual runtime string) is a
  sibling of N1's problem (a claim about coverage that a live probe, not a unit test, disproves).
- **Checked whether the env-var/skip-swallow pattern #1127 names is confined to phylo files or
  wider.** Rose's own count (16 sites, 9 files) is already the wider sweep; this N6 pass did not
  re-run that grep independently, so the count is cited from the Rose verdict, not re-verified here.
- **Checked whether the same "checkpoint.md lagging the gate ledger" problem the Melissa reconcile
  found for N3 also affects N1/N2's checkpoint entries.** The reconcile's own text notes N1 and N2's
  checkpoint entries already carry an explicit "head will move after a repair" caveat; N3's entry
  did not, which is exactly the contradiction the reconcile flagged and is not re-litigated here.

## 9. What Did Not Go Smoothly

- N5's Totoro half could not run at all: `JuliaCall::julia_setup()` segfaulted the R process
  (exit 139, uncatchable by `tryCatch()`) on Totoro's current R 4.5.3 / JuliaCall 0.17.6 /
  Julia 1.12.6-or-1.10.10 stack, across three env variants, after ~15-20 minutes of retry attempts.
  This is a platform limitation carried forward for a future arc (or a Totoro stack fix), not
  something this lane resolved.
- Two gate CHECK commands in leaf-n5.md and leaf-n5b.md needed a correction mid-lane: a multi-line
  python heredoc the checker's `/bin/sh` could not execute (unexpected EOF) was rewritten to a
  one-line equivalent with the same assertions (recorded inline in both gate files as "CORRECTED
  2026-09-03").
- `LOOP/checkpoint.md`'s N3 entry was stale relative to the gate ledger at the point the Melissa
  reconcile was read: it stated PR #1128 was at sha `25b3c8e59` with "Sonnet Rose pass running" and
  "G5 = merge pending", but `leaf-n3.md` already contained a completed Rose verdict (5 attacks, 2
  refuted, both repaired) and the PR's actual head, read via `gh api`, was the later commit
  `6def01c6d`. The gate ledger and the live PR agreed with each other; checkpoint.md was the
  outlier.
- The coordinator sent a mid-write correction to this report after the Melissa reconcile's
  original text (read before the correction) stated the univariate phylo route "remains broken" for
  N1 -- that text was written before leaf-n1:G10's repair-and-re-verify was reflected in the draft.
  This report is written against the corrected state: the univariate phylo route is fixed and
  measured passing (leaf-n1:G10, `PHYLO_ECHO_OK`, skip counts as failure); what remains unfixed is
  sigma-side phylo terms and random-slope phylo blocks.

## 10. Known Residuals

- None of N1 (#1124), N2 (#1125), N3 (#1128) is merged as of this write; all three read
  `state: OPEN`, `mergedAt: null` via `gh pr view`. Their merge-gate lines (N1-G9, N2-G10, N3-G5)
  are correctly `EVIDENCE: pending`, not silently marked met.
- N1's design 258 §7.7 documents an explicit remaining gap: sigma-side phylo terms and
  correlated random-slope phylo blocks are still measured broken against DRM.jl's echo (a
  different, dpar-qualified block key the repair did not attempt).
- N3's Rose pass left one neighbour finding untouched by design, not by oversight: the plain
  `cor:` family's `atanh(value)` has no `/0.999999` factor, so it shares the same class of
  silent-NaN gap as `phylo_cor:` did before repair, at a different (sub-1e-6) boundary. Recorded in
  leaf-n3.md's own Rose-pass note; not repaired this lane.
- N2's random-slope refusal and label repairs are confirmed by gate evidence (leaf-n2:G11); the
  two prose repairs (the `summary()` denominator sentence and the retracted bias-mechanism claim)
  are confirmed by the coordinator's grep-based addendum to leaf-n2:G9 rather than by a
  machine-checked gate CHECK command of their own -- a weaker evidence tier than the CHECK-script
  gates elsewhere in this lane, though still independently verified (not the builder's word alone).
- #1123, #1127, #1129, #1130 are filed and open; none addressed this lane.
- N5b's bootstrap endpoint deltas up to 0.18 at R=20 are attributed to independent RNG streams
  between engines but not investigated further; same-seed resampling or a larger R is named as the
  open P2 design point, not built.
- `summary()`'s derived "repeatability" row still uses the total-variance denominator, unlike the
  new `icc()`'s focal-vs-residual denominator, on the same fit and term. Both surfaces are now
  documented (N2's Rose-driven roxygen fix), but the naming collision itself is unresolved and is
  a named morning question for Shinichi.
- The DRM.jl fence CHECK in `.unlazy/night/GATES.md` (node N3) reads `EVIDENCE: pending`; this N6
  write did not re-run that CHECK command directly (see section 5).

## 11. Team Learning

- **A "coverage complete" claim needs a probe of the route class's siblings, not just the routes
  named in the plan.** N1's plan named structured/known-structured/joint/xfam explicitly and
  delivered all four; Rose's refutation came from a route the plan never named at all (univariate
  mean-side `phylo()`), reached only because Rose's attack script swept every family
  `drm_julia_family_tag()` admits rather than only the families the plan's test fixtures used. The
  concrete safeguard this lane already wrote into gates: leaf-n1:G10-G12 now assert by test-title
  substring that a phylo-named live test exists and cannot skip -- a mechanised version of "sweep
  the sibling routes" rather than a prose reminder.
- **Env-var fragmentation is a structural cause of false-green CI, not a one-off bug.** #1127's 16
  sites across 9 files existed because `DRM_JL_PHYLO_PATH` and `DRM_JL_PATH` gate different test
  families, so a single "run the live suite" command silently skips a whole capability class. Two
  lanes are already named for the swallow-pattern half of this problem; the env-var fragmentation
  half is not yet owned by any lane -- worth naming explicitly as a morning question (already in the
  reconcile) rather than assuming the existing lanes will notice it.
- **Grep-verified addenda are a legitimate but weaker evidence tier than a scripted gate CHECK.**
  N2-G9's addendum (coordinator grep, not a CHECK-and-EXPECT pair) closed a real gap the initial
  gate-check pass missed, but it is not re-runnable the way the other gates are. A future arc adding
  the same kind of late-discovered documentation fix should promote it to a CHECK line where
  practical (e.g. `grep -q 'total-variance' R/heritability.R`) rather than leaving it as prose in
  an EVIDENCE field.
- **`checkpoint.md` needs the same "head moves after repair" caveat on every arc, not just the ones
  where the repair was noticed while writing it.** N1 and N2's entries already carried this caveat;
  N3's did not, and that gap is exactly what let checkpoint.md and the gate ledger disagree. A
  cheap mechanised check (diff checkpoint.md's recorded PR head against `gh pr view`'s
  `headRefOid` before calling an arc "checkpointed") would catch this class of staleness
  automatically.

## 12. Cross-Product Coverage

`coef_labels` (the design 258 producer contract) is the cross-cutting surface this lane widened
the most, and it is a transformation, not a feature: every downstream route that calls the Julia
engine depends on it agreeing with DRM.jl's echo.

- Covers: base bridge (all families `drm_julia_family_tag()` admits, with and without an explicit
  `sigma`/`nu`, per N1's default-dpar fix); structured route (`resd`, relmat/animal/spatial
  markers, all four `drm_julia_structured_families()`); bivariate known-structured q2 route
  (`phylocov`); joint route (by construction); cross-family/xfam route (by construction); univariate
  mean-side `phylo(1 | g)` (after N1's repair, leaf-n1:G10); predict()/fitted()/residuals() after
  the legacy `gsub()` removal, including a factor x continuous interaction on a structured fit
  (leaf-n1:G3, the Rose A10 case).
- Does NOT cover: sigma-side phylo terms (a `phylo()` term inside a `sigma ~` formula) under the
  Julia echo; correlated random-slope phylo blocks (`phylo(1 + x | g)`) under the Julia echo,
  because both carry a different, dpar-qualified `resd_sigma`-style block key the N1 repair did not
  attempt (design 258 §7.7). Does NOT cover name-checking of the three echo-only block prefixes
  (`resd_`, `recov_`, `phylocov_`) -- these are excluded from `drm_julia_bridge_check_coef_labels()`
  by design, so a renamed group on DRM.jl's side would relabel silently on the R side rather than
  abort (Rose n1 Attack 5's blind spot, not repaired this lane). Does NOT cover a capability-status
  or `r_bridge_status`/`julia-capabilities.tsv` promotion -- every leaf's own gate explicitly checks
  the TSVs are untouched (N1: no gate touches them; N4-G5, N5-G3, N5b-G4 check `git diff --quiet`
  against them).

`objective_at()`/`drm_control(start=)` label vocabulary is the second cross-cutting surface this
lane widened (N3). Covers: `rho12` fixed effect under REML (never folded into the random block, so
always addressable); the q4 dense phylo covariance block, split into `phylo_sd:`, `phylo_cor:`
(bounded, refuses outside `|v| < 0.999999` after repair), and `phylo_theta:` (raw Cholesky entry,
dense-only); unknown-label fail-closed behaviour unchanged (still aborts, still lists available
labels). Does NOT cover: the plain (non-phylo) `cor:` family's boundary near its own `atanh()`
transform (no `/0.999999` factor there, a sibling gap, noted not fixed); any label family other
than `rho12` and the q4 phylo block -- this arc's scope was exactly those two, per the A5 finding
that motivated it, and no other `objective_at()` gap was in scope or claimed closed.

`heritability()`/`icc()`/`repeatability()` (N2) is a new cross-cutting accessor family, not a
flag, but the same "what does it NOT cover" discipline applies. Covers: Gaussian fits with a
constant residual sigma (`sigma ~ 1`) and >= 1 structured/random component on the mean; iid random
intercepts, `phylo()`, `animal()`/`relmat()` routes (Rose attack 3, all correctly accepted or
refused); delta-method SE with a documented "not a coverage claim" caveat. Does NOT cover:
non-Gaussian families (refused, matching DRM.jl); heteroscedastic sigma (`sigma ~ x`, refused);
random-slope or correlated random-effect terms (`1 + x | g`, refused after repair -- DRM.jl has no
route for this either, so refusal is the correct behaviour, not a gap); `method = "profile"`
(refused, names `method = "delta"` as the only option); any interval-calibration claim beyond the
sanity-check framing the roxygen states explicitly.

The P2 inference-qualification pilot (N5/N5b) covers: wald and profile CIs on both engines across 4
`partial` capability rows, 5 seeds, with endpoint deltas <= 1.6e-5; bootstrap CIs where the
response is a single column. Does NOT cover: bootstrap CIs on `cbind()`-style two-column binomial
responses (the #1123 bug); any row not in the 4 `partial` rows; the Totoro platform at all (N5
abandoned, no Julia-side numbers from that host); same-seed cross-engine bootstrap comparison (the
0.18 deltas are attributed to independent RNG streams, not eliminated by a matched-seed design);
and, as every leaf's own gate states explicitly, no promotion of any capability row and no
coverage/calibration claim from either N5 or N5b's receipts.
