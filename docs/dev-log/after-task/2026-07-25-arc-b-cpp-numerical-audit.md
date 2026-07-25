# After Task: Arc B — C++ / numerical audit (correctness-first)

**Branch**: `claude/arc-b-numerical-audit` (worktree off `origin/main` 95f323e1)
**Date**: `2026-07-25`
**Platform**: Claude Code
**Roles (engaged)**: Ada (orchestrate) · Gauss (S1, S2, S3) · Curie (S2b) · Rose (S5,
plan gate) · Fisher (plan gate) · Boole (S4 static half) · orchestrator (S4 executable
half, S0, S6)

## 1. Goal

Arc A closed having measured that ~80% of drmTMB's stuck `point_fit_recovery` pool is
**frontier** — structured REs, scale-side REs, `sd()` regression, bivariate LSS,
phylogenetic structure on residual log-SD — where **no external implementation exists to
compare against**. Cross-package parity can reach ~15 cells, ever.

This arc substitutes *internal* correctness evidence for the external agreement parity
cannot supply: analytic density oracles, derivative agreement, score identities, and
branch-continuity checks. Correctness-first; **no efficiency claim without a profiler**.

## 2. Implemented

Five new standing suites (**58 `test_that` blocks, 516 assertions, zero skips**):

| Suite | What it pins |
| --- | --- |
| `test-numeric-kernel-oracle.R` | 17 of 18 univariate families vs independent R references over `eta ∈ {-700…700}` × `log_sigma ∈ {-15…15}` |
| `test-gradient-conformance.R` | `obj$gr` vs `numDeriv::grad` over 14 structures × typical/extreme/boundary theta |
| `test-score-consistency.R` | Bartlett identities `E[score]=0`, `Var(score) ≈ −E[He]` on 4 routes |
| `test-guard-branch-continuity.R` | all 26 `CondExp` sites, each against a **pre-declared** smoothness class |
| `test-link-conformance.R` | `model_type` map read off `obj$env$data`, guarded transforms, cutpoint monotonicity |

