# After Task: AOI-2 fixed-effect association point-recovery consolidation

## 1. Goal

Consolidate the owner-authorized AOI-2 Bernoulli x ordinary-NB2 DRAC results
and review the point-only claim boundary. This is an evidence closeout, not an
implementation, capability, or uncertainty task.

## 2. Implemented

The frozen point-only analyser combined the original Rorqual root
`/project/def-snakagaw/snakagaw/drmTMB-aoi2/2026-07-29-aoi2-bnb-fixed-r3`
with its non-overlapping continuation
`/project/def-snakagaw/snakagaw/drmTMB-aoi2/2026-07-30-aoi2-bnb-fixed-r4`.
It wrote only temporary local analysis tables; the durable raw artifacts remain
on Rorqual. No package source, tests, public article, capability ledger, or
public API was changed.

## 3a. Decisions and Rejected Alternatives

The prespecified grid is the 15-cell Cartesian product of five fixed-effect
association designs and `n = 360, 720, 1440`, with 200 outer datasets per
cell. A cell can receive `PASS_POINT_RECOVERY_ONLY` only if all 200 keys are
retained, at least 95% are usable **interior** association fits, and every
declared alpha and fixed-newdata link target has absolute bias at most 0.10.
Near-boundary and boundary-unresolved fits remain in the denominator and are
not usable point-recovery fits. This contract has no covariance, standard
error, interval, profile, or coverage component.

The owner authorized consolidation and a point-only claim review, not a rerun,
reclassification, capability promotion, public reader update, or AOI-3 work.
Rejected alternatives are to report the small conditional bias while omitting
the retained availability denominator; to count `near_boundary` fits as
interior; or to pool the single stress-cell pass into a grammar-wide claim.
Each would change the prespecified estimand after observing the results.

## 4. Files Touched

- `docs/dev-log/after-task/2026-07-31-aoi2-point-recovery-consolidation-hold.md`

No R source, test, public article, capability ledger, or generated reader
surface was changed.

## 5. Checks Run

All 3,000 expected replicate/seed keys are retained exactly once: 42 original
shards (2,100 rows) plus 18 continuation shards (900 rows). Every cell has the
declared encoded design fingerprint and a single source SHA,
`b01e94f8d50951f6dd7cd5c1dc02a04b9bd93329`.

The outcome is **HOLD_NO_POINT_RECOVERY_CLAIM** for the programme. Only the
`mixed`, `n = 360` stress cell satisfies the mechanical per-cell gate
(199/200 interior fits); the protocol explicitly disallows a lower-sample-size
claim from that stress pass alone. The other 14 cells have interior-fit
availability from 27.0% to 94.5%, below the required 95%.

Across all attempts, 2,182 are interior, 110 near-boundary, and 708
boundary-unresolved. Each unavailable attempt records the same direct reason:
`Cannot predict from a boundary-unresolved association fit.` The largest
absolute bias among the available target summaries is 0.02275, but that
conditional-on-availability statistic cannot override the failed retained
availability gate.

## Claim Review

No AOI-2 point-recovery claim is approved. In particular, the low conditional
bias is not evidence that the full fixed-effect association grammar recovers
under the frozen grid, because the interior-fit denominator fails in 14 cells
and deteriorates rather than improves at larger `n` for several designs.

No uncertainty claim follows from this result. `vcov()`, `confint()`, profile,
standard-error, interval, covariance, and coverage routes remain unavailable;
AOI-3 has not begun.

- Rorqual `sacct` read-back: all 18 continuation tasks completed with exit
  status `0:0`.
- Retained-root count: 42 original plus 18 continuation `raw-attempts.csv`
  files, yielding 3,000 rows.
- `tools/summarize-aoi2-bernoulli-nb2-recovery.R` run against the combined
  temporary read-only copy. It produced complete retention, metric, and
  decision tables without modifying the cluster roots.
- `Rscript -e "devtools::test(filter = 'aoi2-recovery-dispatch',
  stop_on_failure = TRUE)"`: 9 passed, 0 failed, 0 warnings, 0 skips.

## 6. Tests of the Tests

The analyser rejects absent/duplicate/malformed cell keys, unsupported formula
or sample-size identifiers, malformed source SHA values, and design-fingerprint
drift before scoring any target. The focused test set additionally checks the
immutable Rorqual dispatch paths and the malformed-provenance fence. The
point-only analyser contains no code to calculate covariance, standard errors,
intervals, or coverage.

## 7a. Issue Ledger

`gh issue list --state open --search 'associate_pairs in:title,body' --limit 30`
returned no open matching issue. No issue, pull request, or public tracker
entry was changed. The result needs a fresh owner decision about a
diagnostic/repair design before any issue or implementation action is
appropriate.

## 8. Consistency Audit

`R/associate-pairs.R` confirms the observed error is intentional fail-closed
behaviour: `predict.drm_pair_association()` rejects
`status == "boundary_unresolved"`; it does permit `near_boundary`, which the
AOI-2 contract nevertheless excludes from the usable-interior numerator.

The required stale-wording scan also found that
`docs/design/01-formula-grammar.md` still says the Bernoulli x ordinary-NB2
route accepts only one numeric association slope. That is stale relative to
AOI-1's already-merged full fixed-effect grammar, but remains untouched here:
this authorization excludes public articles and the AOI-2 HOLD neither repairs
nor widens the API. No reader-facing status wording was changed because this
evidence is a HOLD, not an admission or promotion.

## 9. What Did Not Go Smoothly

The original 2-hour wall time left 18 `n = 1440` shards incomplete. The
owner-authorized, non-overlapping eight-hour continuation supplied those exact
900 rows; no original result was overwritten. More substantively, the
availability pattern is adverse: it is not a scheduler failure, and it cannot
be repaired by discarding boundary outcomes or by reporting only the successful
fits.

## 10. Known Residuals

The source route remains point-only and the AOI-2 validation grid remains a
HOLD. The campaign did not save an association object for a boundary-unresolved
prediction failure, so its raw record has the direct failure message but not a
separately retained fitted association status or coefficient vector. This does
not alter the all-attempt conclusion; it limits later diagnosis.

## 11. Team Learning

All-attempt availability needs to be a first-class gate alongside bias. The
conditional bias values look small, but would have produced a misleading
success narrative without the frozen interior-status denominator. Future
diagnosis should retain the association status before prediction is attempted,
so boundary cause and association coefficients are separately inspectable even
when newdata prediction correctly fails closed.

## 12. Cross-Product Coverage

This result covers only the frozen 15-cell Bernoulli x ordinary-NB2
fixed-effect point-recovery grid at the stated SHA. It does NOT cover recovery
for any formula family, factor encoding, interaction, transformation, sample
size, margin order, random/structured association effect, missingness, weight,
offset, alternative family pair, REML, engine, `mi()`, capability tier, or
uncertainty target. It does NOT cover `vcov()`, `confint()`, profiles,
standard errors, intervals, covariance, coverage, public documentation, or
AOI-3 authorization.

## Next Actions

Do not promote AOI-1/AOI-2 capability or start AOI-3. A later owner-authorized
diagnostic arc may investigate the boundary-unresolved prevalence and improve
the retained diagnostic payload; it must freeze a new design and preserve this
HOLD result rather than overwrite or pool it away.
