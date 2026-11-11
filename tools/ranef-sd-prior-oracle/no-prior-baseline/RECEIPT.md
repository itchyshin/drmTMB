# R fixed-prior and no-prior baseline comparison

This check compares the pre-change drmTMB source with the candidate containing the Gamma SD-prior work. It covers one deterministic, complete-data, unit-weight Gaussian mean random-intercept model, `bf(mu = y ~ x + (1 | g), sigma = ~ x)`, with 40 observations and 10 groups. The two cases are no prior and an existing normal prior on `mu` coefficient `x` with mean 0.2 and SD 1.4. Both use Gaussian ML and `drm_control(se = FALSE, logsigma_clamp = NULL)`.

The base is commit `bfa7acf5bb85e298fe675c5713c34fa208abd860`; the candidate is `bcb6755861494aa8bfdc692067b8c861e97c06ce`. In the recorded macOS run, fitted parameters, objective, data log likelihood, full gradient and Hessian matched exactly between the snapshots in both cases. Objective, gradient and full Hessian also matched at three common interior working-coordinate points per case. Both versions reported convergence code 0, their largest fitted score was `2.259365e-9`, and each fitted Hessian was positive definite. Parameter names and positions, estimator and fixed-penalty field matched. `comparison.csv` records the numerical differences; this one dataset and these two cases do not establish identity for all models or datasets.

The frozen `data.csv` was generated once with R's Mersenne-Twister/Inversion/Rejection RNG and seed 883. The recorded run used R 4.6.0, TMB 1.9.21, devtools 2.5.2 and numDeriv 2016.8.1.1; see `versions.txt`. Git archives were used to construct separate snapshots, and 74 Git blobs per snapshot across `R/`, `src/`, `DESCRIPTION` and `NAMESPACE` matched the specified commits before and after fitting. `source-pins.json` records those source and tree identities. The loaded pkgload temporary DLL matched the corresponding compiled snapshot DLL by SHA-256: base `e581c5ea841c0799723a4d1e9a8b467d334cde622a26fa5966b8ad29bbc17051`, candidate `e51c6091b6560531ac3d21e498d340d0e2dbd0f22534ab83e25608979921aca6`. These binary hashes identify the recorded run; builds elsewhere may differ. The source and binary checks do not establish continuous full-tree provenance.

The recorded comparison used relative objective and log-likelihood tolerance `1e-8`, absolute parameter tolerance `1e-5`, absolute gradient tolerance `1e-6`, and componentwise scaled Hessian tolerance `1e-5`. The comparator also requires finite fitted scores at most `1e-6`, positive fitted Hessian minimum eigenvalues, convergence code 0 and matching selected metadata. An initial provenance assertion incorrectly expected pkgload to load a DLL directly from the snapshot directory; the final run instead checked the temporary DLL against the compiled snapshot DLL. The original failed assertion and complete raw logs remain in the task's external evidence directory.

## Reproduction

On a Unix-like system, provide a local drmTMB Git repository containing both pinned commits and a new, absolute run-directory path whose parent already exists:

```sh
./reproduce.sh /path/to/drmTMB-git-repo /path/to/new-run-directory
```

The script refuses an existing run directory, verifies `SHA256SUMS`, archives both exact commits, checks their source blobs before and after fitting, and writes inputs, optimizer results, raw logs and `comparison.csv` to the new directory. It caps BLAS and OpenMP at one thread. The run requires Git, tar, Python 3, R, `shasum`, devtools, TMB and numDeriv, plus a working C++ toolchain. It does not install dependencies, remove files, or use prebuilt binaries. Full archives require substantial disk space. Fitted values can vary across platforms; the reproduction is judged by the stated tolerances, convergence and score checks rather than byte identity with the recorded table.

`verification/` records a replay of the portable comparison helper against the original retained result objects and an independent run of the portable source-blob verifier. A subsequent end-to-end run of `reproduce.sh` in a new directory passed, including fresh builds of both snapshots; its raw outputs are retained in the task evidence. The reproduced comparison again matched exactly for the two cases on this platform.
