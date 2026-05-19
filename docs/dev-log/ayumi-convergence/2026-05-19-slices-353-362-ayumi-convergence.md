# Slices 353-362 Ayumi Convergence Stress Test

## Task Goal

Use Ayumi's local lightness data as a package-adjacent stress test for the
current bivariate Gaussian location-scale and correlation machinery. The goal
was not to claim a scientific result from these data. It was to answer three
engineering questions before the next simulation wave:

- does the current bivariate residual `rho12` path still run cleanly on a real
  trait table;
- does the phylogenetic mean-correlation path run once tree preflight is made
  explicit;
- does the full q4 phylogenetic location-scale/correlation path look stable
  enough for reader-facing examples or simulations.

## Evidence Artifacts

The reproducible script is `tools/ayumi-convergence-stress.R`. It reads local
data from `DRMTMB_TEST_DIR`, defaulting to:

```text
../drmTMB-test
```

It writes compact summary artifacts, not raw data, to:

```text
docs/dev-log/ayumi-convergence/slices-353-362/
```

The committed artifacts are:

- `tree-preflight.csv`
- `fit-summary.csv`
- `check-rows.csv`
- `corpairs.csv`
- `profile-targets.csv`
- `profile-intervals.csv`
- `fit-conditions.csv`

## Data And Preflight

Ada used `data_raw/data_6196spp.csv` because it contains
`Delhey_lightness_male`, `Delhey_lightness_female`, and `phylo_name`.
The smaller `dat_500spp.csv` is useful for other checks but does not contain
the Delhey lightness columns needed for the bivariate male/female response.

The script uses a deterministic 80-species aggregate table and a row-level
variant with up to five rows per species. The 10,597-tip tree contains the 80
selected species after pruning, but the raw pruned tree is not ultrametric:
`tree-preflight.csv` records `raw_tree_ultrametric = FALSE`. That is why the
raw phylogenetic scenario fails before fitting with:

```text
`tree` must be ultrametric.
Root-to-tip distances differ by more than 1.49011611938477e-08.
```

For stress testing only, the script also creates a forced-ultrametric tree with
`phytools::force.ultrametric(method = "extend")`. The output keeps the
`phytools` cautionary note visible because this is a numerical coercion for a
stress test, not a formal rate-smoothing analysis.

## Main Results

The non-phylogenetic aggregate fits are clean:

| Scenario | Result |
| --- | --- |
| `agg_base_80_careful` | convergence 0, `pdHess = TRUE`, no `check_drm()` warnings; residual `rho12 = 0.6465`; profile CI from `corpairs(conf.int = TRUE)` is `[0.4999, 0.7570]`. |
| `agg_ls_rho_80_careful` | convergence 0, `pdHess = TRUE`, no `check_drm()` warnings; predictor-dependent residual `rho12` mean `0.6744`, range `[0.5582, 0.7838]`. |

The phylogenetic mean fit runs after forcing ultrametricity, but the fitted
phylogenetic mean-mean correlation is on the boundary:

| Scenario | Result |
| --- | --- |
| `agg_phylo_mean_forced_tree_80_careful` | convergence 0 and `pdHess = TRUE`, but `check_drm()` reports `biv_phylo_mu_covariance` warning with `rho_abs = 1.000` plus single-observation species replication notes. |

The full q4 phylogenetic location-scale variants run, but they are not
trustworthy:

| Scenario | Result |
| --- | --- |
| `agg_phylo_q4_forced_tree_80_careful` | false convergence, `pdHess = FALSE`, fixed-gradient warning, non-finite SE warning, q4 max absolute correlation `0.9945`. |
| `agg_phylo_q4_forced_tree_80_robust` | false convergence, `pdHess = FALSE`, repeated `NA/NaN function evaluation` warnings, q4 max absolute correlation `0.9936`. |
| `agg_phylo_q4_rho_forced_tree_80_robust` | false convergence, `pdHess = FALSE`, predictor-dependent residual `rho12` present but q4 warnings remain. |

The row-level variants are a bad rescue for this data structure because the
male and female responses are species-level constants repeated over rows:

| Scenario | Result |
| --- | --- |
| `row5_phylo_mean_forced_tree_80_robust` | false convergence, `pdHess = FALSE`, enormous fixed-gradient warning, residual `rho12` boundary `1.000`. |
| `row5_phylo_q4_forced_tree_80_robust` | false convergence, `pdHess = FALSE`, enormous fixed-gradient warning, residual `rho12` boundary `0.9980`. |

## Interpretation Boundary

The current package can fit and report:

- bivariate residual `rho12` on real bivariate trait data;
- predictor-dependent residual `rho12`;
- phylogenetic mean-mean correlation rows in `corpairs()`;
- direct residual `rho12` profile intervals through `corpairs(conf.int = TRUE)`.

The current package should not yet present the full q4 phylogenetic
location-scale fit as an applied example for Ayumi's data. The diagnostics are
doing their job: they show false convergence, non-positive-definite Hessians,
large gradients, boundary correlations, and weak replication before a reader
can overinterpret the six latent q4 correlations.

## What This Says About Warm Starts

Optimizer presets (`careful`, `robust`) are not a substitute for a real
warm-start or multistart contract. On these data, increasing the optimizer
budget did not rescue the q4 path. A future warm-start slice should be explicit:
define the source fit, map fixed parameters and latent covariance parameters
into the target model, record provenance in the fitted object, and test that
the target model improves because of the start rather than by chance.

## Team Review

Ada integrated the stress script, evidence artifacts, and slice records.
Fisher treated the run as convergence evidence, not a biological analysis.
Gauss and Noether kept residual `rho12`, phylogenetic mean correlation, and q4
latent correlations separate. Curie checked that the artifacts expose failed
and boundary cases instead of silently hiding them. Pat's reader-facing verdict
is that the q4 model needs a convergence guide before it can become a tutorial
example. Grace kept the run package-adjacent by committing only summary CSVs.
Rose flags the repeated pattern: the more ambitious correlation examples need
preflight and diagnostic prose before they need prettier output.

## Next Actions

1. Add a convergence-workflow note for non-ultrametric tree preflight,
   boundary `rho12`, and q4 simplification choices.
2. Keep Ayumi's full q4 data case as a stress test, not a showcase example.
3. Add a formal warm-start design slice before promising that starting values
   can rescue q4 phylogenetic location-scale fits.
4. Feed the stable residual-`rho12` and non-phylogenetic location-scale pieces
   into the next simulation wave; keep q4 phylogenetic models in a separate
   harder-identifiability lane.
