# Phase 19 gate 3 — the RE-vs-FE log-likelihood repair, re-fitted from scratch (Noether)

Reader: Ada, who rewrote `PR2-build-plan.md` for round 3, and whoever builds PR 2 from it.
Purpose: decide whether the R1 repair is real — whether every log-likelihood the plan now
cites belongs to the model the plan actually displays, and whether each conversion identity
holds **on that model**.

Method, and the one rule I followed. **I accepted no number I did not reproduce.** I did not
re-run `scratchpad/regate.R`, did not read `scratchpad/ada-round3-verify.R`, and did not
compare the plan against my own round-2 report. I wrote nine fresh scripts, re-fitted every
one of the ten displayed models plus the two fixed-effect variants, and re-derived each
identity from the density. Source citations (`rho12` guard, branch reachability, the
unguarded binomial `q = 2` block) were re-grepped from `src/` and `R/` rather than inherited.

Scripts (this session):
`/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/55be482f-02d5-4bbb-8b85-7fd279d63c57/scratchpad/gate3{,b,c,d,e,f,g,h,i}.R`.
Environment: worktree `.worktrees/external-oracle`, branch `claude/external-oracle-intervals`,
`4530fd71a`, drmTMB 0.7.0 (`DESCRIPTION:3`) via `devtools::load_all(".", quiet = TRUE)`,
R 4.6.0, all runs under `R_PROFILE_USER=/dev/null Rscript --no-init-file`. Every fit finished
in seconds; no compute was needed and none was requested.

---

## Verdict summary

| Item | Round-2 verdict | Gate-3 verdict |
| --- | --- | --- |
| **R1** — c01/c03 log-likelihoods attached to the wrong models | MATERIAL, block | **FIXED, and every number in both repaired subsections reproduces to the last digit printed.** The FE/RE split is stated correctly and the identity now holds on the model each number belongs to. |
| **S1** — `1.1e-7` wrong; "agree to 8 significant figures" false | self-correction | **FIXED.** The plan reads `1.6e-7` and `3.8e-8`; measured `1.5696e-07` / `3.7678e-08`. The phrase "agree to 8 significant figures" survives **only inside explicit prohibitions** (`:530`, `:1350`, `:1391`) and nowhere as an assertion. |
| **R2** — fix table quoted plain-`tanh` values as "correct" | MINOR | **FIXED** (`:1355` now carries the response-scale values and forbids the plain-`tanh` pair by name). |
| **R3** — wrong primary citation for the `rho12` guard | CITATION | **FIXED, and independently re-verified from source.** |
| **R4** — "plain `tanh` must not appear anywhere" over-broad | SCOPE | **FIXED** (`:45` scoped to the `rho12` dpar, binomial `q = 2` named). |
| **`rho12 = 0.999999 * tanh`** | CONFIRMED | **Still stands.** `predict()` minus guarded form is **identically zero**; the plan's three quoted values reproduce to `2.3e-13`. |
| **Four previously CONFIRMED conversions** | CONFIRMED | **All four reproduce, plus c05's identity.** Nothing was corrupted by the round-3 rewrite. |

**Nothing round 3 wrote is wrong.** I checked every number Ada added — the whole §11.1 block
and both repaired subsections — against my own fits, and all of them match. The four findings
below (G1–G4) are **residue from the feasibility batches that this round did not touch**, not
new damage. One of them (G4) would write an over-claim into a permanent design doc.

---

## Part 1 — R1: the repair, measured on the models the plan displays

### c01 (`sleepstudy`, gaussian)

The plan displays `bf(mu = Reaction ~ Days + (1 + Days | Subject), sigma = ~ Days)`
(`PR2-build-plan.md:470-472`) and now makes two separate statements about two separate
models (`:489-506`). Both are true. Fitted by me:

