# Prong B scoping decision — the 30 fenced drmTMB cells

Ada, 2026-08-03. Consolidates three read-only scoping slices (zero_one_beta ordinary RE;
zero_one_beta structured RE; count-family labelled-q2 / sigma-interaction), each of which
included a live fence-bypass spike. Read-only memo: no tracked file was modified.

All line numbers are `git show origin/main:R/profile.R` (4357 lines). The local working-tree
copy of `R/profile.R` is dirty and was **not** used for any citation here.

---

## 1. THE HONEST NUMBER

**14 of 30 are promotable. Not 30, not 23, not 19.**

The 30 partition cleanly into three tiers. The partition is by **dpar physics**, not by
family or by fence token — that is the load-bearing finding of this scoping round.

### Tier 1 — PROMOTE (14 cells): fund the campaign now

| group | cells | n | why |
|---|---|---|---|
| zob `sigma`, ordinary RE | mc-0568, mc-0576 | 2 | spike: textbook unimodal profile, CI `[0.207, 0.555]`, two engines agree to 3–4 dp, lower bound nowhere near the sd floor |
| zob `sigma`, structured RE | mc-0593, mc-0594, mc-0595, mc-0596, mc-0597 | 5 | spike (phylo): `pdHess=TRUE`, unimodal, crosses LR both sides (2.034 / 2.004), CI `[0.281, 0.640]` **covers** true 0.45 |
| count `mu`, labelled q2 | mc-0418, mc-0436, mc-0446, mc-0450, mc-0454 | 5 | spike (mc-0418): all **three** direct targets (2 SD + 1 cor) unimodal, non-clamped, each CI brackets truth |
| count `sigma`, phylo_interaction q1 | mc-0425, mc-0653 | 2 | spike (mc-0425): single SD target, CI `[0.3916, 0.6756]` covers true 0.60, endpoint vs grid engine agree to 4 dp |

Common property: every one of these 14 profiles a **scale parameter estimated from all rows**
(`log_sd_sigma` / `log_sd_phylo`), and every spiked representative produced a clean two-sided
profile whose interval covered the truth on the first seed tried.

### Tier 2 — HOLD, do not fund in this arc (11 cells): calibration pilot required first

| group | cells | n | blocking signal |
|---|---|---|---|
| zob `zoi`, ordinary RE | mc-0569, mc-0577 | 2 | **sample-size-sensitive and self-contradictory across two configurations.** n=288: `profile.boundary=TRUE`, `message="near_sd_boundary"`, lower bound 0, NLL flat to `log_sd_zoi = -1.5e22` — a genuine one-sided boundary profile, fails the contract's "not boundary/clamp limited". n=1600: clean profile but point estimate 0.659 vs true 0.45 = **46.4% relative error**, failing the 0.35 gate, with the truth sitting just below the lower CI bound. Neither configuration passes end to end. |
| zob `zoi`, structured RE | mc-0603, mc-0604, mc-0605, mc-0607 | 4 | never spiked; same conditional-atom physics as ordinary `zoi`, which just failed twice in two different ways. Extending Tier-1 optimism here is unsupported. |
| zob `mu`, structured RE | mc-0583, mc-0584, mc-0585, mc-0586, mc-0587 | 5 | spike (mu-phylo, 32 tips × 30 obs, 12% boundary mass): estimate 0.365 vs true 0.55 = **33.6% relative error** (0.014 under the gate) and the 95% profile CI `[0.246, 0.534]` **excludes the true value 0.55**. Under the stated contract that single seed **blocks promotion outright**. The mechanics are fine; the *fixture* is not. |

Tier 2 is not "no". It is "the pilot that would make it a yes has not been run". Each group
needs a bounded fixture-calibration pass (2–3 sizes × 2–3 seeds) before the 5-seed contract
is worth committing to. Cost of that pilot is minutes, not hours — see §4.

### Tier 3 — KEEP FENCED (5 cells): do not fund, now or later, without a fresh owner decision