Plus `docs/dev-log/2026-07-25-arc-b-frontier-hazard-read.md` (S5's static read) and
`numDeriv` added to `DESCRIPTION` `Suggests` so the suites need no `skip_if_not_installed()`.

## 3a. Decisions and Rejected Alternatives

- **The tier fence is asymmetric.** Correctness evidence may **never promote** a ledger
  cell; it **can compel a demotion**. Adopted at Fisher's insistence at the plan gate;
  a blanket "no cell changes tier" would have forbidden the one ledger action this arc
  could legitimately force. Two candidate triggers arose and **both were checked and
  cleared** (§7a), so no demotion is compelled.
- **`TMB::checkConsistency` was NOT used.** It requires `SIMULATE` blocks; there are
  **zero** in `src/drmTMB.cpp`. Adding them across 19 branches is a successor arc.
  The score-consistency slice obtains the same inferential content in pure R instead.
- **Guard-sensitivity simulation stayed fenced** to doc 176's ADEMP lane (Totoro), not
  run here.
- **`Rmpfr` rejected** — not in `Suggests`, needs GMP/MPFR system libraries; the
  precision question it was proposed for was settled analytically instead.

## 4. Files Touched

`DESCRIPTION` (+`numDeriv`) · five new `tests/testthat/test-*.R` ·
`docs/dev-log/2026-07-25-arc-b-frontier-hazard-read.md` · this report.
**No `src/` or `R/` change.** The audit observes; it does not repair.

## 5. Checks Run

| Check | Baseline (pre-arc) | After |
| --- | --- | --- |
| test blocks | 2059 | 2117 (+58) |
| assertions passed | 39192 | 39708 (+516) |
| failures | 1 | **1 — identical** |
| skips | 124 | **124 — identical** |
| new-suite skips | — | **0** |
| new-suite failures | — | **0** |

**Zero pre-existing tests changed status.** The single failure is pre-existing:
`test-phase18-structured-workflow-registry.R` :: "path prefers checkout files", a
path-resolution test unrelated to numerics. Its cause is **not established** — a
worktree-vs-installed-lib artifact is plausible but is inference, not demonstrated.
Explicitly out of scope; not fixed here.

Smoke-first was honoured: a toy Gaussian fit returned a finite objective (89.90883) and
finite gradient, with AD-vs-FD 6.9e-10, before any matrix ran.

**S0 live state re-verification — the evidence, not the assertion.** Rose's completion
gate correctly objected that the first draft *claimed* this ran without attaching output.
Run at S0 and re-confirmed unchanged at close:

```
$ git ls-remote origin | grep -E 'pkgdown-formal-closeout|arc6-6-bernoulli'
2c2499a366bc1bb1201de3c052f211ff2eee8f3c  refs/heads/codex/arc6-6-bernoulli-nb2
f0617e97df95cea2cf45b76c714d1919d29e4fc9  refs/heads/codex/pkgdown-formal-closeout

$ gh pr list --state open
PR #841  codex/pkgdown-formal-closeout
PR #839  handover/2026-07-25-claude-arc-a
PR #836  handover/2026-07-25-claude
PR #829  codex/fix-bivariate-nav-dup

$ git rev-parse origin/main
95f323e153439b85db7e0bd5003c0ac6a250768c
```

This is what retired the handover's "orphaned, needs an owner" framing for
`codex/pkgdown-formal-closeout`: it is pushed and PR #841 is open. `origin/main` has not
drifted from the 95f323e1 this worktree was cut from.

## 6. Tests of the Tests

Every suite was proven able to fail, and reverted:

| Suite | Injection | Result |
| --- | --- | --- |
| kernel oracle | `dnorm(...) + 0.001` | gaussian block red, rest green |
| gradient conformance | corrupted one `g_AD` component; and tol → 1e-15 | 1 of 16 blocks red |
| score consistency | θ₀ intercept shifted +0.5 | z = 42.9 vs \|z\|<2.7 at truth |
| branch continuity | `+1e-3` into a reference helper | rel diff 0.99 ≥ 1e-9, red |
| link conformance | `model_type` 7L → 99L | 39 pass / 1 fail, reverted to 40/0 |

## 7a. Issue Ledger

**Label convention (Rose's completion gate).** A single `CONFIRMED` was doing two
different epistemic jobs, and a reader scanning only this table would weigh them equally.
Split: **CONFIRMED-MEASURED** = demonstrated by running something;
**CONFIRMED-STATIC** = established by source reading plus arithmetic, no fit run.

| # | Finding | Label | Severity |
| --- | --- | --- | --- |
| A1 | `simulate.drmTMB` simulates **conditionally** on fitted MAP `û` (`R/methods.R:5531`); `confint(method="bootstrap")` inherits it via `R/profile.R:2204`, as does the campaign runner `inst/sim/R/sim_bootstrap.R:25` | **CONFIRMED-MEASURED** | High (user-facing) |
| A2 | TMB's built-in `dtweedie()` is **silently wrong** for phi ≲ 1e-7 — wrong sign of trend; begins *inside* the default clamp band. Locus upstream; **exposure is drmTMB's**, which calls it inside its own default band and ships `tweedie()` as a supported family | **CONFIRMED-MEASURED** | Medium |
| A3 | separable-covariance ridge is **trace**-relative, not diagonal-relative → ~50% silent inflation under scale heterogeneity (`drmTMB.cpp:190-195`) | **CONFIRMED-STATIC** | Medium |
| A4 | ridge is multiplicative, so vanishes exactly when `trace(S)` underflows (`log_sd_phylo < -372.5`) | CONFIRMED-STATIC (mechanism traced; reachability inferred) | Medium |
| A5 | beta `mi()` leaf called with **unclamped** `log_sigma` while the main loop uses clamped (`:2766-2771` vs `:2888-2891`); sibling nbinom2 does the opposite | **CONFIRMED-STATIC** | Medium |
| A6 | `default: return Type(0.0)` in the response-kernel leaf → silent zero log-density for a future mi()-capable family | CONFIRMED-STATIC (latent) | Low now, high on P3 |
| A7 | line numbers used as an audit trail have rotted: four `R/family-dpq.R` citations land in the **wrong family**; `drm_dpar_link` carries three different numbers, one of which matches nothing in the repo | **CONFIRMED-STATIC** | Low but systemic |
| A8 | `cumulative_logit` returns `Inf`/NaN-gradient for cutpoint gap ≲ 2.3e-16 where a stable reference continues | **CHARACTERIZED — no reachable defect demonstrated** | Low |
| **F5** | **`sd()` regression takes `exp()` of an unbounded regression-predicted log-SD with no clamp, bound, or `CondExp`** (`drmTMB.cpp:831, 921, 2279, 2815, 4107`), while residual `log_sigma` is clamped by default and every correlation is `tanh`-bounded. Doc 170's own justification for the clamp — "a runaway per-observation scale… estimated from one observation per group" — **applies verbatim to the unguarded case**. A frontier route. Safeguard: bound or clamp the regression-predicted log-SD as the residual one already is | PLAUSIBLE (no fit run to drive `eta_sd > 709`) | Low-Med |
| F3 | Cholesky PD margin degrades ~`q^-3`: ~1e3 at q=4, ~15 at q=8, ~2 at q=16. Adequate today; `q_phylo` is unbounded in C++ | CONFIRMED-STATIC | Low |
| F6 | The four *live* `mu = exp(eta_mu)` sites (`:2667, 2714, 3391, 3447`) — legitimate domain transform under doc 176; ordinary TMB overflow only | CONFIRMED-STATIC | Low |
| F9 | **12** dead `sigma_i` locals (not 3): `drmTMB.cpp:1149, 1232, 1312, 1397, 1535, 1666, 1728, 1810, 1914, 1995, 2079, 2172`. Harmless, and each is a frozen copy matching the extracted leaf — evidence *against* drift | CONFIRMED-MEASURED (`clang++ -fsyntax-only -Wall`) | Info |
| F10 | `model_type == 97` enters the shared `95‖96‖97` setup (`:537`) with no family body and no R-side construction site — unreachable dead code | CONFIRMED-STATIC | Info |

**A1 detail.** Three independent signatures at 25 groups × 8, 200 sims: correlation of
the group-mean pattern across replicate pairs **0.9852**; correlation with fitted `û`
**0.99996**; sd of between-group SD 0.0437 vs 0.2257 expected under marginal simulation.
Curie's elimination isolates the **simulator**, not the density and not Laplace — an
analytic Gaussian-LMM score on correctly marginal data gives z = −1.55 at 4000
replicates, while the same formula on `simulate.drmTMB` output reproduces TMB's z ≈ 4.6.
For a Gaussian random intercept Laplace is analytically exact, closing that door.
Undocumented; there is no `re.form` / `use.u` toggle.

**A2 detail.** `drmTMB.cpp:2726` calls TMB's `dtweedie()`
(`TMB/include/distributions_R.hpp:554`); the defect is upstream in
`atomic::tweedie_logW`. At `mu=1, y=1, p=1.5`: agreement to 5e-14 at `log_sigma = -2`,
then −3.53 at `-8`, −32.6 at `-10`, −42.9 at `-15`. As phi shrinks the density at the
mode must rise; the reference rises (4.08 → 14.08) and the kernel falls (4.08 → −28.84).

**The inferential consequence — the strongest part of this finding, and missing from the
first draft.** Because the likelihood falls where it should rise, the optimizer is
actively **repelled** from small phi. The practical effect is therefore not a crash or a
NaN but an **upward dispersion bias for genuinely low-dispersion Tweedie data**: a fit
whose true phi lies near or below the breakdown cannot be attracted to it. That is a
silent, directional inferential error, not merely a precision loss in a corner.

## 8. Consistency Audit

**Both asymmetric-fence triggers were checked before any claim, and both cleared.**
Fisher's completion gate rejected the first version of this section for resting on an
*absence* argument over 6% of the corpus; it is restated below on the positive check.

**A1 / bootstrap — the POSITIVE check, per certified cell:**

| Cell | Interval method that produced its coverage | Artifact |
| --- | --- | --- |
| `mc-0227` | **profile** — `drm_o3_profile_ci()`, profile of the Cox–Reid restricted objective in log σ | `docs/dev-log/simulation-artifacts/2026-07-18-o3-cumlogit-slope-coverage/README.md` |
| `mc-0242` | **Wald + profile** — `confint(fit, parm = "sd:sigma:(1 | id)", method = "profile")` | `docs/dev-log/simulation-artifacts/2026-07-17-gamma-sigma-re-coverage/README.md` |
| q4 structured-RE grids | **Wald + profile** — `wald_coverage`/`profile_coverage` populated; `bootstrap_coverage = NA`, `bootstrap_R = 0` | `docs/dev-log/simulation-artifacts/2026-06-27-q4-location-coverage-grid-local/*-summary.tsv` |

**Honest scope of the supporting negative scan.** `bootstrap_R = 0` holds in all **151**
artifacts carrying that column, nonzero only in three `*-bootstrap-smoke-contract.tsv` at
`R = 2` (plumbing smoke). But **151 of 2,476** `.tsv`/`.csv` artifacts carry the column at
all; the scan is silent about the other 2,325. It is corroboration, not proof. And the
real exposure surface is `simulate()`, not the `bootstrap_R` column: **`inst/sim/R/sim_bootstrap.R:25`**
calls `stats::simulate(fit, nsim, seed)`, so the conditional simulator is wired into a
campaign runner. The per-cell table above is what actually settles the fence.

**A2 / tweedie:** `mc-0539` is `inference_ready_with_caveats`. Its DGP uses
`beta_sigma = c((Intercept) = -0.65, z = 0.15)` → `log_sigma ≈ -1.1 … -0.2`, i.e.
phi ≈ 0.11–0.67 against a breakdown at phi ≲ 1.1e-7 — **~6 orders of magnitude** of
margin (an earlier draft said seven; the arithmetic is 0.27 / 1.1e-7 ≈ 2.5e6). **Caveat
on what was checked:** this compares the **DGP truth**, not the distribution of realized
`sigma_hat` across replicates, which was not examined. With 6 orders of margin the
conclusion is very likely safe, but the check performed is not the check that would
settle it definitively.

**No ledger cell changes tier as a result of this arc.** This is true by construction —
no `cells.tsv` row was touched — and is **not enforced by tooling**; no automated
pre/post ledger diff exists.

## 9. What Did Not Go Smoothly

- **S4 was misrouted.** `formula_reviewer` has Read/Grep/Glob only, so it could not
  write or run the suite. It correctly refused to fabricate results and delivered the
  static half; the orchestrator absorbed the executable half inline rather than spending
  a seventh child. **Lesson: never assign a write-and-run slice to a review-only agent type.**
- **The plan's nominated "highest-value single target" was a non-finding.** The
  hand-rolled Cholesky cannot produce a silent `sqrt(negative)` NaN from the public API.
- **The NB2 NaN hypothesis was wrong twice.** The orchestrator's mechanism
  (`lgamma(1e300) → Inf`) is numerically false — it is 6.9e302. Fisher's corrected
  mechanism (`0 × −Inf` in the reverse sweep) is sound in theory but **defeated by
  CppAD's own guard**: `cppad/local/div_op.hpp:389-395` skips the operation when the
  adjoint is identically zero, explicitly "(zero times infinity or nan would be
  non-zero)". Verified in source and empirically to `log_sigma = -1e6` with the clamp
  disabled.
- **A truncated build log was reported as complete.** "3 `sigma_i` dead variables" is
  actually **12**. Nine more of the same kind — the Rose principle, paid in full.
- **A monitor false-positived** "ALL SIX ARTIFACTS PRESENT" on a partial set, and a
  `grep` counted a comment as a `skip_` call. Both caught and corrected before they
  reached a conclusion.

## 10. Known Residuals

- A1–A8 are **reported, not fixed**. This arc observes.
- **Bivariate kernels (`model_type` 2, 19, 20) are NOT covered** by the kernel oracle —
  a 2-response, 5-parameter kernel with bounded `rho12` needs a different fixture.
- **`beta_binomial` at `log_sigma = -15`, `trials = 1000`** — kernel and all three
  independent references disagree by up to 2.6e-2. None is a trustworthy arbiter;
  excluded from the strict grid rather than adjudicated.
- **`#710.2` remains open**, re-scoped: the printed constant in the issue has a sign
  error (`0.5*(-digamma(1) - log 2)` = −0.0580, not +0.6352; correct is
  `0.5*(-digamma(1) + log 2)` = 0.6351814), and it is a log-sigma **intercept** bias of
  −0.4094, not a slope bias — slopes are invariant under an intercept-bearing OLS.
- **S2 is a coarse standing guard, not a sensitive one.** Achieved statistics sit at
  1e-9…1e-12 against pre-registered tolerances of 1e-6 (fixed) / 1e-4 (Laplace) — a 4–5
  order margin. Pre-registration was the right discipline and the thresholds were not
  retuned after seeing results, but as a *regression* guard the suite would not notice a
  change that degraded a gradient by three orders. Tightening it is a separate decision
  requiring its own pre-registration.
- **The `R CMD check` gate caught a defect `test_dir` could not.** S3's drift guard read
  `src/` via `test_path("..", "..", "src", …)`, which resolves from a source checkout but
  ERRORs under `R CMD check` (tests run from `<pkg>.Rcheck/tests/`, sources at
  `00_pkg_src/drmTMB/src/`). Fixed by resolving against both layouts and failing loudly
  if neither exists — deliberately **not** a `skip_*()`. The other four suites were
  checked for the same defect class and **none reads source**. This is why the plan wrote
  `R CMD check` as a gate separate from the full-suite run.
- **No profiler was run, so no efficiency claim of any kind is made anywhere.**

## 11. Team Learning

The two plan-gate reviewers changed the arc materially, before anything ran:

- **Rose** caught the carried-over-state table repeating a claim its own source handover
  had retracted 35 minutes later (`codex/pkgdown-formal-closeout` is pushed, PR #841
  open). The *stale-state-as-fact* guard exists because of it.
- **Fisher** caught the `#710.2` sign error, the false `lgamma` premise, a grid that
  could not reach its own hypothesis, the missing `numDeriv` dependency, a
  self-contradictory S1 fixture, and the wrong-way tier fence — **and contributed S2b**,
  which produced the arc's most consequential finding (A1). The plan's own headline
  hypotheses produced non-findings; the slice added at the gate produced the result.

**The generalisable lesson:** in this arc, adversarial review at the plan stage was worth
more than the plan. Three of the four hypotheses the orchestrator ranked highest were
refuted by measurement; the finding that mattered came from an instrument it had not
thought of.

## 12. Cross-Product Coverage

**Does NOT cover:** bivariate kernels (2, 19, 20) · AGHQ + Cox-Reid and native REML
(both pure R — no C++ path exists) · `TMB::checkConsistency` (needs `SIMULATE` blocks,
none exist) · guard-sensitivity simulation (doc 176's ADEMP lane, Totoro) · any
efficiency or performance question · repair of any finding reported here.
