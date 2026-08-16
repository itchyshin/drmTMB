# Phase 19 adversarial claim audit

Author: Rose (`systems_auditor`), 2026-08-14.
Worktree: `.worktrees/external-oracle`, branch `claude/external-oracle-intervals`,
drmTMB 0.7.0 (`DESCRIPTION:3`).
Reader: whoever decides whether the Phase 19 candidate set gets written up, and what
it is allowed to say when it does.

Sources audited in full: `candidate-cells.md`, `feasibility-batch-1.md` through
`feasibility-batch-4.md`, `docs/design/242-external-comparator-evidence-class.md`
including its 2026-08-15 amendment (`:53-84`). Ledger machinery read directly:
`tools/capability_ledger.py`, `tools/tests/test_capability_ledger.py`,
`docs/dev-log/dashboard/capability-ledger/cells.tsv`,
`docs/dev-log/dashboard/capability-ledger/evidence.tsv`.

**Overall verdict: NOT-DONE. Do not write this set up as composed.** Eight blocking
findings below. The feasibility work itself is good — Gauss actually fitted every cell
and corrected Ada on three points — but the *claim architecture* around it fails on all
four questions asked, and one finding (D2) puts a proposed reader-facing sentence in
direct contradiction with a boundary already recorded in the ledger.

---

## Verdict per question

| Q | Question | Verdict |
| --- | --- | --- |
| (a) | Does any cell let comparator agreement speak for the frontier? | **YES — three routes, one blocking** |
| (b) | Does any cell imply every drmTMB model has a one-to-one comparator? | **YES — by sample composition and by one false table row** |
| (c) | Is timing/runtime compared reproducibly? | **NO — not reproducible, and issue #60's five required fields are 1-of-5 present** |
| (d) | Would this need a ledger row, and is it licensable under 242? | **MIXED — some licensable, two not constructible, one redundant, one contradictory** |

---

## (a) Frontier leakage — YES

Doc 242's governing constraint names the frontier explicitly: "scale-side random
effects, `sd()` regression, bivariate LSS, phylogenetic structure on residual log-SD"
(`docs/design/242-external-comparator-evidence-class.md:86-91`). Two proposed cells sit
on that list — Cell 2 (`sigma = ~ (1 | Subject)`, scale-side RE) and Cell 10
(`biv_gaussian()` with `sigma1`/`sigma2`/`rho12` formulas, bivariate LSS).

### A1 [BLOCKING] Each frontier cell is paired with an agreeing overlap cell on the *same dataset*

- Cell 1 (sleepstudy, agrees with glmmTMB to 4-5 s.f., `feasibility-batch-1.md:29-39`)
  is immediately followed by Cell 2 (sleepstudy, frontier, no usable comparator).
- Cell 9 (penguins, agrees with glmmTMB to 7-8 s.f., `feasibility-batch-3.md:181-187`)
  is immediately followed by Cell 10 (penguins, frontier, no comparator at all).

Both pairs share the dataset, the narrative voice, and the reader's question shape
("does spread grow?" → "does each subject have their own spread?"). Labelling the second
cell FRONTIER does not undo the adjacency: 242:86-91 does not say *label* the two, it
says a design that *blurs* them is credibility-laundering, and same-dataset sequential
presentation is blurring by construction. Ada anticipated the wording risk
(`candidate-cells.md:305-309`) but not the structural one.

**What has to change before write-up.** Either separate the frontier cells into their
own section with no shared dataset thread, or attach to each frontier cell an explicit,
non-optional sentence naming the neighbouring number that does *not* transfer — e.g.
"Cell 1's 1e-6 agreement is a statement about `sigma ~ Days`; it says nothing about the
`(1 | Subject)` term in this model." A label is not a firewall.

### A2 [SERIOUS] The coverage table merges an overlap capability with a frontier one

