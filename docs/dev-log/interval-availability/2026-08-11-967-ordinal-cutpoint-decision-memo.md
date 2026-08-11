# Decision memo: ordinal cutpoint intervals (issue #967)

Author: Boole (formula/grammar review), 2026-08-11.
Worktree: `wt-interval`, branch `claude/interval-availability`, base `256e586e5`.

## The question

Six of `cumulative_logit`'s nine G4 cells are the two ordinal cutpoints
(`ordinal:theta_ord:low|medium`, `ordinal:theta_ord:medium|high`) at three
information rungs. All six fail deterministically with a capability message.
Issue #967 asks: implement profile intervals for ordinal cutpoints, or
formally scope them out of G4/G5. This gates a route-level G5 exclusion for
`cumulative_logit` that is otherwise earned
(`docs/dev-log/after-task/2026-08-09-missing-data-capability-drmsem-part-b.md:99-126`).

## Why cutpoints are currently unreachable

This is **"not implemented," and for the second cutpoint onward it is
currently "not well posed under the existing profiling machinery"** — two
different findings that the issue conflates into one label. Details below.

**The rejection itself** is a blanket class gate, not a per-target
statistical judgement. `drm_profile_curve()` and the confint dispatcher both
maintain an `implemented_classes` allowlist that omits
`"ordinal-cutpoint-internal"`:

- `R/profile.R:973-991` (profile curves) and `R/profile.R:2912-2917`
  (`confint(method = "profile")`) both raise `cli::cli_abort()` with "Profile
  intervals are implemented for direct fixed-effect, constant
  distributional-scale, random-effect SD, random-effect correlation, and
  constant residual-correlation targets" whenever
  `target$target_class == "ordinal-cutpoint-internal"`.
- The cutpoint targets themselves are constructed at `R/profile.R:1628-1654`,
  tagged `target_class = "ordinal-cutpoint-internal"`, `scale = "internal"`,
  `transformation = "ordered_cutpoint"`. `profile_ready` for these rows comes
  from the generic `profile_direct_target_status()` (active/mapped-out
  check), **not** from any cutpoint-specific "not well posed" note — the
  code never gets far enough to ask that question.
- Wald and bootstrap intervals hit the identical exclusion independently:
  `wald_supported_targets()` (`R/profile.R:2720-2732`) lists the same five
  classes and the same transformation whitelist
  (`linear_predictor`/`exp`/`tanh`/`rho12_tanh`), omitting
  `ordinal-cutpoint-internal`/`ordered_cutpoint`. `bootstrap_supported_targets()`
  (`R/profile.R:2734-2736`) is a direct alias of the Wald gate. **No interval
  method of any kind currently reaches ordinal cutpoints** — this is not
  "profile is missing but Wald exists."

## Is there a real statistical obstacle

Yes, for one of the two cutpoints, and it is not merely a labeling issue.

**Parameterisation.** `theta_ord` is the unconstrained free vector TMB
actually optimizes: `c_1 = theta_ord[1]` directly, and
`c_j = c_{j-1} + exp(theta_ord[j])` for `j > 1`
(`R/drmTMB.R:18188-18196`, `ordinal_cutpoints_from_raw()`; construction
confirmed at `R/drmTMB.R:20792-20799`). This is exactly the increment
reparameterisation the class name `ordinal-cutpoint-internal` and
`scale = "internal"` are already flagging.

- **First cutpoint (`theta_ord[1]`, e.g. `low|medium`): well posed, already
  correctly scaled.** `theta_ord[1]` *is* `c_1` — an ordinary direct
  parameter, no different in kind from a `fixed-effect` or
  `distributional-scale` target. `profile_lincomb()`
  (`R/profile.R:4383-4395`) already builds the correct one-hot selection
  vector for it. `profile_transform_values()`'s `ordered_cutpoint = values`
  branch (`R/profile.R:1116-1126`, identity pass-through) is *correct* for
  this one component. Nothing here is unsound; it is purely gated by class
  membership.
