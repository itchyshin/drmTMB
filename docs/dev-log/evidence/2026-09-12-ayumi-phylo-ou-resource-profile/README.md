# Ayumi body-mass OU resource and alpha-boundary receipt

This source-current replay used the four cells of
`tools/phylo-ou-ayumi-bodymass-ladder.R`, each run separately with
`/usr/bin/time -l` after the runner's `--cell=` selector.  The models use the
same 10,440 rows, ultrametric tree, transformed climate fields, formulae,
optimizer controls, and `REML = TRUE` as the source-pinned ladder.  Input
source is `Ayumi-495/LS_ecogeographical-rules` commit
`6c52a46f67d9d86842ae5476dee828684f64a464`; model source is
`b5219000845e5d4e74f8843740caadb45f54eb78` plus the uncommitted receipt-tool
helpers that do not change the estimator.

`provenance-manifest.csv` binds each retained row to the Ayumi input commit and
hashes, the source-current model commit, the exact resource command, and the
SHA-256 values of the external cell RDS/receipt/time-log files. Those large
RDS files remain outside Git, but their identity is therefore auditable.
`resource-time-output.txt` preserves the raw relevant lines emitted by
`/usr/bin/time -l`, and `warnings-and-optimizers.csv` preserves exact warning
meaning and every optimizer escalation path.

`fit-summary.csv` records each fit's elapsed time, process peak RSS, process
peak-memory-footprint field, convergence/Hessian/gradient diagnostics, and the
bounded OU profile timing/span. `fixed-effects.csv` retains every fitted
location, residual-scale, and direct-phylogenetic-SD fixed coefficient. The
source-current per-cell RDS receipts additionally retain optimizer attempts and
warnings under the run directory.

The two `alpha-profile-*.csv` files come from
`tools/phylo-ou-ayumi-alpha-profile.R`, which rebuilds a compatible current TMB
objective and runs a four-row, one-step `TMB::tmbprofile` diagnostic.  Both
profiles are locally flat around an alpha near zero.  They are boundary
diagnostics, not confidence intervals, recovery evidence, or a reason to
prefer OU over BM.

The earlier four-cell source-pinned receipt was made at model source
`9d78f85d5fe736b9faae7a0afa304cb15e441a05`. This resource/profile replay is a
separate current-source receipt at `b5219000845e5d4e74f8843740caadb45f54eb78`;
the input source commit and hashes are identical in both receipts.