```
DISPLAYED random-effect model
  drmTMB  logLik                     -870.000347731500        plan: -870.000347731500  OK
  glmmTMB logLik                     -870.000347731517        plan: -870.000347731517  OK
  abs diff                            1.62572577e-11          plan: 1.63e-11           OK
  drm sigma coefs      2.8118490879933251   0.0846339353160082
  gtmb disp coefs      2.8118492449558980   0.0846338976379280
  abs diff             1.56962572717e-07    3.76780801697e-08  plan: 1.5696e-07 / 3.7678e-08  OK
  rel diff             5.58218e-08          4.45189e-07        plan: 5.58e-08 / 4.45e-07      OK

FIXED-EFFECT variant  bf(mu = Reaction ~ Days, sigma = ~ Days)
  drmTMB logLik                      -938.716365658989        plan: -938.716365658989  OK
  hand dnorm(sd = exp(eta))          -938.716365658985        plan: -938.716365658985  OK
  hand dnorm(sd = sqrt(exp(eta)))   -4647.81685139013         plan: -4647.81685139013  OK
  accepted minus logLik                3.64e-12
  separation between the two scales 3709.100485731145         plan: "about 3,700 units" OK
```

The load-bearing check is the one the previous revision failed. On the **displayed**
random-effect model, `sum(dnorm(y, mu_hat, sigma_hat, log = TRUE))` gives
**`-814.808828209801`** — not `-938.716`, and not the reported `-870.000` either. Three
distinct numbers for three distinct quantities. The plan now says exactly this
(`:494-500`: "with a random effect, `logLik()` is the Laplace marginal and `sum(dnorm(...))`
is a conditional quantity"), and the draft article sentence at `:501-506` names the
fixed-effect variant explicitly and reports `-870.0003477` as the shared marginal. Correct.

### c03 (`Owls`, nbinom2)

The plan displays `mu = SiblingNegotiation ~ FoodTreatment * SexParent + (1 | Nest),
sigma = ~ FoodTreatment` (`:587-591`) and splits the evidence at `:608-626`:

```
DISPLAYED random-effect model
  drmTMB  logLik                    -1716.21767807419         plan: -1716.217678074193 OK
  glmmTMB logLik                    -1716.21767807461         plan: -1716.217678074613 OK
  abs diff                            4.19504431e-10          plan: 4.20e-10           OK
  -2 * drm sigma      0.377592192554504  -1.208174014747363    plan: 0.377592192555 / -1.208174014747 OK
  gtmb disp           0.377593346066088  -1.208175329768945    plan: 0.377593346066 / -1.208175329769 OK
  abs diff            1.15351158381e-06   1.31502158252e-06    plan: 1.15e-06 / 1.32e-06 OK

FIXED-EFFECT variant  bf(mu = SiblingNegotiation ~ FoodTreatment, sigma = ~ FoodTreatment)
  drmTMB logLik                     -1725.1721564513          plan: -1725.1721564513   OK
  hand dnbinom(size = 1/sigma^2)    -1725.17215645118         plan: -1725.17215645118  OK
  hand dnbinom(size = 1/sigma)      -1735.68990059604         plan: -1735.68990059604  OK
  hand dnbinom(size = sigma)        -1822.90463179193         plan: -1822.90463179193  OK
```

The `-2 ×` conversion holds on the displayed random-effect model to `1.2e-6` / `1.3e-6`,
which is what the plan claims, and the density identity is asserted only for the
fixed-effect variant, which is where it holds. `:624` also correctly notes that batch 1's
`1.1e-6` / `1e-6` are right to the digit shown here, unlike c01's.

### The direction of the round-3 self-correction is right

`PR2-build-plan.md:1428-1432` narrows my own round-2 wording: I wrote that the two packages
reach the "same" marginal log-likelihood; measured to full double precision they differ by
`1.63e-11` (c01) and `4.20e-10` (c03). I reproduce both. Ada's narrowing is correct and
should stand — "identical to printed precision", never "identical".

---

## Part 2 — S1, and the "8 significant figures" phrasing

Required by this gate, checked by grep and by re-measurement.

- `PR2-build-plan.md:519` — *"The correct value is `1.6e-7`, not the `1.1e-7` the previous
  revision carried"* ✓. Measured `1.56962572717134e-07`.
- `PR2-build-plan.md:533` — *"Write the two measured absolute differences, `1.6e-7` and
  `3.8e-8`"* ✓. Measured `3.76780801697452e-08`.
- `PR2-build-plan.md:1350` and `:1391` carry the same pair ✓.
- **"agree to 8 significant figures" is gone as an assertion.**
  `grep -n "significant figure" PR2-build-plan.md` returns four hits: `:368` (a prohibition
  — *"Do not present this as 'agreement to `rma.mv`'s printed 4 significant figures'"*),
  `:410` (c06, and it is **true** — see Part 4), `:530` and `:1350` (both prohibitions of
  the phrase itself). No surviving claim of the form "the `sigma` coefficients agree to N
  figures".
- The relative differences the plan uses to justify the ban reproduce: `5.58e-08` for the
  intercept (≈ 7–8 figures) and `4.45e-07` for `Days` (≈ 6 figures). The ban is justified.

---

## Part 3 — the `rho12` guard, re-verified from source and from `predict()`

I re-grepped rather than trusting round 2. Fitting the exact c10 model displayed at
`PR2-build-plan.md:801-805` (`n = 333`, 146/68/119 — confirmed):

```
eta_rho12                    0.406880709655500  0.781444355062459  0.782293180518434
predict(type = "response")   0.385820534654985  0.653534293224228  0.654020308385975
0.999999 * tanh(eta)         0.385820534654985  0.653534293224228  0.654020308385975
plain tanh(eta)              0.385820920475906  0.653534946759175  0.654020962406937
predict - guarded            0                  0                  0
predict - plain tanh        -3.8582e-07        -6.5353e-07        -6.5402e-07
atanh(rho/0.999999) - eta    0                 -1.11e-16           0
recomputed - plan-quoted    -1.49e-14           2.28e-13          -2.54e-14
raw per-species Pearson      0.385813200495579  0.653536208180043  0.654023314272654
pooled Pearson              -0.228625635913029
```

The guarded form matches with difference **identically zero**; the plan's three quoted
values (`:827-829`) reproduce to `2.3e-13`; the stated inverse round-trips to machine zero;
and `-0.2286` (`:849`) is right.

**R3 verified independently.** `sed -n '4254p;4260p;618p;670p' src/drmTMB.cpp` gives

```
4254:  } else if (model_type == 2 || model_type == 19 || model_type == 20) {
4260:    vector<Type> rho12 = Type(0.999999) * tanh(eta_rho12);
 618:  } else if (model_type == 95 || model_type == 96 || model_type == 97) {
 670:      vector<Type> rho12 = Type(0.999999) * tanh(eta_rho12);
```

`R/drmTMB.R:20456` is `biv_gaussian = 2L`, and `grep -rn "95L" R/*.R` returns **nothing**.
The plan's corrected citation (`:812-820`, `:1354`) is right: `:4260` is the branch this fit
executes; `:670` is unreachable from R.

**R4 verified independently.** `R/family.R:13-15` documents the guarded form and `:34`
records `rho12 = "atanh_guarded"`; `R/methods.R:5809-5811` is the single back-transform.
The deliberately unguarded site is `src/drmTMB.cpp:3330` (`rho_mu_re(j) =
tanh(eta_cor_mu(j));`, comment at `:3323-3326`), mirrored at `R/drmTMB.R:21581`
(`if (isTRUE(binomial_q2)) tanh(eta) else 0.999999 * tanh(eta)`). `:45`'s scoped sentence is
correct. Completeness nit, no edit needed: two further unguarded sites exist on the same
MSPL `q = 2` path — `src/drmTMB.cpp:5030` (`} else if (mspl_q == 2) { ... mspl_rho =
tanh(z);`) and `R/mspl-estimator.R:580` — so "the admitted binomial `q = 2` block" is the
right way to name the exception, and naming only two of its four lines is fine.

---

## Part 4 — non-corruption: every other conversion, recomputed on the displayed model

Fresh fits, this session. All against `PR2-build-plan.md`'s current text.

**c04, `meta_V`, `tau^2 = exp(2 * eta_sigma)`** (`:315-317`):

```
drm mu / eta_sigma / exp(2*eta)   -0.711198956589743  -0.636432721958328  0.280028066337492
drmTMB logLik                     -12.6650763482774
  hand dnorm sd = sqrt(vi + tau2) -12.6650763482774    <- accepted
  hand dnorm sd = sqrt(vi + e^eta)-13.3578699266808    <- rejected
rma.uni(method="ML") b/tau2/logLik -0.711199139  0.280028171  -12.665076348277
abs diff tau2 / mu / logLik        1.05e-07  1.83e-07  5.77e-13
rma.uni DEFAULT (REML) b / tau2   -0.714532348365102   0.313243325980895
```

The plan's `-12.66507635` (`:330`) and its mandatory `method = "ML"` warning with
`-0.7145323` / `0.3132433` (`:323-324`) both reproduce exactly.

**c05, contrast-to-cell-mean then `exp()`** (`:352-354`, `:369`):

```
drmTMB logLik   -11.9973185172455     rma.mv logLik  -11.9973185172466   abs 1.05e-12
drm tau^2   0.0349727917270701  0.3670682228366637  0.2844497278324761
rma tau^2   0.0349727579931577  0.3670678846522538  0.2844497113645296
abs diff    3.373e-08           3.382e-07           1.647e-08
alloc n     2 / 7 / 4
```

`1.05e-12` and `3.4e-08 / 3.4e-07 / 1.6e-08` reproduce. (The `tau` sentence at `:384` does
not — see **G1**.)

**c09, lognormal `meanlog = mu`** (`:555-565`):

```
drmTMB logLik                        -2511.44817527221    plan: -2511.448175  OK
  hand dlnorm(meanlog = mu)          -2511.44817527219    <- accepted
  hand dlnorm(meanlog = mu - s^2/2)  -2517.47175436946    plan: -2517.47      OK
sum(-log(y))                         -2772.78026115929    plan: -2772.780261  OK
drm logLik - glmmTMB logLik          -2772.78026115931    (the Jacobian gap, to 2e-11)
exp(sigma sexmale coef)               1.54869120600024    plan: "about 55%"   OK
```

**c06, ordinal, no transform** (`:408-411`): drmTMB `-86.4919233656877` against
`ordinal::clm` `-86.4919233656491` — identical to 10 significant figures as claimed, with
same-signed slopes (`2.50310224 / 1.52779699` vs `2.50310201 / 1.52779766`). The comparator's
scale model fits at `-86.4394628794048` (plan: `-86.439` ✓), and drmTMB rejects `sigma` with
the message quoted verbatim at `:420` and `:987` — I reproduced the error text character for
character. Cutpoints are reachable at `fit$ordinal$cutpoints` and printed by `summary()`
(diffs `1.2e-6` to `2.0e-6`), so `:414`'s "compare the four cutpoints as an ordered set" is
executable.

**c08, `cbpp` binomial** (`:290-293`): fixed-effect diffs `-1.85e-04`, `-4.14e-04`,
`-4.33e-04`, `-5.77e-04`; herd RE SD `1.90e-04`. The plan's range `-1.9e-04` to `-5.8e-04`
and its `1.9e-04` are right. The `logLik` figure is not — see **G3**.

**c02 / §4.2** (`:735-752`): `glmmTMB(Reaction ~ Days, dispformula = ~ (1|Subject))` gives
`VarCorr(g)$disp` Variance `1.52124307248313e-12`, Std.Dev. `1.23338683002663e-06`,
`pdHess = FALSE`, `logLik = NA` — all four as stated. drmTMB's control fit gives
`sd:sigma:(1 | Subject) = 0.505749396560021` (SE `0.103180244181686`) and distributional
`sigma = 37.603199171308617`, matching `0.5057494`, `0.1031802`, `37.6032`.

**Conclusion: the round-3 rewrite corrupted nothing.** Every conversion that survived rounds
1 and 2 survives this one, on the models the plan displays, against the same wrong
alternatives.

---

## Part 5 — four findings the repair did not reach

None is new damage; all four are inherited numbers that this round left in place. I raise
them because they are the *same class* the last two rounds were spent eliminating, and
because two of them are in text drafted to ship verbatim.

### G1 — SERIOUS. c05's "eight decimal places" is false, and it sits in a "Ship instead:" sentence

`PR2-build-plan.md:383-385` drafts, for the article: *"drmTMB's per-level `tau` estimates
reproduce `metafor`'s to eight decimal places, and the two fits have the same
log-likelihood."* Measured:

```
level        drmTMB tau      rma.mv tau      abs diff
alternate    0.1870101380    0.1870100478    9.02e-08
random       0.6058615542    0.6058612751    2.79e-07
systematic   0.5333382865    0.5333382710    1.54e-08
```

Rounded to eight decimals the three pairs are `0.18701014/0.18701005`,
`0.60586155/0.60586128`, `0.53333829/0.53333827` — **all three differ**. Under the more
generous reading ("differ by less than `1e-8`") only `systematic` qualifies. Agreement is
six, five and seven decimal places respectively. This is a bare figure-count assertion of
exactly the kind S1 removed from Comparison 6, and it is inside a block the plan instructs
the builder to ship as written.

**Fix.** Quote the differences instead of counting places, matching what the same section
already does for `tau^2` at `:369`: *"…reproduce `metafor`'s to better than `3e-7` on every
level, and the two fits have the same log-likelihood."* Or, if a place count is wanted,
**five**, not eight.

### G2 — MINOR. c07's "every quantity agrees to 1e-5 or better" is false by 53%

`PR2-build-plan.md:440-441` states it, citing `feasibility-batch-3.md:40-58`. Measured on the
displayed model:

```
cutpoints    2.36e-06  8.65e-06  6.69e-06  3.48e-06
tempwarm     4.23e-06
contactyes   1.53446916142386e-05     <- exceeds 1e-5
judge RE SD  6.44e-06
logLik       3.48e-06
maximum      1.53e-05
```

The source is self-contradicting: `feasibility-batch-3.md:46` prints
`contactyes diff = 1.53e-05` and `:56` concludes "Every quantity agrees to 1e-5 or better"
ten lines later. The plan copied the conclusion and not the table.

**Fix.** *"every quantity agrees to `2e-5` or better"*, or *"to `1e-5` or better on every
quantity except the `contact` slope, `1.5e-5`"*. The `sd:mu:(1 | judge)` = `1.131139` vs
`1.131133` pair at `:437-438` is correct as printed (diff `6.44e-06`), as is `1.279461`.

### G3 — MINOR. c08's `logLik` difference is `2.8e-04`, not `2.9e-04`

`PR2-build-plan.md:292` lists `2.9e-04` on `logLik`. Measured: drmTMB `-92.0262818701488`,
`lme4::glmer` `-92.0265663895368`, difference **`2.84519387960813e-04`** → `2.8e-04`.
`feasibility-batch-3.md:113` records `2.85e-04`; the plan rounded an already-rounded value a
second time and rounded it the wrong way. Everything else in that tolerance sentence is
right, and the "not rounding, not under-convergence" argument at `:293-299` is unaffected.

**Fix.** `2.9e-04` → `2.8e-04`.

### G4 — SERIOUS (scope). §10.2 would mark `stats::binomial()` "density-verified" in doc 158, and it never was

`PR2-build-plan.md:1286-1288`: *"**Mark which conversion rows are density-verified**
(Noether N6). Verified: `gaussian()`, `lognormal()`, `stats::binomial()`, `nbinom2()`,
`meta_V(V=V)`."* Four of those five I have now verified from a density myself. The fifth was
never checked: `grep -rn "dbinom" docs/dev-log/external-oracle/phase19/` returns **nothing**,
and `adversarial-scales.md:36` classes c08 as *"binomial, no transform — CONFIRMED (no
conversion exists to get wrong)"*, which is a statement that there is nothing to verify, not
a verification. It could not have been checked as the others were: c08 is a Laplace-marginal
random-intercept model, so no row-wise density identity holds on it — the same fact R1 was
about — and drmTMB and `glmer` differ there by `2.85e-04` (G3), five orders of magnitude
looser than the `1e-12` residuals the four genuine density checks return.

