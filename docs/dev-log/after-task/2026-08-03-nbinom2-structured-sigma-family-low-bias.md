# After Task: nbinom2 structured-sigma random-intercept SD skews low across all four provider cells (mc-0421-mc-0424)

## Goal

Not a new feature, and not a resolution. This is a finding, surfaced while working the Arc 7b
truth gate -- the same pass that demoted `mc-0424` from `interval_feasible` to
`point_fit_recovery` because one of its retained profile intervals excludes the data-generating
process (DGP) truth (`docs/dev-log/dashboard/capability-ledger/cells.tsv:428`). Reading the
twelve retained profile receipts across all four nbinom2 structured-sigma provider cells --
`mc-0421` (phylo), `mc-0422` (spatial), `mc-0423` (animal), `mc-0424` (relmat) -- together,
rather than one cell at a time, surfaces a pattern a per-cell gate cannot see: eleven of the
twelve retained point estimates fall on the same side of the true value.

The reader is whoever adjudicates this next -- most immediately the drmTMB owner, since
`cells.tsv:428`'s own `next_gate` field for `mc-0424` already points here ("Settle the
family-level low-bias question first"), and any future Claude or Codex session that picks up
that pointer. The purpose of this note is to state the finding precisely, show what does and
does not follow from it, and hand off a short list of cheap, concrete experiments that would
discriminate between candidate explanations. It does not settle the question and it does not
move any cell's `evidence_tier`. Files touched by this note: this document only.

## What Was Found

All four cells share one DGP template, built by four sibling functions in
`tools/arc3-nbinom2-sigma-provider-fixtures.R` that differ only in which covariance provider
generates the correlation matrix: NB2 family, log/log link, a true structured random-intercept
SD of 0.55 on `log(sigma)` (lines 271, 316, 377, 481), and an intercept-plus-one-slope
structured-sigma grammar required by `validate_*_sigma_random_terms()` for count families (so
each DGP also draws an independent nuisance slope SD -- 0.20 for phylo/spatial, 0.25 for
animal/relmat -- that is not itself part of any of the twelve targets below). All twelve fits
use `estimator = ML` and `profile_engine = tmbprofile` (verified in every receipt's own
columns), the same runner (`tools/run-arc2-profile-feasibility.R`), and the same
`drm_control(optimizer_preset = "robust")`.

The twelve retained receipts, re-verified digit-for-digit against the raw TSVs under
`docs/dev-log/interval-feasibility/results/a34bb75092c7733e5d65e4bf427895b4318ced7c/arc3-profile-feasibility/totoro/mc-042{1,2,3,4}/`:

| Cell | Provider | Seed | Estimate | 95% profile CI | Below 0.55? | CI brackets 0.55? |
|---|---|---|---|---|---|---|
| mc-0421 | phylo   | 2026080301 | 0.5602 | [0.4010, 0.7726] | No  | Yes |
| mc-0421 | phylo   | 2026080302 | 0.4887 | [0.3311, 0.6968] | Yes | Yes |
| mc-0421 | phylo   | 2026080303 | 0.3773 | [0.2282, 0.5845] | Yes | Yes |
| mc-0422 | spatial | 2026080301 | 0.4828 | [0.3215, 0.7046] | Yes | Yes |
| mc-0422 | spatial | 2026080302 | 0.4157 | [0.2457, 0.6488] | Yes | Yes |
| mc-0422 | spatial | 2026080303 | 0.4372 | [0.2405, 0.6888] | Yes | Yes |
| mc-0423 | animal  | 2026080301 | 0.5225 | [0.3347, 0.7917] | Yes | Yes |
| mc-0423 | animal  | 2026080302 | 0.2828 | [0.1371, 0.4794] | Yes | **No** |
| mc-0423 | animal  | 2026080303 | 0.3978 | [0.1738, 0.6642] | Yes | Yes |
| mc-0424 | relmat  | 2026080301 | 0.3710 | [0.2567, 0.5156] | Yes | **No** |
| mc-0424 | relmat  | 2026080302 | 0.4899 | [0.3737, 0.6433] | Yes | Yes |
| mc-0424 | relmat  | 2026080303 | 0.3962 | [0.2706, 0.5530] | Yes | Yes |

