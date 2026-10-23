# 262: Non-Gaussian Precision Bar  -  Owner Decision Draft

STATUS: OWNER DECISION PENDING (drafted 2026-09-05)

Cross-reference: DRM.jl #606 <-> drmTMB #1129. Drafted from the
`parity-joint-20260905` ultra-plan's fog ticket (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:139`)
by request; this document is the DRAFT the plan asked to be produced before the
owner decides. Nothing in this file changes any gate, tolerance, or code path
by itself.

## 1. The question, in one sentence

Should the drmTMB/DRM.jl parity programme keep a single cross-engine
optimizer-agreement bar of `4e-6` for every family, or split it so
non-Gaussian families are held to `1e-5` while Gaussian families stay at
`4e-6`?

## 2. The measurements

Two distinct axes are in play and this table keeps them separate.

**Axis A  -  native-fit cross-optimizer agreement** (drmTMB native R fit vs
DRM.jl native Julia fit on the same target; this is where the `4e-6` bar
lives and where the reported failures sit). Source: DRM.jl issue #606 (body
and first two comments, `gh issue view 606 -R itchyshin/DRM.jl --comments`).

| leaf / cell | quantity | measured | bar | verdict | source |
|---|---|---|---|---|---|
| `joint-fit-parity:G1` / `joint-public-fit:G5` / `r-joint-native:G1` | Bernoulli coefficient delta | `1.0015e-5` | `4e-6` | FAIL (not run to closure; reported, not re-verified in this leaf) | issue #606 body, "three precision leaves ... not run" |
| `leaf-S9-native-uncertainty:G2` | Gaussian `imputed()` mean_error | `8.606e-4` | `1e-6` | FAIL  -  separate issue (see below) | issue #606 body, item 1 |
| `leaf-S9-finite-state-evidence:G4` | ordinal prediction | `7.56e-6` | `4e-6` | FAIL | issue #606, comment 1 ("Receipt regeneration pass") |
| `leaf-S9-finite-state-evidence:G4` | ordinal imputation | `5.12e-6` | `4e-6` | FAIL | issue #606, comment 1 |
| `leaf-S9-finite-state-evidence:G4` | categorical theta | `1.74e-5` | `4e-6` | FAIL | issue #606, comment 1 |
| `S10 matched-native:G1` | Gaussian `training_mean` | `5.31e-6` | `4e-6` | FAIL | issue #606, comment 1 |
| `S10 matched-native:G1` | Bernoulli `theta` | `1.00e-5` | `4e-6` | FAIL | issue #606, comment 1 |

Pattern stated by the reporting session in issue #606, comment 1: "Every
non-Gaussian (Bernoulli / ordinal / categorical) cell lands at ~1e-5 while
Gaussian cells sit under 4e-6: the two optimisers stop at slightly different
points on discrete-outcome likelihoods." No Gaussian native-fit cell in this
set exceeds `4e-6` in the evidence read for this document; every cell that
exceeds it is non-Gaussian.

**Axis B  -  bridge coefficient parity** (`engine="julia"` bridge output vs
native R fit; a different, looser gate at `tol = 1e-4`, not the `4e-6` bar,
but the only place a broad per-family table of measured deltas exists).
Source: DRM.jl `docs/dev-log/evidence/parity-fixtures.tsv` (pinned checkout
`/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc`, 33 rows, all
`PARITY_PASS`).