The plan states this correctly elsewhere. `:994-1002` says five families were **exercised**,
three conversions are the identity, **"two conversion shapes verified against densities"**,
and instructs "never say the conversion table is verified". §10.2 item 3 contradicts §7, and
it is the half that gets written into `docs/design/158-…`, a permanent design doc, where the
distinction will outlive this plan.

**Fix.** Split the list: *"Density-verified: `gaussian()`, `lognormal()`, `nbinom2()`,
`meta_V(V=V)`. Exercised, identity conversion with nothing to verify: `stats::binomial()`.
Never fitted: `student()`, `Gamma`, `tweedie()`, `beta()`, `beta_binomial()`."*

### Not a finding, recorded so the next round does not re-open it

`PR2-build-plan.md:567` says c09's coefficient agreement is "1e-7 to 1e-8". Measured
`mu`: `8.52e-09`, `4.05e-08`, `3.21e-08`; `sigma`: `9.62e-08`, `1.46e-07`. The top of the
range is `1.5e-7`, which rounds to `1e-7` at the one significant digit the sentence uses. No
edit needed.

---

## Recommended edits, in priority order

1. **`PR2-build-plan.md:383-385` (G1).** Replace "to eight decimal places" with the measured
   bound (`better than 3e-7`), or with "five decimal places". It ships verbatim.