| cells | n | why |
|---|---|---|
| mc-0570, mc-0578 (zob `coi`, ordinary RE) | 2 | `coi` is Pr(y=1 \| y ∈ {0,1}) — estimated **only** from rows already at a boundary. `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c17c1-.../README.md` is `BLOCKED_POINT_RECOVERY`; the hard support gate passed 2/4 seeds; Noether and Rose both returned BLOCK. The cell's current point-fit status rests entirely on `docs/dev-log/evidence/2026-08-01-c17c1-support-floor-disposition.md`, which says in writing: *"The raw prospective receipt remains BLOCKED_POINT_RECOVERY under its original contract and is not rewritten"*, and licenses the **point-fit tier only** — explicitly "must not be described as profile, interval, coverage, inference-ready". The DGP fails its own support rule with probability 0.6299 under a correct generator. |
| mc-0613, mc-0614, mc-0617 (zob `coi`, structured RE) | 3 | identical physics, one provider layer further out, with strictly less evidence. Same verdict. |

Opening a `coi` profile fence would convert a deliberately-scoped point-fit allowance into an
interval claim the owner decision explicitly declined to grant. **That is the one thing in this
memo that must not happen regardless of what a campaign returns.**

14 + 11 + 5 = 30. ✔

---

## 2. IS IT WORTH IT?

Per group, plainly:

- **zob `sigma` ordinary (2 cells) — FUND.** Cheapest, cleanest evidence in the whole set.
  ~70 s of single-core compute for the entire 5-seed campaign.
- **zob `sigma` structured (5 cells) — FUND.** phylo spiked clean and covering. The four
  untested providers share the identical profile code path (the machinery branches on
  `target_class`/`tmb_parameter`/`is_direct`, never on provider).
- **count `mu` labelled q2 (5 cells) — FUND.** The single best spike result in the set: three
  direct targets per cell, all clean, cross-validated by two independent profile engines.
- **count `sigma` phylo_interaction (2 cells) — FUND.**
- **zob `zoi` ordinary + structured (6 cells) — DO NOT FUND YET.** Fund a **2-hour calibration
  pilot** instead. Running the full contract now would burn a campaign to discover a fixture
  problem a 6-fit pilot finds for free.
- **zob `mu` structured (5 cells) — DO NOT FUND YET.** Same reason, with a sharper signal: we
  already know one seed fails. Fund a fixture pilot (raise tips and/or obs-per-tip until the
  point-fit relative error sits ≤0.20 with margin) before the campaign.
- **zob `coi` ordinary + structured (5 cells) — DO NOT FUND. Ever, under the current
  disposition.** This is the legitimate "no". It saves ~5 cells' worth of campaign *and*
  prevents a claim the owner has already declined to authorise.

Overall verdict: **yes, fund Prong B — but at 14 cells, not 30.** The compute is trivial
(§4); the value is that 14 cells move `point_fit_recovery → interval_feasible`, which is the
first interval-tier movement of this programme and the first `R/` source change it has ever
required.

---

## 3. THE R/profile.R CHANGE

This is the **first `R/` source change of the whole interval programme.** It is a pure boolean
unlock: `confint(method="profile")` currently errors only because `profile_ready == FALSE`
(`R/profile.R:894-899`). Flipping it hands control to `profile_direct_target_status()`
(`R/profile.R:3969-3980`), which checks only `sum(names(object$opt$par) == internal) >= index`
(`profile_internal_is_active`, `R/profile.R:3959-3967`). **No shape, monotonicity, boundary or
support check runs at unlock time.** The entire evidence burden is in the campaign, not the code.

### Edits (4), all in R/profile.R

**E1 — `count_point_fit_only_profile_restricted()`, R/profile.R:4027-4036.** Three of its four
disjuncts change:

- delete line **4028** — `(identical(dpar, "mu") && count_labelled_q2_profile_restricted(object)) ||`
  → opens the SD targets of mc-0418/0436/0446/0450/0454.
- delete line **4029** — `count_sigma_interaction_profile_restricted(object, dpar) ||`
  → opens mc-0425 and mc-0653.
