# D-43 panel — Noether (estimand & mathematical consistency)

**Reader:** the D-43 panel deciding whether any of the 18 `missing_response` G3 rows may be promoted.

**Verdict: PROMOTE-WITH-CAVEATS**, limited to the seven candidate routes × three rungs (132 cells).
**My prior objection is DISCHARGED.**

## 1. Whether my prior objection is discharged, and what discharges it

It is discharged — and not by the design stamp alone, which is only a label, but by **bit-exact
reproduction of artifact records from the stamped design**.

The stamp itself checks out. All 348,000 records carry `centre_random_effects=FALSE`; zero NA, zero
blank, one unique state, zero `UNAUTHENTICATED` (`noether1.R`). It is written at generation time, on
the compute node: `.mr_stamp_design()` (`inst/sim/R/sim_missing_response_g4g5.R:65-68`) is called from
every record-producing path — `mr_g4_add_mask_receipt` (`:581`), `mr_g5_failure_record` (`:1158`), and
the fixture-failure early return (`:1203`) — so no path can emit an unstamped record. The array driver
`~/g5run/cell.R` **fails closed**: it `stop()`s unless `MR_G5_CENTRE_RANDOM_EFFECTS` is explicitly
`TRUE` or `FALSE`, then sets the option before any data is drawn. `mr_g4g5_check_design_agreement`
(`:1258-1296`) hard-errors on disagreeing states.

But a provenance field can only be trusted if it corresponds to the data, so I reproduced records:

```
gaussian fixef:mu:(Intercept) 1x rep 7, seed 467450510
  artifact      CI [0.054606037405, 0.611126225783]
  centre=FALSE  CI [0.054606037405, 0.611126225783]   abs diff 0, 0
  centre=TRUE   CI [-0.004369950231, 0.552150238133]  abs diff -0.058976, -0.058976
```

The record reproduces to the last bit under the stamped design and **fails to reproduce under the
other one**. Extended to four records across four candidate routes with `trace = TRUE` (the campaign
setting), all 16 compared fields — `truth`, `conf.low`, `conf.high`, `conf.status`,
`profile.boundary`, `interval_usable`, `truth_contained`, `boundary_or_clamp`, `fit_status`,
`fit_converged`, `pdHess`, `mask_fraction`, `mask_any_response_rows`, `design_state`, `target_scale`,
`target_class` — were **identical, 16/16, in all four** (`noether7.R`):

| route | parm | rung | rep | seed | fields identical |
|---|---|---|---|---|---|
| gaussian | `fixef:mu:(Intercept)` | 1x | 7 | 467450510 | 16/16 |
| gaussian | `sd:mu:(1 \| id)` | 0.5x | 23 | 711304931 | 16/16 |
| biv_gaussian | `fixef:rho12:(Intercept)` | 1x | 11 | 1034375140 | 16/16 |
| zi_poisson | `fixef:zi:z` | 2x | 5 | 293402038 | 16/16 |

The cluster source is byte-identical to the committed file
(`md5 = 5c5de607a15d67de628860e1205ab800` both sides), so this reproduced the committed code, not a
cluster-local variant. Provenance is now **verified**, not inferred from the results it validates.
That was the whole of my objection.

## 2. Independent verification performed

Scripts staged to `~/g5run/noether{1..8}.R` and run with
`module load StdEnv/2023 r-bundle-bioconductor/3.21; R_LIBS_USER=$HOME/R/g4g5-lib`.

- **Design (`noether1.R`).** 348,000 records; `table(design_state)` → one level,
  `centre_random_effects=FALSE`, count 348000; NA 0; blank 0; `UNAUTHENTICATED` 0.
- **Coverage recomputed from records (`noether2.R`).** For the 132 candidate cells, recomputed
  coverage from `truth_contained` / `interval_usable` and compared to `$summary`:
  **max |difference| = 0 over 132 cells.** Every cell n = 1200, 1200 distinct seeds, 1200 distinct
  replicates, exactly one distinct `truth`. Min coverage 0.93167, max 0.96417, **0 cells outside
  [0.925, 0.975]**.
- **Truth × scale (`noether3.R`, `noether4.R`).** All 44 distinct (route, parm) pairs for the seven
  candidates, cross-checked against the DGP source.
- **Rung semantics (`noether3.R`).** Median CI half-width ratios per target.
- **Registry / `n_attempt` (`noether4.R`).** `registry$cells` inside the artifact, absent-cell check,
  calibration flags.
