# Four-fixture R--Julia ordinary-Laplace contract

## Scope and pins

This contract records the bridge-side four-fixture classification prerequisite
for the 0.7.1 ordinary-Laplace parity programme. The frozen preliminary
receipts were run at drmTMB `9939ace07967af9a9b6e23a4d021080d5d7d76a7` and
DRM.jl `b877f5136dbd13b6ff1cb3a1de02ee826b0fdf1c`; their compact historical
reconciliation is [`reconciled-summary.tsv`](reconciled-summary.tsv).

**Supersession notice (2026-09-11).** Review found that `b877f513` clamped a
scalar Laplace raw random-effect log-SD inside the objective while reporting an
unclamped gradient. Candidate `6125d08e` repairs that defect. Consequently the
listed preliminary receipts remain useful diagnostics and fixture/target
design inputs, but they are not current same-target parity, matrix, or coverage
evidence. A new campaign may use only a commit-proven source staging receipt:
each source archive must equal `git archive` of its declared commit contained
in a staged Git bundle. The active retained campaign is pinned to drmTMB
`453cff782900aa55211d3f5971c229fc485d291e` and DRM.jl
`b2caf00f23f080fe89028966a4bfb098ef095510`; its remote source-staging receipt
is authoritative. Earlier pins (`1ae582c9`, `26f4c4dd`, `d24a30d09`, and
`ded85602a`) are technical history, not substitute evidence.
Every task must record source cleanliness, R/TMB/JuliaCall/Julia identities,
Julia project and thread settings, requested and effective marginal integrators,
the family-specific objective convention, a fixture-byte digest, the runner
digest, and the target manifest. A receipt from an earlier source pin is
debugging material, not parity evidence.

## Frozen fixture table

| Fixture | R formula | Julia target | Current bridge evidence | Admission condition |
| --- | --- | --- | --- | --- |
| Binomial RI | `y ~ x + (1 | id)` | `Binomial(); marginal = :Laplace` | retained S7: 500 paired seeds, every free outer target classified | one ordinary mean RI |
| Poisson RI | `y ~ x + (1 | id)` | `Poisson(); marginal = :Laplace` | retained S7: 500 paired seeds, every free outer target classified | one ordinary mean RI |
| NB2 RI | `count ~ x + (1 | id), sigma ~ 1` | `NegBinomial2(); marginal = :Laplace` | retained S7: 500 paired seeds, every free outer target classified | one ordinary mean RI, constant `sigma` |
| coupled NB2 location--scale | `count ~ x + (1 | p | id), sigma ~ z + (1 | p | id)` | matching q=2 location--scale Laplace route | retained S7: 500 paired seeds; every target classified, including retained profile/non-finite outcomes | one matching labelled intercept pair |

The target manifest, not an ad-hoc coefficient vector, will define all common,
free outer parameters on named link/transformed scales. Inner modes never enter
the comparison. Every requested target must receive point, SE, convergence,
gradient/Hessian, and profile-endpoint statuses; absence and non-finiteness are
classified outcomes, never dropped rows.

For the coupled fixture, the common covariance coordinates are explicitly the
three raw Cholesky entries `L11`, `L22`, and `L21`, because they are the shared
working-scale interface. Native R also exposes derived SD and correlation
targets; these are recorded as `engine_only` inventory rows, never profiled as
pretended same-target quantities or silently discarded from the receipt.

## Coupled-NB2 admission design and remaining inference gate

The native prerequisite is designed for one complete-data, non-ZI,
ordinary NB2 cell with exactly one matching labelled intercept pair. The bridge
marshals `p` as a covariance label rather than a data column, reconstructs the
three `recov_group:L11/L22/L21` coordinates, and reports the corresponding
native-scale SD/correlation summaries. The current Julia route uses the same
guarded covariance domain as native TMB; it also rejects non-finite raw
coordinates and treats `L21 = 0` as an unconstrained native-covariance case.
Those source-level checks do not replace a corrected-current-pin point or
profile receipt.

The historical preflight classified each raw Cholesky coordinate with a terminal
profile status. The R bridge profiles these coordinates as
`cholesky:recov:L11/L22/L21` on their declared working scale. It does not
relabel those endpoints as response-SD or correlation intervals; that would be
a different reparameterized profile. Those statuses, including historical
non-finite L22 endpoints, must be rerun and retained under the corrected pin.

## Campaign boundary

Earlier receipts remain diagnosis only. The authoritative corrected-source
campaign is the retained
[`s7-coverage-summary.tsv`](s7-coverage-summary.tsv), pinned to drmTMB
`453cff782900aa55211d3f5971c229fc485d291e` and DRM.jl
`b2caf00f23f080fe89028966a4bfb098ef095510`. It records 500 paired DGP seeds
per fixture, 2,000 paired data sets, and 17,000 engine-target profile attempts.
All attempted seeds remain in the unconditional denominator, with fit failure,
profile failure, non-finite endpoint, and truth-outside statuses kept separate.

The campaign estimates empirical profile-interval coverage only for these four
frozen scenarios. It does not establish general calibration, general R--Julia
coverage parity, performance, or release readiness. Any future campaign needs
a new source pin, a new cost receipt, and its own retained denominator.