Per cell: mc-0421 2/3 below, mc-0422 3/3, mc-0423 3/3, mc-0424 3/3 -- 11/12 overall. Treating
the twelve as independent Bernoulli(0.5) draws (recomputed in R, not by hand), the one-sided
sign-test p-value is P(X >= 11 | n=12, p=0.5) = 13/4096 = **0.0032**; two-sided, 26/4096 =
**0.0063**.

The two retained intervals that already exclude 0.55 (`mc-0423` seed 2026080302, `mc-0424` seed
2026080301) are not new: they are the documented basis of `mc-0423`'s standing withhold
(`cells.tsv:427`) and `mc-0424`'s Arc 7b demotion (`cells.tsv:428`). Those are checks on the
interval's *location*. The eleven-of-twelve pattern is a check on the point *estimate*, and it
is a different, more sensitive diagnostic: `tools/profile_truth_gate.py`, the script this same
arc built to check interval location mechanically, never reads the `estimate` column at all (zero
matches for the string `estimate` in that file). It is blind to a point-estimate sign pattern by
construction -- which is exactly why a per-cell interval gate could not have caught this, and
why none of the four cells' separate reviews (three promotions and one withhold) caught it.

### Is one-sided the right test here?

A sign test's direction should be fixed by a mechanism specified independently of the twelve
numbers, not read off their shape. Two things point toward "downward" as a legitimate
pre-existing direction, and one complicates it:

- **For.** ML estimation of random-effect (co)variance components is well known, in the general
  mixed-model literature, to be downward-biased relative to REML, because ML does not discount
  the degrees of freedom spent estimating the other parameters that share information with the
  variance component -- the textbook justification for REML itself (standard mixed-model theory;
  not re-verified against Patterson & Thompson 1971 or a similar primary source in this session,
  flagged so the provenance of this claim is clear). This is not folklore imported for this note:
  drmTMB's own design record already quantifies and partially corrects exactly this mechanism for
  a different family. `docs/design/224-aghq-coxreid-nongaussian-reml-alignment.md:40` states that
  its REML-style fold (object O2) "removes ~42% of the ML variance bias" for a binomial
  mean-side random-intercept SD. All twelve receipts analyzed here record `estimator = ML`. A
  downward-specific hypothesis therefore rests on a real, independently documented mechanism, not
  only on the shape of this one result.
- **Against.** That mechanism was never pre-registered for these four cells before the twelve
  numbers existed. `tools/arc3-nbinom2-sigma-provider-fixtures.R`'s header is a same-day chronicle
  of look-then-adjust redesign -- `mc-0421`'s tree, `mc-0423`'s pedigree size, and `mc-0424`'s
  cohort size were each changed after specific seeds "looked wrong" under an earlier fixture
  version (lines 71-213) -- and nothing in that record frames ML/REML bias as a predicted,
  pre-committed direction for these specific cells ahead of reading the Totoro receipts.

My call: report the one-sided figure as the headline, because the mechanism is real, independent
of this sample, and already load-bearing elsewhere in this repository's own documentation for an
analogous case -- but report the two-sided figure alongside it every time, and do not lean on the
one-/two-sided choice as the interesting adjustment. p = 0.0032 vs p = 0.0063 is a small,
second-order difference. The clustering correction below is the large, first-order one, and it is
what the sign test is actually most exposed to.

## What This Evidence Does and Does Not Support

**FACT.** The twelve-estimate table above, re-verified against the raw receipt TSVs.

**FACT.** 11/12 estimates fall below 0.55; one-sided p = 0.0032, two-sided p = 0.0063, under the
naive assumption that the twelve fits are independent draws.

**INFERENCE, and the single most attackable part of this claim.** That independence assumption
is optimistic on at least four counts, so "n = 12" overstates the evidence:

1. *Shared design template.* All four cells share the true intercept SD, family, link, grammar
   constraint, profile engine, runner, optimizer preset, and estimator (see "What Was Found"). If
   any part of that shared machinery carries a directional tendency, it would appear in all four
   cells at once, by construction -- which is exactly the observed shape (majority-below in all
   four cells, not scattered across two-and-two).
2. *Shared seeds.* All four cells reuse the identical three seed labels, 2026080301/02/03 (every
   receipt filename and `seed` column). This was one coordinated three-seed campaign across the
   family, not four cells drawing independent seed sets.
