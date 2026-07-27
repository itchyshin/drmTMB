# Arc 6 F4 completion review: alpha Godambe-Wald screen

## Verdict

**FAIL — public association uncertainty remains unavailable.** The approved
DRAC campaign completed its frozen 24-cell, 24,000-attempt grid, and its
provenance and all-attempt receipts authenticate. However, five cells miss the
pre-registered lower bound of 0.925 for primary, all-valid-protocol alpha-Wald
coverage. Unavailable alpha intervals remain primary non-coverage, exactly as
pre-registered; they cannot be removed or converted to conditional coverage.

This is a calibration result for the private link-scale `alpha` candidate. It
does not authorize `vcov()` or `confint()` for `associate_pairs()`, an eta
interval, a bootstrap claim, a capability/ledger change, or a public inference
claim.

## Campaign authentication

| Check | Evidence | Verdict |
| --- | --- | --- |
| source | 24 `provenance.txt` receipts record `a97aa0930cbfe635886f483cb32baf4e75f74227` | PASS |
| private blobs | every receipt records sandwich blob `d090f67b74bf5dfee6baa4396a8f45a3c977d6fd` and fixture blob `d36b02b2ad470e641843d4f751ee1c998e6922bf` | PASS |
| schedule and retention | 24 `RUN-COMPLETE.txt` and 24 all-attempt tables contain 24,000 unique `(cell_id, replicate)` rows: 1,000 per cell | PASS |
| protocol | all 24,000 rows have `protocol_status = valid`; no quarantine, source, fixture, seed, DGP, or schema mismatch was found | PASS |

The retained terminal statuses are informative, not removable observations:
23,740 `eta_delta_unavailable`, 257 `boundary_unresolved`, and 3
`bread_or_meat_unstable`. `RUN-COMPLETE.txt` therefore means that a shard
finished its assigned attempts, not that every attempt reached
`complete:success`. The eta-delta field is descriptive only in F4; its
unavailability does not withhold an otherwise available alpha interval. The
257 unresolved associations and 3 unstable sandwiches withhold the alpha
estimate/interval and therefore count as primary non-coverage.

The retained eta-delta status also exposes a private runner limitation: the
sandwich returns rowwise eta SEs, while the F4 extractor accepts eta only when
that value is scalar. Thus eta availability is zero throughout the campaign.
This neither changes the alpha estimand nor rescues or causes the F4 failure,
but it confirms that F4 supplies no eta-interval claim and must be fixed only
in a separately approved future arc.

## Frozen cell-wise screen

All 24 cells meet the frozen absolute-bias, alpha-Godambe-availability,
interval-availability, and mean-SE-to-empirical-SD requirements. Five cells
fail the primary coverage rule; this is enough to fail the campaign.

| Cell | `(n, b0, sigma, alpha)` | interval availability | primary coverage (MCSE) | conditional coverage | Failed rule |
| --- | --- | ---: | ---: | ---: | --- |
| f4-c01 | `(120, -1.4, 0.25, 0)` | 0.964 | 0.896 (0.0097) | 0.929 | coverage |
| f4-c02 | `(120, -1.4, 0.25, 0.22)` | 0.950 | 0.887 (0.0100) | 0.934 | coverage |
| f4-c05 | `(120, -0.2, 0.25, 0)` | 0.960 | 0.912 (0.0090) | 0.950 | coverage |
| f4-c06 | `(120, -0.2, 0.25, 0.22)` | 0.957 | 0.904 (0.0093) | 0.945 | coverage |
| f4-c10 | `(240, -1.4, 0.25, 0.22)` | 0.985 | 0.923 (0.0084) | 0.937 | coverage |

`f4-c10` is close to the threshold, but the frozen decision uses the observed
cell result, not a post hoc tolerance or re-run. The four `n = 120`,
`sigma = 0.25` failures are materially below the threshold; their primary
coverage loss combines ordinary Wald non-coverage with retained unavailable
intervals. Conditional coverage is reported only to diagnose that mechanism;
it is not the decision denominator.

The private review files are `/private/tmp/arc6-f4-cell-summary.tsv` and
`/private/tmp/arc6-f4-protocol-status.tsv`; the durable DRAC source remains
`/home/snakagaw/arc6-f4-a97aa0930/results`.

The copied receipt packet does not independently preserve the later
SE/empirical-SD bootstrap seed/payload or the per-shard scheduler command and
manifest hash. Those gaps do not determine the frozen PASS/FAIL flags, which
already fail on retained all-attempt coverage, but they should be included in
any future campaign receipt.

## Disposition

Keep the public association methods fail-closed. Do not retry, alter the grid,
remove unavailable fits, change the denominator, or expose F5. A future method
arc would need a newly approved design that explains and addresses the
small-`n`, low-`sigma` failure pattern without borrowing this failed screen as
public validation.
