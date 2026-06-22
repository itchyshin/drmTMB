# After Task: Univariate Phylo Balance Inventory

## Goal

Bank S022 by separating fitted, tested, REML-admitted, bridge-experimental, and
unsupported `phylo()` location/scale rows before returning to any Ayumi-facing
reply work.

## Implemented

Added:

- `docs/dev-log/dashboard/phylo-balance-inventory.tsv`
- `docs/design/182-univariate-phylo-balance-inventory.md`

Updated:

- `tools/validate-mission-control.py`
- `tools/start-mission-control.sh`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/finish-100-slices.tsv`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`

The TSV has nine rows. It records that native TMB ML can fit univariate
mean-only, scale-only, and matched mean-scale phylogenetic Gaussian rows; native
TMB REML is exact-Gaussian mean-side only and rejects scale-side structured
effects; Julia sigma-phylo and q4 REML bridge rows remain experimental; native
q4 ML remains diagnostic; and native q4 REML remains unsupported.

## Checks Run

```sh
Rscript -e 'devtools::load_all(quiet = TRUE); set.seed(62022); tree <- ape::rcoal(8); tree$tip.label <- paste0("sp", seq_len(8)); species <- rep(tree$tip.label, each = 5); x <- stats::rnorm(length(species)); y <- stats::rnorm(length(species), 0.2 + 0.3 * x, exp(-0.6)); dat <- data.frame(y = y, x = x, species = factor(species, levels = tree$tip.label)); fit <- drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ phylo(1 | species, tree = tree)), family = stats::gaussian(), data = dat, control = drmTMB::drm_control(se = FALSE, optimizer = list(eval.max = 300, iter.max = 300))); cat("convergence=", fit$opt$convergence, "\n", sep = ""); cat("sdpars_sigma=", paste(names(fit$sdpars$sigma), collapse = ";"), "\n", sep = "")'
```

Result:

```text
convergence=0
sdpars_sigma=phylo(1 | species)
```

Additional checks are recorded in the paired check-log entry after validator
and focused test runs.

## Consistency Audit

This is an inventory and guardrail slice. It does not change formula grammar,
likelihood code, optimizer controls, bridge gates, q4 support, interval
coverage, non-Gaussian REML wording, HSquared AI-REML status, or Ayumi-facing
text.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use S023 to add focused tests for the currently supported combinations, with
the univariate `sigma`-only ML row first.
