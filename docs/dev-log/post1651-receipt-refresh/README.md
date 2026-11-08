# Post-#1651 bridge receipt refresh

PR #1651 changed a roxygen source-pin line in `R/drmTMB.R`, making the prior
whole-file receipt hash stale. The published v0.8.1 tag is unchanged.

The unchanged 12-label, 72-row Gaussian phylogenetic fixture ran on Totoro
against R commit `51f94e61a3b1f652fcedfc891d6da7e7281c7799` and Julia commit
`0460f25ffd23c7b60c0fc09e9e6820a2881714c9`. The runner passed all eight checks
in 57.183 seconds. The checker verified current source paths on Totoro and
rejected all twelve negative controls. Labels, data, order, tree and group
covariate matched the previous receipt. The earlier receipt is preserved here
as `current-before.json`.

This is one fixture. It does not establish broad engine parity or calibrated
uncertainty. The local CI-equivalent check verifies the R files and runner; when
`DRM_JL_PATH` is unset it does not verify the Julia source entries. The remote
checker verified those source paths at the time of the run.

After the run, `source-provenance.txt` recorded the remote checkout HEAD, clean
tracked status, compiled-source hashes and the built and installed DLL hashes.
Both DLL hashes match the loaded DLL hash in `current.json`. The captured
`install.log.gz` records the package build. This post-run snapshot is not a
continuous source monitor.