- **KEEP line 4030** — `zi_nbinom2_sigma_q1_profile_restricted(object, dpar) ||`. This governs
  zi_nbinom2 *ordinary* sigma q1, which is **not** one of the 30. Do not touch it.
- narrow the zero_one_beta disjunct at **4031-4035**: change
  `dpar %in% c("mu", "sigma", "zoi", "coi")` → `dpar %in% c("mu", "zoi", "coi")`
  → opens mc-0593..0597 while leaving structured `mu`/`zoi`/`coi` fenced (Tiers 2 and 3).

**E2 — correlation-target loop, R/profile.R:1507-1515.** Delete the
`identical(internal, "eta_cor_phylo") && ... && count_labelled_q2_profile_restricted(object)`
branch so the `cor:mu:...` target of the five q2 cells falls through to
`profile_direct_target_status()`. Without E2, E1 opens only 2 of the 3 targets per q2 cell.

**E3 — `zero_one_beta_sigma_q1_profile_restricted()`, R/profile.R:4103-4112.** Delete the
function and both call sites: the disjunct at **R/profile.R:1408** in the SD-target loop, and
the note branch at **R/profile.R:4039-4044**. Opens mc-0568 and mc-0576.

**E4 — orphan removal made necessary by E1–E3** (Karpathy rule: remove only what your own
change orphaned):
- `count_labelled_q2_profile_restricted()` R/profile.R:3982-3996 and
  `count_labelled_q2_profile_restricted_status()` R/profile.R:3998-4003 — orphaned by E1+E2;
  also delete the terminal `count_labelled_q2_profile_restricted_status()` call at
  R/profile.R:4100.
- `count_sigma_interaction_profile_restricted()` R/profile.R:4005-4013 and its note branch
  R/profile.R:4057-4066 — orphaned by E1.
- retired note tokens in the pre-registered valid-note vector: `"point_fit_only_count_q2"`
  (R/profile.R:3816), `"point_fit_only_count_sigma_interaction"` (3817),
  `"point_fit_only_zi_nbinom2_sigma_interaction"` (3818),
  `"point_fit_only_zero_one_beta_sigma_q1"` (3833).
- **Do NOT retire** `"point_fit_only_zero_one_beta_{phylo,animal,relmat,spatial,phylo_interaction}_q1"`.
  Those tokens are **shared** by structured `mu` and structured `sigma` (test-zero-one-beta.R:557
  asserts it for mu-phylo, :612 for sigma-phylo). `mu` stays fenced, so the tokens stay.

### Everything else that must move with it

Because this is the first `R/` change, the downstream surface is larger than the diff:

1. **roxygen / man** — `R/profile.R:514-526` (`@return` list of `profile_note` values) loses four
   tokens; regenerate `man/profile_targets.Rd` (lines 25-26, 35 today) with
   `devtools::document()`. The same block already has a pre-existing gap (animal/relmat/
   phylo_interaction zoi/coi tokens are defined at 3827-3832 but undocumented) — fix it in the
   same pass since you are editing the block anyway.
2. **Tests that assert the retired notes** (each currently asserts `profile_ready == FALSE`;
   each must flip to `"ready"` **and** gain a real interval assertion, not just a note swap):
   - `tests/testthat/test-count-structured-mu.R:606` — `rep("point_fit_only_count_q2", ...)`
   - `tests/testthat/test-phylo-interaction.R:436` (mc-0425), `:541` (mc-0653)
   - `tests/testthat/test-zero-one-beta.R:991`, `:1090` (ordinary sigma), and the
     structured-sigma assertions at `:612`, `:782`, `:811`, `:830`, `:962`
   - `tests/testthat/test-profile-targets.R:462-464` — the valid-token registry test
   - `tests/testthat/test-zero-one-beta.R:1092-1093` — the
     `expect_error(confint(..., "not ready for direct profiling"))` negative control **must be
     replaced**, not deleted: assert a finite ordered interval with `conf.status == "profile"`.
3. **`se = TRUE` coverage.** `tests/testthat/test-zero-one-beta.R` currently has 35 `se = FALSE`
   and zero `se = TRUE`. At least one fast `se = TRUE` + `confint(method="profile")` test per
   promoted group must ship with the change (keep them small — the ordinary-sigma profile is 5.4 s).
