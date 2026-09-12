# Joint OU-sigma sparse 1,000-tip preflight

**Scope:** one local ML fit of the admitted univariate Gaussian independent
location-plus-log-scale OU intercept model. This is a resource preflight, not a
recovery or model-selection campaign.

**Command:**

```sh
/usr/bin/time -l Rscript tools/phylo-ou-sigma-1000-rss-preflight.R
```

**Measured 2026-09-12:** 1,000 tips; 2,000 rows; 1,999 retained all-tree nodes
per field; 3,998 latent values across the two fields. The fit's internal elapsed
time was 14.681 seconds; end-to-end wall time was 43.71 seconds. `nlminb`
returned convergence 0; `pdHess` was false, so this receipt is not an inference
or recovery claim. macOS `/usr/bin/time -l` recorded maximum resident set size
2,346,958,848 bytes and peak memory footprint 592,118,840 bytes.

The preflight asserts the all-node sparse layout and never builds a dense tip
covariance. Its purpose is only to establish that the native route remains
sparse at this size before any approved retained campaign.
