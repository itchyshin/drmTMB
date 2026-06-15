# After Task: Ayumi q4 R-First Status Harness

## Goal

Give the R side a concrete support/status table before chasing Julia speed. The
current user question is practical: for Ayumi's exact bivariate q = 4 Gaussian
phylogenetic location-scale formula, which cells run, which cells reject, which
fits have unsafe Wald inference, and which profile rows return usable intervals
or honest failure statuses?

## Implemented

- Added `tools/ayumi-q4-status-harness.R`.
- The script reads an RDS payload with `data` and `tree`, using Ayumi's current
  default columns:
  `Tarsus_Length_z`, `Beak_Length_Culmen_z`, `mean_tavg_combined_z`,
  `mean_prec_combined_z`, `log_mass_z`, and `phylo_id`.
- It constructs the exact q4 formula with coupled
  `phylo(1 | p | species, tree = tree)` blocks on `mu1`, `mu2`, `sigma1`, and
  `sigma2`, plus `rho12 = ~ 1`.
- It prunes to requested sizes and runs configurable `engine` and `REML` cells.
- It writes:
  - `fits.csv` for point-estimate runtime, convergence, `pdHess`, `logLik`,
    AIC, fitted rows, and error text;
  - `profile-targets.csv` for public target inventory;
  - `intervals.csv` for optional sigma-axis profile attempts;
  - `conditions.csv` for warnings, messages, and errors;
  - `metadata.md` for git, package, system, thread, and run settings.

## Usage

```sh
DRMTMB_AYUMI_Q4_RDS=for_author/birds_tarsus_beak_10440.rds \
DRMTMB_AYUMI_Q4_OUT=docs/dev-log/ayumi-q4-status/local-250 \
DRMTMB_AYUMI_Q4_SIZES=250 \
DRMTMB_AYUMI_Q4_ENGINES=tmb \
DRMTMB_AYUMI_Q4_REML=false,true \
DRMTMB_AYUMI_Q4_PROFILE=first_sigma \
Rscript --vanilla tools/ayumi-q4-status-harness.R
```

Set `DRMTMB_AYUMI_Q4_ENGINES=tmb,julia` only for a deliberate Julia timing
pass. The default is native `tmb` because the plan now prioritizes completing
the R-side workflow first.

## Checks Run

```sh
air format tools/ayumi-q4-status-harness.R
Rscript --vanilla tools/ayumi-q4-status-harness.R --help
DRMTMB_AYUMI_Q4_RDS=<non-ultrametric smoke RDS> DRMTMB_AYUMI_Q4_OUT=<tmp> DRMTMB_AYUMI_Q4_SIZES=8 DRMTMB_AYUMI_Q4_ENGINES=tmb DRMTMB_AYUMI_Q4_REML=false DRMTMB_AYUMI_Q4_PROFILE=none DRMTMB_AYUMI_Q4_TIME_LIMIT=90 Rscript --vanilla tools/ayumi-q4-status-harness.R
DRMTMB_AYUMI_Q4_RDS=<ultrametric smoke RDS> DRMTMB_AYUMI_Q4_OUT=<tmp> DRMTMB_AYUMI_Q4_SIZES=12 DRMTMB_AYUMI_Q4_ENGINES=tmb DRMTMB_AYUMI_Q4_REML=false,true DRMTMB_AYUMI_Q4_PROFILE=none DRMTMB_AYUMI_Q4_TIME_LIMIT=90 Rscript --vanilla tools/ayumi-q4-status-harness.R
DRMTMB_AYUMI_Q4_RDS=<ultrametric smoke RDS> DRMTMB_AYUMI_Q4_OUT=<tmp> DRMTMB_AYUMI_Q4_SIZES=12 DRMTMB_AYUMI_Q4_ENGINES=tmb DRMTMB_AYUMI_Q4_REML=false DRMTMB_AYUMI_Q4_PROFILE=first_sigma DRMTMB_AYUMI_Q4_TIME_LIMIT=90 Rscript --vanilla tools/ayumi-q4-status-harness.R
```

## Results

- The help path printed required inputs and controls.
- The non-ultrametric tree smoke produced recorded `fits.csv` and
  `conditions.csv` error rows.
- The ultrametric native TMB smoke produced an ML fit row and an expected
  native REML rejection row.
- The first-sigma profile smoke produced an `intervals.csv` row with
  `conf.status = "profile_failed"` and missing endpoints, preserving the
  profile failure as data rather than a silent success.

## Claim Boundary

This is a harness slice, not a model-capability slice. It does not add native
TMB REML for bivariate q4, does not make Julia faster, and has not yet been run
on Ayumi's 10,440-tip RDS in this branch. It gives the team and Ayumi a single
script that can generate the evidence table we need before making speed or
fallback claims.