2. **`PR2-build-plan.md:1286-1288` (G4).** Split "density-verified" from "exercised";
   `stats::binomial()` belongs in the second group. This edit lands in doc 158.
3. **`PR2-build-plan.md:440-441` (G2).** `1e-5` → `2e-5`, or name the `contact` slope
   exception.
4. **`PR2-build-plan.md:292` (G3).** `2.9e-04` → `2.8e-04`.

No edit is required to anything round 3 wrote. R1, S1, R2, R3 and R4 are all correctly
applied, and I could not break any of them.

---

## Churn risk: **stabilising, not oscillating**

The question this gate was asked to answer is whether each round fixes the last round's
numbers while introducing its own. The evidence says no — round 3 is the first round that
added numbers without adding defects.

- **Round 3's own output is clean.** I re-measured every number in §11.1 and in both repaired
  subsections — twelve log-likelihoods, six coefficient pairs, four difference figures — and
  all of them reproduce to the last digit printed. Zero new numeric defects.
- **The repair is structural, not cosmetic.** R1 was fixed by separating two models rather
  than by swapping a number, which is why it stayed fixed under an independent re-fit: the
  identity is now asserted where it holds and the marginal is reported where it does not.
- **The round narrowed its own claims unprompted.** `:1428-1432` corrects my "identical" to
  `1.63e-11` / `4.20e-10`. Rounds tightening themselves is the opposite signature of churn.
