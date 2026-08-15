# Phase 19 re-gate of the scale repair (Noether, fresh adversarial pass)

Reader: Ada, who rewrote `PR2-build-plan.md`, and whoever builds PR 2 from it.
Purpose: decide whether the repair actually fixed the conversions I refuted, whether
it broke any conversion that survived, and whether it introduced new defects of the
same class it was repairing.

Method. I did not accept the plan's word on anything. For the `rho12` link I re-derived
the transform from `src/` and `R/` by grep, then measured `predict()` against both
candidate forms on a live fit. For each of N2–N6 I opened the file the plan cites and
checked the line numbers land on the rows claimed. For non-corruption I rebuilt four
previously CONFIRMED conversions from the density in a **freshly written script**
(`scratchpad/regate.R`), not by re-running the earlier `noether-scales*.R`.

Environment: worktree `.worktrees/external-oracle`, branch
`claude/external-oracle-intervals`, `4530fd71a`, drmTMB 0.7.0 (`DESCRIPTION:3`) via
`devtools::load_all(".", quiet = TRUE)`; R 4.6.0; all runs under
`R_PROFILE_USER=/dev/null Rscript --no-init-file`. Every fit finished in seconds;
nothing here needed compute.

## Verdict summary

| Item | Prior verdict | Re-gate verdict |
| --- | --- | --- |
| **N1** `rho12` link stated as plain `atanh`/`tanh` | REFUTED | **FIXED**, and independently re-verified from source and from `predict()`. One citation defect remains (R3). |
| **N2** two `tanh` values misrounded | MINOR | **FIXED in the body** (§4.2 gives six decimals and bans the old digits). The fix table at `:1037` still quotes plain-`tanh` values as "correct" — R2. |
| **N3** `abs diff` reported as `1e-6` | MINOR | **FIXED as an instruction, but the replacement number I supplied is itself wrong.** See S1 — self-correction. |
| **N4** doc-158 line numbers point at the extract | CITATION | **FIXED.** All three repointed line numbers verified in place. |
| **N5** doc-242 citation off by five lines | CITATION | **FIXED.** Verified in place. |
| **N6** coverage claim over-broad | SCOPE | **FIXED**, and carried further than I asked (§7, §10.2 items 2–4). |
| Four previously CONFIRMED conversions | CONFIRMED | **All four reproduce exactly.** Nothing was corrupted by the rewrite. |

Two new findings and one self-correction follow. **R1 is material**: the plan attaches
my density-verification log-likelihoods to two models I never fitted, and for those
models the identity it claims provably does not hold.

---

## Part 1 — N1: the `rho12` link, verified from source rather than from the plan

The plan states the link at `PR2-build-plan.md:36` and `:569-580` as
`rho12 = 0.999999 * tanh(eta_rho12)`. I verified this three independent ways.

**From the compiled kernel.** `grep -rn "tanh" src/*.cpp` returns exactly two sites
that build a `rho12` vector, and both guard:

```
src/drmTMB.cpp:670  : vector<Type> rho12 = Type(0.999999) * tanh(eta_rho12);
src/drmTMB.cpp:4260 : vector<Type> rho12 = Type(0.999999) * tanh(eta_rho12);
```

**From the R metadata.** `R/family.R:34` records `rho12 = "atanh_guarded"` in
`biv_gaussian()`'s `links`; `R/family.R:13-15` documents *"fitted response-scale
correlations use `rho12 = 0.999999 * tanh(eta_rho12)`"*. The single back-transform
helper is `rho_response <- function(eta, guard = 0.999999) guard * tanh(eta)`
(`R/methods.R:5809-5811`), and `DRM_CORR_GUARD <- 0.999999` at `R/profile.R:1178`.

**From the fitted object.** Refitting the exact c10 model (`n = 333`, 146/68/119):

```
eta_rho12                     : 0.406880709656 0.781444355062 0.782293180518
plain tanh(eta)               : 0.385820920476 0.653534946759 0.654020962407
0.999999 * tanh(eta)          : 0.385820534655 0.653534293224 0.654020308386
predict(response)             : 0.385820534655 0.653534293224 0.654020308386
predict - plain tanh          : -3.858e-07 -6.535e-07 -6.540e-07
predict - guarded             :  0          0          0
inverse atanh(rho/0.999999)   : 0.406880709656 0.781444355062 0.782293180518
inverse minus eta             :  0  -1.11e-16  0
```