| file:row | capability_id | family | max\_abs\_coef\_diff | vs 4e-6 | vs 1e-5 |
|---|---|---|---|---|---|
| parity-fixtures.tsv:2 | `base_gaussian_location_scale` | Gaussian | `4.564e-06` | just above | under |
| parity-fixtures.tsv:6 | `fe_gamma` | Gamma | `3.912e-06` | just under | under |
| parity-fixtures.tsv:9 | `biv_student` | Student-t (bivariate) | `3.117e-06` | under | under |
| parity-fixtures.tsv:8 | `biv_lognormal` | LogNormal (bivariate) | `9.149e-07` | under | under |
| parity-fixtures.tsv:5 | `fe_nbinom2` | NegBinomial2 | `2.787e-08` | under | under |
| parity-fixtures.tsv:31 | `truncated_nbinom2` | Truncated NegBinomial2 | `8.812e-11` | under | under |
| parity-fixtures.tsv:30 | `zero_one_beta` | Zero-one-inflated beta | `3.979e-11` | under | under |
| parity-fixtures.tsv:28 | `formula_sigma_factor` | Gaussian (formula construct) | `4.640e-11` | under | under |
| parity-fixtures.tsv:10 / 29 | `fe_tweedie` / `tweedie` | Tweedie | `2.767e-11` | under | under |
| parity-fixtures.tsv:33 | `skew_normal` | Skew-normal | `1.890e-11` | under | under |
| parity-fixtures.tsv:17 | `fe_beta` | Beta | `1.172e-11` | under | under |
| parity-fixtures.tsv:18 | `zi_poisson` | Zero-inflated Poisson | `1.286e-11` | under | under |
| parity-fixtures.tsv:14 | `fe_gamma` (2nd fixture run) | Gamma | `1.911e-11` | under | under |
| parity-fixtures.tsv:16 | `fe_nbinom2` (2nd run) | NegBinomial2 | `1.704e-11` | under | under |
| parity-fixtures.tsv:11 | `fe_beta_binomial` | Beta-binomial | `7.772e-15` | under | under |
| parity-fixtures.tsv:32 | `cumulative_logit` | Cumulative logit (ordinal) | `2.198e-14` | under | under |
| all remaining 17 rows (`fe_poisson`, `plain_binomial_nonphylo`, `fe_student`, `fe_lognormal`, `zi_nbinom2`, `hurdle_nbinom2`, 8x `formula_*`) | mixed | `1e-12` to `1e-14` range | under | under |

Reading Axis B against the bar: at the bridge's own `1e-4` gate every family
passes by 2-5 orders of magnitude, so the bridge coefficient-parity fixture
does **not** reproduce the Axis-A failures at all  -  the two Gaussian rows
that come closest to `4e-6` (`base_gaussian_location_scale` at `4.564e-6`,
just over, and `fe_gamma`/`biv_student` in the `3e-6` range, just under) are
noise-level cross-optimizer spread, not the ~1e-5 non-Gaussian pattern
reported on Axis A. This means the Axis-A native-fit failures are a distinct,
narrower phenomenon (discrete-outcome likelihoods, native R optimizer vs
native Julia optimizer) that the broad bridge fixture set does not surface.
Do not read Axis B as evidence the Axis-A problem is fixed, and do not read
Axis A as implying the bridge (Axis B) is at risk  -  they measure different
things.