3. *Shared random-number entry point (verified, not assumed).* Each fixture's first random draw
   after `set.seed(seed)` is the raw, pre-correlation-transform structured-intercept vector
   (`stats::rnorm(<n>, sd = true_sd_intercept)`; phylo `:283`, spatial `:335`, animal `:443`,
   relmat `:497`), and nothing between `set.seed(seed)` and that call consumes random state: the
   two provider-specific matrix builders each fixture depends on, `drm_spatial_coords_precision()`
   (`R/drmTMB.R:13125`) and `drm_pedigree_additive_relationship()` (`R/phylo-utils.R:432`), are
   both fully deterministic linear algebra (checked by reading both bodies -- no `rnorm`/`runif`/
   `sample` call in either). A standalone base-R check (`set.seed()` + `rnorm()`, no drmTMB code)
   confirms that for each of the three shared seeds, the raw N(0, 0.55^2) draw feeding phylo's and
   relmat's intercept effect (both n = 80) is numerically identical, and animal's draw (n = 40)
   matches the first 40 elements of that same stream. This does not make the four cells' fitted
   results identical -- each provider's distinct correlation transform and the downstream NB2
   sampling clearly send the four cells to different final numbers (see the table) -- but it is a
   genuine extra layer of shared randomness at the input stage, beyond the shared design template.
4. *At least one cell's seeds were not held out from fixture design.*
   `tools/arc3-nbinom2-sigma-provider-fixtures.R:71-131` records that `mc-0421`'s tree (coalescent
   to Grafen) and `mc-0424`'s cohort size (`n_id` 40 to 80) were redesigned specifically because
   seed 2026080303 -- one of the twelve seeds analyzed here -- produced a profile-shape failure
   under the earlier fixture, and the same seed was then re-examined to confirm each redesign
   fixed that failure (lines 99-101, 121-124). That exposure targeted profile *shape*
   (`conf.status`, `profile.boundary`), not point-estimate sign or magnitude, so it does not
   obviously explain the *direction* reported here -- but it means this seed is not a clean,
   held-out draw for those two cells.

**FACT, with a provenance correction.** The `mc-0423` (animal) receipts analyzed here were
generated under the fixture's original `n_founders = 4` (40-individual pedigree) configuration,
not the `n_founders = 8` (80-individual) configuration the runner now uses by default for this
cell (`tools/run-arc2-profile-feasibility.R:442`, added in commit `438f873c20`, 2026-08-02
19:37:36 -0600 -- several hours after the receipts under review were produced). Three checks
confirm this: the receipts' own `information_rung` field and filenames read `id40_each25`; their
`true_parameter_scale` prose says "40-individual (3-generation) pedigree"; and receipt seed
2026080302's numbers (estimate 0.283, interval [0.137, 0.479]) exactly match the fixtures file's
own documented diagnosis of the `n_founders = 4` failure (`:186-189`). The receipts' `source_sha`
field (`a34bb75092c7733e5d65e4bf427895b4318ced7c`) cannot be used to tell the two configurations
apart on its own: that commit predates even the commit that first added the `mc-0421`-`mc-0424`
cells to the runner (`393216d2d`), confirming `source_sha` records `git rev-parse HEAD` at run
time (`tools/run-arc2-profile-feasibility.R:1134`) on a working tree that had local, uncommitted
edits, not a guarantee that the checked-out commit's code produced the receipt. This matters for
how much weight `mc-0423`'s leg of the pattern should carry, but it does not obviously explain the
direction away: `tools/arc3-nbinom2-sigma-provider-fixtures.R:199-207` reports that the same
five-seed family, re-run under the corrected `n_founders = 8` configuration, still gives four of
five estimates below 0.55 (0.434, 0.420, 0.419, 0.329; one above, 0.584) -- smaller errors, but
still a below-truth majority. Those five numbers are reported here as documented in the file's own
header; unlike the twelve in the main table, I have not independently re-verified them against a
raw receipt file. (`tools/run-arc2-profile-feasibility.R` was itself under active,
unrelated concurrent revision in this shared worktree while this note was being
written -- `git status`/`git diff --stat` showed insertions elsewhere in the file
partway through this review. The line numbers cited above were re-checked against
its content at the time this note was finished, but could drift further; the quoted
text they point to is the load-bearing part of each citation, not the line number
alone.)