The guarded form matches with difference identically zero; plain `tanh` matches only to
~6e-7. The plan's stated inverse `eta = atanh(rho12 / 0.999999)` round-trips to machine
zero. **N1 is fixed and the statement is correct.**

The plan's three six-decimal values reproduce to 1e-13:

```
recomputed minus plan : -1.49e-14  2.28e-13  -2.54e-14
```

Two supporting numbers the plan uses also reproduce: pooled Pearson
`r = -0.228625635913` (plan writes `-0.2286`), and per-species Pearson
`0.385813200496 / 0.65353620818 / 0.654023314273`, giving residuals against the fitted
`rho12` of `+7.33e-06 / -1.92e-06 / -3.01e-06` — the values batch 4 reported. The guard
accounts for 5%, 34% and 22% of those three residuals respectively, so the plan's
"~6e-7 of the quoted residual is the guard" is right for Chinstrap and Gentoo and
slightly overstated (3.9e-7) for Adélie. Not worth an edit; worth not tightening.

### R3 — CITATION. The primary source line for the `rho12` guard is the wrong branch

`PR2-build-plan.md:572-573` cites `src/drmTMB.cpp:670` as the source, with
`src/drmTMB.cpp:4260` in parentheses as "the other `biv_gaussian` branch". It is the
other way round. Line 670 sits inside `} else if (model_type == 95 || model_type == 96
|| model_type == 97) {` (`src/drmTMB.cpp:618`), the unstructured random-effect
covariance-probe branch — and **no R code assigns 95**: `grep -rn "95L" R/*.R` returns
nothing. Line 4260 sits inside `} else if (model_type == 2 || model_type == 19 ||
model_type == 20) {` (`src/drmTMB.cpp:4254`), and `R/drmTMB.R:20454-20458` maps
`biv_gaussian = 2L`. The c10 fit therefore executes `:4260`, never `:670`.

The conversion statement is unaffected — both lines are byte-identical and guard the
same way — but a plan whose §11 table repairs three of my citation findings should not
ship a fourth. **Swap the two citations: `src/drmTMB.cpp:4260` primary (the branch
`model_type = 2L` reaches, `R/drmTMB.R:20456`), `:670` as "identically in the
covariance-probe branch".**

### R4 — SCOPE. "Plain `atanh`/`tanh` … must not appear anywhere" is true of `rho12` and false of the codebase

`PR2-build-plan.md:36` reads: *"Plain `atanh`/`tanh` is wrong and must not appear
anywhere."* As a rule for how the article states the **`rho12`** link, correct. As a
statement about drmTMB, it is not: the admitted binomial `q = 2` random-effect
correlation path applies **unguarded** `tanh` on purpose —
`src/drmTMB.cpp:3330` (`rho_mu_re(j) = tanh(eta_cor_mu(j));`, with the comment at
`:3323-3326` explaining the `[[exp(theta1), 0], [exp(theta2) rho, exp(theta2)
sech(eta)]]` factorisation) and the mirroring R accessor at `R/drmTMB.R:21581`
(`if (isTRUE(binomial_q2)) tanh(eta) else 0.999999 * tanh(eta)`). `R/mspl-estimator.R:580`
and `src/drmTMB.cpp:5030` are likewise unguarded.

No Phase 19 cell touches those paths, so nothing in PR 2 is wrong today. But the
sentence as written is a standing rule, and the next contributor who reads it and
"corrects" `src/drmTMB.cpp:3330` will change a likelihood. **Scope the sentence to the
`rho12` dpar**: *"For `rho12` the link is guarded; plain `atanh`/`tanh` must not appear.
Random-effect correlation links are guarded too, except the admitted binomial `q = 2`
block, which is deliberately unguarded (`src/drmTMB.cpp:3330`)."*

---

## Part 2 — the five secondary defects, one by one

### N2 — fixed in the body; the fix table undoes it

`PR2-build-plan.md:581-589` (§4.2, "Numbers to use") gives the three response-scale
values to twelve digits, forbids batch 4's `0.3860`/`0.6536`, forbids
`candidate-cells.md:298-300`'s link-scale triple, and adds a correct warning that
Chinstrap (0.6535) and Gentoo (0.6540) must not be described as different strengths.
That is a complete fix and slightly better than what I asked for.

