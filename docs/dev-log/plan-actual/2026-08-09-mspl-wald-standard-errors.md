# Plan versus actual — MSPL Wald standard errors (Arc C)

Date: 2026-08-09 · Platform: Claude Code · Reconciliation inline by Ada.

Final verdict: **DONE** — deliverables (0) and (1) both met, claim narrowed by review.

## Scope

| Planned (Arc C slice table) | Actual | Disposition |
|---|---|---|
| C0 merge #956, notify lane 1 | merged `8d441a32d`; lane 1 notified on #955 with SHA/PR/disposition/receipt | Matched |
| C1 design 250 Phase 4 amendment | landed `8dfad8587`; Phase 3 text preserved with an inline supersession pointer | Matched |
| C2 implement the covariance | landed `1d6cd5330` | Matched |
| C3 split fences + 6 obligated tests | all six added; ~8 assertions split, none deleted | Matched |
| C4 document + tests + `--as-cran` | document clean; 1958 pass focused; `--as-cran` 0/0/1 | Matched |
| C5 Fisher + Noether reviews | both ran fresh, in parallel | Matched |
| C6 receipt + plan-actual, STOP before PR | this file + the after-task; no PR opened | Matched |

## Material deviations

**1. `--as-cran` run twice — adaptive.** The first run was launched against `1d6cd5330` while the
reviews were still out. Review fixes then landed as `24abee2fd`, making that result describe code
that no longer shipped. Re-run on the final commit rather than reported with a caveat. Both agree at
`0 / 0 / 1`.

**2. A reconcile defect surfaced late — DRIFT, mine, repaired.** `test-reml-binomial-coxreid.R` broke
under the Arc B reconcile and was not caught there, because that slice's neighbour-test filter did
not include the file. It is **new on main from #953**, so the MSPL branch had never seen it. Two
stale assertions, both of the pre-widening `validate_binomial_mu_random_terms()` wording. Rejection
behaviour verified intact directly before either was touched; the class was then swept (`grep`
confirms none remain). **Routed to Rose** as a process item: *a reconcile's verification filter must
be derived from the files the reconcile touched plus the files main added since the merge base — not
from the reconcile's own file list.*

**3. Sub-agent reported a defect as clean — DRIFT, caught by independent verification.** C2 shipped
`vcov()` with duplicated dimnames (`beta_mu`, `beta_mu`, `log_sd_mu`) straight from TMB's raw
`opt$par`, making the matrix un-indexable by name. Not mentioned in its return. Found by re-running
its claims rather than reading them. Repaired inline via `coefficient_labels()`.

**4. Sub-agent mis-attributed a failure's cause — DRIFT, corrected.** C2 described the coxreid error
as "pre-existing, confirmed present on the stashed baseline." True but misleading: stashing only its
own changes left the reconcile in place, so the baseline it compared against still contained the
actual cause. Recorded because the *form* of the claim was plausible enough to have been accepted.

**5. Melissa not dispatched — deviation from the plan's own RECONCILE row.** Same reasoning as the
separation lane: the planned-vs-actual facts live in the orchestrator's context, so a self-contained
brief would have restated them all. Written inline. Recorded rather than left silent.

**6. One extra slice not in the plan — adaptive.** Design note 252 (probit/cloglog scoped for 0.7.1)
was written and committed mid-arc at the owner's explicit reminder. Not scope creep: it is a
*recording* of deferred work, and it is what keeps Arc D from being rediscovered.

## Evidence and verification

Planned: ML-oracle SE agreement, sign-convention test, every fence still errors. All delivered, and
**every sub-agent number was independently re-run** — which is what caught deviations 3 and 4.
Exceeded in one respect: the oracle became a size ladder (n = 48/180/480/960) rather than a single
fixture, so the agreement is shown to converge as `c_n` predicts rather than merely to hold once.

## Model routing

| Slice | Planned | Actual | Note |
|---|---|---|---|
| C1 amendment | Opus inline | Opus inline | Matched |
| C2 covariance | Sonnet | Sonnet | Matched; one defect missed, caught on verify |
| C3 tests | Sonnet | Sonnet | Matched; clean |
| C4 checks | Sonnet | **Opus inline** | Demoted to inline — it is a toolchain run, not a delegable judgment |
| C5a/C5b reviews | Sonnet ×2 | Sonnet ×2 | Matched, parallel |
| C6 receipt | Opus inline | Opus inline | Matched |
| RECONCILE | Sonnet (Melissa) | **Opus inline** | See deviation 5 |

**Children created:** 3 this checkpoint (C2, C5a, C5b) against a budget of 6; 0 Opus children.
Prior planning checkpoint used 3 (two Explore, one Emmy). Within budget throughout.

## Safety gates

Phase 0.25 sweep receipt present and evidence-cited, and it **changed the plan** — the twin-repo line
found gllvmTMB's probit/cloglog and, more usefully, that its numerics are *weaker* than drmTMB's, so
"borrow" became "borrow the pattern, not the clamp." Smoke-first satisfied (C2 fit one toy model and
printed a finite SE before C3 touched the suite). No D-43 panel: a fenced capability, not a milestone
promotion. No compute campaign. No `git add -A`. **No PR opened** — Doc B reserves that to the owner.

## Public claims

None beyond the fenced capability. No DESCRIPTION bump (still `0.6.0`), no `platform-clean`, no
ledger or census movement, no README/NEWS/pkgdown wording. The design-250 amendment is a *contract*
change, landed explicitly and re-asserting the six retained fences verbatim.

## Handoff state

Arc C complete to its stated closure: local green plus a reviewed receipt, stopping before the PR.
Branch `claude/mspl-binomial-inference-promotion` pushed at `24abee2fd` (plus the receipt commit).

Carried forward, in priority order:
1. **q2 has no external oracle** — only q1 is validated against ML `sdreport()`. Smallest
   highest-value gap if MSPL SEs go user-facing in 0.7.0.
2. No threshold or scale-free reading of `unpenalized_gradient_max_abs`.
3. Arc D (probit/cloglog + link-general Jeffreys, 0.7.1) — fully scoped in design note 252,
   including the Julia-bridge re-gate that is its highest-risk item.
