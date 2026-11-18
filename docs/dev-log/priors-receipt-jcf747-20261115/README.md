# Current release bridge receipt

The runner used R source `def81464aec6dfbf7fbba3b00abd06d9616ac24e` and Julia source `cf7477ab31aff77b6af53a00201b2411de749baa` on Totoro with one thread. Its no-prior Gaussian phylogenetic fixture had 12 labels and 72 observations. The checker passed eight checks and rejected 12 mutation controls. The independently checked source manifests covered 68 R files and 127 Julia source files; status and Julia environment records are retained here.

The runner reported a native DLL hash, but the binary build was not independently reproduced. The receipt does not establish prior support, other families, direct-Julia input-order behavior or release readiness. The current JSON is in `docs/dev-log/priors-lane-20261105/release-default-bridge-recheck/current.json`.

A local `--current` check could not resolve the recorded Totoro source path; its failure is retained in `local-current-checker.log`. The runner-side `--current` check passed on Totoro. The independent audit checked the recorded Git blobs separately.

The local CI staleness check passed both without a Julia checkout and with `DRM_JL_PATH` set to the pinned candidate; the latter matched all 127 Julia source entries. The former checks R paths and reports the Julia entries as unverified.