**R2 — MINOR, new.** The repair table at `PR2-build-plan.md:1037` says the correct
values "are `0.3858209` and `0.6535349`". Those are **plain-`tanh`** values. The
response-scale values, per Part 1, are `0.3858205` and `0.6535343`. My N2 text quoted
plain `tanh` because I was checking what batch 4 had *written*; lifted verbatim into a
column headed "Fix", it now instructs the builder to write the unguarded numbers in the
same document that declares the unguarded link wrong. The divergence is 4e-7 — small,
but it is the exact quantity §4.2 exists to get right. **Restate the `:1037` row's
"correct" values as `0.385820534655` and `0.653534293224`, or drop the digits from that
row and point at §4.2.**

### N3 — fixed as an instruction, but my replacement number was wrong (S1)

See the self-correction below. The plan's handling (`:432-436` and `:1032`) faithfully
applies what I wrote; what I wrote is what needs repairing.

### N4 — FIXED, verified in place

`PR2-build-plan.md:1035` repoints batch 3's three "doc 158 Lnn" citations to
`docs/design/158-phase-19-comparator-matrix.md:90`, `:47`, `:42`. I opened the file:

- `:90` → `` | `cumulative_logit()` | `ordinal::clm`, `MASS::polr`, `brms` | cutpoints, location | … `` ✓
- `:47` → `` | `stats::binomial()` | event probability `mu` | … `` ✓
- `:42` → `` | `lognormal()` | `sigma` on `log(y)` | … `` ✓

All three land on the intended rows.

### N5 — FIXED, verified in place

`PR2-build-plan.md:1038` repoints to `docs/design/242-…:86-91`. Opened: `:86-91` is
*"**The governing constraint.** Agreement licenses the **overlap** region only, never
the **frontier** … A design that blurs the two is credibility-laundering."* ✓ And
`:82-84` is indeed the unrelated passage about whether `lme4` point agreement was
withheld from the ledger ✓. The plan also quotes the passage correctly at `:795-796`.

### N6 — FIXED, and carried further than I asked

`PR2-build-plan.md:770-778` states the narrowed claim in the form I recommended: ten
rows, five exercised, three of those identity, **two non-identity conversions tested**
(`nbinom2` `-2×`, meta-analysis `exp(2×)`), five never fitted, and three of those five
are the non-identity ones. It ends with the explicit prohibition. Both of my related
gaps are also carried:

- the ordinal sign convention becomes a doc-158 edit at `:975-979`, with the
  `logit P(Y <= j) = alpha_j - x'beta` form and the "clean sign flip with identical
  magnitudes" rationale;
- `gamlss` absence is recorded at `:765` and in the reproducibility block at `:1074`;
- and `:984-986` closes doc 158's own flagged `glmmTMB::sigma()` gap with both the
  gaussian (`47.44887999`, SD) and tweedie (`1.480683096`, `phi`) values.

Nothing to add.

---

## Part 3 — non-corruption: four previously CONFIRMED conversions, recomputed

Fresh script, fresh fits. Every number below is from this session.

**A. gaussian — dispersion predictor is `log(SD)`** (`drmTMB(bf(mu = Reaction ~ Days,
sigma = ~ Days), sleepstudy, gaussian())`, fixed effects only):

```
drmTMB logLik            : -938.716365659
  hand dnorm sd = sigma  : -938.716365659   <- accepted
  hand dnorm sd = sqrt() : -4647.81685139   <- rejected (off by 3709.10)
drm sigma coefs          : 3.38915034118  0.0904448979173
gtmb disp coefs          : 3.3891506672   0.0904448723522
```

**B. nbinom2 — `size = 1/sigma^2`** (`mu ~ FoodTreatment`, `sigma ~ FoodTreatment`,
`Owls`, fixed effects only):

```
drmTMB logLik                 : -1725.17215645
  hand dnbinom size=1/sigma^2 : -1725.17215645   <- accepted
  hand dnbinom size=1/sigma   : -1735.6899006    <- rejected
  hand dnbinom size=sigma     : -1822.90463179   <- rejected
  hand dnbinom size=sigma^2   : -1897.6444544    <- rejected (new alternative, also rejected)
glmmTMB logLik                : -1725.17215643
-2 * drm sigma coefs          :  0.261619259583 -1.19320216384
gtmb disp coefs               :  0.261630142121 -1.19319755807
```

Source re-read in place: `R/family-dpq.R:902-904` is
`drm_nbinom2_size <- function(sigma) { 1 / sigma^2 }` ✓.

**D. `meta_V` — `tau^2 = exp(2 * eta_sigma)`** (`dat.bcg`, log-RR, 13 trials):

