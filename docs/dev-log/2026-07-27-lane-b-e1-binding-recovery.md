# Lane B E1 count-q1 exact-binding adjudication

## Decision and scope

**Decision:** accept all eight reviewed rows as **proposed, planning-only E1
candidate contracts**: `mc-0410`, `mc-0411`, `mc-0412`, `mc-0413`, `mc-0435`,
`mc-0441`, `mc-0448`, and `mc-0452`.  Each supplies the six E0 identity fields:
an exact archived DGP/version and source function, formula, truth on its
reporting scale, one direct target, a retained information rung, and a source
receipt.  The candidate target ID is the matrix target prefixed by its cell ID,
for example `mc-0410::sd:mu:phylo(0 + x | site)`.  This applies the E0 rule
that a schedule can only use an exact DGP/function-version, formula,
truth/reporting scale, namespaced direct target, information rung, and source
receipt ([`2026-07-27-lane-b-e0-binding-recovery.md:68-74`](2026-07-27-lane-b-e0-binding-recovery.md)).

**Counts:** 8 accepted proposed candidates; 0 deferred/unresolved among this
specified eight-cell tranche.  “Accepted” is deliberately narrower than a
canonical binding: none of these rows has been inserted into a canonical
binding TSV, scheduled, or run by this adjudication.  All eight remain
unscheduled until the full-cohort gate below is met.

This is an internal E1 review record only.  It preserves the **no-compute,
no-public, and no-ledger** fences: it authorizes no local or remote smoke,
Totoro/DRAC request, pregrid, campaign, capability transition, documentation
claim, or default change.  It is unrelated to Lane A association, bootstrap,
and missing-response work.

## E0 identity-field adjudication

The authoritative proposed values are the eight rows of
[`interval-campaign-bindings/2026-07-27-e1-count-q1-source-target-matrix.tsv:2-9`](interval-campaign-bindings/2026-07-27-e1-count-q1-source-target-matrix.tsv).
The stable runner symbol named in each row is part of the DGP/source identity;
the displayed `sd:mu:*` string becomes the exact namespaced target by adding
`cell_id::`, not by inferring another component from the shared
intercept-plus-slope formula.

| Cell | Proposed DGP/version and formula | Truth/reporting scale and direct namespaced target | Retained rung and source | Adjudication / caveat |
| --- | --- | --- | --- | --- |
| `mc-0410` | `count_slope_phylo_nbinom2_q1_mu_one_slope` (archived local micro-shard, 2026-06-26); `bf(nb2_phylo ~ x + phylo(1 + x \| site, tree = tree), sigma ~ 1); nbinom2()` | 0.45 on the NB2 log-mu phylogenetic slope-SD scale; `mc-0410::sd:mu:phylo(0 + x \| site)` | 8 tips × 20 observations/tip; 80 Rorqual recovery replicates; `seed_start=760001`; `new_phylo_nbinom2_slope_data` in the cited runner | **Accept proposed candidate.** It binds the slope only, not the separate 0.25 intercept SD. |
| `mc-0411` | `count_slope_spatial_nbinom2_q1_mu_one_slope` (archived local micro-shard, 2026-06-26); `bf(nb2_spatial ~ x + spatial(1 + x \| site, coords = coords), sigma ~ 1); nbinom2()` | 0.45 on the NB2 log-mu spatial slope-SD scale; `mc-0411::sd:mu:spatial(0 + x \| site)` | 8 sites × 20 observations/site; 80 Rorqual recovery replicates; `seed_start=760001`; `new_spatial_nbinom2_slope_data` in the cited runner | **Accept proposed candidate.** Retain the archived 2/80 `pdHess = FALSE` recovery caveat. |
| `mc-0412` | `count_slope_animal_nbinom2_q1_mu_one_slope` (archived local micro-shard, 2026-06-26); `bf(nb2_animal ~ x + animal(1 + x \| id, Ainv = Q), sigma ~ 1); nbinom2()` | 0.45 on the NB2 log-mu animal slope-SD scale; `mc-0412::sd:mu:animal(0 + x \| id)` | 8 ids × 20 observations/id; 80 Rorqual recovery replicates; `seed_start=760001`; `new_animal_nbinom2_slope_data` in the cited runner | **Accept proposed candidate.** It binds the slope only, not the separate 0.25 intercept SD. |
| `mc-0413` | `count_slope_relmat_nbinom2_q1_mu_one_slope` (archived local micro-shard, 2026-06-26); `bf(nb2_relmat ~ x + relmat(1 + x \| id, Q = Q), sigma ~ 1); nbinom2()` | 0.45 on the NB2 log-mu relatedness slope-SD scale; `mc-0413::sd:mu:relmat(0 + x \| id)` | 8 ids × 20 observations/id; 80 Rorqual recovery replicates; `seed_start=760001`; `new_relmat_nbinom2_slope_data` in the cited runner | **Accept proposed candidate.** It binds the slope only, not the separate 0.25 intercept SD. |
| `mc-0435` | `count_slope_phylo_poisson_q1_mu_one_slope` (archived local micro-shard, 2026-06-26); `bf(poisson_phylo ~ x + phylo(1 + x \| site, tree = tree)); poisson(log)` | 0.45 on the Poisson log-mu phylogenetic slope-SD scale; `mc-0435::sd:mu:phylo(0 + x \| site)` | 8 tips × 20 observations/tip; 80 Rorqual recovery replicates; `seed_start=760001`; `new_phylo_poisson_slope_data` in the cited runner | **Accept proposed candidate.** It binds the slope only, not the separate 0.25 intercept SD. |
| `mc-0441` | `count_slope_spatial_poisson_q1_mu_one_slope` (archived local micro-shard, 2026-06-26); `bf(poisson_spatial ~ x + spatial(1 + x \| site, coords = coords)); poisson(log)` | 0.45 on the Poisson log-mu spatial slope-SD scale; `mc-0441::sd:mu:spatial(0 + x \| site)` | 8 sites × 20 observations/site; 80 Rorqual recovery replicates; `seed_start=760001`; `new_spatial_poisson_slope_data` in the cited runner | **Accept proposed candidate.** It binds the slope only, not the separate 0.25 intercept SD. |
| `mc-0448` | `count_slope_animal_poisson_q1_mu_one_slope` (archived local micro-shard, 2026-06-26); `bf(poisson_animal ~ x + animal(1 + x \| id, Ainv = Q)); poisson(log)` | 0.45 on the Poisson log-mu animal slope-SD scale; `mc-0448::sd:mu:animal(0 + x \| id)` | 8 ids × 20 observations/id; 80 Rorqual recovery replicates; `seed_start=760001`; `new_animal_poisson_slope_data` in the cited runner | **Accept proposed candidate.** It binds the slope only, not the separate 0.25 intercept SD. |
| `mc-0452` | `count_slope_relmat_poisson_q1_mu_one_slope` (archived local micro-shard, 2026-06-26); `bf(poisson_relmat ~ x + relmat(1 + x \| id, Q = Q)); poisson(log)` | 0.45 on the Poisson log-mu relatedness slope-SD scale; `mc-0452::sd:mu:relmat(0 + x \| id)` | 8 ids × 20 observations/id; 80 Rorqual recovery replicates; `seed_start=760001`; `new_relmat_poisson_slope_data` in the cited runner | **Accept proposed candidate.** It binds the slope only, not the separate 0.25 intercept SD. |