- **Failure attribution (`noether5.R`).** All 43 calibration failures tabulated by route and reason.
- **Interval method (`noether8.R`).** `interval_method` × `target_class` × `conf.status` across all
  348,000 records and per-parm for biv_gaussian.

## 3. Estimand identity per candidate route

**Truth constants — all 44 verified against the DGP, on the scale of the estimate they are compared
against.** `target_scale` is `link` for every `fixed-effect` target and `response` for
`random-effect-sd`, `random-effect-correlation`, `residual-correlation`, and `distributional-scale`.
The non-obvious ones are right, which is the real test:

| route | check | source | artifact |
|---|---|---|---|
| gaussian | `fixef:sigma:(Intercept)`, DGP `exp(-0.25 + 0.22 z)` | `:192-197` | −0.25 link ✓ |
| gaussian | `sd:mu:(1 \| id)`, DGP `rnorm(n_id, sd = 0.7)` | `:185` | 0.70 response ✓ |
| biv_gaussian | `fixef:sigma1:(Intercept)` = `log(0.35)` | `:298` | −1.0498221245 link ✓ |
| biv_gaussian | `fixef:rho12:(Intercept)` = `atanh(0.25)` | `:298` | 0.2554128119 link ✓ |
| biv_gaussian | dual `rho12` = 0.25 | `:299` | 0.25 response ✓ |
| biv_gaussian | `cor(...)` from `u2 = 0.45 u1 + sqrt(1−0.45²) ε` | `:286, :301` | 0.45 response ✓ |
| gamma | `mu = c(.15,.36)`, `sigma = c(−.85,.16)`, `sd = .48`; `rgamma(shape=1/σ², scale=exp(η)σ²)` → mean `exp(η)` | `:350-362` | 0.15/0.36/−0.85/0.16 link, 0.48 response ✓ |
| beta_binomial | `plogis(−.25+.65x+u)`, `exp(−1.35+.15z)`, `sd=.60` | `:429-436` | ✓ |
| binomial | intercept −0.30, slope 1.10 | `:490` | ✓ |
| zero_one_beta | mu/sigma/zoi/coi = (−.20,.65)/(−.85,.22)/(−1,.45)/(.15,−.55) | `:404-409` | 8/8 link ✓ |
| zi_poisson | mu (.30,−.35,.25), zi (−.90,.55,−.45) | `:474` | 6/6 link ✓ |

Neither of the two previously wrong-scale constants is in a candidate route — the tweedie
`fixef:nu:(Intercept)` = `qlogis(1.35−1)` fix (`:396-401`) and the cumulative_logit
`log(.75−(−.90))` log-increment fix (`:443-446`) are both non-candidates. The candidates were never
exposed to that class of error and I found no instance of it in them.

`parm` names the parameter whose truth is covered: `mr_g4_target_manifest` enforces
`setequal(targets$parm, names(truth))` (`:632-634`) and assigns `out$truth <- unname(truth[out$parm])`
(`:638`) — a name-keyed lookup, not positional. Every candidate cell holds exactly one distinct
`truth` across its 1200 replicates.

**Rungs index information, verified behaviourally, not asserted.** Multipliers scale the number of
groups at fixed within-group replication (`mr_g4g5_group_count`, `:167-171`) or total n. If that is a
true information multiplier, CI half-width should scale as `1/sqrt(2) = 0.70711` per rung. Median
half-width ratios across all 44 candidate targets:

```
median(halfwidth 1x / halfwidth 0.5x) = 0.7055
median(halfwidth 2x / halfwidth 1x)   = 0.7060
```

Per-target values run 0.693–0.727. The rungs are what they claim to be.

**Candidate exhaustiveness, verified without the registry.** The seven routes contribute 44 canonical
targets (gaussian 5, biv_gaussian 13, gamma 5, beta_binomial 5, binomial 2, zero_one_beta 8,
zi_poisson 6) — exactly the entries of their frozen `truth` vectors. 44 × 3 rungs = 132, and all 132
are present at 1200 records each. This is the full cross product, established from the DGP source
rather than from the artifact's own registry, so the G4-feasibility conditioning that governs
admission screened nothing out for these routes.

## 4. The claimed fifth defect — the stated mechanism is wrong; here is the actual one

The exhaustiveness note (`docs/dev-log/2026-08-11-g5-admission-set-exhaustiveness.md:62-70`) asserted
that in `$summary` the four truncated cells "carry `n_planned = 1200` **and `n_attempt = 1200`**"
while the underlying files hold 818–1132 rows, and concluded "`n_attempt` should be measured from the
records." The coordinator has accepted this correction; the derivation is mine and is recorded here.

**Refuted on every leg** (`noether2.R`, `noether4.R`):

