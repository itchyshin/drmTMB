# Fenced capabilities: the boundaries behind six UNCITED bridge cells

Read this next to `docs/design/parity-scoreboard.md`. The scoreboard counts
what the programme can point at; a cell reads `UNCITED` when no receipt and no
cited refusal reaches it. `UNCITED` is not a synonym for "missing" -- some of
those cells are missing, and some are **decisions the scoreboard simply does
not say out loud**. This file is where the decisions are said out loud.

It is written by hand, not generated. Its job is the one thing a generated
table cannot do: for each fenced capability, name **(i)** the decision or issue
that fences it, **(ii)** what a user should do instead today, and **(iii)**
whether the fence is permanent or carries a stated revisit condition. A
boundary that says only "not supported" is the gap restated -- it leaves a
reader unable to tell a choice from an oversight -- so no entry below stops at
that sentence.

Scope: the six capabilities this file owns are the `Marginal estimators` and
`Bivariate structure and missing data` rows of
`docs/design/capability-status.md` that carry an `UNCITED` bridge cell. Rows
fenced for other reasons (the G3 bridge-inference fence, the interval-coverage
fence of D-181 #2) are not restated here.

## What was measured for this file, and against what

Every refusal message and every number quoted below was **measured in this
run**, not copied from a prior document.

| input | sha / value |
|---|---|
| drmTMB, every live fit below | `origin/main` at `2fcbb0fbf`, `pkgload::load_all()` on branch `claude/parity-uncited-permanent` |
| drmTMB, the receipt re-measurement in section 5 | the same branch after `git merge origin/main`, `e172e7002` |
| DRM.jl | `aee371cc9627c24945859f4caa749e0d5b691782` (the parked reference checkout) |
| environment | `OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true NOT_CRAN=true` |

The section 5 receipt was measured twice, on either side of that merge and by
two different code paths -- a direct `coef()`/`logLik()` comparison, and the
DRM.jl fixture generator's own `parity_numeric()` -- and agreed to every printed
digit (`7.40963e-12`). Where a number below carries no separate sha it was
measured at `2fcbb0fbf`.

The programme pin `430ef64cc` was **not** used: it predates DRM.jl #646 and
#648 and cannot fit a masked response.

Two of the six turned out **not** to be simple fences, and those findings are
the most valuable part of this file. They are §3 (the q4 PLSM route is
reachable and converges through `engine = "julia"`; the *native* comparator is
what fails) and §5 (the Gaussian observed-response mask **agrees across
engines to 7.4e-12** and is now receipted, so only the non-Gaussian half of
that capability is fenced).

---

## 1. AGHQ adaptive-quadrature marginal estimator

`capability-status.md:126` -- native R `planned`; DRM.jl `implemented`;
bridge `UNCITED`.

**(i) What fences it.** Nothing does. **This is the finding: AGHQ is fenced by
absence, not by a decision.** No decision record fences it -- searching
`docs/` for a D-number attached to AGHQ returns nothing, and the parity-joint
ultra-plan's own deferral list (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md`)
names FIML #49 and VA/EVA #496 but **never names AGHQ**. What is measured is
that AGHQ has no public entry point:

- `drmTMB()` takes `estimator`, and `drm_match_estimator()` admits `"ml"` and
  `"mspl"` only (`R/drmTMB.R:269`). There is no `"aghq"`.
- `drm_control()` has 17 formals and none of them selects an integrator
  (`R/control.R:159-176`) -- no `inference`, no `nAGQ`, no `nodes`.
- `getNamespaceExports("drmTMB")` matched against
  `aghq|quad|variational|gva|elbo|nAGQ` returns `character(0)`.

It is not, however, unimplemented. `R/aghq-coxreid.R` is a working
package-private adaptive Gauss-Hermite + Cox-Reid (O3) estimator for a scalar
random effect per cluster, validated in
`tests/testthat/test-aghq-coxreid.R`. The package documentation already states
the boundary in as many words: *"The package-private AGHQ plus Cox-Reid (O3)
estimator is not a `drmTMB()` argument and is not what `REML = TRUE` runs"*
(`R/drmTMB.R:186-187`), and `capability-status.md:143-153` -- rewritten on
2026-09-05, after an earlier version of that paragraph claimed AGHQ had "no
implementation in `R/`" -- now records the same boundary independently: *"The
accurate boundary is 'implemented internally, not exposed'"*. Two readings
agree, so the AGHQ entry here is a restatement of a measured fact, not a new
claim.

The bridge cell therefore cannot be receipted even in principle: a same-target
`engine = "julia"` vs `engine = "tmb"` comparison needs an AGHQ target on both
sides, and the R side exposes none. `R/julia-bridge.R:486` records exactly this
for the sigma-random-effect route -- a same-target comparison "needs a matching
integrator (a Laplace option in DRM.jl's sigma-RE route, or an AGHQ option in
drmTMB's)". DRM.jl's own AGHQ is narrower than its status word suggests: Poisson
`(1 | g)` only (`DRM.jl@aee371cc:docs/design/capability-status.md:242`).

**(ii) What to do instead today.** Fit with the default Laplace approximation
(`engine = "tmb"`, `estimator = "ml"`). Where you have reason to distrust
Laplace -- Bernoulli or low-count Poisson random intercepts with small clusters
-- treat the variance component as a lower bound and check it against a
parametric bootstrap rather than reaching for a quadrature option that is not
there.

**(iii) Permanent?** **No, and not deferred either -- it is unowned.** This is
the one entry in this file with no decision behind it. The parity matrix's own
`NEXT` for the row reads "owner decision: port or fence (not on any leaf)", and
that is still true after this pass. It needs a D-number saying either "expose
`estimator = "aghq"`" or "AGHQ stays package-private"; until it has one, the
row is an oversight wearing the same clothes as a choice.

## 2. Variational (VA/ELBO) marginal estimator

`capability-status.md:127` -- `planned` on both sides; bridge `UNCITED`.

**(i) What fences it.** **D-127**, recorded at
`docs/dev-log/2026-08-08-0.7-issue-sweep-ultra-plan.md:52`: *"GVA/VA-GH/EVA
work is explicitly post-0.7 (D-127), so issues #496 and #932-#936 are not 0.7
implementation blockers."* Issue #496 (the GVA umbrella) was **declined
2026-08-03 and reopened post-0.7** (same file, line 113). The parity-joint
ultra-plan restates the disposition verbatim -- *"CLOSED, not deferred ...
Post-0.7 ... Do not start this first"* -- and rules it OUT of the parity effort
(`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:95`).

The design work is done and waiting, not missing: the pre-code gate is
`docs/design/160-gaussian-variational-approximation-gate.md` (motivation, ELBO
objective, parameterization, engine API, first slice, validation plan) and
Tier G of `docs/design/157-capability-completion-worklist.md`. What does not
exist is code: no `inference = "gva"` path, and `getNamespaceExports()` matches
nothing on `variational|gva|elbo`. DRM.jl is `planned` too, so this is a row
where the twins agree and neither is ahead.

**(ii) What to do instead today.** Use the default Laplace fit. If the
motivating problem is Laplace's known downward bias in the random-effect
variance for non-Gaussian random intercepts with little information per group,
the honest options in the package today are a parametric bootstrap on the
variance component, or a profile-likelihood CI (`confint(type = "profile")`),
neither of which repairs the bias but both of which stop you reporting a
Laplace SE as if it were calibrated.

**(iii) Permanent?** **No -- fenced with a revisit condition that has now come
due.** The stated condition is "post-0.7", and v0.7.0 has been released. The
fence therefore survives only on the second half of the instruction -- *do not
start this first* -- which is a sequencing call, not a permanent boundary.
Reopening is issue #496's job, not this file's.

## 3. Bivariate structured random effect on all four axes (q4 PLSM)

`capability-status.md:195` -- native R `point-fit-recovery`; DRM.jl
`implemented`; bridge `UNCITED` (the ledgered row `biv_q4_phylo_reml`,
`inst/extdata/julia-capabilities.tsv:6`, is the **REML** route and carries no
receipt row at the reference).

**(i) What fences it -- and this one is not what the scoreboard implies.**
Measured in this run, at the exact cell
`tests/testthat/test-julia-phylo-q4-corpairs.R` fits (30 tips x 3 reps = 90
rows, `phylo(1 | p | species)` on `mu1`, `mu2`, `sigma1`, `sigma2`,
`rho12 = ~1`, `biv_gaussian()`, ML):

| engine | converged | logLik | wall |
|---|---|---|---|
| `"julia"` | **TRUE** | -179.85265485 | 41.6 s |
| `"tmb"` | **FALSE** | -179.849481114 | 3.8 s |

`engine = "julia"` **reaches and converges on the ML q4 route.** The native TMB
fit is the one that fails: `opt$convergence = 1`, message **`singular
convergence (7)`**, `is_converged()` `FALSE`, and `vcov()` unavailable, so no
SE comparison is possible. This is not one unlucky cell -- it reproduced on
every cell tried:

| cell | native optimizer message | `is_converged()` | `vcov()` |
|---|---|---|---|
| N=30, m=3, seed 42 | `singular convergence (7)` | FALSE | unavailable |
| N=60, m=5, seed 7 | `singular convergence (7)` | FALSE | unavailable |
| N=40, m=6, seed 11 | `false convergence (8)` | FALSE | unavailable |

and `drm_control(optimizer_preset = "careful")` and `"robust"` both reproduce
the N=30 result to the digit (logLik -179.849481114, `is_converged()` FALSE).

So the fence is the **native** status word, `point-fit-recovery`
(`capability-status.md:195`), and its stated reason at
`capability-status.md:135-141`: there is no single verified claim that a
correction reaches all four axes together. A same-target receipt is blocked not
by the bridge but by the absence of a converged native comparator to compare
*against*. The coefficient spread that follows is a consequence, not an
independent finding: max abs coef delta **1.76998e-2** (7/7 name-matched, worst
on `mu1_(Intercept)`), logLik delta **3.17374e-3** -- both far outside the 1e-4
fixture tolerance, and neither number means the bridge is wrong.

**(ii) What to do instead today.** Fit the q4 model through
`engine = "julia"`, where it converges, and read the among-axis correlations
with `corpairs(fit, level = "phylogenetic")`, which reconstructs them from
`Sigma_a`. Do **not** read a native `engine = "tmb"` q4 fit without checking
`is_converged()` first: it returns a point estimate at a singular optimum and
no standard errors. For an intervals-bearing claim, drop to the q2 mean-only
phylogenetic route, which is ledgered.

**(iii) Permanent?** **No -- and this row is the most reachable of the six.**
The revisit condition is a *native* one: make the four-axis TMB fit converge
(parameterization or start values), and the receipt follows immediately, since
the Julia half already works. The parity matrix's own `NEXT` for this row
("ledger the ML q4 bridge route") is correct but under-states the price: the
ML q4 bridge route can be ledgered today, but it cannot be *receipted* until
the native comparator converges.

## 4. Cross-family bivariate (different families for y1 y2)

`capability-status.md:196` -- native R `planned`; DRM.jl `missing`; bridge
`UNCITED`.

**(i) What fences it.** **Owner decision D-179 #3 (2026-08-27)**, written into
the ledger row itself: `inst/extdata/julia-capabilities.tsv:10`
(`cross_family_latent`) reads *"PERMANENT CLAIM_BOUNDARY (owner decision D-179
#3, 2026-08-27): this row stays `partial` by DESIGN, on the
engine_control_surface pattern -- an owner-signed boundary, not a pe[nding
item]"*. The parity matrix's `NEXT` for the row is *"none: the boundary is
signed (D-179 #3); do not spend simulation-recovery compute here"*, and the
julia-ahead census records the row as *"parked permanently on both sides"*
(`docs/dev-log/evidence/julia-r-parity/2026-09-05-julia-ahead-census.md:277`).

The structural reason a receipt is impossible is measurable, and was measured:

```
drmTMB(bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, rho12 = ~1),
       family = c(gaussian(), poisson()), engine = "tmb")
#> Error: Mixed-response bivariate families are not implemented yet.
#>   x Requested families: "gaussian" and "poisson".
#>   i Only `family = c(gaussian(), gaussian())` or
#>     `family = list(gaussian(), gaussian())` is currently routed to the
#>     bivariate Gaussian engine.
```

(`R/drmTMB.R:3725`.) There is no native mixed pair, so **no native comparator
can exist**, so no same-target coef+logLik comparison can ever be taken for
this capability -- independently of what the bridge does. What the bridge does
have is a latent-rho route: `drmTMB(bf(...), family = c(gaussian(), poisson()),
engine = "julia")` dispatches through `drmTMB_julia_xfam_bridge()`
(defined `R/julia-bridge.R:6847`, reached from `R/julia-bridge.R:545`) to
`DRM.fit_mixed_family`, and `tests/testthat/test-xfam-bridge.R` exercises it
(54 passing assertions, re-run here). So the route is reachable from R -- what
it can never have is a native comparator. It is fenced on three sides by
`inst/extdata/julia-gates.tsv:12-14` (`xfam_missing_route`,
`xfam_rho12_formula`, `xfam_dispersionless_sigma`).

**(ii) What to do instead today.** Fit the two responses as separate univariate
models and report them as such. If the dependence between them is the target,
the reviewed route is `associate_pairs()` with an explicit
`kernel = latent_normal()`, whose five admitted pair classes are listed in
`docs/dev-log/known-limitations.md`; note that its `alpha` is neither `rho12`
nor an observed-scale correlation. Do not use the bivariate `rho12` grammar for
a mixed pair -- it is refused, by design, at the call above.

**(iii) Permanent?** **Yes.** D-179 #3 signs it as permanent, on both sides,
with no revisit condition. This is the one row in this file where "do not work
on this" is the whole instruction.

## 5. Missing-response handling (native, per fitted route)

`capability-status.md:197` -- native R `implemented`; DRM.jl `missing`; bridge
`UNCITED` before this pass.

**(i) The Gaussian half is not fenced -- it is now receipted.** Measured in
this run, `bf(y ~ x, sigma ~ x)`, `gaussian()`, n = 60 with 6 `NA` responses,
`missing = miss_control(response = "include")`, same data, both engines:

| quantity | value |
|---|---|
| coefficients name-matched | 4 / 4 |
| max abs coef delta | **7.40963e-12** |
| logLik delta | **4.26326e-14** |
| SEs name-matched | 4 / 4 |
| max abs SE delta | **7.19797e-08** |
| max rel SE delta | **5.33181e-07** |
| `nobs()` both engines | 54 (60 rows - 6 masked responses) |

Both engines fit the same target and agree, and both report `is_converged()`
TRUE. The receipt is banked in two places: in the ledger row's own
`claim_boundary` (`inst/extdata/julia-capabilities.tsv:5`,
`gaussian_response_mask`), in the prose form the other receipted rows use; and
**upstream as a DRM.jl evidence row** (`capability_id=gaussian_response_mask`,
`PARITY_PASS`) in **DRM.jl PR #734**, which is the form
`tools/write-parity-scoreboard.R` can actually count. Regenerating the
scoreboard against that branch was checked, not assumed: the cell moves
`UNCITED -> RECEIPT` and the **bridge-axis UNCITED count moves 23 -> 22**.
Until #734 merges this cell is BLOCKED-on-DRM.jl-PR-734, which is a different
thing from uncited.

**Two blockers this row records are stale.** The ledger's `next_action` says
G3 (bridge-side inference) was attempted on this exact fixture and blocked by
two findings measured at the dead pin `430ef64cc`. Neither reproduces at
`aee371cc`:

| ledger's recorded finding (at `430ef64cc`) | re-measured at `aee371cc` |
|---|---|
| the julia fit's `is_converged()` reads FALSE (`opt$convergence == 1`) | **TRUE**, `opt$convergence` **0** |
| `confint(method = "bootstrap", R = 99)` on `engine="julia"` fails **all 99** replicates | `confint(parm = "fixef:mu:x", method = "bootstrap", R = 25)` reports **25/25 successful refits, 0 failed** (`engine="tmb"` likewise 25/25) |

The bootstrap intervals themselves are not compared: the two engines draw from
independent RNG streams, so an overlap is not agreement and is not claimed.
Re-running G3 on this route is its owner's call, not this file's; what is
established here is that the reason it stopped no longer holds.

One naming asymmetry surfaced while taking it and is worth a reader's time: the
native engine names SE entries `mu:(Intercept)` and the bridge names them
`mu_(Intercept)`. The numbers agree; the labels do not. Any comparison that
joins on SE names without normalising `:` to `_` will silently match **zero**
entries and can be mistaken for "SEs unavailable".

**(ii) What IS fenced: the non-Gaussian half, and FIML.** Two separate fences.

*Non-Gaussian masks through the bridge* are refused by gate
`base_missing_response_nongaussian` (`inst/extdata/julia-gates.tsv:6`), at
`R/julia-bridge.R:615`, measured:

```
drmTMB(bf(y ~ x), family = poisson(), engine = "julia",
       missing = miss_control(response = "include"))
#> Error: `engine = "julia"` does not support this `missing` route yet.
#>   i Supported: `response = "drop"`, or `response = "include"` for Gaussian
#>     (observed-data fit, tree kept whole). Use `engine = "tmb"` for other
#>     missing-data models.
```

The refusal names the remedy itself: **use `engine = "tmb"`**, where
non-Gaussian masks are `implemented` natively.

*Full-information missing-response (FIML)* is drmTMB issue **#49**, deferred
**twice in writing** as needing its own multi-slice arc, most recently at
`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:92`: *"deferred twice,
in writing, 'needs its own multi-slice arc'; genuinely parity-shaped (DRM.jl
listwise-deletes where drmTMB fits) -> OUT for this effort, by the handover's
own deferral; revisit when 1-11 are done."* DRM.jl's own row is `missing`
because outside its q4 engine it applies automatic listwise deletion.

**(iii) Permanent?** **No, on both halves, and neither is a decision fence.**
The non-Gaussian bridge gate carries `review_due = "before 0.2.0 bridge
promotion"` and its stated reason is "not audited for non-Gaussian masks" --
an audit, not a decision; the fence lifts when someone runs the same
measurement above for a count family. FIML #49 has an explicit revisit
condition: after items 1-11 of the parity-joint plan.

## 6. Missing-predictor imputation (`mi()`)

Capability row, verbatim: `Missing-predictor imputation (mi())`.

`capability-status.md:198` -- native R `implemented`; DRM.jl `experimental`;
bridge `UNCITED`.

**(i) What fences it.** **D-181 #1, reaffirmed by D-209 §3.** The disposition
is recorded at `docs/dev-log/2026-09-02-true-parity-decision-map.md:23` (*"D-181
(2026-08-28): `mi()` fenced for v1.0"*) and line 78 (*"`mi()` in Julia --
D-181 #1"*), and the parity-joint plan classifies it *"D-181 fence, reaffirmed
D-209 | PERMANENT for v1.0 -- write, don't build"*
(`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:44`). DRM.jl fences it
out of the twin claim from its own side
(`DRM.jl@aee371cc:docs/design/capability-status.md:343`). The parity matrix's
`NEXT` is *"owner decision: the fence is recorded, not pending"*.

Unlike §1 and §2 this fence is *executable*, and it was exercised. The bridge
refuses before any Julia session starts, at two gates
(`inst/extdata/julia-gates.tsv:3` `base_impute`, `:5`
`base_missing_predictor_model`):

```
drmTMB(bf(y ~ mi(x)), family = gaussian(), engine = "julia",
       impute = list(x = ~1))
#> Error: Could not prepare the Julia joint missing-predictor model.
#>   i Supported: Gaussian response with one Gaussian/Bernoulli/ordinal/
#>     categorical predictor or two Gaussian predictors, each with a bare
#>     additive mi() term and fixed-effect impute model.
#>   Caused by: The Julia joint missing-predictor adapter requires
#>              missing = miss_control(predictor = "model").
```

(`R/julia-joint-missing.R:246`.) Because the route is refused rather than
mis-fitted, **no R-parity claim is made for it** -- which is the correct
outcome and exactly what a cited refusal is supposed to look like. The
scoreboard reads `UNCITED` here only because its refusal precedence is keyed to
`drm_julia_family_tag()`, and this refusal lives in the joint-missing adapter
instead; the determination has a file:line either way.

**(ii) What to do instead today.** Fit `mi()` models with `engine = "tmb"`,
where the joint missing-predictor route is `implemented` and is the supported
path. The native call needs both halves of the contract -- a two-sided impute
formula and the matching `missing` policy:

```r
drmTMB(bf(y ~ mi(x)), family = gaussian(), data = d, engine = "tmb",
       missing = miss_control(predictor = "model"),
       impute = list(x = x ~ z))
```

A one-sided `impute = list(x = ~1)` is rejected natively too (*"`formula` must
be a two-sided formula such as `x ~ z`"*, measured), so this is a grammar
requirement rather than an engine limitation. Do not route `mi()` through
`engine = "julia"` expecting a fallback: there is none, by decision.

**(iii) Permanent?** **Permanent for v1.0**, with the version as the stated
horizon. D-181 #1 fenced it, D-209 §3 reaffirmed it, and both twins fence it
from their own side. It is not pending work and it is not an oversight; a
revisit needs a new owner decision, not a leaf.

---

## Summary

| capability | ending | fence | permanent? |
|---|---|---|---|
| AGHQ adaptive-quadrature marginal estimator | boundary | **none -- unowned**; no public `estimator`/`drm_control` entry point (`R/drmTMB.R:186-187, 269`; `R/control.R:159-176`) | needs a D-number either way |
| Variational (VA/ELBO) marginal estimator | boundary | D-127, issue #496 (+#932-#936) | no -- "post-0.7", now due; sequencing only |
| Bivariate structured RE, all four axes (q4 PLSM) | boundary (**route reachable**) | native `point-fit-recovery`; native optimizer returns `singular convergence (7)` | no -- lifts when the native q4 fit converges |
| Cross-family bivariate | boundary | **D-179 #3**, signed permanent both sides | **yes** |
| Missing-response handling | **receipt** (Gaussian mask, `7.41e-12` / `4.26e-14`; banked in DRM.jl PR #734) + boundary (non-Gaussian, FIML) | gate `base_missing_response_nongaussian`; issue #49 | no -- audit, and "after items 1-11" |
| Missing-predictor imputation (`mi()`) | boundary | **D-181 #1**, reaffirmed **D-209 §3** | permanent **for v1.0** |

One of the six ends in a receipt rather than a boundary, and it is the only
one of the six that moves the scoreboard: with DRM.jl PR #734 merged, the
bridge-axis UNCITED count goes **23 -> 22**. The other five end in the
boundaries above -- which is the honest ending for them, not a smaller one.

**What this file does NOT cover.** It says nothing about the other 18 UNCITED
bridge cells; nothing about interval coverage on any route (D-181 #2 stands);
and nothing about whether the fences it describes are the *right* calls -- only
what they are, who made them, and what a user should do meanwhile.

Guarded by `tests/testthat/test-parity-fenced-boundaries.R`: if a fence lifts,
that test fails and the entry above must be rewritten rather than quietly
outlived.