- **All four remaining findings are inherited, and they are getting cheaper.** G1–G4 are
  untouched residue from the feasibility batches, and their severity is falling round on
  round: round 1 refuted a link function, round 2 caught a log-likelihood attached to the
  wrong model, round 3 catches a decimal count and a rounding digit. The error class has not
  changed but its blast radius has shrunk by orders of magnitude.
- **The remaining exposure is bounded and enumerable.** Every unverified number now lives in
  the feasibility batches, which the plan already flags for recomputation at `:262-265`
  ("the building session must re-run them and use its own output, not transcribe these").
  G1–G3 are three instances of the batches not having been re-measured; there is no reason to
  expect a fourth round to find a *different kind* of problem, only more of this one.

The one thing that would change this assessment: G4 is not a measurement error but an
internal contradiction between §7 and §10.2 that three review rounds walked past. If the next
round finds more contradictions of that shape, the defect class has moved from arithmetic to
consistency and the count restarts.

---

## What this gate does not cover

- I re-verified the R1 repair, S1, R2–R4, the `rho12` link, and every conversion the plan
  displays a number for. I did **not** re-audit Rose's eight findings, the article
  architecture in §2, the claim-class vocabulary in §8.5, the coverage table in §5, the
  independence classifications, or §9/§10/§12–§15 beyond the four line ranges named above.
- The five never-fitted rows of doc 158's conversion table (`student()`, `Gamma`,
  `tweedie()`, `beta()`, `beta_binomial()`) remain unverified against any density, exactly as
  N6 says and as `:998-1000` states.
- Nothing here bears on interval, coverage or small-sample claims, which
  `docs/design/242-external-comparator-evidence-class.md:47-49` excludes regardless. The two
  interval guards at `:707-709` and `:781-786` are Rose's finding, not re-checked here.
- I fitted each model once, on this machine, at this commit. Agreement figures at the `1e-7`
  level are optimiser-path dependent; the *identities* are not, and it is the identities this
  gate was asked about.
