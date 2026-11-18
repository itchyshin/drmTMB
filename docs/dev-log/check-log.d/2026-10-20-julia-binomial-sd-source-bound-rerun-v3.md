# Source-bound Julia Bernoulli SD bridge rerun (v3)

- Command: `DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-binomial-sd", reporter = "summary")'`.
- Result: R exit code 0; the bridge reported five live Julia tests and no failures or skips.
- Diagnostics: two singular-Hessian warnings recurred (`rcond=9.23265335367337e-10`, flat coordinate 7; `rcond=3.879150990279055e-17`, no flat coordinate identified). Wald standard errors for the affected fits are not trustworthy.
- Candidate pins: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.
- Before/after manifests match byte for byte across 167 files: all R sources, native C/C++ sources, Julia `src/*.jl`, the focused R bridge test, and its Julia regression test. Manifest SHA-256 is `555b3813964e5bca5fec19983024118c32859b88fbd5277c4e890a72a916eb6a` for both files.
- Raw console log: `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261020-v3/test-console.log`; SHA-256 `71ad173bc5b44258b5b1409e8b96686d0d378ac382f02c454644a58a387b9478`.
- Full source manifests: `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261020-v3/sources-before.sha256` and `sources-after.sha256`.
- Independent review: the byte-identical manifests and retained log close the source-binding gap; combined with native recovery/oracle/equivalence checks, they support revised G2 for the tested Bernoulli slice. This does not imply broader G3/G4 support.
- This verifies the Bernoulli Julia fit/recovery smoke and bridge outputs for this exact production-source snapshot. It does not validate interval coverage or establish family/effect/provider parity.