```
drm mu, eta_sigma, exp(2*eta) : -0.71119895659 -0.636432721958 0.280028066337
drmTMB logLik                 : -12.6650763483
  hand dnorm sd=sqrt(vi+tau2) : -12.6650763483   <- accepted
  hand dnorm sd=sqrt(vi+e^eta): -13.3578699267   <- rejected
  hand dnorm sd=sqrt(vi)+tau  : -13.4455631742   <- rejected (new alternative, also rejected)
rma.uni ML b, tau2, logLik    : -0.71119913919  0.28002817105  -12.6650763483
abs diff tau2 / mu / logLik   :  1.05e-07  1.83e-07  5.77e-13
```

Source re-read in place: `R/methods.R:5433-5435` is
`drm_total_obs_sd <- function(v_known, sigma) { sqrt(v_known + sigma^2) }` ✓.

**C. lognormal, and F. c05** — also recomputed, because the plan quotes exact digits
for both:

```
c09 logLik (plan-displayed model) : -2511.44817527   (plan cites -2511.448175 ✓)
  hand dlnorm(meanlog = mu)       : -2511.44817527   <- accepted
  hand meanlog = mu - sigma^2/2   : -2517.47175437   <- rejected
  sum(-log y)                     : -2772.78026116   (plan cites -2772.780261 ✓)
c05 drm logLik / rma.mv logLik    : -11.9973185172 / -11.9973185172
c05 abs diff logLik               :  1.05337960576e-12   (plan cites 1.05e-12 ✓)
```

**Conclusion: the rewrite corrupted nothing.** Every conversion that survived the first
pass survives this one, against the same wrong alternatives and two new ones, and every
digit the plan quotes for c04, c05, c06 and c09 reproduces.

---

## Part 4 — new findings against the repair

### R1 — MATERIAL. c01 and c03 attribute my fixed-effect density checks to random-effect models

This is the one thing in the repair I would block on.

`PR2-build-plan.md:411-413` displays the c01 model as

```r
drmTMB(bf(mu = Reaction ~ Days + (1 + Days | Subject), sigma = ~ Days), ...)
```

and then, four lines later (`:421-424`), states: *"Re-derived from the density, not from
the table: hand `dnorm(sd = exp(eta))` reproduces `logLik = -938.7163657`, while
`sd = sqrt(exp(eta))` gives `-4647.816851`."* Measured on the **displayed** model:

```
c01 plan-displayed logLik  : -870.000347732
audit fixed-effect logLik  : -938.716365659
hand sum(dnorm(sd = sigma)) on the RE model : -814.80882821
```

`-938.7163657` is not that model's log-likelihood, and the density identity the sentence
asserts **does not hold** for it: with a random effect, `logLik()` is the Laplace
marginal (`-870.000`) and `sum(dnorm(...))` is a conditional quantity (`-814.809`). The
two differ by 55 units. My `adversarial-scales.md:50-51` said so explicitly — *"fixed
effects only, so no Laplace step on either side and the likelihoods are exact"* — and
that qualifier did not survive into the plan.

Identically for c03. `PR2-build-plan.md:488-491` displays
`mu = SiblingNegotiation ~ FoodTreatment * SexParent + (1 | Nest)`, and `:508-510` cites
`logLik = -1725.172156` from my `mu ~ FoodTreatment` fixed-effect fit:

```
c03 plan-displayed logLik  : -1716.21767807
audit fixed-effect logLik  : -1725.17215645
```

Why it matters, concretely. A builder following the plan verbatim will fit the displayed
call, get a different number, and take one of three bad exits: quietly print the plan's
number (a fabricated result), quietly change the model to make the number appear
(silently dropping the random effect the reader was promised), or delete the density
sentence (losing the strongest evidence in these two cells). None of those is caught by
any check in §9 or §10.

Why the *conversions* are nonetheless safe. The link is structural, not fit-dependent,
and I confirmed the conversions hold on the plan's displayed RE models directly:

```
c01 RE  drm sigma coefs  : 2.81184908799  0.084633935316
c01 RE  gtmb disp coefs  : 2.81184924496  0.0846338976379
c01 RE  logLik drm/gtmb  : -870.000347732 / -870.000347732   (identical)
c03 RE  -2 * drm sigma   : 0.377592192555 -1.20817401475
c03 RE  gtmb disp        : 0.377593346066 -1.20817532977
c03 RE  logLik drm/gtmb  : -1716.21767807 / -1716.21767807   (identical)
```