`candidate-cells.md:48` reads: "Distributional (`sigma`/dispersion) submodel | 1, 2, 3,
5, 9 (five)". Cells 1, 3, 5 and 9 are *fixed-effect* scale submodels, which have
comparators. Cell 2 is a *random-effect* scale submodel, which per 242:86-89 is the
frontier. That single table row makes "drmTMB's distributional submodel" one validated
thing with five supporting cells. It is two things, four of which agree with something
and one of which cannot. If any version of that table reaches a reader, the merge is the
laundering — no prose caveat elsewhere in the document repairs a summary table.

### A3 [SERIOUS] The scale-side agreement is almost entirely WEAK independence

Doc 242:106-111 classifies `lme4` and `metafor` as **strong** (separate estimation
engines) and `glmmTMB` as **weak** ("built on the same TMB/AD stack and outer optimizer
as `drmTMB`"). Sorting the proposed comparators:

| Cell | Comparator | Independence per 242 | Axis validated |
| --- | --- | --- | --- |
| 1 | glmmTMB `dispformula` | weak | residual scale (fixed) |
| 3 | glmmTMB `dispformula` | weak | NB2 dispersion (fixed) |
| 9 | glmmTMB `dispformula` | weak | log-scale SD (fixed) |
| 4 | metafor `rma.uni` | strong | pooled mean + `tau^2` |
| 5 | metafor `rma.mv` DIAG | strong | per-level `tau` |
| 6, 7 | ordinal `clm`/`clmm` | **unclassified in 242** | `mu` only |
| 8 | lme4 `glmer` | strong | `mu` only |

Every residual-scale agreement in the set is weak-independence. The differentiator
drmTMB is being sold on — "location-scale is drmTMB's stated differentiator"
(`candidate-cells.md:78-80`) — is externally checked here mainly against a package that
shares drmTMB's AD stack and outer optimizer. That is a real result and worth reporting,
but it must be reported with the strength attached, not as "validated against an
independent implementation".

### A4 [NOTE] Cell 2's frontier status is confirmed independently by the ledger

`cells.tsv` carries `mc-0266` (gaussian, `sigma`, `ordinary_re_intercept`, ML,
implemented, `interval_feasible`) with no comparator row in `evidence.tsv`. So Cell 2 is
a real, already-ledgered capability whose claims are governed by *its own* boundary. Any
reader-facing statement about Cell 2 must be sourced to `mc-0266`, never to Cell 1.

---

## (b) One-to-one comparator implication — YES

Issue #60's guardrail, quoted verbatim at `158-plan-of-record.md:119`: "Do not imply
that every `drmTMB` model has a one-to-one comparator."

### B1 [BLOCKING] The sample inverts the package's actual composition

The proposed set is 8 comparator cells and 2 no-comparator cells — 80% with a
comparator. I classified the implemented model surface directly from
`docs/dev-log/dashboard/capability-ledger/cells.tsv` (341 rows with
`axis == "model_surface"` and `capability_status == "implemented"`):

- 222 carry a structured provider (`phylo`, `spatial`, `animal`, `relmat`,
  `phylo_interaction`);
- 146 are on a bivariate/joint family route;
- 36 are scale-side ordinary random effects (`dpar != "mu"` with an RE effect type);
- union: **268 of 341 (79%)** sit in or beside the frontier as 242 defines it;
- remainder: 73 of 341 (21%), and that remainder still includes `zoi`, `coi`, `hu` and
  `nu` cells with no comparator either.

*(This classification is my own reading of three cells.tsv columns, not a repo-blessed
metric — AGENT-INFERRED, reproducible from the file, but treat the exact split as
indicative rather than certified.)*

An 80%-with-comparator sample drawn from a ≤21%-comparator-eligible surface creates the
exact impression #60 forbids, and two labelled exceptions do not correct a 4:1 ratio.
**Fix:** state the proportion in the write-up itself ("these ten cells were chosen
because they *can* be compared; most of drmTMB's implemented surface cannot"), or
rebalance the set.

### B2 [BLOCKING] One coverage-table row states a false non-existence claim

`candidate-cells.md:52` reads: "No comparator can fit the same thing | 2, 10". For Cell
2 this is false, and the document contradicts itself: `candidate-cells.md:101-104`
already says "Writing 'no package can express this' would be false", and
`feasibility-batch-1.md:77-90` proves it — glmmTMB accepts
`dispformula = ~ (1|Subject)`, runs, and returns a non-positive-definite Hessian with
`Variance = 1.521e-12` and `NA` for AIC/BIC/logLik.

Shipping that table row is the mirror-image violation of #60: instead of over-claiming a
comparator, it over-claims a *gap*. The supportable sentence is Gauss's:
`glmmTMB` accepts the syntax but produces an unusable, degenerate fit on this dataset,
while drmTMB's own fit is clean (`pdHess = TRUE`, `convergence = 0`,
`sd:sigma:(1 | Subject) = 0.5057494`, `feasibility-batch-1.md:53-73`). One dataset, one
package, stated as such.

### B3 [NOTE] Cell 6 is the strongest anti-one-to-one signal in the set — keep it

`feasibility-batch-2.md:162-191` confirms drmTMB *rejects* `sigma ~ temp` for
`cumulative_logit()` with a real error message, and confirms
`ordinal::clm(..., scale = ~ temp)` fits (`logLik = -86.439`). A cell where the
comparator can do something drmTMB cannot is the cheapest available defence against the
one-to-one impression. It should be prominent, not buried in a boundary note.

---

## (c) Timing reproducibility — NO

Issue #60 requires: "record package versions, platform, core count, seed, and model
options" (`158-plan-of-record.md:122-124`). Present today: package versions
(`candidate-cells.md:341-345`). Absent everywhere in all five documents: platform, core
count, seed, model options, BLAS, thread pinning, and repetition count. Ada concedes the
gap at `candidate-cells.md:326-329`; that concession is correct and is not yet acted on.

### C1 [BLOCKING] Single-run wall times are noise — measured, not argued

I re-ran Cell 9 five consecutive times in one session
(`R_PROFILE_USER=/dev/null Rscript --no-init-file`, `devtools::load_all(".")`, timer
around the `drmTMB()` call only):

```
cell9 elapsed (5 reps): 0.191, 1.132, 0.031, 0.028, 0.028
min/median/max: 0.028 0.031 1.132
```

A **40× spread** on an identical fit, same session, same data. Every timing number in
all four batches is a single draw from a distribution this wide. No timing comparison —
between cells, or between drmTMB and a comparator — is supportable from single runs.

Environment for that run, i.e. the fields #60 asks for and no batch records:
R 4.6.0, `aarch64-apple-darwin23`, macOS Tahoe 26.6.1, reference
`libRblas.0.dylib` (not Accelerate/OpenBLAS), `parallel::detectCores() = 20`,
drmTMB 0.7.0, n = 333.

### C2 [BLOCKING] The documents already disagree with each other on the same fits

| Cell | Ada (`candidate-cells.md`) | Gauss (batch) | Ratio |
| --- | --- | --- | --- |
| 9 | 0.9 s (`:266`) | 0.049 s (`feasibility-batch-3.md:157`) | 18× |
| 3 | "3 s" (`:122`) | 1.95 s (`feasibility-batch-1.md:123`) | 1.5× |
| 5 | "<1 s" (`:169`) | 1.254 s (`feasibility-batch-2.md:64`) | bound falsified |

C1 explains why: both authors are right about what they observed. That is precisely the
problem. Three of the four documented timings in the set are mutually inconsistent, and
one stated upper bound is already violated by a later measurement.

### C3 [SERIOUS] Timer scope was decided after seeing the numbers

`feasibility-batch-4.md:24-29` reports 1.86 s with `devtools::load_all()` inside the
timer and 0.3126 s without, then instructs: "Report the 0.31 s number." Excluding load
time is the right convention, but it was chosen post hoc from two observed values rather
than fixed in advance. A timing protocol has to be written before the measurements, not
selected from them.

### C4 [SERIOUS] Source-loaded package versus installed comparators is not a fair benchmark

drmTMB is loaded with `devtools::load_all()` from source in this worktree
(`candidate-cells.md:338-341`); every comparator is an installed binary. Compilation
flags for the TMB template are not guaranteed equal between the two paths. I did not
measure the difference, so this is a stated risk rather than a finding — but it means no
"drmTMB is faster/slower than X" sentence can be written from this evidence at all
without first re-measuring against an installed drmTMB build.

### C5 [NOTE] The "seed" field needs an explicit answer, not silence

Cells 1-10 use fixed real datasets with no simulation, so a data seed is close to
vacuous. That is a legitimate answer to #60's seed requirement — but it must be *stated*
("no stochastic component; comparator optimizer control settings recorded instead"),
with the optimizer controls then actually recorded. Leaving the field unaddressed reads
as an omission rather than a reasoned N/A.

---

## (d) Ledger rows — MIXED, with one contradiction

The enforcement path, read directly rather than from doc 242's summary: an
`external_comparator` row must name a package from `COMPARATOR_PACKAGES`
(`tools/capability_ledger.py:3875-3878`) in `run_id`/`result`
(`tools/capability_ledger.py:2329-2333`); must declare STRONG or WEAK INDEPENDENCE in
`claim_boundary` (`tools/capability_ledger.py:2334-2341`); must contain the tokens
"interval", "coverage" and "single-seed" in `claim_boundary`
(`tools/tests/test_capability_ledger.py:3016-3021`); must resolve its `path_or_url`
(`:3022-3025`); and must key to a `cell_id` that exists in `cells.tsv`
(`:3037-3040`).

### D1 [BLOCKING] Cell 5's reader conclusion contradicts a boundary already in the ledger

`evidence.tsv` row `ev-mc-0260m-meta-v` (`evidence_class = external_comparator`,
STRONG INDEPENDENCE, metafor) ends with:

> "At K=12 with true tau = 0.10 the fitted tau pins near 1e-6 and `confint()` returns
> [0, Inf] for heterogeneity, so the heterogeneity interval must not be reported as
> usable at small K."

And `mc-0260m`'s own cell boundary in `cells.tsv` records the Arc 7b interval
withdrawal, ending: "The between-study residual heterogeneity SD remains unpromoted: the
retained K=12, true tau=0.10 [0, Inf] failure is still binding."

Cell 4 is K = 13 trials. Cell 5 splits those 13 into `alternate` n=2, `random` n=7,
`systematic` n=4 (`feasibility-batch-2.md:62-64`), then concludes:
"Alternate-allocation trials are nearly homogeneous (`tau ≈ 0.19`) while randomised and
systematic trials are not (`tau ≈ 0.61`, `0.53`)" (`candidate-cells.md:172-174`). That
is a comparative heterogeneity claim built on `tau` estimated from two studies, one
study-count below the regime the ledger says is unusable. Neither `candidate-cells.md`
nor any feasibility batch cites `mc-0260m` or this boundary at all.

Point agreement with metafor is licensed and is what Gauss demonstrated. The
*interpretive sentence* is not licensed by it, and is contradicted by a recorded
boundary. This is the sharpest claim risk in the whole set and must be resolved before
Cell 5 is written for a reader.

### D2 [BLOCKING] Cells 2 and 10 must carry no row, and must not be framed as "withheld"

The 2026-08-15 amendment (`docs/design/242:78-84`) establishes a specific precedent: the
harness's point-agreement block *could* carry a conforming row today and was withheld as
a scope choice, while the interval row is *blocked* by policy. Three states now exist —
licensable-and-recorded, licensable-but-withheld, and nothing-to-record. Cells 2 and 10
are the third: there is no agreement, so there is nothing withheld. A write-up that says
"no ledger row was added for these" without distinguishing which of the three states
applies invites the reader to infer that evidence exists and was merely not filed.

### D3 [SERIOUS] Cell 5 has no cell to attach to; Cell 4 attaches only on the `mu` side

The only `meta_V` cell in the ledger is `mc-0260m` (gaussian, `dpar = mu`,
`effect_type = fixed`, ML, `point_fit_recovery`) — I checked every row with
`route_modifier == "meta_V"` and there is exactly one. There is **no `meta_V` `sigma`
cell**. Cell 5 is entirely a `sigma`-side contrast model, so no conforming row is
constructible for it without minting a new cell, which is a separate decision and not a
side effect of a write-up. Attaching it to `mc-0262` (plain gaussian `sigma` fixed)
would badge a non-meta cell with a result obtained under a `meta_V` likelihood.

### D4 [SERIOUS] Cells 4 and 5 largely duplicate evidence already banked

`ev-mc-0260m-meta-v` already records five passing metafor comparator tests covering
"the fixed-effect coefficient, the heterogeneity component and log-likelihood" against
`rma.uni(method='ML')` and `rma.mv()` at 1e-4 to 1e-6, with STRONG INDEPENDENCE
declared. Cell 4's genuine increment over that is *real trial data instead of simulated*
— which is a real reader-facing gain but is not an axis the ledger records. Do not open
a new row that restates a banked one; if the real-data provenance matters, extend the
existing row's `result` field.

### D5 [SERIOUS] `ordinal` has no independence classification anywhere

Doc 242:106-111 classifies only `lme4`/`metafor` (strong) and `glmmTMB` (weak).
`ordinal` is in `COMPARATOR_PACKAGES` (`tools/capability_ledger.py:3876`) but has no
declared strength. Rows for Cells 6 and 7 are *required* to declare one. Deciding it
inside a Phase 19 write-up would amend doc 242 by side effect. My own read is that
`ordinal::clm`/`clmm` is a separate estimation engine and would be STRONG — but that is
my inference, and 242 is where it belongs.

### D6 [SERIOUS] Per-cell keying splits a single joint fit across cells

242:93-99 keys the annotation by `cell_id` and forbids aggregation. But Cell 1's *one*
fit spans a `mu` random-slope cell and a `sigma` fixed cell; Cell 3's spans
`nbinom2` `mu` RE-intercept and `sigma` fixed; Cell 9's spans lognormal `mu` fixed and
`sigma` fixed. The agreement is a property of the joint model. Each row must therefore
say the agreement was obtained inside a joint location-scale fit and does not license
the cell in isolation. `ev-mc-0260-external-comparator`'s phrasing ("Does not extend to
REML, to random effects, or to any structured, phylogenetic, spatial or bivariate
Gaussian route") is the right template and does not currently cover this case.

### D7 [NOTE] Which cells *are* cleanly licensable today

Given a conforming boundary (the four required tokens plus a strength declaration), these
have a matching implemented cell and a real agreement:

| Cell | Candidate `cell_id`(s) | Comparator | Strength |
| --- | --- | --- | --- |
| 1 | `mc-0268` (gaussian `mu` RE-slope ML), `mc-0262` (gaussian `sigma` fixed ML) | glmmTMB | weak — but check overlap with the existing `ev-mc-0260-external-comparator` |
| 3 | `mc-0401` (nbinom2 `mu` RE-int ML), `mc-0398` (nbinom2 `sigma` fixed ML) | glmmTMB | weak |
| 6 | `mc-0223` (cumulative_logit `mu` fixed ML) | ordinal | **undeclared — see D5** |
| 7 | `mc-0225` (cumulative_logit `mu` RE-int ML) | ordinal | **undeclared — see D5** |
| 8 | `mc-0059` (binomial `mu` RE-int ML) | lme4 | strong |
| 9 | `mc-0374` (lognormal `mu` fixed ML), `mc-0376` (lognormal `sigma` fixed ML) | glmmTMB | weak |

Cell 8's row must state the tolerance honestly as ~1e-3, not 1e-4
(`feasibility-batch-3.md:107-127`); there is precedent — `ev-mc-0429-external-comparator`
already says "Note the tolerance here is 5e-4, looser than the Gaussian rows".

### D8 [BLOCKING] `metadat` is not a declared dependency

`candidate-cells.md:15-17` claims every dataset is "already reachable from `DESCRIPTION`
`Suggests` ... no new dependency, no vendored data". False for Cells 4 and 5:
`feasibility-batch-2.md:19` calls `data(dat.bcg, package = "metadat")`, and `metadat` is
absent from `DESCRIPTION:44-69`. Mitigating fact I verified: metafor 5.0-1's own
`DESCRIPTION` reads `Depends: R (>= 4.0.0), methods, Matrix, metadat, numDeriv`, so
`metadat` is installed transitively wherever `metafor` is. But an undeclared package used
in a vignette or test is still a declaration defect, and the document's stated claim is
wrong either way. Fix the claim, and add `metadat` to `Suggests` if these cells ship.

### D9 [NOTE] The `nbinom2` masking hazard is a correctness trap specific to this phase

`feasibility-batch-1.md:106-122`: `glmmTMB::nbinom2` masks `drmTMB::nbinom2` after
`library(glmmTMB)`, so a bare `family = nbinom2()` silently hands drmTMB the wrong
family object (here it errored; a future overlap in family names might not). Any
comparator vignette or test that attaches both packages must use
`family = drmTMB::nbinom2()`. This already bit the feasibility run; it will bite a
reader following the write-up verbatim.

---

## What the set gets right

Recorded so the corrections above are not read as a wholesale rejection.

1. **Gauss fitted every cell rather than reasoning about it**, and the fits corrected Ada
   on three substantive points: Cell 2's comparator status
   (`feasibility-batch-1.md:77-90`), Cell 5's conversion path — which Gauss got wrong on
   his own first pass and caught by computing rather than asserting
   (`feasibility-batch-2.md:106-116`) — and Cell 10's `rho12` numbers, which were
   link-scale coefficients mislabelled as response-scale correlations
   (`feasibility-batch-4.md:104-120`).
2. **The `-2 * log(sigma)` NB2 conversion was applied and shown to matter**
   (`feasibility-batch-1.md:130-149`), including what the mismatch would have been if the
   gaussian rule had been transferred naively. That is the #60 scale-conversion guardrail
   met properly.
3. **Batch 3 refused to let Cell 7 license a REML or interval claim**
   (`feasibility-batch-3.md:62-68`), which is exactly the discipline 242 asks for.
4. **The `logLik` Jacobian offset in Cell 9 was explained rather than waved off**
   (`feasibility-batch-3.md:193-200`), as was Cell 8's residual gap, which was tested
   against a tightened optimizer before being attributed
   (`feasibility-batch-3.md:116-127`).

---

## Gate conditions before any write-up

1. Correct `candidate-cells.md:52` (B2) and `candidate-cells.md:15-17` (D8). Both are
   false as written and both are one-line fixes.
2. Restructure so no frontier cell shares a dataset thread with an agreeing overlap cell,
   or attach an explicit non-transfer sentence to each frontier cell (A1).
3. Split the "distributional submodel" coverage row into fixed-effect and random-effect
   halves (A2), and attach independence strength to every agreement claim (A3).
4. Resolve Cell 5's conclusion against `mc-0260m`'s recorded heterogeneity boundary
   before it is written for a reader, or drop the comparative-heterogeneity sentence
   (D1). This one is not a wording fix.
5. Either state the comparator-eligibility proportion explicitly in the write-up, or
   rebalance the sample (B1).
6. Fix a timing protocol *in advance* — repetitions, warm-up discard, timer scope,
   platform/cores/BLAS/optimizer-control recorded, installed-vs-source build settled —
   and re-measure; or drop timing from the phase and say so (C1-C4).
7. Take the `ordinal` independence decision in doc 242, not in the write-up (D5).
8. Confirm with the maintainer whether any Phase 19 ledger row is wanted at all, given
   D2/D3/D4. The live precedent is that the just-landed harness carries none.

## Verification limits of this audit

I re-ran only Cell 9, and only for timing (five reps, script at the session scratchpad
`rose-timing.R`). I did **not** re-fit Cells 1-8 or 10 and did **not** independently
verify any comparator number in the batches — those are Gauss's measurements, cited as
his. The ledger claims (cell existence, tiers, boundary text, enforcement rules) I read
directly from `cells.tsv`, `evidence.tsv`, `tools/capability_ledger.py` and
`tools/tests/test_capability_ledger.py`. The 268/341 frontier proportion in B1 is my own
column-based classification and is marked AGENT-INFERRED. The `ordinal` STRONG suggestion
in D5 is my inference and is not repo-grounded.
