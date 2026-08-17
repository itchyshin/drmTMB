# ADEMP freeze — `mc-0576` zero-one-beta ordinary sigma slope

**Status:** Frozen design sheet only. **Do not launch** a smoke, Totoro job, DRAC
array, or any campaign fit from this document. Compute host (Totoro or DRAC)
waits for Shinichi's explicit GO.

**Reader:** the next Cursor / Claude / Codex agent who would otherwise invent
an `M` / `SD` / `n_each` grid for `mc-0576` coverage.

**Purpose:** lock the aims, data-generating process, estimand, methods, and
profile-coverage gate for one already-admitted cell before anyone spends
compute. The cell is `interval_feasible` on `origin/main`. It has no coverage
claim. This sheet does not move the ledger.

Skeleton: design 257 test-plan ADEMP headings (`Aim` / `Data-generating process`
/ `Estimand` / `Methods` / `Performance` / `Compute gate`) on
`docs/design/257-nongaussian-ordinary-correlated-slope.md` (PR #1057; structure
only — that note is the correlated `(1 + x | g)` neighbour, not this cell).
Gate language: Arc 4c S0
(`docs/dev-log/2026-07-19-arc4c-three-cell-mu-slope-drac-s0.md`).
Numbers come from the Lane C Z5 recovery constructor and the 135-trace
interval campaign, not from Arc 4c's `mu`-slope fixture and not from Gamma
`mc-0242`.

### Frozen contract (do not launch)

| Quantity | Frozen value |
| --- | --- |
| Cell | `mc-0576` (`interval_feasible`; no coverage) |
| Formula | `bf(y ~ x, sigma ~ x + (0 + x \| id), zoi ~ 1, coi ~ 1)` |
| Estimand | `sd:sigma:(0 + x \| id)` |
| True SD | **0.45** |
| `n_each` | **50** |
| `M` | **8, 16, 32, 64** (`M = 8` exploratory) |
| Later `N` (not authorized) | 1200 attempted / `M` |
| First-campaign ceiling | `inference_ready_with_caveats` — never `supported` |
| Host | Totoro or DRAC — **wait for owner GO** |

## Do not launch

This freeze authorizes **no** fit. It does not authorize a one-replicate
smoke, a Totoro `parallel` job, a DRAC array, a ledger edit, or a claim-tier
change. A later coverage campaign needs a separate owner GO that names the
host (Totoro or DRAC) and the immutable source SHA. Until that GO exists,
treat every runner path below as a contract, not a command.

## Cell on `origin/main` (read 2026-08-16)

```text
mc-0576  family=zero_one_beta  model_type=15  dpar=sigma
         effect=ordinary_re_slope  estimator=ML
         capability=implemented  evidence_tier=interval_feasible
         primary_evidence=ev-mc-0576-135trace-profile
         next_gate=Coverage/calibration remain out of scope; a separate goal is required.
```

Five-seed Totoro 135-trace (source SHA `6618e4b30303f7815b272f709ac2c8d09089132d`)
produced finite profile intervals that all bracketed true SD 0.45. That is
interval existence plus truth-bracketing at one design. It is not coverage,
calibration, Type I, or `inference_ready_with_caveats`.

## Neighbours this sheet is not

| Cell / syntax | What it is | Why it is out |
| --- | --- | --- |
| `mc-0575` | `zero_one_beta` **`mu`** independent slope `y ~ x + (0 + x \| id)` | Location slope. Arc 4c S0 already owns that DGP (`n_each = 15`, SD 0.50). |
| `mc-0568` | `zero_one_beta` **`sigma` intercept** `(1 \| id)` | Different estimand. Ordinary intercept, not a slope. |
| `(1 + x \| id)` | Correlated intercept-plus-slope | Design 257 / PRs #1057–#1060. Stay off that code. |
| `mc-0580` | REML twin of this cell | `rejected_by_design`. REML 4b/4c is not in this arc. |
| Wave 3 / NB2 | Other-family correlated or NB2 sigma work | Not in this arc. |

The fitted formula for this cell is the independent scale slope

```r
bf(y ~ x, sigma ~ x + (0 + x | id), zoi ~ 1, coi ~ 1)
```

with `family = zero_one_beta()`. The gate that admits the slope requires the
fixed `sigma` RHS and the random multiplier to be the same raw symbol `x`.
That is not a correlated block and not a `mu` slope.

## A — Aims

Primary aim, **later** and only after owner GO: measure profile-interval
coverage of the ordinary `sigma` slope random-effect SD for `mc-0576` under
ML-Laplace, on the frozen DGP below, at each frozen `M`.

Secondary aim: keep the claim fenced. A passing campaign may support
`inference_ready_with_caveats` on the exact tested `(M, SD, n_each)` cells.
The first campaign cannot support `supported`, REML, AGHQ, a correlated
`(1 + x | id)` block, `mu`/`zoi`/`coi` random effects, structured providers,
or a different `n_each` or true SD.