4. **NEWS.md** — the 0.6.0 entries for these routes currently end "Direct profiles, intervals,
   coverage ... remain unavailable." Those sentences are now **false for the 14 and still true
   for the 16**. Edit surgically per route; do not blanket-edit the section.
5. **Ledger** — `docs/dev-log/dashboard/capability-ledger/cells.tsv`: `evidence_tier`
   `point_fit_recovery → interval_feasible` for exactly the 14 (col 17), plus `claim_boundary`
   (23), `next_gate` (24), `primary_evidence_id` (22), `updated_commit`/`updated_date` (27/28).
   New `evidence.tsv` rows for the campaign receipts.
6. **`R CMD check --as-cran` + full `devtools::test()` locally** before any push (per the
   local-checks-over-CI rule). Expect snapshot churn in `tests/testthat/_snaps` wherever a
   profile note is printed.
7. **pkgdown / vignettes** — grep returned no vignette or README hits for these tokens, so the
   prose surface is small; re-grep after the edit rather than assuming.

---

## 4. THE CAMPAIGN

### Scope

| group | cells | direct targets / cell | targets |
|---|---|---|---|
| zob sigma ordinary | 2 | 1 SD | 2 |
| zob sigma structured | 5 | 1 SD | 5 |
| count mu labelled q2 | 5 | 2 SD + 1 cor | 15 |
| count sigma phylo_interaction | 2 | 1 SD | 2 |
| **total** | **14** | | **24** |

### Fits

- **1 `se = TRUE` fit per (cell, seed)**, which serves as *both* the point-fit recovery gate and
  the profile base — this is what makes the "gate and campaign share one seed family"
  requirement mechanically automatic rather than a discipline problem.
- 5 seeds per cell → **70 fits**.
- Profiles: 24 targets × 5 seeds = **120 profile runs**. Recommend **8 seeds for the three
  `cor:mu:...` targets** (5 cells × 1 cor = 5 targets → +15 runs, ~135 total): the correlation
  target is the single highest-risk object in the slate (§5) and the extra seeds cost seconds.

### Wall-clock (measured in the spikes, single core, this Mac)

| unit | fit | profile (grid engine) | per (cell, seed) |
|---|---|---|---|
| zob sigma ordinary | 1.4 s | 17.8 s | ~19 s |
| zob sigma structured (phylo) | 2.2 s | 35.5 s | ~38 s (pad to 120 s for animal/relmat/spatial/phylo_interaction) |
| count mu q2 (3 targets) | 2.0 s | 75.1 s | ~77 s |
| count sigma interaction | 4.6 s | 104.9 s | ~110 s |

Serial, padded: **~1.5 h single-core for the whole 14-cell slate.** On Totoro the 70 (cell, seed)
units are embarrassingly parallel, well under the ≤100-core policy cap: **≤30 min wall-clock
end-to-end** including R startup, one `pkgload::load_all()` compile (~27 s), staging and
collection. Add the Tier-2 calibration pilots (zoi: 3 sizes × 3 seeds × 2 cells; zob mu
structured: 3 sizes × 3 seeds × 1 provider) for another ~10 min wall-clock.

**Compute is not the constraint. Review is.** 135 profile traces must each be checked against
the contract by a human/agent reviewer — that is several hours of careful work, and it is the
real budget line.

### Engine decision (must be made before the campaign, not during)

The package's default `profile_engine` for these target classes is **`"endpoint"`** (bracket-and-
bisect against `object$obj$fn`), *not* `TMB::tmbprofile()`. The contract's "trace spans both
sides" clause cannot be evidenced by the bisection engine, which produces no trace.
**Decision: the recorded endpoints come from the grid engine (`stats::profile()` →
`TMB::tmbprofile()`), one call per target; the endpoint-engine result is recorded as an
independent cross-check.** Both spikes showed the two agree to 3–4 dp, so a disagreement
beyond ~1e-2 is itself a red flag worth stopping on. This costs ~3× the endpoint engine and is
still under 30 min wall-clock.

