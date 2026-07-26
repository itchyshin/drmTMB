# A1 `R = 999` percentile-bootstrap diagnosis

This prespecified follow-up separates percentile-endpoint Monte Carlo error from
the other explanations for the `0.8714` marginal-bootstrap coverage observed in
the A1 Gaussian random-intercept campaign.

It reruns two original cells with the same 1,000 outer DGP seeds and all package
settings unchanged, except for `R_boot = 999` rather than `199`:

- `c01`: 10 groups, 4 observations per group, `sd_mu = 0.5`;
- `c03`: 50 groups, 4 observations per group, `sd_mu = 0.5`.

The low/high group-count pair tests whether any endpoint-resolution effect is
large enough to explain the shortfall across the observed group-count gradient.
The paired outer seeds make direct coverage and interval-width comparisons more
informative than an unpaired rerun. This is diagnostic evidence only: it cannot
promote a capability-ledger cell.

Run `launch_r999_subset.sh` on Totoro from `~/drm_work`. It authenticates the
unchanged `a1_coverage.R` source by SHA-256, caps BLAS threads, retains all
outer attempts, and writes raw output only to Totoro in accordance with D-50.

## Completed diagnostic

The paired `R = 999` run completed on 2026-07-26 with all 200 expected shard
CSVs, zero detected error logs, the expected A1 harness SHA-256, 2,000 old
rows, 2,000 new rows, no incomplete pairs, and no duplicate `(cell_id, seed)`
pairs. The R=999 coverage increases were +0.1 percentage points at 10 groups
and +0.3 at 50 groups; their paired 95% CIs both include zero and are far below
the prespecified +2-point practical threshold. Thus `R = 199` percentile-tail
resolution is not the dominant explanation for the A1 shortfall in these cells.

See `r999-authentication-receipt.md` and `r999-diagnosis-report.md`. This is
not evidence that percentile-boundary behavior or low-group Laplace refit bias
is absent.

## Profile comparator: smoke passed, full campaign held

`profile_vs_bootstrap.R` is a fresh paired scalar-A1 harness for the frozen
three-cell design: 10, 25, and 50 groups; 10 observations per group; true RE
SD 0.5; profile, marginal percentile bootstrap, and Wald intervals from every
outer fit. It retains all statuses and endpoint classes in one wide row per
outer attempt. `a1_profile_common.R` supplies engine-free interval-accounting
helpers with a testthat contract test.

The one-attempt-per-cell Totoro smoke passed under Totoro's installed `drmTMB`
0.6.0 build: all three fits converged with `pdHess = TRUE`, and profile (`endpoint`),
marginal bootstrap (`R = 19`), and Wald returned valid scalar SD endpoints.
This proves runner plumbing only. The 3,000-attempt / `R = 999` full campaign
is explicitly held pending Shinichi's separate compute approval packet in
`profile-vs-bootstrap-protocol.md`.