This document's only present aim is to freeze that contract.

## D — Data-generating process (frozen)

Reuse the 135-trace / Lane C Z5 constructor. Do not silently switch to the
Arc 4c zero-one-beta **`mu`** slope DGP (`n_each = 15`, SD 0.50, 15%
boundary) or to Gamma `mc-0242` (`n_each = 12`, SD 0.40).

For groups `j = 1, …, M` and observations `k = 1, …, n_each`:

```text
x_{jk}     = within-group-centred, then globally scaled to sd 1
b_j        ~ Normal(0, 0.45^2)          # iid, uncentred (population SD)
logit(mu_{jk}) = -0.15 + 0.35 x_{jk}    # fixed mu only
log(sigma_{jk}) = -1 + b_j x_{jk}       # true fixed sigma slope = 0
zoi        = logit^{-1}(-0.7)           # ≈ 0.332 structural 0/1
coi        = logit^{-1}(0.1)            # ≈ 0.525 P(one | boundary)
boundary_{jk} ~ Bernoulli(zoi)
y_{jk} | interior ~ Beta(mu / sigma^2, (1 - mu) / sigma^2)
y_{jk} | boundary ~ Bernoulli(coi)
```

Family `sigma` is the interior-beta scale on a log link. Interior precision
is `phi = 1 / sigma^2`. That `sigma` is not a meta-analysis `tau`, and it is
not the `mu`-slope SD of `mc-0575`.

`x` is within-group centred because a slope with no within-group variation in
`x` is unidentified. The random intercepts `b_j` stay **uncentred**: the
coverage estimand is the population SD 0.45, not the realised finite-`M`
sample SD. That matches Arc 4c's coverage-vs-recovery distinction on the
random-effect draw, while keeping the 135-trace `x` transform.

The fitted model still includes the fixed `sigma ~ x` term. The true fixed
sigma slope is 0; the symbol must remain because the admission gate matches
raw expressions, not merely variable names.

### Frozen `(M, SD, n_each)`

| Quantity | Frozen value | Provenance | Do not substitute |
| --- | ---: | --- | --- |
| True SD | **0.45** | Lane C Z5 `tau = 0.45`; 135-trace `true_value = 0.45` | Arc 4c `mu` SD 0.50; Gamma `mc-0242` SD 0.40 |
| `n_each` | **50** | Z5 / 135-trace `each = 50L` | Arc 4c ZO-beta `mu` 15; `mc-0242` 12 |
| `M` grid | **8, 16, 32, 64** | Arc 4c / `mc-0242` ladder, applied to this DGP | A single untested `M`, or the recovery-only `M = 32` without the ladder |

`M = 32` is the interval-feasible fixture (four-seed local recovery and five
135-trace profiles). It is the primary certified-candidate cell. `M = 8` is
exploratory only: Gamma sigma-intercept `mc-0242` already excluded `M = 8`,
and a scale **slope** with ~33% structural 0/1 observations is not a more
informative input. `M = 16` and `M = 64` complete the ladder so a later
verdict can name a floor instead of a single `M`.

Do not change `n_each` when `M` changes. Scale-side slopes need within-group
replication; dropping to 12 or 15 would be a new DGP.

## E — Estimand (frozen)

Primary estimand: the population SD of the ordinary `sigma` slope random
effect, truth **0.45**, scored on the natural RE-SD scale against

```r
confint(fit, parm = "sd:sigma:(0 + x | id)", method = "profile")
```

The matching Wald interval on `log_sd_sigma` is a comparator only. It cannot
rescue a profile failure or change a coverage verdict.

Fixed `mu` / `sigma` / `zoi` / `coi` coefficients are nuisance. Do not
profile them for this cell.

## M — Methods (frozen; not launched)

Estimator: drmTMB ML with first-order Laplace integration. Keep
`estimator = "ML"` on any later ledger edit; a new token would make the
family-map slope appear absent.

Interval engine for recorded endpoints: one `stats::profile()` →
`TMB::tmbprofile` grid call per replicate, the same engine as the 135-trace
receipts. Endpoint-engine disagreement beyond about `1e-2` is a stop, not a
silent prefer. Compute `clamp_limited` from the profile path; do not
hard-code `FALSE`.

Intended later campaign size, **frozen so nobody invents a smaller N after
seeing results**, and **not authorized to run**: `N = 1200` attempted
replicates per `M`. That is 4 × 1200 = 4,800 attempted fits. Denominators
are never pooled across `M`.

Comparators are diagnostic, not gates: 135-trace seed-level receipts at
`M = 32`, and the Lane C Z5 four-seed point-fit relative-error envelope
(mean 0.0613 at the same DGP). `glmmTMB` / `glmer` are not required for a
first `inference_ready_with_caveats` campaign on this cell.

## P — Performance gates (profile coverage; later)

Reuse the Arc 4c S0 / `mc-0242` decision rule. A cell-`M` either earns a
separately fenced `inference_ready_with_caveats` claim or stays
`interval_feasible` with the negative evidence recorded.

