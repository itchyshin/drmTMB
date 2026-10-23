# Dinnage audit — second arc (M1 ×11 · M2 · S6 note · S2/D-252 · S3 doc)

🎯 GOAL
Solo platform: Claude Code (this session; Fable orchestrating). HANDS TO: none.
Deliverable: on branch `claude/audit-dinnage-wave1-20260913` (draft PR #1361), the four owed items landed as
  surgical commits — (1) M1: the eleven non-Bernoulli `mi()` quadrature sites weight the mixture, not the
  leaves, with one per-family weight-invariance test; (2) M2: `sigma()`/`predict()`/`residuals()` report the
  soft-clamped scale the likelihood used; (3) S6: a design note, no code, Fisher-reviewed; (4) S2: a
  reconciliation note answering #1301's four checks under D-252, then the scale-independent
  `drm_constant_residual_sigma()` fix if Fisher concurs — plus S3's help page telling the truth about the
  log-scale MAP. Closed with an after-task report, a Melissa plan-actual row, and a handover.
HEADLINE: M1 — the only finding that biases a point estimate through the likelihood; eleven sites still do.
IN PARALLEL: M2 (R only), the S6 note, and the S2 note + S3 doc run beside M1's test-first half.
DEFER (fenced): S3 option B (drop the Jacobian — a likelihood change needing a campaign); the S6 code
  change and its coverage campaign; all Moderates/Minors (#1316–#1360); a fit-time `weights`+`mi()`
  refusal (moot once all sites are fixed); the Gaussian latent `mi()` route (`mi_family == 0`) beyond a
  scratch probe; merge; release; any message to Russell.
DISCIPLINE: verify = unlazy ledger per slice · every new test shown red on pre-fix code · fresh-context
  Opus (Fisher) review of every diff before it counts · one local `R CMD check --as-cran` on a clean export
  before push · compute = local Mac Studio only (one TMB recompile ≈ 5 min for M1, one more inside as-cran;
  no campaigns) · closure = all leaf gates green, as-cran 0 errors, branch pushed, after-task + Melissa +
  handover written.

## Context

Russell Dinnage's independent evaluation of drmTMB 0.7.0 is filed as issues #1306–#1360 (D-263). Yesterday's
arc (PR #1361, CI green) fixed C1, Md-A/D/E/M/N, Mi-9, S1, S4, S5, M4, and the ten Bernoulli `mi()` sites of
M1. Fisher's fresh-context review (`docs/dev-log/audits/2026-09-13-dinnage-wave1-review.md`) left four owed
items and two decisions. This arc pays the four items in the order Shinichi gave and records the two
decisions under "use your judgment".

**Bars and model.** Session model is Fable (read from the runtime). Usage bars are not readable in this
non-interactive desktop session — recorded as unknown, not estimated.

**Lane pre-flight (Shannon).** `lane_preflight.sh .` verdict: FOREIGN LANE ACTIVE (codex) — 7 lanes live;
the audit lane `claude/audit-dinnage-wave1-20260913` is ours (draft PR #1361). Lane taken: that branch, in
`/Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1`. No other lane touches `src/drmTMB.cpp`
`mi()` blocks, `R/methods.R` sigma paths, `R/penalty.R`, or `R/heritability.R` per the census; the 071 lane
(PR #1304) is done and untouched. Board committed; no live leases; design-number NEXT FREE = 274 across all
refs (the lane alone shows 261 — `main`-only counts under-count; claim by committing). The main Dropbox
checkout sits on `claude/d252-repeatability-notice-20260908` with unrelated prior-session dirt (`.gitignore`
graft lines, `.ignore`, `drmjl-profile-diagnostic.R`) — left alone, not ours.

## Phase 0.25 — Prior-work sweep receipt

- **repo git state** → `git status -sb; git log --oneline -8; branch_drift_check.sh` (lane) → clean, 27
  ahead / 0 behind `origin/main`; `.unlazy/` ignored via the shared `.git/info/exclude:28` (verified with
  `git check-ignore -v`; a scout reported otherwise and was wrong) → **resume the lane**.
- **twin / sister repos** → DRM.jl `main` grepped for `repeatab|icc` (has `src/heritability.jl`) and for
  `weights` near `mi`/imputation (only GH node weights, no observation weights in the finite-mixture
  imputation) → the S2 note names the twin's status; M1 has no Julia counterpart to co-opt → **n/a for code;
  S2 note carries a twin line**. gllvmTMB #1276 (same D-252 rename) is OPEN → sibling, cited.
- **brain** (`search_notes`, `search_all_projects: true`, query "Dinnage audit M1 weights inside mi()
  mixture quadrature; M2 softclamp…; S6 percentile bootstrap bias; repeatability D-252 three-scale") →
  nothing on point beyond gllvmTMB milestone noise; deterministic greps: `AGENT_LOG.md` "dinnage" → the
  2026-09-13 arc entry (what was done); `DECISIONS.md` → **D-252** (three scales, latent ≠ liability, never
  NaN), **D-263** (audit answered as issues first; no audit fix merges on the builder's own tests);
  `OPEN_QUESTIONS.md` → nothing on point; `projects/deep-research/README.md` → dr26 (REML CIs under-cover,
  REHE bootstrap near nominal) and dr24 (plug-in SEs under-cover; bootstrap adds precision) — related
  reading for the S6 note, not answers → **reuse D-252 as the S2 contract; nothing else to reuse**.
- **Verdict** → resume the lane and build the gap: M1 ×11, M2, S6 note, S2 note (+ scale-independent fix),
  S3 doc. Reuse: the repaired Bernoulli block (`bb7b0de8b`, `src/drmTMB.cpp:1272-1313`) as the template;
  per-family fixtures in `tests/testthat/test-missing-predictor-*.R`; `drm_softclamp_log_sd()`
  (`R/drmTMB.R:23038-23060`; `drm_clamped_scale_families()` is at `R/drmTMB.R:3521`) and
  `drm_control(logsigma_clamp=, logsigma_clamp_margin=)` for a clamp-active fixture; Fisher's S3 wording
  (review §1 "Concrete change"); design 172 and 259.

## Plan review (Rose + Fisher lens, Sonnet, before execution) — PASS-WITH-CHANGES, all five applied

1. Citation for `drm_softclamp_log_sd()` corrected (above).
2. `devtools::document()` is package-wide: no builder runs it. Builders edit roxygen only; Ada runs
   `document()` once after batch 1 returns and checks `git diff --stat -- man/` against OWNS.
3. M2 has THREE sigma paths, not one: `predict.drmTMB()` (`R/methods.R:2853-2937`), the second predict
   path (`~6288/6706`), and `drm_marginal_predict()` (`R/methods.R:6691-6707`, ~15 call sites inside
   `simulate.drmTMB()`'s default `marginal = TRUE` branch — the path S6's default bootstrap draws from).
   All three are in M2's patch list; the M2 test adds a `simulate()` arm.
4. S2b must walk every source `has_sigma_random_effects()` (`R/methods.R:6182-6190`) knows, including
   phylo-on-sigma (`sd_phylo_group_values()`); phylo-on-sigma returns `NA` with a message in this arc,
   never the old silently wrong `exp(b0)`.
5. F-A's checklist asks explicitly: "does M2 cover `simulate()`'s marginal path?" and "does S2b cover
   phylo-on-sigma?".
(The reviewer ran one `git fetch origin` in the lane while checking design numbers across refs — remote-
tracking refs only, no tracked file touched; recorded here for honesty. Highest design number across all
refs after fetch is 273, so 274/275 stand.)

## Phase 0.6 — Route check

Destination is one sentence (the GOAL). Every slice names a file path. One slice (S2b) is decision-dependent
and is gated explicitly on Fisher's review of the S2 note rather than left as fog. **Route is knowable; no
decision map needed.**

## WHAT THE BRAIN ALREADY KNOWS

- D-252: any repeatability/ICC on a non-Gaussian scale must name its scale; Eq 4 latent is defined for
  every family; never return NaN for a defined quantity; twins land the same vocabulary.
- Fisher (2026-09-13): M1's eleven sites also leave the imputation prior unweighted and subtract the
  combined `log_denom` with no outer weight; the invariance test must assert at a converged optimum.
- Fisher on S3: the prior is the documented exponential PC prior; the defect is that a MAP in `log(sd)` is
  never zero and sits at `1/rate` under a flat likelihood; option A (document) is reversible and lands today.
- M4: #1188 already made "keep the mask" the rule; Fisher recommends confirm.

## WHAT SHINICHI TOLD US

"use your judgment" on S3 and M4; order M1 → M2 → S6 → S2; gates as listed; no merge/release; close with
after-task, Melissa row, handover; no sub-agents from scouts; ≤5 live.

## WHAT THE TEAM RAISED (Phase 0.4, attributed)

```
TEAM RAISED
  Gauss  — the eleven sites differ from the Bernoulli template in TWO ways: the response density is weighted
           inside the quadrature sum AND the observed-row prior is unweighted; lognormal (mi_family 6) puts
           no prior term in its quadrature sum at all (likely absorbed into Gauss-Hermite nodes, to be
           verified, not touched). The row-duplication arm of the test catches both defects; the
           w=1-vs-w=2 arm alone would not catch the unweighted prior. Recommendation: three arms per family
           (w=1, w=2, literal duplication), convergence asserted. Default: as recommended.
  Emmy   — M2 has ONE choke point: predict.drmTMB() forms eta for dpar = sigma and returns it either as
           type="link" or through drm_inverse_link(); clamp there (for every sigma-type dpar of a family in
           drm_clamped_scale_families(), band from object$model$tmb_data) and sigma(), residuals(),
           fitted() inherit it. Do not patch the ~16 downstream sites. Question: should type="link" also
           return the clamped eta? Recommendation: yes — it is what the likelihood evaluated; label it in
           ?predict.drmTMB. Default: yes.
  Fisher — S2: both loci (summary()$derived and heritability()/icc()/repeatability()) are GAUSSIAN-ONLY
           (`R/methods.R:4553`, `R/heritability.R:278`), so D-252's scale question is moot for the number
           Russell measured; the residual variance marginal over a Gaussian random intercept on log-sigma is
           exactly exp(2*b0 + 2*omega^2), so the fix is exact and scale-independent. The D-252 gap in drmTMB
           is a different one: the accessors REFUSE non-Gaussian fits outright (an error, not NaN) where Eq 4
           is defined — a scope limit to name, not a bug to fix here. Recommendation: note first, then the
           exact fix. Default: as recommended.
  Fisher — S6: the bootstrap is already opt-in (method defaults to "wald"); the percentile interval
           re-applies the estimator's bias; the cheapest correction is the basic (reflected) interval
           2*theta_hat - q, computed on the link scale where the package already takes its percentiles;
           BCa needs n jackknife refits per target and is out of reach for TMB fits at this size.
           Recommendation: note proposes basic + BC as opt-in types, documents the bias-doubling on the
           help page, and specifies the D-139 pre-run before any default changes. Default: note only.
  Rose   — NEWS entries are shared surface between four builders; only the orchestrator writes NEWS.md,
           after builders return. Every "fixed" claim for M2 must repeat Fisher's caveat: C1's detector
           plus M2's reporting make a clamped fit honest, not correct. Public writes: comments on our own
           issues only. Default: as stated.
  Ada    — sequence M1 as test-first (red proof against the current .so, patch prepared but not applied)
           in batch 1, then apply+recompile in batch 2, so no builder recompiles src/ while another runs
           load_all in the same worktree. Two Opus reviewers (code; docs) is a stated exception to the
           one-ceiling rule, mandated by the arc's own gate.
```

## DECISIONS LOCKED (under "use your judgment")

1. **S3 = document.** Keep the code; rewrite `?drm_phylo_penalty` Details per Fisher §1 (prior is
   exponential with rate `-log(sd_alpha)/sd_u`, calibration true; penalty evaluated in `log(sd)` with the
   Jacobian; the reported penalised `sd_phylo` is the mode in `log(sd)`, never zero, `1/rate` = 0.334 at
   defaults under a flat likelihood; do not test a null of zero phylogenetic signal on a penalised fit; keep
   Simpson et al. 2017 as the prior's source and Chung et al. 2013 for why an off-zero estimator is
   defensible). Option B parked: a likelihood change needing bias/coverage evidence at a true null and a
   true nonzero SD (a campaign, Totoro). Record as a D- entry.
2. **M4 masking contract = confirm.** `simulate()` returns `NA` at masked rows for all thirteen families;
   consistent with `residuals()` and #1188. Record as a D- entry; no code.
3. **S2 code = yes, if Fisher concurs with the note** that the fix is scale-independent (Gaussian-only
   loci). Otherwise it stays a documented proposal.
4. **Russell** is not messaged in this arc.

## QUESTIONS STILL OPEN (none block execution)

- Whether the S6 default interval should later move from percentile to basic — needs the D-139 pre-run the
  note specifies; Shinichi's call after the note.
- Whether the heritability accessors should admit non-Gaussian families on the Eq 4 latent scale (the true
  D-252 gap in drmTMB) — a feature decision the S2 note frames; not this arc.

## SLICE TABLE

| id | slice | member | model · effort · dispatch | time | files (OWNS) | dep |
|---|---|---|---|---|---|---|
| R0 | RECON: M1 sites, M2/S2 paths, S6/infra | 3 scouts | Haiku · low · claude/model-param | done (3×~3 min) | scratchpad `recon-*.md` | — |
| L0 | Ledger: `.unlazy/dinnage-2/GATES.md` + 8 leaf gates; claim OWNS | Ada (orchestrator) | Fable (session) | 10 min | `.unlazy/dinnage-2/**` (ignored) | R0 |
| M1a | M1 test-first: `tests/testthat/test-dinnage-audit-m1-families.R` (11 families × 3 arms, converged); run against the CURRENT .so → red proof saved; prepare the C++ patch as `scratchpad/m1.patch` (NOT applied); scratch probe of `mi_family == 0` (report only) | Gauss (`tmb_engineer`) | Sonnet · high · claude/model-param | 60–90 min | `tests/testthat/test-dinnage-audit-m1-families.R`, `scratchpad/m1.*` | L0 |
| M2 | Clamp at the three sigma paths (`predict.drmTMB()`, the ~6288/6706 predict path, `drm_marginal_predict()` used by `simulate()`); `tests/testthat/test-dinnage-audit-m2.R` (clamp-active fit via narrow `drm_control(logsigma_clamp=)`: hand-recomputed Gaussian log-lik under `sigma(fit)` equals `logLik(fit)`; `sd(residuals(type="pearson"))` ≈ 1; `sigma()` within the band; `simulate()` draws' SD matches `sigma(fit)`) shown red first; roxygen note on `?predict.drmTMB`/`?sigma.drmTMB` (no `document()` call) | M2 builder (general-purpose) | Sonnet · high · claude/model-param | 60–90 min | `R/methods.R`, `tests/testthat/test-dinnage-audit-m2.R` | L0 |
| S6 | Design note `docs/design/274-bootstrap-interval-bias.md`: mechanism, Russell's numbers, options (document + recommend Wald/profile; basic; BC; BCa rejected with cost), recommendation, D-139 pre-run spec (n=100, R=199, 250 reps ≈ 50k refits → Totoro ≤150 cores), what it does NOT cover; help-page paragraph drafted but not applied | S6 writer (general-purpose) | Sonnet · high · claude/model-param | 40–60 min | `docs/design/274-*.md` | L0 |
| S2a+S3 | Design note `docs/design/275-repeatability-scale-and-residual-variance.md` answering #1301's four checks for drmTMB under D-252 (both loci Gaussian-only; no link variance added; non-Gaussian refused by error, not NaN — Eq 4 gap named; phylogenetic-signal denominator checked), then the S2 mechanism and the exact fix `exp(b0 + sum(omega_k^2))` for random intercepts on sigma, `NA` for random slopes on sigma; twin line for DRM.jl and gllvmTMB #1276. Plus S3: rewrite `R/penalty.R` roxygen per Decision 1 (no `document()` call) | S2 writer (general-purpose) | Sonnet · high · claude/model-param | 60–80 min | `docs/design/275-*.md`, `R/penalty.R` | L0 |
| DOC | `devtools::document()` once; `git diff --stat -- man/ NAMESPACE` must touch only `predict.drmTMB.Rd`, `sigma.drmTMB.Rd`, `drm_phylo_penalty.Rd` (and later `summary.drmTMB.Rd`) | Ada | Fable (session) | 5 min | `man/*.Rd` | batch 1 returned |
| M1b | Apply `m1.patch` to the eleven blocks; recompile (~5 min); run M1a test → green; run the existing `mi()` family tests + `test-dinnage-audit-wave1.R` | Gauss (reuse M1a agent) | Sonnet · high · SendMessage | 25–40 min | `src/drmTMB.cpp` | M1a, M2 returned |
| S2b | `drm_constant_residual_sigma()` exact fix + test (fit with `sigma ~ 1 + (1|g)`, compare `summary()$derived$residual_variance` and `repeatability()` to `exp(2*b0+2*omega^2)`; red first); walks every sigma random-effect source `has_sigma_random_effects()` knows; phylo-on-sigma → `NA` + message, tested | S2 writer (reuse) | Sonnet · high · SendMessage | 30–45 min | `R/methods.R:4650-4668` region, `tests/testthat/test-dinnage-audit-s2.R`, roxygen in `R/methods.R` for `summary.drmTMB` | S2a, Fisher-B concurs, M2 returned (shared file) |
| F-A | Fisher review, code: M1 (all 11 blocks vs the template; prior weighting; lognormal quadrature question), M2 (explicitly: does it cover `simulate()`'s marginal path?), S2b (explicitly: phylo-on-sigma?) diffs; negative controls read, not trusted | Fisher (`inference_reviewer`) | **Opus** · high · claude/model-param | 25–40 min | read-only; writes `docs/dev-log/audits/2026-09-14-dinnage-wave3-review.md` | M1b, M2, S2b |
| F-B | Fisher review, docs: notes 274 + 275, S3 help page, DECISION text | Fisher (fresh) | **Opus** · high · claude/model-param | 20–30 min | read-only; appends to the same review file (section 2) | S6, S2a+S3 |
| RP | Repairs from F-A/F-B by reusing the owning builder; re-review only if the estimand changed | builders (reuse) | Sonnet · high · SendMessage | 30–60 min | as owned | F-A, F-B |
| NEWS | NEWS.md entries (M1, M2, S2, S3 doc), check-log entry, issue-comment drafts in `docs/dev-log/issue-drafts/2026-09-14-dinnage-wave3/` | Ada | Fable (session) | 20 min | `NEWS.md`, `docs/dev-log/check-log.md`, drafts | RP |
| MV | MECHANICAL-VERIFY: `gate-check.mjs --reverify` every leaf; count new tests; confirm each red-proof artefact exists and names the failing expectation; NEWS/check-log entries present; `git diff --stat` matches OWNS | Haiku verifier | Haiku · low · claude/model-param | 10 min | read-only; `scratchpad/mv.md` | NEWS |
| CHK | `R CMD check --as-cran` on a clean export (`git archive` → tmp dir), in the background; then commit, push branch | Ada | Fable (session) | 45–90 min wall (unknown; not a campaign) | none | MV |
| REC | Melissa reconcile → `docs/dev-log/plan-actual/2026-09-14-dinnage-wave3.md` | Melissa | Sonnet · medium · claude/model-param | 15 min | that file | CHK |
| CLOSE | After-task report (11 sections), D- entries + AGENT_LOG in the vault, handover, GitHub comments (after approval) | Ada (Rose lens) | Fable (session) | 30 min | `docs/dev-log/after-task/2026-09-14-dinnage-audit-wave3.md`, `docs/dev-log/handover/2026-09-14-claude-handover-dinnage-audit.md`, vault | REC |

SEARCH: inline repo only (no NotebookLM — no novelty claim; dr24/dr26 cited as related reading in note 274).
SLICES: batch 1 = {M1a, M2, S6, S2a+S3} parallel (4 live) · batch 2 = {M1b, S2b} then {F-A, F-B} (≤4 live)
  · batch 3 = RP → NEWS → MV → CHK → REC → CLOSE (sequential).
FAN-OUT: 4 builders + 2 Fisher + 1 Haiku verifier + 1 Melissa = **8 new children** after G0 (exception to the
  6-per-checkpoint budget: the arc's own gate mandates a fresh-context Opus review of every diff, and Melissa
  and the mechanical verifier are required closes); never more than 4 live; recon scouts already returned.
FAN-OUT BUDGET: checkpoint=G0 · new children=8/6 (reason above) · scout=1 (MV) + 3 recon done · build=4 ·
  ceiling=2 (F-A code, F-B docs — fresh contexts required; cannot be one agent) · reuse=M1a→M1b, S2→S2b, RP.
SCOUT SUITABILITY: yes — three Haiku recon slices ran; MV runs on Haiku.
ULTRA EFFORT: no.
CONTEXT BRAKE: parent input ≈ 110k at plan time (Fable window is large; the ~100k rule targets forked
  children — every child here gets a fresh self-contained brief, none forks the parent).
COMPACTIONS: parent=0 · children max=0 · boundary=open.
LANE RECEIPT: CONTINUE HERE · reason=one lane, one branch, one arc; the handover at CLOSE carries the rest.
AUTO-REVIEW: guardian calls unknown · action=batch remote actions (push + comments) into one step at CLOSE.
D-43 PANEL: milestone=PR #1361 wave-3 push · status=not fired (F-A + F-B are the arc's mandated reviews;
  the merge panel belongs to the merge decision, which is deferred).
MODELS: Fable orchestrates (session); Sonnet high builds; Opus high reviews; Haiku low verifies;
  Sonnet medium reconciles — all via the Agent tool's `model` param; audited with `claude-routing-audit.py`.
ESTIMATE: ~4–5.5 h wall · 8 children in 3 batches · fits one session if as-cran ≤ 90 min; the handover is
  written regardless (D-88/handoff rule). No simulation, fit campaign, or benchmark; the only >30-min items
  are the as-cran check and the reviews, neither a D-139 run.
PREFLIGHT: Shannon — FOREIGN LANE ACTIVE (codex); lane claimed = `claude/audit-dinnage-wave1-20260913`
  (see Context).
REVIEW (plan, before run): Rose — sweep receipt present and evidence-cited (above) · Fisher — slicing keeps
  every estimand-touching change (M1b, S2b) behind a red-first test and a fresh Opus read · Gauss — the
  test-first/recompile split avoids the load_all-vs-compile race in one worktree.
VERIFY: `gate-check.mjs --reverify` per leaf (Haiku) · F-A/F-B (Opus) · as-cran (Ada).
CONSOLIDATE: NEWS, check-log, after-task, handover, vault (DECISIONS D-entries for S3/M4, AGENT_LOG, journal).
RECONCILE: Melissa (Sonnet, medium) → `docs/dev-log/plan-actual/2026-09-14-dinnage-wave3.md`.

## Slice details (what each builder is told)

**M1a/M1b (Gauss).** Template = the Bernoulli block at `src/drmTMB.cpp:1272-1313`. For each of the eleven
blocks (ordinal 1315, categorical 1417, beta 1495, zero-one-beta 1603, beta-binomial 1753, poisson 1853,
nbinom2 1926, truncated-nbinom2 2016, lognormal 2122, gamma 2196, tweedie 2285): (a) observed row →
`nll -= weights(i) * <prior log-density>`; (b) unobserved row → the per-node `log_y` loses its `weights(i)`
factor, and the closing line becomes `nll -= weights(i) * log_denom` (this is a larger change than at the
two-point sites because those rows are currently not weighted at all); (c) Tweedie has weights on both
2323/2324 — read before editing; (d) lognormal's quadrature sum has no prior term — verify it is absorbed
into the Gauss–Hermite nodes and say so in the commit; do not add one. Families via
`R/missing-data.R:3966-3982`; fixtures from `tests/testthat/test-missing-predictor-<family>.R`. Test arms:
`weights = 1`, `weights = 2`, `rbind(dat, dat)`; `expect_equal(fit$opt$convergence, 0L)` in the fit helper
(Fisher's caveat); tolerances 1e-6 / 1e-5 as in wave 1. Red proof = testthat output on the current .so
saved to `scratchpad/m1-red.txt` (expect 11 failing blocks). `mi_family == 0` (Gaussian latent) gets a
scratch probe only; a failure there is reported, not fixed.

**M2.** In `predict.drmTMB()` (`R/methods.R:2853-2937`), the second predict path (~6288/6706), and
`drm_marginal_predict()` (`R/methods.R:6691-6707`, the path `simulate()` uses by default and hence S6's
bootstrap), when `dpar` is a sigma-type parameter of a family in `drm_clamped_scale_families()`, pass eta
through `drm_softclamp_log_sd(eta, object$model$tmb_data)` before both the `type = "link"` return and
`drm_inverse_link()` — ideally via one shared helper the three call. Verify `observation_sigma()`
(`R/methods.R:5743`) and the lognormal `fitted()` path inherit it. NEWS wording names exactly which
accessors now report the clamped scale. Test fixture: Gaussian fit with `drm_control(logsigma_clamp = c(lo, hi), logsigma_clamp_margin
= m)` narrow enough that the clamp binds (pattern in `test-clamp-active-guard.R`). Assertions: hand
log-likelihood `sum(dnorm(y, predict(mu), sigma(fit), log = TRUE))` equals `logLik(fit)`; pearson SD ≈ 1;
every `sigma(fit)` ≤ `exp(hi + m)`. Show red first (pre-fix: the 752-nat gap Russell measured).
Help text: `sigma()`/`predict(dpar = "sigma")` return the scale the likelihood evaluated; when
`check_drm()` reports the clamp active, the estimate is still not trustworthy (C1 caveat).

**S6 (note 274).** Sections: reader and purpose; Russell's evidence (offset 2.35× bias, coverage 0.852 vs
0.896/0.912, one-sided); mechanism (percentile interval of draws centred at a biased θ̂ re-applies the
bias); where the code takes its percentiles (`bootstrap_percentile_interval()`, `R/profile.R:2978`, link
scale for positive targets; `bias_correct` reaches only the Wald path); options with cost and what changes
for users; recommendation; a D-139 pre-run spec with an explicit time estimate (from measured refit time
in the lane) and Totoro as target; help-page paragraph (drafted, not applied); NOT COVERED list.

**S2a (note 275) + S3.** Answer #1301's checkboxes with file:line evidence; state the scale of both loci
(Gaussian: the three scales coincide; the delta-method runs on the working log-SD scale); name the true
D-252 gap (non-Gaussian refused by error at `R/heritability.R:278`, so the package neither computes nor
mislabels — Eq 4 support is a feature decision); S2 mechanism and the exact correction; random slopes on
sigma → `NA` with a `conf.status`/message naming why; DRM.jl and gllvmTMB #1276 lines. S3: roxygen in
`R/penalty.R` per Decision 1, then `devtools::document()`.

**S2b.** Only after F-B concurs. Detect random intercepts on `sigma` through every source
`has_sigma_random_effects()` (`R/methods.R:6182-6190`) knows — ordinary group intercepts AND phylo-on-sigma
(`sd_phylo_group_values()`); ordinary intercepts → `exp(b0 + sum(omega_k^2))` (the RMS sigma, i.e.
`sqrt(E[sigma^2])`); random slopes on sigma or phylo-on-sigma → `NA` with a message, never the old
silently wrong `exp(b0)`; keep the existing `NA` guards; both callers inherit. Test red first, with a
phylo-on-sigma case asserting `NA`.

## Pre-authorisation envelope

```
PRE-AUTHORISED AFTER G0: scoped edits in the lane worktree; devtools::load_all/test/document; one TMB
recompile; R CMD check --as-cran on a clean export; local commits on the lane branch; the .unlazy ledger.
OPTIONAL REMOTE AUTHORITY: push claude/audit-dinnage-wave1-20260913 to the existing draft PR #1361;
post status comments on our own issues #1307, #1308, #1312, #1315, #1301 (drafted to files first);
never merge/release; no message to Russell.
MUST STOP: merge/release/public claim beyond those comments; any campaign or run >30 min other than the
package check; evidence that M1's algebra differs from the template at a site; a Fisher REJECT on an
estimand-touching diff (M1b, M2, S2b) that a bounded repair does not clear.
```

## Verification (end-to-end)

1. Every leaf gate re-run: `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --reverify
   .unlazy/dinnage-2/gates/leaf-<id>.md` — exit 0 for all.
2. Red proofs on disk: `scratchpad/m1-red.txt`, `m2-red.txt`, `s2-red.txt`, each naming the failing
   expectation on the pre-fix code.
3. `devtools::test(filter = "dinnage-audit|missing-predictor|clamp|heritability")` green.
4. Fisher's review file with an explicit verdict per diff; repairs closed.
5. `R CMD check --as-cran` on `git archive HEAD` → 0 errors, 0 warnings, notes as on 2026-09-13.
6. Branch pushed; PR #1361 CI observed (not waited on for the close, recorded in the handover).

## Close-out artefacts

- `docs/dev-log/after-task/2026-09-14-dinnage-audit-wave3.md` (protocol §10 sections).
- `docs/dev-log/plan-actual/2026-09-14-dinnage-wave3.md` (Melissa).
- `docs/dev-log/handover/2026-09-14-claude-handover-dinnage-audit.md` + a `CARRIED-OVER` line.
- Vault: D-entries (S3 = document; M4 = confirm), `AGENT_LOG.md`, `journal/2026-09-14`.