- **Second and later cutpoints (`theta_ord[j]`, `j > 1`, e.g.
  `medium|high`): not well posed under the current profiling machinery.**
  `theta_ord[j]` is `log(c_j - c_{j-1})`, the log-gap between adjacent
  cutpoints — not `c_j` itself. `TMB::tmbprofile(..., lincomb = e_j)` fixes
  the *linear* combination `theta_ord[j] = τ` and re-optimizes every other
  free parameter, including `theta_ord[1..j-1]`, i.e. it lets `c_{j-1}` float.
  The set `{par : theta_ord[j] = τ}` is a flat hyperplane in parameter space;
  the set a genuine profile of `c_j` needs, `{par : c_j(par) = c*}`, is a
  curved manifold (any `c_{j-1}` paired with the compatible
  `theta_ord[j] = log(c* - c_{j-1})` satisfies it). The flat-hyperplane
  optimum is one point on that curved manifold, not generally its maximum —
  so profiling `theta_ord[j]` and profiling `c_j` are different constrained
  optimization problems, and the existing `lincomb` machinery (linear
  combinations only) cannot express the second one. Reconstructing `c_j`
  post hoc from the `theta_ord[j]`-profile trace (which *is* captured;
  see `drm_profile_trace_object()`, `R/profile.R:3588-3633`, used today only
  for the direct-SD clamp diagnostic) would relabel the x-axis but would not
  fix this: the curve being cut by the likelihood-ratio threshold is still
  the wrong curve.

  This is not a novel judgement call for this codebase — it is the same
  problem the package already declined to solve elsewhere.
  `R/profile.R:1587-1591` marks the analogous nonlinear derived correlation
  case (`is_structured_qgt2`, structured `q > 2` correlations) as
  `profile_ready = FALSE, profile_note = "derived_unstructured_correlation"`
  **even though its `target_class` ("random-effect-correlation") already sits
  in `implemented_classes`.** In other words: nonlinear-derived-quantity
  profiling is a capability gap in `R/profile.R` generally, not something
  specific to ordinal cutpoints, and the package's one prior encounter with
  it was to punt, not to solve it.

## Which scale a cutpoint interval would be on

- First cutpoint: **response/cutpoint scale**, correctly, with zero new
  transform work — `theta_ord[1] = c_1` exactly.
- Second-and-later cutpoints: any interval produced by directly profiling
  `theta_ord[j]` (`j > 1`) would be on the **log-increment scale**
  (`log(c_j - c_{j-1})`), not the cumulative cutpoint scale a user asking
  "where is the medium|high boundary" wants. Reporting it under the existing
  `ordered_cutpoint = values` identity transform (`R/profile.R:1120`) would
  silently mislabel a log-gap CI as a cutpoint-location CI.

  This is precisely the failure mode issue #981 already documented for the
  *point estimate* on this same target
  (`ordinal:theta_ord:medium|high` truth constant recorded as the cumulative
  value `0.75` instead of the log-increment `log(0.75-(-0.90)) = 0.5008`,
  `R/profile.R:1628-1654` cross-referenced in #981). #981 is closed as a
  truth-table fix, but its warning stands: "if #967 is fixed, they will read
  as an engine bug when they are a truth-table bug." Any implementation of
  #967 must not repeat that ambiguity — a genuine `c_j` interval and a raw
  `theta_ord[j]` interval are different quantities and must be labeled as
  such (`scale` and `transformation` already have the vocabulary for this;
  they just need to be applied correctly per cutpoint index, not uniformly).

## Cost to implement

**First cutpoint only** — low. Add an index-aware carve-out (e.g. `j == 1`
within `target_class == "ordinal-cutpoint-internal"`) to the two
`implemented_classes` gates (`R/profile.R:973-991`, `2912-2917`) and to
`wald_supported_targets()` (`R/profile.R:2720-2732`, plus its transformation
whitelist). No new transform, no C++ change, no new profiling machinery —
this path already round-trips correctly today; it is purely excluded by
class label. Tests: recovery-style tests confirming the reported interval
matches an independent brute-force profile of `theta_ord[1]`, plus the
existing G4 harness. Order of magnitude: a small, single-PR change.

**Second-and-later cutpoints** — substantial, and would be new machinery for
the package, not a copy of an existing pattern (the one existing nonlinear
derived-quantity case, `is_structured_qgt2`, was declined rather than
solved). A correct implementation needs a genuine constrained profile of
`c_j(par) = c*`, which the current `lincomb`-based `TMB::tmbprofile` call
cannot express. Realistic routes:
1. A bespoke in-R profiling loop that substitutes
   `theta_ord[j] = log(c* - c_{j-1})` into the objective and re-optimizes the
   remaining free parameters (including `c_{j-1}`) at each grid point of
   `c*`, handling the `c_{j-1} < c*` domain restriction and the two-sided
   likelihood-ratio crossing search that `TMB::tmbprofile`/`stats::confint`
   currently provide for free. This duplicates profile-search logic
   (`drm_tmbprofile_confint()`, `R/profile.R:3700-3716`) for a constraint
   type the package has never implemented.
2. Reparameterise the C++ ordinal likelihood at profile time so `c_j` can be
   held fixed directly and the increments recomputed around it — a template
   change, compiled, needing its own tests, for a profile-only code path.

Either route is a multi-function, new-capability piece of work (new profiling
driver or new C++ path, new tests for the constrained optimization, new
recovery evidence), not a small carve-out. I would not commit to a size
estimate without a design doc first (this is exactly the kind of
likelihood-affecting change AGENTS.md design rule 4 gates on).

## Cost to scope out, per-target vs per-route

**Per-target is the right grain, and it is nearly free** — the ledger and
the code both already operate at the individual-target level; nothing forces
a route-level exclusion.

- The evidence base already treats this per-target: the companion doc says
  "cumulative_logit cutpoint targets cannot reach G4 at all... no route-level
  G4/G5 promotion" (`docs/dev-log/after-task/2026-08-09-missing-data-capability-drmsem-part-b.md:99-126`)
  — i.e. the *cause* is already understood as target-scoped even though the
  *consequence* being applied is route-scoped.
  `cumulative_logit`'s "one non-cutpoint target" (its `mu` fixed effect, most
  likely) is unaffected by anything identified above: the obstacle is
  specific to the `theta_ord` increment reparameterisation and touches
  nothing about how `mu`/`sigma`/RE-SD targets are profiled for this family.
  There is no statistical or code reason those targets must wait for a
  cutpoint fix.