### Per-cell evidence contract (all clauses; any single failure blocks that cell)

1. Point-fit gate **run before profiling**, same seed family: mean relative error ≤ 0.35 **and**
   no single seed > 0.35.
2. ≥5 seeds (≥8 for correlation targets).
3. `conf_status == "profile"`; lower/estimate/upper finite; `lower < estimate < upper`.
4. `convergence == 0`; `pdHess == TRUE`.
5. Not boundary- or clamp-limited: `profile.boundary == FALSE`, `message == "ok"`, no contact
   with the `[-12, 12]` log-scale clamp band.
6. Trace spans both sides and crosses the LR threshold (1.9207 on the deviance/2 scale) on
   **both** sides; unimodal under a 1e-6 monotonicity tolerance.
7. Endpoints from **one** `stats::profile()` call per target.
8. **Every seed's interval contains the true value.** One exclusion blocks the cell even if
   coverage is 4/5 and the mean passes.
9. The profiled variance component's true value is non-zero (all Tier-1 DGPs use 0.45–0.60 — fine).
10. Independent location review (Fisher). Shape checks are not location checks: the Arc 3
    precedent caught two mechanically-passing-but-wrong-location cases (mc-0423, mc-0409).

---

## 5. THE RISK

Ranked by probability × damage, each with its early warning.

**R1 — Collateral unlock (highest damage, most under-appreciated).** E1/E3 delete *predicates*,
not *cells*. Every route the predicate governed becomes profile-ready, including routes with no
ledger cell and no evidence. `zero_one_beta_sigma_q1_profile_restricted` does not constrain
`random$mu$n_re`, so a zob model with **both** a mu RE and a sigma RE also unlocks its sigma SD
target. `count_labelled_q2_profile_restricted` permits poisson × {phylo, spatial, animal,
relmat} and nbinom2 × phylo — 5 combinations, which happens to map 1:1 onto our 5 cells today,
but that coincidence is not enforced anywhere.
**Early warning / required gate:** before merging, dump `profile_targets()` for every fitted
object in the test suite, pre- and post-edit, and diff the `profile_ready` column. Any route
that flips to TRUE and is not one of the 14 must be re-fenced explicitly or accepted in writing.

**R2 — The `cor:mu:...` target reproduces the STOPPED Gaussian q2 failure.** The four Gaussian
matched-q2 cells (mc-0278/0291/0303/0315, mc-0279/0292/0304/0316) were stopped on a
correlation-target/denominator failure, root-caused in Arc 3 to ill-conditioned trees
(condition number 98,563 for `ape::rcoal()`) and finite-sample intercept/slope RE correlation up
to 0.457. Our q2 spike gave `cor = [-0.0105, 0.7024]` against true 0.50 at 64 tips — it covers,
but the lower bound is 0.01 from zero.
**Early warning:** any seed whose correlation lower bound < −0.3, whose interval width > 0.85, or
whose `profile.boundary == TRUE`. Also check tree condition number per seed *before* fitting; if
it exceeds ~10⁴, the seed is a conditioning artefact, not a method failure — fix the tree
generator, do not redesign the DGP until green.

**R3 — Structured-sigma providers other than phylo behave unlike phylo.** Only phylo was spiked.
animal/relmat/spatial/phylo_interaction carry denser precision structure (Kronecker for
phylo_interaction).
**Early warning:** seed 1 of each provider. If the point estimate's relative error exceeds 0.25,
or the profile takes >5× the phylo time, stop and pilot that provider separately rather than
running all 5 seeds.

**R4 — The mu-structured near-miss generalises to sigma-structured.** mu-phylo produced 33.6%
error with a truth-excluding CI at 32 tips × 30 obs. sigma-phylo at the same design covered
comfortably (8.2% error), so the two dpars are genuinely different — but this is n=1 per dpar.
**Early warning:** the point-fit gate. If sigma-structured seeds start landing above 0.20
relative error, the fixture is too small; raise N *before* profiling, not after.