- Only one `beta` 2x row exists in `$summary` — `sd:mu:(1 | id)`, genuinely complete (1200 records,
  1200 usable, coverage 0.9408). The four truncated cells **are not in `$summary` at all**.
- Across all 290 summary rows, **`n_attempt` equals the measured record count for every cell**
  (cells where they differ: 0). It is already measured, not asserted: `n_attempt = nrow(x)` at `:927`,
  computed inside the aggregation over the records themselves.
- `registry$cells` **inside the artifact has 290 rows, not 294** — its `beta` block lists 0.5x×5,
  1x×5, and 2x `sd:mu:(1 | id)` only. Registry cells absent from records: 0.

So the proposed fix targets a field that is already correct, and the four cells never reached the
reconciler in the way the note describes.

**The actual mechanism, stated plainly.** The artifact does not carry the frozen 294-cell intent; it
carries a registry that has already been narrowed to the cells that reconciled. Completeness is then
checked *within* that narrowed set — `calibration_complete = (n_attempt == n_planned)` at `:960` —
and passes 290/290. It passes **vacuously**. A cell that ran 818 of 1200 attempts does not fail the
completeness gate; it leaves the population the gate is computed over. Truncation is therefore
invisible not because the denominator is wrong, but because the row is gone.

This is the same failure *shape* as the other four defects — the check cannot see the thing that is
wrong — but the consequence is sharper than the note claimed: **the artifact cannot certify its own
exhaustiveness.** Any 294-vs-290 comparison must be made against the frozen registry from outside the
artifact, because the embedded one is a post-hoc record of what survived. The remedy is not to
re-measure `n_attempt`; it is to **embed the frozen pre-campaign registry alongside the reconciled
one and gate on set equality between them**, so an absent cell is a failure rather than a silence.

This does not reach the promotion set: I established candidate exhaustiveness independently in §3,
from the frozen `truth` vectors rather than from the registry. But the note's §"A fifth defect" must
not enter the ledger or a design doc as originally written.

## 5. The conditioning question — vacuous for the candidates, confirmed

Conditioning coverage on `interval_usable == TRUE` makes the reported number a conditional quantity
wherever some intervals fail, and 42 of 43 campaign failures are `unusable_interval`. For the seven
candidates it is inert, confirmed three ways (`noether2.R`, `noether5.R`):

- **All 132 candidate cells are 1200/1200 usable.** Cells with usable ≠ 1200: 0.
- **Conditional and unconditional coverage are identical.** Cells where
  `mean(contained | usable)` differs from `sum(contained)/1200`: **0**, to machine precision.
- **No candidate cell appears among the 43 failures.** They fall in beta (3), hurdle_nbinom2 (1),
  nbinom2 (6), poisson (2), skew_normal (3), student (15), truncated_nbinom2 (6), tweedie (1),
  zi_nbinom2 (6). The single non-`unusable_interval` failure is
  `poisson fixef:mu:(Intercept)` 0.5x at 0.9217 — not a candidate.

All 132 candidate cells pass `calibration_complete`, `_available`, `_precise`, and `_in_band`.
The reported coverage for the candidates is the unconditional quantity claimed.

One related note: `interval_usable` is a **compound** flag. `mr_g4_validate_record` (`:701-716`)
requires `trace_requested == TRUE` in addition to a finite two-sided profile interval, so it means
"a fully audited profile interval", not "an interval was computable". Inert here (100% TRUE) but it
should not be read as a pure interval property. I hit this directly: a `trace = FALSE` reproduction
returned `truth_contained = FALSE` on an interval that plainly contains the truth. The campaign runs
`trace = TRUE` (`~/g5run/cell.R`), and the `trace = TRUE` reproductions matched 16/16.

## 6. Ruling on Rose's profile/Wald question

Rose asks whether mixing profile and Wald interval methods within one promoted route — specifically
biv_gaussian's derived/reporting-scale targets `rho12`, `sigma1`, `sigma2`, `cor:mu:*` — is
estimand-acceptable, given the fallback at `:639` and `:713`.

**First, the factual answer: no mixing occurred, so the ruling does not affect this promotion.**
Verified across the entire artifact (`noether8.R`):

```
records with interval_method == "wald" : 0   (of 348,000)
records with conf.status    == "wald"  : 0   (of 348,000)
biv_gaussian: all 13 parms profile_ready = TRUE, interval_method = "profile",
              conf.status = "profile" for all 46,800 records
```