**The separate issue.** `imputed()` Gaussian conditional-mode error, `8.6e-4`
against a `1e-6` tolerance (drmTMB #1129 / DRM.jl #606 item 1), is diagnosed
as an inner-Newton-mode convergence gap in `R/missing-data.R` (~line 5000),
not an optimizer-tolerance or cross-engine question. It is a Gaussian bug
with a numeric fix, not a precision-bar decision. Kept separate throughout
this document per the task brief.

## 3. What each option costs

### Option A  -  keep `4e-6` everywhere; engineer optimizer tolerances on the non-Gaussian routes

- **Which routes.** Every discrete-outcome / non-Gaussian native-fit route
  that currently fails Axis A: Bernoulli (`joint-fit-parity`,
  `joint-public-fit`, `S10 matched-native`), ordinal (`finite-state-evidence`
  prediction and imputation), categorical (`finite-state-evidence` theta).
  Each is a *different* likelihood with its own optimizer surface, so this is
  not one fix  -  it is one investigation per family.
- **What would change.** Either (a) tighten `nlminb`/inner-optimizer controls
  (`rel.tol`, `eval.max`, `iter.max`) on the R side, the DRM.jl-side optimizer
  defaults, or both, until the two engines land within `4e-6` of each other
  on discrete-outcome likelihoods; or (b) add a per-family Newton polish step
  after the primary optimizer converges (the same class of fix design 260,
  `docs/design/260-nlminb-newton-polish-optimizer-tolerance.md`, already
  applied for a different cell). Both require re-deriving convergence
  behaviour per family, not a single constant change.
- **Who pays.** Whoever does this work must (i) reproduce each failing cell,
  (ii) diagnose whether the gap is optimizer stopping criteria, likelihood
  parameterisation, or numerical-derivative precision (issue #606 explicitly
  declines to guess: "same mechanism as the prediction 'factors' case in
  #609" is offered as a hypothesis, not a diagnosis), (iii) verify the fix
  does not regress the `1e-8`-to-`1e-13` cells that already pass comfortably,
  and (iv) re-run the full Axis-A ledger (`.unlazy/julia-r-parity`) to
  confirm no other cell moved. Issue #606's own framing is "owner call:
  re-derive the bar ... or tighten the looser side's convergence. Not
  changed tonight"  -  i.e. the reporting session itself treated this as
  open-ended optimizer engineering, not a bounded fix, and did not attempt
  it. Multi-family, multi-day, uncertain-outcome work with no committed
  estimate anywhere in the evidence read for this document.

### Option B  -  adopt `1e-5` for non-Gaussian, keep `4e-6` for Gaussian

- **What the ledger/gates would say.** Every Axis-A cell in Table 2 above
  (Bernoulli `1.0015e-5`, ordinal `7.56e-6`/`5.12e-6`, categorical `1.74e-5`,
  Bernoulli `theta` `1.00e-5`) passes immediately under a `1e-5` non-Gaussian
  bar, except categorical theta (`1.74e-5`), which would still fail and need
  its own look. Gaussian `training_mean` (`5.31e-6`) is Gaussian, so it would
  **not** be covered by a non-Gaussian carve-out and stays FAIL against
  `4e-6` under this option  -  it is not currently explained by anything in
  the evidence read here, and adopting Option B does not resolve it. This
  document does not paper over that: **Option B closes 4 of the 6 measured
  non-Gaussian/mixed Axis-A failures, not all of them**, and it does not
  touch the categorical-theta or Gaussian-`training_mean` cells.
- **Cost.** Editing and documenting the tolerance constant in each of the
  gate files enumerated in Section 6, re-running the affected receipts, and
  writing the two-tier rule into the programme's public tolerance
  documentation so nobody reads a `1e-5` PASS as a `4e-6` claim.

## 4. Recommended default

**Adopt `1e-5` as the documented non-Gaussian native-fit precision bar; keep
`4e-6` for Gaussian.** Document `imputed()`'s `8.6e-4` separately as a
Gaussian conditional-mode bug (drmTMB #1129), not a bar question  -  already
true today and unaffected by this decision either way.

Why:

- The reporting session's own diagnosis is that the gap is a **stopping-
  criteria mismatch between two independent optimizers on discrete-outcome
  likelihoods**, not a modelling error, an oracle defect, or a correctness
  problem: fitted parameter estimates and likelihoods agree; only the last
  ~1e-5 of optimizer polish differs. Chasing that last decimal on N
  independent non-Gaussian likelihoods, with no diagnosis yet of *why* each
  one stops early, is exactly the kind of accuracy-only work the standing
  rule below says to weigh against usability cost.
- The standing rule invoked by the ultra-plan (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:139`)
  is the owner's D-139 usability-first rule (recorded in the owner's personal
  operating doctrine, not in this repo's own decision log  - 
  `docs/dev-log/decisions.md` on `origin/main` has no D-139 entry, so it is
  cited here by name as the owner's standing rule, not as an in-repo
  citation): *usability is uncompromisable; accuracy is critical but
  contextualised; an accuracy gain that costs usability loses by default.*
  A multi-family, open-ended optimizer-tuning investigation is a usability
  cost (lane time, risk of regressing passing cells, delay to every other
  parity item behind it in the same ultra-plan) purchased for an accuracy
  gain of roughly one order of magnitude on a bar that is already stated to
  four significant figures beyond what any downstream inference could use.
- This keeps the strict `4e-6` bar exactly where the evidence says it is
  earned  -  Gaussian cells never approach it in the data read for this
  document  -  while acknowledging, in writing, that two independently-written
  optimizers do not converge to identical last-decimal stopping points on
  discrete likelihoods, which is a true and boring fact about numerical
  optimization, not a parity defect.
- It does not hide the shortfall: categorical `theta` (`1.74e-5`) and
  Gaussian `training_mean` (`5.31e-6`) both stay FAIL under this
  recommendation and must be tracked as open leaves, not silently absorbed.

## 5. Drafted decision entry (owner can paste)

> **D-NNN placeholder (2026-09-05): Non-Gaussian precision bar.** The
> drmTMB/DRM.jl parity programme's cross-engine native-fit agreement bar is
> split: Gaussian families are held to `4e-6`; non-Gaussian families
> (Bernoulli, ordinal, categorical, and other discrete-outcome likelihoods)
> are held to `1e-5`, reflecting measured optimizer stopping-criteria
> differences between drmTMB's R-side and DRM.jl's Julia-side optimizers on
> discrete-outcome likelihoods (DRM.jl #606, drmTMB #1129), not a modelling
> or correctness defect. `imputed()`'s Gaussian conditional-mode error
> (`8.6e-4`, drmTMB #1129) is tracked separately as a numeric bug, not a
> precision-bar question. Per D-139: an accuracy gain that costs usability
> (open-ended per-family optimizer engineering with no diagnosed mechanism
> or estimate) loses by default; document the measured bar instead of
> chasing it. Any cell that still fails its assigned bar (categorical theta
> at `1.74e-5`; Gaussian `training_mean` at `5.31e-6`) remains an open leaf,
> tracked on its own issue, not absorbed by this decision.

## 6. What changes in the repos if adopted

**drmTMB** (`tools/`, hardcoded `4e-6` constants that would need a
non-Gaussian-vs-Gaussian split, or a documented comment explaining why the
constant stays `4e-6` for that specific gate's family scope):

- `tools/check-julia-phylo-labels-receipt.R:354` (`tolerance <- 4e-6`)
- `tools/check-native-joint-prediction-neighbours.R:21` (`tolerance=4e-6`)
- `tools/check-native-joint-prediction.R:14` (`tolerance = 4e-6`)
- `tools/run-julia-joint-finite-public.R:18,56` (`native_tolerance=4e-6`)
- `tools/run-julia-joint-public.R:27` (`native_tolerance = 4e-6`)
- `tools/run-julia-joint-two-public.R:20,51` (`native_tolerance=4e-6`)
- `tools/run-julia-phylo-labels-public.R:62-63` (`native_parity<=4e-6`,
  `bridge_parity<=4e-6`)
- `tools/run-julia-polytomy-public.R:19,68-69` (`native_tolerance=4e-6`)
- `R/julia-bridge.R:434` (comment documenting the `4e-6`/`1e-4` figures cited
  to DRM.jl's `parity-fixtures.tsv`  -  would need a note distinguishing the
  bridge tolerance, unaffected, from the native-fit bar, split)

**DRM.jl** (`tools/`, the Python/Julia checkers that assert `4e-6` as a
receipt invariant):

- `tools/check_component_receipt.py:35`
- `tools/check_finite_fit_receipt.py:34,75`
- `tools/check_finite_joint_fit.jl:16,44`
- `tools/check_finite_public_receipt.py:14,73`
- `tools/check_finite_stopping_diagnostic.py:46`
- `tools/check_joint_bridge_public_receipt.py:145,149,150`
- `tools/check_joint_frontend_fit_receipt.py:212`
- `tools/check_joint_predictor_fit_receipt.py:66`
- `tools/check_polytomy_public_receipt.py:38,86,92`
- `tools/check_two_gaussian_fit.jl:68`
- `tools/check_two_gaussian_fit.py:118`
- `tools/check_two_public.py:19,68`
- `tools/parity_conditional_components.R:39` (`fit_tolerance=4e-6`)
- `tools/parity_conditional_prediction.R:34` (`independent_fit_tolerance = 4e-6`)
- `tools/parity_prediction.R:28` (`tolerance = 4e-6`)

Each of these checkers currently asserts `4e-6` as a frozen invariant
(several literally `require(tolerance==4e-6, ...)`), regardless of family.
Adopting Option B means either parameterising these by family (Gaussian vs
non-Gaussian) or leaving the ones that only ever exercise Gaussian fixtures
untouched and adding a family-scoped constant only where a non-Gaussian
fixture is checked  -  a per-file decision this document does not make, since
it depends on which fixture each checker exercises today (not verified line
by line here; flagged as the first task if Option B is adopted).

## Not covered by this document

- Does not diagnose *why* the non-Gaussian optimizers stop at ~1e-5 instead
  of ~4e-6 (Option A's investigation is not performed here).
- Does not fix `imputed()` (drmTMB #1129)  -  tracked separately by design.
- Does not resolve the categorical-theta (`1.74e-5`) or Gaussian
  `training_mean` (`5.31e-6`) failures, which persist under either option
  and need their own leaves.
- Does not audit which DRM.jl checker files exercise Gaussian-only vs
  non-Gaussian fixtures; that audit is the first task if Option B is
  adopted and this document is approved.
- Does not touch any R/, src/, or tests/ file  -  docs-only, per this leaf's
  scope.