**R5 — First-`R/`-change process risk.** Snapshot churn, `document()` drift, NEWS claim
boundaries edited too broadly.
**Early warning:** `R CMD check --as-cran` locally before push; a NEWS diff that touches routes
outside the 14 is a defect.

**R6 — Seed-family drift.** The gate and the campaign silently using different seeds, which
would void clause 1 of the contract.
**Early warning:** structural, not procedural — mandate one `se = TRUE` fit per (cell, seed)
reused for both purposes so the two cannot diverge.

---

## 6. WHAT MUST NOT HAPPEN

1. **Do not open any `coi` fence** (mc-0570, mc-0578, mc-0613, mc-0614, mc-0617). The
   2026-08-01 disposition licenses the point-fit tier only and says so in writing. Reopening
   requires a fresh, explicit owner decision naming interval claims, not a campaign result.
2. **Do not open the Tier-2 fences "while we're in there."** The `zoi` and structured-`mu`
   predicates are in the same functions being edited, and narrowing rather than deleting is
   deliberate. Widening the edit to 25 cells because the diff is adjacent is exactly the
   failure this memo exists to prevent.
3. **Do not delete a fence predicate whose governed route set is larger than its ledger cell
   set** without running the R1 diff first.
4. **Do not report a cell as promoted on mean statistics.** Any single seed >0.35 relative
   error, or any single interval excluding the truth, blocks that cell. 4/5 coverage is a
   block, not a 80% pass.
5. **Do not redesign the DGP until it goes green.** If a seed fails, root-cause it (tree
   conditioning, RE-draw correlation, boundary counts, dispersion/SD confound) the way Arc 3
   did. Regenerating data until the gate passes is fabrication with extra steps.
6. **Do not substitute the endpoint (bisection) engine for the recorded profile endpoints**
   without saying so explicitly in the receipt. It produces no trace and cannot evidence the
   "spans both sides" clause.
7. **Do not describe any promoted cell as coverage-, inference-, or CRAN-ready.** The target
   tier is `interval_feasible`, which means *this route can produce an honest profile interval
   at the tested design*. It is not a coverage claim, not a guarantee at other N, and not a
   package-level support statement.
8. **Do not let the `mu`/`sigma` shared note tokens be retired.** Retiring
   `point_fit_only_zero_one_beta_phylo_q1` (etc.) would silently unfence structured `mu`.
9. **Do not run this campaign on GitHub Actions or store its outputs as Actions artifacts**
   (D-50). Totoro, results local.
10. **Do not claim the arc is done from a green campaign alone.** The Fisher location review is
    a contract clause, not a courtesy; it has already caught two mechanically-passing failures
    in this same programme.

---

## Turnkey handoff for the execution lane

1. Branch. Apply E1–E4 to `R/profile.R` (§3). Run the **R1 pre/post `profile_ready` diff** —
   this is the gate on the source change, before any campaign.
2. `devtools::document()`; update the 9 test call sites in §3.2; add one `se = TRUE` interval
   test per promoted group; `devtools::test()`; `R CMD check --as-cran`.
3. Build the campaign runner: 14 cells × 5 seeds (8 for cor targets), one `se = TRUE` fit per
   (cell, seed) feeding both the gate and `stats::profile()`. Reuse the DGP parameterizations
   from `tools/run-lane-c-c1-nb2-phylo-q2-local-recovery.R`,
   `tools/run-lane-c-c2-poisson-{phylo,provider}-q2-local-recovery.R`,
   `tools/run-lane-c-nb2-sigma-phylo-interaction-local-recovery.R`,
   `tools/run-lane-c-c12-zinb-sigma-control-local-recovery.R`, and the zob helpers in
   `tests/testthat/test-zero-one-beta.R:133-225`. None of these currently computes an SE;
   all need a profile path added.
4. Run on Totoro (≤100 cores). Expect ≤30 min wall-clock.
5. Review all 135 traces against the §4 contract. Fisher location review. Then ledger + NEWS.
6. Separately and later: the Tier-2 calibration pilots. They are ~10 min of compute and would
   convert some or all of the 11 held cells into a second, well-founded slate.