For each `M`, report all-attempts and conditional coverage separately:
`hits / 1200` (primary; a noncomputable interval is noncoverage) and
`hits / n_profile_finite` (diagnostic only), each with MCSE and an exact
binomial 95% interval. Also report finite-profile availability
`n_profile_finite / 1200`, fit / convergence / Hessian / profile failures,
below-lower and above-upper misses, profile width, mean RE-SD relative
bias, and zero-one-beta interior / boundary counts plus invalid-interior
failures.

1. Profile availability 1.000 is clean. `>= 0.99` can be promoted only with
   every failure disclosed and primary all-attempts coverage meeting (2).
   Below 0.99, any unrecorded failure, or a failed smoke withholds that `M`.
2. Calibration passes when the primary all-attempts exact-binomial interval
   intersects `[0.925, 0.975]`, or when its lower limit exceeds 0.975
   (labelled conservative, never nominal). It withholds when the upper limit
   is below 0.925. Conditional-on-finite coverage cannot rescue an
   attempted-denominator failure.
3. Let `A` be the acceptable non-exploratory rungs. Promotion requires `64`
   in `A` and `A` to be a contiguous suffix of `{16, 32, 64}`. The
   deployment floor is the smallest member of that suffix. A hole or an
   unacceptable `M = 64` positive control withholds promotion pending
   diagnosis. A floor is **firmly certified** only when its primary exact
   interval lies wholly inside `[0.925, 0.975]`; boundary-overlap and
   conservative suffixes support at most `inference_ready_with_caveats`.
   `M = 8` is exploratory and never sets the floor.
4. Pre-registered diagnostic: ML-Laplace's low RE-SD bias predicts
   predominantly above-upper misses at small `M`. The opposite direction is
   a red flag, not an ad-hoc promotion.

Expected floor is `M >= 16` or `M >= 32`, not a promise. Zero-one beta has
fewer interior observations than a continuous scale model (`zoi ≈ 0.33` here,
not Arc 4c's 15%). Scale slopes also need within-group `x` variation. Those
are reasons the frozen `n_each` stays 50, not reasons to move the gate after
results are known.

## Claim ceiling

Later, after a launched campaign, D-43 review, and a passing `M` set, the
maximum first-campaign claim is `inference_ready_with_caveats` on the exact
tested `(M, SD = 0.45, n_each = 50)` cells. **`supported` is forbidden** in
the first campaign. `interval_feasible` remains the current tier until that
review.

Keep `estimator = "ML"`. Do not open REML, AGHQ, Wave 3, NB2, or correlated
`(1 + x | id)` from this sheet.

## Compute gate — Totoro or DRAC? Wait for owner GO

Ask “Totoro or DRAC?” before any recovery or coverage run (D-50). Never
GitHub Actions; never Actions artifacts.

This sheet does **not** choose the host. 135-trace profiles at `M = 32`,
`n_each = 50` cost about 55–95 seconds per seed after a ~7 second fit. A
later 4 × 1200 profile campaign is large enough that Totoro (fast CPU,
≤100 cores) or a DRAC array could both be reasonable. The owner names the
host in the GO. Until then:

1. **Local** docs and ledger reads only. No new R or C++.
2. **Smoke** (one replicate per `M` on the exact frozen DGP) only after GO.
   Stop that `M` if the smoke does not converge (`convergence == 0`,
   `pdHess = TRUE`) with a finite in-range profile.
3. **Campaign** only after smoke, this frozen sheet, and the same GO. Do not
   scale around a failed smoke.

## Explicit stop boundary

Planning only. Do not run the smoke, compile on a compute node, submit an
array, or alter ledger status until Shinichi explicitly approves a reviewed
plan that cites this freeze.

**Not in this arc:** the `N ≈ 1200` run; Wave 3; NB2 code; REML 4b/4c;
PRs #1033 / #1059 / #1060.

## Provenance

- Ledger row: `origin/main` `docs/dev-log/dashboard/capability-ledger/cells.tsv` `mc-0576`.
- Recovery DGP: `tools/run-lane-c-zob-sigma-slope-local-recovery.R`
  (`simulate_zoib_sigma_slope`, `tau = 0.45`, `n_group = 32`, `n_each = 50`).
- Interval DGP: `tools/run-135-trace-campaign.R` cell `mc-0576`
  (`32L` groups, `50L` each, `sd = 0.45`, target `sd:sigma:(0 + x | id)`).
- Receipts: `docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/reconcile/mc-0576-reconcile.tsv`.
- Gate language: `docs/dev-log/2026-07-19-arc4c-three-cell-mu-slope-drac-s0.md`;
  `scratchpad/mc0242-gamma-sigma-gate-spec.md` (Gamma intercept analogue only).
- ADEMP skeleton: design 257 test-plan block
  (`docs/design/257-nongaussian-ordinary-correlated-slope.md`, PR #1057;
  structure only; this cell is independent `(0 + x | id)`).