**Quantifying the clustering concern.** Given points 1-4, the defensible unit of replication is
closer to the *cell* (four provider designs) than the *fit* (twelve seeds). Collapsing each cell
to its majority direction gives 4 of 4 cells majority-below (mc-0421 2/3, mc-0422 3/3, mc-0423
3/3, mc-0424 3/3); the one-sided sign-test p-value at this level is 1/16 = **0.0625** -- not
significant at the conventional 0.05 threshold. The four cells' mean signed relative deviations
are all negative too (mc-0421 -13.6%, mc-0422 -19.1%, mc-0423 -27.1%, mc-0424 -23.8%; overall mean
-20.9%), and a one-sample t-test on those four cell means gives t = -7.09, p = 0.0058, 95% CI
[-30.2%, -11.5%] -- offered as illustration only, since three degrees of freedom is too few to
trust the normal-theory assumptions behind a t-test. All three views point the same direction, but
the strength of the *statistical* evidence is far more sensitive to this clustering correction (p
moves from about 0.003 to about 0.06) than to the one-/two-sided choice (0.0032 to 0.0063). With
only four independent DGP designs, no method -- sign test, t-test, or anything else -- can deliver
a well-calibrated p-value for a claim about NB2 structured-sigma providers generally; four is too
few clusters for asymptotic cluster-robust methods to behave well either. That is the honest state
of the evidence: a consistent, unusual-looking directional pattern that is not yet statistically
established at the level the twelve raw numbers alone make it look like it is.

**SPECULATION, labeled as such.** It is tempting to read this as "NB2 structured-sigma
random-intercept SDs on a log link are downward-biased under ML," full stop. That is one candidate
explanation among several below, and this note does not have the evidence to select it over the
others.

One more descriptive (not statistically tested) observation: among the ten intervals that do
bracket 0.55, the two closest calls both sit near the *upper* endpoint rather than centered --
`mc-0421` seed 2026080303 clears 0.55 by 0.035 (6.3% of truth), and `mc-0424` seed 2026080303
clears it by only 0.003 (0.5% of truth). That is consistent with the same downward pull, but it is
not a new test and should not be read as one.

## Candidate Explanations

For each candidate, what already-available evidence bears on it, and the cheapest experiment that
would help discriminate it from the others.

1. **ML variance-component downward bias (vs REML).** Independently documented in this repo for a
   different family (`docs/design/224...md:40`, "~42% of the ML variance bias" removed by REML-style
   folding for a binomial mean-side random intercept). Checked, and not cheap to test directly here:
   that same design record scopes its REML-style objects (O2, O3) to a *mean*-side random-intercept
   SD for binomial (model_type 18) and cumulative_logit (model_type 13) only; for binomial's O2,
   `scale_fixed` is explicitly "empty (no dispersion)" (`:182`). No dispersion-side (`sigma`)
   random-effect REML-style fold exists yet for any family, let alone nbinom2 (model_type 7).
   Cheapest available experiment: strip the phylogenetic/spatial/pedigree covariance structure down
   to a plain `(1 | group)` random intercept-plus-slope on NB2 dispersion, and compare drmTMB ML
   against an external comparator -- `glmmTMB(dispformula = ~ ..., REML = TRUE/FALSE)` -- on that
   simplified, structurally comparable DGP. No such comparator run exists yet for any of these four
   cells (checked: not in the fixtures file, the runner, or the ledger rows), which is itself worth
   flagging: a claim about a family-wide estimation bias is exactly the kind of claim that needs an
   external check. glmmTMB's current robustness for `dispformula` random effects under
   `REML = TRUE` has not been verified in this session and should be confirmed before treating it as
   ground truth.
2. **Laplace/AGHQ integration error specific to the NB2 dispersion nonlinearity.** `size = 1/sigma^2`
   makes the dispersion-side random effect enter the NB2 likelihood highly nonlinearly, and this
   repo's own O3 record documents a comparable, non-negligible Laplace-vs-AGHQ gap for a different
   nonlinear link (`docs/design/224...md`, "~2.3 pt at M=40" for cumulative_logit). Cheapest
   experiment: refit a small subset (e.g. one cell, all three seeds) with drmTMB's AGHQ integrator
   instead of the default Laplace approximation, holding data, seeds, and estimator (ML) fixed, and
   check whether the point estimates move toward 0.55.
