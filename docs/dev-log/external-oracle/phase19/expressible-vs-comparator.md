# drmTMB expressible surface vs. external comparator existence

Author: Boole (formula/API reviewer), Phase 19 external-oracle survey.
Structurally revised 2026-08-15 (Ada, round 5) after `gate4-claims.md` returned NOT-DONE
with four blocking findings. What changed in round 5 is described at the end of this file
and, per finding, in `plan-repair-changelog.md`, "Round 5 — structural".

## Scope, and what OVERLAP and FRONTIER mean here

This document separates what `drmTMB` can currently fit (per
`docs/design/01-formula-grammar.md`, `docs/design/02-family-registry.md`, `R/family.R`) into
two regions.

**The set this survey searched, named here because both definitions depend on it:** the 25
packages listed in `drmTMB`'s `DESCRIPTION` under `Suggests`, quoted in full in "What was
searched" below. **No CRAN search was made, for any row of this document.** A comparator was
actually executed for some rows and not for others; the per-row **"Actually run?"** column of
the table below says which, row by row.

- **OVERLAP** — the region where a package **in that set** fits a statistically equivalent
  model. An OVERLAP verdict states whether the comparator was actually run for that row or
  the judgement is a documentation read.
- **FRONTIER** — the region where **this survey found no comparator in the set it searched
  (`DESCRIPTION` `Suggests`), having in most rows searched that set by reading package
  documentation rather than by running anything**. FRONTIER is a statement about what this
  survey found in that set. It is **never** a statement that no implementation exists, and it
  must not be read, quoted, or inherited as one.

Both definitions name the searched set and the run status in the same sentence, which is the
rule this document is held to ("How this document states comparator absence **and
presence**", below). Round 4 corrected fifteen *uses* of the token FRONTIER while leaving the
token defined as "the region where none can" — an unqualified absence assertion that every
use inherited (`gate4-claims.md` G4-B1, BLOCKING). Redefining the term is the fix; correcting
instances of a term is not correcting the term.

`docs/design/242-external-comparator-evidence-class.md` is the governing policy: comparator
agreement licenses only the overlap region, and treating it as evidence for the frontier is
named "credibility-laundering" in that doc
(`docs/design/242-external-comparator-evidence-class.md:86-91`; **repointed 2026-08-15** —
the `:82-84` this line carried is inside the 2026-08-15 amendment, about whether an `lme4`
point-agreement block was withheld from the ledger, and is the third instance of the
stale-citation class corrected in this file).

All family names, dpars, and evidence language below are quoted or closely paraphrased from
`docs/design/02-family-registry.md:68-118` (the Slice 283 family/evidence table) and
cross-checked against `R/family.R:25-501` for the implemented `name`/`n_response`/`dpars`
fields. Random-effect grammar claims are cross-checked against
`docs/design/01-formula-grammar.md:201-202, 1087-1088, 1130-1160`.

## Verified: correlated slopes are Gaussian-only

`docs/design/01-formula-grammar.md:1143-1145` states directly: "Random
intercepts, random slopes with one numeric predictor per random-slope term, and
labelled or unlabelled ordinary correlated intercept-slope blocks are currently
implemented for the univariate Gaussian `mu` formula; multiple separate
independent slope terms are allowed [for other formulas]." The Gaussian `sigma`
row (`docs/design/01-formula-grammar.md:202`) repeats the same distinction:
"Residual-scale random intercepts, independent numeric slopes, and unlabelled
ordinary correlated intercept-slope or multi-slope blocks... Separate terms
remain independent; a single multi-coefficient bar term estimates its
within-block correlations."

For every non-Gaussian family in the Slice 283 table
(`docs/design/02-family-registry.md:68-118`), the random-effect column
consistently uses the phrase "ordinary unlabelled `mu` random intercepts and
independent numeric slopes" (Student-t, skew-normal, lognormal, Gamma, tweedie,
beta, zero_one_beta, binomial, beta-binomial, Poisson, NB2, truncated NB2,
cumulative_logit all use this wording verbatim or near-verbatim). None of these
rows grants a correlated `(1 + x | id)` block as a general capability.