Every one of biv_gaussian's four derived targets — `rho12` (residual-correlation, response),
`sigma1`/`sigma2` (distributional-scale, response), and
`cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)` (random-effect-correlation, response) — is
`profile_ready = TRUE` and took the profile branch on every replicate. The Wald branch exists in code
but is dead in this campaign. Rose's premise is correct about the code and incorrect about the data.

**Second, the ruling on the principle, which I am asked to make and do make: mixing is NOT acceptable
within one promoted row.** The reason is not that the estimand differs — it does not. The parameter
and its truth are identical either way. The reason is that **coverage is a property of the interval
procedure, not of the parameter.** A row asserting "biv_gaussian covers at 0.95" while some cells used
profile and others Wald is asserting one calibration for two procedures, and the reader cannot tell
which one the number describes.

That distinction is load-bearing exactly where the fallback would fire. These four targets are
constrained and reported on the response scale: `rho12` and the RE correlation live in (−1, 1),
`sigma1`/`sigma2` in (0, ∞). A Wald interval is symmetric on a scale where the sampling distribution
is skewed and the parameter is bounded, so it can undercover asymmetrically and can place endpoints
outside the parameter space. Profile intervals are reparameterization-equivariant and respect the
boundary. The two procedures have materially different finite-sample coverage precisely on the
targets in question, so pooling them would hide the difference under a route-level average.

**Therefore:** `interval_method` is part of a promoted row's identity, not an implementation detail.
If any future rerun takes the Wald branch for any cell, that cell must be promoted as a separate row,
or the row must carry the method explicitly. For this campaign no split is required, because the set
of Wald cells is empty.

**Third, a latent hazard this exposed, which I flag as unguarded.** `interval_method` is *derived at
runtime* from the fitted object — `out$interval_method <- ifelse(out$profile_ready, "profile", "wald")`
(`:639`), where `profile_ready` comes from `profile_targets(fit)`. It is not frozen in the registry
and it is not stamped. If the package's `profile_ready` flags change, a future campaign silently
switches interval procedure for some targets, and nothing in the artifact would say so.
`mr_g4_validate_target_manifest` (`:653-655`) checks only
`profile_ready == (interval_method == "profile")`, which is a tautology given `:639` and cannot detect
the change. This is the **same class of defect as the centring switch**: a property of the experiment
determined by ambient state rather than declared and verified. It did not bite here — I confirmed 0
Wald records — but `interval_method` deserves the `design_state` treatment: freeze it in the registry
and hard-error when the runtime value disagrees.

## 7. Caveats attached to the PROMOTE

1. **Scope.** Seven routes × three rungs = 132 cells only: gaussian, biv_gaussian, gamma,
   beta_binomial, binomial, zero_one_beta, zi_poisson. `beta` must not be promoted — 4 of 15 cells
   are unreconciled and array 18826926 is actively rewriting them; its "3 fail / 8 pass" covers
   11/15 and is not a route result.
2. **Correct the exhaustiveness note's §"A fifth defect" before citing it** (§4 above), and record the
   silent registry-narrowing mechanism in its place.
3. **`biv_gaussian fixef:mu2:(Intercept)` 1x = 0.9317 (MCSE 0.00728).** The only candidate cell whose
   lower 1-MCSE bound (0.9244) falls below the band, and ~2.5 MCSE below nominal 0.95. This is not a
   scale or estimand error — truth (−0.15), link scale, and bit-exact reproduction all check out. It
   is genuine ~1.8-point finite-sample undercoverage and should be named in the ledger rather than
   absorbed into a route-level pass.
4. **State the admission conditioning explicitly.** The G5 set is drawn from G4-feasible targets. For
   these seven that is the full canonical target set, so nothing was screened out — but the promoted
   claim should not be read as a route-wide guarantee covering targets that never entered.
5. **The promoted rows are profile-interval coverage.** Per §6, record `interval_method = profile` as
   part of the claim, not as background.
6. **Residual, non-blocking.** The design stamp reads an option at record-construction time rather
   than being derived from the realized `u`, so it is formally desynchronizable if the option changed
   mid-attempt. Impossible under the single-threaded fail-closed driver, and the bit-exact
   reproductions close it empirically for the records tested.

## 8. What would make me withhold again

- `beta` included in the promotion set, at any rung.
- The exhaustiveness note's §"A fifth defect" carried into the ledger or a design doc as written.
- Any candidate cell found below 100% interval-usable, which would silently turn its reported
  coverage into a conditional quantity.
- Any promoted row mixing profile and Wald cells, per the §6 ruling.
- A future artifact whose embedded registry is again the reconciled subset rather than the frozen
  intent, with no external 294-cell comparison performed.