Both cells' matched-scale agreement is genuine on the models actually displayed, and in
both cases drmTMB and glmmTMB reach the **same** log-likelihood to printed precision —
which is stronger evidence than the coefficient table and is currently unused.

**Fix.** In c01 and c03, say which model the density check used and why it was that one:
*"The conversion was verified from the density on the fixed-effect variant of this model
(`mu ~ Days`, no `(1 + Days | Subject)`), where the likelihood is exact and no Laplace
step intervenes on either side: hand `dnorm(sd = exp(eta))` reproduces `-938.7163657`
while `sd = sqrt(exp(eta))` gives `-4647.816851`. On the random-effect model shown here,
`logLik()` is the Laplace marginal and no row-wise density identity holds; what the two
packages share there is the marginal log-likelihood itself, `-870.000347732` on both
sides."* The same shape for c03 with `-1716.21767807`.

### S1 — SELF-CORRECTION. My N3 replacement number is wrong; the plan inherited it

N3 said batch 1's `sigma:(Intercept)` `abs diff` of `1e-6` should be `1.1e-7`. I got
`1.1e-7` by differencing batch 1's **printed, rounded** values `2.81184909` and
`2.8118492` — which is precisely the mistake I was charging batch 1 with. At full
precision (measured above, on the RE model batch 1 actually fitted):

```
sigma:(Intercept)  2.81184908799  vs  2.81184924496  ->  1.56962572717e-07
sigma:Days         0.084633935316 vs  0.0846338976379 -> 3.76780801697e-08
```

**The correct value is `1.6e-7`, not `1.1e-7`.** N3's direction stands — batch 1's `1e-6`
overstates the disagreement by roughly an order of magnitude — but the number the plan
now carries at `:434` and `:1032` is wrong by 30%.

The second half of that finding also needs tightening. I wrote, and the plan repeats at
`:435-436`, that the `sigma` coefficients "agree to 8" significant figures. They do not:
the intercept agrees to a relative `5.6e-8` (≈ 7–8 figures) but the `Days` coefficient to
a relative `4.5e-7` (≈ 6 figures). **Replace "agree to 8" with the two relative
differences, or with "abs diff `1.6e-7` and `3.8e-8`".** Batch 1's own `4e-8` for
`sigma:Days` was correct.

For completeness, c03's table needs no such repair: batch 1's `1.1e-6` and `1e-6` measure
`1.15351158381e-06` and `1.31502158252e-06` — correct to the digit shown.

---

## Recommended edits, in priority order

1. **`PR2-build-plan.md:421-424` and `:508-510` (R1, material).** Name the fixed-effect
   variant the density check used, and state that the displayed random-effect models
   share the *marginal* log-likelihood instead (`-870.000347732`; `-1716.21767807`).
   Do not delete the density evidence and do not change the displayed models.
2. **`PR2-build-plan.md:434` and `:1032` (S1).** `1.1e-7` → `1.6e-7`. Replace "agree to
   8 significant figures" with the measured `1.6e-7` / `3.8e-8`.
3. **`PR2-build-plan.md:572-573` (R3).** Make `src/drmTMB.cpp:4260` the primary citation
   (`model_type = 2L`, `R/drmTMB.R:20456`); demote `:670` to the covariance-probe branch.
4. **`PR2-build-plan.md:1037` (R2).** The "correct" values in the fix table are
   plain-`tanh`; use the response-scale `0.385820534655` / `0.653534293224`.
5. **`PR2-build-plan.md:36` (R4).** Scope the no-plain-`tanh` rule to `rho12`; note the
   deliberately unguarded binomial `q = 2` block (`src/drmTMB.cpp:3330`,
   `R/drmTMB.R:21581`).

## What this re-gate does not cover

- I re-verified the `rho12` link, N2–N6, and five conversions. I did **not** re-audit
  Rose's eight findings, the article architecture in §2, the coverage table in §5, the
  independence classifications, or anything in §8–§12 beyond the line numbers named above.
- The four conversions recomputed here are the same four families as before. The five
  never-fitted rows of doc 158's table (`student()`, `Gamma`, `tweedie()`, `beta()`,
  `beta_binomial()`) remain unverified against a density, exactly as N6 says.
- Nothing here bears on interval, coverage, or small-sample claims, which doc 242
  (`:47-49`) excludes regardless.