Each row's complete source chain—including the array task, runner function,
artifact directory, and test block—is retained verbatim in its corresponding
matrix row rather than replaced by this summary
([`2026-07-27-e1-count-q1-source-target-matrix.tsv:2-9`](interval-campaign-bindings/2026-07-27-e1-count-q1-source-target-matrix.tsv)).
This matters because the common DGP contains both intercept and slope SDs: the
E0 recovery record expressly prohibits choosing either component silently
([`2026-07-27-lane-b-e0-binding-recovery.md:20-29`](2026-07-27-lane-b-e0-binding-recovery.md)).

## What direct-evidenced target availability does not establish

`direct_evidenced` here establishes only that the proposed cell-specific slope
target has an exact source/DGP identity and can be named directly.  It is **not**
profile-interval calibration, coverage, availability, capability, or
transferable support.  The source matrix itself records that no count-specific
profile route or interval calibration is evidenced for these rows
([`2026-07-27-e1-count-q1-source-target-matrix.tsv:2-9`](interval-campaign-bindings/2026-07-27-e1-count-q1-source-target-matrix.tsv)); the archived Rorqual work is recovery-only and never called
`confint()` ([`2026-07-27-lane-b-e0-binding-recovery.md:20-29`](2026-07-27-lane-b-e0-binding-recovery.md)).

Existing exact-DGP route observations are likewise not reclassified here.  The
E0 record reports lower-bound contact for the Poisson and NB2 candidates and,
for `mc-0411`, the retained recovery convergence caveat; it calls them
non-covering technical evidence, not finite-profile successes
([`2026-07-27-lane-b-e0-binding-recovery.md:196-245`](2026-07-27-lane-b-e0-binding-recovery.md)).
No result from one provider, family, target component, information rung, or
seed transfers to another.

## Design-2 dependency: unavailable means unavailable

This candidate set depends on the merged trace-first full-profile contract, not
on the separate endpoint engine.  `drm_tmbprofile()` wraps every full
`TMB::tmbprofile()` `obj$fn()` evaluation, and
`drm_profile_direct_sd_clamp_trace()` returns `clamp_limited` or
`trace_incomplete` whenever clamp contact cannot be excluded
([`2026-07-27-lane-b-e1-design2-source-map.md:40-61`](2026-07-27-lane-b-e1-design2-source-map.md)).
Accordingly, E1 must treat `clamp_limited`, `trace_incomplete`,
`nonfinite_interval`, failed fits, and missing attempts as **unavailable and
non-covering**.  Neither a finite-looking endpoint nor a Wald substitute may
repair that outcome.

In particular, a finite K=12 profile is an **error**, not a successful interval.
The only K=12 control is `mc-0260m`; its allowed non-success reductions are
`nonfinite_interval`, `clamp_limited`, or `trace_incomplete`, with
`interval_status = "incomplete"`, `complete_profile = 0`, and
`usable_and_covering = 0`
([`2026-07-27-lane-b-e1-design2-source-map.md:68-77`](2026-07-27-lane-b-e1-design2-source-map.md)).
The eight q1 rows above are not that control and must not be used to soften its
contract.  The source map limits trace evidence to the full `tmbprofile` route;
it makes no clamp-detection assertion for endpoint profiles
([`2026-07-27-lane-b-e1-design2-source-map.md:84-93`](2026-07-27-lane-b-e1-design2-source-map.md)).

## Concrete next approval gate

Before any binding-table edit, smoke, schedule, or compute request, a reviewer
must verify these eight candidate strings against the cited archived source
functions and review their inclusion alongside the other unresolved E0 cells.
Only after every non-foreign E0 candidate has a reviewed exact DGP/formula/
truth/direct-profile binding may an E1 pregrid packet be drafted.  That packet
must name the source SHA, manifest hashes, 150-attempt seed schedule, resource
estimate, output location, validation command, and no-ledger boundary; then
**Shinichi must explicitly approve it** before any Totoro or DRAC action
([`2026-07-27-lane-b-e0-readiness-receipt.md:119-126`](2026-07-27-lane-b-e0-readiness-receipt.md)).