**One documented exception, narrowly scoped:** binomial. Both
`docs/design/02-family-registry.md:106` ("one complete-data unlabelled
correlated intercept-slope block is experimental and point-fit-only") and
`docs/design/01-formula-grammar.md:1087` ("Binomial additionally admits one
experimental complete-data unlabelled `(1 + x | id)` point-fit route") confirm
this. It is explicitly **not** inference-ready — only the independent-slope
domain (`mc-0061`) is "inference_ready_with_caveats"; the correlated-slope route
is point-fit-only and experimental.

So the claim to verify — "binomial/Poisson/NB2 support only INDEPENDENT
slopes" — is confirmed for Poisson and NB2 without qualification, and confirmed
for binomial **except** for one experimental, point-fit-only, not-inference-ready
correlated intercept-slope cell that has no interval/coverage claim attached.
No comparator/family-map or evidence-tier language upgrades that one cell beyond
point-fit; it does not contradict the "independent slopes only" characterization
of the *supported* surface.

## How this document states comparator absence **and presence**

**The rule this document is held to** (`PR2-build-plan.md` §8.5, extended to presence in
round 5 per `gate4-claims.md` G4-S1):

> **No sentence may assert that a comparator is absent, and no sentence may assert that a
> comparator exists and fits, unless the same sentence names (a) the set that was searched
> or the package named, and (b) whether a comparator was actually run.** A table cell, a
> parenthetical, a column entry and a heading each count as a sentence.

The rule was one-way until round 5. Absence was governed; presence was not, and several
presence claims in this very document named packages that are **not installed on this
machine** and were never executed (`gate4-claims.md` G4-S1). An unverified OVERLAP claim is
the same credibility defect as an unverified FRONTIER claim pointed the other way: it tells
the reader a check is available that nobody performed, and it shrinks the apparent frontier.
Doc 242's concern is that the two regions not be blurred; a wrongly-placed boundary blurs
them whichever side the error falls on.

### What was searched, once, for the whole document

The set is `drmTMB`'s `DESCRIPTION` `Suggests` list, read in place 2026-08-15:

```
ape, callr, detectseparation, emmeans, extraDistr, fmesher, glmmTMB, ggplot2,
JuliaCall, knitr, lme4, MASS, metafor, mvtnorm, numDeriv, ordinal, palmerpenguins,
pkgload, rmarkdown, sf, spelling, statmod, testthat, tweedie, withr
```

**No CRAN search was made, for any row.** For most rows that set was searched by reading
package documentation, not by running anything; the table's "Actually run?" column is what
distinguishes the two.

### Installed status of the non-`Suggests` packages this document names

Measured 2026-08-15 in `.worktrees/phase19` with

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'for (p in c("gamlss","sn","VGAM","cplm","brms","MCMCglmm","betareg","metadat"))
     cat(p, ifelse(nzchar(system.file(package = p)), "INSTALLED", "ABSENT"), "\n")'
```

| Package | On this machine | In `Suggests`? | Run in Phase 19? |
| --- | --- | --- | --- |
| `gamlss` | **ABSENT** | no | no |
| `sn` | **ABSENT** | no | no |
| `cplm` | **ABSENT** | no | no |
| `VGAM` | installed | no | no |
| `brms` | installed | no | no |
| `MCMCglmm` | installed | no | no |
| `betareg` | installed (3.2.5) | no | no |
| `metadat` | installed (transitively via `metafor`) | **no** — see `PR2-build-plan.md` §9.3 | yes, as the data source for Comparisons 2 and 3 |

Every presence claim naming one of the first six packages is therefore a claim about what
their documentation says, not about a fit anybody performed here. The rows that made such
claims are `student()`, `skew_normal()`, `tweedie()`, `beta()`, `beta_binomial()` and the
OVERLAP summary; each now says so in the same cell.

### Comparators actually executed anywhere in Phase 19

Eleven executions, all in the feasibility batches, attributed to the family row they bear on:

| # | Executed comparator | Family row | Source |
| --- | --- | --- | --- |
| 1 | `lme4::glmer` on `cbpp` (herd RE) | `binomial()` | `feasibility-batch-3.md:138-144` |
| 2 | `metafor::rma.uni(method = "ML")` on `dat.bcg` | `gaussian()` (`meta_V`) | `feasibility-batch-2.md:46-52` |
| 3 | `metafor::rma.mv(struct = "DIAG")` on `dat.bcg` | `gaussian()` (`meta_V`, `sigma ~ alloc`) | `feasibility-batch-2.md:118-129` |
| 4 | `ordinal::clm` on `wine` | `cumulative_logit()` | `feasibility-batch-2.md:183-191` |
| 5 | `ordinal::clmm` on `wine` (judge RE) | `cumulative_logit()` | `feasibility-batch-3.md:60-68` |
| 6 | `ordinal::clm(scale = ~ temp)` on `wine` — fits a model drmTMB **rejects** | `cumulative_logit()` | `feasibility-batch-2.md:162-191` |
| 7 | `glmmTMB` `dispformula = ~ Days` on `sleepstudy` (fixed-effect `sigma`) | `gaussian()` | `feasibility-batch-1.md:40-43` |
| 8 | `glmmTMB` gaussian on `log(y)` with `dispformula = ~ sex` on `penguins` | `lognormal()` | `feasibility-batch-3.md:208-213` |
| 9 | `glmmTMB` `dispformula = ~ FoodTreatment` on `Owls` | `nbinom2()` | `feasibility-batch-1.md:142-149` |
| 10 | `glmmTMB` `dispformula = ~ (1 \| Subject)` on `sleepstudy` — **random effect on dispersion**; runs, returns a variance component, degenerate | `gaussian()` | `feasibility-batch-1.md:66-73` |
| 11 | `glmmTMB(cbind(bill_length_mm, bill_depth_mm) ~ species)` on `penguins` — **rejects** the call, `"matrix-valued responses are not allowed"` | `biv_gaussian()` | `feasibility-batch-4.md:52-73` |

(Eleven rows; #6 and #11 are rejections rather than agreements, which is why the count of
*agreeing* comparisons is eight.) **Eleven of the seventeen family rows had no comparator
executed for them at all.** That is what the table's third new column exists to show without
anyone having to sweep for it.

### The three claim classes

They are how a compliant sentence is built, not a list of approved strings:

- **(A) No comparator found** — the stated set was searched and nothing in it fits.
- **(B) A comparator fits, or fits and fails** — something accepts the syntax; it is not
  usable here.
- **(C) A comparator may fit; it was not checked** — not installed, not a dependency, not
  run, or a different inferential framework.

**When uncertain between A and C, write C.** Class A is the strongest of the three and the
hardest to support: it requires having looked.

### The column contract for the table below (round 5, `gate4-claims.md` G4-B2/G4-B3)

Every row of the per-family table carries three dedicated columns — **claim class (A/B/C)**,
**set searched**, **actually run?** — and **all three must be non-empty for all seventeen
rows**. A blank, a bare dash, or a cell that names no set and no run status is a **visible
defect on sight**, with no sweep required to find it. That is the point of the columns: the
rule stops being something a reader must remember to apply and becomes something the table's
shape enforces.

**A claim-class cell must carry a letter whenever the row makes a claim of either kind. The
one permitted letterless cell is a row that makes no claim of either kind — no absence claim
and no presence claim — and it must say so** (added in round 6, `gate5-claims.md` G5-S4).
"No absence claim in this row" is not by itself a reason to omit the letter: an *unverified*
presence half is class C, and "when uncertain between A and C, write C" makes declining to
write a letter where the class is **determinate** strictly worse than the case that rule was
written for. Two cells were repaired under this line — `beta_binomial()` and
`biv_lognormal()`, both now **C**. `biv_student()` is the permitted letterless cell: it
claims nothing either way and its cell says exactly that. `binomial()` is letterless on a
different and narrower ground — its presence claim is neither absent nor unverified but
**demonstrated by an executed, agreeing `lme4::glmer` fit**, which is the one status A/B/C
was not built to letter; `gate5-claims.md` G5-S4 examined that cell and passed it. Any future
letterless cell must be one of these two shapes and must name which. A blank cell names
neither, so a blank stays visibly wrong.

**There is no blanket default, and there must not be one.** Round 4 carried a document-wide
instruction to "read every unmarked FRONTIER verdict as class C". That instruction was
deleted in round 5 (`gate4-claims.md` G4-B3): it was a prose caveat repairing table cells,
installed 25 lines below a rule that says the clause must be in the cell — the exact
mechanism `PR2-build-plan.md:771` rules out at source ("**No prose caveat elsewhere repairs
a summary table**"), and the exact reason nobody went looking for unmarked rows. Nothing
below is rescued by a paragraph elsewhere. If a cell is incomplete, the cell is wrong.

## Per-family table

Columns: **dpars** and **submodels with predictors** (from the family's `dpars` and the Slice
283 table); **random-effect forms supported now**; **comparator verdict** (OVERLAP / FRONTIER,
as those terms are defined at the top of this file); then the three round-5 columns —
**claim class**, **set searched**, **actually run?**. Dated correction markers are kept in
"Row correction record" below the table; the clause-bearing content is in the row.

| Family (`R/family.R` name) | dpars | Submodels with predictors | Random-effect forms (current) | Comparator verdict for the SAME model | Claim class (A/B/C) | Set searched | Actually run? |
|---|---|---|---|---|---|---|---|
| `gaussian()` | mu, sigma | mu, sigma both formula-capable | mu: intercepts, independent slopes, q>2 numeric slope blocks, selected labelled intercept covariance; sigma: intercepts, independent slopes, unlabelled correlated intercept-slope/multi-slope; selected `sd(group)`; `meta_V()`, `phylo()`, `spatial()` are separate rows | OVERLAP for plain fixed/random-intercept mu and for a **fixed-effect** `sigma` submodel (`lme4`, `glmmTMB`, `metafor` under `meta_V`); FRONTIER for `sigma` **random** effects, `sd(group)` regression, and any `phylo()`/`spatial()`/`animal()`/`relmat()` route. See row note R1 | **B** for the `sigma`-RE half — `glmmTMB`'s `dispformula` accepts a random effect and was run; **C** for `sd(group)` regression and every structured route | `DESCRIPTION` `Suggests` (25 packages, above); no CRAN search. `gamlss`, doc 158's other nominated scale-RE comparator, is outside that set and **absent from this machine** | **Yes, four runs:** `glmmTMB` fixed-effect `sigma` (`feasibility-batch-1.md:40-43`); `metafor::rma.uni` and `rma.mv` under `meta_V` (`feasibility-batch-2.md:46-52`, `:118-129`); `glmmTMB` `dispformula = ~ (1\|Subject)` (`feasibility-batch-1.md:66-73`), which ran and returned a degenerate variance component. **No** run for `sd(group)` or any structured route; `gamlss` not run |
| `student()` | mu, sigma, nu | mu, sigma, nu (nu = tail shape/df) | mu: intercepts + independent slopes; one diagnostic-only `spatial()` mu intercept/slope, one diagnostic-only `phylo()` nu intercept | OVERLAP for fixed-effect + mu-RE-only Student-t location-scale is **asserted from documentation only**: the packages named for it, `gamlss` and `brms`, were never run and `gamlss` is absent from this machine. FRONTIER for phylo/spatial-structured nu or mu. See row note R2 | **C** on both halves — the frontier half was not searched beyond `Suggests` and not run; the overlap half names two packages neither of which was run | `DESCRIPTION` `Suggests`; no CRAN search. `gamlss` (absent from this machine) and `brms` (installed, not in `Suggests`) were read about, not searched systematically and not run | **No.** No comparator was executed for any Student-t claim in this survey, presence or absence |
| `skew_normal()` | mu, sigma, nu | mu, sigma, nu (nu = slant) | mu: intercepts + independent slopes only | OVERLAP for fixed-effect skew-normal is **asserted from `sn`'s documentation only** — `sn` is absent from this machine and was never run, so "fits fixed-effect only, no RE" is a documentation reading, not a tested limit. FRONTIER once mu random effects are added. See row note R3 | **C** on both halves | `DESCRIPTION` `Suggests`; no CRAN search. `sn` and `gamlss.dist` are outside it; `sn` is absent from this machine | **No.** No `sn`, `gamlss.dist` or other skew-normal comparator was run |
| `lognormal()` | mu, sigma | mu, sigma | mu: intercepts + independent slopes (separate gate); sigma: one random intercept (separate gate, cannot combine with mu RE); one recovery-grade `phylo()`/`relmat()` mu intercept | OVERLAP for the fixed-effect mu + fixed-effect `sigma` model, **run and agreeing**: `glmmTMB` gaussian on `log(y)` with `dispformula`. FRONTIER for the `sigma` **random** intercept and for phylogenetic mu. See row note R4 | **C** for both frontier halves — a `glmmTMB` `dispformula` random effect is plausible on the `gaussian(link=log)` route (it was demonstrated on the gaussian row) and was **not tried** for lognormal | `DESCRIPTION` `Suggests`; no CRAN search | **Yes, one run**, on the overlap half only: `glmmTMB` gaussian on `log(y)`, `dispformula = ~ sex` (`feasibility-batch-3.md:208-213`). **No** run for lognormal `sigma`-RE or phylogenetic mu |
| `Gamma(link="log")` | mu, sigma | mu, sigma (internal shape = 1/sigma^2) | mu: intercepts + independent slopes (separate gate); sigma: one random intercept (separate gate); recovery-grade `relmat()`/`phylo()` mu intercept | OVERLAP for mu-RE Gamma GLMM asserted from `glmmTMB(family=Gamma)`'s documentation; not run here. FRONTIER for the `sigma` random intercept. See row note R5 | **C** on both halves. Not class A: `glmmTMB`'s `dispformula` accepts a random effect (shown on the gaussian row), so the supportable claim is "not tested", not "no comparator" | `DESCRIPTION` `Suggests`; no CRAN search | **No.** No Gamma comparator of any kind was run in this survey |
| `tweedie()` | mu, sigma, nu | mu, nu (nu ~ 1 only) | mu: intercepts + independent slopes | OVERLAP for the fixed/mu-RE Tweedie mean is asserted from documentation: `glmmTMB(family=tweedie)` is in `Suggests` but was not run for this row, and `cplm` is outside the set and absent from this machine. FRONTIER for any structured/phylo/spatial route — currently moot, since none is implemented on tweedie. See row note R6 | **C** on both halves | `DESCRIPTION` `Suggests`; no CRAN search. `cplm` is outside it and absent from this machine | **No.** Neither `glmmTMB(family=tweedie)` nor `cplm` was run for this row |
| `beta()` | mu, sigma | mu, sigma | mu: intercepts + independent slopes; one recovery-grade `animal()` mu intercept/slope OR one sigma intercept, one endpoint at a time | OVERLAP for fixed/mu-RE Beta regression asserted from documentation (`glmmTMB(family=beta_family)` in `Suggests`, not run; `gamlss` outside the set and absent from this machine; `betareg` installed but not in `Suggests`). FRONTIER for `animal()`-structured mu/sigma. See row note R7 | **C** on both halves | `DESCRIPTION` `Suggests`; no CRAN search. `gamlss` absent from this machine; `betareg` installed but outside `Suggests` and its addition is a dependency decision (`PR2-build-plan.md` §7) | **No.** No beta-regression comparator was run |
| `zero_one_beta()` | mu, sigma, zoi, coi | mu, sigma, zoi, coi all formula-capable | mu: intercepts + independent slopes (inference-ready with caveats for the slope cell); sigma/zoi: point-fit-only q1 intercepts and matching slopes; coi: point-fit-only q1 intercept/slope | FRONTIER throughout. The closest analogues named in the literature (`gamlss.dist` BEINF, `brms` `zero_one_inflated_beta`) are absent from `Suggests`; on a documentation read they do not share this zoi/coi random-effect grammar. See row note R8 | **C** throughout — "none found by this survey in the set it searched", not a demonstrated absence | `DESCRIPTION` `Suggests`; no CRAN search. `gamlss.dist` and `brms` are outside it | **No.** Neither analogue was run, and no zero-one-inflated-beta comparator of any kind was executed |
| `beta_binomial()` | mu, sigma | mu, sigma | mu: intercepts + independent slopes | OVERLAP for fixed/mu-RE beta-binomial counts asserted from documentation: `glmmTMB(family=betabinomial)` is in `Suggests` but was not run for this row, and `VGAM` is installed but outside `Suggests` and was not run. No structured/`sigma`-RE cells exist yet, so there is **no frontier cell to report** for this family. See row note R9 | **C** — no absence claim in this row; nothing here asserts a comparator is missing. The presence half is **unrun documentation**: `glmmTMB(family=betabinomial)` may fit and was not checked | `DESCRIPTION` `Suggests`; no CRAN search. `VGAM` installed, outside the set | **No comparator run.** One **drmTMB-side** fit was attempted and failed — `sigma ~ period` on `cbpp`, "false convergence (8)", `NaN` SEs (`candidate-cells.md:322-325`) — which is a drmTMB result, not a comparator result |
| `stats::binomial(link="logit")` | mu | mu only | mu: intercepts + independent slopes (inference-ready with caveats); one experimental point-fit-only correlated `(1+x\|id)` block | OVERLAP for the whole supported surface, and the only row where that is **demonstrated rather than asserted**: `lme4::glmer` was run on `cbpp` and agrees. The experimental correlated-slope cell has the same `lme4` comparator; it is simply not promoted past point-fit | **No absence claim in this row** | `DESCRIPTION` `Suggests`; no CRAN search — and none needed for the presence claim, which rests on an executed fit | **Yes:** `lme4::glmer(family = binomial)` on `cbpp`, agreeing at ~1e-3 (`feasibility-batch-3.md:138-144`) |
| `poisson(link="log")` | mu (+ zi) | mu, and zi as a separate fixed-effect route | mu: intercepts + independent slopes + one q=1 structured intercept (`phylo`/`phylo_interaction`/`spatial`/`animal`/`relmat`) + one unlabelled intercept-plus-slope structured term; zi: fixed-effect only, one diagnostic-only `spatial()` zi intercept | OVERLAP for mu-RE-only Poisson asserted from documentation (`lme4::glmer`, `glmmTMB`; both in `Suggests`, neither run for this row). FRONTIER for every structured `mu` route and for the `spatial()` zi intercept | **C** on both halves | `DESCRIPTION` `Suggests`; no CRAN search | **No.** No Poisson comparator was run in this survey |
| `nbinom2()` | mu, sigma (+ zi) | mu, sigma, zi | mu: as Poisson above, plus structured `sigma` intercept-plus-slope for the same 4 providers at recovery grade; sigma: one ordinary random intercept + structured q1 routes; zi: fixed-effect only, one local-fit `spatial()` mu intercept with fixed zi | OVERLAP for mu-RE + **fixed-effect** `sigma` NB2, **run and agreeing** (`glmmTMB(family=nbinom2)` with `dispformula`). FRONTIER for `sigma` **random** effects and every structured mu/sigma route. See row note R10 | **C** for the frontier halves. Not class A: `glmmTMB`'s `dispformula` accepts a formula-driven random effect (gaussian row), so the supportable NB2 claim is "not tested" | `DESCRIPTION` `Suggests`; no CRAN search | **Yes, one run**, on the overlap half only: `glmmTMB` `dispformula = ~ FoodTreatment` on `Owls` (`feasibility-batch-1.md:142-149`). **No** NB2 `sigma`-RE or structured comparator was run |
| `truncated_nbinom2()` (+ hurdle `hu`) | mu, sigma (+ hu) | mu, sigma, hu | mu: intercepts + independent slopes; hu: fixed-effect, one diagnostic-only `relmat()` hu intercept | OVERLAP for mu-RE-only zero-truncated NB2 asserted from documentation (`glmmTMB(family=truncated_nbinom2)`, in `Suggests`, not run for this row). FRONTIER for the `relmat()`-structured hurdle intercept | **C** on both halves | `DESCRIPTION` `Suggests`; no CRAN search | **No.** No truncated-NB2 comparator was run |
| `cumulative_logit()` | mu (ordered cutpoints) | mu only | mu: intercepts + independent slopes; one local-fit `phylo()` mu intercept; separate technical-only AGHQ+Cox-Reid REML study (`mc-0227`, M>=80) | OVERLAP for mu-RE-only ordinal, **run and agreeing** on both the fixed-effect and judge-RE forms (`ordinal::clm`, `ordinal::clmm`). The same comparator fits a **scale** submodel drmTMB rejects (`clm(scale = ~ temp)`), which is this survey's only demonstrated asymmetry in the comparator's favour. FRONTIER for the `phylo()` mu intercept. This is also the one row with an internal, non-public REML comparator study against `glmer`/brute-force (`docs/design/02-family-registry.md:118`) | **C** for the `phylo()` frontier half — not searched beyond `Suggests`, not run. **No absence claim** on the overlap half | `DESCRIPTION` `Suggests`; no CRAN search | **Yes, three runs:** `ordinal::clm` (`feasibility-batch-2.md:183-191`), `ordinal::clmm` (`feasibility-batch-3.md:60-68`), and `ordinal::clm(scale = ~ temp)` (`feasibility-batch-2.md:162-191`). **No** run for the `phylo()` mu intercept |
| `biv_gaussian()` / `c(gaussian(),gaussian())` | mu1, mu2, sigma1, sigma2, rho12 | all four formula-capable | fixed effects; selected labelled random-intercept covariance; matching slope-only mu/sigma blocks; q4/q6 location blocks; first all-four q8 endpoint block; selected phylogenetic and constant-coordinate spatial blocks | FRONTIER throughout, and the row splits into two different claims: predictor-dependent `rho12 ~ x`, where the one `Suggests` package that could take a two-column response **was run and rejected the call**; and bivariate LSS with structured covariance, which was neither searched beyond `Suggests` nor run. See row note R11 | **A within `DESCRIPTION` `Suggests`, for predictor-dependent `rho12 ~ x` only.** **C** for the structured-covariance remainder | `DESCRIPTION` `Suggests`; **no CRAN search for any part of this row**. `MCMCglmm` and `brms` are installed on this machine but outside `Suggests`, are Bayesian, and on a documentation read do not share this q-series block/label grammar | **Yes, one run**, and only for the `rho12 ~ x` half: `glmmTMB(cbind(bill_length_mm, bill_depth_mm) ~ species)` returns `"matrix-valued responses are not allowed"` (`feasibility-batch-4.md:52-73`). **No** run for any structured-covariance form; `MCMCglmm`/`brms` never tried |
| `biv_lognormal()` | mu1, mu2, sigma1, sigma2, rho12 | fixed-effect mu1/mu2 only; sigma/rho12 intercept-only | none (all random/structured effects deferred) | The fixed-effect-only cell is a narrow OVERLAP surface asserted from reasoning, not from a fit: a bivariate lognormal with fixed `rho12` is reproducible via a transformed-scale bivariate-normal fit in general software. No RE surface exists, so there is **no frontier cell to report** | **C** — no absence claim in this row. The presence half is an **unrun inference**, not a documentation read of a named package, so it is weaker than C's usual warrant: no package is even named | `DESCRIPTION` `Suggests`; no CRAN search | **No.** No bivariate-lognormal comparator was run |
| `biv_student()` | mu1, mu2, sigma1, sigma2, nu, rho12 | fixed-effect mu1/mu2 only; scales/nu/rho12 intercept-only | none | Source-evidence only, no capability claim; not comparator-relevant yet. **Neither an OVERLAP nor a FRONTIER verdict is asserted for this row** | **No claim of either kind** | not searched — no claim depends on a search | **No.** Nothing was run |

**Reading the three new columns.** Eleven of the seventeen rows answer "Actually run?" with
**No**. Six answer **Yes**, and of those, four (`lognormal`, `nbinom2`, `binomial`,
`cumulative_logit`) had a comparator run only on their *overlap* half, one (`gaussian`) on
both halves, and one (`biv_gaussian`) only on the frontier half. Exactly one cell in the whole
table is **class A**, and it is class A only within `Suggests`. That distribution is the
document's real epistemic state, and before round 5 it was not visible anywhere.

## Row correction record

Kept separately from the table so the clause-bearing content stays in the row and the
historical record is not lost. Every marker below is dated and names the finding that forced
it.

- **R1 (`gaussian()`), classified 2026-08-15, `gate3-claims.md` G-B1.** The `sigma`-RE half
  is class B, not an absence: `glmmTMB`'s `dispformula` accepts a random effect, **was run**
  on `sleepstudy`, and returned a degenerate variance component
  (`feasibility-batch-1.md:66-73`). `sd(group)` regression and the structured routes are
  class C.
- **R2 (`student()`), presence claim marked 2026-08-15, `gate4-claims.md` G4-S1; frontier
  half classified round 5, `gate4-claims.md` G4-B2.** This row previously asserted FRONTIER
  with the bare bolded token and no clause at all, and simultaneously asserted OVERLAP by
  naming `gamlss` and `brms` — a package absent from this machine and a package never run.
  Both halves now carry their status.
- **R3 (`skew_normal()`), presence claim marked 2026-08-15, `gate4-claims.md` G4-S1.** The
  sentence "`sn` package fits fixed-effect only, no RE" was simultaneously a presence claim
  and an absence claim about `sn`'s capability, with no clause on either. `sn` is absent from
  this machine.
- **R4 (`lognormal()`), classified 2026-08-15, `gate3-claims.md` G-B1.** `glmmTMB`'s
  `dispformula` does accept a formula-driven random effect on dispersion (demonstrated on
  gaussian), so a lognormal-scale analogue via `gaussian(link=log)` on `log(y)` is plausible;
  it was not tried, and nothing beyond `Suggests` was searched.
- **R5 (`Gamma(link="log")`), corrected 2026-08-15, `gate3-claims.md` G-B1.** The cell
  previously read "sigma is a single fixed dispersion in glmmTMB, not a modelled/RE
  parameter" and "glmmTMB has no formula for dispersion-as-random-effect". **Both are false**
  (`feasibility-batch-1.md:66-73`). Deleted; the supportable claim is "not tested".
- **R6 (`tweedie()`), frontier half classified round 5, `gate4-claims.md` G4-B2; presence
  half marked, G4-S1.** This row previously asserted FRONTIER with the bare token and no
  clause, and named `cplm` as a comparator without saying it is absent from this machine.
- **R7 (`beta()`), narrowed 2026-08-15; presence half marked round 5, `gate4-claims.md`
  G4-S1.** The "no comparator fits …" phrasing became "none found by this survey, none
  tried"; the `gamlss` presence claim now says the package is absent from this machine.
- **R8 (`zero_one_beta()`), classified 2026-08-15, `gate3-claims.md` G-B1.** Previously
  "FRONTIER throughout — no established package fits a four-parameter zero-one-inflated beta
  … the same way", with no scope.
- **R9 (`beta_binomial()`), presence half marked round 5, `gate4-claims.md` G4-S1.** `VGAM`
  was named as a comparator; it is installed but outside `Suggests` and was never run.
- **R10 (`nbinom2()`), corrected 2026-08-15, `gate3-claims.md` G-B1.** The parenthetical
  "fixed dispersion in glmmTMB" was **false**, same refutation as R5.
- **R11 (`biv_gaussian()`), classified 2026-08-15, `gate3-claims.md` G-B1; citation note
  re-identified by claim 2026-08-15 round 6, `gate5-claims.md` G5-S1.** *Citation note:*
  `feasibility-batch-4.md`'s **`biv_gaussian()`/`rho12` FRONTIER verdict** — in its
  *"3/4. Matched scale + verdict"* section, the sentence beginning **"Verdict: UNCERTAIN,
  unchanged from the pre-filled cell, and for the same reason:"** — cites this row **by line
  number** as authority for "no comparator to check it against". Cite it by row
  (`biv_gaussian()`), not by line, and carry the class split — the whole-row form of that
  claim is class C, not class A. Until that repair lands, **that verdict sentence** is on the
  do-not-cite list (`PR2-build-plan.md` §15.9). Round 5 recorded this quarantine as
  `feasibility-batch-4.md:126-127`; that range is innocuous convergence prose and was the
  wrong target, which is why the quarantine now names the claim and not a range.
- **Round-5 note on rows R2, R6 and the `cumulative_logit()` row.** These three asserted
  FRONTIER with a bare bolded token and no clause of any kind, which is why four consecutive
  phrase-searches could not see them (`gate4-claims.md` G4-B2, BLOCKING). They were not fixed
  as three exceptions: all seventeen rows were enumerated and every one filled in, which is
  what the three new columns record.

## OVERLAP region, summarized

The overlap region is: fixed-effect models for every family, plus **`mu`-only ordinary
(unlabelled) random intercepts and independent numeric slopes** for every fitted univariate
non-Gaussian family, plus Gaussian `mu`/`sigma` random-intercept-slope models including
correlated blocks.

**How much of that is demonstrated, and how much is asserted** (marked round 5,
`gate4-claims.md` G4-S1 — this paragraph previously said the named packages "fit
statistically equivalent models and can serve as an oracle", which is a presence claim with
no run status and, for `gamlss` and `sn`, no installed package behind it):

- **Demonstrated by an executed, agreeing fit:** `lme4::glmer` for binomial mu-RE;
  `metafor::rma.uni`/`rma.mv` for gaussian under `meta_V`; `ordinal::clm`/`clmm` for ordinal
  mu-RE; `glmmTMB` for gaussian, lognormal and NB2 with a **fixed-effect** `sigma` submodel.
  Sources in "Comparators actually executed", above.
- **Asserted from documentation, not run:** `glmmTMB` for Poisson, Gamma, tweedie, beta,
  beta-binomial and truncated-NB2 mu-RE models.
- **Asserted from documentation, and the package is not installed on this machine:** `gamlss`
  (Student-t, beta, gaussian scale-RE), `sn` (skew-normal), `cplm` (tweedie).
- **Named, installed, outside `Suggests`, never run:** `VGAM` (beta-binomial), `brms`
  (Student-t, zero-one-inflated beta, bivariate), `MCMCglmm` (bivariate).

The demonstrated subset is exactly the region
`docs/design/242-external-comparator-evidence-class.md` describes as licensable by comparator
agreement (`docs/design/242...md:86-87`: "Agreement licenses the overlap region only, never
the frontier"; the citation read `:82` before the 2026-08-14 correction, which is the wrong
passage — same defect class as the `:79-80` citation corrected below). The asserted subset is
**not** licensed by anything, because nothing was run.

The one row where drmTMB has an actual REML-vs-comparator study on record is
`cumulative_logit()`'s `mc-0227`, described in `docs/design/02-family-registry.md:118` as
validated against `glmer`/brute-force at M>=80 — but that study is explicitly "package-private
technical evidence with no public interval or reporting permission," so even this
comparator-backed cell does not license a public interval claim.

## FRONTIER region, summarized

> **Correction, 2026-08-14 (Ada, PR 2 build-plan round 3).** Two errors in this section are
> fixed below. (1) The citation at the head of this list pointed at
> `docs/design/242-…:79-80`; that range is inside the 2026-08-15 amendment, about whether an
> `lme4` point-agreement block was withheld from the ledger. The frontier passage is at
> `:86-91`, its example list at `:87-88`. (2) Class 1's claim that no comparator models a
> formula-driven random effect on dispersion is **false**, and it was the upstream source of
> a false claim that reached the drafted article twice. Both are corrected in place; the
> original class-1 sentence is quoted inside the correction so the record is not lost. See
> `PR2-build-plan.md` §8.5 and §11.
>
> **Second correction, 2026-08-15 (round 4 — narrowing).** The round-3 fix reached this
> section and stopped at its boundary; the per-family table above repeated the same refuted
> proposition twice and four further rows asserted absence with no scope
> (`gate3-claims.md` G-B1, BLOCKING). Ten rows were corrected and the claim-class preamble was
> moved above the table.
>
> **Third correction, 2026-08-15 (round 5 — structural).** Round 4's sweep was a search over
> a phrase, so it could not see three rows that asserted absence with nothing but the bolded
> token, and it left the token itself defined at the top of this file as "the region where
> none can" (`gate4-claims.md` G4-B1/G4-B2, both BLOCKING). Round 5 **redefined the term**,
> **added three per-row columns** so incompleteness is visible without a sweep, **deleted the
> blanket class-C default** that made unmarked rows feel safe, and **extended the rule to
> presence claims**. This section now refines a scoped term instead of rescuing an unscoped
> one.

Four classes of frontier surface recur across nearly every family row, matching the frontier
examples named in `docs/design/242-external-comparator-evidence-class.md:86-91`
("Where `drmTMB` is genuinely novel — scale-side random effects, `sd()` regression,
bivariate LSS, phylogenetic structure on residual log-SD — no established
implementation exists to borrow credibility from", the example list at `:87-88`):

**Note on that quotation, added 2026-08-15.** Doc 242's sentence is quoted here for its
*list*, not for its verdict. Its verdict — "no established implementation exists" — names no
searched set and no run, and it is **too strong for its own first item**: Phase 19 ran a
comparator against scale-side random effects and `glmmTMB` accepted the model and returned a
variance component (`feasibility-batch-1.md:66-73`). Do not quote doc 242's verdict onward
from here without the class split below. The over-claim in the governing design document is
reported upward in `PR2-build-plan.md` §10.5.

**Frontier does not mean "no comparator exists"** — see the definition at the top of this
file, which now says so in the term itself rather than in a caveat below it. These four
classes differ in *why* they are frontier, and the three cases must not be merged. The
classes A / B / C are defined once, for the whole document, in "How this document states
comparator absence **and presence**" above, together with the set searched (`DESCRIPTION`
`Suggests`, never CRAN) and the eleven comparator executions this survey actually performed.
**Each class below carries its own class marker; there is no default for one that does not**
(`gate4-claims.md` G4-B3).

1. **Scale-side (`sigma`) random effects** — present for Gaussian, lognormal,
   Gamma, NB2 (ordinary intercepts), plus structured NB2 sigma routes. **Class B, not
   class A.** `glmmTMB` **does** accept a formula-driven random effect on dispersion:
   `glmmTMB(Reaction ~ Days, dispformula = ~ (1 | Subject), data = sleepstudy)` runs and
   returns a dispersion variance component. On `sleepstudy` it is degenerate —
   `VarCorr(g)$disp` gives `Variance = 1.521243e-12`, `Std.Dev. = 1.233387e-06`, with a
   non-positive-definite Hessian, `NA` for AIC/BIC/logLik, and a convergence warning
   (`feasibility-batch-1.md:66-90`; re-run 2026-08-14 for this correction). The supportable
   claim is therefore **"the comparator accepts this model and its fit is degenerate on the
   one dataset tested"**, not that no package expresses it. `gamlss`, doc 158's other
   nominated scale-RE comparator, is **absent from this machine and was never tested**
   (class C).

   > *Superseded sentence, kept for the record:* "No comparator package models residual-scale
   > as a random effect the way drmTMB does; `glmmTMB` treats dispersion as a fixed nuisance
   > parameter, not a formula-driven random-effect target." This is refuted by the run above.
   > It is quoted approvingly at `candidate-cells.md:97-99`, which must be corrected before
   > that file is cited.
2. **Structured providers on any parameter** (`phylo()`, `phylo_interaction()`,
   `spatial()`, `animal()`, `relmat()`) — present as q1 intercepts, sometimes
   intercept-plus-slope, across Poisson, NB2, Gaussian, Student-t, Gamma, beta,
   truncated NB2 (hurdle), cumulative_logit, and the bivariate q4/q8/spatial/
   phylogenetic blocks. **Class C — `DESCRIPTION` `Suggests` was read, nothing beyond it was
   searched, and no comparator was run for any of these.** The author knows of no
   established R package that fits a GLMM/GLM with a pedigree- or coordinate-derived
   correlation structure on a non-Gaussian `mu` or on any `sigma`/`zi`/`hu` parameter the
   same way; that is a statement about what this survey knows, not about what exists.
3. **`sd(group)` regression / `sd(..., level=)` grammar** — noted only for
   Gaussian ("selected `sd(group)` SD-surface formulas"); this is a
   drmTMB-specific latent-SD-regression grammar with no analogue known to this
   survey. **Class C — `Suggests` read, nothing beyond it searched, nothing run.**
4. **Bivariate location-scale-scale (LSS) with structured covariance** — the
   `biv_gaussian()` q4/q6/q8 endpoint blocks and phylogenetic/spatial
   bivariate slots. `MCMCglmm` and `brms` fit multivariate mixed models but not
   with this q-series block/label grammar, and neither offers this ML/Laplace
   engine with matching extractors. **Class C for `MCMCglmm`/`brms`** — both are
   Bayesian, both are absent from `DESCRIPTION` `Suggests` (both are installed on this
   machine, which changes nothing: neither was run). The one member of this neighbourhood
   that *was* tested is predictor-dependent `rho12 ~ x`, where `glmmTMB` — the only
   `Suggests` package that could take a two-column response — rejects the call with
   `"matrix-valued responses are not allowed"` (`feasibility-batch-4.md:52-73`). That single
   instance is class A **within `Suggests`**; it does not license a class-A claim for the
   whole class.

**Also frontier, stated with the same clauses:** `zero_one_beta()`'s zoi/coi random-effect
cells — no package known to this survey shares the exact four-parameter
zero-one-inflated-beta random-effect grammar, `Suggests` was read, nothing beyond it was
searched, and nothing was run — and any zero-inflation or hurdle random effect beyond the two
diagnostic-only `spatial()`/`relmat()` intercepts noted above, for which likewise **nothing
was searched beyond `Suggests` and nothing was run** (second conjunct scoped in round 5,
`gate4-claims.md` G4-S2; `PR2-build-plan.md:734-736` already stated it correctly and this
file was the weaker source).

## Files consulted

- `docs/design/01-formula-grammar.md` (lines 201-202, 1087-1088, 1130-1160 for
  random-effect grammar; line 176 for `biv_student()`; line 110 for `rho12`)
- `docs/design/02-family-registry.md` (lines 68-118, the Slice 283 family
  table; lines 151-233 shape/random-effect boundary sections)
- `R/family.R` (lines 25-501, `name`/`n_response`/`dpars` fields per family,
  cross-checked against the registry table)
- `DESCRIPTION` (`Suggests`, read in place 2026-08-15 — the set this survey searched)
- `docs/design/242-external-comparator-evidence-class.md` (governing policy on
  what comparator agreement may and may not license; the credibility-laundering
  warning at lines **86-91**, its frontier example list at `:87-88`, the independence
  classifications at `:108-111`, and the amendment at lines 51-73. **Repointed
  2026-08-15** from `79-84`, same stale-citation class as above)
- `feasibility-batch-1.md` … `feasibility-batch-4.md` (the eleven comparator executions
  tabulated above)

## Uncertainty flagged

- This survey is a documentation-level read, not a fresh code trace of every
  random-effect gate in `R/`. Where the registry text is itself ambiguous
  (e.g., whether a "diagnostic-only" cell counts as OVERLAP or FRONTIER when a
  comparator exists for the underlying model but not the exact structured
  term), I have classified by the structured-term test, since that is what
  makes the model novel.
- I did not re-run any fits; all claims are sourced to the design docs and
  `R/family.R`, per the hard constraint against editing/running comparisons in
  this slice. The eleven comparator executions tabulated above were run by the feasibility
  batches, not by this document.
- **"Searched" is weaker than it sounds for most rows.** For eleven of the seventeen rows the
  search consisted of reading the `Suggests` list and the candidate packages' documentation.
  Only the six rows marked "Yes" under "Actually run?" rest on an executed fit. Round 5 made
  that distribution visible in the table rather than leaving it to be reconstructed.

## Change record — round 5 (structural), 2026-08-15

Four blocking findings from `gate4-claims.md`, each answered by a change to the document's
structure rather than to its wording:

1. **G4-B1 — the term is redefined, not its instances.** FRONTIER no longer means "the region
   where none can". It means what this survey found in `DESCRIPTION` `Suggests`, and the
   definition names the set and the run status in its own sentence, satisfying the rule the
   document holds everything else to.
2. **G4-B2 — three columns, seventeen rows, filled by enumeration.** Not by searching for a
   phrase. The three rows that carried a bare bolded token were filled as part of the
   enumeration, not as exceptions.
3. **G4-B3 — the blanket default is deleted.** No paragraph reinterprets an unmarked cell,
   because there are no unmarked cells and an empty one is a visible defect.
4. **G4-S1 — the rule is two-way.** Presence claims now name the package and its run status.
   Six of them were false or unsupported as written; the installed-status table above is the
   measurement.
5. **G4-S2 — the "also frontier" tail's second conjunct is scoped**, matching what
   `PR2-build-plan.md:734-736` already said.