3. **Finite-sample intercept/slope confounding** (the mechanism the fixtures file already
   investigated for `mc-0424` and `mc-0423`). Already tested and *ruled out* for `mc-0423`'s single
   worst-offending seed specifically (realized cor(v0, v1) = -0.14, not an outlier over a 10-seed
   scan; `tools/run-arc2-profile-feasibility.R:417-418`), so it is not a family-wide default
   explanation. Cheapest experiment: compute realized cor(v0, v1) for all twelve fixture draws (each
   receipt's `fixture_path` names the saved fixture `.tsv`, though these currently live on the
   Totoro host, not in this worktree) and regress signed relative deviation on it across the twelve
   points; a null relationship would rule this out family-wide the same way it was already ruled out
   for one seed.
4. **An optimizer- or parameterization-level artifact specific to
   `drm_control(optimizer_preset = "robust")`.** Checked, and downgraded: this preset only raises
   `nlminb`'s `iter.max`/`eval.max` to 5000 (`R/control.R:294-300`); it changes no starting values,
   bounds, or penalty term. A directional artifact from this specific setting is possible in
   principle (e.g. through which local optimum a longer search happens to find) but not obviously
   supported by what the preset actually configures. Cheapest experiment: refit a handful of the
   twelve under `optimizer_preset = "careful"` or `"default"` with a different starting value for the
   structured-sigma log-SD intercept; a stable sign pattern across presets would rule this out.
5. **A selection effect from the iterative fixture-design process itself.** As shown above, at
   least two cells' retained seeds were re-examined mid-redesign, and the whole family went through
   several look-then-adjust rounds gated on mean relative error (a magnitude criterion, not a sign
   criterion) rather than a pre-registered protocol. Cheapest experiment: run each of the four cells
   on a handful of brand-new seeds that have never appeared in any prior design, point-fit-gate, or
   re-gate round for that cell, and check whether the below-truth majority survives on seeds nobody
   has looked at before choosing them.

## Why This Was Not Resolved Here

Deciding which of these candidate explanations, if any, is the real driver -- and whether the
resulting bias is large enough to withhold or requalify any claim -- is an owner/inference
decision, not a mechanical one. It requires deciding how much of drmTMB's limited
comparator-checking and REML-extension effort to spend chasing a signal that, at the only
defensible unit of replication (four cells), does not yet clear conventional significance. That
decision does not belong to a truth-gate pass whose job was to check whether each cell's own
retained intervals bracket its own truth -- the narrower task this finding was surfaced during.

## Disposition -- What This Does Not Change

No cell's `evidence_tier` moves because of this finding, and this note edits nothing under
`docs/dev-log/dashboard/`. Specifically:

- `mc-0424`'s demotion from `interval_feasible` to `point_fit_recovery`, already landed elsewhere
  in this same arc (`cells.tsv:428`), is driven by its own interval missing truth (seed
  2026080301's [0.2567, 0.5156] excludes 0.55) -- a single, self-contained, per-cell fact. It would
  stand or fall on its own even if this cross-cell pattern did not exist, and it is not being used
  as corroboration for this finding, or vice versa.
- `mc-0423` remains at `point_fit_recovery` on its own prior, already-documented withhold
  (`cells.tsv:427`).
- `mc-0421` and `mc-0422` remain `interval_feasible`: all six of their retained intervals bracket
  0.55. Nothing in this note downgrades either cell.
- `cells.tsv:428`'s `next_gate` field for `mc-0424` already names this document as a prerequisite
  for restoring an interval claim. This document supplies the triage that field asks for, not the
  settlement: the family-level question stays open until an owner picks a candidate explanation to
  chase above (or explicitly declines to).
- This note does not extend to any other nbinom2 structured-sigma cell, any other family's
  structured-sigma cells, or any mean-side (`mu`) structured random effect. The pattern was checked
  only for the four cells sharing this exact DGP template (NB2, `sigma`, intercept-plus-one-slope
  grammar, true intercept SD 0.55).

## Issue Ledger

I did not query the live GitHub issue tracker for this task: my instructions were to draft, not
file, and specifically not to run `gh`. The only issue number referenced elsewhere in this
repository's own `docs/dev-log/after-task/` history that is even loosely topical is #682,
"Methods: profile likelihood as the featured CI method" (cited in, e.g.,
`docs/dev-log/after-task/2026-08-02-arc1-first-interval-feasibility-cohort.md` and
`...-arc2-interval-feasibility-first-tranche.md`). That issue concerns the profile-likelihood CI
*method* generally; this finding concerns a possible *estimation* bias in specific point
estimates -- related, since both touch the same profile machinery, but probably not the same
issue. A human should search the live tracker for #682 and for any open issue mentioning
`nbinom2`, `structured sigma`, `variance component bias`, or `mc-0421`/`mc-0422`/`mc-0423`/
`mc-0424` before filing, per this protocol's preference for updating an existing issue over
opening a duplicate.

Recommendation: open a new issue if that search turns up nothing closer. Draft below.

> **Title:** nbinom2 structured-sigma random-intercept SD: 11/12 retained ML point estimates fall
> below truth across all four provider cells (mc-0421-mc-0424)
>
> **Body:**
>
> Across the four nbinom2 structured-sigma provider cells that share one DGP template (true
> structured-intercept SD 0.55 on `log(sigma)`, intercept-plus-one-slope grammar,
> `tools/arc3-nbinom2-sigma-provider-fixtures.R`), the retained profile receipts give 12 ML point
> estimates (4 cells x 3 seeds, seeds 2026080301/02/03). Eleven of twelve fall below 0.55
> (one-sided sign-test p = 0.0032 treating the 12 as independent; a cell-level re-analysis that
> respects the shared DGP gives p = 0.0625 over 4 cells, not significant at 0.05).
>
> Full analysis, the twelve-estimate table, the independence critique, and five candidate
> explanations with proposed cheap discriminating experiments:
> `docs/dev-log/after-task/2026-08-03-nbinom2-structured-sigma-family-low-bias.md`.
>
> This is a flagged pattern, not a proven bias: the evidence does not establish a bias magnitude
> or a cause, and the only defensible unit of replication (4 independent DGP designs) is too small
> for any method to give a well-calibrated p-value. No cell's `evidence_tier` should move on this
> issue alone.
>
> Candidate mechanisms (see the linked note for detail and proposed experiments): ML-vs-REML
> downward bias in variance-component estimation (well established generally; drmTMB's own
> `docs/design/224` already documents and partially corrects an analogous ~42% ML bias for a
> different family's mean-side random intercept, but no REML-style machinery exists yet for a
> dispersion-side random effect on any family); Laplace/AGHQ integration error specific to the NB2
> dispersion nonlinearity; finite-sample intercept/slope confounding (already tested and ruled out
> for one seed; not yet tested family-wide); an optimizer/parameterization artifact (partially
> downgraded: the "robust" preset only raises iteration/evaluation budgets); and a selection effect
> from the iterative, look-then-adjust fixture-design process.
>
> Owner decision needed: which candidate explanation, if any, to chase, and whether/when to
> reconsider `mc-0423` or re-open an interval claim for `mc-0424` pending that work.

## Next Actions

1. An owner reviews this note and either commissions one or more of the five candidate-explanation
   experiments above, or explicitly declines to pursue the question further for now.
2. If pursued, the cheapest and most informative next steps are candidate explanations 3 (the
   cor(v0, v1) regression, which reuses receipts and fixture files already on disk and needs no new
   fits) and 5 (fresh, never-tuned-against seeds); both are cheaper than 1 (needs new estimator
   development or an external comparator) and are more targeted than 4 (already partly downgraded
   by the code check above).
3. Open the GitHub issue drafted above, or fold this into an existing issue if a human search turns
   up a better match than the weak candidate noted there.
4. Do not re-open `mc-0424`'s interval claim, promote `mc-0423`, or otherwise move any cell's
   `evidence_tier` on the basis of this note alone -- `tools/profile_truth_gate.py`'s per-cell
   location/rate rule remains the mechanical gate for that, and nothing in this document changes
   it.