- The capability ledger's `target_class` field is already the natural
  join key for this exclusion (`"ordinal-cutpoint-internal"`, further
  split by index if the first-cutpoint carve-out above is taken). Scoping
  out at that grain requires no new ledger machinery — it requires writing
  down, for `cumulative_logit`, "G4/G5 promotion applies per target;
  `ordinal-cutpoint-internal` targets beyond the first are excluded pending
  a nonlinear-derived-quantity profiling capability; all other targets are
  eligible on their own evidence."
- A **per-route** exclusion (the current de facto framing) forfeits G4/G5 for
  `cumulative_logit`'s `mu`, `sigma`, and RE-SD targets too, with no
  technical justification — those targets were never shown to share the
  obstacle. That is the more costly documentation debt: it reads as "ordinal
  models can't have intervals" when the true boundary is "ordinal
  *cutpoints beyond the first* can't yet have intervals."

## RECOMMENDATION

**Scope out now, per-target, and split the cutpoint exclusion into two
tiers rather than treating "cutpoints" as one bloc:**

1. Change the G4/G5 ledger/doc framing from route-level to target-level for
   `cumulative_logit` immediately — this costs nothing beyond writing the
   correct sentence and lets the route's non-cutpoint target(s) be evaluated
   for G4/G5 on their own evidence, unblocking part of the value #967's
   author flagged as most wanted (drmSEM's downstream need).
2. Implement the **first-cutpoint** carve-out as a small, low-risk follow-up
   PR: it is already statistically correct today, gated only by a class
   label, needs no new machinery, and recovers half of the six blocked
   cells (the three `low|medium` rungs).
3. Formally close out the **second-and-later cutpoint** case as "not yet
   well posed under the current profiling machinery" rather than "not
   implemented." Do not attempt it inside this issue: it requires new
   constrained-profiling machinery (or a C++ reparameterisation) that the
   package has never built, and the one prior encounter with the same
   general problem (`is_structured_qgt2`) was itself deferred. Treat it as
   its own design-doc-gated arc if drmSEM's need is specifically for
   `medium|high`-style non-anchor cutpoints (worth confirming before
   investing).

**Reasoning.** The two cutpoints are not one problem wearing one label. One
is a documentation/class-gate bug with a free, correct fix; the other is a
genuine open capability gap that would require inventing new profiling
machinery this codebase has so far chosen not to build, on a change class
(likelihood/profiling correctness) that AGENTS.md already asks to be
design-doc-gated. Bundling them under "implement #967" either stalls the
easy 50% behind the hard 50%, or risks a rushed nonlinear-profile
implementation without the scrutiny #981 already showed this exact target
needs. Splitting them lets the ledger tell the truth at the grain it
actually has evidence for.

**What could go wrong if the second-cutpoint case is implemented anyway:**
a rushed substitution-based profiler could silently produce a profile curve
that is not actually the LR profile of `c_j` (e.g. if the domain restriction
`c_{j-1} < c*` is not enforced correctly, or if the two-sided root search
inherited from `stats::confint.profile.glm`-style code assumes a
monotone/well-behaved curve that a substituted, re-optimized-at-every-grid-point
objective may not guarantee) — precisely the "reads as an engine bug when
it's a scale bug" risk #981 already flagged, now compounded by a genuinely
new numerical procedure.

## What would change my mind

- If `drmSEM`'s actual need is only the first (anchor) cutpoint per ordinal
  response, tier 2 alone may already be sufficient and tier 3 can stay
  deferred indefinitely without cost.
- If a design doc shows the substitution-based constrained profiler (tier 3,
  route 1) can reuse `drm_tmbprofile_confint()`'s existing root-finding
  against a *validated* re-optimized objective (with an independent
  brute-force oracle proving the curve is the correct LR profile of `c_j`,
  not just a relabeled `theta_ord[j]` curve), the cost estimate for
  second-cutpoint support should come down from "new capability" to
  "moderate, well-scoped feature," and implementing rather than permanently
  scoping out would become reasonable.
- If it turns out `cumulative_logit` models in practice are always
  restricted to two categories (one cutpoint), the second-cutpoint case is
  moot and the whole issue reduces to tier 1 + tier 2 above.
