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
