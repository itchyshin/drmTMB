# Julia Poisson SD smoke test

`DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^julia-poisson-sd$", reporter = "summary", stop_on_failure = TRUE)'`

Result after correcting the phylogenetic prediction oracle: Julia bridge ran 3 live tests and passed. The tests exercised five fits: Julia Poisson intercept SD output/prediction, seeded native-versus-Julia independent-slope SD agreement, and native-versus-Julia phylogenetic SD coefficients, tree scaling, likelihood, and prediction. Julia warned that this tree has maximum tip height 2.5, so `sd_phylo` uses raw branch-length scale and differs from correlation scaling by `sqrt(2.5)` for this ultrametric tree; the test explicitly checks this scale.

The first run exposed a test-oracle mismatch: it computed expected Julia predictions using TMB coefficients at `1e-8`, although the preceding cross-engine coefficient check allowed `3e-4`. Expected predictions now use the Julia fit's own coefficients. This is a test correction, not a production-model change. It is a focused smoke check only; it does not establish recovery or interval coverage. Julia candidate worktree: `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia`.
